//
//  TwoPoleSVF.cpp
//  AUSpringReverb
//
//  Created by Aliaksandr Tsurko on 07.01.16.
//  Copyright © 2016 Aliaksandr Tsurko. All rights reserved.
//

#include <stdio.h>
#include "TwoPoleSVF.hpp"

namespace ataudioprocessing {
    void TwoPoleSVF::init(sample_t sampleRate, int chnum, int blockSize) {
        Generator::init(sampleRate, chnum, blockSize);
        setParameters(LP, 250.0, 0.1);
    }
    
    void TwoPoleSVF::setParameters(FilterType newType, sample_t newFreq, sample_t newResonance) {
        type = newType;
        frequency = newFreq;
        resonance = 1.0-newResonance;
        
        cutoff = tanf(fmin((M_PI / sr) * frequency, 1.50845));
        sample_t twoRes = resonance * 2;
        D = twoRes + cutoff;
    }
    
    sample_t TwoPoleSVF::generateSample(sample_t input) {
        hp_out = (input - (lp_out + bp_out*D)) / (D*cutoff + 1);
        bp_out += hp_out*cutoff;
        lp_out += bp_out*cutoff;
        
        float prev_out, curr_out;
        
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
        
        out = prev_out * (1.0 - fade) + curr_out*fade;
        
        testType = type;
        
        return out;
    }
}