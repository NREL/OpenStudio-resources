import openstudio

from lib.baseline_model import BaselineModel

model = BaselineModel()

# make a 1 story, 100m X 50m, 5 zone core/perimeter building
model.add_geometry(length=100, width=50, num_floors=1, floor_to_floor_height=4, plenum_height=1, perimeter_zone_depth=3)

# add windows at a 40% window-to-wall ratio
model.add_windows(wwr=0.4, offset=1, application_type="Above Floor")

# add thermostats
model.add_thermostats(heating_setpoint=24, cooling_setpoint=28)

# assign constructions from a local library to the walls/windows/etc. in the model
model.set_constructions()

# set whole building space type; simplified 90.1-2004 Large Office Whole Building
model.set_space_type()

# add design days to the model (Chicago)
model.add_design_days()

# In order to produce more consistent results between different runs,
# we sort the zones by names
zones = sorted(model.getThermalZones(), key=lambda z: z.nameString())

alwaysOn = model.alwaysOnDiscreteSchedule()

vrf_fluid_temperature_control_hr = openstudio.model.AirConditionerVariableRefrigerantFlowFluidTemperatureControlHR(
    model
)
vrf_fluid_temperature_control_hr.setAvailabilitySchedule(alwaysOn)
vrf_fluid_temperature_control_hr.setRefrigerantType("R410a")
vrf_fluid_temperature_control_hr.setRatedEvaporativeCapacity(40000)
vrf_fluid_temperature_control_hr.setRatedCompressorPowerPerUnitofRatedEvaporativeCapacity(0.35)
vrf_fluid_temperature_control_hr.setMinimumOutdoorAirTemperatureinCoolingOnlyMode(-6.0)
vrf_fluid_temperature_control_hr.setMaximumOutdoorAirTemperatureinCoolingOnlyMode(43.0)
vrf_fluid_temperature_control_hr.setMinimumOutdoorAirTemperatureinHeatingOnlyMode(-20.0)
vrf_fluid_temperature_control_hr.setMaximumOutdoorAirTemperatureinHeatingOnlyMode(16.0)
vrf_fluid_temperature_control_hr.setMinimumOutdoorTemperatureinHeatRecoveryMode(-20.0)
vrf_fluid_temperature_control_hr.setMaximumOutdoorTemperatureinHeatRecoveryMode(43.0)
vrf_fluid_temperature_control_hr.setRefrigerantTemperatureControlAlgorithmforIndoorUnit("VariableTemp")
vrf_fluid_temperature_control_hr.setReferenceEvaporatingTemperatureforIndoorUnit(6.0)
vrf_fluid_temperature_control_hr.setReferenceCondensingTemperatureforIndoorUnit(44.0)
vrf_fluid_temperature_control_hr.setVariableEvaporatingTemperatureMinimumforIndoorUnit(4.0)
vrf_fluid_temperature_control_hr.setVariableEvaporatingTemperatureMaximumforIndoorUnit(13.0)
vrf_fluid_temperature_control_hr.setVariableCondensingTemperatureMinimumforIndoorUnit(42.0)
vrf_fluid_temperature_control_hr.setVariableCondensingTemperatureMaximumforIndoorUnit(46.0)
vrf_fluid_temperature_control_hr.setOutdoorUnitEvaporatorReferenceSuperheating(3)
vrf_fluid_temperature_control_hr.setOutdoorUnitCondenserReferenceSubcooling(5)
vrf_fluid_temperature_control_hr.setOutdoorUnitEvaporatorRatedBypassFactor(0.4)
vrf_fluid_temperature_control_hr.setOutdoorUnitCondenserRatedBypassFactor(0.2)
vrf_fluid_temperature_control_hr.setDifferencebetweenOutdoorUnitEvaporatingTemperatureandOutdoorAirTemperatureinHeatRecoveryMode(
    5
)
vrf_fluid_temperature_control_hr.setOutdoorUnitHeatExchangerCapacityRatio(0.3)
vrf_fluid_temperature_control_hr.setOutdoorUnitFanPowerPerUnitofRatedEvaporativeCapacity(4.25e-3)
vrf_fluid_temperature_control_hr.setOutdoorUnitFanFlowRatePerUnitofRatedEvaporativeCapacity(7.50e-5)
vrf_fluid_temperature_control_hr.setDiameterofMainPipeforSuctionGas(0.0762)
vrf_fluid_temperature_control_hr.setDiameterofMainPipeforDischargeGas(0.0762)
vrf_fluid_temperature_control_hr.setLengthofMainPipeConnectingOutdoorUnittotheFirstBranchJoint(30.0)
vrf_fluid_temperature_control_hr.setEquivalentLengthofMainPipeConnectingOutdoorUnittotheFirstBranchJoint(36.0)
vrf_fluid_temperature_control_hr.setHeightDifferenceBetweenOutdoorUnitandIndoorUnits(5.0)
vrf_fluid_temperature_control_hr.setMainPipeInsulationThickness(0.02)
vrf_fluid_temperature_control_hr.setMainPipeInsulationThermalConductivity(0.032)
vrf_fluid_temperature_control_hr.setCrankcaseHeaterPowerperCompressor(33.0)
vrf_fluid_temperature_control_hr.setNumberofCompressors(2)
vrf_fluid_temperature_control_hr.setRatioofCompressorSizetoTotalCompressorCapacity(0.5)
vrf_fluid_temperature_control_hr.setMaximumOutdoorDryBulbTemperatureforCrankcaseHeater(5.0)
vrf_fluid_temperature_control_hr.setDefrostStrategy("Resistive")
vrf_fluid_temperature_control_hr.setDefrostControl("Timed")
vrf_fluid_temperature_control_hr.setDefrostTimePeriodFraction(0.058333)
vrf_fluid_temperature_control_hr.setResistiveDefrostHeaterCapacity(0.0)
vrf_fluid_temperature_control_hr.setMaximumOutdoorDrybulbTemperatureforDefrostOperation(5.0)
vrf_fluid_temperature_control_hr.setInitialHeatRecoveryCoolingCapacityFraction(1)
vrf_fluid_temperature_control_hr.setHeatRecoveryCoolingCapacityTimeConstant(0)
vrf_fluid_temperature_control_hr.setInitialHeatRecoveryCoolingEnergyFraction(1)
vrf_fluid_temperature_control_hr.setHeatRecoveryCoolingEnergyTimeConstant(0)
vrf_fluid_temperature_control_hr.setInitialHeatRecoveryHeatingCapacityFraction(1)
vrf_fluid_temperature_control_hr.setHeatRecoveryHeatingCapacityTimeConstant(0)
vrf_fluid_temperature_control_hr.setInitialHeatRecoveryHeatingEnergyFraction(1)
vrf_fluid_temperature_control_hr.setHeatRecoveryHeatingEnergyTimeConstant(0)
vrf_fluid_temperature_control_hr.setCompressorMaximumDeltaPressure(4500000.0)
vrf_fluid_temperature_control_hr.setCompressorInverterEfficiency(0.95)
vrf_fluid_temperature_control_hr.setCompressorEvaporativeCapacityCorrectionFactor(1.0)
vrf_fluid_temperature_control_hr.removeAllLoadingIndexes()

