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
supp_heating_coil = OpenStudio::Model::CoilHeatingGas.new(model, schedule)

grid_signal_schedule = OpenStudio::Model::ScheduleRuleset.new(model)
grid_signal_schedule.defaultDaySchedule.addValue(OpenStudio::Time.new(0, 15, 0, 0), 5.5)
grid_signal_schedule.defaultDaySchedule.addValue(OpenStudio::Time.new(0, 20, 0, 0), 8.0)
grid_signal_schedule.defaultDaySchedule.addValue(OpenStudio::Time.new(0, 24, 0, 0), 5.5)

heating_coil = OpenStudio::Model::CoilHeatingDXVariableSpeed.new(model)
heating_coil_speed_1 = OpenStudio::Model::CoilHeatingDXVariableSpeedSpeedData.new(model)
heating_coil.addSpeed(heating_coil_speed_1)
heating_coil.setGridSignalSchedule(grid_signal_schedule)
heating_coil.setLowerBoundToApplyGridResponsiveControl(100)
heating_coil.setUpperBoundToApplyGridResponsiveControl(-100)
heating_coil.setMaxSpeedLevelDuringGridResponsiveControl(10)

cooling_coil = OpenStudio::Model::CoilCoolingDXVariableSpeed.new(model)
cooling_coil_speed_1 = OpenStudio::Model::CoilCoolingDXVariableSpeedSpeedData.new(model)
cooling_coil.addSpeed(cooling_coil_speed_1)

unitary = OpenStudio::Model::AirLoopHVACUnitaryHeatPumpAirToAir.new(model, schedule, fan, heating_coil, cooling_coil, supp_heating_coil)
unitary.addToNode(supplyOutletNode)

terminal = OpenStudio::Model::AirTerminalSingleDuctConstantVolumeNoReheat.new(model, schedule)
air_loop.addBranchForZone(zone, terminal.to_StraightComponent)
unitary.setControllingZone(zone)

# save the OpenStudio model (.osm)
model.save_openstudio_osm({ 'osm_save_directory' => Dir.pwd,
                            'osm_name' => 'in.osm' })
