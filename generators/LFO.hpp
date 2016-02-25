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
        sample_vec_t calculateBlock(LFOType type,
                                    sample_t frequency,
                                    sample_t amplitude,
                                    sample_t add);
        
    private:
        void generateSawSample(sample_t phase,
                               sample_t amplitude,
                               sample_t add);
        
        void generateTriSample(sample_t phase,
                               sample_t amplitude,
                               sample_t add);
        
        void generateSquareSample(sample_t phase,
                                  sample_t amplitude,
                                  sample_t add);
        
        void generateSinSample(sample_t phase,
                               sample_t amplitude,
                               sample_t add);
        
        sample_t phase;
        sample_t croutput;
        Smoother smoother;
    };
}

#endif /* LFO_hpp */
