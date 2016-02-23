//
//  LFO.hpp
//
//  Created by Ales Tsurko on 23.02.16.
//  Copyright © 2016 Aliaksandr Tsurko. All rights reserved.
//

#ifndef LFO_hpp
#define LFO_hpp

#include <stdio.h>
#include "../Globals.hpp"

namespace ataudioprocessing {
    class LFO : public Generator {
    public:
        sample_t output;
        
        sample_t generateCRSample(LFOType type,
                                  sample_t frequency,
                                  sample_t amount);
        
    private:
        void generateSawSample(sample_t phase,
                               sample_t amount);
        
        void generateTriSample(sample_t phase,
                               sample_t amount);
        
        void generateSquareSample(sample_t phase,
                                  sample_t amount);
        
        void generateSinSample(sample_t phase,
                               sample_t amount);
        
        sample_t phase;
    };
}

#endif /* LFO_hpp */
