//
//  SaturatedAmp.hpp
//
//  Created by Ales Tsurko on 28.01.16.
//  Copyright © 2016 Aliaksandr Tsurko. All rights reserved.
//

#ifndef SaturatedAmp_hpp
#define SaturatedAmp_hpp

#import "../Globals.hpp"
#import <vector>
#import "../filters/FIRLP.hpp"

namespace ataudioprocessing {
   class SaturatedAmp : public Generator {
   public:
       multich_sample_vec_t output;

       void init(sample_t sampleRate,
                 int chnum,
                 int blockSize,
                 int oversamplingFactor);

       multich_sample_vec_t calculateBlock(multich_sample_vec_t input,
                                           sample_t inputAmp,
                                           sample_t outputAmp);
   private:
       int oversmplFactor;
       std::vector<FIRLP> upsamplingFilters;
       std::vector<FIRLP> decimationFilters;
       multich_sample_vec_t oversampledBuffer;
       size_t oversampledBufSize;
   };
}

#endif /* SaturatedAmp_hpp */
