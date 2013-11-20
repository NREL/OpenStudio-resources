########################################################
# runmanager resources
# clear runs, calls to RUN_ENERGYPLUS will populate this
SET(ENERGYPLUS_OUTPUTS "")

SET(runmanager_resources_src
  in.file
  test.rb
  5ZoneAirCooledWithSlab.idf
  LgOffVAVusingBasement.idf
  USA_IL_Chicago-OHare.Intl.AP.725300_TMY3.epw
)

# update the resources
UPDATE_RESOURCES("${runmanager_resources_src}")

# add target
ADD_CUSTOM_TARGET( runmanager_resources
  DEPENDS ${runmanager_resources_src} ${ENERGYPLUS_OUTPUTS}
  SOURCES ${runmanager_resources_src}
)

CREATE_SRC_GROUPS( "${runmanager_resources_src}" )