outdoorUnitEvaporatingTemperatureFunctionofSuperheatingCurve = openstudio.model.CurveQuadratic(model)
outdoorUnitEvaporatingTemperatureFunctionofSuperheatingCurve.setCoefficient1Constant(0)
outdoorUnitEvaporatingTemperatureFunctionofSuperheatingCurve.setCoefficient2x(6.05e-1)
outdoorUnitEvaporatingTemperatureFunctionofSuperheatingCurve.setCoefficient3xPOW2(2.50e-2)
outdoorUnitEvaporatingTemperatureFunctionofSuperheatingCurve.setMinimumValueofx(0)
outdoorUnitEvaporatingTemperatureFunctionofSuperheatingCurve.setMaximumValueofx(15)
vrf_fluid_temperature_control_hr.setOutdoorUnitEvaporatingTemperatureFunctionofSuperheatingCurve(
    outdoorUnitEvaporatingTemperatureFunctionofSuperheatingCurve
)

outdoorUnitCondensingTemperatureFunctionofSubcoolingCurve = openstudio.model.CurveQuadratic(model)
outdoorUnitCondensingTemperatureFunctionofSubcoolingCurve.setCoefficient1Constant(0)
outdoorUnitCondensingTemperatureFunctionofSubcoolingCurve.setCoefficient2x(-2.91)
outdoorUnitCondensingTemperatureFunctionofSubcoolingCurve.setCoefficient3xPOW2(1.180)
outdoorUnitCondensingTemperatureFunctionofSubcoolingCurve.setMinimumValueofx(0)
outdoorUnitCondensingTemperatureFunctionofSubcoolingCurve.setMaximumValueofx(5)
vrf_fluid_temperature_control_hr.setOutdoorUnitCondensingTemperatureFunctionofSubcoolingCurve(
    outdoorUnitCondensingTemperatureFunctionofSubcoolingCurve
)

