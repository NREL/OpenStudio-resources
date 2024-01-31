# frozen_string_literal: true

require 'openstudio'
require_relative 'lib/baseline_model'

m = BaselineModel.new

# make a 1 story, 100m X 50m, 1 zone building
m.add_geometry({ 'length' => 100,
                 'width' => 50,
                 'num_floors' => 1,
                 'floor_to_floor_height' => 4,
                 'plenum_height' => 0,
                 'perimeter_zone_depth' => 0 })

# add windows at a 40% window-to-wall ratio
m.add_windows({ 'wwr' => 0.4,
                'offset' => 1,
                'application_type' => 'Above Floor' })

# add thermostats
m.add_thermostats({ 'heating_setpoint' => 19,
                    'cooling_setpoint' => 26 })

# assign constructions from a local library to the walls/windows/etc. in the model
m.set_constructions

# set whole building space type; simplified 90.1-2004 Large Office Whole Building
m.set_space_type

# add design days to the model (Chicago)
m.add_design_days

def curve_biquadratic(model, c_1constant, c_2x, c_3xPOW2, c_4y, c_5yPOW2, c_6xTIMESY, minx, maxx, miny, maxy)
  curve = OpenStudio::Model::CurveBiquadratic.new(model)
  curve.setCoefficient1Constant(c_1constant)
  curve.setCoefficient2x(c_2x)
  curve.setCoefficient3xPOW2(c_3xPOW2)
  curve.setCoefficient4y(c_4y)
  curve.setCoefficient5yPOW2(c_5yPOW2)
  curve.setCoefficient6xTIMESY(c_6xTIMESY)
  curve.setMinimumValueofx(minx)
  curve.setMaximumValueofx(maxx)
  curve.setMinimumValueofy(miny)
  curve.setMaximumValueofy(maxy)
  return curve
end

def curve_cubic(model, c_1constant, c_2x, c_3xPOW2, c_4xPOW3, minx, maxx)
  curve = OpenStudio::Model::CurveCubic.new(model)
  curve.setCoefficient1Constant(c_1constant)
  curve.setCoefficient2x(c_2x)
  curve.setCoefficient3xPOW2(c_3xPOW2)
  curve.setCoefficient4xPOW3(c_4xPOW3)
  curve.setMinimumValueofx(minx)
  curve.setMaximumValueofx(maxx)
  return curve
end

def curve_quadratic(model, c_1constant, c_2x, c_3xPOW2, minx = nil, maxx = nil, miny = nil, maxy = nil)
  curve = OpenStudio::Model::CurveQuadratic.new(model)
  curve.setCoefficient1Constant(c_1constant)
  curve.setCoefficient2x(c_2x)
  curve.setCoefficient3xPOW2(c_3xPOW2)
  curve.setMinimumValueofx(minx) if !minx.nil?
  curve.setMaximumValueofx(maxx) if !maxx.nil?
  curve.setMinimumCurveOutput(miny) if !miny.nil?
  curve.setMaximumCurveOutput(maxy) if !maxy.nil?
  return curve
end

def curve_triquadratic(model)
  curve = OpenStudio::Model::CurveTriquadratic.new(model)
  # TODO
  return curve
end

def curve_table_lookup(model)
  curve = OpenStudio::Model::TableLookup.new(model)
  # TODO
  return curve
end

# RetailPackagedTESCoil.idf

# CoilCoolingDXSingleSpeedThermalStorage
coil = OpenStudio::Model::CoilCoolingDXSingleSpeedThermalStorage.new(m)
coil.setAvailabilitySchedule(m.alwaysOnDiscreteSchedule)
coil.setOperatingModeControlMethod("EMSControlled")
coil.setStorageType("Ice")
coil.autocalculateIceStorageCapacity
coil.setStorageCapacitySizingFactor(6.0)
coil.setStorageTanktoAmbientUvalueTimesAreaHeatTransferCoefficient(7.913)
coil.autosizeRatedEvaporatorAirFlowRate
coil.setAncillaryElectricPower(0.0)
coil.setColdWeatherOperationMinimumOutdoorAirTemperature(2.0)
coil.setColdWeatherOperationAncillaryPower(0.0)
coil.setCondenserAirFlowSizingFactor(1.25)
coil.setCondenserType("AirCooled")
coil.setEvaporativeCondenserEffectiveness(0.7)
coil.setEvaporativeCondenserPumpRatedPowerConsumption(0)
coil.setBasinHeaterCapacity(0)
coil.setBasinHeaterSetpointTemperature(2)

