//
//  BiquadSVF.hpp
//
//  Created by Ales Tsurko on 04.03.16.
//  Copyright © 2016 Aliaksandr Tsurko. All rights reserved.
//

#ifndef BiquadSVF_hpp
#define BiquadSVF_hpp

#import "../Globals.hpp"
#import <Accelerate/Accelerate.h>
#import <vector>

namespace ataudioprocessing {
    typedef enum {
        BiquadOnePoleLP,
        BiquadOnePoleHP,
        BiquadLP,
        BiquadHP,
        BiquadBP,
        BiquadNotch,
        BiquadPeak,
        BiquadLowShelf,
        BiquadHighShelf
    } BiquadSVFType;
    
    class BiquadSVF: public Generator {
        std::vector<double> coeffs;
        
    public:
        
        void init(sample_t sampleRate,
                  int chnum,
                  int blockSize);
        
        // Coefficients calculation
        void setParameters(BiquadSVFType filterType,
                                   sample_t frequency,
                                   sample_t q,
                                   sample_t gain);
        
        sample_vec_t calculateBlock(sample_t *input);
        
        std::vector<double> getCoefficients() {
            return coeffs;
        }
    };
}

#endif /* BiquadSVF_hpp */