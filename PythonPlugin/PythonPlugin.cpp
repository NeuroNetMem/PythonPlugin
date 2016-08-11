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

    PythonPlugin.cpp
    Created: 13 Jun 2014 5:56:17pm
    Author:  fpbatta

  ==============================================================================
*/

#include "PythonPlugin.h"




#include "PythonPlugin.h"
#include "PythonEditor.h"

#include <dlfcn.h>
#include <stdlib.h>
#include <string.h>

#define PYTHON_DEBUG

#ifdef PYTHON_DEBUG
#if defined(__linux__)
#include <sys/syscall.h>
#include <unistd.h>
#else
#include <pthread.h> 
#endif
#endif




PythonPlugin::PythonPlugin(const String &processorName)
    : GenericProcessor(processorName) //, threshold(200.0), state(true)

{

    //parameters.add(Parameter("thresh", 0.0, 500.0, 200.0, 0));
    filePath = "";
    plugin = 0;
#define QUOTE(name) #name
#define STR(macro) QUOTE(macro)
#define PYTHON_HOME_NAME STR(PYTHON_HOME)
    char * old_python_home = getenv("PYTHONHOME");
    if (old_python_home == NULL)
				{
#ifdef PYTHON_DEBUG
					std::cout << "setting PYTHONHOME" << std::endl;
#endif
        	setenv("PYTHONHOME", PYTHON_HOME_NAME, 1);
				}
    // setenv("PYTHONHOME", "/usr/local/anaconda", 1); // FIXME hardcoded PYTHONHOME!
    
#ifdef PYTHON_DEBUG
    std::cout << "PYTHONHOME: " << getenv("PYTHONHOME") << std::endl;
#endif
    
#ifdef PYTHON_DEBUG
#if defined(__linux__)
    pid_t tid;
    tid = syscall(SYS_gettid);
#else
    uint64_t tid;
    pthread_threadid_np(NULL, &tid);
#endif
    std::cout << "in constructor pthread_threadid_np()=" << tid << std::endl;
#endif
    

#if PY_MAJOR_VERSION==3
    Py_SetProgramName ((wchar_t *)"PythonPlugin");
#else
    Py_SetProgramName ((char *)"PythonPlugin");
#endif
    Py_Initialize ();
    PyEval_InitThreads();

    
    PyRun_SimpleString("import sys");
    PyRun_SimpleString("sys.setcheckinterval(10000)");
#ifdef PYTHON_DEBUG
    std::cout << Py_GetPrefix() << std::endl;
    std::cout << Py_GetVersion() << std::endl;
#endif
    GUIThreadState = PyEval_SaveThread();
}

PythonPlugin::~PythonPlugin()
{
	dlclose(plugin);
}

AudioProcessorEditor* PythonPlugin::createEditor()
{

//        std::cout << "in PythonEditor::createEditor()" << std::endl;
    editor = new PythonEditor(this, true);

    return editor;

}


bool PythonPlugin::isReady()
{
#ifdef PYTHON_DEBUG
#if defined(__linux__)
    pid_t tid;
    tid = syscall(SYS_gettid);
#else
    uint64_t tid;
    pthread_threadid_np(NULL, &tid);
#endif
    std::cout << "in isReady pthread_threadid_np()=" << tid << std::endl;
#endif


    bool ret;
    PyEval_RestoreThread(GUIThreadState);
    if (plugin == 0 )
    {
        // sendActionMessage("No plugin selected in Python Plugin."); // FIXME how to send error message?
        ret = false;
    }
    else if (pluginIsReady && !(*pluginIsReady)())
    {
        // sendActionMessage("Plugin is not ready"); // FIXME how to send error message?
        ret = false;
    }
    else
    {
        ret = true;
    }
    GUIThreadState = PyEval_SaveThread();
    return ret;

}

void PythonPlugin::setParameter(int parameterIndex, float newValue)
{
    editor->updateParameterButtons(parameterIndex);

    //Parameter& p =  parameters.getReference(parameterIndex);
    //p.setValue(newValue, 0);

    //threshold = newValue;

    //std::cout << float(p[0]) << std::endl;
    editor->updateParameterButtons(parameterIndex);
}


