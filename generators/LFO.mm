//
//  LFO.mm
//
//  Created by Ales Tsurko on 23.02.16.
//  Copyright © 2016 Aliaksandr Tsurko. All rights reserved.
//

#include "LFO.hpp"

namespace ataudioprocessing {
    
    sample_t LFO::generateCRSample(LFOType type,
                                   sample_t frequency,
                                   sample_t amount) {
        
        sample_t incr = frequency / sr * calculationBlockSize;
        phase = fmodf(phase + incr, 1.0);
        
        switch (type) {
            case Saw:
                generateSawSample(phase, amount);
                break;
                
            case Tri:
                generateTriSample(phase, amount);
                break;
                
            case Square:
                generateSquareSample(phase, amount);
                break;
                
            case Sin:
                generateSinSample(phase, amount);
                break;
                
            default:
                break;
        }
        
        return output;
    }
    
    void LFO::generateSawSample(sample_t phase,
                                sample_t amount) {
        output = (phase * 2.0 - 1.0) * amount;
    }
    
    void LFO::generateTriSample(sample_t phase,
                                sample_t amount) {
        output = (fabs(phase * 4.0 - 2.0) - 1.0) * amount;
    }
    
    void LFO::generateSquareSample(sample_t phase,
                                   sample_t amount) {
        output = phase < 0.5 ? 1.0 : -1.0;
        output *= amount;
    }
    
    void LFO::generateSinSample(sample_t phase,
                                sample_t amount) {
        output = sinf(phase*twopi)*amount;
    }
}