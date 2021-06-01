# frozen_string_literal: true

# This test aims to test the new feature (in E+ 9.3.0) that allows connecting
# a ZoneHVAC:TerminalUnit:VariableRefrigerantFlow to an AirLoopHVAC / AirLoopHVACOutdoorAirSystem
# This feature was added in 3.2.0

require 'openstudio'
require 'lib/baseline_model'

model = BaselineModel.new

# make a 1 story, 100m X 50m, 5 zone building
model.add_geometry({ 'length' => 100,
                     'width' => 50,
                     'num_floors' => 1,
                     'floor_to_floor_height' => 3,
                     'plenum_height' => 0,
                     'perimeter_zone_depth' => 3 })

# add windows at a 40% window-to-wall ratio
model.add_windows({ 'wwr' => 0.4,
                    'offset' => 1,
                    'application_type' => 'Above Floor' })

# add thermostats
model.add_thermostats({ 'heating_setpoint' => 19,
                        'cooling_setpoint' => 26 })

# assign constructions from a local library to the walls/windows/etc. in the model
model.set_constructions

# set whole building space type; simplified 90.1-2004 Large Office Whole Building
model.set_space_type

# add design days to the model (Chicago)
model.add_design_days

# In order to produce more consistent results between different runs,
# we sort the zones by names
zones = model.getThermalZones.sort_by { |z| z.name.to_s }

# Create an AirLoopHVAC, with an OutdoorAirSystem
airLoop = OpenStudio::Model::AirLoopHVAC.new(model)
controllerOutdoorAir = OpenStudio::Model::ControllerOutdoorAir.new(model)
outdoorAirSystem = OpenStudio::Model::AirLoopHVACOutdoorAirSystem.new(model, controllerOutdoorAir)
outdoorAirSystem.addToNode(airLoop.supplyOutletNode)

# Create an AirLoopHVAC, with an OutdoorAirSystem, AND a supply fan on main
# branch
airLoopWithOwnFan = OpenStudio::Model::AirLoopHVAC.new(model)
controllerOutdoorAir2 = OpenStudio::Model::ControllerOutdoorAir.new(model)
outdoorAirSystem2 = OpenStudio::Model::AirLoopHVACOutdoorAirSystem.new(model, controllerOutdoorAir2)
outdoorAirSystem2.addToNode(airLoopWithOwnFan.supplyOutletNode)

vrf = OpenStudio::Model::AirConditionerVariableRefrigerantFlow.new(model)
# E+ now throws when the CoolingEIRLowPLR has a curve minimum value of x which
# is higher than the Minimum Heat Pump Part-Load Ratio.
# The curve has a min of 0.5 here, so set the MinimumHeatPumpPartLoadRatio to
# the same value
vrf.setMinimumHeatPumpPartLoadRatio(0.5)

def name_vrf_terminal(vrf_terminal, name)
  vrf_terminal.setName(name)
  vrf_terminal.coolingCoil.get.setName("#{name} CC")
  vrf_terminal.heatingCoil.get.setName("#{name} HC")
  vrf_terminal.supplyAirFan.setName("#{name} Fan")
end

zones.each_with_index do |z, i|
  case i
  when 0
    # First zone, we place this VRF Terminal on the main branch of the AirLoopHVAC
    # The default Ctor has a fan, which we actually need here
    vrf_terminal = OpenStudio::Model::ZoneHVACTerminalUnitVariableRefrigerantFlow.new(model)
    vrf_terminal.addToNode(airLoop.supplyOutletNode)
    vrf_terminal.setControllingZoneorThermostatLocation(z)
    name_vrf_terminal(vrf_terminal, 'VRF Terminal on Main Branch')
    vrf_terminal.setSupplyAirFanPlacement('DrawThrough')
    vrf.addTerminal(vrf_terminal)

    # And we add an ATU Uncontroller for this zone
    atu = OpenStudio::Model::AirTerminalSingleDuctConstantVolumeNoReheat.new(model, model.alwaysOnDiscreteSchedule)
    airLoop.addBranchForZone(z, atu)
  when 1

    # First zone, we place this VRF Terminal on the main branch of the AirLoopHVAC
    # The default Ctor has a fan, which we actually don't need here since we
    # place a fan on the AirLoopHVAC main branch (it won't be FT'ed)
    vrf_terminal = OpenStudio::Model::ZoneHVACTerminalUnitVariableRefrigerantFlow.new(model)
    vrf_terminal.addToNode(airLoopWithOwnFan.supplyOutletNode)
    vrf_terminal.setControllingZoneorThermostatLocation(z)
    name_vrf_terminal(vrf_terminal, 'VRF Terminal on Main Branch that has a fan')
    vrf_terminal.setSupplyAirFanPlacement('DrawThrough')
    vrf.addTerminal(vrf_terminal)

    # And we add an ATU Uncontroller for this zone
    atu = OpenStudio::Model::AirTerminalSingleDuctConstantVolumeNoReheat.new(model, model.alwaysOnDiscreteSchedule)
    airLoopWithOwnFan.addBranchForZone(z, atu)

    fan = OpenStudio::Model::FanSystemModel.new(model)
    fan.addToNode(airLoopWithOwnFan.supplyOutletNode)

  else
    # We add an ATU, for outside air
    atu = OpenStudio::Model::AirTerminalSingleDuctConstantVolumeNoReheat.new(model, model.alwaysOnDiscreteSchedule)
    if i.even?
      airLoop.addBranchForZone(z, atu)
    else
      airLoopWithOwnFan.addBranchForZone(z, atu)
    end

    # And a regular (zonehvac) VRF terminal
    vrf_terminal = OpenStudio::Model::ZoneHVACTerminalUnitVariableRefrigerantFlow.new(model)
    vrf_terminal.addToThermalZone(z)
    vrf_terminal.setSupplyAirFanPlacement('BlowThrough')
    name_vrf_terminal(vrf_terminal, 'Regular VRF Terminal')
    vrf.addTerminal(vrf_terminal)
  end
end

# Now we also create a VRF Terminal to place onto the OutdoorAirSystem, on the OA branch (for preheat/precool)
oa_vrf_terminal = OpenStudio::Model::ZoneHVACTerminalUnitVariableRefrigerantFlow.new(model)
oa_vrf_terminal.addToNode(outdoorAirSystem.outboardOANode.get)
name_vrf_terminal(oa_vrf_terminal, 'VRF Terminal on OA System')
oa_vrf_terminal.setSupplyAirFanPlacement('DrawThrough')
vrf.addTerminal(oa_vrf_terminal)

lat_temp_f = 70.0
lat_temp_c = OpenStudio.convert(lat_temp_f, 'F', 'C').get
lat_temp_sch = OpenStudio::Model::ScheduleRuleset.new(model)
lat_temp_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0, 24, 0, 0), lat_temp_c)
lat_stpt_manager1 = OpenStudio::Model::SetpointManagerScheduled.new(model, lat_temp_sch)
lat_stpt_manager1.addToNode(airLoop.supplyOutletNode)

# A default SPM Mixed air will be created by OpenStudio if not explictly set
# lat_stpt_manager2 = lat_stpt_manager1.clone(model).to_SetpointManagerScheduled.get
# lat_stpt_manager2.addToNode(oa_vrf_terminal.outletNode.get)

# save the OpenStudio model (.osm)
model.save_openstudio_osm({ 'osm_save_directory' => Dir.pwd,
                            'osm_name' => 'in.osm' })
