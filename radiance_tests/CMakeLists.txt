SET( target_name radiance_tests )

SET( ${target_name}_src
  RadianceSimulationFixture.hpp
  RadianceSimulationFixture.cpp
  RadianceSimulation_GTest.cpp
)

SET( ${target_name}_depends
 ${OPENSTUDIO_LIBS}
)

CREATE_TEST_TARGET( ${target_name} "${${target_name}_src}" "${${target_name}_depends}")

CONFIGURE_FILE("RadianceBin.hxx.in" "${CMAKE_CURRENT_BINARY_DIR}/RadianceBin.hxx")

ADD_DEPENDENCIES( ${target_name} model_resources weatherdata_resources )

