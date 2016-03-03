//
//  FIRLP.mm
//
//  Created by Ales Tsurko on 16.02.16.
//  Copyright © 2016 Aliaksandr Tsurko. All rights reserved.
//

#include "FIRLP.hpp"
#import <Accelerate/Accelerate.h>


namespace ataudioprocessing {
   void FIRLP::init(sample_t sampleRate,
                    int chnum,
                    int blockSize,
                    sample_t cutoff,
                    int kernelSize) {

       Generator::init(sampleRate, chnum, blockSize);

       filterKernelSize = kernelSize;

       output.resize(calculationBlockSize);
       filterKernel.resize(kernelSize);

       ringBufSize = (1<<int(ceil(log2(kernelSize+blockSize))))-1;
       ringBuf.resize(ringBufSize);

       cutoffRatio = cutoff / sampleRate;

       // SINC
       sample_t sinc[kernelSize];
       int halfSize = kernelSize/2;

       for (int i = 0; i < kernelSize; ++i) {
           if (i - halfSize != 0) {
               sample_t incr = twopi * cutoffRatio * sample_t(i-halfSize);
               sinc[i] = sinf(incr) / sample_t(i-halfSize);
           } else {
               sinc[i] = twopi * cutoffRatio;
           }
       }

       // WINDOWING
       sample_t hammw[kernelSize];
       vDSP_hamm_window(hammw, kernelSize, 0);

       // apply window to sinc
       vDSP_vmul(sinc, 1, hammw, 1, &filterKernel[0], 1, kernelSize);

       // NORMALIZE GAIN
       sample_t sum;
       vDSP_sve(&filterKernel[0], 1, &sum, kernelSize);
       vDSP_vsdiv(&filterKernel[0], 1, &sum, &filterKernel[0], 1, kernelSize);
   }

   sample_vec_t FIRLP::calculateBlock(sample_vec_t input) {

       for (int frameIndex = 0; frameIndex < calculationBlockSize; ++frameIndex) {
           ringBuf[(ringBufIndexOffset+frameIndex)&ringBufSize] = input[frameIndex];
       }

       // convolution
       size_t convinpsize = calculationBlockSize+filterKernelSize;
       sample_t convinp[convinpsize];

       for (int frameIndex = 0; frameIndex < convinpsize; ++frameIndex) {
           convinp[frameIndex] = ringBuf[(ringBufIndexOffset-filterKernelSize+frameIndex+1)&ringBufSize];
       }

       vDSP_conv(convinp, 1, &filterKernel[filterKernelSize-1], -1, &output[0], 1, calculationBlockSize, filterKernelSize);

       ringBufIndexOffset+=calculationBlockSize;

       return output;
   }   
}
