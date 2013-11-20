SET( target_name contam_tests )

SET( ${target_name}_src
  CONTAMSimulationFixture.hpp
  CONTAMSimulationFixture.cpp
  CONTAMSimulation_GTest.cpp
)

SET( ${target_name}_depends
 ${OPENSTUDIO_LIBS}
)

CREATE_TEST_TARGET( ${target_name} "${${target_name}_src}" "${${target_name}_depends}")

CONFIGURE_FILE("CONTAM.hxx.in" "${CMAKE_CURRENT_BINARY_DIR}/CONTAM.hxx")

ADD_DEPENDENCIES( ${target_name} weatherdata_resources )

