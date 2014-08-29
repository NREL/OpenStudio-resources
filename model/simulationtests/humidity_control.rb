
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
        
#add ASHRAE System type 03, PSZ-AC
model.add_hvac({"ashrae_sys_num" => '03'})

#add thermostats
model.add_thermostats({"heating_setpoint" => 24,
                      "cooling_setpoint" => 28})

#pick out on of the zone/system pairs and add a humidifier
zones = model.getThermalZones
zone = zones[0]

dehumidify_sch = OpenStudio::Model::ScheduleConstant.new(model)
dehumidify_sch.setValue(50)
humidistat = OpenStudio::Model::ZoneControlHumidistat.new(model)
humidistat.setHumidifyingRelativeHumiditySetpointSchedule(dehumidify_sch)
zone.setZoneControlHumidistat(humidistat)

air_system = zone.airLoopHVAC.get
fan = air_system.supplyComponents(OpenStudio::Model::FanConstantVolume::iddObjectType()).first.to_FanConstantVolume.get
node = fan.inletModelObject.get.to_Node.get
humidifier = OpenStudio::Model::HumidifierSteamElectric.new(model)
humidifier.addToNode(node)
node = humidifier.outletModelObject.get.to_Node.get
spm = OpenStudio::Model::SetpointManagerSingleZoneHumidityMinimum.new(model)
spm.addToNode(node)
#spm = OpenStudio::Model::SetpointManagerMultiZoneHumidityMinimum.new(model)
#spm.addToNode(node)
#spm = OpenStudio::Model::SetpointManagerMultiZoneMinimumHumidityAverage.new(model)
#spm.addToNode(node)
              
#assign constructions from a local library to the walls/windows/etc. in the model
model.set_constructions()

#set whole building space type; simplified 90.1-2004 Large Office Whole Building
model.set_space_type()  

#add design days to the model (Chicago)
model.add_design_days()
       
#save the OpenStudio model (.osm)
model.save_openstudio_osm({"osm_save_directory" => Dir.pwd,
                           "osm_name" => "out.osm"})
                           
