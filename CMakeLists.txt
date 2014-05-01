CMAKE_MINIMUM_REQUIRED( VERSION 2.8 )
 
PROJECT(OpenStudioRegression)

###############################################################################
# Add to include path

CONFIGURE_FILE( "resources.in" "${CMAKE_BINARY_DIR}/resources.hxx" )

# Project source directory
INCLUDE_DIRECTORIES( "${CMAKE_SOURCE_DIR}/" )

# Project binary directory
INCLUDE_DIRECTORIES( "${CMAKE_BINARY_DIR}/" )
###############################################################################

###############################################################################
# Sub projects

# Creating options to enable the various sub-projects
option( BUILD_ANALYSISDRIVER_TESTS "Build the analysisdriver tests" ON )
option( BUILD_ENERGYPLUS_TESTS "Build the energyplus tests" ON )
option( BUILD_MODEL_TESTS "Build the model tests" ON )
option( BUILD_PROJECT_TESTS "Build the project tests" ON )
option( BUILD_RUBY_TESTS "Build the ruby tests" ON )
option( BUILD_RUNMANAGER_TESTS "Build the runmanager tests" ON )
option( BUILD_SDD_TESTS "Build the sdd tests" OFF )
option( BUILD_CONTAM_TESTS "Build the CONTAM tests" OFF )
option( BUILD_SQUISH_SKETCHUP_TESTS "Build the SketchUp plugin tests" OFF )
option( BUILD_SQUISH_QT_TESTS "Build the OpenStudio QT application Squish tests" OFF )
option( BUILD_UTILITIES_TESTS "Build the utilities tests" ON )
option( REQUIRE_OSSERVER OFF )

# Point to OpenStudio
SET( OPENSTUDIO_BUILD_DIR "" CACHE PATH "Build or install directory for OpenStudio build to link against")
SET( OPENSTUDIOCORE_BUILD_DIR "${OPENSTUDIO_BUILD_DIR}/OpenStudioCore-prefix/src/OpenStudioCore-build")
INCLUDE ( "${OPENSTUDIO_BUILD_DIR}/OpenStudioCore-prefix/src/OpenStudioCore-build/OpenStudioCoreConfig.cmake" )

# Point to openstudio-server
SET( OSSERVER_PATH "" CACHE PATH "Path to your openstudio-server repository." )

IF(MSVC)
  # Build with Multiple Processes
  OPTION( BUILD_WITH_MULTIPLE_PROCESSES "/MP compiler flag for full processor utilization" ON )
  MARK_AS_ADVANCED( BUILD_WITH_MULTIPLE_PROCESSES )
ENDIF()

# NOTE: 3/17/2011 JC - I am only going to include the subdirectories for the tests
#       based on whether the option is set or not, instead of just including them all
# Each subfolder of src is a major sub-project
#SET( project_directories
#  model_tests
#  ruby
#  squish
#)
###############################################################################

###############################################################################
# CMake control  

