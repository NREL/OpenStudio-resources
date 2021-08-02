# frozen_string_literal: true

require 'openstudio'
require 'lib/baseline_model'

model = BaselineModel.new

# make a 1 story, 100m X 50m, 1 zone building
model.add_geometry({ 'length' => 100,
                     'width' => 50,
                     'num_floors' => 1,
                     'floor_to_floor_height' => 4,
                     'plenum_height' => 0,
                     'perimeter_zone_depth' => 0 })

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

# In order to produce more consistent results between different runs,
# we sort the zones by names (only one here anyways...)
zones = model.getThermalZones.sort_by { |z| z.name.to_s }
zone = zones[0]

# PlantLoopHeatPump_EIR_WaterSource.idf

############### HEATING / COOLING (LOAD) LOOPS  ###############

hw_loop = OpenStudio::Model::PlantLoop.new(model)
hw_loop.setName('Hot Water Loop')
hw_loop.setMinimumLoopTemperature(10)
hw_temp_f = 140
hw_delta_t_r = 20 # 20F delta-T
hw_temp_c = OpenStudio.convert(hw_temp_f, 'F', 'C').get
hw_delta_t_k = OpenStudio.convert(hw_delta_t_r, 'R', 'K').get
hw_temp_sch = OpenStudio::Model::ScheduleRuleset.new(model)
hw_temp_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0, 24, 0, 0), hw_temp_c)
hw_stpt_manager = OpenStudio::Model::SetpointManagerScheduled.new(model, hw_temp_sch)
hw_stpt_manager.addToNode(hw_loop.supplyOutletNode)
sizing_plant = hw_loop.sizingPlant
sizing_plant.setLoopType('Heating')
sizing_plant.setDesignLoopExitTemperature(hw_temp_c)
sizing_plant.setLoopDesignTemperatureDifference(hw_delta_t_k)
# Pump
hw_pump = OpenStudio::Model::PumpVariableSpeed.new(model)
hw_pump_head_ft_h2o = 60.0
hw_pump_head_press_pa = OpenStudio.convert(hw_pump_head_ft_h2o, 'ftH_{2}O', 'Pa').get
hw_pump.setRatedPumpHead(hw_pump_head_press_pa)
hw_pump.setPumpControlType('Intermittent')
hw_pump.addToNode(hw_loop.supplyInletNode)

chw_loop = OpenStudio::Model::PlantLoop.new(model)
chw_loop.setName('Chilled Water Loop')
chw_loop.setMaximumLoopTemperature(98)
chw_loop.setMinimumLoopTemperature(1)
chw_temp_f = 44
chw_delta_t_r = 10.1 # 10.1F delta-T
chw_temp_c = OpenStudio.convert(chw_temp_f, 'F', 'C').get
chw_delta_t_k = OpenStudio.convert(chw_delta_t_r, 'R', 'K').get
chw_temp_sch = OpenStudio::Model::ScheduleRuleset.new(model)
chw_temp_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0, 24, 0, 0), chw_temp_c)
chw_stpt_manager = OpenStudio::Model::SetpointManagerScheduled.new(model, chw_temp_sch)
chw_stpt_manager.addToNode(chw_loop.supplyOutletNode)
sizing_plant = chw_loop.sizingPlant
sizing_plant.setLoopType('Cooling')
sizing_plant.setDesignLoopExitTemperature(chw_temp_c)
sizing_plant.setLoopDesignTemperatureDifference(chw_delta_t_k)
# Pump
pri_chw_pump = OpenStudio::Model::HeaderedPumpsConstantSpeed.new(model)
pri_chw_pump.setName('Chilled Water Loop Primary Pump')
pri_chw_pump_head_ft_h2o = 15
pri_chw_pump_head_press_pa = OpenStudio.convert(pri_chw_pump_head_ft_h2o, 'ftH_{2}O', 'Pa').get
pri_chw_pump.setRatedPumpHead(pri_chw_pump_head_press_pa)
pri_chw_pump.setMotorEfficiency(0.9)
pri_chw_pump.setPumpControlType('Intermittent')
pri_chw_pump.addToNode(chw_loop.supplyInletNode)

###############################################################

############   C O N D E N S E R    S I D E  ##################

