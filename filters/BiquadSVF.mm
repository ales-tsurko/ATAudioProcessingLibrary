//
//  BiquadSVF.mm
//
//  Created by Ales Tsurko on 04.03.16.
//  Copyright © 2016 Aliaksandr Tsurko. All rights reserved.
//

#include "BiquadSVF.hpp"
#import <math.h>

namespace ataudioprocessing {
    void BiquadSVF::init(sample_t sampleRate,
                         int chnum,
                         int blockSize) {
        Generator::init(sampleRate, chnum, blockSize);
        
        coeffs.resize(5);
        setParameters(BiquadLP, 440, 0.5, 0.0);
    }
    
    void BiquadSVF::setParameters(BiquadSVFType filterType,
                                  sample_t frequency,
                                  sample_t Q,
                                  sample_t gain) {
        
        double a0, a1, a2, b1, b2, norm;
        double sqrt2 = 1.414213562;
        double V = pow(10, std::abs(gain)/20);
        double K = tan(M_PI * double(frequency/sr));
        
        switch (filterType) {
            case BiquadOnePoleLP:
                b1 = exp(-2*M_PI*double(frequency/sr));
                a0 = 1.0 - b1;
                b1 = -b1;
                a1 = 0.0;
                a2 = 0.0;
                b2 = 0.0;
                break;
                
            case BiquadOnePoleHP:
                b1 = -exp(-2.0*M_PI*(0.5 - double(frequency/sr)));
                a0 = 1.0 + b1;
                b1 = -b1;
                a1 = 0.0;
                a2 = 0.0;
                b2 = 0.0;
                break;
                
            case BiquadLP:
                norm = 1.0/(1.0 + K/Q + K*K);
                a0 = K*K*norm;
                a1 = 2.0 * a0;
                a2 = a0;
                b1 = 2.0 * norm * (K*K - 1.0);
                b2 = norm * (1.0 - K/Q + K*K);
                break;
                
            case BiquadHP:
                norm = 1.0/(1.0 + K/Q + K*K);
                a0 = norm;
                a1 = -2.0 * a0;
                a2 = a0;
                b1 = 2.0 * (K*K - 1.0) * norm;
                b2 = (1.0 - K/Q + K*K) * norm;
                break;
                
            case BiquadBP:
                norm = 1.0/(1.0 + K/Q + K*K);
                a0 = K/Q * norm;
                a1 = 0.0;
                a2 = -a0;
                b1 = 2.0 * (K*K - 1.0) * norm;
                b2 = (1.0 - K / Q + K * K) * norm;
                break;
                
            case BiquadNotch:
                norm = 1.0/(1.0 + K/Q + K*K);
                a0 = (1.0 + K*K) * norm;
                a1 = 2.0 * (K*K - 1.0) * norm;
                a2 = a0;
                b1 = a1;
                b2 = (1.0 - K/Q + K*K) * norm;
                break;
                
            case BiquadPeak:
                if (gain >= 0) {
                    norm = 1.0/(1.0 + 1.0/Q * K + K*K);
                    a0 = (1.0 + V/Q * K + K*K) * norm;
                    a1 = 2.0 * (K*K - 1.0) * norm;
                    a2 = (1.0 - V/Q * K + K*K) * norm;
                    b1 = a1;
                    b2 = (1.0 - 1.0/Q * K + K*K) * norm;
                } else {
                    norm = 1.0/(1.0 + V/Q * K + K*K);
                    a0 = (1.0 + 1.0/Q * K + K*K) * norm;
                    a1 = 2.0 * (K*K - 1.0) * norm;
                    a2 = (1.0 - 1.0/Q * K + K*K) * norm;
                    b1 = a1;
                    b2 = (1.0 - V/Q * K + K*K) * norm;
                }
                break;
                
            case BiquadLowShelf:
                if (gain >= 0) {
                    norm = 1.0/(1.0 + sqrt2*K + K*K);
                    a0 = (1.0 + sqrtf(2.0*V)*K + V*K*K) * norm;
                    a1 = 2.0 * (V*K*K - 1.0) * norm;
                    a2 = (1.0 - sqrt(2.0*V)*K + V*K*K) * norm;
                    b1 = 2.0 * (K*K - 1.0) * norm;
                    b2 = (1.0 - sqrt2*K + K*K) * norm;
                } else {
                    norm = 1.0 / (1.0 + sqrt(2.0*V)*K + V*K*K);
                    a0 = (1.0 + sqrt2*K + K*K) * norm;
                    a1 = 2.0 * (K*K - 1.0) * norm;
                    a2 = (1.0 - sqrt2*K + K*K) * norm;
                    b1 = 2.0 * (V*K*K - 1.0) * norm;
                    b2 = (1.0 - sqrt(2.0*V)*K + V*K*K) * norm;
                }
                break;
                
            case BiquadHighShelf:
                if (gain >= 0) {
                    norm = 1.0/(1.0 + sqrt2*K + K*K);
                    a0 = (V + sqrt(2.0*V)*K + K*K) * norm;
                    a1 = 2.0 * (K*K - V) * norm;
                    a2 = (V - sqrt(2.0*V)*K + K*K) * norm;
                    b1 = 2.0 * (K*K - 1.0) * norm;
                    b2 = (1.0 - sqrt2*K + K*K) * norm;
                } else {
                    norm = 1.0/(V + sqrt(2.0*V)*K + K*K);
                    a0 = (1.0 + sqrt2*K + K*K) * norm;
                    a1 = 2.0 * (K*K - 1.0) * norm;
                    a2 = (1.0 - sqrt2*K + K*K) * norm;
                    b1 = 2 * (K*K - V) * norm;
                    b2 = (V - sqrt(2*V)*K + K*K) * norm;
                }
                break;
                
            default:
                NSLog(@"Unknown filter type\n");
                break;
        }
        
        coeffs[0] = a0;
        coeffs[1] = a1;
        coeffs[2] = a2;
        coeffs[3] = b1;
        coeffs[4] = b2;
    }
    
    sample_vec_t BiquadSVF::calculateBlock(sample_t *input) {
        // в документации сказано, что размер дилея должен быть 2*колСекций+2
        // Но c таким размером не работает... И при небольшом размере этого массива
        // проблемы.
        // Пока не понимаю почему. Здесь просто достаточно большой размер этого
        // массива, т. е. работает как надо.
        vDSP_biquad_Setup filterSetup = vDSP_biquad_CreateSetup(&coeffs[0], 1);
        sample_t delay[calculationBlockSize*calculationBlockSize];
        vDSP_biquad(filterSetup, delay, input, 1,
                    &output[0], 1, calculationBlockSize);
        vDSP_biquad_DestroySetup(filterSetup);
        return output;
    }
}
