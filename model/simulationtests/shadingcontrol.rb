require 'openstudio'
require 'lib/baseline_model'

m = BaselineModel.new

#make a 1 story, 100m X 50m, 1 zone core/perimeter building
m.add_geometry({"length" => 100,
                "width" => 50,
                "num_floors" => 1,
                "floor_to_floor_height" => 4,
                "plenum_height" => 1,
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

# Use Ideal Air Loads
zones.each{|z| z.setUseIdealAirLoads(true)}

# shading material 1
blind1 = OpenStudio::Model::Blind.new(m)

# shading material 2
blind2 = OpenStudio::Model::Blind.new(m)

# shading control 1
shading_control1 = OpenStudio::Model::ShadingControl.new(blind1)

# shading control 2
shading_control2 = OpenStudio::Model::ShadingControl.new(blind1)

# shading control 3
shading_control3 = OpenStudio::Model::ShadingControl.new(blind2)
shading_control3.setTypeofSlatAngleControlforBlinds("BlockBeamSolar")

# sub surfaces
sub_surfaces = m.getSubSurfaces.sort_by{|ss| ss.name.to_s}
sub_surface1 = sub_surfaces[0]
sub_surface2 = sub_surfaces[1]
sub_surface3 = sub_surfaces[2]
sub_surface4 = sub_surfaces[3]

# add sub surfaces to shading control 1
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

#save the OpenStudio model (.osm)
m.save_openstudio_osm({"osm_save_directory" => Dir.pwd,
                       "osm_name" => "in.osm"})
