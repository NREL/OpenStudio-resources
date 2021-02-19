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

# pick out on of the zone/system pairs and add a humidifier
# In order to produce more consistent results between different runs,
# we sort the zones by names
zones = model.getThermalZones.sort_by { |z| z.name.to_s }
zone = zones[0]

air_loop = OpenStudio::Model::AirLoopHVAC.new(model)
supplyOutletNode = air_loop.supplyOutletNode

chw_loop = OpenStudio::Model::PlantLoop.new(model)

schedule = model.alwaysOnDiscreteSchedule
fan = OpenStudio::Model::FanOnOff.new(model, schedule)
supp_heating_coil = OpenStudio::Model::CoilHeatingElectric.new(model, schedule)

space_heating_coil = OpenStudio::Model::CoilHeatingDXVariableSpeed.new(model)
space_heating_coil_speed_1 = OpenStudio::Model::CoilHeatingDXVariableSpeedSpeedData.new(model)
space_heating_coil.addSpeed(space_heating_coil_speed_1)

grid_signal_schedule = OpenStudio::Model::ScheduleRuleset.new(model)
grid_signal_schedule.defaultDaySchedule.addValue(OpenStudio::Time.new(0, 15, 0, 0), 5.5)
grid_signal_schedule.defaultDaySchedule.addValue(OpenStudio::Time.new(0, 20, 0, 0), 8.0)
grid_signal_schedule.defaultDaySchedule.addValue(OpenStudio::Time.new(0, 24, 0, 0), 5.5)

space_cooling_coil = OpenStudio::Model::CoilCoolingDXVariableSpeed.new(model)
space_cooling_coil_speed_1 = OpenStudio::Model::CoilCoolingDXVariableSpeedSpeedData.new(model)
space_cooling_coil.addSpeed(space_cooling_coil_speed_1)
space_cooling_coil.setGridSignalSchedule(grid_signal_schedule)
space_cooling_coil.setLowerBoundToApplyGridResponsiveControl(100)
space_cooling_coil.setUpperBoundToApplyGridResponsiveControl(-100)
space_cooling_coil.setMaxSpeedLevelDuringGridResponsiveControl(10)
space_cooling_coil.setLoadControlDuringGridResponsiveControl('SenLat')

chiller_coil = OpenStudio::Model::CoilChillerAirSourceVariableSpeed.new(model)
chiller_coil_speed_1 = OpenStudio::Model::CoilChillerAirSourceVariableSpeedSpeedData.new(model)
chiller_coil.addSpeed(chiller_coil_speed_1)
chiller_coil.setNominalSpeedLevel(1)
chiller_coil.autosizeRatedChilledWaterCapacity
chiller_coil.setRatedEvaporatorInletWaterTemperature(8)
chiller_coil.setRatedCondenserInletAirTemperature(35)
chiller_coil.autocalculateRatedEvaporatorWaterFlowRate
chiller_coil.setEvaporatorPumpPowerIncludedinRatedCOP('No')
chiller_coil.setEvaporatorPumpHeatIncludedinRatedCoolingCapacityandRatedCOP('No')
chiller_coil.setFractionofEvaporatorPumpHeattoWater(0.2)
chiller_coil.setCrankcaseHeaterCapacity(0)
chiller_coil.setMaximumAmbientTemperatureforCrankcaseHeaterOperation(10)
chiller_coil.setGridSignalSchedule(grid_signal_schedule)
chiller_coil.setLowerBoundToApplyGridResponsiveControl(100)
chiller_coil.setUpperBoundToApplyGridResponsiveControl(-100)
chiller_coil.setMaxSpeedLevelDuringGridResponsiveControl(10)

supp_chiller_coil = OpenStudio::Model::CoilCoolingWater.new(model)
supp_chiller_coil.addToNode(supplyOutletNode)
chw_loop.addDemandBranchForComponent(supp_chiller_coil)

thermal_storage = OpenStudio::Model::ThermalStoragePcmSimple.new(model)
chw_loop.addSupplyBranchForComponent(thermal_storage)

coil_system = OpenStudio::Model::CoilSystemIntegratedHeatPumpAirSource.new(model, space_cooling_coil, space_heating_coil)
coil_system.setChillerCoil(chiller_coil)
coil_system.setSupplementalChillerCoil(supp_chiller_coil)
coil_system.setStorageTank(thermal_storage)

thermal_storage_cooling_pair = OpenStudio::Model::ThermalStorageCoolingPair.new(model, space_cooling_coil, thermal_storage)

unitary = OpenStudio::Model::AirLoopHVACUnitaryHeatPumpAirToAir.new(model, schedule, fan, coil_system, coil_system, supp_heating_coil)
unitary.addToNode(supplyOutletNode)

terminal = OpenStudio::Model::AirTerminalSingleDuctConstantVolumeNoReheat.new(model, schedule)
air_loop.addBranchForZone(zone, terminal.to_StraightComponent)
unitary.setControllingZone(zone)

# save the OpenStudio model (.osm)
model.save_openstudio_osm({ 'osm_save_directory' => Dir.pwd,
                            'osm_name' => 'in.osm' })
