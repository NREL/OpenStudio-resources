# frozen_string_literal: true

require 'openstudio'
require 'lib/baseline_model'

model = BaselineModel.new

# make a 3 story, 100m X 50m, 10 zone core/perimeter building
model.add_geometry({ 'length' => 100,
                     'width' => 50,
                     'num_floors' => 1,
                     'floor_to_floor_height' => 4,
                     'plenum_height' => 1,
                     'perimeter_zone_depth' => 3 })

# add windows at a 40% window-to-wall ratio
model.add_windows({ 'wwr' => 0.4,
                    'offset' => 1,
                    'application_type' => 'Above Floor' })

# add thermostats
model.add_thermostats({ 'heating_setpoint' => 24,
                        'cooling_setpoint' => 28 })

# chilled Water Temp Schedule
osTime = OpenStudio::Time.new(0, 24, 0, 0)
# Schedule Ruleset
chilled_water_temp_sch = OpenStudio::Model::ScheduleRuleset.new(model)
chilled_water_temp_sch.setName('Chilled_Water_Temperature')
# Winter Design Day
chilled_water_temp_schWinter = OpenStudio::Model::ScheduleDay.new(model)
chilled_water_temp_sch.setWinterDesignDaySchedule(chilled_water_temp_schWinter)
chilled_water_temp_sch.winterDesignDaySchedule.setName('Chilled_Water_Temperature_Winter_Design_Day')
chilled_water_temp_sch.winterDesignDaySchedule.addValue(osTime, 6.7)
# Summer Design Day
chilled_water_temp_schSummer = OpenStudio::Model::ScheduleDay.new(model)
chilled_water_temp_sch.setSummerDesignDaySchedule(chilled_water_temp_schSummer)
chilled_water_temp_sch.summerDesignDaySchedule.setName('Chilled_Water_Temperature_Summer_Design_Day')
chilled_water_temp_sch.summerDesignDaySchedule.addValue(osTime, 6.7)
# All other days
chilled_water_temp_sch.defaultDaySchedule.setName('Chilled_Water_Temperature_Default')
chilled_water_temp_sch.defaultDaySchedule.addValue(osTime, 6.7)

# Chilled Water Plant
chilledWaterPlant = OpenStudio::Model::PlantLoop.new(model)
chilledWaterPlant.setName('Chilled Water Plant')
chilledWaterSizing = chilledWaterPlant.sizingPlant
chilledWaterSizing.setLoopType('Cooling')
chilledWaterSizing.setDesignLoopExitTemperature(7.22)
chilledWaterSizing.setLoopDesignTemperatureDifference(6.67)
chilledWaterOutletNode = chilledWaterPlant.supplyOutletNode
chilledWaterInletNode = chilledWaterPlant.supplyInletNode
chilledWaterDemandOutletNode = chilledWaterPlant.demandOutletNode
chilledWaterDemandInletNode = chilledWaterPlant.demandInletNode
chilledWaterSPM = OpenStudio::Model::SetpointManagerScheduled.new(model, chilled_water_temp_sch)
chilledWaterSPM.addToNode(chilledWaterOutletNode)

# pump
chilledWaterPump = OpenStudio::Model::PumpVariableSpeed.new(model)
chilledWaterPump.addToNode(chilledWaterInletNode)

# district cooling
district_cooling = OpenStudio::Model::DistrictCooling.new(model)
chilledWaterPlant.addSupplyBranchForComponent(district_cooling)

chilledWaterDemandBypass = OpenStudio::Model::PipeAdiabatic.new(model)
chilledWaterPlant.addSupplyBranchForComponent(chilledWaterDemandBypass)

# assign constructions from a local library to the walls/windows/etc. in the model
model.set_constructions

# set whole building space type; simplified 90.1-2004 Large Office Whole Building
model.set_space_type

# add design days to the model (Chicago)
model.add_design_days

# assign thermal zones to variables
story_1_core_thermal_zone = model.getThermalZoneByName('Story 1 Core Thermal Zone').get

# Add ZoneHVACCoolingPanelRadiantConvectiveWater
zoneHVACCoolingPanelRadiantConvectiveWater = OpenStudio::Model::ZoneHVACCoolingPanelRadiantConvectiveWater.new(model)
panel_coil = zoneHVACCoolingPanelRadiantConvectiveWater.coolingCoil
chilledWaterPlant.addDemandBranchForComponent(panel_coil)
zoneHVACCoolingPanelRadiantConvectiveWater.addToThermalZone(story_1_core_thermal_zone)

# save the OpenStudio model (.osm)
model.save_openstudio_osm({ 'osm_save_directory' => Dir.pwd,
                            'osm_name' => 'in.osm' })
