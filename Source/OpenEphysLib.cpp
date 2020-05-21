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

#include "PythonFilter.h"
#include "PythonSource.h"
#include "PythonSink.h"

#include <PluginInfo.h>
#include <string>
#ifdef WIN32
#include <Windows.h>
#define EXPORT __declspec(dllexport)
#else
#define EXPORT
#endif

using namespace Plugin;
//Number of plugins defined on the library. Can be of different types (Processors, RecordEngines, etc...)
#define NUM_PLUGINS 3

extern "C" EXPORT void getLibInfo(Plugin::LibraryInfo* info)
{
    info->apiVersion = PLUGIN_API_VER; /*API version, defined by the GUI source.
                                        Should not be changed to ensure it is always equal to the one used in the latest codebase. The GUI refueses to load plugins with mismatched API versions */
    info->name = "Python Plugin"; //Name of the Library, used only for information
    info->libVersion = 1; //Version of the library, used only for information
    info->numPlugins = NUM_PLUGINS;
}

extern "C" EXPORT int getPluginInfo(int index, Plugin::PluginInfo* info)
{
    switch (index)
    {
            //one case per plugin. This example is for a processor which connects directly to the signal chain
        case 0:
            info->type = Plugin::PLUGIN_TYPE_PROCESSOR; //Type of plugin. See "Source/Processors/PluginManager/OpenEphysPlugin.h" for complete info about the different type structures
            //For processor
            info->processor.name = "Python Filter"; //Processor name shown in the GUI
            info->processor.type = Plugin::FilterProcessor; //Type of processor. Can be FilterProcessor, SourceProcessor, SinkProcessor or UtilityProcessor. Specifies where on the processor list will appear
            info->processor.creator = &(Plugin::createProcessor<PythonFilter>); //Class factory pointer. Replace "ExampleProcessor" with the name of your class.
            break;
        case 1:
            info->type = Plugin::PLUGIN_TYPE_PROCESSOR; //Type of plugin. See "Source/Processors/PluginManager/OpenEphysPlugin.h" for complete info about the different type structures
            //For processor
            info->processor.name = "Python Source"; //Processor name shown in the GUI
            info->processor.type = Plugin::SourceProcessor; //Type of processor. Can be FilterProcessor, SourceProcessor, SinkProcessor or UtilityProcessor. Specifies where on the processor list will appear
            info->processor.creator = &(Plugin::createProcessor<PythonSource>); //Class factory pointer. Replace "ExampleProcessor" with the name of your class.

            break;
        case 2:
            info->type = Plugin::PLUGIN_TYPE_PROCESSOR; //Type of plugin. See "Source/Processors/PluginManager/OpenEphysPlugin.h" for complete info about the different type structures
            //For processor
            info->processor.name = "Python Sink"; //Processor name shown in the GUI
            info->processor.type = Plugin::SinkProcessor; //Type of processor. Can be FilterProcessor, SourceProcessor, SinkProcessor or UtilityProcessor. Specifies where on the processor list will appear
            info->processor.creator = &(Plugin::createProcessor<PythonSink>); //Class factory pointer. Replace "ExampleProcessor" with the name of your class.
            
            break;
        default:
            return -1;
            break;
    }
    return 0;
}

#ifdef WIN32
BOOL WINAPI DllMain(IN HINSTANCE hDllHandle,
                    IN DWORD     nReason,
                    IN LPVOID    Reserved)
{
    return TRUE;
}

#endif
