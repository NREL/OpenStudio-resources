
require 'openstudio'
require 'lib/baseline_model'

m = BaselineModel.new
#m = OpenStudio::Model::Model.new
#airloop = OpenStudio::Model::AirLoopHVAC.new(m)

# long standing issue with this coil
#coil = OpenStudio::Model::CoilSystemCoolingWaterHeatExchangerAssisted.new(m)
#coil.addToNode(airloop.supplyOutletNode)

#zone = OpenStudio::Model::ThermalZone.new(m)
#terminal = OpenStudio::Model::AirTerminalSingleDuctUncontrolled.new(m,m.alwaysOnDiscreteSchedule())
#airloop.addBranchForZone(zone,terminal)
#fan = OpenStudio::Model::FanConstantVolume.new(m)
#fan.addToNode(airloop.supplyOutletNode)
#heating_coil = OpenStudio::Model::CoilHeatingGas.new(m)
#heating_coil.addToNode(airloop.supplyOutletNode)
#cooling_coil = OpenStudio::Model::CoilCoolingDXTwoSpeed.new(m)
#cooling_coil.addToNode(airloop.supplyOutletNode)
##coil_system = OpenStudio::Model::CoilSystemCoolingWaterHeatExchangerAssisted.new(m)
##coil_system.addToNode(airloop.supplyOutletNode)
#spm = OpenStudio::Model::SetpointManagerSingleZoneReheat.new(m)
#spm.setControlZone(zone)
#spm.addToNode(airloop.supplyOutletNode)
##water_coil = coil_system.coolingCoil
#plant = OpenStudio::Model::PlantLoop.new(m)
##plant.addDemandBranchForComponent(water_coil)


#
#make a 2 story, 100m X 50m, 10 zone core/perimeter building
m.add_geometry({"length" => 100,
              "width" => 50,
              "num_floors" => 2,
              "floor_to_floor_height" => 4,
              "plenum_height" => 1,
              "perimeter_zone_depth" => 3})

#add windows at a 40% window-to-wall ratio
m.add_windows({"wwr" => 0.4,
                  "offset" => 1,
                  "application_type" => "Above Floor"})
        
#add ASHRAE System type 07, VAV w/ Reheat
m.add_hvac({"ashrae_sys_num" => '07'})

zones = m.getThermalZones

# CoilCoolingDXTwoStageWithHumidityControlMode
zone = zones[0]
zone.airLoopHVAC.get.removeBranchForZone(zone)
airloop = OpenStudio::Model::addSystemType3(m).to_AirLoopHVAC.get
airloop.addBranchForZone(zone)
coil = airloop.supplyComponents(OpenStudio::Model::CoilCoolingDXSingleSpeed::iddObjectType()).first.to_StraightComponent.get
node = coil.outletModelObject.get.to_Node.get
new_coil = OpenStudio::Model::CoilCoolingDXTwoStageWithHumidityControlMode.new(m)
new_coil.addToNode(node)
coil.remove()

# CoilSystemCoolingDXHeatExchangerAssisted
zone = zones[1]
zone.airLoopHVAC.get.removeBranchForZone(zone)
airloop = OpenStudio::Model::AirLoopHVAC.new(m)
terminal = OpenStudio::Model::AirTerminalSingleDuctUncontrolled.new(m,m.alwaysOnDiscreteSchedule())
airloop.addBranchForZone(zone,terminal)
unitary = OpenStudio::Model::AirLoopHVACUnitarySystem.new(m)
unitary.setFanPlacement("BlowThrough")
fan = OpenStudio::Model::FanOnOff.new(m)
unitary.setSupplyFan(fan)
heating_coil = OpenStudio::Model::CoilHeatingElectric.new(m)
unitary.setHeatingCoil(heating_coil)
cooling_coil = OpenStudio::Model::CoilSystemCoolingDXHeatExchangerAssisted.new(m)
unitary.setCoolingCoil(cooling_coil)
unitary.addToNode(airloop.supplyOutletNode())
unitary.setControllingZoneorThermostatLocation(zone)

# CoilCoolingDXVariableSpeed
zone = zones[2]
zone.airLoopHVAC.get.removeBranchForZone(zone)
airloop = OpenStudio::Model::addSystemType7(m).to_AirLoopHVAC.get
airloop.addBranchForZone(zone)
coil = airloop.supplyComponents(OpenStudio::Model::CoilCoolingWater::iddObjectType).first.to_CoilCoolingWater.get
newcoil = OpenStudio::Model::CoilCoolingDXVariableSpeed.new(m)
coildata = OpenStudio::Model::CoilCoolingDXVariableSpeedSpeedData.new(m)
newcoil.addSpeed(coildata)
newcoil.addToNode(coil.airOutletModelObject.get.to_Node.get)
coil.remove

node = newcoil.outletModelObject.get.to_Node.get

# CoilHeatingDXVariableSpeed
newcoil = OpenStudio::Model::CoilHeatingDXVariableSpeed.new(m)
coildata = OpenStudio::Model::CoilHeatingDXVariableSpeedSpeedData.new(m)
newcoil.addSpeed(coildata)
newcoil.addToNode(node)


##CoilSystemCoolingWaterHeatExchangerAssisted
##zone = zones[3]
##zone.airLoopHVAC.get.removeBranchForZone(zone)
#zone = OpenStudio::Model::ThermalZone.new(model)
#airloop = OpenStudio::Model::AirLoopHVAC.new(model)
#terminal = OpenStudio::Model::AirTerminalSingleDuctUncontrolled.new(model,model.alwaysOnDiscreteSchedule())
#airloop.addBranchForZone(zone,terminal)
#fan = OpenStudio::Model::FanConstantVolume.new(model)
#fan.addToNode(airloop.supplyOutletNode)
#heating_coil = OpenStudio::Model::CoilHeatingGas.new(model)
#heating_coil.addToNode(airloop.supplyOutletNode)
#coil_system = OpenStudio::Model::CoilSystemCoolingWaterHeatExchangerAssisted.new(model)
#coil_system.addToNode(airloop.supplyOutletNode)
##spm = OpenStudio::Model::SetpointManagerSingleZoneReheat.new(model)
##spm.setControlZone(zone)
##spm.addToNode(airloop.supplyOutletNode)
#water_coil = coil_system.coolingCoil
#chiller = model.getChillerElectricEIRs.first
#plant = chiller.plantLoop.get
#plant.addDemandBranchForComponent(water_coil)


#add thermostats
m.add_thermostats({"heating_setpoint" => 24,
                      "cooling_setpoint" => 28})
              
#assign constructions from a local library to the walls/windows/etc. in the model
m.set_constructions()

#set whole building space type; simplified 90.1-2004 Large Office Whole Building
m.set_space_type()  

#add design days to the model (Chicago)
m.add_design_days()
      
#save the OpenStudio model (.osm)
m.save_openstudio_osm({"osm_save_directory" => Dir.pwd,
                           "osm_name" => "out.osm"})
                           
#m.save(Dir.pwd + '/out.osm',true)

