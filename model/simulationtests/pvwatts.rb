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

# create the pvwatts generator object
generator = nil
surfaces = model.getSurfaces.sort_by { |z| z.name.to_s } # sort surfaces for repeatible results
surfaces.each do |surface|
  next unless surface.surfaceType.downcase == 'roofceiling'

  generator = OpenStudio::Model::GeneratorPVWatts.new(model, surface, 1000)
  generator.setSurface(surface) # not needed but tests the api
  break
end

# create the pvwatts inverter object
inverter = OpenStudio::Model::ElectricLoadCenterInverterPVWatts.new(model)

# create the electric load center distribution object
electric_load_center_dist = OpenStudio::Model::ElectricLoadCenterDistribution.new(model)
electric_load_center_dist.addGenerator(generator)
electric_load_center_dist.setInverter(inverter)

# let's add a shading surface too
vertices = nil
if generator.surface.is_initialized
  surface = generator.surface.get
  vertices = surface.vertices
end
shading_surface = OpenStudio::Model::ShadingSurface.new(vertices, model)
shading_surface_group = OpenStudio::Model::ShadingSurfaceGroup.new(model)
shading_surface.setShadingSurfaceGroup(shading_surface_group)

generator = OpenStudio::Model::GeneratorPVWatts.new(model, shading_surface, 1000)
generator.setSurface(shading_surface) # not needed but tests the api
electric_load_center_dist.addGenerator(generator)

# and add a random PV with no surface
generator = OpenStudio::Model::GeneratorPVWatts.new(model, 1000)
generator.setAzimuthAngle(30)
generator.setTiltAngle(30)
electric_load_center_dist.addGenerator(generator)

# save the OpenStudio model (.osm)
model.save_openstudio_osm({ 'osm_save_directory' => Dir.pwd, 'osm_name' => 'in.osm' })
