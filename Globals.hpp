//
//  Globals.h
//  AUSpringReverb
//
//  Created by Aliaksandr Tsurko on 22.12.15.
//  Copyright © 2015 Aliaksandr Tsurko. All rights reserved.
//

#ifndef Globals_h
#define Globals_h

#import <AVFoundation/AVFoundation.h>
#include <math.h>
#include <algorithm>
#include <vector>

namespace ataudioprocessing {
    typedef float sample_t;
    typedef std::vector<sample_t> sample_vec_t;
    typedef std::vector<std::vector<sample_t>> multich_sample_vec_t;
    
    const sample_t twopi = 2.0 * M_PI;
    
    typedef enum {
        LP, HP, BP
    } FilterType;
    
    typedef enum {
        Saw, Tri, Square, Sin
    } LFOType;
    
    template <typename T>
    inline T midiToFreq(T noteNumber) {
        return T(pow(2, (noteNumber-69.0) * 0.083333333333) * 440.0);
    }
    
    template <typename T>
    inline T frequencyToMIDI(T freq) {
        return T(12.0*log2(freq/440.0) + 69.0);
    }
    
    template <typename T>
    inline T clamp(T input, T low, T high) {
        return std::min(std::max(input, low), high);
    }
    
    template <typename T>
    inline T threePointShaper(T in, T start, T mid, T end) {
        T value = clamp(in, T(0.0), T(1.0));
        T fhalf = 2*value*(mid-start) + start;
        T shalf = 2*value*(end-mid) + 2*mid - end;
        return value < 0.5 ? fhalf : shalf;
    }
    
    template <typename T>
    inline T twoPointShaper(T in, T outStart, T outEnd) {
        return clamp(in, T(0.0), T(1.0))*(outEnd-outStart) + outStart;
    }
    
    template <typename T>
    inline T linearToLog(T input, T minIn, T maxIn, T minOut, T maxOut) {
        if (input <= minIn) return minOut;
        if (input >= maxIn) return maxOut;
        return pow(maxOut/minOut, (input-minIn)/(maxIn-minIn)) * minOut;
    }
    
    template <typename T>
    inline T dBToAmp(T input) {
        return pow((T)10.0, input * (T)0.05);;
    }
    
    typedef struct Smoother {
        sample_t output;
        
        void setAmount(sample_t amount) {
            smoothing = 1.0 - clamp(amount, 0.0f, 1.0f);
        }
        
        sample_t smooth(sample_t input) {
            output = output * (1.0 - smoothing) + input * smoothing;
            return output;
        }
    private:
        sample_t smoothing = 0.1;
    } Smoother;
    
    //===============
    // Base objects
    //===============
    
    class Generator {
    public:
        sample_vec_t output;
        
        void init(sample_t sampleRate, int chnum, int blockSize) {
            sr = sampleRate;
            numberOfChannels = chnum;
            calculationBlockSize = blockSize;
            output.resize(blockSize);
        }
        
    protected:
        sample_t sr;
        int calculationBlockSize;
        int numberOfChannels;
    };
}

#endif /* Globals_h */
