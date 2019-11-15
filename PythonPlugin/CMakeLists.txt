cmake_minimum_required(VERSION 3.5.0)
# MS: Updated to follow the regular cmake format (11/5/19)
# Needed to change some paths to follow new cmake file structure. If using old GUI build you may need to change them back. Also needs to be tested to make sure the changes didn't break apple/linux building.

# Get GUI Base Dir
if (NOT DEFINED GUI_BASE_DIR)
    if (DEFINED ENV{GUI_BASE_DIR})
		set(GUI_BASE_DIR $ENV{GUI_BASE_DIR})
    else()
		set(GUI_BASE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../../plugin-GUI)
    endif()
endif()

# Get plugin info
get_filename_component(PROJECT_FOLDER ${CMAKE_CURRENT_SOURCE_DIR} ABSOLUTE)
get_filename_component(PLUGIN_NAME ${PROJECT_FOLDER} NAME)
# Set plugin info
project(OE_PLUGIN_${PLUGIN_NAME})
set(CMAKE_SHARED_LIBRARY_PREFIX "")
if(${CMAKE_SYSTEM_NAME} STREQUAL "Linux")
	set(LINUX 1)
	if(NOT CMAKE_BUILD_TYPE)
		set(CMAKE_BUILD_TYPE Debug)
	endif()
endif()

# Compiler definitions
set_property(DIRECTORY APPEND PROPERTY COMPILE_DEFINITIONS
	OEPLUGIN
	"$<$<PLATFORM_ID:Windows>:JUCE_API=__declspec(dllimport)>"
	$<$<PLATFORM_ID:Windows>:_CRT_SECURE_NO_WARNINGS>
	$<$<PLATFORM_ID:Linux>:JUCE_DISABLE_NATIVE_FILECHOOSERS=1>
	$<$<CONFIG:Debug>:DEBUG=1>
	$<$<CONFIG:Debug>:_DEBUG=1>
	$<$<NOT:$<CONFIG:Debug>>:NDEBUG=1>
    )

# Get source files
set(SOURCE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/Source)
file(GLOB_RECURSE SRC_FILES LIST_DIRECTORIES false "${SOURCE_PATH}/*.cpp" "${SOURCE_PATH}/*.h")
set(GUI_COMMONLIB_DIR ${GUI_BASE_DIR}/installed_libs)

# set build type to debug by default
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Debug)
endif()
if(NOT (CMAKE_BUILD_TYPE STREQUAL Debug) OR (CMAKE_BUILD_TYPE STREQUAL Release))
    message(FATAL_ERROR, "Unsupported CMAKE_BUILD_TYPE: " ${CMAKE_BUILD_TYPE})
endif()
message(STATUS "Build type: " ${CMAKE_BUILD_TYPE})

# Find Python. Users can specify by providing the following in the call to cmake:
    # -DPYTHON_EXECUTABLE
    # -DPYTHON_LIBRARIES
    # -DPYTHON_INCLUDE_DIRS
    # -DPYTHON_HOME
find_package(PythonInterp REQUIRED)
find_package(PythonLibs REQUIRED)
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

# put together path for common plugin libraries
#get_filename_component(COMMON_DIR ${GUI_BASE_DIR}/Source/Plugins/CommonLibs ABSOLUTE)
# MS: Above looks like old GUI file format?
get_filename_component(COMMON_DIR ${GUI_BASE_DIR}/installed_libs ABSOLUTE)
message("CommonLibs: " ${COMMON_DIR})

# add project dir to module path so the library finding .cmake files are found
list(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR})


# generate shared library
if (APPLE)
	add_library(${PLUGIN_NAME} MODULE ${SRC_FILES})
else()
	add_library(${PLUGIN_NAME} SHARED ${SRC_FILES})
endif()

set(CMAKE_SHARED_LIBRARY_PREFIX "")


target_compile_features(${PLUGIN_NAME} PUBLIC cxx_auto_type cxx_generalized_initializers)

