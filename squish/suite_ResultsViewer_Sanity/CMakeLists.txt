set( target_name suite_ResultsViewer_Sanity )

# List all the directories of the test cases here
set( test_cases 
	tst_OpenResultFile
	tst_LinePlot
	tst_FloodPlot
)

# Add each test case as a Squish Qt test
foreach( t ${test_cases} )
	if(SQUISH_FOUND)
		SQUISH_ADD_TEST( "${t}" ResultsViewer "${CMAKE_CURRENT_SOURCE_DIR}/${t}" "" "QT" )
	endif(SQUISH_FOUND)
endforeach( t ${test_cases} )
