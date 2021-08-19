# frozen_string_literal: true

require 'openstudio'
# require 'C:/Projects/OpenStudio_branch/build/OpenStudioCore-prefix/src/OpenStudioCore-build/ruby/Debug/openstudio.rb'
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

# add packaged rooftop VAV with dist chilled and hot water attach all zones

# Make a time stamp to use in multiple places
os_time = OpenStudio::Time.new(0, 24, 0, 0)

# always On Schedule
# Schedule Ruleset
always_on_sch = OpenStudio::Model::ScheduleRuleset.new(model)
always_on_sch.setName('Always_On')
# Winter Design Day
always_on_sch_winter = OpenStudio::Model::ScheduleDay.new(model)
always_on_sch.setWinterDesignDaySchedule(always_on_sch_winter)
always_on_sch.winterDesignDaySchedule.setName('Always_On_Winter_Design_Day')
always_on_sch.winterDesignDaySchedule.addValue(os_time, 1)
# Summer Design Day
always_on_sch_summer = OpenStudio::Model::ScheduleDay.new(model)
always_on_sch.setSummerDesignDaySchedule(always_on_sch_summer)
always_on_sch.summerDesignDaySchedule.setName('Always_On_Summer_Design_Day')
always_on_sch.summerDesignDaySchedule.addValue(os_time, 1)
# All other days
always_on_sch.defaultDaySchedule.setName('Always_On_Default')
always_on_sch.defaultDaySchedule.addValue(os_time, 1)

# deck temperature schedule
# Schedule Ruleset
deck_temp_sch = OpenStudio::Model::ScheduleRuleset.new(model)
deck_temp_sch.setName('Deck_Temperature')
# Winter Design Day
deck_temp_sch_winter = OpenStudio::Model::ScheduleDay.new(model)
deck_temp_sch.setWinterDesignDaySchedule(deck_temp_sch_winter)
deck_temp_sch.winterDesignDaySchedule.setName('Deck_Temperature_Winter_Design_Day')
deck_temp_sch.winterDesignDaySchedule.addValue(os_time, 12.8)
# Summer Design Day
deck_temp_sch_summer = OpenStudio::Model::ScheduleDay.new(model)
deck_temp_sch.setSummerDesignDaySchedule(deck_temp_sch_summer)
deck_temp_sch.summerDesignDaySchedule.setName('Deck_Temperature_Summer_Design_Day')
deck_temp_sch.summerDesignDaySchedule.addValue(os_time, 12.8)
# All other days
deck_temp_sch.defaultDaySchedule.setName('Deck_Temperature_Default')
deck_temp_sch.defaultDaySchedule.addValue(os_time, 12.8)

# hot Water Temp Schedule
# Schedule Ruleset
hot_water_temp_sch = OpenStudio::Model::ScheduleRuleset.new(model)
hot_water_temp_sch.setName('Hot_Water_Temperature')
# Winter Design Day
hot_water_temp_sch_winter = OpenStudio::Model::ScheduleDay.new(model)
hot_water_temp_sch.setWinterDesignDaySchedule(hot_water_temp_sch_winter)
hot_water_temp_sch.winterDesignDaySchedule.setName('Hot_Water_Temperature_Winter_Design_Day')
hot_water_temp_sch.winterDesignDaySchedule.addValue(os_time, 67)
# Summer Design Day
hot_water_temp_sch_summer = OpenStudio::Model::ScheduleDay.new(model)
hot_water_temp_sch.setSummerDesignDaySchedule(hot_water_temp_sch_summer)
hot_water_temp_sch.summerDesignDaySchedule.setName('Hot_Water_Temperature_Summer_Design_Day')
hot_water_temp_sch.summerDesignDaySchedule.addValue(os_time, 67)
# All other days
hot_water_temp_sch.defaultDaySchedule.setName('Hot_Water_Temperature_Default')
hot_water_temp_sch.defaultDaySchedule.addValue(os_time, 67)

