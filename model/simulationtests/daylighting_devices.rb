# frozen_string_literal: true

require 'openstudio'
require_relative 'lib/baseline_model'

model = BaselineModel.new

# make a 1 story, 100m X 50m, 1 zone building
model.add_geometry({ 'length' => 100,
                     'width' => 50,
                     'num_floors' => 1,
                     'floor_to_floor_height' => 4,
                     'plenum_height' => 0,
                     'perimeter_zone_depth' => 0 })

# add windows at a 40% window-to-wall ratio
model.add_windows({ 'wwr' => 0.4,
                    'offset' => 1,
                    'application_type' => 'Above Floor' })

# add thermostats
model.add_thermostats({ 'heating_setpoint' => 24,
                        'cooling_setpoint' => 28 })

# assign constructions from a local library to the walls/windows/etc. in the model
model.set_constructions

# set whole building space type; simplified 90.1-2004 Large Office Whole Building
model.set_space_type

# add design days to the model (Chicago)
model.add_design_days

thermal_zones = model.getThermalZones.sort_by { |tz| tz.name.to_s }
thermal_zone = thermal_zones[0]
spaces = thermal_zone.spaces.sort_by { |s| s.name.to_s }

windows = []
spaces.each do |space|
  surfaces = space.surfaces.sort_by {|s| s.name.to_s }
  surfaces.each do |surface|
    sub_surfaces = surface.subSurfaces.sort_by { |ss| ss.name.to_s }
    sub_surfaces.each do |sub_surface|
      next if sub_surface.subSurfaceType != 'FixedWindow'

      windows << sub_surface
    end
  end
end

window1 = windows[0]
window2 = windows[1]

# DaylightingDeviceTubular
material = OpenStudio::Model::StandardOpaqueMaterial.new(model)
material.setThickness(0.2032)
material.setConductivity(1.3114056)
material.setDensity(2242.8)
material.setSpecificHeat(837.4)
construction = OpenStudio::Model::Construction.new(model)
construction.insertLayer(0, material)

points = OpenStudio::Point3dVector.new
points << OpenStudio::Point3d.new(0, 1, 0.2)
points << OpenStudio::Point3d.new(0, 0, 0.2)
points << OpenStudio::Point3d.new(1, 0, 0.2)
points << OpenStudio::Point3d.new(1, 1, 0.2)
dome = OpenStudio::Model::SubSurface.new(points, model)
dome.setName('Dome')
dome.setSubSurfaceType('TubularDaylightDome')
dome.setSurface(window1.surface.get)

points = OpenStudio::Point3dVector.new
points << OpenStudio::Point3d.new(0, 1, 0.1)
points << OpenStudio::Point3d.new(0, 0, 0.1)
points << OpenStudio::Point3d.new(1, 0, 0.1)
points << OpenStudio::Point3d.new(1, 1, 0.1)
diffuser = OpenStudio::Model::SubSurface.new(points, model)
diffuser.setName('Diffuser')
diffuser.setSubSurfaceType('TubularDaylightDiffuser')
diffuser.setSurface(window1.surface.get)

tubular = OpenStudio::Model::DaylightingDeviceTubular.new(dome, diffuser, construction)
tubular.setDiameter(1.1)
tubular.setTotalLength(1.4)
tubular.setEffectiveThermalResistance(0.28)

transition_zone = OpenStudio::Model::TransitionZone.new(thermal_zone, 1)
tubular.addTransitionZone(transition_zone)

# DaylightingDeviceLightWell
sub_surface = window1

light_well = OpenStudio::Model::DaylightingDeviceLightWell.new(sub_surface)
light_well.setHeightofWell(1.2)
light_well.setPerimeterofBottomofWell(12.0)
light_well.setAreaofBottomofWell(9.0)
light_well.setVisibleReflectanceofWellWalls(0.7)

# DaylightingDeviceShelf
sub_surface = window2

points = OpenStudio::Point3dVector.new
points << OpenStudio::Point3d.new(0, 1, 0.3)
points << OpenStudio::Point3d.new(0, 0, 0.3)
points << OpenStudio::Point3d.new(1, 0, 0.3)
points << OpenStudio::Point3d.new(1, 1, 0.3)
inside_shelf = OpenStudio::Model::InteriorPartitionSurface.new(points, model)

points = OpenStudio::Point3dVector.new
points << OpenStudio::Point3d.new(0, 1, 0.4)
points << OpenStudio::Point3d.new(0, 0, 0.4)
points << OpenStudio::Point3d.new(1, 0, 0.4)
points << OpenStudio::Point3d.new(1, 1, 0.4)
outside_shelf = OpenStudio:Model::ShadingSurface.new(points, model)

shelf = OpenStudio::Model::DaylightingDeviceShelf.new(sub_surface)
shelf.setInsideShelf(inside_shelf)
shelf.setOutsideShelf(outside_shelf)
shelf.setViewFactortoOutsideShelf(0.5)

# save the OpenStudio model (.osm)
model.save_openstudio_osm({ 'osm_save_directory' => Dir.pwd,
                            'osm_name' => 'in.osm' })
