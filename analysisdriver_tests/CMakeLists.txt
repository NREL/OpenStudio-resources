SET( target_name analysisdriver_tests )

SET( ${target_name}_src
  ${OpenStudioCore_CMAKE_DIR}/src/analysisdriver/test/AnalysisDriverTestLibrary.hpp
  ${OpenStudioCore_CMAKE_DIR}/src/analysisdriver/test/AnalysisDriverTestLibrary.cpp
  AnalysisDriverFixture.hpp
  AnalysisDriverFixture.cpp
  AnalysisDriver_GTest.cpp
)

IF( OSSERVER_FOUND )
  LIST(APPEND ${target_name}_src
    CloudFixture.hpp
    CloudFixture.cpp
    CloudAnalysisDriver_GTest.cpp
  )
ENDIF( OSSERVER_FOUND )

SET( ${target_name}_depends
 ${OPENSTUDIO_LIBS}
)

CREATE_TEST_TARGET( ${target_name} "${${target_name}_src}" "${${target_name}_depends}" )

ADD_DEPENDENCIES(${target_name}
  energyplus_resources
  model_resources
  runmanager_resources )
