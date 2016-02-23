//
//  FMSVFilter.mm
//
//  Created by Aliaksandr Tsurko on 12.01.16.
//  Copyright © 2016 Aliaksandr Tsurko. All rights reserved.
//

#import "Accelerate/Accelerate.h"
#include "FMSVF.hpp"

namespace ataudioprocessing {
   void FMSVF::init(sample_t sampleRate, int chnum, int blockSize) {
      Generator::init(sampleRate, chnum, blockSize);

      output.resize(blockSize);
   }
   
   sample_vec_t FMSVF::calculateBlock(sample_vec_t input,
      sample_t freq,
      sample_t res,
      sample_t lfoFreq,
      sample_t lfoAmount,
      FilterType filterType) {

         frequency = freq;
         resonance = 1.0 - res;
         lfo_frequency = lfoFreq;
         lfo_incr = lfo_frequency / sr;
         lfo_amount = lfoAmount;
         type = filterType;

         sample_t phaseArr[calculationBlockSize];
         sample_t lfo[calculationBlockSize];
         sample_t frequencyModulation[calculationBlockSize];
         sample_t cutoff[calculationBlockSize];
         sample_t D[calculationBlockSize];

         sample_t ones[calculationBlockSize];
         sample_t phaseMax = 1.0;

         vDSP_vfill(&phaseMax, ones, 1, calculationBlockSize);
         vDSP_vramp(&lfo_phase, &lfo_incr, phaseArr, 1, calculationBlockSize);
         vvfmodf(phaseArr, phaseArr, ones, &calculationBlockSize);

         lfo_phase = phaseArr[calculationBlockSize-1]+lfo_incr;

         vDSP_vsmul(phaseArr, 1, &twopi, phaseArr, 1, calculationBlockSize);

         vvsinf(lfo, phaseArr, &calculationBlockSize);

         float modMultiplier = frequency * 0.5 * lfo_amount;
         vDSP_vsmsa(lfo, 1, &modMultiplier, &frequency, frequencyModulation, 1, calculationBlockSize);

         modMultiplier = M_PI/sr;

         vDSP_vsmul(frequencyModulation, 1, &modMultiplier, cutoff, 1, calculationBlockSize);
         float lowestValue = 0.0;
         float highestValue = 1.50845;

         vDSP_vclip(cutoff, 1, &lowestValue, &highestValue, cutoff, 1, calculationBlockSize);
         vvtanf(cutoff, cutoff, &calculationBlockSize);

         float twoRes = resonance * 2;

         vDSP_vsadd(cutoff, 1, &twoRes, D, 1, calculationBlockSize);

         for (int frameIndex = 0; frameIndex < calculationBlockSize; ++frameIndex) {
            float prev_out, curr_out;

            hp_out = (input[frameIndex] - lp_out - bp_out*D[frameIndex]) / (D[frameIndex]*cutoff[frameIndex] + 1);
            bp_out += hp_out*cutoff[frameIndex];
            lp_out += bp_out*cutoff[frameIndex];

            if (testType != type) {
               fade = 0.0;
               previousType = testType;
            }

            switch (previousType) {
               case LP:
               prev_out = lp_out;
               break;

               case HP:
               prev_out = hp_out;
               break;

               case BP:
               prev_out = bp_out;
               break;
            }

            switch (type) {
               case LP:
               curr_out = lp_out;
               break;

               case HP:
               curr_out = hp_out;
               break;

               case BP:
               curr_out = bp_out;
               break;
            }

            if (fade < 0.999) fade = fade*0.999 + 0.001;

            output[frameIndex] = prev_out * (1.0 - fade) + curr_out*fade;
         }

         testType = type;
         return output;
      }
   } /* ataudioprocessing */
