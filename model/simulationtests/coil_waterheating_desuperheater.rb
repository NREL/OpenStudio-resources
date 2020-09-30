# frozen_string_literal: true

require 'openstudio'
require 'lib/baseline_model'

# Creates a simple condenser loop with a CT SingleSpeed, a Pump:VariableSpeed
# and a SPM:FollowOutdoorAirTemperature on the supply side
#
# @param model [BaselineModel] The model in which to create it
# @return [OpenStudio::Model::PlantLoop] the resulting plantloop
def create_condenser_loop(model)
  # Create a Condenser Loop
  cw_loop = OpenStudio::Model::PlantLoop.new(model)
  cw_loop.setName('Condenser Water Loop')
  cw_loop.setMaximumLoopTemperature(80)
  cw_loop.setMinimumLoopTemperature(5)
  cw_temp_sizing_f = 102 # CW sized to deliver 102F
  cw_delta_t_r = 10 # 10F delta-T
  cw_approach_delta_t_r = 7 # 7F approach
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

  # One pump and a CT
  cw_pump = OpenStudio::Model::PumpVariableSpeed.new(model)
  cw_pump.addToNode(cw_loop.supplyInletNode)

  ct = OpenStudio::Model::CoolingTowerSingleSpeed.new(model)
  cw_loop.addSupplyBranchForComponent(ct)

  return cw_loop
end

# Gets the PSZ-AC for a Zone, and replace the Cooling coil with a
# AirLoopHVACUnitarySystem that is an empty shell, and which is
# returned by the method. The Control Zone of the unitary is set to the one
# passed as argument.
#
# @param zone [OpenStudio::Model::ThermalZone] The control zone
# @return [OpenStudio::Model::AirLoopHVACUnitarySystem] the unitary
def create_unitary_on_airloophvac(model, zone)
  airloop = zone.airLoopHVAC.get
  airloop.setName("AirLoopHVAC for #{zone.name}")

  unitary = OpenStudio::Model::AirLoopHVACUnitarySystem.new(model)
  unitary.setControllingZoneorThermostatLocation(zone)

  # Replace the default Cooling Coil with the Unitary, then remove the default one
  coil = airloop.supplyComponents(OpenStudio::Model::CoilCoolingDXSingleSpeed.iddObjectType).first.to_CoilCoolingDXSingleSpeed.get
  unitary.addToNode(coil.outletModelObject.get.to_Node.get)
  coil.remove

  return unitary
end

# Tests a desuperheater with:
# * Heat Rejection Target: WaterHeaterStratified
# * Heating source: CoilCoolingWaterToAirHeatPumpEquationFit. Creates a
# CondenserLoop to place that coil on the demand side too
#
# @param model [BaselineModel] The model in which to create it
# @param zone [OpenStudio::Model::ThermalZone] the zone in question (has a
# PSZ-AC that we'll mess with to add an AirLoopHVACUnitary with the
# CoilCoolingWaterToAirHeatPumpEquationFit)
# @return [OpenStudio::Model::CoilWaterHeatingDesuperheater]
def create_gshp_test(model, zone)
  # create desuperheater object
  setpoint_temp_sch = OpenStudio::Model::ScheduleRuleset.new(model, 60)
  coil_water_heating_desuperheater_gshp = OpenStudio::Model::CoilWaterHeatingDesuperheater.new(model, setpoint_temp_sch)
  coil_water_heating_desuperheater_gshp.setRatedHeatReclaimRecoveryEfficiency(0.25)

  # create a SWH Loop with a stratified water heater
  stratified_swh_loop = model.add_swh_loop('Stratified')
  water_heater_stratified = stratified_swh_loop.supplyComponents('OS:WaterHeater:Stratified'.to_IddObjectType)[0].to_WaterHeaterStratified.get
  # Add it as a heat rejection target for the Desuperheater
  coil_water_heating_desuperheater_gshp.addToHeatRejectionTarget(water_heater_stratified)

  # create equation fit water to air cooling coil
  coil_cooling_water_to_air_heat_pump_equation_fit = OpenStudio::Model::CoilCoolingWaterToAirHeatPumpEquationFit.new(model)

  # Create a condenserLoop and add it on the demand side
  condenserLoop = create_condenser_loop(model)
  condenserLoop.addDemandBranchForComponent(coil_cooling_water_to_air_heat_pump_equation_fit)

  # Create a Unitary on the AirLoopHVAC for that zone
  unitary = create_unitary_on_airloophvac(model, zone)
  # Set it as the coolingCoil of the Unitary
  unitary.setCoolingCoil(coil_cooling_water_to_air_heat_pump_equation_fit)

  # And Set it as the heating source of the Desuperheater
  coil_water_heating_desuperheater_gshp.setHeatingSource(coil_cooling_water_to_air_heat_pump_equation_fit)

  return coil_water_heating_desuperheater_gshp
