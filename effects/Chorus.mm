//
//  Chorus.cpp
//
//  Created by Aliaksandr Tsurko on 21.01.16.
//  Copyright © 2016 Aliaksandr Tsurko. All rights reserved.
//

#include "Chorus.hpp"
#import <Accelerate/Accelerate.h>

namespace ataudioprocessing {
   void Chorus::init(sample_t sampleRate, int chnum, int blockSize) {
       Generator::init(sampleRate, chnum, blockSize);

       output.resize(numberOfChannels, sample_vec_t(calculationBlockSize, 0.0));

       delays[0].init(sampleRate, chnum, blockSize);
       delays[1].init(sampleRate, chnum, blockSize);
       delays[0].setInterpolation(Cubic);
       delays[1].setInterpolation(Cubic);
       lfo.init(sampleRate, chnum, blockSize);
   }

   multich_sample_vec_t Chorus::calculateBlock(multich_sample_vec_t input,
                                               sample_t rate,
                                               sample_t delay,
                                               sample_t depth,
                                               sample_t spread,
                                               sample_t drywet) {

       sample_t realDepth = twoPointShaper(depth,
                                           sample_t(0.0005),
                                           sample_t(0.002));
       sample_t newDelayTime;
       sample_t smoothing = 0.001;
       sample_t amount = realDepth/rate;

       sample_vec_t lfoOutput = lfo.generateCRFrame(rate, spread, 1.0);


       sample_t dryMul = (2.0 - (1.0-drywet)) * (1.0-drywet);
       sample_t wetMul = (2.0 - drywet) * drywet;

       sample_t dry[calculationBlockSize];
       sample_t wet[calculationBlockSize];

       for (int channel = 0; channel < numberOfChannels; ++channel) {

           newDelayTime = (lfoOutput[channel] + 1) * amount + delay;

           for (int frameIndex = 0; frameIndex < calculationBlockSize; ++frameIndex) {
               modulatedDelayTime[channel] = modulatedDelayTime[channel]*(1.0-smoothing) + newDelayTime*smoothing;

               delays[channel].setDelayTime(modulatedDelayTime[channel]);
               wet[frameIndex] = delays[channel].generateSample(input[channel][frameIndex]);
           }
           vDSP_vsmul(&input[channel][0], 1, &dryMul, dry, 1, calculationBlockSize);
           vDSP_vsmul(wet, 1, &wetMul, wet, 1, calculationBlockSize);
           vDSP_vadd(dry, 1, wet, 1, &output[channel][0], 1, calculationBlockSize);
       }

       return output;
   }
}
