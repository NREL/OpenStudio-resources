# frozen_string_literal: true

require 'openstudio'
require 'lib/baseline_model'

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

# add ASHRAE System type 07, VAV w/Reheat
model.add_hvac({ 'ashrae_sys_num' => '07' })

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
# We ensure we do get the same object each time
cts = model.getCoolingTowerSingleSpeeds.sort_by { |c| c.name.to_s }
chillers = model.getChillerElectricEIRs.sort_by { |c| c.name.to_s }
boilers = model.getBoilerHotWaters.sort_by { |c| c.name.to_s }

condenser_loop = cts.first.plantLoop.get
cooling_loop = chillers.first.plantLoop.get
heating_loop = boilers.first.plantLoop.get

# Get the heating loop
# We turn it off if the OA temp is above 18C, and turn it on, if below 15C
avm_HTOff = OpenStudio::Model::AvailabilityManagerHighTemperatureTurnOff.new(model)
avm_HTOff.setSensorNode(model.outdoorAirNode)
avm_HTOff.setTemperature(18)
heating_loop.addAvailabilityManager(avm_HTOff)

avm_LTOn = OpenStudio::Model::AvailabilityManagerLowTemperatureTurnOn.new(model)
avm_LTOn.setSensorNode(model.outdoorAirNode)
avm_LTOn.setTemperature(15)
heating_loop.addAvailabilityManager(avm_LTOn)

# Get the chiller water loop
# We turn it off if the OA Temp is below 15C, turn if back on if its over 18C
avm_LTOff = OpenStudio::Model::AvailabilityManagerLowTemperatureTurnOff.new(model)
avm_LTOff.setSensorNode(model.outdoorAirNode)
avm_LTOff.setTemperature(15)
cooling_loop.addAvailabilityManager(avm_LTOff)

avm_HTOn = OpenStudio::Model::AvailabilityManagerHighTemperatureTurnOn.new(model)
avm_HTOn.setSensorNode(model.outdoorAirNode)
avm_HTOn.setTemperature(18)
cooling_loop.addAvailabilityManager(avm_HTOn)

# Get the Condenser loop
# We control it by looking at the chilled water return temp and the cooling
# tower supply temp, needs to be at least 2C diff to be on, and once it goes to 10C
# difference, we shut the CT loop.
# Note: whether this makes sense from a design standpoint is out of question
# here. The classical application of this one is for solar collectors on the
# demand side of a plant loop (temp diffs are reversed, 2 for Off, 10 for On),
# which OpenStudio doesn't allow right now
chw_pump = cooling_loop.supplyComponents('OS_Pump_VariableSpeed'.to_IddObjectType)[0].to_PumpVariableSpeed.get
chw_pump_outlet_node = chw_pump.outletModelObject.get.to_Node.get

avm_Diff = OpenStudio::Model::AvailabilityManagerDifferentialThermostat.new(model)
avm_Diff.setHotNode(chw_pump_outlet_node)
avm_Diff.setColdNode(condenser_loop.supplyOutletNode)
avm_Diff.setTemperatureDifferenceOnLimit(2)
avm_Diff.setTemperatureDifferenceOffLimit(10)

# save the OpenStudio model (.osm)
model.save_openstudio_osm({ 'osm_save_directory' => Dir.pwd,
                            'osm_name' => 'in.osm' })
