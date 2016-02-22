//
//  TwoPoleSVF.h
//  AUSpringReverb
//
//  Created by Aliaksandr Tsurko on 07.01.16.
//  Copyright © 2016 Aliaksandr Tsurko. All rights reserved.
//

#ifndef TwoPoleSVF_h
#define TwoPoleSVF_h
#include "../Globals.hpp"

namespace ataudioprocessing {
    class TwoPoleSVFS: public Generator {
    public:
        
        sample_t out = 0.0;
        
        void init(sample_t sampleRate, int chnum, int blockSize);
        
        void setParameters(FilterType newType, sample_t newFreq, sample_t newResonance);
        
        sample_t generateSample(sample_t input);
        
    private:
        sample_t lp_out = 0.0;
        sample_t hp_out = 0.0;
        sample_t bp_out = 0.0;
        
        FilterType previousType = LP;
        FilterType testType = LP;
        sample_t fade = 0.0;
        
        sample_t cutoff = 0.0; // don't set it directly! use setParameters instead
        sample_t D = 0.0; // calculates from cutoff
        
        FilterType type = LP;
        sample_t frequency = 20000.0;
        sample_t resonance = 0.0;
    };
}

#endif /* TwoPoleSVF_h */