end

# Tests a desuperheater with:
# * Heat Rejection Target: WaterHeaterMixed
# * Heating source: CoilCoolingDXMultiSpeed.
#
# @param model [BaselineModel] The model in which to create it
# @param zone [OpenStudio::Model::ThermalZone] the zone in question (has a
# PSZ-AC that we'll mess with to add an AirLoopHVACUnitary with the
# CoilCoolingDXMultiSpeed)
# @return [OpenStudio::Model::CoilWaterHeatingDesuperheater]
def create_multispeedac_test(model, zone)
  # create desuperheater object
  setpoint_temp_sch = OpenStudio::Model::ScheduleRuleset.new(model, 60)
  coil_water_heating_desuperheater_multi = OpenStudio::Model::CoilWaterHeatingDesuperheater.new(model, setpoint_temp_sch)
  coil_water_heating_desuperheater_multi.setRatedHeatReclaimRecoveryEfficiency(0.25)

  # Create a SHW Loop with a Mixed Water Heater
  mixed_swh_loop = model.add_swh_loop('Mixed')
  water_heater_mixed = mixed_swh_loop.supplyComponents('OS:WaterHeater:Mixed'.to_IddObjectType)[0].to_WaterHeaterMixed.get
  # Add it as a heat rejection target
  coil_water_heating_desuperheater_multi.addToHeatRejectionTarget(water_heater_mixed)

  # Create a Unitary on the AirLoopHVAC for that zone
  unitary = create_unitary_on_airloophvac(model, zone)

  # create multispeed dx cooling coil
  coil_cooling_dx_multispeed = OpenStudio::Model::CoilCoolingDXMultiSpeed.new(model)
  cool_stage_1 = OpenStudio::Model::CoilCoolingDXMultiSpeedStageData.new(model)
  cool_stage_2 = OpenStudio::Model::CoilCoolingDXMultiSpeedStageData.new(model)
  coil_cooling_dx_multispeed.addStage(cool_stage_1)
  coil_cooling_dx_multispeed.addStage(cool_stage_2)

  # Set it as the coolingCoil of the Unitary
  unitary.setCoolingCoil(coil_cooling_dx_multispeed)

  # And Set it as the heating source of the Desuperheater
  coil_water_heating_desuperheater_multi.setHeatingSource(coil_cooling_dx_multispeed)

  return coil_water_heating_desuperheater_multi
end

model = BaselineModel.new

# make a 2 story, 100m X 50m, 2 zone core/perimeter building
model.add_geometry({ 'length' => 100,
                     'width' => 50,
                     'num_floors' => 2,
                     'floor_to_floor_height' => 4,
                     'plenum_height' => 1,
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

# add ASHRAE System type 03, PSZ-AC
model.add_hvac({ 'ashrae_sys_num' => '03' })

# In order to produce more consistent results between different runs,
# we sort the zones by names
zones = model.getThermalZones.sort_by { |z| z.name.to_s }

###############################################################################
#                           (1) T E S T    G S H P                            #
###############################################################################

# Tests a desuperheater with:
# * Heat Rejection Target: WaterHeaterStratified
# * Heating source: CoilCoolingWaterToAirHeatPumpEquationFit. Creates a
# CondenserLoop to place that coil on the demand side too
create_gshp_test(model, zones[0])

###############################################################################
#                  (2) T E S T    M U L T I S P E E D    A C                  #
###############################################################################

# Tests a desuperheater with:
# * Heat Rejection Target: WaterHeaterMixed
# * Heating source: CoilCoolingDXMultiSpeed.
create_multispeedac_test(model, zones[1])

# save the OpenStudio model (.osm)
model.save_openstudio_osm({ 'osm_save_directory' => Dir.pwd, 'osm_name' => 'in.osm' })
