
require 'openstudio'
require 'lib/baseline_model'

model = BaselineModel.new

#make a 3 story, 100m X 50m, 10 zone core/perimeter building
model.add_geometry({"length" => 100,
              "width" => 50,
              "num_floors" => 3,
              "floor_to_floor_height" => 4,
              "plenum_height" => 1,
              "perimeter_zone_depth" => 3})

#add windows at a 40% window-to-wall ratio
model.add_windows({"wwr" => 0.4,
                  "offset" => 1,
                  "application_type" => "Above Floor"})

#add thermostats
model.add_thermostats({"heating_setpoint" => 24,
                      "cooling_setpoint" => 28})
                      
# Add a hot water plant to supply the baseboard heaters
# This could be baked into HVAC templates in the future
hotWaterPlant = OpenStudio::Model::PlantLoop.new(model)
hotWaterPlant.setName('Hot Water Plant')

sizingPlant = hotWaterPlant.sizingPlant()
sizingPlant.setLoopType('Heating')
sizingPlant.setDesignLoopExitTemperature(82.0)
sizingPlant.setLoopDesignTemperatureDifference(11.0)

hotWaterOutletNode = hotWaterPlant.supplyOutletNode()
hotWaterInletNode = hotWaterPlant.supplyInletNode()

pump = OpenStudio::Model::PumpVariableSpeed.new(model)
pump.addToNode(hotWaterInletNode)

boiler = OpenStudio::Model::BoilerHotWater.new(model)
node = hotWaterPlant.supplySplitter().lastOutletModelObject().get().to_Node().get()
boiler.addToNode(node)

pipe = OpenStudio::Model::PipeAdiabatic.new(model)
hotWaterPlant.addSupplyBranchForComponent(pipe)

pipe2 = OpenStudio::Model::PipeAdiabatic.new(model)
pipe2.addToNode(hotWaterOutletNode)

## Make a hot Water temperature schedule
  
osTime = OpenStudio::Time.new(0,24,0,0)

hotWaterTempSchedule = OpenStudio::Model::ScheduleRuleset.new(model)
hotWaterTempSchedule.setName('Hot Water Temperature')

### Winter Design Day
hotWaterTempScheduleWinter = OpenStudio::Model::ScheduleDay.new(model)
hotWaterTempSchedule.setWinterDesignDaySchedule(hotWaterTempScheduleWinter)
hotWaterTempSchedule.winterDesignDaySchedule().setName('Hot Water Temperature Winter Design Day')
hotWaterTempSchedule.winterDesignDaySchedule().addValue(osTime,67)

### Summer Design Day
hotWaterTempScheduleSummer = OpenStudio::Model::ScheduleDay.new(model)
hotWaterTempSchedule.setSummerDesignDaySchedule(hotWaterTempScheduleSummer)
hotWaterTempSchedule.summerDesignDaySchedule().setName("Hot Water Temperature Summer Design Day")
hotWaterTempSchedule.summerDesignDaySchedule().addValue(osTime,67)

### All other days
hotWaterTempSchedule.defaultDaySchedule().setName("Hot Water Temperature Default")
hotWaterTempSchedule.defaultDaySchedule().addValue(osTime,67)

hotWaterSPM = OpenStudio::Model::SetpointManagerScheduled.new(model,hotWaterTempSchedule)
hotWaterSPM.addToNode(hotWaterOutletNode)                      

# Add a hot water plant to supply the water to air heat pump
# This could be baked into HVAC templates in the future
condenserWaterPlant = OpenStudio::Model::PlantLoop.new(model)
condenserWaterPlant.setName('Condenser Water Plant')

sizingPlant = condenserWaterPlant.sizingPlant()
sizingPlant.setLoopType('Heating')
sizingPlant.setDesignLoopExitTemperature(30.0)
sizingPlant.setLoopDesignTemperatureDifference(11.0)

condenserWaterOutletNode = condenserWaterPlant.supplyOutletNode()
condenserWaterInletNode = condenserWaterPlant.supplyInletNode()

pump = OpenStudio::Model::PumpVariableSpeed.new(model)
pump.addToNode(condenserWaterInletNode)