# MS: I believe this can be deleted
# compiler flags
#set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall")
#set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -DDEBUG=1 -D_DEBUG=1")
#set(CMAKE_CXX_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -DNDEBUG=1")

# cross-platform CFLAGS
#set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall")
#set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -DDEBUG=1 -D_DEBUG=1")
#set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} -DNDEBUG=1")

# link libraries
target_link_libraries(${PLUGIN_NAME} ${PYTHON_LIBRARIES})
#target_link_directories(${PLUGIN_NAME} PUBLIC ${PYTHON_INCLUDE_DIRS})

# preprocessor definitions
add_definitions(-DOEPLUGIN)
add_definitions(-DJUCE_APP_VERSION=0.4.2)
add_definitions(-DJUCE_APP_VERSION_HEX=0x402)
add_definitions(-DJUCE_APP_VERSION_HEX=0x402)
add_definitions(-DPYTHON_HOME=${PYTHON_HOME})
add_definitions(-DPYTHON_PATH=${PYTHON_PATH})

# include directories
target_include_directories(${PLUGIN_NAME} PUBLIC
	${GUI_BASE_DIR}/JuceLibraryCode
	${GUI_BASE_DIR}/JuceLibraryCode/modules
	${GUI_BASE_DIR}/Plugins/Headers
    ${GUI_COMMONLIB_DIR}/include
    ${PYTHON_INCLUDE_DIRS})

# Check if configuration types are set up by GUI and common libs are installed.
set(GUI_BIN_DIR ${GUI_BASE_DIR}/Build/$<CONFIG>)
foreach(config ${CMAKE_CONFIGURATION_TYPES})
    if (NOT EXISTS ${GUI_BASE_DIR}/Build/${config})
        if (EXISTS ${GUI_BASE_DIR}/Build/Release)
            # default to release
            message(WARNING "${config} ${PLUGIN_NAME} build will link to Release GUI build")
            set(GUI_BIN_DIR $<IF:$<CONFIG:${config}>,${GUI_BASE_DIR}/Build/Release,${GUI_BIN_DIR}>)
        else()
            message(WARNING "${config} ${PLUGIN_NAME} build will not be available")
        endif()
    endif()
endforeach()

# Check for 64bit compiler
if (NOT CMAKE_LIBRARY_ARCHITECTURE)
	if (CMAKE_SIZEOF_VOID_P EQUAL 8)
		set(CMAKE_LIBRARY_ARCHITECTURE "x64")
	else()
		set(CMAKE_LIBRARY_ARCHITECTURE "x86")
	endif()
endif()

