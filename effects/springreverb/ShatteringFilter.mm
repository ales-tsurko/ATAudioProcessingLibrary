//
//  ShatteringFilter.mm
//
//  Created by Aliaksandr Tsurko on 22.12.15.
//  Copyright © 2015 Aliaksandr Tsurko. All rights reserved.
//

#include "ShatteringFilter.hpp"

namespace ataudioprocessing {
   void ShatteringFilter::init(sample_t sampleRate, int chnum, int blockSize) {
       Generator::init(sampleRate, chnum, blockSize);

       length = 0.633;
       lng = twoPointShaper(length, sample_t(0.02), sample_t(0.04));
       frc = twoPointShaper(length, sample_t(0.0003), sample_t(0.0005));

       setDensity(1.0);

       reflectionFilter.init(sampleRate, chnum, blockSize);

       dampingFilter.init(sampleRate, chnum, blockSize);
       damping = 5214.0; // in Hz
       dampingFilter.setParameters(LP, damping, 0.0);

       smoothing = 0.007;
       inSmoother_out = 0.0;
       out_lng = lng * 0.5;
       output = 0.0;

       transverseReflectionFilter.init(sampleRate, chnum, blockSize);
       transverseReflectionFilter.setInterpolation(None);
       transverseReflectionFilter.setDelayTime(out_lng);
       transverseReflectionFilter.setFeedback(transReflectFBGain);

       sample_t diffusionDelayTime = 0.003;
       diffusionFilterBankFBGain = 0.65/density;
       numberOfDiffFilters = 3;
       diffusionFilterBank.resize(numberOfDiffFilters);
       for (int i = 0; i < numberOfDiffFilters; ++i) {
           diffusionFilterBank[i].init(sampleRate, chnum, blockSize);
           diffusionFilterBank[i].setInterpolation(Cubic);
           diffusionFilterBank[i].setFeedback(diffusionFilterBankFBGain);
       }

       diffusionFilterBank[0].setDelayTime(diffusionDelayTime);
       diffusionFilterBank[1].setDelayTime(diffusionDelayTime*1.0472);
       diffusionFilterBank[2].setDelayTime(diffusionDelayTime*1.136212); // dt * 1.0472 * 1.085

       longitDelayTime = lng * 1.0472;
       longitudinalFilter.init(sampleRate, chnum, blockSize);
       longitudinalFilter.setInterpolation(None);
       longitudinalFilter.setDelayTime(longitDelayTime);
   }

   void ShatteringFilter::setSize(sample_t newSize) {
       // -0.75 <= true <= -0.985, 0 <= normalized <= 1
       feedback = twoPointShaper(newSize, sample_t(-0.74934), sample_t(-0.999));
   }

   void ShatteringFilter::setDensity(sample_t newDensity) {
       density = threePointShaper(newDensity, sample_t(10.0), sample_t(2.0), sample_t(1.0));
       transReflectFBGain = threePointShaper(length, sample_t(0.13), sample_t(0.25), sample_t(0.2))/density;
       transverseReflectionFilter.setFeedback(transReflectFBGain);
       diffusionFilterBankFBGain = 0.65/density;

       for (int i = 0; i < numberOfDiffFilters; ++i) {
           diffusionFilterBank[i].setFeedback(diffusionFilterBankFBGain);
       }
   }

   sample_t ShatteringFilter::generateSample(sample_t input) {
       transverseReflectionFilter.generateSample(input);
       sample_t dampFilterOut = dampingFilter.generateSample(transverseReflectionFilter.out);

       /* Smoothing input */
       sample_t inSmoothed = inSmoother_out*(1-smoothing) + input*smoothing;
       inSmoother_out = (inSmoothed-inSmoother_out)*0.000226757 + inSmoother_out;

       /* Diffusion */

       diffusionFilterBank[0].generateSample(dampFilterOut);
       diffusionFilterBank[1].generateSample(diffusionFilterBank[0].out);
       diffusionFilterBank[2].generateSample(diffusionFilterBank[1].out);

       /* Longitudinal */

       sample_t longitFBGain = -0.25*inSmoother_out + 0.58/density;

       longitudinalFilter.setFeedback(longitFBGain);
       longitudinalFilter.generateSample(diffusionFilterBank[2].out);

       /* Reflection */

       sample_t reflectDelayTime = longitDelayTime*1.0472 + frc*inSmoother_out;

       // Diffusion is the same for longitudinal and reflection filters
       reflectionFilter.setDelayTime(reflectDelayTime);
       reflectionFilter.setFeedback(longitFBGain);
       reflectionFilter.generateSample(longitudinalFilter.out);

       output = reflectionFilter.out * feedback;

       return output;
   }
} /* ataudiopocessing */
