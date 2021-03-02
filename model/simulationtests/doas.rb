# frozen_string_literal: true

require 'openstudio'
require_relative 'lib/baseline_model'

model = BaselineModel.new

# make a 2 story, 100m X 50m, 2 zone building
model.add_geometry({ 'length' => 100,
                     'width' => 50,
                     'num_floors' => 2,
                     'floor_to_floor_height' => 4,
                     'plenum_height' => 0,
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
zone1 = zones[0]
zone2 = zones[1]

# Outdoor Air System 1
controller1 = OpenStudio::Model::ControllerOutdoorAir.new(model)
oas1 = OpenStudio::Model::AirLoopHVACOutdoorAirSystem.new(model, controller1)
airloop1 = OpenStudio::Model::AirLoopHVAC.new(model)
supplyOutletNode1 = airloop1.supplyOutletNode
oas1.addToNode(supplyOutletNode1)
airloop1.addBranchForZone(zone1)

# Outdoor Air System 2
controller2 = OpenStudio::Model::ControllerOutdoorAir.new(model)
oas2 = OpenStudio::Model::AirLoopHVACOutdoorAirSystem.new(model, controller2)
airloop2 = OpenStudio::Model::AirLoopHVAC.new(model)
supplyOutletNode2 = airloop2.supplyOutletNode
oas2.addToNode(supplyOutletNode2)
airloop2.addBranchForZone(zone2)

# Dedicated Outdoor Air System
controller = OpenStudio::Model::ControllerOutdoorAir.new(model) # this won't be translated
oas = OpenStudio::Model::AirLoopHVACOutdoorAirSystem.new(model, controller)
doas = OpenStudio::Model::AirLoopHVACDedicatedOutdoorAirSystem.new(oas)
doas.addAirLoop(airloop1)
doas.addAirLoop(airloop2)

coil_cooling_water = OpenStudio::Model::CoilCoolingWater.new(model)
coil_heating_water = OpenStudio::Model::CoilHeatingWater.new(model)
fan = OpenStudio::Model::FanVariableVolume.new(model)

coil_cooling_water.addToNode(oas.outboardOANode.get)
coil_heating_water.addToNode(oas.outboardOANode.get)
fan.addToNode(oas.outboardOANode.get)

chilled_water = OpenStudio::Model::PlantLoop.new(model)
chilled_water.addDemandBranchForComponent(coil_cooling_water)
chilled_water_inlet = chilled_water.supplyInletNode
chilled_water_outlet = chilled_water.supplyOutletNode
chilled_water_pump = OpenStudio::Model::PumpVariableSpeed.new(model)
chilled_water_pump.addToNode(chilled_water_inlet)
pipe = OpenStudio::Model::PipeAdiabatic.new(model)
chilled_water.addSupplyBranchForComponent(pipe)
pipe2 = OpenStudio::Model::PipeAdiabatic.new(model)
pipe2.addToNode(chilled_water_outlet)

hot_water = OpenStudio::Model::PlantLoop.new(model)
hot_water.addDemandBranchForComponent(coil_heating_water)
hot_water_inlet = hot_water_inlet.supplyInletNode
hot_water_outlet = hot_water.supplyOutletNode
hot_water_pump = OpenStudio::Model::PumpVariableSpeed.new(model)
hot_water_pump.addToNode(hot_water_inlet)
pipe = OpenStudio::Model::PipeAdiabatic.new(model)
hot_water.addSupplyBranchForComponent(pipe)
pipe2 = OpenStudio::Model::PipeAdiabatic.new(model)
pipe2.addToNode(hot_water_outlet)

# save the OpenStudio model (.osm)
model.save_openstudio_osm({ 'osm_save_directory' => Dir.pwd, 'osm_name' => 'in.osm' })
