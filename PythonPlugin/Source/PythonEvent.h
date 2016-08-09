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

    PythonEvent.h
    Created: 27 Jul 2014 4:42:07pm
    Author:  Francesco Battaglia

  ==============================================================================
*/

#ifndef __PYTHONEVENT_H
#define __PYTHONEVENT_H

struct PythonEvent;

struct PythonEvent {
    unsigned char type;
    int sampleNum;
    unsigned char eventId;
    unsigned char eventChannel;
    unsigned char numBytes;
    unsigned char *eventData;
    struct PythonEvent *nextEvent;
};



#endif  // __PYTHONEVENT_H
