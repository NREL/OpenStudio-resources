# frozen_string_literal: true

require 'openstudio'
require 'lib/baseline_model'

m = BaselineModel.new

# make a 3 story, 100m X 50m, 3 zone building
m.add_geometry({ 'length' => 100,
                 'width' => 50,
                 'num_floors' => 3,
                 'floor_to_floor_height' => 4,
                 'plenum_height' => 0,
                 'perimeter_zone_depth' => 0 })

# add windows at a 40% window-to-wall ratio
m.add_windows({ 'wwr' => 0.4,
                'offset' => 1,
                'application_type' => 'Above Floor' })

# add thermostats
m.add_thermostats({ 'heating_setpoint' => 24,
                    'cooling_setpoint' => 28 })

# assign constructions from a local library to the walls/windows/etc. in the model
m.set_constructions

# set whole building space type; simplified 90.1-2004 Large Office Whole Building
m.set_space_type

# add design days to the model (Chicago)
m.add_design_days

# In order to produce more consistent results between different runs,
# we sort the zones by names (only one here anyways...)
zones = m.getThermalZones.sort_by { |z| z.name.to_s }
zone1 = zones[0]
zone2 = zones[1]
zone3 = zones[2]

# spaces
spaces1 = zone1.spaces.sort_by { |s| s.name.to_s }
spaces2 = zone2.spaces.sort_by { |s| s.name.to_s }
spaces3 = zone3.spaces.sort_by { |s| s.name.to_s }

# surfaces
sub_surfaces1 = []
surfaces1 = spaces1[0].surfaces.sort_by { |s| s.name.to_s }
surfaces1.each do |surface|
  next if surface.surfaceType != 'Wall'

  sub_surfaces1 += surface.subSurfaces.sort_by { |ss| ss.name.to_s }
end
sub_surfaces2 = []
surfaces2 = spaces2[0].surfaces.sort_by { |s| s.name.to_s }
surfaces2.each do |surface|
  next if surface.surfaceType != 'Wall'

  sub_surfaces2 += surface.subSurfaces.sort_by { |ss| ss.name.to_s }
end
sub_surfaces3 = []
surfaces3 = spaces3[0].surfaces.sort_by { |s| s.name.to_s }
surfaces3.each do |surface|
  next if surface.surfaceType != 'Wall'

  sub_surfaces3 += surface.subSurfaces.sort_by { |ss| ss.name.to_s }
end

# sub surfaces
sub_surface1 = sub_surfaces1[0] # zone 1
sub_surface1.setName("ZONE 1 - Sub Surface 1")
sub_surface2 = sub_surfaces1[1] # zone 1
sub_surface2.setName("ZONE 1 - Sub Surface 2")
sub_surface3 = sub_surfaces2[0] # zone 2
sub_surface3.setName("ZONE 2 - Sub Surface 1")
sub_surface4 = sub_surfaces2[1] # zone 2
sub_surface4.setName("ZONE 2 - Sub Surface 2")
sub_surface5 = sub_surfaces3[0] # zone 3
sub_surface5.setName("ZONE 3 - Sub Surface 1")
sub_surface6 = sub_surfaces3[1] # zone 3
sub_surface6.setName("ZONE 3 - Sub Surface 2")

# Use Ideal Air Loads
zones.each { |z| z.setUseIdealAirLoads(true) }

# SHADING CONTROL 1 (BLIND 1)
# SUB SURFACE 1 (ZONE 1)
# SUB SURFACE 3 (ZONE 2)
# SUB SURFACE 5 (ZONE 3)
# SHADING CONTROL 2 (BLIND 1) - doesn't show up in "Window Control" table
# SUB SURFACE 1 (ZONE 1)
# SUB SURFACE 3 (ZONE 2)
# SUB SURFACE 5 (ZONE 3)
# SHADING CONTROL 3 (BLIND 2) - doesn't show up in "Window Control" table
# SUB SURFACE 1 (ZONE 1)
# SUB SURFACE 3 (ZONE 2)
# SUB SURFACE 5 (ZONE 3)
# SHADING CONTROL 4 (CONSTRUCTION 1)
# SUB SURFACE 2 (ZONE 1)
# SUB SURFACE 4 (ZONE 2)
# SUB SURFACE 6 (ZONE 3)

# shading materials
blind1 = OpenStudio::Model::Blind.new(m)
blind1.setName("BLIND 1")
blind2 = OpenStudio::Model::Blind.new(m)
blind2.setName("BLIND 2")

# construction
simple_glazing = OpenStudio::Model::SimpleGlazing.new(m)
construction1 = OpenStudio::Model::Construction.new(m)
construction1.setName("CONSTRUCTION 1")
construction1.insertLayer(0, simple_glazing)

# shading controls
shading_control1 = OpenStudio::Model::ShadingControl.new(blind1)
shading_control1.setName("SHADING CONTROL 1")
shading_control2 = OpenStudio::Model::ShadingControl.new(blind1)
shading_control2.setName("SHADING CONTROL 2")
shading_control3 = OpenStudio::Model::ShadingControl.new(blind2)
shading_control3.setName("SHADING CONTROL 3")
shading_control4 = OpenStudio::Model::ShadingControl.new(construction1)
shading_control4.setName("SHADING CONTROL 4")

# SHADING CONTROL 1
shading_control1.addSubSurface(sub_surface1)
shading_control1.addSubSurface(sub_surface3)
shading_control1.addSubSurface(sub_surface5)

# SHADING CONTROL 2
shading_control2.addSubSurface(sub_surface1)
shading_control2.addSubSurface(sub_surface3)
shading_control2.addSubSurface(sub_surface5)

# SHADING CONTROL 3
shading_control3.addSubSurface(sub_surface1)
shading_control3.addSubSurface(sub_surface3)
shading_control3.addSubSurface(sub_surface5)

# SHADING CONTROL 4
shading_control4.addSubSurface(sub_surface2)
shading_control4.addSubSurface(sub_surface4)
shading_control4.addSubSurface(sub_surface6)

# save the OpenStudio model (.osm)
m.save_openstudio_osm({ 'osm_save_directory' => Dir.pwd,
                        'osm_name' => 'in.osm' })
