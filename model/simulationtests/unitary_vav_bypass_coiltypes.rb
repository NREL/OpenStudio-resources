# frozen_string_literal: true

require 'openstudio'
require 'lib/baseline_model'

model = BaselineModel.new

# make a 1 story, 100m X 50m, 5 zone core/perimeter building
model.add_geometry({ 'length' => 100,
                     'width' => 50,
                     'num_floors' => 1,
                     'floor_to_floor_height' => 4,
                     'plenum_height' => 0,
                     'perimeter_zone_depth' => 3 })

# add windows at a 40% window-to-wall ratio
model.add_windows({ 'wwr' => 0.4,
                    'offset' => 1,
                    'application_type' => 'Above Floor' })

# add thermostats
model.add_thermostats({ 'heating_setpoint' => 24,
                        'cooling_setpoint' => 28 })

# assign constructions from a local library to the walls/windows/etc. in the model
model.set_constructions

# set whole building space type; simplified 90.1-2004 Large Office Whole Building
model.set_space_type

# add design days to the model (Chicago)
model.add_design_days

schedule = model.alwaysOnDiscreteSchedule

# In order to produce more consistent results between different runs,
# we sort the zones by names
zones = model.getThermalZones.sort_by { |z| z.name.to_s }

# CoilHeatingDXSingleSpeed, CoilCoolingDXSingleSpeed
airLoop_1 = OpenStudio::Model::AirLoopHVAC.new(model)
airLoop_1_supplyNode = airLoop_1.supplyOutletNode

fan_1 = OpenStudio::Model::FanConstantVolume.new(model, schedule)
cooling_coil_1 = OpenStudio::Model::CoilCoolingDXSingleSpeed.new(model)
heating_coil_1 = OpenStudio::Model::CoilHeatingDXSingleSpeed.new(model)
unitary_1 = OpenStudio::Model::AirLoopHVACUnitaryHeatCoolVAVChangeoverBypass.new(model, fan_1, cooling_coil_1, heating_coil_1)

unitary_1.addToNode(airLoop_1_supplyNode)
terminal_1 = OpenStudio::Model::AirTerminalSingleDuctVAVHeatAndCoolNoReheat.new(model)
airLoop_1.addBranchForZone(zones[0], terminal_1)

# CoilHeatingDXVariableSpeed, CoilCoolingDXVariableSpeed
airLoop_2 = OpenStudio::Model::AirLoopHVAC.new(model)
airLoop_2_supplyNode = airLoop_2.supplyOutletNode

fan_2 = OpenStudio::Model::FanConstantVolume.new(model, schedule)
cooling_coil_2 = OpenStudio::Model::CoilCoolingDXVariableSpeed.new(model)
cooling_coil_speed_2 = OpenStudio::Model::CoilCoolingDXVariableSpeedSpeedData.new(model)
cooling_coil_2.addSpeed(cooling_coil_speed_2)
heating_coil_2 = OpenStudio::Model::CoilHeatingDXVariableSpeed.new(model)
heating_coil_speed_2 = OpenStudio::Model::CoilHeatingDXVariableSpeedSpeedData.new(model)
heating_coil_2.addSpeed(heating_coil_speed_2)
unitary_2 = OpenStudio::Model::AirLoopHVACUnitaryHeatCoolVAVChangeoverBypass.new(model, fan_2, cooling_coil_2, heating_coil_2)

unitary_2.addToNode(airLoop_2_supplyNode)
terminal_2 = OpenStudio::Model::AirTerminalSingleDuctVAVHeatAndCoolNoReheat.new(model)
airLoop_2.addBranchForZone(zones[1], terminal_2)

# CoilHeatingGas, CoilSystemCoolingDXHeatExchangerAssisted
airLoop_3 = OpenStudio::Model::AirLoopHVAC.new(model)
airLoop_3_supplyNode = airLoop_3.supplyOutletNode

