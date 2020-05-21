cmake_minimum_required(VERSION 3.5.0)
if (NOT DEFINED GUI_BASE_DIR)
    if (DEFINED ENV{GUI_BASE_DIR})
        set(GUI_BASE_DIR $ENV{GUI_BASE_DIR})
    else()
        set(GUI_BASE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../../plugin-GUI)
    endif()
endif()
project(PythonPlugin)

set(PLUGIN_NAME PythonPlugin)

# define LINUX if you're building on linux.
# for now we assume that you're building to run on the build machine
set(CMAKE_SHARED_LIBRARY_PREFIX "")
if(${CMAKE_SYSTEM_NAME} STREQUAL "Linux")
	set(LINUX 1)
	if(NOT CMAKE_BUILD_TYPE)
		set(CMAKE_BUILD_TYPE Debug)
	endif()
endif()

set_property(DIRECTORY APPEND PROPERTY COMPILE_DEFINITIONS
	OEPLUGIN
	"$<$<PLATFORM_ID:Windows>:JUCE_API=__declspec(dllimport)>"
	$<$<PLATFORM_ID:Windows>:_CRT_SECURE_NO_WARNINGS>
	$<$<PLATFORM_ID:Linux>:JUCE_DISABLE_NATIVE_FILECHOOSERS=1>
	$<$<CONFIG:Debug>:DEBUG=1>
	$<$<CONFIG:Debug>:_DEBUG=1>
	$<$<CONFIG:Release>:NDEBUG=1>
	)

# Find Python. Users can specify by providing the following in the call to cmake:
    # -DPYTHON_EXECUTABLE
    # -DPYTHON_LIBRARIES
    # -DPYTHON_INCLUDE_DIRS
    # -DPYTHON_HOME
find_package(PythonInterp REQUIRED)
find_package(PythonLibs REQUIRED)
#set(PYTHON_HOME $ENV{CONDA_PREFIX} CACHE PATH "Where is the root of your python installation?")
set(PYTHON_HOME $ENV{CONDA_HOME} CACHE PATH "Where is the root of your python installation?")
get_filename_component(PYTHON_LIB_DIR ${PYTHON_LIBRARIES} DIRECTORY)
message(STATUS "Python home: " ${PYTHON_HOME})
message(STATUS "Python executable: " ${PYTHON_EXECUTABLE})
message(STATUS "Python library: " ${PYTHON_LIBRARIES})
message(STATUS "Python lib dir: " ${PYTHON_LIB_DIR})
message(STATUS "Python include dir: " ${PYTHON_INCLUDE_DIRS})

# extend PYTHONPATH to include python_modules
if(WIN32)
    set(PY_PATH_SEP ;)
else()
    set(PY_PATH_SEP :)
endif()
# might have to get file(TO_NATIVE_PATH "<path>" <variable>) involved for windows...
set(PLUGIN_MODULES_PATH "${PROJECT_SOURCE_DIR}/python_modules" CACHE PATH "Where are the python modules you want to plug in?")
file(TO_NATIVE_PATH "${PLUGIN_MODULES_PATH}" NATIVE_PLUGIN_MODULES_PATH)


# TODO: remove if you're sure this is overkill
# execute_process(COMMAND python -c "import sys; import os; print(os.pathsep.join(sys.path))" OUTPUT_VARIABLE ORIG_PY_PATH)
# string(STRIP "${ORIG_PY_PATH}" ORIG_PY_PATH)

# # TODO: remove orig_py_path if you remove the bit above
# set(PYTHON_PATH "${ORIG_PY_PATH}${PY_PATH_SEP}${NATIVE_PLUGIN_MODULES_PATH}" CACHE PATH "What do you want on your PYTHONPATH?")
# message(STATUS "ORIG PYTHONPATH: " ${ORIG_PY_PATH})
# message(STATUS "PYTHONPATH: " ${PYTHON_PATH})

set(SOURCE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/Source)
file(GLOB_RECURSE SRC_FILES LIST_DIRECTORIES false "${SOURCE_PATH}/*.cpp" "${SOURCE_PATH}/*.c" "${SOURCE_PATH}/*.h")
set(GUI_COMMONLIB_DIR ${GUI_BASE_DIR}/installed_libs)

set(CONFIGURATION_FOLDER $<$<CONFIG:Debug>:Debug>$<$<NOT:$<CONFIG:Debug>>:Release>)

list(APPEND CMAKE_PREFIX_PATH ${GUI_COMMONLIB_DIR} ${GUI_COMMONLIB_DIR}/${CONFIGURATION_FOLDER})

if (APPLE)
	add_library(${PLUGIN_NAME} MODULE ${SRC_FILES})
else()
	add_library(${PLUGIN_NAME} SHARED ${SRC_FILES})
endif()

target_compile_features(${PLUGIN_NAME} PUBLIC cxx_auto_type cxx_generalized_initializers)
target_include_directories(${PLUGIN_NAME} PUBLIC ${GUI_BASE_DIR}/JuceLibraryCode ${GUI_BASE_DIR}/JuceLibraryCode/modules ${GUI_BASE_DIR}/Plugins/Headers ${GUI_COMMONLIB_DIR}/include)

