//
//  SpringReverbUGen.mm
//
//  Created by Aliaksandr Tsurko on 22.12.15.
//  Copyright © 2015 Aliaksandr Tsurko. All rights reserved.
//

#import "SpringReverb.hpp"

namespace ataudioprocessing {
   void SpringReverbUGen::init(sample_t sr, int chnum, int blockSize) {
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

       output.resize(calculationBlockSize);

       if (sr == 44100) {
           double tempArr[] =
           {
               // LS: 186 Hz, 10.6 dB
               1.0158749924647352, -1.9617036847175415, 0.9481644143239139,
               -1.9625268855267364, 0.9632162059794545,
               // LS: 224 Hz, -21.2 dB
               0.9475874183067349, -1.852413399312816, 0.9057697612042064,
               -1.8474672661500053, 0.8583033126737517,
               // Peak: 711 Hz, 4.7 dB, q: 2.6
               1.0136952088305418, -1.9517895238889746, 0.9481517090338248,
               -1.9517895238889746, 0.9618469178643667,
               // HS: 7994 Hz, 20.9 dB
               6.2700242953076035, -9.227127877550974, 3.6652470882682673,
               -0.5097415520432348, 0.21788505806813324,
               // LP: 6900 Hz, q: 0.751
               0.14334659416296255, 0.2866931883259251, 0.14334659416296255,
               -0.7135581464149591, 0.2869445230668091
           };
           memcpy(correctionEQCoeffs, tempArr, sizeof(double) * 25);

       } else if (sr == 48000) {
           double tempArr[] =
           {
               // LS: 186 Hz, 10.6 dB
               1.014576464145353, -1.9648750615052122, 0.9522731520484237,
               -1.965570972648722, 0.9661537050502668,
               // LS: 224 Hz, -21.2 dB
               0.9517329385475987, -1.8640059380012302, 0.9130745782090185,
               -1.859805049624361, 0.8690084051334861,
               // Peak: 711 Hz, 4.7 dB, q: 2.6
               1.012605309455968, -1.9563795019276446, 0.9522779272314428,
               -1.9563795019276446, 0.9648832366874106,
               // HS: 7994 Hz, 20.9 dB
               6.581983020309701, -10.0154452469018, 4.052929582719251,
               -0.6211546528730335, 0.24062200900018385,
               // LP: 6900 Hz, q: 0.751
               0.12506375492012178, 0.25012750984024357, 0.12506375492012178,
               -0.813074130050981, 0.31332914973146814
           };
           memcpy(correctionEQCoeffs, tempArr, sizeof(double) * 25);

       } else if (sr == 88200) {
           double tempArr[] =
           {
               // LS: 186 Hz, 10.6 dB
               1.0079079945479108, -1.9810541314971244, 0.9737355124891006,
               -1.9812618507405038, 0.981435787793632,
               // LS: 224 Hz, -21.2 dB
               0.9734179255554328, -1.924869621641347, 0.9516967919631796,
               -1.9235851309844976, 0.9263992081754615,
               // Peak: 711 Hz, 4.7 dB, q: 2.6
               1.0069223397355174, -1.9781750965856655, 0.9737929162516012,
               -1.9781750965856655, 0.9807152559871185,
               // HS: 7994 Hz, 20.9 dB
               8.372904289182472, -14.678728074397567, 6.534333620330828,
               -1.2194377329064168, 0.44794756802215,
               // LP: 6900 Hz, q: 0.751
               0.04504273508830321, 0.09008547017660642, 0.04504273508830321,
               -1.3416233208909372, 0.5217942612441501

           };
           memcpy(correctionEQCoeffs, tempArr, sizeof(double) * 25);

       } else if (sr == 96000) {
           double tempArr[] =
           {
               // LS: 186 Hz, 10.6 dB
               1.0072632273751065, -1.9826087795377407, 0.9758434215708557,
               -1.9827842484022906, 0.9829311800814126,
               // LS: 224 Hz, -21.2 dB
               0.9755499532641314, -1.9308741001448992, 0.9555316746246918,
               -1.929786495363125, 0.9321692326705973,
               // Peak: 711 Hz, 4.7 dB, q: 2.6
               1.006365306744916, -1.9801211740086908, 0.9759017711753795,
               -1.9801211740086908, 0.9822670779202954,
               // HS: 7994 Hz, 20.9 dB
               8.566683098785477, -15.196694611337648, 6.827716440827543,
               -1.280149913576492, 0.4778548418518613,
               // LP: 6900 Hz, q: 0.751
               0.03884063132645234, 0.07768126265290468, 0.03884063132645234,
               -1.3943618244174234, 0.5497243497232326
           };
           memcpy(correctionEQCoeffs, tempArr, sizeof(double) * 25);

       } else if (sr == 192000) {
           double tempArr[] =
           {
               // LS: 186 Hz, 10.6 dB
               1.0036252159990904, -1.9913479115065316, 0.987847697411234,
               -1.9913919671198366, 0.9914288577970192,
               // LS: 224 Hz, -21.2 dB
               0.9876969609146508, -1.9651548282093587, 0.9775106667955403,
               -1.9648781182693065, 0.9654843376502433,
               // Peak: 711 Hz, 4.7 dB, q: 2.6
               1.0031976873147697, -1.9905527191608154, 0.9878939690247527,
               -1.9905527191608154, 0.9910916563395223,
               // HS: 7994 Hz, 20.9 dB
               9.74667603756897, -18.406026149784022, 8.71687651203807,
               -1.63326420064161, 0.6907906004646261,
               // LP: 6900 Hz, q: 0.751
               0.011046043068701536, 0.022092086137403072, 0.011046043068701536,
               -1.696369048270059, 0.7405532205448653
           };
           memcpy(correctionEQCoeffs, tempArr, sizeof(double) * 25);

       } else {
           printf("Unsupported sample rate\n");
       }

   }

   sample_vec_t SpringReverbUGen::calculateBlock(sample_t *input,
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
       vDSP_vsmul(input, 1, &dryMul, dry, 1, calculationBlockSize);
       vDSP_vsmul(wet, 1, &wetMul, wet, 1, calculationBlockSize);

       sample_t outputMul = 0.5;
       vDSP_vasm(dry, 1, wet, 1, &outputMul, &output[0], 1, calculationBlockSize);

       return output;
   }
} /* ataudioprocessing */