distHeating = OpenStudio::Model::DistrictHeating.new(model)
condenserWaterPlant.addSupplyBranchForComponent(distHeating)

fluidCooler = OpenStudio::Model::EvaporativeFluidCoolerSingleSpeed.new(model)
condenserWaterPlant.addSupplyBranchForComponent(fluidCooler)

groundHX = OpenStudio::Model::GroundHeatExchangerVertical.new(model)
condenserWaterPlant.addSupplyBranchForComponent(groundHX)

pipe = OpenStudio::Model::PipeAdiabatic.new(model)
condenserWaterPlant.addSupplyBranchForComponent(pipe)

pipe2 = OpenStudio::Model::PipeAdiabatic.new(model)
pipe2.addToNode(condenserWaterOutletNode)

## Make a condenser Water temperature schedule
  
osTime = OpenStudio::Time.new(0,24,0,0)

condenserWaterTempSchedule = OpenStudio::Model::ScheduleRuleset.new(model)
condenserWaterTempSchedule.setName('Condenser Water Temperature')

### Winter Design Day
condenserWaterTempScheduleWinter = OpenStudio::Model::ScheduleDay.new(model)
condenserWaterTempSchedule.setWinterDesignDaySchedule(condenserWaterTempScheduleWinter)
condenserWaterTempSchedule.winterDesignDaySchedule().setName('Condenser Water Temperature Winter Design Day')
condenserWaterTempSchedule.winterDesignDaySchedule().addValue(osTime,24)

### Summer Design Day
condenserWaterTempScheduleSummer = OpenStudio::Model::ScheduleDay.new(model)
condenserWaterTempSchedule.setSummerDesignDaySchedule(condenserWaterTempScheduleSummer)
condenserWaterTempSchedule.summerDesignDaySchedule().setName("Condenser Water Temperature Summer Design Day")
condenserWaterTempSchedule.summerDesignDaySchedule().addValue(osTime,24)

### All other days
condenserWaterTempSchedule.defaultDaySchedule().setName("Condenser Water Temperature Default")
condenserWaterTempSchedule.defaultDaySchedule().addValue(osTime,24)

condenserWaterSPM = OpenStudio::Model::SetpointManagerScheduled.new(model,condenserWaterTempSchedule)
condenserWaterSPM.addToNode(condenserWaterOutletNode)      

#assign constructions from a local library to the walls/windows/etc. in the model
model.set_constructions()

#set whole building space type; simplified 90.1-2004 Large Office Whole Building
model.set_space_type()  

#add design days to the model (Chicago)
model.add_design_days()
                     
#assign thermal zones to variables
story_1_core_thermal_zone = model.getThermalZoneByName("Story 1 Core Thermal Zone").get
story_1_north_thermal_zone = model.getThermalZoneByName("Story 1 North Perimeter Thermal Zone").get
story_1_south_thermal_zone = model.getThermalZoneByName("Story 1 South Perimeter Thermal Zone").get
story_1_east_thermal_zone = model.getThermalZoneByName("Story 1 East Perimeter Thermal Zone").get
story_1_west_thermal_zone = model.getThermalZoneByName("Story 1 West Perimeter Thermal Zone").get
story_2_core_thermal_zone = model.getThermalZoneByName("Story 2 Core Thermal Zone").get
story_2_north_thermal_zone = model.getThermalZoneByName("Story 2 North Perimeter Thermal Zone").get
story_2_south_thermal_zone = model.getThermalZoneByName("Story 2 South Perimeter Thermal Zone").get
story_2_east_thermal_zone = model.getThermalZoneByName("Story 2 East Perimeter Thermal Zone").get
story_2_west_thermal_zone = model.getThermalZoneByName("Story 2 West Perimeter Thermal Zone").get
story_3_core_thermal_zone = model.getThermalZoneByName("Story 3 Core Thermal Zone").get
story_3_north_thermal_zone = model.getThermalZoneByName("Story 3 North Perimeter Thermal Zone").get
story_3_south_thermal_zone = model.getThermalZoneByName("Story 3 South Perimeter Thermal Zone").get
story_3_east_thermal_zone = model.getThermalZoneByName("Story 3 East Perimeter Thermal Zone").get
story_3_west_thermal_zone = model.getThermalZoneByName("Story 3 West Perimeter Thermal Zone").get                      