set(GUI_BIN_DIR ${GUI_BASE_DIR}/Build/${CONFIGURATION_FOLDER})

if (NOT CMAKE_LIBRARY_ARCHITECTURE)
	if (CMAKE_SIZEOF_VOID_P EQUAL 8)
		set(CMAKE_LIBRARY_ARCHITECTURE "x64")
	else()
		set(CMAKE_LIBRARY_ARCHITECTURE "x86")
	endif()
endif()

# link libraries
target_link_libraries(${PLUGIN_NAME} ${PYTHON_LIBRARIES})
target_include_directories(${PLUGIN_NAME} PRIVATE ${PYTHON_INCLUDE_DIRS})

# preprocessor definitions
add_definitions(-DOEPLUGIN)
add_definitions(-DJUCE_APP_VERSION=0.4.2)
add_definitions(-DJUCE_APP_VERSION_HEX=0x402)
add_definitions(-DJUCE_APP_VERSION_HEX=0x402)
add_definitions(-DPYTHON_HOME=${PYTHON_HOME})
add_definitions(-DPYTHON_PATH=${PYTHON_PATH})

# platform specific stuff
if(APPLE)
    set_target_properties(${PLUGIN_NAME} PROPERTIES BUNDLE TRUE)
    set_property(TARGET ${PLUGIN_NAME} APPEND_STRING PROPERTY LINK_FLAGS
    "-undefined dynamic_lookup -rpath @loader_path/../../../../shared")

    install(TARGETS ${PLUGIN_NAME} DESTINATION $ENV{HOME}/Library/Application\ Support/open-ephys/PlugIns)
    set(CMAKE_PREFIX_PATH /opt/local)

    # link the IOKit framework
    target_link_libraries(${PLUGIN_NAME} debug "-framework IOKit")
    target_link_libraries(${PLUGIN_NAME} optimized "-framework IOKit")

    # mac-specific preprocessor definitions
    add_definitions(-DMAC_PACKAGE_DIR=${MAC_PACKAGE_DIR})
    add_definitions(-DJUCER_XCODE_MAC_F6D2F4CF=1)
    # add_definitions(-D_ANSI_SOURCE) # needed for nanosleep()

    # mac-specific cxx flags
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-inconsistent-missing-override")

    # mac-specific c flags
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-inconsistent-missing-override")

    # # mac-specific library include directories
    # target_include_directories(${PLUGIN_NAME} PUBLIC
    #     ${MAC_PACKAGE_DIR}/include
    #     )

    # mac-specific library search paths
    link_directories(${MAC_PACKAGE_DIR}/lib)

    # mac-specific linker flags
    set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} -undefined dynamic_lookup")

    # xcode properties
    set_xcode_property(${PLUGIN_NAME} WRAPPER_EXTENSION bundle)

elseif(LINUX)
    target_link_libraries(${PLUGIN_NAME} GL X11 Xext Xinerama asound dl freetype pthread rt)
	set_property(TARGET ${PLUGIN_NAME} APPEND_STRING PROPERTY LINK_FLAGS
		"-fvisibility=hidden -fPIC -rdynamic -Wl,-rpath,'$$ORIGIN/../shared'")
	target_compile_options(${PLUGIN_NAME} PRIVATE -fPIC -rdynamic)
	target_compile_options(${PLUGIN_NAME} PRIVATE -O3) #enable optimization for linux debug
	
	install(TARGETS ${PLUGIN_NAME} LIBRARY DESTINATION ${GUI_BIN_DIR}/plugins)
elseif(WIN32)
    add_definitions(-DPYTHON_HOME_NAME="C:\/Anaconda3")
    target_link_libraries(${PLUGIN_NAME} ${GUI_BIN_DIR}/open-ephys.lib)
	target_compile_options(${PLUGIN_NAME} PRIVATE /sdl-)
	
	install(TARGETS ${PLUGIN_NAME} RUNTIME DESTINATION ${GUI_BIN_DIR}/plugins  CONFIGURATIONS ${CMAKE_CONFIGURATION_TYPES})

    set(CMAKE_PREFIX_PATH ${CMAKE_CURRENT_SOURCE_DIR}/../libs)


    # target_link_libraries(${PLUGIN_NAME} debug ${LIBSERIAL_LIBRARIES} "setupapi.lib" )
    # target_link_libraries(${PLUGIN_NAME} optimized ${LIBSERIAL_LIBRARIES} "setupapi.lib")
endif()

foreach( src_file IN ITEMS ${SRC_FILES})
	get_filename_component(src_path "${src_file}" PATH)
	file(RELATIVE_PATH src_path_rel "${SOURCE_PATH}" "${src_path}")
	string(REPLACE "/" "\\" group_name "${src_path_rel}")
	source_group("${group_name}" FILES "${src_file}")
endforeach()
