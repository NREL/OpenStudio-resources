# frozen_string_literal: true

require 'openstudio'
require_relative 'lib/baseline_model'

model = BaselineModel.new

# make a 2 story, 100m X 50m, 10 zone core/perimeter building
model.add_geometry({ 'length' => 100,
                     'width' => 50,
                     'num_floors' => 2,
                     'floor_to_floor_height' => 4,
                     'plenum_height' => 1,
                     'perimeter_zone_depth' => 3 })

# add windows at a 40% window-to-wall ratio
model.add_windows({ 'wwr' => 0.4,
                    'offset' => 1,
                    'application_type' => 'Above Floor' })

# In order to produce more consistent results between different runs,
# we sort the zones by names
zones = model.getThermalZones.sort_by { |z| z.name.to_s }

vrf_fluid_temperature_control = OpenStudio::Model::AirConditionerVariableRefrigerantFlowFluidTemperatureControl.new(model)
vrf_fluid_temperature_control_hr = OpenStudio::Model::AirConditionerVariableRefrigerantFlowFluidTemperatureControlHR.new(model)

zones.each_with_index do |z, i|
  vrf_terminal = OpenStudio::Model::ZoneHVACTerminalUnitVariableRefrigerantFlow.new(model)
  vrf_terminal.addToThermalZone(z)
  if i <= 4
    vrf_fluid_temperature_control.addTerminal(vrf_terminal)
  else
    vrf_fluid_temperature_control_hr.addTerminal(vrf_terminal)
  end
end

# add thermostats
model.add_thermostats({ 'heating_setpoint' => 24,
                        'cooling_setpoint' => 28 })

# assign constructions from a local library to the walls/windows/etc. in the model
model.set_constructions

# set whole building space type; simplified 90.1-2004 Large Office Whole Building
model.set_space_type

# add design days to the model (Chicago)
model.add_design_days

# save the OpenStudio model (.osm)
model.save_openstudio_osm({ 'osm_save_directory' => Dir.pwd,
                            'osm_name' => 'in.osm' })