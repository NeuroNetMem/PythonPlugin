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

    PythonFilter.h
    Created: 13 Jun 2014 1:50:08pm
    Author:  fpbatta

  ==============================================================================
*/

#ifndef __PYTHONFILTER_H
#define __PYTHONFILTER_H

#include "PythonPlugin.h"
//==============================================================================
/*
*/

class PythonFilter    : public PythonPlugin
{
public:
    /** The class constructor, used to initialize any members. */
    PythonFilter();

    /** The class destructor, used to deallocate memory */
    ~PythonFilter();

    /** Determines whether the processor is treated as a source. */
    bool isSource()
    {
        return false;
    }

    /** Determines whether the processor is treated as a sink. */
    bool isSink()
    {
        return false;
    }



    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(PythonFilter);

};



#endif  // __PYTHONFILTER_H