# chilled Water Temp Schedule
# Schedule Ruleset
chilled_water_temp_sch = OpenStudio::Model::ScheduleRuleset.new(model)
chilled_water_temp_sch.setName('Chilled_Water_Temperature')
# Winter Design Day
chilled_water_temp_schWinter = OpenStudio::Model::ScheduleDay.new(model)
chilled_water_temp_sch.setWinterDesignDaySchedule(chilled_water_temp_schWinter)
chilled_water_temp_sch.winterDesignDaySchedule.setName('Chilled_Water_Temperature_Winter_Design_Day')
chilled_water_temp_sch.winterDesignDaySchedule.addValue(os_time, 6.7)
# Summer Design Day
chilled_water_temp_schSummer = OpenStudio::Model::ScheduleDay.new(model)
chilled_water_temp_sch.setSummerDesignDaySchedule(chilled_water_temp_schSummer)
chilled_water_temp_sch.summerDesignDaySchedule.setName('Chilled_Water_Temperature_Summer_Design_Day')
chilled_water_temp_sch.summerDesignDaySchedule.addValue(os_time, 6.7)
# All other days
chilled_water_temp_sch.defaultDaySchedule.setName('Chilled_Water_Temperature_Default')
chilled_water_temp_sch.defaultDaySchedule.addValue(os_time, 6.7)

# new airloop
airLoopHVAC = OpenStudio::Model::AirLoopHVAC.new(model)

# system sizing
sizingSystem = airLoopHVAC.sizingSystem
sizingSystem.setCentralCoolingDesignSupplyAirTemperature(12.8)
sizingSystem.setCentralHeatingDesignSupplyAirTemperature(12.8)

# fan
fan = OpenStudio::Model::FanVariableVolume.new(model, always_on_sch)
fan.setPressureRise(500)

# hot water heating coil
coilHeatingWater = OpenStudio::Model::CoilHeatingWater.new(model, always_on_sch)

# chilled water cooling coil
coilCoolingWater = OpenStudio::Model::CoilCoolingWater.new(model, always_on_sch)

# setpoint managers
setpointMMA1 = OpenStudio::Model::SetpointManagerMixedAir.new(model)
setpointMMA2 = OpenStudio::Model::SetpointManagerMixedAir.new(model)
setpointMMA3 = OpenStudio::Model::SetpointManagerMixedAir.new(model)
deckTempSPM = OpenStudio::Model::SetpointManagerScheduled.new(model, deck_temp_sch)

# OA controller
controllerOutdoorAir = OpenStudio::Model::ControllerOutdoorAir.new(model)
outdoorAirSystem = OpenStudio::Model::AirLoopHVACOutdoorAirSystem.new(model, controllerOutdoorAir)

# add the equipment to the airloop
supplyOutletNode = airLoopHVAC.supplyOutletNode
outdoorAirSystem.addToNode(supplyOutletNode)
coilCoolingWater.addToNode(supplyOutletNode)
coilHeatingWater.addToNode(supplyOutletNode)
fan.addToNode(supplyOutletNode)
node1 = fan.outletModelObject.get.to_Node.get
deckTempSPM.addToNode(node1)
node2 = coilHeatingWater.airOutletModelObject.get.to_Node.get
setpointMMA1.addToNode(node2)
node3 = coilCoolingWater.airOutletModelObject.get.to_Node.get
setpointMMA2.addToNode(node3)
node4 = outdoorAirSystem.mixedAirModelObject.get.to_Node.get
setpointMMA3.addToNode(node4)

# Hot Water Plant
hotWaterPlant = OpenStudio::Model::PlantLoop.new(model)
sizingPlant = hotWaterPlant.sizingPlant
sizingPlant.setLoopType('Heating')
sizingPlant.setDesignLoopExitTemperature(82.0)
sizingPlant.setLoopDesignTemperatureDifference(11.0)
hotWaterOutletNode = hotWaterPlant.supplyOutletNode
hotWaterInletNode = hotWaterPlant.supplyInletNode
hotWaterDemandOutletNode = hotWaterPlant.demandOutletNode
hotWaterDemandInletNode = hotWaterPlant.demandInletNode

# pump
pump = OpenStudio::Model::HeaderedPumpsVariableSpeed.new(model)

# district heating
district_heating = OpenStudio::Model::DistrictHeating.new(model)