void PythonPlugin::resetConnections()
{
    
#ifdef PYTHON_DEBUG
#if defined(__linux__)
    pid_t tid;
    tid = syscall(SYS_gettid);
#else
    uint64_t tid;
    pthread_threadid_np(NULL, &tid);
#endif
    std::cout << "in resetConnection pthread_threadid_np()=" << tid << std::endl;
#endif

    nextAvailableChannel = 0;
    
    wasConnected = false;
#ifdef PYTHON_DEBUG
    std::cout << "resetting ThreadState, which was "  << processThreadState << std::endl;
#endif
    processThreadState = 0;
}

void PythonPlugin::process(AudioSampleBuffer& buffer,
                               MidiBuffer& events)
{

#ifdef PYTHON_DEBUG
#if defined(__linux__)
    pid_t tid;
    tid = syscall(SYS_gettid);
#else
    uint64_t tid;
    pthread_threadid_np(NULL, &tid);
#endif
    std::cout << "in process pthread_threadid_np()=" << tid << std::endl;
#endif
    
    
    if(!processThreadState)
    {
        
        //DEBUG
        PyThreadState *nowState;
        nowState = PyGILState_GetThisThreadState();
#ifdef PYTHON_DEBUG
        std::cout << "currentState: " << nowState << std::endl;
        std::cout << "initialiting ThreadState" << std::endl;
#endif
        if(nowState) //UGLY HACK!!!
        {
            processThreadState = nowState;
        }
        else
        {
            processThreadState =  PyThreadState_New(GUIThreadState->interp);
        }
        if(!processThreadState)
            std::cout << "ThreadState is Null!" << std::endl;
    }

    PyEval_RestoreThread(processThreadState);
    
    PythonEvent *pyEvents = (PythonEvent *)calloc(1, sizeof(PythonEvent));
    pyEvents->type = 0; // this marks an empty event
#ifdef PYTHON_DEBUG
    std::cout << "in process, trying to acquire lock" << std::endl;
#endif 
    
    // PyEval_InitThreads();
//    
//    std::cout << "in process, threadstate: " << PyGILState_GetThisThreadState() << std::endl;
//    PyGILState_STATE gstate;
//    gstate = PyGILState_Ensure();
//    std::cout << "in process, lock acquired" << std::endl;
    (*pluginFunction)(*(buffer.getArrayOfWritePointers()), buffer.getNumChannels(), buffer.getNumSamples(), getNumSamples(0), pyEvents);
//    PyGILState_Release(gstate);
//    std::cout << "in process, lock released" << std::endl;
    
    if(pyEvents->type != 0)
    {
#ifdef PYTHON_DEBUG
        std::cout << (int)pyEvents->type << std::endl;
#endif
        addEvent(events, pyEvents->type, pyEvents->sampleNum, pyEvents->eventId,
                 pyEvents->eventChannel, pyEvents->numBytes, pyEvents->eventData);
        PythonEvent *lastEvent = pyEvents;
        PythonEvent *nextEvent = lastEvent->nextEvent;
        free((void *)lastEvent);
        while (nextEvent) {
            addEvent(events, nextEvent->type, nextEvent->sampleNum, nextEvent->eventId, nextEvent->eventChannel, nextEvent->numBytes, nextEvent->eventData);
            lastEvent = nextEvent;
            nextEvent = nextEvent->nextEvent;
            free((void *)lastEvent);
            
        }
    }
    
    processThreadState = PyEval_SaveThread();
#ifdef PYTHON_DEBUG
    std::cout << "Thread saved" << std::endl;
#endif
}


/* The complete API that the Cython plugin has to expose is
 void pluginStartup(void): a function to initialize the plugin data structures prior to start ACQ
 int isReady(void): a boolean function telling the processor whether the plugin is ready  to receive data
 int getParamNum(void) get the number of parameters that the plugin takes
 ParamConfig *getParamConfig(void) this will allow generating the editor GUI TODO
 void setIntParameter(char *name, int value) set integer parameter
 void set FloatParameter(char *name, float value) set float parameter
 
 */
