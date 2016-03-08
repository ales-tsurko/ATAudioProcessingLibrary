//
//  SpringReverbUGen.hpp
//
//  Created by Aliaksandr Tsurko on 22.12.15.
//  Copyright © 2015 Aliaksandr Tsurko. All rights reserved.
//

#ifndef SpringReverbUGen_hpp
#define SpringReverbUGen_hpp

#import <math.h>
#import "../../Globals.hpp"
#import "ShatteringFilter.hpp"
#import "../../delay/SingleDelay.hpp"
#import "../../filters/OnePoleLPHP.hpp"
#import "../../filters/BiquadSVF.hpp"
#import <vector>
#import <Accelerate/Accelerate.h>

namespace ataudioprocessing {
   class SpringReverb : public Generator {
   public:
       
       ~SpringReverb();

       void init(sample_t sr, int chnum, int blockSize);

       void setSize(sample_t newSize);

       void setDryWet(sample_t newDryWet);

       void setDensity(sample_t newDensity);

       sample_vec_t calculateBlock(sample_vec_t input,
                                   sample_t size,
                                   sample_t density,
                                   sample_t drywet);
       
   private:
       OnePoleLPHP highAttenuationFilter;
       OnePoleLPHP transducerFilter;
       ShatteringFilter shattering;
       SingleDelay delay;
       
       sample_t suspension;
       sample_t highAttenuation; // in Hz
       double correctionEQCoeffs[25];
       std::vector<BiquadSVF> correctionEQ;
       vDSP_biquad_Setup filterSetup = NULL;
   };
} /* ataudioprocessing */

#endif /* SpringReverbUGen_hpp */
