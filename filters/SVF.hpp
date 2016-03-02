//
//  SVF.hpp
//
//  Created by Aliaksandr Tsurko on 12.01.16.
//  Copyright © 2016 Aliaksandr Tsurko. All rights reserved.
//

#ifndef SVF_hpp
#define SVF_hpp

#include <stdio.h>
#include <math.h>
#include <vector>
#include "../Globals.hpp"

namespace ataudioprocessing {
    
    class SVF : public Generator {
    public:
        void init(sample_t sampleRate, int chnum, int blockSize);
        
        sample_vec_t calculateBlock(sample_vec_t input,
                                    sample_t frequency,
                                    sample_t resonance,
                                    FilterType filterType);
        
        sample_vec_t calculateBlock(sample_vec_t input,
                                    sample_vec_t frequency,
                                    sample_vec_t resonance,
                                    FilterType type);
        
    private:
        sample_t lp_out = 0.0;
        sample_t hp_out = 0.0;
        sample_t bp_out = 0.0;
        Smoother freqSmoother;
        
        FilterType previousType = LP;
        FilterType testType = LP;
        sample_t fade = 0.0;
    };
    
} /* ataudioprocessing */

#endif /* SVFilter_hpp */
