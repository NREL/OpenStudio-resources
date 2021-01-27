# frozen_string_literal: true

require 'openstudio'
require_relative 'lib/baseline_model'

model = BaselineModel.new

# make a 1 story, 100m X 50m, 5 zone core/perimeter building
model.add_geometry({ 'length' => 100,
                     'width' => 50,
                     'num_floors' => 1,
                     'floor_to_floor_height' => 4,
                     'plenum_height' => 0,
                     'perimeter_zone_depth' => 3 })

# add windows at a 40% window-to-wall ratio
model.add_windows({ 'wwr' => 0.4,
                    'offset' => 1,
                    'application_type' => 'Above Floor' })

# add ASHRAE System type 01, PTAC, Residential
model.add_hvac({ 'ashrae_sys_num' => '01' })

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

alwaysOn = model.alwaysOnDiscreteSchedule

[zones[0], zones[1], zones[2]].each_with_index do |zone, i|
  if i == 0
    # CoilCoolingDXSingleSpeed
    htg_coil = OpenStudio::Model::CoilHeatingElectric.new(model, model.alwaysOffDiscreteSchedule)
    clg_coil = OpenStudio::Model::CoilCoolingDXSingleSpeed.new(model)
    fan = OpenStudio::Model::FanOnOff.new(model, alwaysOn)
    ptac = OpenStudio::Model::ZoneHVACPackagedTerminalAirConditioner.new(model, alwaysOn, fan, htg_coil, clg_coil)
    ptac.addToThermalZone(zone)
  elsif i == 1
    # CoilCoolingDXVariableSpeed
    htg_coil = OpenStudio::Model::CoilHeatingElectric.new(model, model.alwaysOffDiscreteSchedule)
    clg_coil = OpenStudio::Model::CoilCoolingDXVariableSpeed.new(model)
    clg_coil_data = OpenStudio::Model::CoilCoolingDXVariableSpeedSpeedData.new(model)
    clg_coil.addSpeed(clg_coil_data)
    fan = OpenStudio::Model::FanOnOff.new(model, alwaysOn)
    ptac = OpenStudio::Model::ZoneHVACPackagedTerminalAirConditioner.new(model, alwaysOn, fan, htg_coil, clg_coil)
    ptac.addToThermalZone(zone)
  elsif i == 2
    # CoilSystemCoolingDXHeatExchangerAssisted
    htg_coil = OpenStudio::Model::CoilHeatingElectric.new(model, model.alwaysOffDiscreteSchedule)
    clg_coil = OpenStudio::Model::CoilSystemCoolingDXHeatExchangerAssisted.new(model)
    fan = OpenStudio::Model::FanOnOff.new(model, alwaysOn)
    ptac = OpenStudio::Model::ZoneHVACPackagedTerminalAirConditioner.new(model, alwaysOn, fan, htg_coil, clg_coil)
    ptac.addToThermalZone(zone)
  end
end

# save the OpenStudio model (.osm)
model.save_openstudio_osm({ 'osm_save_directory' => Dir.pwd, 'osm_name' => 'in.osm' })
