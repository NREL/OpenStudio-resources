# frozen_string_literal: true

# This test aims to test the new 'Adiabatic Surface Construction Name' field
# added in the OS:DefaultConstructionSet

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
model.add_thermostats({ 'heating_setpoint' => 19,
                        'cooling_setpoint' => 26 })

# assign constructions from a local library to the walls/windows/etc. in the model
model.set_constructions

# set whole building space type; simplified 90.1-2004 Large Office Whole Building
model.set_space_type

# add design days to the model (Chicago)
model.add_design_days

# In order to produce more consistent results between different runs,
# we sort the zones by names
# (There's only one here, but just in case this would be copy pasted somewhere
# else...)
zones = model.getThermalZones.sort_by { |z| z.name.to_s }
z = zones[0]
z.setUseIdealAirLoads(true)

# Get the first Outdoors surface, sorting by name to ensure consistency
surfaces = model.getSurfaces.select { |s| s.outsideBoundaryCondition == 'Outdoors' }.sort_by { |s| s.name.to_s }

adiabatic_surface = surfaces[0]
# This will remove the subSurfaces (if any)
adiabatic_surface.setOutsideBoundaryCondition('Adiabatic')
# assert adiabatic_surface.construction.empty?

# Only one here, but let's be safe
construction_set = model.getDefaultConstructionSets.min_by { |d| d.name.to_s }
# I know it's initialized, so I get it already
ext_set = construction_set.defaultExteriorSurfaceConstructions.get
# Same, I know it's initialized
c = ext_set.wallConstruction.get
adiabatic_c = c.clone(model).to_ConstructionBase.get
adiabatic_c.setName('Adiabatic Construction')

if Gem::Version.new(OpenStudio.openStudioVersion) > Gem::Version.new('2.7.1')
  construction_set.setAdiabaticSurfaceConstruction(adiabatic_c)
end
# assert !adiabatic_surface.construction.empty?
# assert adiabatic_surface.construction.get == adiabatic_c

window_property = OpenStudio::Model::WindowPropertyFrameAndDivider.new(model)
window_property.setNFRCProductTypeforAssemblyCalculations("ProjectingSingle")

model.getSubSurfaces.each do |sub_surface|
  next if sub_surface.subSurfaceType != 'FixedWindow'

  sub_surface.setWindowPropertyFrameAndDivider(window_property)
end

# save the OpenStudio model (.osm)
model.save_openstudio_osm({ 'osm_save_directory' => Dir.pwd,
                            'osm_name' => 'in.osm' })
