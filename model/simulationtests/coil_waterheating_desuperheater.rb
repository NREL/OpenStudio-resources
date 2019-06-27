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

#create schedule object
schedule_constant = OpenStudio::Model::ScheduleConstant.new(model)

# (1) test gshp

#create desuperheater object
coil_water_heating_desuperheater = OpenStudio::Model::CoilWaterHeatingDesuperheater.new(model, schedule_constant)

#create stratified water heater
water_heater_stratified = OpenStudio::Model::WaterHeaterStratified.new(model)
coil_water_heating_desuperheater.addToHeatRejectionTarget(water_heater_stratified)

#create loops
plant_loop = OpenStudio::Model::PlantLoop.new(model)
air_loop_unitary = OpenStudio::Model::AirLoopHVACUnitarySystem.new(model)
air_loop = OpenStudio::Model::AirLoopHVAC.new(model)
air_supply_inlet_node = air_loop.supplyInletNode
air_loop_unitary.addToNode(air_supply_inlet_node)

#create equation fit water to air cooling coil
coil_cooling_water_to_air_heat_pump_equation_fit = OpenStudio::Model::CoilCoolingWaterToAirHeatPumpEquationFit.new(model)
plant_loop.addDemandBranchForComponent(coil_cooling_water_to_air_heat_pump_equation_fit)
air_loop_unitary.setCoolingCoil(coil_cooling_water_to_air_heat_pump_equation_fit)
coil_water_heating_desuperheater.setHeatingSource(coil_cooling_water_to_air_heat_pump_equation_fit)

# (2) test multispeed ac

#create desuperheater object
coil_water_heating_desuperheater = OpenStudio::Model::CoilWaterHeatingDesuperheater.new(model, schedule_constant)

#create mixed water heater
water_heater_mixed = OpenStudio::Model::WaterHeaterMixed.new(model)
coil_water_heating_desuperheater.addToHeatRejectionTarget(water_heater_mixed)

#create loops
air_loop_unitary = OpenStudio::Model::AirLoopHVACUnitarySystem.new(model)
air_loop = OpenStudio::Model::AirLoopHVAC.new(model)
air_supply_inlet_node = air_loop.supplyInletNode
air_loop_unitary.addToNode(air_supply_inlet_node)

#create multispeed dx cooling coil
coil_cooling_dx_multispeed = OpenStudio::Model::CoilCoolingDXMultiSpeed.new(model)
cool_stage_1 = OpenStudio::Model::CoilCoolingDXMultiSpeedStageData.new(model)
cool_stage_2 = OpenStudio::Model::CoilCoolingDXMultiSpeedStageData.new(model)
coil_cooling_dx_multispeed.addStage(cool_stage_1)
coil_cooling_dx_multispeed.addStage(cool_stage_2)
air_loop_unitary.setCoolingCoil(coil_cooling_dx_multispeed)
coil_water_heating_desuperheater.setHeatingSource(coil_cooling_dx_multispeed)

# save the OpenStudio model (.osm)
model.save_openstudio_osm({"osm_save_directory" => Dir.pwd, "osm_name" => "in.osm"})
