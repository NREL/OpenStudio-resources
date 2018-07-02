
require 'openstudio'
#require 'C:/Projects/OpenStudio_branch/build/OpenStudioCore-prefix/src/OpenStudioCore-build/ruby/Debug/openstudio.rb'
require 'lib/baseline_model'


model = BaselineModel.new

#make a 1 story, 100m X 50m, 10 zone core/perimeter building
model.add_geometry({"length" => 100,
              "width" => 50,
              "num_floors" => 1,
              "floor_to_floor_height" => 4,
              "plenum_height" => 1,
              "perimeter_zone_depth" => 3})

#add windows at a 40% window-to-wall ratio
model.add_windows({"wwr" => 0.4,
                  "offset" => 1,
                  "application_type" => "Above Floor"})

# add a zone hvac ideal loads system to each zone in the model
# In order to produce more consistent results between different runs,
# we sort the zones by names (doesn't matter here, but just in case)
zones = model.getThermalZones.sort_by{|z| z.name.to_s}

# make the first zone (doesn't really matter which one it is) a plenum
plenum = zones.first
zones[1..-1].each do|zone|
  zone_ideal_loads = OpenStudio::Model::ZoneHVACIdealLoadsAirSystem.new(model)
  zone_ideal_loads.addToThermalZone(zone)
  zone_ideal_loads.setReturnPlenum(plenum)
end

#add thermostats
model.add_thermostats({"heating_setpoint" => 24,
                      "cooling_setpoint" => 28})

#assign constructions from a local library to the walls/windows/etc. in the model
model.set_constructions()

#set whole building space type simplified 90.1-2004 Large Office Whole Building
model.set_space_type()

#add design days to the model (Chicago)
model.add_design_days()

#save the OpenStudio model (.osm)
model.save_openstudio_osm({"osm_save_directory" => Dir.pwd,
                           "osm_name" => "in.osm"})

