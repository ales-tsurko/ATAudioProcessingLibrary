A ready-to-use collection of high performance unit generators and utility functions for DSP programming.

Depends on Apple's Accelerate framework, so apple platforms only.

## Content
### Ugens
#### Delay
SingleDelay

#### Distortion
SaturatedAmp

#### Effects
Chorus

SpringReverb

#### Filters
AllpassFilter

FIRLP

SVF

OnePoleLPHP

TwoPoleSVFS

BiquadSVF

#### Generators
ParabolicWM

TriLFOStereo

LFO

### Utility
midiToFreq(noteNumber)
 
frequencyToMIDI(freq)
    
clamp(input, low, high)
    
threePointShaper(in, start, mid, end)
    
twoPointShaper(in, outStart, outEnd)

linearToLog(input, minIn, maxIn, minOut, maxOut)
    
dBToAmp(input)

## Usage
Link `Accelerate.framework`, then include `ATAudioProcessing.hpp`.

Use the `.calculateBlock` method, then copy the `.output` into buffer.


The example of a process function will look like this:


```cpp
// The code looks complex, but it's calculated per vectorized block, 
// so it quite outperforms the sample-by-sample approach.

// ParabolicWM oscillator;
// oscillator.init(sampleRate, channelCount, calculationBlockSize, oversamplingFactor);

void process(AUAudioFrameCount frameCount, AUAudioFrameCount bufferOffset) override {
    AudioBuffer *out = outBufferListPtr->mBuffers;
    
    for (int frameOffset = 0; frameOffset < frameCount; frameOffset+=calculationBlockSize) {
        //
        // Fill the rest of the output from the previous iteration
        // (to prevent problems, which may occur with variable framerate)
        //
        
        if (frameCount - frameOffset < preGenWriteIndex) {
            preGenWriteIndex = frameCount - frameOffset;
        }
        
        if (preGenWriteIndex != 0) {
            for (int channel = 0; channel < numberOfChannels; ++channel) {
                sample_t *outChannel = (sample_t *)out[channel].mData;
                memcpy(outChannel+frameOffset, &oscillator.output[channel][postGenWriteIndex],
                       preGenWriteIndex*sizeof(sample_t));
            }
        }
        
        if (preGenWriteIndex + frameOffset == frameCount) {
            postGenWriteIndex += preGenWriteIndex;
            break;
        }

        //
        // block calculation
        // put here your DSP part
        //
        oscillator.calculateBlock(440, 0.5, 1);
        
        //
        // copying to the output
        //
        if (frameCount - frameOffset < calculationBlockSize) {
            postGenWriteIndex = frameCount - frameOffset - preGenWriteIndex;
        }

        for (int channel = 0; channel < numberOfChannels; ++channel) {
            sample_t *outChannel = (sample_t *)out[channel].mData;
            memcpy(outChannel+frameOffset+preGenWriteIndex, &oscillator.output[channel][0],
                postGenWriteIndex*sizeof(sample_t));
        }
    }
    
    preGenWriteIndex = calculationBlockSize - postGenWriteIndex;
}

```
