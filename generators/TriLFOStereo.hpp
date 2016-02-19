//
//  TriLFOStereo.hpp
//
//  Created by Aliaksandr Tsurko on 21.01.16.
//  Copyright © 2016 Aliaksandr Tsurko. All rights reserved.
//

#ifndef TriLFOStereo_hpp
#define TriLFOStereo_hpp

#import "../Globals.hpp"

namespace ataudioprocessing {
   class TriLFOStereo : public Generator {
   public:
       multich_sample_vec_t output;
       sample_vec_t controlOutput;

       void init(sample_t sampleRate, int chnum, int blockSize);

       multich_sample_vec_t calculateBlock(sample_t frequency,
                                           sample_t spread,
                                           sample_t amp);

       sample_vec_t generateCRFrame(sample_t frequency,
                                    sample_t spread,
                                    sample_t amp);
   private:
       sample_t phase;
   };   
}

#endif /* TriLFOStereo_hpp */
