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

    PythonPlugin.h
    Created: 13 Jun 2014 5:56:17pm
    Author:  fpbatta

  ==============================================================================
*/



#ifndef __PYTHONPLUGIN_H
#define __PYTHONPLUGIN_H

//Hack to get around python37_d.lib not exisiting on Windows (at least on my system)
#if defined(_WIN32) && defined(_DEBUG)
#define _DEBUG_TEMP _DEBUG
#undef _DEBUG
#include <Python.h>
#define _DEBUG _DEBUG_TEMP
#undef _DEBUG_TEMP
#else
#include <Python.h>
#endif

#include "PythonParamConfig.h"
#include "PythonEvent.h"

#include "PythonEditor.h"

//#if PY_MAJOR_VERSION>=3
typedef PyObject * (*initfunc_t)(void);
//#else
//typedef PyMODINIT_FUNC (*initfunc_t)(void);
//#endif
typedef void (*startupfunc_t)(float); // passes the sampling rate
typedef void (*eventfunc_t)(int, int, int, double, int);// CJB added
typedef void (*spikefunc_t)(int, int, float[18]);// CJB added
typedef void (*pluginfunc_t)(float *, int, int, int, PythonEvent *);
typedef int (*isreadyfunc_t)(void);
typedef int (*getparamnumfunc_t)(void);
typedef void (*getparamconfigfunc_t)(struct ParamConfig*);
typedef void (*setintparamfunc_t)(char*, int);
typedef void (*setfloatparamfunc_t)(char*, float);
typedef int (*getintparamfunc_t)(char*);
typedef float (*getfloatparamfunc_t)(char*);


#ifdef _WIN32
#include <Windows.h>
#endif

#include <ProcessorHeaders.h>



//=============================================================================
/*
*/
class PythonPlugin : public GenericProcessor
{
public:
    /** The class constructor, used to initialize any members. */
    PythonPlugin(const String &processorName = "Python Plugin");

    /** Determines whether the processor is treated as a source. */
    virtual bool isSource()
    {
        return false;
    }

    /** Determines whether the processor is treated as a sink. */
    virtual bool isSink()
    {
        return false;
    }

    /** Defines the functionality of the processor.

        The process method is called every time a new data buffer is available.

        Processors can either use this method to add new data, manipulate existing
        data, or send data to an external target (such as a display or other hardware).

        Continuous signals arrive in the "buffer" variable, event data (such as TTLs
        and spikes) is contained in the "events" variable, and "nSamples" holds the
        number of continous samples in the current buffer (which may differ from the
        size of the buffer).
         */
    virtual void process(AudioSampleBuffer& buffer /* , MidiBuffer& events */);

    void handleEvent (const EventChannel* eventInfo, const MidiMessage& event, int sampleNum); // CJB added
    void handleSpike(const SpikeChannel* channelInfo, const MidiMessage& event, int samplePosition); //CJB added

    AudioProcessorEditor* createEditor();

    bool hasEditor() const
    {
        return true;
    }

    void updateSettings();
    void createEventChannels(); 
    void setFile(String fullpath);
    String getFile();
    bool isReady();
    void setIntPythonParameter(String name, int value);
    void setFloatPythonParameter(String name, float value);
    
    int getNumPythonParams()
    {
        return numPythonParams;
    }
    
    ParamConfig *getPythonParams() const
    {
        return params;
    }
    
    Component **getParamsControl() const
    {
        return paramsControl;
    }
    
    int getIntPythonParameter(String name);
    float getFloatPythonParameter(String name);
    
    void resetConnections();

private:
    // private members and methods go here
    //
    // e.g.:
    //
    // float threshold;
    // bool state;

    void sendEventPlugin(int eventType, int sourceID, int subProcessorIdx, double timestamp, int sourceIndex); //CJB added

    String filePath;
    DynamicLibrary plugin;

    int numPythonParams = 0;
    ParamConfig *params;
    Component **paramsControl;
    // var for stashing the sample rate
    float dataSampleRate = 44100;
    // function pointers to the python plugin
    pluginfunc_t pluginFunction;
    isreadyfunc_t pluginIsReady;
    startupfunc_t pluginStartupFunction;
    getparamnumfunc_t getParamNumFunction;
    getparamconfigfunc_t getParamConfigFunction;
    setintparamfunc_t setIntParamFunction;
    setfloatparamfunc_t setFloatParamFunction;
    getintparamfunc_t getIntParamFunction;
    getfloatparamfunc_t getFloatParamFunction;
    eventfunc_t eventFunction;
    spikefunc_t spikeFunction;
    const EventChannel* ttlChannel{ nullptr };
    bool wasTriggered = 0;
    uint16 lastChan = 0;

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(PythonPlugin);
};




#endif  // __PYTHONPLUGIN_H
