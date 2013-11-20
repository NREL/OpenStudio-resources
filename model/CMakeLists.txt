########################################################
# model resources
# clear runs, calls to RUN_ENERGYPLUS will populate this
SET(ENERGYPLUS_OUTPUTS "")

SET(model_resources_src
  OpenStudio.idd
  Medium_GeometryHeavy.osm
  Medium_HVACHeavy.osm
)

# update the resources
UPDATE_RESOURCES("${model_resources_src}")

# add target
ADD_CUSTOM_TARGET( model_resources
  DEPENDS ${model_resources_src} ${ENERGYPLUS_OUTPUTS}
  SOURCES ${model_resources_src}
)

CREATE_SRC_GROUPS( "${model_resources_src}" )