# platform specific stuff
if(APPLE)
    set_target_properties(${PLUGIN_NAME} PROPERTIES BUNDLE TRUE)
    # macros for working with apple stuff
    macro (set_xcode_property TARGET XCODE_PROPERTY XCODE_VALUE)
        set_property(TARGET ${TARGET} PROPERTY XCODE_ATTRIBUTE_${XCODE_PROPERTY}
            ${XCODE_VALUE})
    endmacro (set_xcode_property)

    # we need to know where the package dir is
    set(MAC_PACKAGE_DIR "/usr/local" CACHE PATH "Where do you install custom libs on this mac?")
    string(STRIP "${MAC_PACKAGE_DIR}" MAC_PACKAGE_DIR)
    if(NOT MAC_PACKAGE_DIR)
        message(FATAL_ERROR, "MAC_PACKAGE_DIR not specified... please set using ccmake or use -DMAC_PACKAGE_DIR.")
    endif()
    get_filename_component(MAC_PACKAGE_DIR ${MAC_PACKAGE_DIR} ABSOLUTE)

    # install location
    SET(CMAKE_INSTALL_PREFIX
        "$ENV{HOME}/Library/Application Support/open-ephys/PlugIns"
        CACHE PATH
        "Plugin install location. See Open Ephys docs for details."
        FORCE)

    set_xcode_property(${PLUGIN_NAME} INSTALL_PATH ${CMAKE_INSTALL_PREFIX})
    set_xcode_property(${PLUGIN_NAME} GCC_INLINES_ARE_PRIVATE_EXTERN NO)

    # rpath stuff
    # see: https://gitlab.kitware.com/cmake/community/wikis/doc/cmake/RPATH-handling
    set_target_properties(${PLUGIN_NAME} PROPERTIES MACOSX_RPATH TRUE)
    set_target_properties(${PLUGIN_NAME} PROPERTIES SKIP_BUILD_RPATH FALSE)
    set_target_properties(${PLUGIN_NAME} PROPERTIES BUILD_WITH_INSTALL_RPATH FALSE)
    set_target_properties(${PLUGIN_NAME} PROPERTIES INSTALL_RPATH "${PYTHON_LIB_DIR}")
    set_target_properties(${PLUGIN_NAME} PROPERTIES INSTALL_RPATH_USE_LINK_PATH TRUE)
    list(FIND CMAKE_PLATFORM_IMPLICIT_LINK_DIRECTORIES "${PYTHON_LIB_DIR}" isSystemDir)
    if("${isSystemDir}" STREQUAL "-1")
        set_target_properties(${PLUGIN_NAME} PROPERTIES INSTALL_RPATH "${PYTHON_LIB_DIR}")
    endif()
    message("install rpath: " ${CMAKE_INSTALL_RPATH})

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
    set_target_properties(${PLUGIN_NAME} PROPERTIES LINKER_LANGUAGE CXX)
	# MS: Don't know anything about how Linux building is different, but the regular cmake file format is much more condensed. Can probably use it as a baseline.
    if(TARGET_ARCH)
        # (this disables dependency generation if multiple architectures are set)
        list(LENGTH TARGET_ARCH ARCH_COUNT)
        if(${ARCH_COUNT} GREATER 1)
            message("ARCH_COUNT = " ${ARCH_COUNT})
            set(DEPFLAGS  "")
        else()
            set(DEPFLAGS -MMD)
        endif()
    else()
        # -march=native really only supported on for GCC, Clang and ICC on i386 and x86_64.
        # ... fix this, if ever needed
        set(TARGET_ARCH -march=native)
        set(DEPFLAGS -MMD)
    endif()

    # find freetype (needed on linux only)
    find_package(LibFreetype2 REQUIRED)
    file(GLOB LIBFREETYPE2_HEADER_FILES "${LIBFREETYPE2_INCLUDE_DIRS}/libserialport.h")

    # install into the open ephy plugins directory
    get_filename_component(OE_PLUGIN_DIR ${GUI_BASE_DIR}/Build/${CMAKE_BUILD_TYPE}/plugins/ ABSOLUTE)
    SET(CMAKE_INSTALL_PREFIX
        ${OE_PLUGIN_DIR}
        CACHE PATH
        "Plugin install location. See Open Ephys docs for details."
        FORCE)

    # no 'lib' prefix, please... the other plugins will laugh
    SET_TARGET_PROPERTIES(${PLUGIN_NAME} PROPERTIES PREFIX "")

    # linux-specific c flags
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${DEPFLAGS} -O3 -fPIC -rdynamic -lcap")

    # linux-specific preprocessor definitions
    add_definitions(-DLINUX=1)
    add_definitions(-DJUCER_LINUX_MAKE_7346DA2A=1)
    add_definitions(-DJUCE_DISABLE_NATIVE_FILECHOOSERS=1)
    add_definitions(-D_XOPEN_SOURCE=700)

    # linux-specific include directories
    target_include_directories(${PLUGIN_NAME} PUBLIC
        /usr/include                # TODO: always right?
        ${COMMON_DIR}
        )

    # linker flags
    set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} -pg  -fPIC -rdynamic")
    set(CMAKE_MODULE_LINKER_FLAGS_DEBUG "${CMAKE_MODULE_LINKER_FLAGS_DEBUG} -L/usr/local/include") # is this really needed?

    # STRONGLY consider removing fvisibility call...
    # https://github.com/open-ephys/plugin-GUI/issues/89
    set(CMAKE_MODULE_LINKER_FLAGS_RELEASE "${CMAKE_MODULE_LINKER_FLAGS_RELEASE} -fvisibility=hidden")

    ##
    ## TODO LATER: there's a more robust way to link libs using add_library() w/SHARED, but
    ## we'll do that later if there's time / a need
    ##

    # look for libraries in build dirs first
    link_directories(${CMAKE_BINARY_DIR})
    link_directories(${CMAKE_CURRENT_BINARY_DIR})

    # add standard library locations
    link_directories("/usr/X11R6/lib")

    # link libraries that "should" be in standard locations
    target_link_libraries(${PLUGIN_NAME} GL)
    target_link_libraries(${PLUGIN_NAME} X11)
    target_link_libraries(${PLUGIN_NAME} Xext)
    target_link_libraries(${PLUGIN_NAME} Xinerama)
    target_link_libraries(${PLUGIN_NAME} asound)
    target_link_libraries(${PLUGIN_NAME} dl)
    target_link_libraries(${PLUGIN_NAME} rt)
    target_link_libraries(${PLUGIN_NAME} dl)
    target_link_libraries(${PLUGIN_NAME} Xext)
    target_link_libraries(${PLUGIN_NAME} GLU)

    # link freetype
    if(LIBFREETYPE2_FOUND)
        target_include_directories(${PLUGIN_NAME} PUBLIC ${LIBFREETYPE2_INCLUDE_DIRS})
        target_link_libraries(${PLUGIN_NAME} ${LIBFREETYPE2_LIBRARIES})
    endif()

    # rpath stuff
    # see: https://gitlab.kitware.com/cmake/community/wikis/doc/cmake/RPATH-handling
    set(CMAKE_SKIP_BUILD_RPATH FALSE)
    set(CMAKE_BUILD_WITH_INSTALL_RPATH FALSE)
    set(CMAKE_INSTALL_RPATH "${PYTHON_LIB_DIR}") # TODO: can I delete this as long as I have the line below?
    set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
    list(FIND CMAKE_PLATFORM_IMPLICIT_LINK_DIRECTORIES "${PYTHON_LIB_DIR}" isSystemDir)
    if("${isSystemDir}" STREQUAL "-1")
        set(CMAKE_INSTALL_RPATH "${PYTHON_LIB_DIR}")
    endif()
