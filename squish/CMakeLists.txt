# Squish is found in the top level CMakeLists.txt file. If it was found all the appropriate
# variables should be set now.
# NOTE: 1/24/2011 JC - Currently you need to manually set the Squish directory to one of the 
#   installed Squish directories. This will need to be made more adaptable if we want to run  
#   different types of Squish tests
if (SQUISH_FOUND)
  find_program( SKETCHUP_8_EXE NAMES SketchUp.exe PATHS "$ENV{ProgramFiles}/Google/Google SketchUp 8/" )
  if (SKETCHUP_8_EXE)
    #CONFIGURE_FILE( ${CMAKE_SOURCE_DIR}/Doxyfile.in ${CMAKE_BINARY_DIR}/Doxyfile_${DOC_NAME} )
		#SQUISH_ADD_TEST("squish_tst_zz_time_log_8" "${SKETCHUP_8_EXE}" "${CMAKE_SOURCE_DIR}/squish/suite_SP110_SU8_XP_001tests" "" "tst_zz_time_log")
  endif (SKETCHUP_8_EXE)
  
else (SQUISH_FOUND)
	message("ERROR: Squish not found")
endif (SQUISH_FOUND)

#set( SU_SQUISH_TEST_DIRS
#	bad_IDF_files
#)
#
#foreach( D ${SU_SQUISH_TEST_DIRS} )
#	add_subdirectory( SquishTestingResources/${D} )
#endforeach( D ${SU_SQUISH_TEST_DIRS} )

# NOTE: 3/13/2011 Not sure if it will cause problems if both these options are turned on at the
#       same time.
if( BUILD_SQUISH_SKETCHUP_TESTS )
  add_subdirectory( SquishTestingResources )
endif( BUILD_SQUISH_SKETCHUP_TESTS )

if( BUILD_SQUISH_QT_TESTS )
	add_subdirectory( suite_RunManager_Sanity )
	add_subdirectory( suite_ResultsViewer_Sanity )
endif( BUILD_SQUISH_QT_TESTS )