fan_3 = OpenStudio::Model::FanConstantVolume.new(model, schedule)
cooling_coil_3 = OpenStudio::Model::CoilSystemCoolingDXHeatExchangerAssisted.new(model)
heating_coil_3 = OpenStudio::Model::CoilHeatingGas.new(model)
unitary_3 = OpenStudio::Model::AirLoopHVACUnitaryHeatCoolVAVChangeoverBypass.new(model, fan_3, cooling_coil_3, heating_coil_3)

unitary_3.addToNode(airLoop_3_supplyNode)
terminal_3 = OpenStudio::Model::AirTerminalSingleDuctVAVHeatAndCoolNoReheat.new(model)
airLoop_3.addBranchForZone(zones[2], terminal_3)

# CoilHeatingElectric, CoilCoolingDXTwoStageWithHumidityControlMode
airLoop_4 = OpenStudio::Model::AirLoopHVAC.new(model)
airLoop_4_supplyNode = airLoop_4.supplyOutletNode

fan_4 = OpenStudio::Model::FanConstantVolume.new(model, schedule)
cooling_coil_4 = OpenStudio::Model::CoilCoolingDXTwoStageWithHumidityControlMode.new(model)
heating_coil_4 = OpenStudio::Model::CoilHeatingElectric.new(model)
unitary_4 = OpenStudio::Model::AirLoopHVACUnitaryHeatCoolVAVChangeoverBypass.new(model, fan_4, cooling_coil_4, heating_coil_4)

unitary_4.addToNode(airLoop_4_supplyNode)
terminal_4 = OpenStudio::Model::AirTerminalSingleDuctVAVHeatAndCoolNoReheat.new(model)
airLoop_4.addBranchForZone(zones[3], terminal_4)

# CoilHeatingWater, CoilCoolingDXSingleSpeed
hw_loop = OpenStudio::Model::PlantLoop.new(model)
hw_temp_f = 140
hw_delta_t_r = 20 # 20F delta-T
hw_temp_c = OpenStudio.convert(hw_temp_f, 'F', 'C').get
hw_delta_t_k = OpenStudio.convert(hw_delta_t_r, 'R', 'K').get
hw_temp_sch = OpenStudio::Model::ScheduleRuleset.new(model)
hw_temp_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0, 24, 0, 0), hw_temp_c)
hw_stpt_manager = OpenStudio::Model::SetpointManagerScheduled.new(model, hw_temp_sch)
hw_stpt_manager.addToNode(hw_loop.supplyOutletNode)

hotWaterOutletNode = hw_loop.supplyOutletNode
hotWaterInletNode = hw_loop.supplyInletNode

pump = OpenStudio::Model::PumpVariableSpeed.new(model)
pump.addToNode(hotWaterInletNode)

boiler = OpenStudio::Model::BoilerHotWater.new(model)
node = hw_loop.supplySplitter.lastOutletModelObject.get.to_Node.get
boiler.addToNode(node)

pipe = OpenStudio::Model::PipeAdiabatic.new(model)
hw_loop.addSupplyBranchForComponent(pipe)

pipe2 = OpenStudio::Model::PipeAdiabatic.new(model)
pipe2.addToNode(hotWaterOutletNode)

airLoop_5 = OpenStudio::Model::AirLoopHVAC.new(model)
airLoop_5_supplyNode = airLoop_5.supplyOutletNode

fan_5 = OpenStudio::Model::FanConstantVolume.new(model, schedule)
cooling_coil_5 = OpenStudio::Model::CoilCoolingDXSingleSpeed.new(model)
heating_coil_5 = OpenStudio::Model::CoilHeatingWater.new(model)
unitary_5 = OpenStudio::Model::AirLoopHVACUnitaryHeatCoolVAVChangeoverBypass.new(model, fan_5, cooling_coil_5, heating_coil_5)

unitary_5.addToNode(airLoop_5_supplyNode)
terminal_5 = OpenStudio::Model::AirTerminalSingleDuctVAVHeatAndCoolNoReheat.new(model)
airLoop_5.addBranchForZone(zones[4], terminal_5)

hw_loop.addDemandBranchForComponent(heating_coil_5)

# save the OpenStudio model (.osm)
model.save_openstudio_osm({ 'osm_save_directory' => Dir.pwd,
                            'osm_name' => 'in.osm' })
