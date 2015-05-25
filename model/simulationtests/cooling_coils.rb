
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
        
#add ASHRAE System type 07, VAV w/ Reheat
model.add_hvac({"ashrae_sys_num" => '07'})

zones = model.getThermalZones

# CoilCoolingDXTwoStageWithHumidityControlMode
zone = zones[0]
zone.airLoopHVAC.get.removeBranchForZone(zone)
airloop = OpenStudio::Model::addSystemType3(model).to_AirLoopHVAC.get
airloop.addBranchForZone(zone)
coil = airloop.supplyComponents(OpenStudio::Model::CoilCoolingDXSingleSpeed::iddObjectType()).first.to_StraightComponent.get
node = coil.outletModelObject.get.to_Node.get
new_coil = OpenStudio::Model::CoilCoolingDXTwoStageWithHumidityControlMode.new(model)
new_coil.addToNode(node)
coil.remove()

# CoilSystemCoolingDXHeatExchangerAssisted
zone = zones[1]
zone.airLoopHVAC.get.removeBranchForZone(zone)
airloop = OpenStudio::Model::AirLoopHVAC.new(model)
terminal = OpenStudio::Model::AirTerminalSingleDuctUncontrolled.new(model,model.alwaysOnDiscreteSchedule())
airloop.addBranchForZone(zone,terminal)
unitary = OpenStudio::Model::AirLoopHVACUnitarySystem.new(model)
unitary.setFanPlacement("BlowThrough")
fan = OpenStudio::Model::FanOnOff.new(model)
unitary.setSupplyFan(fan)
heating_coil = OpenStudio::Model::CoilHeatingElectric.new(model)
unitary.setHeatingCoil(heating_coil)
cooling_coil = OpenStudio::Model::CoilSystemCoolingDXHeatExchangerAssisted.new(model)
cooling_coil.heatExchanger.to_HeatExchangerAirToAirSensibleAndLatent.get.setSupplyAirOutletTemperatureControl(false)
unitary.setCoolingCoil(cooling_coil)
unitary.addToNode(airloop.supplyOutletNode())
unitary.setControllingZoneorThermostatLocation(zone)


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
                           "osm_name" => "out.osm"})
                           
