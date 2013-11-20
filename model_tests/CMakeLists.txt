SET( target_name model_tests )

SET( ${target_name}_src
  ModelFixture.hpp
  ModelFixture.cpp
  Alpha1_GTest.cpp
  Intersection_GTest.cpp
  TimeDependentValuation_GTest.cpp
  ModelProfileFixture.hpp
  ModelProfileFixture.cpp
  ModelProfiling_GTest.cpp
  ModelSimulationFixture.hpp
  ModelSimulationFixture.cpp
  ModelSimulation_GTest.cpp
)

SET( ${target_name}_depends
 ${OPENSTUDIO_LIBS}
)

CREATE_TEST_TARGET( ${target_name} "${${target_name}_src}" "${${target_name}_depends}")

CONFIGURE_FILE("ModelBin.hxx.in" "${CMAKE_CURRENT_BINARY_DIR}/ModelBin.hxx")

CONFIGURE_FILE("Coverage.rb.in" "${CMAKE_CURRENT_BINARY_DIR}/Coverage.rb")

ADD_CUSTOM_TARGET(coverage_report "${RUBY_EXECUTABLE}" "${CMAKE_CURRENT_BINARY_DIR}/Coverage.rb")

ADD_DEPENDENCIES( ${target_name} model_resources weatherdata_resources )

