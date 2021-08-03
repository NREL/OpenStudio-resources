# frozen_string_literal: true

require 'openstudio'
require 'lib/baseline_model'

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

sub_surfaces = model.getSubSurfaces.sort_by { |ss| ss.name.to_s }
windows = []
sub_surfaces.each do |sub_surface|
  next if sub_surface.subSurfaceType != 'FixedWindow'

  windows << sub_surface
end

# DaylightingDeviceShelf
sub_surface = windows[0]
shelf = OpenStudio::Model::DaylightingDeviceShelf.new(sub_surface)
# shelf.setInsideShelf()
# shelf.setOutsideShelf()
# shelf.setViewFactortoOutsideShelf()

# DaylightingDeviceTubular
material = OpenStudio::Model::StandardOpaqueMaterial.new(model)
material.setThickness(0.2032)
material.setConductivity(1.3114056)
material.setDensity(2242.8)
material.setSpecificHeat(837.4)
construction = OpenStudio::Model::Construction.new(model)
construction.insertLayer(0, material)

thermal_zone = OpenStudio::Model::ThermalZone.new
transition_zone = OpenStudio::Model::TransitionZone.new(thermal_zone, 1)

dome = windows[1]
diffuser = windows[2]
tubular = OpenStudio::Model::DaylightingDeviceTubular.new(dome, diffuser, construction)
tubular.setDiameter(0.3556)
tubular.setTotalLength(1.4)
tubular.setEffectiveThermalResistance(0.28)
tubular.addTransitionZone(transition_zone)

# DaylightingDeviceLightWell
sub_surface = windows[3]
light_well = OpenStudio::Model::DaylightingDeviceLightWell.new(sub_surface)
light_well.setHeightofWell(1.2)
light_well.setPerimeterofBottomofWell(12.0)
light_well.setAreaofBottomofWell(9.0)
light_well.setVisibleReflectanceofWellWalls(0.7)

# save the OpenStudio model (.osm)
model.save_openstudio_osm({ 'osm_save_directory' => Dir.pwd,
                            'osm_name' => 'in.osm' })
