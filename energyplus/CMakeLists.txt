# Configure a header file to point to the resources directory
#CONFIGURE_FILE( "resources.in" "${CMAKE_BINARY_DIR}/src/resources.hxx" )

########################################################
# energyplus resources
# clear runs, calls to RUN_ENERGYPLUS will populate this
SET(ENERGYPLUS_OUTPUTS "")

SET(energyplus_resources_src
  6-0-0/5ZoneAirCooled/in.idf
  7-0-0/5ZoneAirCooled/in.idf
  7-1-0/5ZoneAirCooled/in.idf
  7-2-0/5ZoneAirCooled/in.idf
  8-0-0/5ZoneAirCooled/in.idf
  PostProcessComparison.rb
)


# update the resources
UPDATE_RESOURCES("${energyplus_resources_src}")

# add runs
# ETH@20111201 Jason--do you want to keep the 6-0-0 run somehow?
RUN_ENERGYPLUS("in.idf" "6-0-0/5ZoneAirCooled" "USA_IL_Chicago-OHare.Intl.AP.725300_TMY3.epw")
RUN_ENERGYPLUS("in.idf" "7-0-0/5ZoneAirCooled" "USA_IL_Chicago-OHare.Intl.AP.725300_TMY3.epw")
RUN_ENERGYPLUS("in.idf" "7-1-0/5ZoneAirCooled" "USA_IL_Chicago-OHare.Intl.AP.725300_TMY3.epw")
RUN_ENERGYPLUS("in.idf" "7-2-0/5ZoneAirCooled" "USA_IL_Chicago-OHare.Intl.AP.725300_TMY3.epw")
RUN_ENERGYPLUS("in.idf" "8-0-0/5ZoneAirCooled" "USA_IL_Chicago-OHare.Intl.AP.725300_TMY3.epw")

# add target
ADD_CUSTOM_TARGET( energyplus_resources
  DEPENDS ${energyplus_resources_src} ${ENERGYPLUS_OUTPUTS}
  SOURCES ${energyplus_resources_src}
)

CREATE_SRC_GROUPS( "${energyplus_resources_src}" )
