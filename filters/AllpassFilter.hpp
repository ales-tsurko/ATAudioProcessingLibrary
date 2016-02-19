//
//  AllpassFilter.h
//  AUSpringReverb
//
//  Created by Aliaksandr Tsurko on 05.01.16.
//  Copyright © 2016 Aliaksandr Tsurko. All rights reserved.
//

#ifndef AllpassFilter_h
#define AllpassFilter_h
#include "../Globals.hpp"
#include "../delay/SingleDelay.hpp"

namespace ataudioprocessing {
    class AllPassFilter: public Generator {
        SingleDelay delay;
        sample_t fbRamp = 0.0;
        sample_t feedback = 0.0;
        
    public:
        sample_t out = 0.0;
        
        void init(sample_t sampleRate, int numberOfChannels, int blockSize) {
            Generator::init(sampleRate, numberOfChannels, blockSize);
            
            delay.init(sampleRate, numberOfChannels, blockSize);
            setInterpolation(Linear);
            setDelayTime(0.1);
            setFeedback(0.1);
        }
        
        void setInterpolation(DelayInterpolationType type) {
            delay.setInterpolation(type);
        }
        
        void setDelayTime(sample_t newDelayTime) {
            delay.setDelayTime(newDelayTime);
        }
        
        void setFeedback(sample_t newFeedback) {
            feedback = newFeedback;
        }
        
        sample_t generateSample(sample_t in) {
            fbRamp = feedback*0.01 + fbRamp*0.99; // parameter smoothing
            
            sample_t delOut = delay.out;
            sample_t delIn = in + delOut*fbRamp;
            delay.generateSample(delIn);
            out = delOut - fbRamp*delIn;
            
            return out;
        }
        
    };
}

#endif /* AllpassFilter_h */
