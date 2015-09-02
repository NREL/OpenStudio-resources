
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
        
#add ASHRAE System type 07, VAV w/ Reheat
model.add_hvac({"ashrae_sys_num" => '07'})


airloops = model.getAirLoopHVACs()
oa_airloops = model.getAirLoopHVACOutdoorAirSystems()
schedule = model.alwaysOnDiscreteSchedule()

# constant_temp_sch = OpenStudio::Model::ScheduleRuleset.new(model);
# constant_temp_sch.defaultDaySchedule().addValue( OpenStudio::Time.new(0, 24, 0), 50 );

if oa_airloops.length > 0 then
	oa_airloop = oa_airloops[0]
	coil = OpenStudio::Model::CoilHeatingElectric.new(model,schedule)
	coil.addToNode(oa_airloop.outboardOANode.get)
	spm = OpenStudio::Model::SetpointManagerOutdoorAirPretreat.new(model)
	oa_node = oa_airloop.outdoorAirModelObject.get.to_Node.get
	spm.addToNode(oa_node)
	mixed_node = oa_airloop.mixedAirModelObject.get.to_Node.get
	spm.setMixedAirStreamNode(mixed_node)
	spm.setReferenceSetpointNode(mixed_node)
	spm.setOutdoorAirStreamNode(oa_airloop.outdoorAirModelObject.get.to_Node.get)
	spm.setReturnAirStreamNode(oa_airloop.returnAirModelObject.get.to_Node.get)
end

if airloops.length > 0 then
	airloop = airloops[0]
	spm = OpenStudio::Model::SetpointManagerOutdoorAirPretreat.new(model)
	node = airloop.mixedAirNode.get
	spm.addToNode(node)

	heating_coils = airloop.supplyComponents(OpenStudio::Model::CoilHeatingWater.iddObjectType)
	heating_coil = heating_coils[0].to_CoilHeatingWater.get
	high_temperature_sch = OpenStudio::Model::ScheduleConstant.new(model)
	high_temperature_sch.setValue(40)
	low_temperature_sch = OpenStudio::Model::ScheduleConstant.new(model)
	low_temperature_sch.setValue(10)
	spm_2 = OpenStudio::Model::SetpointManagerScheduledDualSetpoint.new(model)
	spm_2.setHighSetpointSchedule(high_temperature_sch)
	spm_2.setLowSetpointSchedule(low_temperature_sch)
	spm_2.addToNode(heating_coil.airOutletModelObject.get.to_Node.get)

	# test adding Return Air Bypass to AirLoopHVAC
	# Not possible currently in OS, uncomment in future
	# airloop.setReturnAirBypassFlowTemperatureSetpointSchedule(constant_temp_sch)
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
                           