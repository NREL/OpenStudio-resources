# frozen_string_literal: true

require 'openstudio'
require 'lib/baseline_model'

model = BaselineModel.new

# make a 1 story, 100m X 50m, 1 zone building
model.add_geometry({ 'length' => 100,
                     'width' => 50,
                     'num_floors' => 1,
                     'floor_to_floor_height' => 4,
                     'plenum_height' => 0,
                     'perimeter_zone_depth' => 0 })

# add windows at a 40% window-to-wall ratio
model.add_windows({ 'wwr' => 0.4,
                    'offset' => 1,
                    'application_type' => 'Above Floor' })

# assign constructions from a local library to the walls/windows/etc. in the model
model.set_constructions

# set whole building space type; simplified 90.1-2004 Large Office Whole Building
model.set_space_type

# add design days to the model (Chicago)
model.add_design_days

# add thermostats
model.add_thermostats({ 'heating_setpoint' => 24,
                        'cooling_setpoint' => 28 })

# In order to produce more consistent results between different runs,
# we sort the zones by names
zones = model.getThermalZones.sort_by { |z| z.name.to_s }
zone = zones[0]

air_loop = OpenStudio::Model::AirLoopHVAC.new(model)
supplyOutletNode = air_loop.supplyOutletNode

schedule = model.alwaysOnDiscreteSchedule
fan = OpenStudio::Model::FanOnOff.new(model, schedule)
supp_heating_coil = OpenStudio::Model::CoilHeatingElectric.new(model, schedule)

space_cooling_coil = OpenStudio::Model::CoilCoolingDXVariableSpeed.new(model)
space_cooling_coil.setName('Heat Pump ACDXCoil 1')
space_cooling_coil_speed_1 = OpenStudio::Model::CoilCoolingDXVariableSpeedSpeedData.new(model)
space_cooling_coil.addSpeed(space_cooling_coil_speed_1)
space_cooling_coil.setGrossRatedTotalCoolingCapacityAtSelectedNominalSpeedLevel(32000)
space_cooling_coil.setRatedAirFlowRateAtSelectedNominalSpeedLevel(1.7)

space_heating_coil = OpenStudio::Model::CoilHeatingDXVariableSpeed.new(model)
space_heating_coil.setName('Heat Pump DX Heating Coil 1')
space_heating_coil_speed_1 = OpenStudio::Model::CoilHeatingDXVariableSpeedSpeedData.new(model)
space_heating_coil.addSpeed(space_heating_coil_speed_1)
space_heating_coil.setRatedHeatingCapacityAtSelectedNominalSpeedLevel(32000)
space_heating_coil.setRatedAirFlowRateAtSelectedNominalSpeedLevel(1.7)

dedicated_water_heating_coil = OpenStudio::Model::CoilWaterHeatingAirToWaterHeatPumpVariableSpeed.new(model)
dedicated_water_heating_coil.setName('HPWHOutdoorDXCoilVS')
dedicated_water_heating_coil_speed_1 = OpenStudio::Model::CoilWaterHeatingAirToWaterHeatPumpVariableSpeedSpeedData.new(model)
dedicated_water_heating_coil.addSpeed(dedicated_water_heating_coil_speed_1)

scwh_coil = OpenStudio::Model::CoilWaterHeatingAirToWaterHeatPumpVariableSpeed.new(model)
scwh_coil.setName('SCWHCoil1')
scwh_coil_speed_1 = OpenStudio::Model::CoilWaterHeatingAirToWaterHeatPumpVariableSpeedSpeedData.new(model)
scwh_coil.addSpeed(scwh_coil_speed_1)

scdwh_cooling_coil = OpenStudio::Model::CoilCoolingDXVariableSpeed.new(model)
scdwh_cooling_coil.setName('SCDWHCoolCoil1')
scdwh_cooling_coil_speed_1 = OpenStudio::Model::CoilCoolingDXVariableSpeedSpeedData.new(model)
scdwh_cooling_coil.addSpeed(scdwh_cooling_coil_speed_1)

scdwh_water_heating_coil = OpenStudio::Model::CoilWaterHeatingAirToWaterHeatPumpVariableSpeed.new(model)
scdwh_water_heating_coil.setName('SCDWHWHCoil1')
scdwh_water_heating_coil_speed_1 = OpenStudio::Model::CoilWaterHeatingAirToWaterHeatPumpVariableSpeedSpeedData.new(model)
scdwh_water_heating_coil.addSpeed(scdwh_water_heating_coil_speed_1)

