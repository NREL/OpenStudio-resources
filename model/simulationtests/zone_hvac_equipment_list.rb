# frozen_string_literal: true

require 'openstudio'
require 'lib/baseline_model'

model = BaselineModel.new

# make a 2 story, 100m X 50m, 2 zone core/perimeter building
model.add_geometry({ 'length' => 100,
                     'width' => 50,
                     'num_floors' => 2,
                     'floor_to_floor_height' => 4,
                     'plenum_height' => 1,
                     'perimeter_zone_depth' => 0 })

# add windows at a 40% window-to-wall ratio
model.add_windows({ 'wwr' => 0.4,
                    'offset' => 1,
                    'application_type' => 'Above Floor' })

# add thermostats
model.add_thermostats({ 'heating_setpoint' => 24,
                        'cooling_setpoint' => 28 })

# assign constructions from a local library to the walls/windows/etc. in the model
model.set_constructions

# set whole building space type; simplified 90.1-2004 Large Office Whole Building
model.set_space_type

# add design days to the model (Chicago)
model.add_design_days

# In order to produce more consistent results between different runs,
# we sort the zones by names
zones = model.getThermalZones.sort_by { |z| z.name.to_s }

heating_schedule = OpenStudio::Model::ScheduleConstant.new(model)
heating_schedule.setValue(0.75)
cooling_schedule = OpenStudio::Model::ScheduleRuleset.new(model, 0.995)

zones.each_with_index do |thermal_zone, i|
  htg_coil = OpenStudio::Model::CoilHeatingDXSingleSpeed.new(model)
  htg_supp_coil = OpenStudio::Model::CoilHeatingElectric.new(model)
  clg_coil = OpenStudio::Model::CoilCoolingDXSingleSpeed.new(model)
  fan = OpenStudio::Model::FanOnOff.new(model)

  air_loop_unitary = OpenStudio::Model::AirLoopHVACUnitarySystem.new(model)
  air_loop_unitary.setSupplyFan(fan)
  # Be explicit about the fanPlacement. If you have a fan, you MUST supply a
  # fanPlacement. (FT currently Would default that to DrawThrough)
  air_loop_unitary.setFanPlacement('BlowThrough')
  air_loop_unitary.setHeatingCoil(htg_coil)
  air_loop_unitary.setCoolingCoil(clg_coil)
  air_loop_unitary.setSupplementalHeatingCoil(htg_supp_coil)

  air_loop = OpenStudio::Model::AirLoopHVAC.new(model)
  air_supply_inlet_node = air_loop.supplyInletNode

  air_loop_unitary.addToNode(air_supply_inlet_node)
  air_loop_unitary.setControllingZoneorThermostatLocation(thermal_zone)

  air_terminal_living = OpenStudio::Model::AirTerminalSingleDuctConstantVolumeNoReheat.new(model, model.alwaysOnDiscreteSchedule)
  # TODO: I don't think there's any reason to use the multiAddBranchForZone
  # method, addBranchForZone is plenty fine here.
  air_loop.multiAddBranchForZone(thermal_zone, air_terminal_living)

  if i == 0 # test that the old methods still accept doubles
    thermal_zone.setSequentialHeatingFraction(air_terminal_living, 0.9)
    thermal_zone.setSequentialHeatingFraction(air_terminal_living, 0.4)
  else # test new schedule arguments

    thermal_zone.setSequentialHeatingFractionSchedule(air_terminal_living, heating_schedule)
    thermal_zone.setSequentialHeatingFractionSchedule(air_terminal_living, cooling_schedule)
  end
end

# save the OpenStudio model (.osm)
model.save_openstudio_osm({ 'osm_save_directory' => Dir.pwd,
                            'osm_name' => 'in.osm' })
