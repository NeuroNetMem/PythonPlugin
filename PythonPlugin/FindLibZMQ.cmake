# - Try to find libzmq
# Once done this will define
#
#  LIBZMQ_FOUND - system has libzmq
#  LIBZMQ_INCLUDE_DIRS - the libzmq include directory
#  LIBZMQ_LIBRARIES - Link these to use libzmq
#  LIBZMQ_DEFINITIONS - Compiler switches required for using libzmq
#
#  Adapted from cmake-modules Google Code project
#
#  Copyright (c) 2006 Andreas Schneider <mail@cynapses.org>
#
#  (Changes for libzmq) Copyright (c) 2018 Ben Acland
#
# Redistribution and use is allowed according to the terms of the New BSD license.
# For details see the accompanying COPYING-CMAKE-SCRIPTS file.
#

# first we'll try with pkg-config
if (PKG_CONFIG_FOUND)
  pkg_check_modules(LIBZMQ libzmq)
else (PKG_CONFIG_FOUND)
  if (NOT libzmq_FIND_QUIETLY)
    message(STATUS "Could not find pkg-config!!")
  endif (NOT libzmq_FIND_QUIETLY)
endif (PKG_CONFIG_FOUND)

if (LIBZMQ_LIBRARIES AND LIBZMQ_INCLUDE_DIRS)
  # in cache already
  set(LIBZMQ_FOUND TRUE)
else (LIBZMQ_LIBRARIES AND LIBZMQ_INCLUDE_DIRS)
  find_path(LIBZMQ_INCLUDE_DIR
    NAMES
      zmq.h
    PATHS
      /usr/include
      /usr/local/include
      /opt/local/include
      /sw/include
  )

  set(CMAKE_FIND_LIBRARY_PREFIXES lib l)
  find_library(LIBZMQ_LIBRARY
    NAMES
      zmq
    PATHS
      /usr/lib
      /usr/local/lib
      /opt/local/lib
      /sw/lib
  )

  set(LIBZMQ_INCLUDE_DIRS
    ${LIBZMQ_INCLUDE_DIR}
  )
  set(LIBZMQ_LIBRARIES
    ${LIBZMQ_LIBRARY}
)

  if (LIBZMQ_INCLUDE_DIRS AND LIBZMQ_LIBRARIES)
     set(LIBZMQ_FOUND TRUE)
  endif (LIBZMQ_INCLUDE_DIRS AND LIBZMQ_LIBRARIES)
endif (LIBZMQ_LIBRARIES AND LIBZMQ_INCLUDE_DIRS)

if (LIBZMQ_FOUND)
  if (NOT libzmq_FIND_QUIETLY)
    message(STATUS "Found libzmq:")
  message(STATUS " - Includes: ${LIBZMQ_INCLUDE_DIRS}")
  message(STATUS " - Libraries: ${LIBZMQ_LIBRARIES}")
  endif (NOT libzmq_FIND_QUIETLY)
else (LIBZMQ_FOUND)
  if (libzmq_FIND_REQUIRED)
    message(FATAL_ERROR "Could not find libzmq")
  endif (libzmq_FIND_REQUIRED)
endif (LIBZMQ_FOUND)

# show the LIBZMQ_INCLUDE_DIRS and LIBZMQ_LIBRARIES variables only in the advanced view
mark_as_advanced(LIBZMQ_INCLUDE_DIRS LIBZMQ_LIBRARIES)