cw_loop = OpenStudio::Model::PlantLoop.new(model)
cw_loop.setName('Condenser Water Loop')
cw_loop.setMaximumLoopTemperature(80)
cw_loop.setMinimumLoopTemperature(5)
cw_temp_f = 70 # CW setpoint 70F
cw_temp_sizing_f = 102 # CW sized to deliver 102F
cw_delta_t_r = 10 # 10F delta-T
cw_approach_delta_t_r = 7 # 7F approach
cw_temp_c = OpenStudio.convert(cw_temp_f, 'F', 'C').get
cw_temp_sizing_c = OpenStudio.convert(cw_temp_sizing_f, 'F', 'C').get
cw_delta_t_k = OpenStudio.convert(cw_delta_t_r, 'R', 'K').get
cw_approach_delta_t_k = OpenStudio.convert(cw_approach_delta_t_r, 'R', 'K').get
float_down_to_f = 70
float_down_to_c = OpenStudio.convert(float_down_to_f, 'F', 'C').get
cw_t_stpt_manager = OpenStudio::Model::SetpointManagerFollowOutdoorAirTemperature.new(model)
cw_t_stpt_manager.setReferenceTemperatureType('OutdoorAirWetBulb')
cw_t_stpt_manager.setMaximumSetpointTemperature(cw_temp_sizing_c)
cw_t_stpt_manager.setMinimumSetpointTemperature(float_down_to_c)
cw_t_stpt_manager.setOffsetTemperatureDifference(cw_approach_delta_t_k)
cw_t_stpt_manager.addToNode(cw_loop.supplyOutletNode)
sizing_plant = cw_loop.sizingPlant
sizing_plant.setLoopType('Condenser')
sizing_plant.setDesignLoopExitTemperature(cw_temp_sizing_c)
sizing_plant.setLoopDesignTemperatureDifference(cw_delta_t_k)

cw_pump = OpenStudio::Model::PumpConstantSpeed.new(model)
cw_pump.setName('Condenser Water Loop Pump')
cw_pump_head_ft_h2o = 60.0
cw_pump_head_press_pa = OpenStudio.convert(cw_pump_head_ft_h2o, 'ftH_{2}O', 'Pa').get
cw_pump.setRatedPumpHead(cw_pump_head_press_pa)
cw_pump.addToNode(cw_loop.supplyInletNode)

cw_loop.addSupplyBranchForComponent(OpenStudio::Model::CoolingTowerSingleSpeed.new(model))

###############################################################

plhp_htg = OpenStudio::Model::HeatPumpPlantLoopEIRHeating.new(model)
plhp_clg = OpenStudio::Model::HeatPumpPlantLoopEIRCooling.new(model)

plhp_htg.setName('Heating Coil')
plhp_htg.setCompanionCoolingHeatPump(plhp_clg)
plhp_htg.setCondenserType('WaterSource')
plhp_htg.setReferenceLoadSideFlowRate(0.005)
plhp_htg.setReferenceSourceSideFlowRate(0.002)
plhp_htg.setReferenceCapacity(80000)
plhp_htg.setReferenceCoefficientofPerformance(3.5)
plhp_htg.setSizingFactor(1)
plhp_htg.capacityModifierFunctionofTemperatureCurve.setName('CapCurveFuncTemp')
plhp_htg.electricInputtoOutputRatioModifierFunctionofTemperatureCurve.setName('EIRCurveFuncTemp')
plhp_htg.electricInputtoOutputRatioModifierFunctionofPartLoadRatioCurve.setName('EIRCurveFuncPLR')

plhp_clg.setName('Cooling Coil')
plhp_clg.setCompanionHeatingHeatPump(plhp_htg)
plhp_clg.setCondenserType('WaterSource')
plhp_clg.setReferenceLoadSideFlowRate(0.005)
plhp_clg.setReferenceSourceSideFlowRate(0.003)
plhp_clg.setReferenceCapacity(400000)
plhp_clg.setReferenceCoefficientofPerformance(3.5)
plhp_clg.setSizingFactor(1)
plhp_clg.capacityModifierFunctionofTemperatureCurve.setName('CapCurveFuncTemp2')
plhp_clg.electricInputtoOutputRatioModifierFunctionofTemperatureCurve.setName('EIRCurveFuncTemp2')
plhp_clg.electricInputtoOutputRatioModifierFunctionofPartLoadRatioCurve.setName('EIRCurveFuncPLR2')

hw_loop.addSupplyBranchForComponent(plhp_htg)
cw_loop.addDemandBranchForComponent(plhp_htg)

chw_loop.addSupplyBranchForComponent(plhp_clg)
cw_loop.addDemandBranchForComponent(plhp_clg)

# save the OpenStudio model (.osm)
model.save_openstudio_osm({ 'osm_save_directory' => Dir.pwd,
                            'osm_name' => 'in.osm' })