# Cooling Only Mode = Yes
coil.setCoolingOnlyModeAvailable(true)
coil.autosizeCoolingOnlyModeRatedTotalEvaporatorCoolingCapacity
coil.setCoolingOnlyModeRatedSensibleHeatRatio(0.7)
coil.setCoolingOnlyModeRatedCOP(3.50015986358308)
cool_cap_ft = curve_biquadratic(m, 0.9712123, -0.015275502, 0.0014434524, -0.00039321, -0.0000068364, -0.0002905956, -100, 100, -100, 100)
constant_cubic = curve_cubic(m, 1, 0, 0, 0, -100, 100)
cool_eir_ft = curve_biquadratic(m, 0.28687133, 0.023902164, -0.000810648, 0.013458546, 0.0003389364, -0.0004870044, -100, 100, -100, 100)
cool_plf_fplr = curve_quadratic(m, 0.90949556, 0.09864773, -0.00819488, 0, 1, 0.7, 1)
cool_shr_ft = curve_biquadratic(m, 1.3294540786, -0.0990649255, 0.0008310043, 0.0652277735, -0.0000793358, -0.0005874422, 24.44, 26.67, 29.44, 46.1)
cool_shr_fff = curve_quadratic(m, 0.9317, -0.0077, 0.0760, 0.69, 1.30)
coil.setCoolingOnlyModeTotalEvaporatorCoolingCapacityFunctionofTemperatureCurve(cool_cap_ft)
coil.setCoolingOnlyModeTotalEvaporatorCoolingCapacityFunctionofFlowFractionCurve(constant_cubic)
coil.setCoolingOnlyModeEnergyInputRatioFunctionofTemperatureCurve(cool_eir_ft)
coil.setCoolingOnlyModeEnergyInputRatioFunctionofFlowFractionCurve(constant_cubic)
coil.setCoolingOnlyModePartLoadFractionCorrelationCurve(cool_plf_fplr)
coil.setCoolingOnlyModeSensibleHeatRatioFunctionofTemperatureCurve(cool_shr_ft)
coil.setCoolingOnlyModeSensibleHeatRatioFunctionofFlowFractionCurve(cool_shr_fff)

# Cooling And Charge Mode = Yes
coil.setCoolingAndChargeModeAvailable(false)
coil.autocalculateCoolingAndChargeModeRatedTotalEvaporatorCoolingCapacity
coil.setCoolingAndChargeModeCapacitySizingFactor(1.0)
coil.autocalculateCoolingAndChargeModeRatedStorageChargingCapacity
coil.setCoolingAndChargeModeStorageCapacitySizingFactor(0.86)
coil.setCoolingAndChargeModeRatedSensibleHeatRatio(0.7)
coil.setCoolingAndChargeModeCoolingRatedCOP(3.66668442928701)
coil.setCoolingAndChargeModeChargingRatedCOP(2.17)
cool_charge_cool_cap_ft = curve_triquadratic(m) # TODO
cool_charge_cool_eir_ft = curve_triquadratic(m) # TODO
# cool_charge_charge_cap_ft = curve_table_lookup(m) # TODO
# cool_charge_charge_eir_ft = curve_table_lookup(m) # TODO
coil.setCoolingAndChargeModeTotalEvaporatorCoolingCapacityFunctionofTemperatureCurve(cool_charge_cool_cap_ft)
coil.setCoolingAndChargeModeTotalEvaporatorCoolingCapacityFunctionofFlowFractionCurve(constant_cubic)
coil.setCoolingAndChargeModeEvaporatorEnergyInputRatioFunctionofTemperatureCurve(cool_charge_cool_eir_ft)
coil.setCoolingAndChargeModeEvaporatorEnergyInputRatioFunctionofFlowFractionCurve(constant_cubic)
coil.setCoolingAndChargeModeEvaporatorPartLoadFractionCorrelationCurve(cool_plf_fplr)
# coil.setCoolingAndChargeModeStorageChargeCapacityFunctionofTemperatureCurve(cool_charge_charge_cap_ft)
coil.setCoolingAndChargeModeStorageChargeCapacityFunctionofTotalEvaporatorPLRCurve(constant_cubic)
# coil.setCoolingAndChargeModeStorageEnergyInputRatioFunctionofTemperatureCurve(cool_charge_charge_eir_ft)
coil.setCoolingAndChargeModeStorageEnergyInputRatioFunctionofFlowFractionCurve(constant_cubic)
coil.setCoolingAndChargeModeStorageEnergyPartLoadFractionCorrelationCurve(constant_cubic)
coil.setCoolingAndChargeModeSensibleHeatRatioFunctionofTemperatureCurve(cool_shr_ft)
coil.setCoolingAndChargeModeSensibleHeatRatioFunctionofFlowFractionCurve(cool_shr_fff)

