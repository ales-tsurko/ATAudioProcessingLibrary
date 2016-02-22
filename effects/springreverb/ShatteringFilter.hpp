//
//  ShatteringFilter.hpp
//
//  Created by Aliaksandr Tsurko on 22.12.15.
//  Copyright © 2015 Aliaksandr Tsurko. All rights reserved.
//

#ifndef ShatteringFilter_hpp
#define ShatteringFilter_hpp

#include <stdio.h>
#include <math.h>
#include <vector>
#include "../../Globals.hpp"
#include "../../filters/TwoPoleSVFS.hpp"
#include "../../filters/AllpassFilter.hpp"

namespace ataudioprocessing {
   class ShatteringFilter : public Generator {
   public:
       sample_t output;
       sample_t out_lng;

       void init(sample_t sampleRate, int chnum, int blockSize);

       void setDensity(sample_t newDensity);

       void setSize(sample_t newSize);

       sample_t generateSample(sample_t input);

    private:
      sample_t length;
      sample_t lng, frc, transReflectFBGain, diffusionFilterBankFBGain, density, longitDelayTime;
      sample_t damping;
      sample_t smoothing; // 0 < value < 1
      sample_t inSmoother_out;
      sample_t feedback;
      int numberOfDiffFilters;
      std::vector<AllPassFilter> diffusionFilterBank;
      AllPassFilter transverseReflectionFilter;
      AllPassFilter longitudinalFilter;
      AllPassFilter reflectionFilter;
      TwoPoleSVFS dampingFilter;
   };
} /* ataudioprocessing */

#endif /* ShatteringFilter_hpp */
