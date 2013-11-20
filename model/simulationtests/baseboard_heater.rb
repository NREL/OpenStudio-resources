
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

#add a baseboard heater to each zone
zones = model.getThermalZones()
hot_water_zones = zones[0..4]
hot_water_zones.each do |z|
  baseboard_coil = OpenStudio::Model::CoilHeatingWaterBaseboard.new(model)
  baseboard_heater = OpenStudio::Model::ZoneHVACBaseboardConvectiveWater.new(model,model.alwaysOnDiscreteSchedule(),baseboard_coil)
  baseboard_heater.addToThermalZone(z);

  hotWaterPlant.addDemandBranchForComponent(baseboard_coil)
end

electric_zones = zones[5..9]
electric_zones.each do |z|
  baseboard_heater = OpenStudio::Model::ZoneHVACBaseboardConvectiveElectric.new(model)
  baseboard_heater.addToThermalZone(z);
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
                           
