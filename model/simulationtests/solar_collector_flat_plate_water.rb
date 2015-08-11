
require 'openstudio'
require 'lib/baseline_model'
require 'JSON'

model = BaselineModel.new
  
	model.add_standards( JSON.parse('{
  "schedules": [
    {
        "name": "Medium Office Bldg Swh",
        "category": "Service Water Heating",
        "units": null,
        "day_types": "Default|SmrDsn",
        "start_date": "2014-01-01T00:00:00+00:00",
        "end_date": "2014-12-31T00:00:00+00:00",
        "type": "Hourly",
        "notes": "From DOE Reference Buildings ",
        "values": [
          0.05, 0.05, 0.05, 0.05, 0.05, 0.08, 0.07, 0.19, 0.35, 0.38, 0.39, 0.47, 0.57, 0.54, 0.34, 0.33, 0.44, 0.26, 0.21, 0.15, 0.17, 0.08, 0.05, 0.05
        ]
      },
      {
        "name": "Medium Office Bldg Swh",
        "category": "Service Water Heating",
        "units": null,
        "day_types": "Sun",
        "start_date": "2014-01-01T00:00:00+00:00",
        "end_date": "2014-12-31T00:00:00+00:00",
        "type": "Hourly",
        "notes": "From DOE Reference Buildings ",
        "values": [
          0.04, 0.04, 0.04, 0.04, 0.04, 0.07, 0.04, 0.04, 0.04, 0.04, 0.04, 0.06, 0.06, 0.09, 0.06, 0.04, 0.04, 0.04, 0.04, 0.04, 0.04, 0.07, 0.04, 0.04
        ]
      },
      {
        "name": "Medium Office Bldg Swh",
        "category": "Service Water Heating",
        "units": null,
        "day_types": "WntrDsn|Sat",
        "start_date": "2014-01-01T00:00:00+00:00",
        "end_date": "2014-12-31T00:00:00+00:00",
        "type": "Hourly",
        "notes": "From DOE Reference Buildings ",
        "values": [
          0.05, 0.05, 0.05, 0.05, 0.05, 0.08, 0.07, 0.11, 0.15, 0.21, 0.19, 0.23, 0.2, 0.19, 0.15, 0.13, 0.14, 0.07, 0.07, 0.07, 0.07, 0.09, 0.05, 0.05
        ]
      }
    ]
  }') )

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
        
#add ASHRAE System type 01, PTAC, Residential
model.add_hvac({"ashrae_sys_num" => '01'})

#add thermostats
model.add_thermostats({"heating_setpoint" => 24,
                      "cooling_setpoint" => 28})
              
#assign constructions from a local library to the walls/windows/etc. in the model
model.set_constructions()

#set whole building space type; simplified 90.1-2004 Large Office Whole Building
model.set_space_type()  

#add design days to the model (Chicago)
model.add_design_days()

mixed_swh_loop = model.add_swh_loop("Mixed")
supply_components = mixed_swh_loop.supplyComponents("OS:WaterHeater:Mixed".to_IddObjectType)
swh_water_heater = supply_components.first.to_WaterHeaterMixed.get

zones = model.getThermalZones
zones.each do |thermal_zone|
  model.add_swh_end_uses(mixed_swh_loop, "Medium Office Bldg Swh")
end
      
# Auxillary water heating loop
aux_water_loop = OpenStudio::Model::PlantLoop.new(self)
aux_water_loop.setName("Auxillary Water Loop")
aux_water_loop.setMaximumLoopTemperature(60)
aux_water_loop.setMinimumLoopTemperature(10)

# Temperature schedule type limits
temp_sch_type_limits = OpenStudio::Model::ScheduleTypeLimits.new(self)
temp_sch_type_limits.setName('Temperature Schedule Type Limits')
temp_sch_type_limits.setLowerLimitValue(0.0)
temp_sch_type_limits.setUpperLimitValue(100.0)
temp_sch_type_limits.setNumericType('Continuous')
temp_sch_type_limits.setUnitType('Temperature')

# Auxillary water heating loop controls
aux_temp_f = 140
aux_delta_t_r = 9 #9F delta-T    
aux_temp_c = OpenStudio.convert(aux_temp_f,'F','C').get
aux_delta_t_k = OpenStudio.convert(aux_delta_t_r,'R','K').get
aux_temp_sch = OpenStudio::Model::ScheduleRuleset.new(self)
aux_temp_sch.setName("Hot Water Loop Temp - #{aux_temp_f}F")
aux_temp_sch.defaultDaySchedule().setName("Hot Water Loop Temp - #{aux_temp_f}F Default")
aux_temp_sch.defaultDaySchedule().addValue(OpenStudio::Time.new(0,24,0,0),aux_temp_c)
aux_temp_sch.setScheduleTypeLimits(temp_sch_type_limits)
aux_stpt_manager = OpenStudio::Model::SetpointManagerScheduled.new(self,aux_temp_sch)    
aux_stpt_manager.addToNode(aux_water_loop.supplyOutletNode)
sizing_plant = service_water_loop.sizingPlant
sizing_plant.setLoopType('Heating')
sizing_plant.setDesignLoopExitTemperature(swh_temp_c)
sizing_plant.setLoopDesignTemperatureDifference(swh_delta_t_k)         

# Auxiliary water heating pump
aux_pump_head_press_pa = 0.001
aux_pump_motor_efficiency = 1

aux_pump = OpenStudio::Model::PumpConstantSpeed.new(self)
aux_pump.setName('Auxillary Water Loop Pump')
aux_pump.setRatedPumpHead(aux_pump_head_press_pa.to_f)
aux_pump.setMotorEfficiency(aux_pump_motor_efficiency)
aux_pump.setPumpControlType('Intermittent')
aux_pump.addToNode(aux_water_loop.supplyInletNode)

aux_water_heater = OpenStudio::Model::WaterHeaterMixed.new(self)
aux_water_heater.setName("Auxiliary Hot Water Tank")
aux_water_heater.setSetpointTemperatureSchedule(swh_temp_sch)
aux_water_heater.setHeaterMaximumCapacity(0.0)
#aux_water_heater.setDeadbandTemperatureDifference(OpenStudio.convert(3.6,'R','K').get)
#aux_water_heater.setHeaterControlType('Cycle')
#aux_water_heater.setTankVolume(OpenStudio.convert(water_heater_vol_gal,'gal','m^3').get)
aux_water_loop.addSupplyBranchForComponent(aux_water_heater)

# Service water heating loop bypass pipes
water_heater_bypass_pipe = OpenStudio::Model::PipeAdiabatic.new(self)
aux_water_loop.addSupplyBranchForComponent(water_heater_bypass_pipe)
coil_bypass_pipe = OpenStudio::Model::PipeAdiabatic.new(self)
aux_water_loop.addDemandBranchForComponent(coil_bypass_pipe)
supply_outlet_pipe = OpenStudio::Model::PipeAdiabatic.new(self)
supply_outlet_pipe.addToNode(aux_water_loop.supplyOutletNode)    
demand_inlet_pipe = OpenStudio::Model::PipeAdiabatic.new(self)
demand_inlet_pipe.addToNode(aux_water_loop.demandInletNode) 
demand_outlet_pipe = OpenStudio::Model::PipeAdiabatic.new(self)
demand_outlet_pipe.addToNode(aux_water_loop.demandOutletNode)   
      
# make a solar collector and add it to the loops
vertices = OpenStudio::Point3dVector.new
vertices << OpenStudio::Point3d.new(0,0,0)
vertices << OpenStudio::Point3d.new(10,0,0)
vertices << OpenStudio::Point3d.new(10,4,0)
vertices << OpenStudio::Point3d.new(0,4,0)
rotation = OpenStudio::createRotation(OpenStudio::Vector3d.new(1,0,0), OpenStudio::degToRad(30))
vertices = rotation*vertices

group = OpenStudio::Model::ShadingSurfaceGroup.new(model)
group.setXOrigin(20)
group.setYOrigin(10)
group.setZOrigin(8)

shade = OpenStudio::Model::ShadingSurface.new(vertices, model)
shade.setShadingSurfaceGroup(group)

collector = OpenStudio::Model::SolarCollectorFlatPlateWater.new(model)
collector.addToNode(aux_water_heater.supplyInletModelObject.get.to_Node.get)
collector.addToNode(swh_water_heater.demandInletModelObject.get.to_Node.get) 
collector.setSurface(shade)

collector.outputVariableNames.each do |var|
  OpenStudio::Model::OutputVariable.new(var, model)
end
      
#save the OpenStudio model (.osm)
model.save_openstudio_osm({"osm_save_directory" => Dir.pwd, "osm_name" => "out.osm"})
