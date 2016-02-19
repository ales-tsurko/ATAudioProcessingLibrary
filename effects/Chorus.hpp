//
//  Chorus.hpp
//
//  Created by Aliaksandr Tsurko on 21.01.16.
//  Copyright © 2016 Aliaksandr Tsurko. All rights reserved.
//

#ifndef Chorus_hpp
#define Chorus_hpp

#import "../Globals.hpp"
#import "../generators/TriLFOStereo.hpp"
#import "../delay/SingleDelay.hpp"

namespace ataudioprocessing {
   class Chorus : public Generator {
   public:
       multich_sample_vec_t output;

       multich_sample_vec_t calculateBlock(multich_sample_vec_t input,
                                           sample_t rate,
                                           sample_t delay,
                                           sample_t depth,
                                           sample_t spread,
                                           sample_t drywet);

       void init(sample_t sampleRate, int chnum, int blockSize);

   private:
       TriLFOStereo lfo;
       SingleDelay delays[2];
       sample_t modulatedDelayTime[2];
   };
}

#endif /* Chorus_hpp */
