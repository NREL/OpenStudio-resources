
require 'openstudio'
require 'lib/baseline_model'

model = BaselineModel.new

#make a 2 story, 100m X 50m, 10 zone core/perimeter building
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
        
air_loop = OpenStudio::Model::AirLoopHVAC.new(model)

oa_controller = OpenStudio::Model::ControllerOutdoorAir.new(model)
oa_system = OpenStudio::Model::AirLoopHVACOutdoorAirSystem.new(model,oa_controller)
oa_system.addToNode(air_loop.supplyOutletNode())

fan = OpenStudio::Model::FanVariableVolume.new(model)
fan.addToNode(air_loop.supplyOutletNode())

splitter = OpenStudio::Model::ConnectorSplitter.new(model)
splitter.addToNode(air_loop.supplyOutletNode())

# After adding the splitter, we will now have two supply outlet nodes
supply_outlet_nodes = air_loop.supplyOutletNodes()

heating_coil = OpenStudio::Model::CoilHeatingGas.new(model)
heating_coil.addToNode(supply_outlet_nodes[0])

heating_sch = OpenStudio::Model::ScheduleRuleset.new(model)
heating_sch.defaultDaySchedule().addValue(OpenStudio::Time.new(0,24,0,0),45.0)
heating_spm = OpenStudio::Model::SetpointManagerScheduled.new(model,heating_sch)
heating_spm.addToNode(supply_outlet_nodes[0])

cooling_coil = OpenStudio::Model::CoilCoolingDXTwoSpeed.new(model)
cooling_coil.addToNode(supply_outlet_nodes[1])

cooling_sch = OpenStudio::Model::ScheduleRuleset.new(model)
cooling_sch.defaultDaySchedule().addValue(OpenStudio::Time.new(0,24,0,0),12.8)
cooling_spm = OpenStudio::Model::SetpointManagerScheduled.new(model,cooling_sch)
cooling_spm.addToNode(supply_outlet_nodes[1])

zones = model.getThermalZones
zones.each do |zone|
  terminal = OpenStudio::Model::AirTerminalDualDuctVAV.new(model)
  air_loop.addBranchForZone(zone,terminal)
end

#add thermostats
model.add_thermostats({"heating_setpoint" => 24,
                      "cooling_setpoint" => 28})
              
#assign constructions from a local library to the walls/windows/etc. in the model
model.set_constructions()

#set whole building space type; simplified 90.1-2004 Large Office Whole Building
model.set_space_type()  

#add design days to the model (Chicago)
model.add_design_days()
       
#save the OpenStudio model (.osm)
model.save_openstudio_osm({"osm_save_directory" => Dir.pwd,
                           "osm_name" => "in.osm"})
                           
