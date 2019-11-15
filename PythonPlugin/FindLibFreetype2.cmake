# - Try to find libfreetype2
# Once done this will define
#
#  LIBFREETYPE2_FOUND - system has libfreetype2
#  LIBFREETYPE2_INCLUDE_DIRS - the libfreetype2 include directory
#  LIBFREETYPE2_LIBRARIES - Link these to use libfreetype2
#  LIBFREETYPE2_DEFINITIONS - Compiler switches required for using libfreetype2
#
#  Adapted from cmake-modules Google Code project
#
#  Copyright (c) 2006 Andreas Schneider <mail@cynapses.org>
#
#  (Changes for libfreetype2) Copyright (c) 2018 Ben Acland
#
# Redistribution and use is allowed according to the terms of the New BSD license.
# For details see the accompanying COPYING-CMAKE-SCRIPTS file.
#

if (LIBFREETYPE2_LIBRARIES AND LIBFREETYPE2_INCLUDE_DIRS)
  # in cache already
  set(LIBFREETYPE2_FOUND TRUE)
else (LIBFREETYPE2_LIBRARIES AND LIBFREETYPE2_INCLUDE_DIRS)
  find_path(LIBFREETYPE2_INCLUDE_DIR
    NAMES
      freetype.h
    PATHS
      /usr/include
      /usr/local/include
      /opt/local/include
      /sw/include
      /usr/include/freetype2/freetype
  )

  set(CMAKE_FIND_LIBRARY_PREFIXES lib)
  find_library(LIBFREETYPE2_LIBRARY
    NAMES
      freetype
    PATHS
      /usr/lib
      /usr/local/lib
      /opt/local/lib
      /sw/lib
      /usr/lib/x86_64-linux-gnu
  )

  set(LIBFREETYPE2_INCLUDE_DIRS
    ${LIBFREETYPE2_INCLUDE_DIR}
  )
  set(LIBFREETYPE2_LIBRARIES
    ${LIBFREETYPE2_LIBRARY}
)

  if (LIBFREETYPE2_INCLUDE_DIRS AND LIBFREETYPE2_LIBRARIES)
     set(LIBFREETYPE2_FOUND TRUE)
  endif (LIBFREETYPE2_INCLUDE_DIRS AND LIBFREETYPE2_LIBRARIES)

  if (LIBFREETYPE2_FOUND)
    if (NOT libfreetype2_FIND_QUIETLY)
      message(STATUS "Found libfreetype2:")
    message(STATUS " - Includes: ${LIBFREETYPE2_INCLUDE_DIRS}")
    message(STATUS " - Libraries: ${LIBFREETYPE2_LIBRARIES}")
    endif (NOT libfreetype2_FIND_QUIETLY)
  else (LIBFREETYPE2_FOUND)
    if (libfreetype2_FIND_REQUIRED)
      message(FATAL_ERROR "Could not find libfreetype2")
    endif (libfreetype2_FIND_REQUIRED)
  endif (LIBFREETYPE2_FOUND)

  # show the LIBFREETYPE2_INCLUDE_DIRS and LIBFREETYPE2_LIBRARIES variables only in the advanced view
  mark_as_advanced(LIBFREETYPE2_INCLUDE_DIRS LIBFREETYPE2_LIBRARIES)

endif (LIBFREETYPE2_LIBRARIES AND LIBFREETYPE2_INCLUDE_DIRS)