evaporativeCapacityMultiplierFunctionofTemperatureCurve1 = openstudio.model.CurveBiquadratic(model)
evaporativeCapacityMultiplierFunctionofTemperatureCurve1.setCoefficient1Constant(3.19e-01)
evaporativeCapacityMultiplierFunctionofTemperatureCurve1.setCoefficient2x(-1.26e-03)
evaporativeCapacityMultiplierFunctionofTemperatureCurve1.setCoefficient3xPOW2(-2.15e-05)
evaporativeCapacityMultiplierFunctionofTemperatureCurve1.setCoefficient4y(1.20e-02)
evaporativeCapacityMultiplierFunctionofTemperatureCurve1.setCoefficient5yPOW2(1.05e-04)
evaporativeCapacityMultiplierFunctionofTemperatureCurve1.setCoefficient6xTIMESY(-8.66e-05)
evaporativeCapacityMultiplierFunctionofTemperatureCurve1.setMinimumValueofx(15)
evaporativeCapacityMultiplierFunctionofTemperatureCurve1.setMaximumValueofx(65)
evaporativeCapacityMultiplierFunctionofTemperatureCurve1.setMinimumValueofy(-30)
evaporativeCapacityMultiplierFunctionofTemperatureCurve1.setMaximumValueofy(15)

compressorPowerMultiplierFunctionofTemperatureCurve1 = openstudio.model.CurveBiquadratic(model)
compressorPowerMultiplierFunctionofTemperatureCurve1.setCoefficient1Constant(8.79e-02)
compressorPowerMultiplierFunctionofTemperatureCurve1.setCoefficient2x(-1.72e-04)
compressorPowerMultiplierFunctionofTemperatureCurve1.setCoefficient3xPOW2(6.93e-05)
compressorPowerMultiplierFunctionofTemperatureCurve1.setCoefficient4y(-3.38e-05)
compressorPowerMultiplierFunctionofTemperatureCurve1.setCoefficient5yPOW2(-8.10e-06)
compressorPowerMultiplierFunctionofTemperatureCurve1.setCoefficient6xTIMESY(-1.04e-05)
compressorPowerMultiplierFunctionofTemperatureCurve1.setMinimumValueofx(15)
compressorPowerMultiplierFunctionofTemperatureCurve1.setMaximumValueofx(65)
compressorPowerMultiplierFunctionofTemperatureCurve1.setMinimumValueofy(-30)
compressorPowerMultiplierFunctionofTemperatureCurve1.setMaximumValueofy(15)
loadingIndex1 = openstudio.model.LoadingIndex(
    model,
    1500,
    evaporativeCapacityMultiplierFunctionofTemperatureCurve1,
    compressorPowerMultiplierFunctionofTemperatureCurve1,
)
vrf_fluid_temperature_control_hr.addLoadingIndex(loadingIndex1)

evaporativeCapacityMultiplierFunctionofTemperatureCurve2 = openstudio.model.CurveBiquadratic(model)
evaporativeCapacityMultiplierFunctionofTemperatureCurve2.setCoefficient1Constant(8.12e-01)
evaporativeCapacityMultiplierFunctionofTemperatureCurve2.setCoefficient2x(-4.23e-03)
evaporativeCapacityMultiplierFunctionofTemperatureCurve2.setCoefficient3xPOW2(-4.11e-05)
evaporativeCapacityMultiplierFunctionofTemperatureCurve2.setCoefficient4y(2.97e-02)
evaporativeCapacityMultiplierFunctionofTemperatureCurve2.setCoefficient5yPOW2(2.67e-04)
evaporativeCapacityMultiplierFunctionofTemperatureCurve2.setCoefficient6xTIMESY(-2.23e-04)
evaporativeCapacityMultiplierFunctionofTemperatureCurve2.setMinimumValueofx(15)
evaporativeCapacityMultiplierFunctionofTemperatureCurve2.setMaximumValueofx(65)
evaporativeCapacityMultiplierFunctionofTemperatureCurve2.setMinimumValueofy(-30)
evaporativeCapacityMultiplierFunctionofTemperatureCurve2.setMaximumValueofy(15)