#add a unit heater to next available zone
fan = OpenStudio::Model::FanConstantVolume.new(model,model.alwaysOnDiscreteSchedule())
coil = OpenStudio::Model::CoilHeatingElectric.new(model,model.alwaysOnDiscreteSchedule())
unit_heater = OpenStudio::Model::ZoneHVACUnitHeater.new(model,model.alwaysOnDiscreteSchedule(),fan,coil)
unit_heater.addToThermalZone(story_1_core_thermal_zone)

#add a zone exhaust fan to next available zone
zone_exhaust_fan = OpenStudio::Model::FanZoneExhaust.new(model)
zone_exhaust_fan.addToThermalZone(story_1_north_thermal_zone)

#add baseboard heater to next available zone
baseboard_coil = OpenStudio::Model::CoilHeatingWaterBaseboard.new(model)     
baseboard_heater = OpenStudio::Model::ZoneHVACBaseboardConvectiveWater.new(model,model.alwaysOnDiscreteSchedule(),baseboard_coil)
baseboard_heater.addToThermalZone(story_1_south_thermal_zone)
hotWaterPlant.addDemandBranchForComponent(baseboard_coil)
        
#add water to air heat pump to next available zone        
fanPowerFtSpeedCurve = OpenStudio::Model::CurveExponent.new(model)
fanPowerFtSpeedCurve.setCoefficient1Constant(0.0)
fanPowerFtSpeedCurve.setCoefficient2Constant(1.0)
fanPowerFtSpeedCurve.setCoefficient3Constant(3.0)
fanPowerFtSpeedCurve.setMinimumValueofx(0.0)
fanPowerFtSpeedCurve.setMaximumValueofx(1.5)
fanPowerFtSpeedCurve.setMinimumCurveOutput(0.01)
fanPowerFtSpeedCurve.setMaximumCurveOutput(1.5)  

fanEfficiencyFtSpeedCurve = OpenStudio::Model::CurveCubic.new(model)
fanEfficiencyFtSpeedCurve.setCoefficient1Constant(0.33856828)
fanEfficiencyFtSpeedCurve.setCoefficient2x(1.72644131)
fanEfficiencyFtSpeedCurve.setCoefficient3xPOW2(-1.49280132)
fanEfficiencyFtSpeedCurve.setCoefficient4xPOW3(0.42776208)
fanEfficiencyFtSpeedCurve.setMinimumValueofx(0.5)
fanEfficiencyFtSpeedCurve.setMaximumValueofx(1.5)
fanEfficiencyFtSpeedCurve.setMinimumCurveOutput(0.3)
fanEfficiencyFtSpeedCurve.setMaximumCurveOutput(1.0)
 
supplyFan = OpenStudio::Model::FanOnOff.new(model,model.alwaysOnDiscreteSchedule(),fanPowerFtSpeedCurve,fanEfficiencyFtSpeedCurve)
wahpDXHC = OpenStudio::Model::CoilHeatingWaterToAirHeatPumpEquationFit.new(model)
wahpDXCC = OpenStudio::Model::CoilCoolingWaterToAirHeatPumpEquationFit.new(model)
supplementalHC = OpenStudio::Model::CoilHeatingElectric.new(model,model.alwaysOnDiscreteSchedule())  
wtahp = OpenStudio::Model::ZoneHVACWaterToAirHeatPump.new(model,model.alwaysOnDiscreteSchedule(),supplyFan,wahpDXHC,wahpDXCC,supplementalHC)
wtahp.addToThermalZone(story_1_east_thermal_zone);

condenserWaterPlant.addDemandBranchForComponent(wahpDXHC)
condenserWaterPlant.addDemandBranchForComponent(wahpDXCC)

#save the OpenStudio model (.osm)
model.save_openstudio_osm({"osm_save_directory" => Dir.pwd,
                           "osm_name" => "out.osm"})