# Cooling And Discharge Mode = No
coil.setCoolingAndDischargeModeAvailable(false)

# Charge Only Mode = No
coil.setChargeOnlyModeAvailable(false)

# Discharge Only Mode = Yes
coil.setDischargeOnlyModeAvailable(true)
coil.autocalculateDischargeOnlyModeRatedStorageDischargingCapacity
coil.setDischargeOnlyModeCapacitySizingFactor(1.70)
coil.setDischargeOnlyModeRatedSensibleHeatRatio(0.64)
coil.setDischargeOnlyModeRatedCOP(63.6)
discharge_cap_ft = curve_biquadratic(m, -0.561476105575098, 0.133948946696947, -0.0027652398813276, 0.0, 0.0, 0.0, -100, 100, -100, 100)
discharge_cap_fff = curve_cubic(m, 0.743258739392434, 0.167765026703717, 0.0852727911986869, 0, -100, 100)
constant_bi = curve_biquadratic(m, 1, 0, 0, 0, 0, 0, -100, 100, -100, 100)
discharge_shr_ft = curve_biquadratic(m, -76.3312028672366, 3.69083877577677, 0.00402614182268047, 3.120670734078, -0.00297662635327143, -0.148603418986272, 24.44, 26.67, 29.44, 46.1)
discharge_shr_fff = curve_quadratic(m, 0.60557628, 0.506516665, -0.12647141, 0.2, 1.00)
coil.setDischargeOnlyModeStorageDischargeCapacityFunctionofTemperatureCurve(discharge_cap_ft)
coil.setDischargeOnlyModeStorageDischargeCapacityFunctionofFlowFractionCurve(discharge_cap_fff)
coil.setDischargeOnlyModeEnergyInputRatioFunctionofTemperatureCurve(constant_bi)
coil.setDischargeOnlyModeEnergyInputRatioFunctionofFlowFractionCurve(constant_cubic)
coil.setDischargeOnlyModePartLoadFractionCorrelationCurve(constant_cubic)
coil.setDischargeOnlyModeSensibleHeatRatioFunctionofTemperatureCurve(discharge_shr_ft)
coil.setDischargeOnlyModeSensibleHeatRatioFunctionofFlowFractionCurve(discharge_shr_fff)

# FanOnOff
fan = OpenStudio::Model::FanOnOff.new(m)
fan.setFanEfficiency(0.75)
fan.setPressureRise(476.748000740096)
fan.setMotorEfficiency(1.0)
fan.setMotorInAirstreamFraction(1.0)

# AirLoopHVACUnitarySystem
air_loop_unitary = OpenStudio::Model::AirLoopHVACUnitarySystem.new(m)
air_loop_unitary.setAvailabilitySchedule(m.alwaysOnDiscreteSchedule)
air_loop_unitary.setCoolingCoil(coil)
air_loop_unitary.setSupplyAirFlowRateDuringHeatingOperation(0.0)
air_loop_unitary.setSupplyFan(fan)
air_loop_unitary.setFanPlacement('BlowThrough')
air_loop_unitary.setSupplyAirFanOperatingModeSchedule(m.alwaysOffDiscreteSchedule)
air_loop_unitary.setSupplyAirFlowRateMethodDuringCoolingOperation('SupplyAirFlowRate')
air_loop_unitary.setSupplyAirFlowRateMethodDuringHeatingOperation('SupplyAirFlowRate')
air_loop_unitary.setMaximumSupplyAirTemperature(48.888889)
air_loop_unitary.setSupplyAirFlowRateWhenNoCoolingorHeatingisRequired(0)

# AirLoopHVAC
air_loop = OpenStudio::Model::AirLoopHVAC.new(m)
air_supply_inlet_node = air_loop.supplyInletNode
air_loop_unitary.addToNode(air_supply_inlet_node)

# Add to zone
# In order to produce more consistent results between different runs,
# we sort the zones by names
# (There's only one here, but just in case this would be copy pasted somewhere
# else...)
zones = m.getThermalZones.sort_by { |z| z.name.to_s }
z = zones[0]
atu = OpenStudio::Model::AirTerminalSingleDuctConstantVolumeNoReheat.new(m, m.alwaysOnDiscreteSchedule)
air_loop_unitary.setControllingZoneorThermostatLocation(z)
air_loop.addBranchForZone(z, atu)

# save the OpenStudio model (.osm)
m.save_openstudio_osm({ 'osm_save_directory' => Dir.pwd,
                        'osm_name' => 'in.osm' })
