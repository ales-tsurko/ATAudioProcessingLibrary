//
//  FMSVF.hpp
//
//  Created by Aliaksandr Tsurko on 12.01.16.
//  Copyright © 2016 Aliaksandr Tsurko. All rights reserved.
//

#ifndef FMSVF_hpp
#define FMSVF_hpp

#include <stdio.h>
#include <math.h>
#include <vector>
#include "../Globals.hpp"

namespace ataudioprocessing {
   // MARK: Filter definition

   class FMSVF : public Generator {
   public:
      sample_vec_t output;

      void init(sample_t sampleRate, int chnum, int blockSize);

      sample_vec_t calculateBlock(sample_vec_t input,
         sample_t freq,
         sample_t res,
         sample_t lfoFreq,
         sample_t lfoAmount,
         FilterType filterType);

   private:
      sample_t lp_out = 0.0;
      sample_t hp_out = 0.0;
      sample_t bp_out = 0.0;

      FilterType type = LP;
      sample_t frequency = 20000.0;
      sample_t resonance = 0.0;
      sample_t lfo_frequency = 10.0;
      sample_t lfo_amount = 0.0;

      sample_t lfo_incr = 0.0;
      sample_t lfo_phase = 0.0;
      sample_t lfo_output = 0.0;

      FilterType previousType = LP;
      FilterType testType = LP;
      sample_t fade = 0.0;
   };
} /* ataudioprocessing */

#endif /* FMSVFilter_hpp */
