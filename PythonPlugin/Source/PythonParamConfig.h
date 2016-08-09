/*
 ------------------------------------------------------------------
 
 Python Plugin
 Copyright (C) 2016 FP Battaglia
 
 based on
 Open Ephys GUI
 Copyright (C) 2013, 2015 Open Ephys
 
 ------------------------------------------------------------------
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 
 */
/*
  ==============================================================================

    PythonParamConfig.h
    Created: 20 Jul 2014 6:53:03pm
    Author:  Francesco Battaglia

  ==============================================================================
*/

#ifndef __PYTHONPARAMCONFIG_H_13EFE267__
#define __PYTHONPARAMCONFIG_H_13EFE267__

// a small header file so that Cython doesn't get confused by the juce headers

enum paramType {
    TOGGLE,
    INT_SET,
    FLOAT_RANGE
};


struct ParamConfig {
    enum paramType type;
    char *name;
    int isEnabled;
    int nEntries;
    int *entries;
    float rangeMin;
    float rangeMax;
    float startValue;
};



#endif  // __PYTHONPARAMCONFIG_H_13EFE267__
