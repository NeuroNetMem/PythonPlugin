cmake_minimum_required(VERSION 3.14)
project(PythonPlugin)

set(PLUGIN_NAME PythonPlugin)

# define LINUX if you're building on linux.
# for now we assume that you're building to run on the build machine
if(CMAKE_HOST_SYSTEM_NAME STREQUAL Linux)
    set(LINUX TRUE)
endif()

# set build type to debug by default
if(NOT DEFINED CONFIG)
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
set(PYTHON_HOME $ENV{CONDA_PREFIX} CACHE PATH "Where is the root of your python installation?")
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

# TODO: remove orig_py_path if you remove the bit above
set(PYTHON_PATH "${ORIG_PY_PATH}${PY_PATH_SEP}${NATIVE_PLUGIN_MODULES_PATH}" CACHE PATH "What do you want on your PYTHONPATH?")
message(STATUS "ORIG PYTHONPATH: " ${ORIG_PY_PATH})
message(STATUS "PYTHONPATH: " ${PYTHON_PATH})

# we need to know where the open ephys source is
set(OPEN_EPHYS_DIR "" CACHE PATH "Where is the Open Ephys repo's base directory?")
string(STRIP "${OPEN_EPHYS_DIR}" OPEN_EPHYS_DIR)
if(NOT OPEN_EPHYS_DIR)
    message(FATAL_ERROR, "OPEN_EPHYS_DIR not specified... please set using ccmake or use -DOPEN_EPHYS_DIR.")
    return()
else()
    get_filename_component(OPEN_EPHYS_DIR ${OPEN_EPHYS_DIR} ABSOLUTE)
    message("Open Ephys Source: " ${OPEN_EPHYS_DIR})
endif()

# put together path for common plugin libraries
get_filename_component(COMMON_DIR ${OPEN_EPHYS_DIR}/Source/Plugins/CommonLibs ABSOLUTE)
message("CommonLibs: " ${COMMON_DIR})

# add project dir to module path so the library finding .cmake files are found
list(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR})

# our headers
file(GLOB PLUGIN_HEADER_FILES "PythonPlugin/*.h")
set(HEADER_FILES "${PLUGIN_HEADER_FILES}")

# our c and cpp files
file(GLOB PLUGIN_SOURCES "PythonPlugin/*.cpp" "PythonPlugin/*.c")
set(SOURCES "${PLUGIN_SOURCES}")

# generate shared library
add_library(${PLUGIN_NAME} MODULE ${PLUGIN_SOURCES} ${PLUGIN_HEADER_FILES})
set(CMAKE_SHARED_LIBRARY_PREFIX "")
set_target_properties(${PLUGIN_NAME} PROPERTIES BUNDLE TRUE)

target_compile_features(${PLUGIN_NAME} PUBLIC cxx_std_11)

# compiler flags
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall")
set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -DDEBUG=1 -D_DEBUG=1")
set(CMAKE_CXX_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -DNDEBUG=1")

# cross-platform CFLAGS
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall")
set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -DDEBUG=1 -D_DEBUG=1")
set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} -DNDEBUG=1")

# link libraries
target_link_libraries(${PLUGIN_NAME} ${PYTHON_LIBRARIES})
target_link_directories(${PLUGIN_NAME} PUBLIC ${PYTHON_INCLUDE_DIRS})

# preprocessor definitions
add_definitions(-DOEPLUGIN)
add_definitions(-DJUCE_APP_VERSION=0.4.2)
add_definitions(-DJUCE_APP_VERSION_HEX=0x402)
add_definitions(-DJUCE_APP_VERSION_HEX=0x402)
add_definitions(-DPYTHON_HOME=${PYTHON_HOME})
add_definitions(-DPYTHON_PATH=${PYTHON_PATH})

# include directories
target_include_directories(${PLUGIN_NAME}
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/PythonPlugin>
        $<INSTALL_INTERFACE:include>
        ${OPEN_EPHYS_DIR}/JuceLibraryCode
        ${OPEN_EPHYS_DIR}/JuceLibraryCode/modules
        ${OPEN_EPHYS_DIR}/Source/Plugins/Headers
        ${PYTHON_INCLUDE_DIRS}
    )

# platform specific stuff
if(APPLE)
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
    get_filename_component(OE_PLUGIN_DIR ${OPEN_EPHYS_DIR}/Builds/Linux/build/plugins ABSOLUTE)
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
elseif(WIN32)
    # TODO: this is surely broken... fix it (if you ever need to)

    # install into the open ephy plugins directory
    get_filename_component(OE_PLUGIN_DIR ${OPEN_EPHYS_DIR}/Builds/Linux/build/plugins ABSOLUTE)
    SET(CMAKE_INSTALL_PREFIX
        ${OE_PLUGIN_DIR}
        CACHE PATH
        "Plugin install location. See Open Ephys docs for details."
        FORCE)

    # no 'lib' prefix, please...
    SET_TARGET_PROPERTIES(${PLUGIN_NAME} PROPERTIES PREFIX "")

    # compile flags
    set(WIN32_COMPILE_FLAGS
        "/nologo /Zc:wchar_t /Zc:forScope /GX /GL /GF /GR /GS- /Zi /fp:precise /MP /W4 "
    )
    set(DEFAULT_COMPILE_FLAGS ${WIN32_COMPILE_FLAGS})

    # target_link_libraries(${PLUGIN_NAME} debug ${LIBSERIAL_LIBRARIES} "setupapi.lib" )
    # target_link_libraries(${PLUGIN_NAME} optimized ${LIBSERIAL_LIBRARIES} "setupapi.lib")
else()
    # maybe non-apple unix
    message(FATAL_ERROR, "Build Platform Not Recognized: Aborting...")
    return()
endif()

message("Install location: " ${CMAKE_INSTALL_PREFIX})

# Set the library installation location
install(TARGETS ${PLUGIN_NAME} DESTINATION ${CMAKE_INSTALL_PREFIX})