void PythonPlugin::setFile(String fullpath)
{
#ifdef PYTHON_DEBUG
#if defined(__linux__)
    pid_t tid;
    tid = syscall(SYS_gettid);
#else
    uint64_t tid;
    pthread_threadid_np(NULL, &tid);
#endif
    std::cout << "in setFile pthread_threadid_np()=" << tid << std::endl;
#endif
    

    filePath = fullpath;

    const char* path = filePath.getCharPointer();
    plugin = dlopen(path, RTLD_LAZY);
    if (!plugin)
      {
          std::cout << "Can't open plugin "
                    << '"' << path << "\""
                    << dlerror()
                    << std::endl;
          return;
      }

    String initPlugin = filePath.fromLastOccurrenceOf(String("/"), false, true);
    
    initPlugin = initPlugin.upToFirstOccurrenceOf(String("."), false, true);
    
#if PY_MAJOR_VERSION>=3
    String initPluginName = String("PyInit_");
#else
    String initPluginName = String("init");
#endif
    initPluginName.append(initPlugin, 200);
    
    std::cout << "init function is: " << initPluginName << std::endl;
    
    void *initializer = dlsym(plugin,initPluginName.getCharPointer());
    
#ifdef PYTHON_DEBUG
    std::cout << "initializer: " << initializer << std::endl;
#endif
    if (!initializer)
    {
    	std::cout << "Can't find init function in plugin "
        << '"' << path << "\"" << std::endl
        << dlerror()
        << std::endl;
    	plugin = 0;
    	return;
    }
    
    initfunc_t initF = (initfunc_t) initializer;
    
    void *cfunc = dlsym(plugin,"pluginisready");
    if (!cfunc)
    {
    	std::cout << "Can't find ready function in plugin "
        << '"' << path << "\"" << std::endl
        << dlerror()
        << std::endl;
    	plugin = 0;
    	return;
    }
    pluginIsReady = (isreadyfunc_t)cfunc;

    cfunc = dlsym(plugin,"pluginStartup");
    if (!cfunc)
    {
    	std::cout << "Can't find startup function in plugin "
        << '"' << path << "\"" << std::endl
        << dlerror()
        << std::endl;
        plugin = 0;
        return;
    }
    pluginStartupFunction = (startupfunc_t)cfunc;
    
    cfunc = dlsym(plugin,"getParamNum");
    if (!cfunc)
    {
    	std::cout << "Can't find getParamNum function in plugin "
        << '"' << path << "\"" << std::endl
        << dlerror()
        << std::endl;
        plugin = 0;
        return;
    }
    getParamNumFunction = (getparamnumfunc_t)cfunc;
    

    cfunc = dlsym(plugin,"getParamConfig");
    if (!cfunc)
    {
    	std::cout << "Can't find getParamNum function in plugin "
        << '"' << path << "\"" << std::endl
        << dlerror()
        << std::endl;
        //    	plugin = 0;
        //    	return;
    }
    getParamConfigFunction = (getparamconfigfunc_t)cfunc;

    
    cfunc = dlsym(plugin,"pluginFunction");
    // std::cout << "plugin:   " << cfunc << std::endl;
    if (!cfunc)
    {
    	std::cout << "Can't find plugin function in plugin "
        << '"' << path << "\"" << std::endl
        << dlerror()
        << std::endl;
    	plugin = 0;
    	return;
    }
    pluginFunction = (pluginfunc_t)cfunc;
    

    cfunc = dlsym(plugin,"setIntParam");
    // std::cout << "plugin:   " << cfunc << std::endl;
    if (!cfunc)
    {
    	std::cout << "Can't find setIntParam function in plugin "
        << '"' << path << "\"" << std::endl
        << dlerror()
        << std::endl;
    	plugin = 0;
    	return;
    }
    setIntParamFunction = (setintparamfunc_t)cfunc;
    
    cfunc = dlsym(plugin,"setFloatParam");
    // std::cout << "plugin:   " << cfunc << std::endl;
    if (!cfunc)
    {
    	std::cout << "Can't find setFloatParam function in plugin "
        << '"' << path << "\"" << std::endl
        << dlerror()
        << std::endl;
    	plugin = 0;
    	return;
    }

    setFloatParamFunction = (setfloatparamfunc_t)cfunc;

    cfunc = dlsym(plugin, "getIntParam");
    // std::cout << "plugin:   " << cfunc << std::endl;
    if (!cfunc)
    {
        std::cout << "Can't find getIntParam function in plugin "
        << '"' << path << "\"" << std::endl
        << dlerror()
        << std::endl;
        plugin = 0;
        return;
    }
    getIntParamFunction = (getintparamfunc_t)cfunc;
    

    
    cfunc = dlsym(plugin, "getFloatParam");
    // std::cout << "plugin:   " << cfunc << std::endl;
    if (!cfunc)
    {
        std::cout << "Can't find getFloatParam function in plugin "
        << '"' << path << "\"" << std::endl
        << dlerror()
        << std::endl;
        plugin = 0;
        return;
    }
    
    getFloatParamFunction = (getfloatparamfunc_t)cfunc;

    
// now the API should be fully loaded
    
    PyEval_RestoreThread(GUIThreadState);
    // initialize the plugin
#ifdef PYTHON_DEBUG
    std::cout << "before initplugin" << std::endl; // DEBUG
#endif 
    
    (*initF)();

#ifdef PYTHON_DEBUG
    std::cout << "after initplugin" << std::endl; // DEBUG
#endif
    
    (*pluginStartupFunction)(getSampleRate());
    
    // load the parameter configuration
    numPythonParams = (*getParamNumFunction)();
#ifdef PYTHON_DEBUG
    std::cout << "the plugin wants " << numPythonParams
        << " parameters" << std::endl;
#endif
    params = (ParamConfig *)calloc(numPythonParams, sizeof(ParamConfig));
    paramsControl = (Component **)calloc(numPythonParams, sizeof(Component *));
    
    (*getParamConfigFunction)(params);
#ifdef PYTHON_DEBUG
    std::cout << "release paramconfig" << std::endl;
#endif
    
    for(int i = 0; i < numPythonParams; i++)
    {
#ifdef PYTHON_DEBUG
        std::cout << "param " << i << " is a " << params[i].type << std::endl;
        std::cout << "it is named: " << params[i].name << std::endl << std::endl;
#endif
        switch (params[i].type) {
            case TOGGLE:
                paramsControl[i] = dynamic_cast<PythonEditor *>(getEditor())->addToggleButton(String(params[i].name), params[i].isEnabled);
                break;
            case INT_SET:
                paramsControl[i] = dynamic_cast<PythonEditor *>(getEditor())->addComboBox(String(params[i].name), params[i].nEntries, params[i].entries);
                break;
            case FLOAT_RANGE:
                paramsControl[i] = dynamic_cast<PythonEditor *>(getEditor())->addSlider(String(params[i].name), params[i].rangeMin, params[i].rangeMax, params[i].startValue);
                break;
            default:
                break;
        }
    }
    GUIThreadState = PyEval_SaveThread();
}


