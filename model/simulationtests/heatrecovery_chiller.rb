# frozen_string_literal: true

require 'openstudio'
require_relative 'lib/baseline_model'

model = BaselineModel.new

# make a 2 story, 100m X 50m, 10 zone core/perimeter building
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

# add ASHRAE System type 03, PSZ-AC
model.add_hvac({ 'ashrae_sys_num' => '03' })

# In order to produce more consistent results between different runs,
# we sort the zones by names
zones = model.getThermalZones.sort_by { |z| z.name.to_s }

# Water Heater Mixed
water_heater_mixed = OpenStudio::Model::WaterHeaterMixed.new(model)
water_heater_mixed.setName("Water Heater")

# Plant Loop 1
plant_loop_1 = OpenStudio::Model::PlantLoop.new(model)
plant_loop_1.setName("First Plant Loop")

# water_heater_mixed.addToNode(plant_loop_1.supplyInletNode)
plant_loop_1.addSupplyBranchForComponent(water_heater_mixed)

pump_1 = OpenStudio::Model::PumpConstantSpeed.new(model)
pump_1.setName("First Pump")
pump_1.addToNode(plant_loop_1.supplyInletNode)

boiler_1 = OpenStudio::Model::BoilerHotWater.new(model)
boiler_1.setName("First Boiler")
plant_loop_1.addSupplyBranchForComponent(boiler_1)

pipe_1 = OpenStudio::Model::PipeAdiabatic.new(model)
pipe_1.setName("First Pipe")
plant_loop_1.addSupplyBranchForComponent(pipe_1)

sch_1 = OpenStudio::Model::ScheduleRuleset.new(model)
sch_1.setName("Hot_Water_Temperature")
sch_1.defaultDaySchedule.addValue(OpenStudio::Time.new(0, 24, 0, 0), 55.0)

hot_water_spm_1 = OpenStudio::Model::SetpointManagerScheduled.new(model, sch_1)
hot_water_spm_1.addToNode(plant_loop_1.supplyOutletNode)

# Plant Loop 2
plant_loop_2 = OpenStudio::Model::PlantLoop.new(model)
plant_loop_2.setName("Second Plant Loop")

# pipe = OpenStudio::Model::PipeAdiabatic.new(model)
# plant_loop_2.addSupplyBranchForComponent(pipe)
# water_heater_mixed.addToSourceSideNode(pipe.inletModelObject.get.to_Node.get)
# pipe.remove
water_heater_mixed.addToSourceSideNode(plant_loop_2.supplyInletNode)

pump_2 = OpenStudio::Model::PumpConstantSpeed.new(model)
pump_2.setName("Second Pump")
pump_2.addToNode(plant_loop_2.supplyInletNode)

hot_water_spm_2 = OpenStudio::Model::SetpointManagerScheduled.new(model, sch_1)
hot_water_spm_2.addToNode(plant_loop_2.supplyOutletNode)

# add thermostats
model.add_thermostats({ 'heating_setpoint' => 24,
                        'cooling_setpoint' => 28 })

# assign constructions from a local library to the walls/windows/etc. in the model
model.set_constructions

# set whole building space type; simplified 90.1-2004 Large Office Whole Building
model.set_space_type

# add design days to the model (Chicago)
model.add_design_days

# save the OpenStudio model (.osm)
model.save_openstudio_osm({ 'osm_save_directory' => Dir.pwd,
                            'osm_name' => 'in.osm' })
