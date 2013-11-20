# Add google tests macro
macro(ADD_GOOGLE_TESTS executable)
  foreach ( source ${ARGN} )
    file(READ "${source}" contents)
    string(REGEX MATCHALL "TEST_?F?\\(([A-Za-z_0-9 ,]+)\\)" found_tests ${contents})
    foreach(hit ${found_tests})
      string(REGEX REPLACE ".*\\(([A-Za-z_0-9]+)[, ]*([A-Za-z_0-9]+)\\).*" "\\1.\\2" test_name ${hit})
      add_test(${test_name} "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${executable}" --gtest_filter=${test_name})
    endforeach(hit)
  endforeach()
endmacro()

# Create source groups automatically based on file path
MACRO( CREATE_SRC_GROUPS SRC )
  FOREACH( F ${SRC} )
    STRING( REGEX MATCH "(^.*)([/\\].*$)" M ${F} )
  IF(CMAKE_MATCH_1)
    STRING( REGEX REPLACE "[/\\]" "\\\\" DIR ${CMAKE_MATCH_1} )
    SOURCE_GROUP( ${DIR} FILES ${F} )
  ELSE()
    SOURCE_GROUP( \\ FILES ${F} )
  ENDIF()
  ENDFOREACH()
ENDMACRO()

# Create test targets
macro( CREATE_TEST_TARGET NAME SRC DEPENDENCIES )

  ADD_EXECUTABLE( ${NAME} ${SRC} )

  CREATE_SRC_GROUPS( "${SRC}" )

  TARGET_LINK_LIBRARIES( ${NAME} 
    ${OPENSTUDIO_LIBS} 
    ${Boost_LIBRARIES}
    ${DEPENDENCIES}
    ${CMAKE_THREAD_LIBS}
    ${QT_LIBS}
  )

  ADD_GOOGLE_TESTS( ${NAME} ${SRC} )

  ADD_CUSTOM_TARGET( ${NAME}_run
    COMMAND ${NAME}
    DEPENDS ${NAME}
    WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}" 
  )

endmacro()

# run energyplus
# appends output (eplusout.err) to list ENERGYPLUS_OUTPUTS
MACRO(RUN_ENERGYPLUS FILENAME DIRECTORY WEATHERFILE)
  LIST(APPEND ENERGYPLUS_OUTPUTS "${DIRECTORY}/eplusout.err")
  ADD_CUSTOM_COMMAND(
    OUTPUT "${DIRECTORY}/eplusout.err"
    COMMAND ${CMAKE_COMMAND} -E copy "${DIRECTORY}/${FILENAME}" "${DIRECTORY}/in.idf"
    COMMAND ${CMAKE_COMMAND} -E copy "${ENERGYPLUS_IDD}" "${DIRECTORY}/Energy+.idd"
    COMMAND ${CMAKE_COMMAND} -E copy "${ENERGYPLUS_WEATHER_DIR}/${WEATHERFILE}" "${DIRECTORY}/in.epw"
    COMMAND ${CMAKE_COMMAND} -E chdir "${DIRECTORY}" "${ENERGYPLUS_EXE}" ">" "${DIRECTORY}/screen.out"
    DEPENDS "${ENERGYPLUS_IDD}" "${ENERGYPLUS_WEATHER_DIR}/${WEATHERFILE}" "${ENERGYPLUS_EXE}" "${CMAKE_CURRENT_BINARY_DIR}/${DIRECTORY}/${FILENAME}"
    COMMENT "Updating EnergyPlus simulation in ${CMAKE_CURRENT_BINARY_DIR}/${DIRECTORY}/, this may take a while"
  )
ENDMACRO(RUN_ENERGYPLUS DIRECTORY WEATHERFILE)

# adds custom command to update a resource
MACRO(UPDATE_RESOURCES SRCS)
  FOREACH( SRC ${SRCS} )
    ADD_CUSTOM_COMMAND(
      OUTPUT "${SRC}"
      COMMAND ${CMAKE_COMMAND} -E copy "${CMAKE_CURRENT_SOURCE_DIR}/${SRC}" "${SRC}"
      DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/${SRC}"
    )
  ENDFOREACH()
ENDMACRO(UPDATE_RESOURCES SRCS)
