//
//  OnePoleLPHP.h
//  AUSpringReverb
//
//  Created by Aliaksandr Tsurko on 05.01.16.
//  Copyright © 2016 Aliaksandr Tsurko. All rights reserved.
//

#ifndef OnePoleLPHP_h
#define OnePoleLPHP_h
#include "Globals.hpp"

/*---------------------------------------*/
/*----------OnePoleLPHP Filter-----------*/
/*---------------------------------------*/

class OnePoleLPHP: public Generator {
    sample_t freq;
    // coefficients
    sample_t a0, b1;
    
    void calculateCoefficients() {
        sample_t x = expf(-2*M_PI*freq/sr);
        a0 = 1-x;
        b1 = -x;
    }
    
public:
    sample_t lp_out = 0.0;
    sample_t hp_out = 0.0;
    
    void init(sample_t sampleRate, int chnum, int blockSize) {
        Generator::init(sampleRate, chnum, blockSize);
        
        setFrequency(1000.0);
    }
    
    void setFrequency(sample_t frequency) {
        freq = frequency;
        calculateCoefficients();
    }
    
    void generateSample(sample_t input) {
            lp_out = a0*input - b1*lp_out;
            hp_out = input - lp_out;
    }
    
};

#endif /* OnePoleLPHP_h */
