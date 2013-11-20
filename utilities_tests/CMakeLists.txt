SET( target_name utilities_tests )

SET( ${target_name}_src
)

IF( OSSERVER_FOUND )
  LIST(APPEND ${target_name}_src
    VagrantFixture.hpp
    VagrantFixture.cpp
    VagrantProvider_GTest.cpp
  )  
ENDIF( OSSERVER_FOUND )

SET( ${target_name}_depends
  ${OPENSTUDIO_LIBS}
)

IF( OSSERVER_FOUND )
  CREATE_TEST_TARGET( ${target_name} "${${target_name}_src}" "${${target_name}_depends}")
ENDIF( OSSERVER_FOUND )  
