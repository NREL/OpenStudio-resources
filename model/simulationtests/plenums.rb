
require 'openstudio'
require 'lib/baseline_model'

model = BaselineModel.new

always_on_schedule = model.alwaysOnDiscreteSchedule()

#make a 2 story, 100m X 50m, 10 zone core/perimeter building
model.add_geometry({"length" => 100,
              "width" => 50,
              "num_floors" => 3,
              "floor_to_floor_height" => 4,
              "plenum_height" => 1,
              "perimeter_zone_depth" => 3})

#add windows at a 40% window-to-wall ratio
model.add_windows({"wwr" => 0.4,
                  "offset" => 1,
                  "application_type" => "Above Floor"})

#add thermostats
model.add_thermostats({"heating_setpoint" => 24,
                      "cooling_setpoint" => 28})
        
#add ASHRAE System type 07, VAV w/ Reheat
model.add_hvac({"ashrae_sys_num" => '07'})

#create plenum

air_handler = model.getAirLoopHVACs.first
hot_water_plant = model.getBoilerHotWaters.first.plantLoop.get

story_1_core_thermal_zone = model.getThermalZoneByName("Story 1 Core Thermal Zone").get
story_1_north_thermal_zone = model.getThermalZoneByName("Story 1 North Perimeter Thermal Zone").get
story_1_south_thermal_zone = model.getThermalZoneByName("Story 1 South Perimeter Thermal Zone").get
story_1_east_thermal_zone = model.getThermalZoneByName("Story 1 East Perimeter Thermal Zone").get
story_1_west_thermal_zone = model.getThermalZoneByName("Story 1 West Perimeter Thermal Zone").get
story_2_core_thermal_zone = model.getThermalZoneByName("Story 2 Core Thermal Zone").get
story_2_north_thermal_zone = model.getThermalZoneByName("Story 2 North Perimeter Thermal Zone").get
story_2_south_thermal_zone = model.getThermalZoneByName("Story 2 South Perimeter Thermal Zone").get
story_2_east_thermal_zone = model.getThermalZoneByName("Story 2 East Perimeter Thermal Zone").get
story_2_west_thermal_zone = model.getThermalZoneByName("Story 2 West Perimeter Thermal Zone").get
story_3_core_thermal_zone = model.getThermalZoneByName("Story 3 Core Thermal Zone").get
story_3_north_thermal_zone = model.getThermalZoneByName("Story 3 North Perimeter Thermal Zone").get
story_3_south_thermal_zone = model.getThermalZoneByName("Story 3 South Perimeter Thermal Zone").get
story_3_east_thermal_zone = model.getThermalZoneByName("Story 3 East Perimeter Thermal Zone").get
story_3_west_thermal_zone = model.getThermalZoneByName("Story 3 West Perimeter Thermal Zone").get

story_1_core_thermal_zone.thermostatSetpointDualSetpoint().get.remove()
air_handler.removeBranchForZone(story_1_core_thermal_zone)
story_3_core_thermal_zone.thermostatSetpointDualSetpoint().get.remove()
air_handler.removeBranchForZone(story_3_core_thermal_zone)

supply_plenum1 = OpenStudio::Model::AirLoopHVACSupplyPlenum.new(model)
supply_plenum1.setThermalZone(story_1_core_thermal_zone)
return_plenum1 = OpenStudio::Model::AirLoopHVACReturnPlenum.new(model)
return_plenum1.setThermalZone(story_3_core_thermal_zone)

conditioned_zones = air_handler.thermalZones()

conditioned_zones.each do |zone|
  air_handler.removeBranchForZone(zone)
end

# Simple method of adding supply and return plenum in a pair
air_handler.addBranchForPlenums(supply_plenum1,return_plenum1)

conditioned_zones.each do |zone|
  reheat_coil = OpenStudio::Model::CoilHeatingWater.new(model,always_on_schedule)
  terminal = OpenStudio::Model::AirTerminalSingleDuctVAVReheat.new(model,always_on_schedule,reheat_coil)
  air_handler.addBranchForZone(zone,terminal)
  # If there is exactly one return or supply plenum, or exactly one supply and return plenum pair
  # addDemandBranchForComponent is a convenient way of adding zones to the plenum(s).
  hot_water_plant.addDemandBranchForComponent(terminal.reheatCoil())
end
              
#assign constructions from a local library to the walls/windows/etc. in the model
model.set_constructions()

#set whole building space type; simplified 90.1-2004 Large Office Whole Building
model.set_space_type()  

#add design days to the model (Chicago)
model.add_design_days()
       
#save the OpenStudio model (.osm)
model.save_openstudio_osm({"osm_save_directory" => Dir.pwd,
                           "osm_name" => "out.osm"})
                           