shdwh_heating_coil = OpenStudio::Model::CoilHeatingDXVariableSpeed.new(model)
shdwh_heating_coil.setName('SHDWHHeatCoil1')
shdwh_heating_coil_speed_1 = OpenStudio::Model::CoilHeatingDXVariableSpeedSpeedData.new(model)
shdwh_heating_coil.addSpeed(shdwh_heating_coil_speed_1)

shdwh_water_heating_coil = OpenStudio::Model::CoilWaterHeatingAirToWaterHeatPumpVariableSpeed.new(model)
shdwh_water_heating_coil.setName('SHDWHWHCoil1')
shdwh_water_heating_coil_speed_1 = OpenStudio::Model::CoilWaterHeatingAirToWaterHeatPumpVariableSpeedSpeedData.new(model)
shdwh_water_heating_coil.addSpeed(shdwh_water_heating_coil_speed_1)

coil_system = OpenStudio::Model::CoilSystemIntegratedHeatPumpAirSource.new(model,
                                                                           space_cooling_coil, space_heating_coil,
                                                                           dedicated_water_heating_coil, scwh_coil,
                                                                           scdwh_cooling_coil, scdwh_water_heating_coil,
                                                                           shdwh_heating_coil, shdwh_water_heating_coil)

coil_system.setIndoorTemperatureLimitForSCWHMode(23.0)
coil_system.setAmbientTemperatureLimitForSCWHMode(28.0)
coil_system.setIndoorTemperatureAboveWhichWHHasHigherPriority(20.0)
coil_system.setAmbientTemperatureAboveWhichWHHasHigherPriority(16.0)
coil_system.setFlagtoIndicateLoadControlInSCWHMode(0)
coil_system.setMinimumSpeedLevelForSCWHMode(1)
coil_system.setMaximumWaterFlowVolumeBeforeSwitchingfromSCDWHtoSCWHMode(3.0)
coil_system.setMinimumSpeedLevelForSCDWHMode(1)
coil_system.setMaximumRunningTimeBeforeAllowingElectricResistanceHeatUseDuringSHDWHMode(600.0)
coil_system.setMinimumSpeedLevelForSHDWHMode(1)

unitary = OpenStudio::Model::AirLoopHVACUnitaryHeatPumpAirToAir.new(model, schedule, fan, coil_system, coil_system, supp_heating_coil)
unitary.addToNode(supplyOutletNode)
unitary.setSupplyAirFlowRateDuringCoolingOperation(1.7)
unitary.setSupplyAirFlowRateDuringHeatingOperation(1.7)

terminal = OpenStudio::Model::AirTerminalSingleDuctConstantVolumeNoReheat.new(model, schedule)
air_loop.addBranchForZone(zone, terminal.to_StraightComponent)
unitary.setControllingZone(zone)

heat_pump_water_heater = OpenStudio::Model::WaterHeaterHeatPump.new(model)
heat_pump_water_heater.setDXCoil(coil_system)
heat_pump_water_heater.addToThermalZone(zone)

plant = OpenStudio::Model::PlantLoop.new(model)
pump = OpenStudio::Model::PumpConstantSpeed.new(model)
pump.addToNode(plant.supplyInletNode)
tank = heat_pump_water_heater.tank
plant.addSupplyBranchForComponent(tank)

hot_water_temp_sch = OpenStudio::Model::ScheduleRuleset.new(model)
hot_water_temp_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0, 24, 0, 0), 55.0)
hot_water_spm = OpenStudio::Model::SetpointManagerScheduled.new(model, hot_water_temp_sch)
hot_water_spm.addToNode(plant.supplyOutletNode)

water_connections = OpenStudio::Model::WaterUseConnections.new(model)
plant.addDemandBranchForComponent(water_connections)
water_def = OpenStudio::Model::WaterUseEquipmentDefinition.new(model)
water_equipment = OpenStudio::Model::WaterUseEquipment.new(water_def)
water_connections.addWaterUseEquipment(water_equipment)

# save the OpenStudio model (.osm)
model.save_openstudio_osm({ 'osm_save_directory' => Dir.pwd,
                            'osm_name' => 'in.osm' })
