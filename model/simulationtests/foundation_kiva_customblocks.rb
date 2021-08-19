# frozen_string_literal: true

require 'openstudio'
require_relative 'lib/baseline_model'

model = BaselineModel.new

# make a 2 story, 100m X 50m, 10 zone core/perimeter building
model.add_geometry({ 'length' => 100,
                     'width' => 50,
                     'num_floors' => 2,
                     'floor_to_floor_height' => 4,
                     'plenum_height' => 1,
                     'perimeter_zone_depth' => 3 })

# add windows at a 40% window-to-wall ratio
model.add_windows({ 'wwr' => 0.4,
                    'offset' => 1,
                    'application_type' => 'Above Floor' })

# add ASHRAE System type 01, PTAC, Residential
model.add_hvac({ 'ashrae_sys_num' => '01' })

# add thermostats
model.add_thermostats({ 'heating_setpoint' => 24,
                        'cooling_setpoint' => 28 })

# assign constructions from a local library to the walls/windows/etc. in the model
model.set_constructions

# set whole building space type; simplified 90.1-2004 Large Office Whole Building
model.set_space_type

# add design days to the model (Chicago)
model.add_design_days

# create the foundation kiva settings object
foundation_kiva_settings = model.getFoundationKivaSettings

# create 8in concrete construction
material = OpenStudio::Model::StandardOpaqueMaterial.new(model)
material.setThickness(0.2032)
material.setConductivity(1.3114056)
material.setDensity(2242.8)
material.setSpecificHeat(837.4)
construction = OpenStudio::Model::Construction.new(model)
construction.insertLayer(0, material)

# create a foundation kiva object
foundation_kiva = OpenStudio::Model::FoundationKiva.new(model)
foundation_kiva.setWallHeightAboveGrade(0.2032)
foundation_kiva.setWallDepthBelowSlab(0.2032)
foundation_kiva.setFootingWallConstruction(construction)

# add custom blocks
foundation_kiva.addCustomBlock(material, 1, 0, 1)
foundation_kiva.addCustomBlock(material, 1, 1, 2)
foundation_kiva.addCustomBlock(material, 2, -1, 3)
custom_block = OpenStudio::Model::CustomBlock.new(material, 2, 2, 4)
foundation_kiva.addCustomBlock(custom_block)
custom_blocks = []
custom_blocks << OpenStudio::Model::CustomBlock.new(material, 3, 2, 5)
custom_blocks << OpenStudio::Model::CustomBlock.new(material, 4, 2, 6)
foundation_kiva.addCustomBlocks(custom_blocks)

# attach foundation kiva object to floor surfaces
model.getSurfaces.each_with_index do |surface, i|
  next if surface.surfaceType.downcase != 'floor'
  next if surface.outsideBoundaryCondition.downcase != 'ground'

  surface.setAdjacentFoundation(foundation_kiva)
  surface.setConstruction(construction)
  if i == 0 # try creating one with no default properties
    surface.createSurfacePropertyExposedFoundationPerimeter('TotalExposedPerimeter', 4 * (surface.grossArea**0.5))
  end
end

# save the OpenStudio model (.osm)
model.save_openstudio_osm({ 'osm_save_directory' => Dir.pwd, 'osm_name' => 'in.osm' })