# add the equipment to the hot water loop
pump.addToNode(hotWaterInletNode)
node = hotWaterPlant.supplySplitter.lastOutletModelObject.get.to_Node.get
district_heating.addToNode(node)
pipe = OpenStudio::Model::PipeAdiabatic.new(model)
hotWaterPlant.addSupplyBranchForComponent(pipe)
hotWaterBypass = OpenStudio::Model::PipeAdiabatic.new(model)
hotWaterPlant.addDemandBranchForComponent(hotWaterBypass)
hotWaterPlant.addDemandBranchForComponent(coilHeatingWater)
hotWaterDemandInlet = OpenStudio::Model::PipeAdiabatic.new(model)
hotWaterDemandOutlet = OpenStudio::Model::PipeAdiabatic.new(model)
hotWaterDemandOutlet.addToNode(hotWaterDemandOutletNode)
hotWaterDemandInlet.addToNode(hotWaterDemandInletNode)
pipe2 = OpenStudio::Model::PipeAdiabatic.new(model)
pipe2.addToNode(hotWaterOutletNode)
hotWaterSPM = OpenStudio::Model::SetpointManagerScheduled.new(model, hot_water_temp_sch)
hotWaterSPM.addToNode(hotWaterOutletNode)

# Chilled Water Plant
chilledWaterPlant = OpenStudio::Model::PlantLoop.new(model)
chilledWaterSizing = chilledWaterPlant.sizingPlant
chilledWaterSizing.setLoopType('Cooling')
chilledWaterSizing.setDesignLoopExitTemperature(7.22)
chilledWaterSizing.setLoopDesignTemperatureDifference(6.67)
chilledWaterOutletNode = chilledWaterPlant.supplyOutletNode
chilledWaterInletNode = chilledWaterPlant.supplyInletNode
chilledWaterDemandOutletNode = chilledWaterPlant.demandOutletNode
chilledWaterDemandInletNode = chilledWaterPlant.demandInletNode

# pump
pump2 = OpenStudio::Model::HeaderedPumpsConstantSpeed.new(model)
pump2.addToNode(chilledWaterInletNode)

# district cooling
district_cooling = OpenStudio::Model::DistrictCooling.new(model)

# add equipment to the chilled water loop
node = chilledWaterPlant.supplySplitter.lastOutletModelObject.get.to_Node.get
district_cooling.addToNode(node)
pipe3 = OpenStudio::Model::PipeAdiabatic.new(model)
chilledWaterPlant.addSupplyBranchForComponent(pipe3)
pipe4 = OpenStudio::Model::PipeAdiabatic.new(model)
pipe4.addToNode(chilledWaterOutletNode)
chilledWaterPlant.addDemandBranchForComponent(coilCoolingWater)
chilledWaterSPM = OpenStudio::Model::SetpointManagerScheduled.new(model, chilled_water_temp_sch)
chilledWaterSPM.addToNode(chilledWaterOutletNode)
waterReheatCoil = OpenStudio::Model::CoilHeatingWater.new(model, always_on_sch)
waterTerminal = OpenStudio::Model::AirTerminalSingleDuctVAVReheat.new(model, always_on_sch, waterReheatCoil)
airLoopHVAC.addBranchForHVACComponent(waterTerminal)

chilledWaterDemandBypass = OpenStudio::Model::PipeAdiabatic.new(model)
chilledWaterPlant.addDemandBranchForComponent(chilledWaterDemandBypass)

hotWaterPlant.addDemandBranchForComponent(waterReheatCoil)

chilledWaterDemandInlet = OpenStudio::Model::PipeAdiabatic.new(model)
chilledWaterDemandInlet.addToNode(chilledWaterDemandInletNode)

chilledWaterDemandOutlet = OpenStudio::Model::PipeAdiabatic.new(model)
chilledWaterDemandOutlet.addToNode(chilledWaterDemandOutletNode)

# hook all zones to the airloop
# In order to produce more consistent results between different runs,
# we sort the zones by names (doesn't matter here, just in case)
zones = model.getThermalZones.sort_by { |z| z.name.to_s }
zones.each do |zone|
  airLoopHVAC.addBranchForZone(zone)
end

# add thermostats
model.add_thermostats({ 'heating_setpoint' => 24,
                        'cooling_setpoint' => 28 })

# assign constructions from a local library to the walls/windows/etc. in the model
model.set_constructions

# set whole building space type simplified 90.1-2004 Large Office Whole Building
model.set_space_type

# add design days to the model (Chicago)
model.add_design_days

# save the OpenStudio model (.osm)
model.save_openstudio_osm({ 'osm_save_directory' => Dir.pwd,
                            'osm_name' => 'in.osm' })
