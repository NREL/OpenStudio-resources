# frozen_string_literal: true

require 'openstudio'
require 'lib/baseline_model'

model = BaselineModel.new

# make a 2 story, 100m X 50m, 10 zone core/perimeter building
model.add_geometry({ 'length' => 100,
                     'width' => 50,
                     'num_floors' => 1,
                     'floor_to_floor_height' => 4,
                     'plenum_height' => 1,
                     'perimeter_zone_depth' => 3 })

# add windows at a 40% window-to-wall ratio
model.add_windows({ 'wwr' => 0.4,
                    'offset' => 1,
                    'application_type' => 'Above Floor' })

always_on = model.alwaysOnDiscreteSchedule

# In order to produce more consistent results between different runs,
# we sort the zones by names
zones = model.getThermalZones.sort_by { |z| z.name.to_s }

# add thermostats
model.add_thermostats({ 'heating_setpoint' => 20,
                        'cooling_setpoint' => 30 })

# get the heating and cooling setpoint schedule to use later
thermostat = model.getThermostatSetpointDualSetpoints[0]
heating_schedule = thermostat.heatingSetpointTemperatureSchedule.get
cooling_schedule = thermostat.coolingSetpointTemperatureSchedule.get

# Unitary System with CoilHeatingGasMultiStage and CoilCoolingDXMultiSpeed test
zone = zones[0]

staged_thermostat = OpenStudio::Model::ZoneControlThermostatStagedDualSetpoint.new(model)
staged_thermostat.setHeatingTemperatureSetpointSchedule(heating_schedule)
staged_thermostat.setNumberofHeatingStages(2)
staged_thermostat.setCoolingTemperatureSetpointBaseSchedule(cooling_schedule)
staged_thermostat.setNumberofCoolingStages(2)
zone.setThermostat(staged_thermostat)

air_system = OpenStudio::Model::AirLoopHVAC.new(model)
supply_outlet_node = air_system.supplyOutletNode

# Modify the sizing parameters for the air system
air_loop_sizing = air_system.sizingSystem
air_loop_sizing.setCentralHeatingDesignSupplyAirTemperature(OpenStudio.convert(104, 'F', 'C').get)

controllerOutdoorAir = OpenStudio::Model::ControllerOutdoorAir.new(model)
outdoorAirSystem = OpenStudio::Model::AirLoopHVACOutdoorAirSystem.new(model, controllerOutdoorAir)
outdoorAirSystem.addToNode(supply_outlet_node)

fan = OpenStudio::Model::FanConstantVolume.new(model, always_on)
heat = OpenStudio::Model::CoilHeatingGasMultiStage.new(model)
heat.setName('Multi Stage Gas Htg Coil')
heat_stage_1 = OpenStudio::Model::CoilHeatingGasMultiStageStageData.new(model)
heat_stage_2 = OpenStudio::Model::CoilHeatingGasMultiStageStageData.new(model)
heat.addStage(heat_stage_1)
heat.addStage(heat_stage_2)
cool = OpenStudio::Model::CoilCoolingDXMultiSpeed.new(model)
cool.setName('Multi Stage DX Clg Coil')
cool_stage_1 = OpenStudio::Model::CoilCoolingDXMultiSpeedStageData.new(model)
cool_stage_2 = OpenStudio::Model::CoilCoolingDXMultiSpeedStageData.new(model)
cool.addStage(cool_stage_1)
cool.addStage(cool_stage_2)
supp_heat = OpenStudio::Model::CoilHeatingElectric.new(model, always_on)
supp_heat.setName('Sup Elec Htg Coil')
unitary = OpenStudio::Model::AirLoopHVACUnitaryHeatPumpAirToAirMultiSpeed.new(model, fan, heat, cool, supp_heat)
unitary.addToNode(supply_outlet_node)
unitary.setControllingZoneorThermostatLocation(zone)

terminal = OpenStudio::Model::AirTerminalSingleDuctUncontrolled.new(model, always_on)
air_system.addBranchForZone(zone, terminal)

# Unitary System with CoilHeatingDXMultiSpeed and CoilCoolingDXMultiSpeed test
zone = zones[1]

staged_thermostat = OpenStudio::Model::ZoneControlThermostatStagedDualSetpoint.new(model)
staged_thermostat.setHeatingTemperatureSetpointSchedule(heating_schedule)
staged_thermostat.setNumberofHeatingStages(2)
staged_thermostat.setCoolingTemperatureSetpointBaseSchedule(cooling_schedule)
staged_thermostat.setNumberofCoolingStages(2)
zone.setThermostat(staged_thermostat)

air_system = OpenStudio::Model::AirLoopHVAC.new(model)
supply_outlet_node = air_system.supplyOutletNode

# Modify the sizing parameters for the air system
air_loop_sizing = air_system.sizingSystem
air_loop_sizing.setCentralHeatingDesignSupplyAirTemperature(OpenStudio.convert(104, 'F', 'C').get)

controllerOutdoorAir = OpenStudio::Model::ControllerOutdoorAir.new(model)
outdoorAirSystem = OpenStudio::Model::AirLoopHVACOutdoorAirSystem.new(model, controllerOutdoorAir)
outdoorAirSystem.addToNode(supply_outlet_node)

fan = OpenStudio::Model::FanConstantVolume.new(model, always_on)
heat = OpenStudio::Model::CoilHeatingDXMultiSpeed.new(model)
heat.setName('Multi Stage Gas Htg Coil')
heat_stage_1 = OpenStudio::Model::CoilHeatingDXMultiSpeedStageData.new(model)
heat_stage_2 = OpenStudio::Model::CoilHeatingDXMultiSpeedStageData.new(model)
heat.addStage(heat_stage_1)
heat.addStage(heat_stage_2)
cool = OpenStudio::Model::CoilCoolingDXMultiSpeed.new(model)
cool.setName('Multi Stage DX Clg Coil')
cool_stage_1 = OpenStudio::Model::CoilCoolingDXMultiSpeedStageData.new(model)
cool_stage_2 = OpenStudio::Model::CoilCoolingDXMultiSpeedStageData.new(model)
cool.addStage(cool_stage_1)
cool.addStage(cool_stage_2)
supp_heat = OpenStudio::Model::CoilHeatingElectric.new(model, always_on)
supp_heat.setName('Sup Elec Htg Coil')
unitary = OpenStudio::Model::AirLoopHVACUnitaryHeatPumpAirToAirMultiSpeed.new(model, fan, heat, cool, supp_heat)
unitary.addToNode(supply_outlet_node)
unitary.setControllingZoneorThermostatLocation(zone)

terminal = OpenStudio::Model::AirTerminalSingleDuctUncontrolled.new(model, always_on)
air_system.addBranchForZone(zone, terminal)

# Put all of the other zones on a system type 3
zones[2..-1].each do |z|
  air_system = OpenStudio::Model.addSystemType3(model).to_AirLoopHVAC.get
  air_system.addBranchForZone(z)
end

# assign constructions from a local library to the walls/windows/etc. in the model
model.set_constructions

# set whole building space type; simplified 90.1-2004 Large Office Whole Building
model.set_space_type

# add design days to the model (Chicago)
model.add_design_days

# save the OpenStudio model (.osm)
model.save_openstudio_osm({ 'osm_save_directory' => Dir.pwd,
                            'osm_name' => 'in.osm' })
