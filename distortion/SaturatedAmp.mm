//
//  SaturatedAmp.mm
//
//  Created by Aliaksandr Tsurko on 28.01.16.
//  Copyright © 2016 Aliaksandr Tsurko. All rights reserved.
//

#include "SaturatedAmp.hpp"
#import <Accelerate/Accelerate.h>

namespace ataudioprocessing {
    void SaturatedAmp::init(sample_t sampleRate,
                            int chnum,
                            int blockSize,
                            int oversamplingFactor) {
        Generator::init(sampleRate, chnum, blockSize);
        
        oversmplFactor = oversamplingFactor;
        output.resize(numberOfChannels, sample_vec_t(calculationBlockSize, 0.0));
        
        oversampledBufSize = oversamplingFactor * blockSize;
        oversampledBuffer.resize(numberOfChannels, sample_vec_t(oversampledBufSize, 0.0));
        
        sample_t cutFreq = sampleRate*0.47;
        
        upsamplingFilters.resize(numberOfChannels);
        decimationFilters.resize(numberOfChannels);
        
        for (int channel = 0; channel < chnum; ++channel) {
            upsamplingFilters[channel].init(sampleRate*oversamplingFactor, chnum, blockSize*oversamplingFactor, cutFreq, 10);
            decimationFilters[channel].init(sampleRate*oversamplingFactor, chnum, blockSize*oversamplingFactor, cutFreq, 25);
        }
    }
    
    multich_sample_vec_t SaturatedAmp::calculateBlock(multich_sample_vec_t input,
                                                      sample_t preamp,
                                                      sample_t outputAmp) {
        sample_t inputMul = dBToAmp(preamp);
        sample_t outputMul = dBToAmp(outputAmp);
        
        for (int channel = 0; channel < numberOfChannels; ++channel) {
            // нужно заполнять нулями, чтобы в промежутках между сэмплами не оказа-
            // лись сэмплы предыдущих вычислений
            memset(&oversampledBuffer[channel][0], 0, sizeof(sample_t) * oversampledBufSize);
            
            // input gain
            vDSP_vsmul(&input[channel][0], 1, &inputMul, &oversampledBuffer[channel][0], oversmplFactor, calculationBlockSize);
        }
        
        // interpolation filter
        for (int channel = 0; channel < numberOfChannels; ++channel) {
            upsamplingFilters[channel].calculateBlock(oversampledBuffer[channel]);
        }
        
        // saturation on upsampled table
        sample_t lim = 1.3333;
        sample_t a1 = -0.18963;
        sample_t b1 = 0.0161817;
        sample_t cubed[oversampledBufSize];
        sample_t x[oversampledBufSize];
        sample_t y[oversampledBufSize];
        sample_t saturated[oversampledBufSize];
        
        sample_t outSample;
        for (int channel = 0; channel < numberOfChannels; ++channel) {
            // (a1 * cubed + out) + (b1 * cubed * out)
            // cubed
            vDSP_vmul(&upsamplingFilters[channel].output[0], 1, &upsamplingFilters[channel].output[0], 1, cubed, 1, oversampledBufSize);
            vDSP_vmul(cubed, 1, &upsamplingFilters[channel].output[0], 1, cubed, 1, oversampledBufSize);
            // x ((a1 * cubed + out))
            vDSP_vsma(cubed, 1, &a1, &upsamplingFilters[channel].output[0], 1, x, 1, oversampledBufSize);
            // y ((b1 * cubed * out))
            vDSP_vsmul(cubed, 1, &b1, y, 1, oversampledBufSize);
            vDSP_vmul(y, 1, &upsamplingFilters[channel].output[0], 1, y, 1, oversampledBufSize);
            // x + y
            vDSP_vadd(x, 1, y, 1, saturated, 1, oversampledBufSize);
            
            for (int frameIndex = 0; frameIndex < oversampledBufSize; ++frameIndex) {
                
                if (upsamplingFilters[channel].output[frameIndex] > lim) {
                    outSample = 1.0;
                } else if (upsamplingFilters[channel].output[frameIndex] < -lim) {
                    outSample = -1.0;
                } else {
                    outSample = saturated[frameIndex];
                }
                
                oversampledBuffer[channel][frameIndex] = outSample;
            }
        }
        
        // decimation
        for (int channel = 0; channel < numberOfChannels; ++channel) {
            decimationFilters[channel].calculateBlock(oversampledBuffer[channel]);
            
            for (int frameIndex = 0; frameIndex < calculationBlockSize; ++frameIndex) {
                int frameOffset = frameIndex*oversmplFactor;
                
                output[channel][frameIndex] = decimationFilters[channel].output[frameOffset];
            }
        }
        
        // output gain
        for (int channel = 0; channel < numberOfChannels; ++channel) {
            vDSP_vsmul(&output[channel][0], 1, &outputMul, &output[channel][0], 1, calculationBlockSize);
        }
        
        return output;
    }
}
