SET( target_name energyplus_tests )

SET( ${target_name}_src
  EnergyPlusTestFixture.hpp
  EnergyPlusTestFixture.cpp
  EnergyPlusTranslators_GTest.cpp
  EnergyPlusProfileFixture.hpp
  EnergyPlusProfileFixture.cpp
  EnergyPlusProfileTranslators_GTest.cpp
)


# Example IDFs
FILE(GLOB idftests "${ENERGYPLUS_EXAMPLES_DIR}/*.idf")
LIST(SORT idftests)
FOREACH(idf ${idftests})
  SET(idffiles "${idffiles} \"${idf}\", ")
ENDFOREACH()
SET(idffiles "${idffiles} 0")

# Reference building OSM files
FILE(GLOB osmtests "${CMAKE_SOURCE_DIR}/energyplus/ReferenceBuildings/*.osm")
LIST(SORT osmtests)
FOREACH(osm ${osmtests})
  SET(osmfiles "${osmfiles} \"${osm}\", ")
ENDFOREACH()
SET(osmfiles "${osmfiles} 0")

CONFIGURE_FILE("EnergyPlusBin.hxx.in" "${CMAKE_CURRENT_BINARY_DIR}/EnergyPlusBin.hxx")

CREATE_TEST_TARGET( ${target_name} "${${target_name}_src}" "${${target_name}_depends}")

SET(testincrement 0)
FOREACH(idf ${idftests})
  file(RELATIVE_PATH relativepath "${ENERGYPLUS_EXAMPLES_DIR}"  "${idf}")

  add_test('TranslatorExampleFileComparisonTest/EnergyPlusTestFixture.PostProcessComparison/${relativepath}' "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${target_name}" --gtest_filter=TranslatorExampleFileComparisonTest/EnergyPlusTestFixture.PostProcessComparison/${testincrement})

  add_test('TranslatorExampleFileComparisonTest/EnergyPlusTestFixture.ConversionFileComparison/${relativepath}' "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${target_name}" --gtest_filter=TranslatorExampleFileComparisonTest/EnergyPlusTestFixture.ConversionFileComparison/${testincrement})

  math(EXPR testincrement "${testincrement} + 1")
ENDFOREACH()

SET(testincrement 0)
FOREACH(osm ${osmtests})
  file(RELATIVE_PATH relativepath "${CMAKE_SOURCE_DIR}/energyplus/ReferenceBuildings/"  "${osm}")

  add_test('TranslatorReferenceFileComparisonTest/EnergyPlusTestFixture.ProcessComparison/${relativepath}' "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${target_name}" --gtest_filter=TranslatorReferenceFileComparisonTest/EnergyPlusTestFixture.PostProcessComparison/${testincrement})

  add_test('TranslatorReferenceFileComparisonTest/EnergyPlusTestFixture.ConversionFileComparison/${relativepath}' "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${target_name}" --gtest_filter=TranslatorReferenceFileComparisonTest/EnergyPlusTestFixture.ConversionFileComparison/${testincrement})


  math(EXPR testincrement "${testincrement} + 1")
ENDFOREACH()


ADD_DEPENDENCIES( ${target_name} model_resources energyplus_resources weatherdata_resources)
