//
//  SaturatedAmp.mm
//
//  Created by Aliaksandr Tsurko on 28.01.16.
//  Copyright © 2016 Aliaksandr Tsurko. All rights reserved.
//

#include "SaturatedAmp.hpp"
#import <Accelerate/Accelerate.h>

namespace ataudioprocessing {
   SaturatedAmp::SaturatedAmp() : upsamplingFilters(NULL), decimationFilters(NULL) {}

   SaturatedAmp::~SaturatedAmp() {
       for (int channel = 0; channel < numberOfChannels; ++channel) {
           delete upsamplingFilters[channel];
           delete decimationFilters[channel];
       }
       delete [] upsamplingFilters;
       delete [] decimationFilters;
   }

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

       upsamplingFilters = new FIRLP* [chnum];

       for (int channel = 0; channel < chnum; ++channel) {
           upsamplingFilters[channel] = new FIRLP();
           upsamplingFilters[channel]->init(sampleRate*oversamplingFactor, chnum, blockSize*oversamplingFactor, cutFreq, 10);
       }

       decimationFilters = new FIRLP* [chnum];

       for (int channel = 0; channel < chnum; ++channel) {
           decimationFilters[channel] = new FIRLP();
           decimationFilters[channel]->init(sampleRate*oversamplingFactor, chnum, blockSize*oversamplingFactor, cutFreq, 25);
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
           vDSP_vsmul(&input[channel][0], 1, &inputMul, &oversampledBuffer[channel][0], 4, calculationBlockSize);
       }

       // interpolation filter
       for (int channel = 0; channel < numberOfChannels; ++channel) {
           upsamplingFilters[channel]->calculateBlock(oversampledBuffer[channel]);
       }

       // saturation on upsampled table
       sample_t lim = 1.3333;
       for (int channel = 0; channel < numberOfChannels; ++channel) {
           for (int frameIndex = 0; frameIndex < oversampledBufSize; ++frameIndex) {
               sample_t outSample = upsamplingFilters[channel]->output[frameIndex];

               if (outSample > lim) {
                   outSample = 1.0;
               } else if (outSample < -lim) {
                   outSample = -1.0;
               } else {
                   sample_t outSampleCubed = outSample*outSample*outSample;
                   outSample = (-0.18963*outSampleCubed + outSample) + (0.0161817*outSampleCubed*outSample);
               }

               oversampledBuffer[channel][frameIndex] = outSample;
           }
       }

       // decimation
       for (int channel = 0; channel < numberOfChannels; ++channel) {
           decimationFilters[channel]->calculateBlock(oversampledBuffer[channel]);

           for (int frameIndex = 0; frameIndex < calculationBlockSize; ++frameIndex) {
               int frameOffset = frameIndex*oversmplFactor;

               output[channel][frameIndex] = decimationFilters[channel]->output[frameOffset];
           }
       }

       // output gain
       for (int channel = 0; channel < numberOfChannels; ++channel) {
           vDSP_vsmul(&output[channel][0], 1, &outputMul, &output[channel][0], 1, calculationBlockSize);
       }

       return output;
   }
}
