
require 'openstudio'
require 'lib/baseline_model'

model = BaselineModel.new

#make a 2 story, 100m X 50m, 10 zone core/perimeter building
model.add_geometry({"length" => 100,
              "width" => 50,
              "num_floors" => 2,
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
thermal_zone = model.getThermalZoneByName("Story 2 Core Thermal Zone").get
thermal_zone.thermostatSetpointDualSetpoint().get.remove()
air_handler.removeBranchForZone(thermal_zone)

supply_plenum = OpenStudio::Model::AirLoopHVACSupplyPlenum.new(model)
supply_plenum.setThermalZone(thermal_zone)
air_handler.addBranchForHVACComponent(supply_plenum)

zones = air_handler.thermalZones()

zones.each do |zone|
  terminal = zone.equipment.first.clone(model).to_AirTerminalSingleDuctVAVReheat.get
  supply_plenum.addBranchForZone(zone,terminal)
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
                           
