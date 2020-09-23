require 'openstudio'
require 'lib/baseline_model'

m = BaselineModel.new

#make a 1 story, 100m X 50m, 1 zone core/perimeter building
m.add_geometry({"length" => 150,
                "width" => 100,
                "num_floors" => 2,
                "floor_to_floor_height" => 4,
                "plenum_height" => 0,
                "perimeter_zone_depth" => 0})

#add windows at a 40% window-to-wall ratio
m.add_windows({"wwr" => 0.4,
               "offset" => 1,
               "application_type" => "Above Floor"})

#add thermostats
m.add_thermostats({"heating_setpoint" => 24,
                   "cooling_setpoint" => 28})

#assign constructions from a local library to the walls/windows/etc. in the model
m.set_constructions()

#set whole building space type; simplified 90.1-2004 Large Office Whole Building
m.set_space_type()

#add design days to the model (Chicago)
m.add_design_days()

# In order to produce more consistent results between different runs,
# we sort the zones by names (only one here anyways...)
zones = m.getThermalZones.sort_by{|z| z.name.to_s}
zone1 = zones[0]
zone2 = zones[1]

# spaces
spaces1 = zone1.spaces.sort_by{|s| s.name.to_s}
spaces2 = zone2.spaces.sort_by{|s| s.name.to_s}

# surfaces
sub_surfaces1 = []
surfaces1 = spaces1[0].surfaces.sort_by{|s| s.name.to_s}
surfaces1.each do |surface|
  next if surface.surfaceType != "Wall"
  sub_surfaces1 += surface.subSurfaces.sort_by{|ss| ss.name.to_s}
end
sub_surfaces2 = []
surfaces2 = spaces2[0].surfaces.sort_by{|s| s.name.to_s}
surfaces2.each do |surface|
  next if surface.surfaceType != "Wall"
  sub_surfaces2 += surface.subSurfaces.sort_by{|ss| ss.name.to_s}
end

# sub surfaces
sub_surface1 = sub_surfaces1[0]
sub_surface2 = sub_surfaces2[0]
sub_surface3 = sub_surfaces1[1]
sub_surface4 = sub_surfaces2[1]
sub_surface5 = sub_surfaces1[2]
sub_surface6 = sub_surfaces2[2]

# Use Ideal Air Loads
zones.each{|z| z.setUseIdealAirLoads(true)}

# shading materials
blind1 = OpenStudio::Model::Blind.new(m)
blind2 = OpenStudio::Model::Blind.new(m)

# construction
simple_glazing = OpenStudio::Model::SimpleGlazing.new(m)
construction1 = OpenStudio::Model::Construction.new(m)
construction1.insertLayer(0, simple_glazing)

# shading controls
shading_control1 = OpenStudio::Model::ShadingControl.new(blind1)
shading_control2 = OpenStudio::Model::ShadingControl.new(blind2)
shading_control3 = OpenStudio::Model::ShadingControl.new(construction1)
shading_control4 = OpenStudio::Model::ShadingControl.new(blind2)
shading_control4.setTypeofSlatAngleControlforBlinds("BlockBeamSolar")

# add sub surface to shading control 1
shading_control1.addSubSurface(sub_surface1)

# bulk add sub surfaces to shading control 2
sub_surfaces = OpenStudio::Model::SubSurfaceVector.new
[sub_surface2].each do |sub_surface|
  sub_surfaces << sub_surface
end
shading_control2.addSubSurfaces(sub_surfaces)

# add shading controls to sub suface 3
sub_surface3.addShadingControl(shading_control1)
sub_surface3.addShadingControl(shading_control2)

# bulk add shading controls to sub surface 4
shading_controls = OpenStudio::Model::ShadingControlVector.new
[shading_control3].each do |shading_control|
  shading_controls << shading_control
end
sub_surface4.addShadingControls(shading_controls)

# bulk add sub surfaces to shading control 4
sub_surfaces = OpenStudio::Model::SubSurfaceVector.new
[sub_surface5, sub_surface6].each do |sub_surface|
  sub_surfaces << sub_surface
end
shading_control4.addSubSurfaces(sub_surfaces)

#save the OpenStudio model (.osm)
m.save_openstudio_osm({"osm_save_directory" => Dir.pwd,
                       "osm_name" => "in.osm"})