elseif(MSVC)
    # MS: Working!

    # install into the open ephy plugins directory
    get_filename_component(OE_PLUGIN_DIR ${GUI_BASE_DIR}/Build/Plugins ABSOLUTE)
    SET(CMAKE_INSTALL_PREFIX
        ${OE_PLUGIN_DIR}
        CACHE PATH
        "Plugin install location. See Open Ephys docs for details."
        FORCE)

    # no 'lib' prefix, please...
    SET_TARGET_PROPERTIES(${PLUGIN_NAME} PROPERTIES PREFIX "")

	target_link_libraries(${PLUGIN_NAME} ${GUI_BIN_DIR}/open-ephys.lib)
	target_compile_options(${PLUGIN_NAME} PRIVATE /sdl-)

	install(TARGETS ${PLUGIN_NAME} RUNTIME DESTINATION ${GUI_BIN_DIR}/plugins)

	# also install dependency DLLs for runtime loading
	install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/../libs/bin/${CMAKE_LIBRARY_ARCHITECTURE}/
		DESTINATION ${GUI_BIN_DIR}/shared OPTIONAL)

	list(APPEND CMAKE_PREFIX_PATH ${CMAKE_CURRENT_SOURCE_DIR}/../libs)

else()
    # maybe non-apple unix
    message(FATAL_ERROR, "Build Platform Not Recognized: Aborting...")
    return()
endif()

message("Install location: " ${CMAKE_INSTALL_PREFIX})

# Set the library installation location
install(TARGETS ${PLUGIN_NAME} DESTINATION ${CMAKE_INSTALL_PREFIX})
