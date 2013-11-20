# Configure a header file to point to the resources directory
#CONFIGURE_FILE( "resources.in" "${CMAKE_BINARY_DIR}/src/resources.hxx" )

########################################################
# weatherdata resources
# clear runs, calls to RUN_WEATHERDATA will populate this
SET(WEATHERDATA_OUTPUTS "")

SET(weatherdata_resources_src
  USA_IL_Chicago-OHare.Intl.AP.725300_TMY3.epw
  USA_IL_Chicago-OHare.Intl.AP.725300_TMY3.ddy
)


# update the resources
UPDATE_RESOURCES("${weatherdata_resources_src}")

# add target
ADD_CUSTOM_TARGET( weatherdata_resources
  DEPENDS ${weatherdata_resources_src} ${WEATHERDATA_OUTPUTS}
  SOURCES ${weatherdata_resources_src}
)

CREATE_SRC_GROUPS( "${weatherdata_resources_src}" )
