# find all tests
file(GLOB_RECURSE RUBY_TEST_SRC "./*_Test.rb")

# add a test for each unit test
SET( RUBY_TEST_REQUIRES "#include test files" )
FOREACH( f ${RUBY_TEST_SRC} )

  FILE( RELATIVE_PATH REQUIRE_NAME "${CMAKE_CURRENT_BINARY_DIR}" ${f} )
  IF(MSVC)
    SET( RUBY_TEST_REQUIRES "${RUBY_TEST_REQUIRES} \nrequire '../${REQUIRE_NAME}'" )  
  ELSE()
    SET( RUBY_TEST_REQUIRES "${RUBY_TEST_REQUIRES} \nrequire '${REQUIRE_NAME}'" )
  ENDIF()
     
  FILE( READ "${f}" CONTENTS)
  STRING( REGEX MATCHALL "def +test_([A-Za-z_0-9 ]+)" FOUND_TESTS ${CONTENTS} )

  FOREACH(HIT ${FOUND_TESTS})
    STRING(REGEX REPLACE "def +test_([A-Za-z_0-9]+)" "\\1" TEST_NAME ${HIT})
    STRING(REGEX MATCH "/?([A-Za-z_0-9 ]+)\\.rb" FILE_NAME ${f})
    STRING(REGEX REPLACE "/?([A-Za-z_0-9 ]+)\\.rb" "\\1" FILE_NAME ${FILE_NAME})
    IF(BUILD_TESTING)
      IF(MSVC)
        ADD_TEST(NAME "RubyTest-${FILE_NAME}-${TEST_NAME}"
          COMMAND "${CMAKE_COMMAND}" -E chdir "${CMAKE_CURRENT_BINARY_DIR}/$<CONFIGURATION>"
          "${RUBY_EXECUTABLE}" "openstudio_test.rb" "--name=test_${TEST_NAME}"
        )    
      ELSE()
        ADD_TEST(NAME "RubyTest-${FILE_NAME}-${TEST_NAME}"
          COMMAND "${CMAKE_COMMAND}" -E chdir "${CMAKE_CURRENT_BINARY_DIR}"
          "${RUBY_EXECUTABLE}" "openstudio_test.rb" "--name=test_${TEST_NAME}"
        )
      ENDIF()
      SET_TESTS_PROPERTIES("RubyTest-${FILE_NAME}-${TEST_NAME}" PROPERTIES DEPENDS energyplus_resources)
    ENDIF(BUILD_TESTING)
  ENDFOREACH(HIT)
ENDFOREACH( f ${RUBY_TEST_SRC} )

# get all possible configurations
LIST(LENGTH CMAKE_CONFIGURATION_TYPES POSSIBLE_CONFIGURATIONS_LENGTH)
IF(CMAKE_CONFIGURATION_TYPES)
  SET(POSSIBLE_CONFIGURATIONS ${CMAKE_CONFIGURATION_TYPES})
ELSE()
  SET(POSSIBLE_CONFIGURATIONS ".")
ENDIF()

# configure ruby files for testing from build directory
FOREACH(POSSIBLE_CONFIGURATION ${POSSIBLE_CONFIGURATIONS})
  SET(OPENSTUDIO_RUBY_DIR "${OPENSTUDIOCORE_BUILD_DIR}/ruby/${POSSIBLE_CONFIGURATION}")
  CONFIGURE_FILE( "openstudio_test.in" "${CMAKE_CURRENT_BINARY_DIR}/${POSSIBLE_CONFIGURATION}/openstudio_test.rb" )
ENDFOREACH(POSSIBLE_CONFIGURATION IN ${POSSIBLE_CONFIGURATIONS})

# which directory will we run ruby tests from
SET(RUBY_RUN_DIR "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_CFG_INTDIR}")

# run all the unit tests
ADD_CUSTOM_TARGET( ruby_run_tests
  ${CMAKE_COMMAND} -E chdir "${RUBY_RUN_DIR}" "${RUBY_EXECUTABLE}" "openstudio_test.rb" "$(ConfigurationName)"
  DEPENDS energyplus_resources
)
