
require 'openstudio'
require 'lib/baseline_model'

m = BaselineModel.new

#make a 2 story, 100m X 50m, 2 zone core/perimeter building
m.add_geometry({"length" => 100,
                    "width" => 50,
                    "num_floors" => 2,
                    "floor_to_floor_height" => 4,
                    "plenum_height" => 1,
                    "perimeter_zone_depth" => 0})

#add windows at a 40% window-to-wall ratio
m.add_windows({"wwr" => 0.4,
                   "offset" => 1,
                   "application_type" => "Above Floor"})

#add thermostats
m.add_thermostats({"heating_setpoint" => 24,
                       "cooling_setpoint" => 28})

#assign constructions from a local library to the walls/windows/etc. in the model
m.set_constructions()

#set whole building space type; simplified 90.1-2004 Large Office Whole Building
m.set_space_type()

#add design days to the model (Chicago)
m.add_design_days()


# In order to produce more consistent results between different runs,
# we sort the zones by names
zones = m.getThermalZones.sort_by{|z| z.name.to_s}

controlled_zone = zones[0]
plenum_zone = zones[1]
plenum_zone.resetThermostatSetpointDualSetpoint

# Make a Unitary for zone 1, set zone 2 as plenum, and connect unitary bypass
# to that plenum
a = OpenStudio::Model::AirLoopHVAC.new(m)

reheat_coil = OpenStudio::Model::CoilHeatingGas.new(m)
terminal = OpenStudio::Model::AirTerminalSingleDuctVAVHeatAndCoolReheat.new(m, reheat_coil)
a.addBranchForZone(controlled_zone, terminal)

controlled_zone.setReturnPlenum(plenum_zone)

mixer = a.zoneMixer
# Get the Plenum, ensuring we have the one we want (in this case the model only
# has one so there's just m.getAirLoopHVACReturnPlenums[0] that would work...)
return_plenum = a.demandComponents(controlled_zone, mixer).select{|c| c.iddObjectType == "OS:AirLoopHVAC:ReturnPlenum".to_IddObjectType}[0]
return_plenum = return_plenum.to_AirLoopHVACReturnPlenum.get

fan = OpenStudio::Model::FanConstantVolume.new(m)
cc = OpenStudio::Model::CoilCoolingDXSingleSpeed.new(m)
hc = OpenStudio::Model::CoilHeatingGas.new(m)
unitary = OpenStudio::Model::AirLoopHVACUnitaryHeatCoolVAVChangeoverBypass.new(m, fan, cc, hc)


# Connecting to a Plenum / Mixer is meant to be used with an external Outdoor
# Air System, setting the internal one to zero
unitary.setOutdoorAirFlowRateDuringCoolingOperation(0.0)
unitary.setOutdoorAirFlowRateDuringHeatingOperation(0.0)
unitary.setOutdoorAirFlowRateWhenNoCoolingorHeatingisNeeded(0.0)
controllerOutdoorAir = OpenStudio::Model::ControllerOutdoorAir.new(m)
outdoorAirSystem = OpenStudio::Model::AirLoopHVACOutdoorAirSystem.new(m, controllerOutdoorAir)

outdoorAirSystem.addToNode(a.supplyOutletNode)
unitary.addToNode(a.supplyOutletNode)

unitary.setPlenumorMixer(return_plenum)

#save the OpenStudio model (.osm)
model.save_openstudio_osm({"osm_save_directory" => Dir.pwd,
                           "osm_name" => "in.osm"})
