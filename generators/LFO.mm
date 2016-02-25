//
//  LFO.mm
//
//  Created by Ales Tsurko on 23.02.16.
//  Copyright © 2016 Aliaksandr Tsurko. All rights reserved.
//

#include "LFO.hpp"

namespace ataudioprocessing {
    
    sample_vec_t LFO::calculateBlock(LFOType type,
                                     sample_t frequency,
                                     sample_t amplitude,
                                     sample_t add) {
        
        sample_t incr = frequency / sr * calculationBlockSize;
        phase = fmodf(phase + incr, 1.0);
        
        switch (type) {
            case Saw:
                generateSawSample(phase, amplitude, add);
                break;
                
            case Tri:
                generateTriSample(phase, amplitude, add);
                break;
                
            case Square:
                generateSquareSample(phase, amplitude, add);
                break;
                
            case Sin:
                generateSinSample(phase, amplitude, add);
                break;
                
            default:
                break;
        }
        
        for (int frameNumber = 0; frameNumber < calculationBlockSize; ++frameNumber) {
            output[frameNumber] = smoother.smooth(croutput);
        }
        
        return output;
    }
    
    void LFO::generateSawSample(sample_t phase,
                                sample_t amplitude,
                                sample_t add) {
        croutput = (phase * 2.0 - 1.0) * amplitude + add;
    }
    
    void LFO::generateTriSample(sample_t phase,
                                sample_t amplitude,
                                sample_t add) {
        croutput = (fabs(phase * 4.0 - 2.0) - 1.0) * amplitude + add;
    }
    
    void LFO::generateSquareSample(sample_t phase,
                                   sample_t amplitude,
                                   sample_t add) {
        croutput = phase < 0.5 ? 1.0 : -1.0;
        croutput *= amplitude + add;
    }
    
    void LFO::generateSinSample(sample_t phase,
                                sample_t amplitude,
                                sample_t add) {
        croutput = sinf(phase*twopi)*amplitude + add;
    }
}