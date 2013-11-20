
require 'openstudio'
require 'lib/baseline_model'

model = BaselineModel.new

#make a 2 story, 100m X 50m, 10 zone core/perimeter building
model.add_geometry({"length" => 100,
              "width" => 50,
              "num_floors" => 2,
              "floor_to_floor_height" => 4,
              "plenum_height" => 1,
              "perimeter_zone_depth" => 3})

#add windows at a 40% window-to-wall ratio
model.add_windows({"wwr" => 0.4,
                  "offset" => 1,
                  "application_type" => "Above Floor"})

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

#add a water to air heat pump to each zone
zones = model.getThermalZones()
zones.each do |z|
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
wtahp.addToThermalZone(z);

condenserWaterPlant.addDemandBranchForComponent(wahpDXHC)
condenserWaterPlant.addDemandBranchForComponent(wahpDXCC)
end
    
#add thermostats
model.add_thermostats({"heating_setpoint" => 24,
                      "cooling_setpoint" => 28})
              
#assign constructions from a local library to the walls/windows/etc. in the model
model.set_constructions()

#set whole building space type; simplified 90.1-2004 Large Office Whole Building
model.set_space_type()  

#add design days to the model (Chicago)
model.add_design_days()
       
#save the OpenStudio model (.osm)
model.save_openstudio_osm({"osm_save_directory" => Dir.pwd,
                           "osm_name" => "out.osm"})
                           
