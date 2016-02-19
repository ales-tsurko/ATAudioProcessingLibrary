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

       output.resize(blockSize);

       oversampledBlockSize = blockSize * oversamplingFactor;
       oversampledOutput.resize(oversampledBlockSize);

       phase.resize(oversampledBlockSize);

       sample_t cuttoff = sampleRate * 0.47;

       decimationFilter.init(sampleRate*oversamplingFactor, chnum, oversampledBlockSize, cuttoff, 15);
   }

   sample_vec_t ParabolicWM::calculateBlock(sample_t frequency, sample_t width, sample_t amplitude) {

       sample_t incr = frequency/(sr*oversmplFactor);

       sample_t ones[oversampledBlockSize];
       sample_t phaseMax = 1.0;

       vDSP_vfill(&phaseMax, ones, 1, oversampledBlockSize);
       vDSP_vramp(&zphase, &incr, &phase[0], 1, oversampledBlockSize);

       vvfmodf(&phase[0], &phase[0], ones, &oversampledBlockSize);

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
}
