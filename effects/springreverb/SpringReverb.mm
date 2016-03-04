//
//  SpringReverbUGen.mm
//
//  Created by Aliaksandr Tsurko on 22.12.15.
//  Copyright © 2015 Aliaksandr Tsurko. All rights reserved.
//

#import "SpringReverb.hpp"

namespace ataudioprocessing {
   void SpringReverb::init(sample_t sr, int chnum, int blockSize) {
       Generator::init(sr, chnum, blockSize);

       highAttenuation = 3767.0; // in Hz
       highAttenuationFilter.init(sr, chnum, blockSize);
       highAttenuationFilter.setFrequency(highAttenuation);

       suspension = 62.0; // in Hz
       transducerFilter.init(sr, chnum, blockSize);
       transducerFilter.setFrequency(suspension);

       shattering.init(sr, chnum, blockSize);

       delay.init(sr, chnum, blockSize);
       delay.setInterpolation(None);
       delay.setDelayTime(shattering.out_lng);
       
       int numberOfFilters = 5;
       
       correctionEQ.resize(numberOfFilters);
       
       for (int n = 0; n < numberOfFilters; ++n) {
           correctionEQ[n].init(sr, chnum, blockSize);
       }
       
       correctionEQ[0].setParameters(BiquadLowShelf, 186, 1, 10.6);
       correctionEQ[1].setParameters(BiquadLowShelf, 224, 1, -21.2);
       correctionEQ[2].setParameters(BiquadPeak, 711, 2.6, 4.7);
       correctionEQ[3].setParameters(BiquadHighShelf, 7994, 1, 20.9);
       correctionEQ[4].setParameters(BiquadLP, 6900, 0.751, 0);
       
       for (int n = 0; n < numberOfFilters; ++n) {
           memcpy(correctionEQCoeffs+n*numberOfFilters,
                  &correctionEQ[n].getCoefficients()[0],
                  numberOfFilters*sizeof(double));
       }
   }

   sample_vec_t SpringReverb::calculateBlock(sample_vec_t input,
                                                 sample_t size,
                                                 sample_t density,
                                                 sample_t drywet) {

       sample_t newSize = clamp(size, sample_t(0.0), sample_t(1.0));
       shattering.setSize(newSize);

       shattering.setDensity(density);

       sample_t wet[calculationBlockSize];

       for (int frameIndex = 0; frameIndex < calculationBlockSize; ++frameIndex) {
           highAttenuationFilter.generateSample(input[frameIndex]);
           sample_t transducerIn = highAttenuationFilter.lp_out+shattering.output;
           transducerFilter.generateSample(transducerIn);

           shattering.generateSample(transducerFilter.hp_out);

           wet[frameIndex] = delay.generateSample(shattering.output);
       }

       vDSP_biquad_Setup filterSetup = vDSP_biquad_CreateSetup(correctionEQCoeffs,
                                                               5);
       sample_t delayBuff[calculationBlockSize*calculationBlockSize*5];
       vDSP_biquad(filterSetup, delayBuff, wet, 1, wet, 1, calculationBlockSize);
       vDSP_biquad_DestroySetup(filterSetup);

       // Dry/Wet mixing
       sample_t newDryWet = clamp(drywet, sample_t(0.0), sample_t(1.0));
       sample_t dryMul = (2.0 - (1.0-newDryWet)) * (1.0-newDryWet);
       sample_t wetMul = (2.0 - newDryWet) * newDryWet;

       dryMul*=0.3;
       wetMul*=0.5;
       sample_t dry[calculationBlockSize];
       vDSP_vsmul(&input[0], 1, &dryMul, dry, 1, calculationBlockSize);
       vDSP_vsmul(wet, 1, &wetMul, wet, 1, calculationBlockSize);

       sample_t outputMul = 0.5;
       vDSP_vasm(dry, 1, wet, 1, &outputMul, &output[0], 1, calculationBlockSize);

       return output;
   }
} /* ataudioprocessing */
