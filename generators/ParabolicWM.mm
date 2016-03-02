//
//  ParabolicWM.mm
//
//  Created by Aliaksandr Tsurko on 13.01.16.
//  Copyright © 2016 Aliaksandr Tsurko. All rights reserved.
//

#include "ParabolicWM.hpp"
#import <Accelerate/Accelerate.h>

namespace ataudioprocessing {
    void ParabolicWM::init(sample_t sampleRate, int chnum, int blockSize, int oversamplingFactor) {
        Generator::init(sampleRate, chnum, blockSize);
        
        oversmplFactor = oversamplingFactor;
        oversampleRate = sampleRate * oversamplingFactor;
        
        oversampledBlockSize = blockSize * oversamplingFactor;
        oversampledOutput.resize(oversampledBlockSize);
        
        phase.resize(oversampledBlockSize);
        ones.resize(oversampledBlockSize);
        std::fill(ones.begin(), ones.end(), 1.0);
        
        sample_t cuttoff = sampleRate * 0.47;
        
        decimationFilter.init(sampleRate*oversamplingFactor, chnum, oversampledBlockSize, cuttoff, 15);
        freqSmoother.setAmount(0.93);
        ampSmoother.setAmount(0.93);
        widthSmoother.setAmount(0.99);
    }
    
    sample_vec_t ParabolicWM::calculateBlock(sample_t frequency,
                                             sample_t width,
                                             sample_t amplitude) {
        
        sample_t incr = frequency/oversampleRate;
        
        vDSP_vramp(&zphase, &incr, &phase[0], 1, oversampledBlockSize);
        
        vvfmodf(&phase[0], &phase[0], &ones[0], &oversampledBlockSize);
        
        zphase = phase[oversampledBlockSize-1]+incr;
        
        // First part of the wave
        sample_t firstWavePart[oversampledBlockSize];
        vDSP_vsdiv(&phase[0], 1, &width, firstWavePart, 1, oversampledBlockSize);
        sample_t x = -0.5;
        vDSP_vsadd(firstWavePart, 1, &x, firstWavePart, 1, oversampledBlockSize);
        vDSP_vmul(firstWavePart, 1, firstWavePart, 1, firstWavePart, 1, oversampledBlockSize);
        x = -4;
        sample_t y = 1;
        vDSP_vsmsa(firstWavePart, 1, &x, &y, firstWavePart, 1, oversampledBlockSize);
        
        // Second part of the wave
        sample_t secondWavePart[oversampledBlockSize];
        sample_t xArr[oversampledBlockSize];
        
        vDSP_vfill(&width, xArr, 1, oversampledBlockSize);
        x = 1/(1-width);
        vDSP_vsbsm(&phase[0], 1, xArr, 1, &x, secondWavePart, 1, oversampledBlockSize);
        x = -0.5;
        vDSP_vsadd(secondWavePart, 1, &x, secondWavePart, 1, oversampledBlockSize);
        vDSP_vmul(secondWavePart, 1, secondWavePart, 1, secondWavePart, 1, oversampledBlockSize);
        x = 4;
        y = -1;
        vDSP_vsmsa(secondWavePart, 1, &x, &y, secondWavePart, 1, oversampledBlockSize);
        
        sample_t second_discontinuity[oversampledBlockSize];
        x = -width;
        vDSP_vsadd(&phase[0], 1, &x, second_discontinuity, 1, oversampledBlockSize);
        vvfabsf(second_discontinuity, second_discontinuity, &oversampledBlockSize);
        
        for (int frameIndex = 0; frameIndex < oversampledBlockSize; ++frameIndex) {
            if (phase[frameIndex] < width) {
                oversampledOutput[frameIndex] = firstWavePart[frameIndex];
            } else {
                oversampledOutput[frameIndex] = secondWavePart[frameIndex];
            }
            
            // PolyBLAMP
            
            sample_t currentPhase = phase[frameIndex];
            sample_t secondDiscontinuityPhase = second_discontinuity[frameIndex];
            
            if (currentPhase < incr || secondDiscontinuityPhase < incr) {
                sample_t t = secondDiscontinuityPhase < incr || secondDiscontinuityPhase > 1-incr ? secondDiscontinuityPhase : currentPhase;
                sample_t scale_a = 2 * incr/width;
                sample_t scale_b = 2 * incr/(1-width);
                sample_t d = t/incr - 1;
                sample_t x = -(d*d*d)/3;
                oversampledOutput[frameIndex] = oversampledOutput[frameIndex] + x*scale_a - x*scale_b;
            } else if (currentPhase > 1-incr || secondDiscontinuityPhase > 1-incr) {
                sample_t t = secondDiscontinuityPhase < incr || secondDiscontinuityPhase > 1-incr ? secondDiscontinuityPhase : currentPhase;
                sample_t scale_a = 2 * incr/width;
                sample_t scale_b = 2 * incr/(1-width);
                sample_t d = (t-1)/incr + 1;
                sample_t x = (d*d*d)/3;
                oversampledOutput[frameIndex] = oversampledOutput[frameIndex] + x*scale_a - x*scale_b;
            }
        }
        
        vDSP_vsmul(&oversampledOutput[0], 1, &amplitude, &oversampledOutput[0], 1, oversampledBlockSize);
        
        // decimation
        decimationFilter.calculateBlock(oversampledOutput);
        
        for (int frameIndex = 0; frameIndex < calculationBlockSize; ++frameIndex) {
            int frameOffset = frameIndex*oversmplFactor;
            
            output[frameIndex] = decimationFilter.output[frameOffset];
        }
        
        return output;
    }
    
