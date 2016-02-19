//
//  ParabolicWM.hpp
//
//  Created by Aliaksandr Tsurko on 13.01.16.
//  Copyright © 2016 Aliaksandr Tsurko. All rights reserved.
//

#ifndef ParabolicWM_hpp
#define ParabolicWM_hpp

#include <stdio.h>
#include <math.h>
#include <vector>
#import <algorithm>
#import "../Globals.hpp"
#import "../filters/FIRLP.hpp"

namespace ataudioprocessing {
   class ParabolicWM : public Generator {
   public:
       sample_vec_t output;

       void init(sample_t sampleRate, int chnum, int blockSize, int oversamplingFactor);

       sample_vec_t calculateBlock(sample_t frequency, sample_t width, sample_t amplitude);

   private:
       int oversmplFactor;
       sample_t zphase = 0.0;
       sample_vec_t oversampledOutput;
       int oversampledBlockSize;

       sample_vec_t phase;

       FIRLP decimationFilter;
   };   
}

#endif /* ParabolicWM_hpp */