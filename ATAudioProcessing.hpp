// Copyright 2016 Aliaksandr Tsurko

#include "Globals.hpp"
/* Delay */
#include "delay/SingleDelay.hpp"
/* Distortion */
#include "distortion/SaturatedAmp.hpp"
/* Effects */
#include "effects/Chorus.hpp"
#include "effects/springreverb/SpringReverb.hpp"
/* Filters */
#include "filters/AllpassFilter.hpp"
#include "filters/FIRLP.hpp"
#include "filters/FMSVF.hpp"
#include "filters/OnePoleLPHP.hpp"
#include "filters/TwoPoleSVF.hpp"
/* Generators */
#include "generators/ParabolicWM.hpp"
#include "generators/TriLFOStereo.hpp"