# High level project configuration
SET( CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/Products" )
SET( CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/Products" )
SET( CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/Products" )

SET ( LIBRARY_SEARCH_DIRECTORY "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}" "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/Release" "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/Debug" )

# Include project specific macros
INCLUDE(ProjectMacros.cmake)

# Search for modules in the root dir first to override cmake ones 
LIST(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR})

# Use CTest
ENABLE_TESTING()
INCLUDE(CTest) 
###############################################################################

###############################################################################
# Compiler and system specific options
IF(UNIX)
  # all warnings
  SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -fPIC -fno-strict-aliasing")
  SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -fPIC -fno-strict-aliasing")
  # effective c++
  #SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Weffc++")
  # treat warnings as errors
  #SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Werror")
ENDIF(UNIX)
IF(APPLE AND NOT CMAKE_COMPILER_IS_GNUCXX)
  SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -stdlib=libstdc++")
  SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -stdlib=libstdc++")
ENDIF()
IF(MINGW)
  # all warnings
  SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall")
  # effective c++
  #SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Weffc++")
  # treat warnings as errors
  #SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Werror")
  
  # wchar not supported for MinGW
  ADD_DEFINITIONS(-DBOOST_LOG_USE_CHAR)
  ADD_DEFINITIONS(-DBOOST_LOG_NO_COMPILER_TLS)
ENDIF(MINGW)
IF(MSVC)
  # warning level 3
  SET(CMAKE_CXX_WARNING_LEVEL 3)
  # all warnings
  #SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /Wall")
  # create compiler processes on all effective processors
  IF(BUILD_WITH_MULTIPLE_PROCESSES)
    SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /MP")
  ENDIF(BUILD_WITH_MULTIPLE_PROCESSES)
  # ignore first seen as struct now using class
  SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /wd4099")
  # ignore decorated name length exceeded
  SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /wd4503")
  # ignore needs to have dll-interface to be used by clients of class
  # we will not rely on exporting templates instead all libraries must 
  # be linked against the same runtime
  SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /wd4251")
  # treat warnings as errors
  SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /WX")
  # ignore warnings about the stl being insecure
  ADD_DEFINITIONS(-D_CRT_SECURE_NO_WARNINGS -D_SCL_SECURE_NO_WARNINGS)
ENDIF(MSVC)
###############################################################################

###############################################################################
# Required dependencies 

# OpenStudio
INCLUDE_DIRECTORIES( ${OpenStudioCore_INCLUDE_DIRS} )

option(  "Build the SketchUp plugin tests" OFF )
option( BUILD_SQUISH_QT_TESTS "Build the OpenStudio QT application Squish tests" OFF )

IF(BUILD_SQUISH_SKETCHUP_TESTS OR BUILD_SQUISH_QT_TESTS)
  find_package(Squish)
  IF(SQUISH_FOUND)
    message("Found Squish: ${SQUISH_INSTALL_DIR}")
  ELSE(SQUISH_FOUND)
    message("ERROR: Squish not found")
  ENDIF(SQUISH_FOUND)
ENDIF()


#IF(MSVC)
#  SET(OPENSTUDIO_LIB_DIR "${OPENSTUDIO_BUILD_DIR}/Products/$<CONFIGURATION>")
#ELSE(MSVC)
#  SET(OPENSTUDIO_LIB_DIR "${OPENSTUDIO_BUILD_DIR}/Products")
#ENDIF(MSVC)

IF(MSVC)
  file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/Products/Debug")
  file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/Products/Release")
  file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/Products/RelWithDebInfo")
  list( APPEND CMAKE_LIBRARY_PATH ${OPENSTUDIO_LIB_DIR} )

  file(GLOB DEBUG_DLLS "${OPENSTUDIO_BUILD_DIR}/OpenStudioCore-prefix/src/OpenStudioCore-build/Products/Debug/*.dll")
  file(GLOB RELEASE_DLLS "${OPENSTUDIO_BUILD_DIR}/OpenStudioCore-prefix/src/OpenStudioCore-build/Products/Release/*.dll")
  file(GLOB RELDBG_DLLS "${OPENSTUDIO_BUILD_DIR}/OpenStudioCore-prefix/src/OpenStudioCore-build/Products/RelWithDebInfo/*.dll")

  list( APPEND ALL_DLLS ${DEBUG_DLLS} )
  list( APPEND ALL_DLLS ${RELEASE_DLLS} )
  list( APPEND ALL_DLLS ${RELDBG_DLLS} )
  list( LENGTH ALL_DLLS NUM_DLLS )
  message("Copying ${NUM_DLLS} DLLs under ${OPENSTUDIO_BUILD_DIR} to ${CMAKE_BINARY_DIR}")
  file(COPY ${DEBUG_DLLS} DESTINATION "${CMAKE_BINARY_DIR}/Products/Debug/")
  file(COPY ${RELEASE_DLLS} DESTINATION "${CMAKE_BINARY_DIR}/Products/Release/")
  file(COPY ${RELDBG_DLLS} DESTINATION "${CMAKE_BINARY_DIR}/Products/RelWithDebInfo/")
ENDIF()

link_directories(${OpenStudioCore_LIBRARY_DIRS})

SET(OPENSTUDIO_LIBS
  gtest
  gtest_main
  zkqwt
  litesql
  litesql-util
  openstudio_utilities
  openstudio_model
  openstudio_energyplus
  openstudio_runmanager
  openstudio_ruleset
  openstudio_project
  openstudio_analysis
  openstudio_analysisdriver
  openstudio_sdd
  openstudio_ruleset
)

if( BUILD_RULESENGINE_TESTS )
  LIST( APPEND OPENSTUDIO_LIBS openstudio_rulesengine )
endif( BUILD_RULESENGINE_TESTS )

if( BUILD_CONTAM_TESTS )
  LIST( APPEND OPENSTUDIO_LIBS openstudio_contam )
endif( BUILD_CONTAM_TESTS )

# EnergyPlus
FIND_PACKAGE(EnergyPlus "8.1" REQUIRED)
MARK_AS_ADVANCED(
  ENERGYPLUS_EXE
  ENERGYPLUS_IDD
  ENERGYPLUS_WEATHER_DIR
  ENERGYPLUS_EXAMPLES_DIR
)

# Ruby
FIND_PROGRAM( RUBY_EXECUTABLE NAMES ruby PATHS $ENV{CMAKE_RUBY_PATH} NO_SYSTEM_ENVIRONMENT_PATH )
FIND_PACKAGE( Ruby REQUIRED )

# Google test library
ADD_DEFINITIONS( -DGTEST_HAS_TR1_TUPLE=0 )

# Enable support for boost > 1.42 ish by forcing boost_filesystem_version 2
ADD_DEFINITIONS(-DBOOST_FILESYSTEM_VERSION=2)

# Boost
IF(APPLE)
  set(Boost_USE_STATIC_LIBS ON)  
ENDIF()
IF (WIN32)
  set(Boost_USE_STATIC_LIBS ON)  

  #uncomment all of this if we want to force dynamic libs on windows
#  set(Boost_USE_STATIC_LIBS OFF)  
#  ADD_DEFINITIONS( -DBOOST_THREAD_USE_DLL -DBOOST_THREAD_DYN_LINK -DBOOST_PROGRAM_OPTIONS_DYN_LINK  -DBOOST_REGEX_DYN_LINK  -DBOOST_FILESYSTEM_DYN_LINK -DBOOST_SYSTEM_DYN_LINK -DBOOST_SERIALIZATION_DYN_LINK  -DBOOST_DATE_TIME_DYN_LINK)
#  LINK_DIRECTORIES( ${Boost_LIBRARY_DIRS} )
#  IF (MSVC)
#    #Ignore dll specific warnings that are out of our hands to control, coming from external projects
#    ADD_DEFINITIONS( "/wd4251 /wd4275" )
#  ENDIF (MSVC)
ENDIF (WIN32)

SET( Boost_ADDITIONAL_VERSIONS "1.40" )
FIND_PACKAGE( Boost 1.40.0 REQUIRED COMPONENTS filesystem regex program_options system thread date_time serialization)
INCLUDE_DIRECTORIES( ${Boost_INCLUDE_DIR} )
MARK_AS_ADVANCED( Boost_LIB_DIAGNOSTIC_DEFINITIONS )

# Boost-log
ADD_DEFINITIONS( -DBOOST_LOG_NO_LIB ) # disable autolinking
ADD_DEFINITIONS( -DBOOST_LOG_SETUP_NO_LIB ) # disable autolinking


find_package(BoostLog REQUIRED HINTS "${OPENSTUDIO_BUILD_DIR}/BoostLog-prefix/src/BoostLog-build")
INCLUDE_DIRECTORIES( ${BoostLog_INCLUDE_DIRS} )
LINK_DIRECTORIES( ${BoostLog_LIBRARY_DIRS} )


# SketchUp executable location needed for testing
if( BUILD_SQUISH_SKETCHUP_TESTS )
  set( SKETCHUP_8_DIR "" CACHE PATH "Path to SketchUp 8 executable" )
endif( BUILD_SQUISH_SKETCHUP_TESTS )

#--------------------------------------------------------------------------------
# Qt
FIND_PACKAGE (Qt4 4.6.0 COMPONENTS QtCore QtGui QtNetwork QtXml REQUIRED)
INCLUDE_DIRECTORIES( ${QT_INCLUDE_DIR} )
#LIST( APPEND CMAKE_PROGRAM_PATH ${QT_LIBRARY_DIR})
#LIST( APPEND CMAKE_LIBRARY_PATH ${QT_LIBRARY_DIR})
#--------------------------------------------------------------------------------
# QT_USE_FILE is a variable defined by FIND_PACKAGE( Qt4 ) that contains a path to
# a CMake script that sets up this directory for building with Qt4
INCLUDE( ${QT_USE_FILE} )
MARK_AS_ADVANCED( QT_QMAKE_EXECUTABLE QT_QTMOTIF_INCLUDE_DIR QT_QTMOTIF_LIBRARY_DEBUG QT_QTMOTIF_LIBRARY_RELEASE )

# This sets the windows build that will need the special winmain@16 call. Qt provides
#  this for us in the qtmain.lib file. Using this cmake code will ensure we have it
#  linked into our build. Not needed on Unix/OS X/Linux which is why we have the 
#  IF(WIN32) conditional.
IF (WIN32)
    SET (QT_USE_QTMAIN TRUE)
ENDIF (WIN32)

#--------------------------------------------------------------------------------
# QT_USE_FILE is a variable defined by FIND_PACKAGE( Qt4 ) that contains a path to
# a CMake script that sets up this directory for building with Qt4
INCLUDE( ${QT_USE_FILE} )

#Adding the qtnetwork library to the includes
INCLUDE_DIRECTORIES( ${QT_QTSQL_INCLUDE_DIR} )
INCLUDE_DIRECTORIES( ${QT_QTNETWORK_INCLUDE_DIR} )
INCLUDE_DIRECTORIES( ${QT_QTXML_INCLUDE_DIR} )

# list of all Qt libs and dependencies we are using
LIST( APPEND QT_LIBS ${QT_QTSQL_LIBRARY})
LIST( APPEND QT_LIBS ${QT_QTGUI_LIBRARY})
LIST( APPEND QT_LIBS ${QT_QTGUI_LIB_DEPENDENCIES})
LIST( APPEND QT_LIBS ${QT_QTCORE_LIBRARY})
LIST( APPEND QT_LIBS ${QT_QTCORE_LIB_DEPENDENCIES})
LIST( APPEND QT_LIBS ${QT_QTMAIN_LIBRARY})
LIST( APPEND QT_LIBS ${QT_QTNETWORK_LIBRARY})
LIST( APPEND QT_LIBS ${QT_QTNETWORK_LIB_DEPENDENCIES})
LIST( APPEND QT_LIBS ${QT_QTXML_LIBRARY})
LIST( APPEND QT_LIBS ${QT_QTXML_LIB_DEPENDENCIES})
###############################################################################

# QJSON

find_package(QJSON REQUIRED HINTS "${OPENSTUDIO_BUILD_DIR}/QJSON-prefix/src/QJSON-build")
INCLUDE_DIRECTORIES( SYSTEM ${QJSON_INCLUDE_DIR} )
LINK_DIRECTORIES( ${QJSON_LIBRARY_DIRS} )

# openstudio-server

IF (EXISTS "${OSSERVER_PATH}")
  SET (OSSERVER_FOUND TRUE)
  CONFIGURE_FILE("Vagrant.hxx.in" "${CMAKE_CURRENT_BINARY_DIR}/Vagrant.hxx")
ELSE (EXISTS "${OSSERVER_PATH}")
  SET (OSSERVER_FOUND FALSE)
  IF (REQUIRE_OSSERVER) 
    MESSAGE(SEND_ERROR "Error: Required resource openstudio-server not found.")
  ENDIF (REQUIRE_OSSERVER)
ENDIF(EXISTS "${OSSERVER_PATH}")
SET(OSSERVER_FOUND ${OSSERVER_FOUND} CACHE INTERNAL "Boolean indicating whether openstudio-server was found.")

###############################################################################
# Add project sub directories

# Include the resources, should happen after find EnergyPlus
ADD_SUBDIRECTORY(energyplus)

# Only adding subdirectories based on options set during the configure step. This way we
#  won't have to build all the tests if we don't want to.
if( BUILD_MODEL_TESTS )
  add_subdirectory( model_tests )
endif( BUILD_MODEL_TESTS )

if( BUILD_SDD_TESTS )
  add_subdirectory( sdd_tests )
endif( BUILD_SDD_TESTS )

if( BUILD_CONTAM_TESTS )
  FIND_PROGRAM( CONTAM_EXECUTABLE NAMES contamx3 )
  FIND_PROGRAM( SIMREAD_EXECUTABLE NAMES simread3 )
  add_subdirectory( contam_tests )
endif( BUILD_CONTAM_TESTS )

if( BUILD_RUBY_TESTS )
  add_subdirectory( ruby )
endif( BUILD_RUBY_TESTS )

if( BUILD_SQUISH_SKETCHUP_TESTS OR BUILD_SQUISH_QT_TESTS )
  add_subdirectory( squish )
endif( BUILD_SQUISH_SKETCHUP_TESTS OR BUILD_SQUISH_QT_TESTS )

ADD_SUBDIRECTORY( weatherdata )

option( BUILD_ENERGYPLUS_TESTS "Build the energyplus tests" ON )

ADD_SUBDIRECTORY( runmanager )

if( BUILD_RUNMANAGER_TESTS )
  ADD_SUBDIRECTORY( runmanager_tests )
endif()

ADD_SUBDIRECTORY( model )

if( BUILD_ANALYSISDRIVER_TESTS )
  ADD_SUBDIRECTORY( analysisdriver_tests )
endif()

if( BUILD_PROJECT_TESTS )
  ADD_SUBDIRECTORY( project )
  ADD_SUBDIRECTORY( project_tests )
endif()

if( BUILD_ENERGYPLUS_TESTS )
  ADD_SUBDIRECTORY( energyplus_tests )
endif()

if( BUILD_UTILITIES_TESTS )
  ADD_SUBDIRECTORY( utilities_tests )
endif()

###############################################################################

