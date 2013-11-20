cmake_minimum_required( VERSION 2.8 )
############################################################################################
# The intention of this script is to automate squish testing of the OpenStudio plugin.
############################################################################################

##### Variable Setup #######################################################################
# The OpenStudio directories are not necessary for the tests, but are needed for configuration
set( OPENSTUDIO_DIR "C:/projects/openstudio" )
set( OPENSTUDIO_BUILD_DIR "${OPENSTUDIO_DIR}/build" )
set( OPENSTUDIO_LIB_DIR "${OPENSTUDIO_BUILD_DIR}/Products/Debug" )

# Squish directory paths
set( SQUISH_WINDOWS_PATH "C:/Squish/squish-4.0.2-windows" )
set( SQUISH_QT_PATH "" )

# SketchUp directory
set( sketchup_8_dir "C:/Program Files/Google/Google SketchUp 8" )

# CTest Variables
set( generator "Visual Studio 9 2008" )  # Needs to be set so CMake knows how to configure
set( win_version "XP" )
set( ctest_source_dir "C:/projects/openstudio-resources" )
set( ctest_binary_dir "C:/projects/openstudio-resources/build" )
set( svn_url "https://cbr.nrel.gov/openstudio-resources/svn/trunk" )


##### Project configuration ###############################################################
set( CTEST_PROJECT_NAME OpenStudio )
site_name( SITE )
set( CTEST_SITE ${SITE} )
set( CTEST_BUILD_NAME "${CMAKE_SYSTEM_NAME}-SquishTesting" )

set( CTEST_SOURCE_DIRECTORY "${ctest_source_dir}" )
set( CTEST_BINARY_DIRECTORY "${ctest_binary_dir}" )

# set only one package name (different for each platform)
set( UNIX_PACKAGE_NAME "all" )
set( MSVC_PACKAGE_NAME "ALL_BUILD" )

##### CDash configuration ##########
set( CTEST_PROJECT_NAME "OpenStudio" )
set( CTEST_NIGHTLY_START_TIME "00:00:00 MDT" )
set( CTEST_DROP_METHOD "http" )
set( CTEST_DROP_LOCATION "/submit.php?project=OpenStudio" )
set( CTEST_DROP_SITE_CDASH TRUE )

##### CTest generator configuration #######################################################
IF( ${generator} STREQUAL "Unix Makefiles" )
  SET( CTEST_CMAKE_GENERATOR "Unix Makefiles" )
  SET( CTEST_BUILD_COMMAND 
    "make -j${jobs} ${UNIX_PACKAGE_NAME}" 
  )
ELSEIF( ${generator} STREQUAL "Visual Studio 9 2008" )
  SET( CTEST_CMAKE_GENERATOR "Visual Studio 9 2008" )
  SET( MSVC_IS_EXPRESS "OFF" )
	if( ${win_version} STREQUAL "7" )
		set( CTEST_BUILD_COMMAND 
			"\"C:\\Program Files (x86)\\Microsoft Visual Studio 9.0\\Common7\\IDE\\devenv.com\" OpenStudioRegression.sln /build Release /project ${MSVC_PACKAGE_NAME}" ) 
	else()
		set( CTEST_BUILD_COMMAND 
			"\"C:\\Program Files\\Microsoft Visual Studio 9.0\\Common7\\IDE\\devenv.com\" OpenStudioRegression.sln /build Release /project ${MSVC_PACKAGE_NAME}" ) 
	endif( ${win_version} STREQUAL "7" )
ELSEIF( ${generator} STREQUAL "Visual Studio 9 2008 Express" )
  SET( CTEST_CMAKE_GENERATOR "Visual Studio 9 2008" )
  SET( MSVC_IS_EXPRESS "ON" )
	if( ${win_version} STREQUAL "7" )
		set( CTEST_BUILD_COMMAND 
			"\"C:\\Program Files (x86)\\Microsoft Visual Studio 9.0\\Common7\\IDE\\vcexpress.exe\" OpenStudioRegression.sln /build Release /project ${MSVC_PACKAGE_NAME}" ) 
	else()
		set( CTEST_BUILD_COMMAND 
		"\"C:\\Program Files\\Microsoft Visual Studio 9.0\\Common7\\IDE\\vcexpress.exe\" OpenStudioRegression.sln /build Release /project ${MSVC_PACKAGE_NAME}" ) 
	endif( ${win_version} STREQUAL "7" )
ELSEIF( ${generator} STREQUAL "Visual Studio 10" )
  SET( CTEST_CMAKE_GENERATOR "Visual Studio 10" )
  SET( MSVC_IS_EXPRESS "OFF" )
  SET( CTEST_BUILD_COMMAND 
     "\"C:\\Program Files\\Microsoft Visual Studio 10.0\\Common7\\IDE\\devenv.com\" OpenStudioRegression.sln /build Release /project ${MSVC_PACKAGE_NAME}" 
  )
ELSEIF( ${generator} STREQUAL "Visual Studio 10 Express" )
  SET( CTEST_CMAKE_GENERATOR "Visual Studio 10" )
  SET( MSVC_IS_EXPRESS "ON" )
  SET( CTEST_BUILD_COMMAND 
     "\"C:\\Program Files\\Microsoft Visual Studio 10.0\\Common7\\IDE\\vcexpress.exe\" OpenStudioRegression.sln /build Release /project ${MSVC_PACKAGE_NAME}" 
  )  
ENDIF()


##### Run CTest ###########################################################################

# NOTE: These tests assume that you have installed OpenStudio, including the Sketchup Plugin,
#    in some way. This script will make no attempt to build and/or install OpenStudio for you.
#    This test also assumes that your checkout of the openstudio-resources repository is 
#    current to the version you want it, and will not attempt to update it.

message( "starting" )
ctest_start( "Nightly" "${ctest_source_dir}" "${ctest_binary_dir}" )

set( INITIAL_CACHE "
  BUILD_MODEL_TESTS:BOOL=OFF
  BUILD_RUBY_TESTS:BOOL=OFF
  BUILD_SQUISH_SKETCHUP_TESTS:BOOL=ON
	BUILD_SQUISH_QT_TESTS:BOOL=OFF
  BUILD_TESTING:BOOL=ON
  OPENSTUDIO_BUILD_DIR:PATH=${OPENSTUDIO_BUILD_DIR}
  OPENSTUDIO_DIR:PATH=${OPENSTUDIO_DIR}
  OPENSTUDIO_LIB_DIR:PATH=${OPENSTUDIO_LIB_DIR}
  SQUISH_INSTALL_DIR:PATH=${SQUISH_WINDOWS_PATH}
	SKETCHUP_8_DIR:PATH=${sketchup_8_dir}
")

# Write an initial CMake Cache file. This will over-write any existing cache file
file( WRITE "${ctest_binary_dir}/CMakeCache.txt" "${INITIAL_CACHE}" )

# Configure
message( "configuring" )
ctest_configure( BUILD "${ctest_binary_dir}" SOURCE "${ctest_source_dir}"
                 RETURN_VALUE config_res )
if( NOT config_res EQUAL 0 )
  # Configure failed, do not submit a new package
  set( submit_package FALSE )
endif( NOT config_res EQUAL 0 )

# Build
message("building")
ctest_build( BUILD "${ctest_binary_dir}" NUMBER_ERRORS build_res )
if( NOT res EQUAL 0 )
	# Build failed, do not submit a new package
	set(submit_package FALSE)
endif( NOT res EQUAL 0 )

# Testing
message( "testing" )
ctest_test( BUILD "${ctest_binary_dir}" RETURN_VALUE test_res PARALLEL_LEVEL 1 )


