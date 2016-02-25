//
//  SVF.mm
//
//  Created by Aliaksandr Tsurko on 12.01.16.
//  Copyright © 2016 Aliaksandr Tsurko. All rights reserved.
//

#import "Accelerate/Accelerate.h"
#include "SVF.hpp"

namespace ataudioprocessing {
    sample_vec_t SVF::calculateBlock(sample_vec_t input,
                                     sample_t frequency,
                                     sample_t resonance,
                                     FilterType type) {
        
        sample_t res = 1.0 - resonance;
        sample_t cutoff = tanf(fmin((M_PI / sr) * frequency, 1.50845));
        sample_t twoRes = res * 2;
        sample_t D = twoRes + cutoff;
        
        for (int frameIndex = 0; frameIndex < calculationBlockSize; ++frameIndex) {
            sample_t prev_out, curr_out;
            
            hp_out = (input[frameIndex] - lp_out - bp_out*D) / (D*cutoff + 1);
            bp_out += hp_out*cutoff;
            lp_out += bp_out*cutoff;
            
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
    
    sample_vec_t SVF::calculateBlock(sample_vec_t input,
                                     sample_vec_t frequency,
                                     sample_vec_t resonance,
                                     FilterType type) {
        
        sample_t res[calculationBlockSize];
        sample_t cutoff[calculationBlockSize];
        sample_t twoRes[calculationBlockSize];
        sample_t D[calculationBlockSize];
        
        for (int frameIndex = 0; frameIndex < calculationBlockSize; ++frameIndex) {
            res[frameIndex] = 1.0 - resonance[frameIndex];
        }
        
        sample_t angf = M_PI/sr;
        
        vDSP_vsmul(&frequency[0], 1, &angf, cutoff, 1, calculationBlockSize);
        
        sample_t low = 0.0;
        sample_t high = 1.50845;
        vDSP_vclip(cutoff, 1, &low, &high, cutoff, 1, calculationBlockSize);
        
        vvtanf(cutoff, cutoff, &calculationBlockSize);
        
        sample_t mul = 2.0;
        vDSP_vsmul(res, 1, &mul, twoRes, 1, calculationBlockSize);
        
        vDSP_vadd(twoRes, 1, cutoff, 1, D, 1, calculationBlockSize);
        
        for (int frameIndex = 0; frameIndex < calculationBlockSize; ++frameIndex) {
            sample_t prev_out, curr_out;
            
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
