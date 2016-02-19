//
//  SingleDelay.mm
//
//  Created by Aliaksandr Tsurko on 05.01.16.
//  Copyright © 2016 Aliaksandr Tsurko. All rights reserved.
//

#include "SingleDelay.hpp"

namespace ataudioprocessing {
   void SingleDelay::init(sample_t sampleRate, int chnum, int blockSize) {
       Generator::init(sampleRate, chnum, blockSize);
       sampleRatePowersOfTwoApprox = (1<<int(ceil(log2(sampleRate))))-1;

       delayBuffer.resize(sampleRatePowersOfTwoApprox+1);

       setInterpolation(Linear);
       setDelayTime(0.1);
   }

   void SingleDelay::setInterpolation(DelayInterpolationType type) {
       interpolationType = type;
   }

   void SingleDelay::setDelayTime(sample_t newDelayTime) {
       delayTime = newDelayTime;
       delayTimeInSamples = floorf(sr*delayTime);
   }

   sample_t SingleDelay::generateSample(sample_t in) {
       switch (interpolationType) {
           case None:
               out = generateSampleNone(in);
               break;

           case Linear:
               out = generateSampleLinear(in);
               break;

           case Allpass:
               out = generateSampleAllpass(in);
               break;

           case Cubic:
               out = generateSampleCubic(in);
               break;

           default:
               out = 0.0;
               break;
       }

       return out;
   }

   sample_t SingleDelay::generateSampleNone(sample_t in) {
       delayBuffer[inputIndex&sampleRatePowersOfTwoApprox] = in;
       out = delayBuffer[(inputIndex-delayTimeInSamples)&sampleRatePowersOfTwoApprox];

       ++inputIndex;

       return out;
   }

   sample_t SingleDelay::generateSampleLinear(sample_t in) {
       delayBuffer[inputIndex&sampleRatePowersOfTwoApprox] = in;
       sample_t fraction = (sr*delayTime) - delayTimeInSamples;
       sample_t t0 = delayBuffer[(inputIndex-delayTimeInSamples)&sampleRatePowersOfTwoApprox];
       sample_t z1 = delayBuffer[(inputIndex-delayTimeInSamples-1)&sampleRatePowersOfTwoApprox];

       ++inputIndex;

       out = t0*(1.0-fraction) + z1*fraction;

       return out;
   }

   sample_t SingleDelay::generateSampleAllpass(sample_t in) {
       delayBuffer[inputIndex&sampleRatePowersOfTwoApprox] = in;
       sample_t fraction = (sr*delayTime) - delayTimeInSamples;
       sample_t t0 = delayBuffer[(inputIndex-delayTimeInSamples)&sampleRatePowersOfTwoApprox];
       sample_t z1 = delayBuffer[(inputIndex-delayTimeInSamples-1)&sampleRatePowersOfTwoApprox];

       ++inputIndex;

       sample_t coeff = 1-fraction;

       out = (t0*coeff + z1) - out*coeff;

       return out;
   }

   sample_t SingleDelay::generateSampleCubic(sample_t in) {
       delayBuffer[inputIndex&sampleRatePowersOfTwoApprox] = in;

       sample_t fraction = (sr*delayTime) - delayTimeInSamples;
       sample_t t1 = delayBuffer[(inputIndex-delayTimeInSamples+1)&sampleRatePowersOfTwoApprox];
       sample_t t0 = delayBuffer[(inputIndex-delayTimeInSamples)&sampleRatePowersOfTwoApprox];
       sample_t z1 = delayBuffer[(inputIndex-delayTimeInSamples-1)&sampleRatePowersOfTwoApprox];
       sample_t z2 = delayBuffer[(inputIndex-delayTimeInSamples-2)&sampleRatePowersOfTwoApprox];

       // Interpolation
       sample_t z1Minust0 = z1-t0;
       out = t0 + fraction*(z1Minust0 - 0.1666667*(1.0-fraction)*((z2 - t1 - (3.0*z1Minust0))*fraction + (z2 + (2.0*t1) - (3.0*t0))));

       // Increment
       ++inputIndex;

       return out;
   }
}
