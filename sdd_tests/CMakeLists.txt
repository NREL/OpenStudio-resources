SET( target_name sdd_tests )

SET( ${target_name}_src
  SDDSimulationFixture.hpp
  SDDSimulationFixture.cpp
  SDDSimulation_GTest.cpp
)

SET( ${target_name}_depends
 ${OPENSTUDIO_LIBS}
)

CREATE_TEST_TARGET( ${target_name} "${${target_name}_src}" "${${target_name}_depends}")

CONFIGURE_FILE("SDDBin.hxx.in" "${CMAKE_CURRENT_BINARY_DIR}/SDDBin.hxx")

ADD_DEPENDENCIES( ${target_name} weatherdata_resources )

