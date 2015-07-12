SET( target_name runmanager_tests )

SET( runmanager_test_moc
  SignalListener.hpp
)

## Qt moc generation
qt5_wrap_cpp( runmanager_test_moc_src ${runmanager_test_moc} )

ADD_LIBRARY( openstudio_runmanager_lib_test STATIC
  ${runmanager_test_moc_src}
)

SET( ${target_name}_src
  RunManagerTestFixture.hpp
  RunManagerTestFixture.cpp
  RunManagerStress_GTest.cpp
  RunManagerProfiling_GTest.cpp
  SignalListener.hpp
  BasementSlabJobs_GTest.cpp
)

SET( ${target_name}_depends
 openstudio_runmanager_lib_test
 ${OPENSTUDIO_LIBS}
)

CREATE_TEST_TARGET( ${target_name} "${${target_name}_src}" "${${target_name}_depends}")

ADD_DEPENDENCIES( ${target_name} energyplus_resources runmanager_resources)
