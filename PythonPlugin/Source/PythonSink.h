/*
 ------------------------------------------------------------------
 
 Python Plugin
 Copyright (C) 2016 FP Battaglia
 
 based on
 Open Ephys GUI
 Copyright (C) 2013, 2015 Open Ephys
 
 ------------------------------------------------------------------
v 
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

    PythonSink.h
    Created: 13 Jun 2014 5:37:25pm
    Author:  fpbatta

  ==============================================================================
*/

#ifndef __PYTHONSINK_H
#define __PYTHONSINK_H

#include "PythonPlugin.h"


class PythonSink: public PythonPlugin
{
public:
    /** The class constructor, used to initialize any members. */
    PythonSink();

    /** The class destructor, used to deallocate memory */
    ~PythonSink();

    /** Determines whether the processor is treated as a source. */
    bool isSource()
    {
        return false;
    }

    /** Determines whether the processor is treated as a sink. */
    bool isSink()
    {
        return true;
    }



    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(PythonSink);

};




#endif  // __PYTHONSINK_H_4D2E4E29__
