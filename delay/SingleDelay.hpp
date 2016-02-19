//
//  SingleDelay.hpp
//
//  Created by Aliaksandr Tsurko on 05.01.16.
//  Copyright © 2016 Aliaksandr Tsurko. All rights reserved.
//

#ifndef SingleDelay_hpp
#define SingleDelay_hpp

#include <stdio.h>
#include <vector>
#include "../Globals.hpp"


namespace ataudioprocessing {
   // Maximum length is 1 second
   typedef enum {
       None = 0,
       Linear = 1,
       Allpass = 2,
       Cubic = 3
   } DelayInterpolationType;

   class SingleDelay: public Generator {
   public:
       sample_t out;

       void init(sample_t sampleRate, int chnum, int blockSize);

       void setDelayTime(sample_t newDelayTime);
       void setInterpolation(DelayInterpolationType type);

       sample_t generateSample(sample_t in);

   private:
       sample_t generateSampleNone(sample_t in);
       sample_t generateSampleLinear(sample_t in);
       sample_t generateSampleAllpass(sample_t in);
       sample_t generateSampleCubic(sample_t in);

       int inputIndex = 0;
       int delayTimeInSamples;
       DelayInterpolationType interpolationType;
       size_t sampleRatePowersOfTwoApprox;
       sample_vec_t delayBuffer;
       sample_t delayTime = 0;

   };   
}

#endif /* SingleDelay_hpp */