String PythonPlugin::getFile()
{
    return filePath;
}

void PythonPlugin::updateSettings()
{

}

void PythonPlugin::setIntPythonParameter(String name, int value)
{
    
#ifdef PYTHON_DEBUG
#if defined(__linux__)
    pid_t tid;
    tid = syscall(SYS_gettid);
#else
    uint64_t tid;
    pthread_threadid_np(NULL, &tid);
#endif
    std::cout << "in setintparam pthread_threadid_np()=" << tid << std::endl;
#endif
    
    PyEval_RestoreThread(GUIThreadState);
    (*setIntParamFunction)(name.getCharPointer().getAddress(), value);
    GUIThreadState = PyEval_SaveThread();
}

void PythonPlugin::setFloatPythonParameter(String name, float value)
{

#ifdef PYTHON_DEBUG
#if defined(__linux__)
    pid_t tid;
    tid = syscall(SYS_gettid);
#else
    uint64_t tid;
    pthread_threadid_np(NULL, &tid);
#endif
    std::cout << "in setfloatparam pthread_threadid_np()=" << tid << std::endl;
#endif
    PyEval_RestoreThread(GUIThreadState);
    (*setFloatParamFunction)(name.getCharPointer().getAddress(), value);
    GUIThreadState = PyEval_SaveThread();
}

int PythonPlugin::getIntPythonParameter(String name)
{

#ifdef PYTHON_DEBUG
#if defined(__linux__)
    pid_t tid;
    tid = syscall(SYS_gettid);
#else
    uint64_t tid;
    pthread_threadid_np(NULL, &tid);
#endif
    std::cout << "in getintparam pthread_threadid_np()=" << tid << std::endl;
#endif

    int value;
    PyEval_RestoreThread(GUIThreadState);
    value = (*getIntParamFunction)(name.getCharPointer().getAddress());
    GUIThreadState = PyEval_SaveThread();
    return value;
}

float PythonPlugin::getFloatPythonParameter(String name)
{
    
    
#ifdef PYTHON_DEBUG
#if defined(__linux__)
    pid_t tid;
    tid = syscall(SYS_gettid);
#else
    uint64_t tid;
    pthread_threadid_np(NULL, &tid);
#endif
    std::cout << "in getfloatparam pthread_threadid_np()=" << tid << std::endl;
#endif
    
    PyEval_RestoreThread(GUIThreadState);
    float value;
    value = (*getFloatParamFunction)(name.getCharPointer().getAddress());
    GUIThreadState = PyEval_SaveThread();
    return value;
}