compressorPowerMultiplierFunctionofTemperatureCurve2 = openstudio.model.CurveBiquadratic(model)
compressorPowerMultiplierFunctionofTemperatureCurve2.setCoefficient1Constant(3.26e-01)
compressorPowerMultiplierFunctionofTemperatureCurve2.setCoefficient2x(-2.20e-03)
compressorPowerMultiplierFunctionofTemperatureCurve2.setCoefficient3xPOW2(1.42e-04)
compressorPowerMultiplierFunctionofTemperatureCurve2.setCoefficient4y(2.82e-03)
compressorPowerMultiplierFunctionofTemperatureCurve2.setCoefficient5yPOW2(2.86e-05)
compressorPowerMultiplierFunctionofTemperatureCurve2.setCoefficient6xTIMESY(-3.50e-05)
compressorPowerMultiplierFunctionofTemperatureCurve2.setMinimumValueofx(15)
compressorPowerMultiplierFunctionofTemperatureCurve2.setMaximumValueofx(65)
compressorPowerMultiplierFunctionofTemperatureCurve2.setMinimumValueofy(-30)
compressorPowerMultiplierFunctionofTemperatureCurve2.setMaximumValueofy(15)
loadingIndex2 = openstudio.model.LoadingIndex(
    model,
    3600,
    evaporativeCapacityMultiplierFunctionofTemperatureCurve2,
    compressorPowerMultiplierFunctionofTemperatureCurve2,
)
vrf_fluid_temperature_control_hr.addLoadingIndex(loadingIndex2)

evaporativeCapacityMultiplierFunctionofTemperatureCurve3 = openstudio.model.CurveBiquadratic(model)
evaporativeCapacityMultiplierFunctionofTemperatureCurve3.setCoefficient1Constant(1.32e00)
evaporativeCapacityMultiplierFunctionofTemperatureCurve3.setCoefficient2x(-6.20e-03)
evaporativeCapacityMultiplierFunctionofTemperatureCurve3.setCoefficient3xPOW2(-7.10e-05)
evaporativeCapacityMultiplierFunctionofTemperatureCurve3.setCoefficient4y(4.89e-02)
evaporativeCapacityMultiplierFunctionofTemperatureCurve3.setCoefficient5yPOW2(4.59e-04)
evaporativeCapacityMultiplierFunctionofTemperatureCurve3.setCoefficient6xTIMESY(-3.67e-04)
evaporativeCapacityMultiplierFunctionofTemperatureCurve3.setMinimumValueofx(15)
evaporativeCapacityMultiplierFunctionofTemperatureCurve3.setMaximumValueofx(65)
evaporativeCapacityMultiplierFunctionofTemperatureCurve3.setMinimumValueofy(-30)
evaporativeCapacityMultiplierFunctionofTemperatureCurve3.setMaximumValueofy(15)

compressorPowerMultiplierFunctionofTemperatureCurve3 = openstudio.model.CurveBiquadratic(model)
compressorPowerMultiplierFunctionofTemperatureCurve3.setCoefficient1Constant(6.56e-01)
compressorPowerMultiplierFunctionofTemperatureCurve3.setCoefficient2x(-3.71e-03)
compressorPowerMultiplierFunctionofTemperatureCurve3.setCoefficient3xPOW2(2.07e-04)
compressorPowerMultiplierFunctionofTemperatureCurve3.setCoefficient4y(1.05e-02)
compressorPowerMultiplierFunctionofTemperatureCurve3.setCoefficient5yPOW2(7.36e-05)
compressorPowerMultiplierFunctionofTemperatureCurve3.setCoefficient6xTIMESY(-1.57e-04)
compressorPowerMultiplierFunctionofTemperatureCurve3.setMinimumValueofx(15)
compressorPowerMultiplierFunctionofTemperatureCurve3.setMaximumValueofx(65)
compressorPowerMultiplierFunctionofTemperatureCurve3.setMinimumValueofy(-30)
compressorPowerMultiplierFunctionofTemperatureCurve3.setMaximumValueofy(15)
loadingIndex3 = openstudio.model.LoadingIndex(
    model,
    6000,
    evaporativeCapacityMultiplierFunctionofTemperatureCurve3,
    compressorPowerMultiplierFunctionofTemperatureCurve3,
)
vrf_fluid_temperature_control_hr.addLoadingIndex(loadingIndex3)