    sample_vec_t ParabolicWM::calculateBlock(sample_vec_t frequency,
                                             sample_vec_t width,
                                             sample_vec_t amplitude) {
        
        sample_vec_t upsampledFrequency (oversampledBlockSize);
        sample_vec_t upsampledAmplitude (oversampledBlockSize);
        sample_vec_t upsampledWidth (oversampledBlockSize);
        
        for (int frameIndex = 0; frameIndex < calculationBlockSize; ++frameIndex) {
            upsampledFrequency[frameIndex*oversmplFactor] = frequency[frameIndex];
            upsampledAmplitude[frameIndex*oversmplFactor] = amplitude[frameIndex];
            upsampledWidth[frameIndex*oversmplFactor] = clamp(width[frameIndex], 0.05f, 0.95f); // clip to width min/max value
        }
        
        for (int frameIndex = 0; frameIndex < oversampledBlockSize; ++frameIndex) {
            upsampledFrequency[frameIndex] = freqSmoother.smooth(upsampledFrequency[frameIndex]);
            upsampledAmplitude[frameIndex] = ampSmoother.smooth(upsampledAmplitude[frameIndex])*sample_t(oversmplFactor)*0.93;
            upsampledAmplitude[frameIndex] = clamp(upsampledAmplitude[frameIndex], 0.0f, 1.0f);
            
            upsampledWidth[frameIndex] = (widthSmoother.smooth(upsampledWidth[frameIndex]))*sample_t(oversmplFactor)*0.99;
            upsampledWidth[frameIndex] = clamp(upsampledWidth[frameIndex], 0.05f, 0.95f);
        }
        
        sample_vec_t incr (oversampledBlockSize);
        vDSP_vsdiv(&upsampledFrequency[0], 1, &sr, &incr[0], 1, oversampledBlockSize);
        
        for (int frameIndex = 0; frameIndex < oversampledBlockSize; ++frameIndex) {
            phase[frameIndex] = zphase;
            zphase += incr[frameIndex];
        }
        
        vvfmodf(&phase[0], &phase[0], &ones[0], &oversampledBlockSize);
        
        zphase = phase[oversampledBlockSize-1]+incr[oversampledBlockSize-1];
        
        // First part of the wave
        // -4 * (phase/w - 0.5)^2 + 1
        sample_t firstWavePart[oversampledBlockSize];
        vDSP_vdiv(&upsampledWidth[0], 1, &phase[0], 1, firstWavePart, 1, oversampledBlockSize);
        
        sample_t x = -0.5;
        vDSP_vsadd(firstWavePart, 1, &x, firstWavePart, 1, oversampledBlockSize);
        vDSP_vmul(firstWavePart, 1, firstWavePart, 1, firstWavePart, 1, oversampledBlockSize);
        x = -4;
        sample_t y = 1;
        vDSP_vsmsa(firstWavePart, 1, &x, &y, firstWavePart, 1, oversampledBlockSize);
        
        // Second part of the wave
        // 4 * ((phase-w)/(1-w) - 0.5)^2 - 1
        sample_t secondWavePart[oversampledBlockSize];
        sample_t xArr[oversampledBlockSize];
        
        vDSP_vsub(&upsampledWidth[0], 1, &ones[0], 1, xArr, 1, oversampledBlockSize);
        x = 1;
        vDSP_svdiv(&x, xArr, 1, xArr, 1, oversampledBlockSize);
        vDSP_vsbm(&phase[0], 1, &upsampledWidth[0], 1, xArr, 1, secondWavePart, 1, oversampledBlockSize);
        
        x = -0.5;
        vDSP_vsadd(secondWavePart, 1, &x, secondWavePart, 1, oversampledBlockSize);
        vDSP_vmul(secondWavePart, 1, secondWavePart, 1, secondWavePart, 1, oversampledBlockSize);
        x = 4;
        y = -1;
        vDSP_vsmsa(secondWavePart, 1, &x, &y, secondWavePart, 1, oversampledBlockSize);
        
        sample_t second_discontinuity[oversampledBlockSize];
        vDSP_vneg(&upsampledWidth[0], 1, second_discontinuity, 1, oversampledBlockSize);
        vDSP_vadd(&phase[0], 1, second_discontinuity, 1, second_discontinuity, 1, oversampledBlockSize);
        vvfabsf(second_discontinuity, second_discontinuity, &oversampledBlockSize);
        
        for (int frameIndex = 0; frameIndex < oversampledBlockSize; ++frameIndex) {
            if (phase[frameIndex] < upsampledWidth[frameIndex]) {
                oversampledOutput[frameIndex] = firstWavePart[frameIndex];
            } else {
                oversampledOutput[frameIndex] = secondWavePart[frameIndex];
            }
            
            // PolyBLAMP
            
            sample_t currentPhase = phase[frameIndex];
            sample_t secondDiscontinuityPhase = second_discontinuity[frameIndex];
            sample_t incr_s = incr[frameIndex];
            sample_t width_s = upsampledWidth[frameIndex];
            
            if (currentPhase < incr_s || secondDiscontinuityPhase < incr_s) {
                sample_t t = secondDiscontinuityPhase < incr_s || secondDiscontinuityPhase > 1-incr_s ? secondDiscontinuityPhase : currentPhase;
                sample_t scale_a = 2 * incr_s/width_s;
                sample_t scale_b = 2 * incr_s/(1-width_s);
                sample_t d = t/incr_s - 1;
                sample_t x = -(d*d*d)/3;
                oversampledOutput[frameIndex] = oversampledOutput[frameIndex] + x*scale_a - x*scale_b;
            } else if (currentPhase > 1-incr_s || secondDiscontinuityPhase > 1-incr_s) {
                sample_t t = secondDiscontinuityPhase < incr_s || secondDiscontinuityPhase > 1-incr_s ? secondDiscontinuityPhase : currentPhase;
                sample_t scale_a = 2 * incr_s/width_s;
                sample_t scale_b = 2 * incr_s/(1-width_s);
                sample_t d = (t-1)/incr_s + 1;
                sample_t x = (d*d*d)/3;
                oversampledOutput[frameIndex] = oversampledOutput[frameIndex] + x*scale_a - x*scale_b;
            }
        }
        
        vDSP_vmul(&oversampledOutput[0], 1, &upsampledAmplitude[0], 1, &oversampledOutput[0], 1, oversampledBlockSize);
        
        // decimation
        decimationFilter.calculateBlock(oversampledOutput);
        
        for (int frameIndex = 0; frameIndex < calculationBlockSize; ++frameIndex) {
            int frameOffset = frameIndex*oversmplFactor;
            
            output[frameIndex] = decimationFilter.output[frameOffset];
        }
        
        return output;
    }
}
