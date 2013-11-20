# This file will configure the test directories for the squish tests and add the tests


##### Tests for bad idf files #####

include( bad_IDF_files/CMakeLists.txt ) # sets test_idfs list
set( target_name suite_OSSP_XP_IDF_bad )
# Create a directory for each test in the build directory
foreach( f ${test_idfs} )
	string( REGEX REPLACE "(^.*)[/\\](.*$)" \\2 fname "${f}" )
	configure_file( "${CMAKE_CURRENT_SOURCE_DIR}/GenScripts/OSSP_XP_IDF_bad_test.js" 
		"${CMAKE_CURRENT_BINARY_DIR}/${target_name}/tst_${fname}/test.js" COPYONLY )
	if(SQUISH_FOUND)
		# add the squish test case for each file using the macro from the findSquish module:
		# SQUISH_ADD_TEST( testName testAUT testCase envVars testWrapper )
		#SQUISH_ADD_TEST( )
	endif(SQUISH_FOUND)
endforeach( f ${test_idfs} )
# Copy the shared files into the build directory
configure_file( "${CMAKE_CURRENT_SOURCE_DIR}/GenScripts/OSSP_XP_IDF_bad_script_shared.js"
	"${CMAKE_CURRENT_BINARY_DIR}/${target_name}/shared/scripts/script_shared.js" COPYONLY )
configure_file( "${CMAKE_CURRENT_SOURCE_DIR}/GenScripts/OSSP_XP_IDF_bad_objects.map"
	"${CMAKE_CURRENT_BINARY_DIR}/${target_name}/objects.map" COPYONLY )
configure_file( "${CMAKE_CURRENT_SOURCE_DIR}/GenScripts/OSSP_XP_IDF_bad_suite.conf"
	"${CMAKE_CURRENT_BINARY_DIR}/${target_name}/suite.conf" COPYONLY )


##### Tests for EnergyPlus example files #####

include( EP6_sample_files/CMakeLists.txt ) # sets xmpl_idfs list
set( target_name suite_OSSP_XP_IDF_xmpl )
# Create a directory for each test in the build directory
foreach( f ${xmpl_idfs} )
	string( REGEX REPLACE "(^.*)[/\\](.*$)" \\2 fname "${f}" )
	configure_file( "${CMAKE_CURRENT_SOURCE_DIR}/GenScripts/OSSP_XP_IDF_xmpl_test.js" 
		"${CMAKE_CURRENT_BINARY_DIR}/${target_name}/tst_${fname}/test.js" COPYONLY )
	if(SQUISH_FOUND)
		# add the squish test case for each file using the macro from the findSquish module:
		# SQUISH_ADD_TEST( testName testAUT testCase envVars testWrapper )
		SQUISH_ADD_TEST( ${fname} SketchUp "${CMAKE_CURRENT_BINARY_DIR}/${target_name}/tst_${fname}"
			"" "Windows" )
	endif(SQUISH_FOUND)
endforeach( f ${xmpl_idfs} )
# Copy the shared files into the build directory
configure_file( "${CMAKE_CURRENT_SOURCE_DIR}/GenScripts/OSSP_XP_IDF_xmpl_script_shared.js"
	"${CMAKE_CURRENT_BINARY_DIR}/${target_name}/shared/scripts/script_shared.js" COPYONLY )
configure_file( "${CMAKE_CURRENT_SOURCE_DIR}/GenScripts/OSSP_XP_IDF_xmpl_objects.map"
	"${CMAKE_CURRENT_BINARY_DIR}/${target_name}/objects.map" COPYONLY )
configure_file( "${CMAKE_CURRENT_SOURCE_DIR}/GenScripts/OSSP_XP_IDF_xmpl_suite.conf"
	"${CMAKE_CURRENT_BINARY_DIR}/${target_name}/suite.conf" COPYONLY )
