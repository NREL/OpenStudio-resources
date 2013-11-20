# Configure a header file to point to the resources directory
#CONFIGURE_FILE( "resources.in" "${CMAKE_BINARY_DIR}/src/resources.hxx" )

########################################################
# project resources
# clear runs, calls to RUN_ENERGYPLUS will populate this
SET(ENERGYPLUS_OUTPUTS "")

SET(project_resources_src
  MS-BESX-2_Heating_DDACE-Random_1000.osp
  MS-BESX-2_Heating_DDACE-Random_1000.db
)

# update the resources
UPDATE_RESOURCES("${project_resources_src}")

# add target
ADD_CUSTOM_TARGET( project_resources
  DEPENDS ${project_resources_src} ${ENERGYPLUS_OUTPUTS}
  SOURCES ${project_resources_src}
)

CREATE_SRC_GROUPS( "${project_resources_src}" )
