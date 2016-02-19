//
//  TriLFOStereo.mm
//
//  Created by Ales Tsurko on 21.01.16.
//  Copyright © 2016 Aliaksandr Tsurko. All rights reserved.
//

#include "TriLFOStereo.hpp"
#import <Accelerate/Accelerate.h>

namespace ataudioprocessing {
   void TriLFOStereo::init(sample_t sampleRate, int chnum, int blockSize) {
       Generator::init(sampleRate, chnum, blockSize);

       output.resize(numberOfChannels, sample_vec_t(calculationBlockSize, 0.0));
       controlOutput.resize(numberOfChannels);
   }

   multich_sample_vec_t TriLFOStereo::calculateBlock(sample_t frequency,
                                                     sample_t spread,
                                                     sample_t amp) {

       sample_t nextPhase;
       sample_t incr = frequency/sr;
       sample_t offset = spread * 0.25;

       for (int frameIndex = 0; frameIndex < calculationBlockSize; ++frameIndex) {
           // Common phase
           nextPhase = phase + incr;
           phase = nextPhase - roundf(nextPhase);

           // Left
           nextPhase = phase + offset;
           nextPhase = nextPhase - roundf(nextPhase);
           output[0][frameIndex] = (fabs(nextPhase) * 4 - 1) * amp;

           if (numberOfChannels > 1) {
               // Right
               nextPhase = phase - offset;
               nextPhase = nextPhase - roundf(nextPhase);
               output[1][frameIndex] = (fabs(nextPhase) * 4 - 1) * amp;
           }
       }

       return output;
   }

   sample_vec_t TriLFOStereo::generateCRFrame(sample_t frequency,
                                              sample_t spread,
                                              sample_t amp) {

       sample_t incr = (frequency/sr)*calculationBlockSize;
       sample_t offset = spread * 0.25;
       sample_t nextPhase = phase+incr;
       phase = nextPhase - roundf(nextPhase);
       nextPhase = phase+offset;
       nextPhase = nextPhase - roundf(nextPhase);
       controlOutput[0] = (fabs(nextPhase) * 4 - 1) * amp;

       if (numberOfChannels > 1) {
           nextPhase = phase-offset;
           nextPhase = nextPhase - roundf(nextPhase);
           controlOutput[1] = (fabs(nextPhase) * 4 - 1) * amp;
       }

       return controlOutput;
   }
} /* ataudioprocessing */
