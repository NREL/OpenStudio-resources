
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

conditioned_zones = air_handler.thermalZones()

conditioned_zones.each do |zone|
  air_handler.removeBranchForZone(zone)
end

supply_plenum1 = OpenStudio::Model::AirLoopHVACSupplyPlenum.new(model)
story_1_core_thermal_zone.thermostatSetpointDualSetpoint.get.remove()
supply_plenum1.setThermalZone(story_1_core_thermal_zone)

return_plenum1 = OpenStudio::Model::AirLoopHVACReturnPlenum.new(model)
story_3_core_thermal_zone.thermostatSetpointDualSetpoint.get.remove
return_plenum1.setThermalZone(story_3_core_thermal_zone)

supply_plenum2 = OpenStudio::Model::AirLoopHVACSupplyPlenum.new(model)
story_1_north_thermal_zone.thermostatSetpointDualSetpoint.get.remove()
supply_plenum2.setThermalZone(story_1_north_thermal_zone);

return_plenum2 = OpenStudio::Model::AirLoopHVACReturnPlenum.new(model)
story_3_north_thermal_zone.thermostatSetpointDualSetpoint.get.remove
return_plenum2.setThermalZone(story_3_north_thermal_zone);

reheat_coil = OpenStudio::Model::CoilHeatingWater.new(model,always_on_schedule)
terminal = OpenStudio::Model::AirTerminalSingleDuctVAVReheat.new(model,always_on_schedule,reheat_coil)
hot_water_plant.addDemandBranchForComponent(terminal.reheatCoil())

# Add zone between two plenums
air_handler.addBranchForPlenums(supply_plenum1,return_plenum1)
air_handler.addBranchForZone(story_2_core_thermal_zone,supply_plenum1,return_plenum1,terminal)

# Add zone between zone splitter/mixer (no plenum)
terminal = terminal.clone(model).to_AirTerminalSingleDuctVAVReheat.get
hot_water_plant.addDemandBranchForComponent(terminal.reheatCoil())
air_handler.addBranchForZone(story_2_north_thermal_zone,terminal)

zone_splitter = air_handler.zoneSplitter()
zone_mixer = air_handler.zoneMixer()

# Supply plenum to zone mixer
air_handler.addBranchForHVACComponent(supply_plenum2)

# Zone splitter to return plenum
air_handler.addBranchForHVACComponent(return_plenum2)


# Add zones between zone splitter and return plenum 2
terminal = terminal.clone(model).to_AirTerminalSingleDuctVAVReheat.get
hot_water_plant.addDemandBranchForComponent(terminal.reheatCoil())
air_handler.addBranchForZone(story_2_south_thermal_zone,
                             zone_splitter,
                             return_plenum2,
                             terminal)

terminal = terminal.clone(model).to_AirTerminalSingleDuctVAVReheat.get
hot_water_plant.addDemandBranchForComponent(terminal.reheatCoil())
air_handler.addBranchForZone(story_2_east_thermal_zone,
                             zone_splitter,
                             return_plenum2,
                             terminal)

terminal = terminal.clone(model).to_AirTerminalSingleDuctVAVReheat.get
hot_water_plant.addDemandBranchForComponent(terminal.reheatCoil())
air_handler.addBranchForZone(story_2_west_thermal_zone,
                             zone_splitter,
                             return_plenum2,
                             terminal)

# Add zones between supply plenum 2 and zone mixer
terminal = terminal.clone(model).to_AirTerminalSingleDuctVAVReheat.get
hot_water_plant.addDemandBranchForComponent(terminal.reheatCoil())
air_handler.addBranchForZone(story_3_south_thermal_zone,
                             supply_plenum2,
                             zone_mixer,
                             terminal)

terminal = terminal.clone(model).to_AirTerminalSingleDuctVAVReheat.get
hot_water_plant.addDemandBranchForComponent(terminal.reheatCoil())
air_handler.addBranchForZone(story_3_east_thermal_zone,
                             supply_plenum2,
                             zone_mixer,
                             terminal)

terminal = terminal.clone(model).to_AirTerminalSingleDuctVAVReheat.get
hot_water_plant.addDemandBranchForComponent(terminal.reheatCoil())
air_handler.addBranchForZone(story_3_west_thermal_zone,
                             supply_plenum2,
                             zone_mixer,
                             terminal)

# Add zone between supply and return plenum 2
terminal = terminal.clone(model).to_AirTerminalSingleDuctVAVReheat.get
hot_water_plant.addDemandBranchForComponent(terminal.reheatCoil())
air_handler.addBranchForZone(story_1_south_thermal_zone,
                             supply_plenum2,
                             return_plenum2,
                             terminal)

# Add zone between supply and return plenum 2
terminal = terminal.clone(model).to_AirTerminalSingleDuctVAVReheat.get
hot_water_plant.addDemandBranchForComponent(terminal.reheatCoil())
air_handler.addBranchForZone(story_1_west_thermal_zone,
                             supply_plenum2,
                             return_plenum2,
                             terminal)

              
#assign constructions from a local library to the walls/windows/etc. in the model
model.set_constructions()

#set whole building space type; simplified 90.1-2004 Large Office Whole Building
model.set_space_type()  

#add design days to the model (Chicago)
model.add_design_days()
       
#save the OpenStudio model (.osm)
model.save_openstudio_osm({"osm_save_directory" => Dir.pwd,
                           "osm_name" => "out.osm"})
                           
