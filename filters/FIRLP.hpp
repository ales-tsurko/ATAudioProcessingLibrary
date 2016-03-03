//
//  FIRLP.hpp
//
//  Created by Ales Tsurko on 16.02.16.
//  Copyright © 2016 Aliaksandr Tsurko. All rights reserved.
//

#ifndef FIRLP_hpp
#define FIRLP_hpp

#include <stdio.h>
#include "../Globals.hpp"

// using namespace amp;

namespace ataudioprocessing {
   class FIRLP : public Generator {
   public:
      sample_vec_t output;

      void init(sample_t sampleRate,
         int chnum,
         int blockSize,
         sample_t cutoff,
         int kernelSize);

         sample_vec_t calculateBlock(sample_vec_t input);

   private:
         sample_t cutoffRatio;
         sample_vec_t filterKernel;
         int filterKernelSize;
         sample_vec_t ringBuf;
         size_t ringBufSize;
         int ringBufIndexOffset;
   };
}


#endif /* FIRLP_hpp */