for i, z in enumerate(zones):
    coolingCoil = openstudio.model.CoilCoolingDXVariableRefrigerantFlowFluidTemperatureControl(model)
    coolingCoil.setAvailabilitySchedule(alwaysOn)
    coolingCoil.autosizeRatedTotalCoolingCapacity()
    coolingCoil.autosizeRatedSensibleHeatRatio()
    coolingCoil.setIndoorUnitReferenceSuperheating(5.0)

    indoorUnitEvaporatingTemperatureFunctionofSuperheatingCurve = openstudio.model.CurveQuadratic(model)
    indoorUnitEvaporatingTemperatureFunctionofSuperheatingCurve.setCoefficient1Constant(0)
    indoorUnitEvaporatingTemperatureFunctionofSuperheatingCurve.setCoefficient2x(0.843)
    indoorUnitEvaporatingTemperatureFunctionofSuperheatingCurve.setCoefficient3xPOW2(0)
    indoorUnitEvaporatingTemperatureFunctionofSuperheatingCurve.setMinimumValueofx(0)
    indoorUnitEvaporatingTemperatureFunctionofSuperheatingCurve.setMaximumValueofx(15)
    coolingCoil.setIndoorUnitEvaporatingTemperatureFunctionofSuperheatingCurve(
        indoorUnitEvaporatingTemperatureFunctionofSuperheatingCurve
    )

    heatingCoil = openstudio.model.CoilHeatingDXVariableRefrigerantFlowFluidTemperatureControl(model)
    heatingCoil.setAvailabilitySchedule(alwaysOn)
    heatingCoil.autosizeRatedTotalHeatingCapacity()
    heatingCoil.setIndoorUnitReferenceSubcooling(5.0)
    indoorUnitCondensingTemperatureFunctionofSubcoolingCurve = openstudio.model.CurveQuadratic(model)
    indoorUnitCondensingTemperatureFunctionofSubcoolingCurve.setCoefficient1Constant(-1.85)
    indoorUnitCondensingTemperatureFunctionofSubcoolingCurve.setCoefficient2x(0.411)
    indoorUnitCondensingTemperatureFunctionofSubcoolingCurve.setCoefficient3xPOW2(0.0196)
    indoorUnitCondensingTemperatureFunctionofSubcoolingCurve.setMinimumValueofx(0)
    indoorUnitCondensingTemperatureFunctionofSubcoolingCurve.setMaximumValueofx(20)
    heatingCoil.setIndoorUnitCondensingTemperatureFunctionofSubcoolingCurve(
        indoorUnitCondensingTemperatureFunctionofSubcoolingCurve
    )

    fan = openstudio.model.FanVariableVolume(model)
    fan.setAvailabilitySchedule(alwaysOn)
    fan.setFanTotalEfficiency(0.6045)
    fan.setPressureRise(1017.592)
    fan.autosizeMaximumFlowRate()
    fan.setFanPowerMinimumFlowRateInputMethod("FixedFlowRate")
    fan.setFanPowerMinimumFlowFraction(0.0)
    fan.setFanPowerMinimumAirFlowRate(0.0)
    fan.setMotorEfficiency(0.93)
    fan.setMotorInAirstreamFraction(1.0)
    fan.setFanPowerCoefficient1(0.0407598940)
    fan.setFanPowerCoefficient2(0.08804497)
    fan.setFanPowerCoefficient3(-0.072926120)
    fan.setFanPowerCoefficient4(0.9437398230)
    fan.setFanPowerCoefficient5(0.0)

    vrf_terminal = openstudio.model.ZoneHVACTerminalUnitVariableRefrigerantFlow(model, coolingCoil, heatingCoil, fan)

    vrf_terminal.addToThermalZone(z)
    vrf_fluid_temperature_control_hr.addTerminal(vrf_terminal)


# save the OpenStudio model (.osm)
model.save_openstudio_osm(osm_save_directory=None, osm_name="in.osm")
