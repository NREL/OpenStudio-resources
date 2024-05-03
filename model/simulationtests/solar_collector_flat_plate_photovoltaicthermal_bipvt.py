import json

import openstudio

from lib.baseline_model import BaselineModel

model = BaselineModel()

model.add_standards(
    json.loads(
        """{
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
  }"""
    )
)

# make a 1 story, 100m X 50m, 1 zone core/perimeter building
model.add_geometry(length=100, width=50, num_floors=1, floor_to_floor_height=4, plenum_height=0, perimeter_zone_depth=0)

# add windows at a 40% window-to-wall ratio
model.add_windows(wwr=0.4, offset=1, application_type="Above Floor")

# add ASHRAE System type 01, PTAC, Residential
model.add_hvac(ashrae_sys_num="01")

# add thermostats
model.add_thermostats(heating_setpoint=24, cooling_setpoint=28)

# assign constructions from a local library to the walls/windows/etc. in the model
model.set_constructions()

# set whole building space type; simplified 90.1-2004 Large Office Whole Building
model.set_space_type()

# add design days to the model (Chicago)
model.add_design_days()

# create the swh loop and uses
mixed_swh_loop = model.add_swh_loop("Mixed")
model.add_swh_end_uses(mixed_swh_loop, "Medium Office Bldg Swh")

# remove the existing water heater
supply_components = mixed_swh_loop.supplyComponents("OS:WaterHeater:Mixed".to_IddObjectType())
swh_water_heater = supply_components[0].to_WaterHeaterMixed().get()
mixed_swh_loop.removeSupplyBranchWithComponent(swh_water_heater)

supply_components = mixed_swh_loop.supplyComponents("OS:Pipe:Adiabatic".to_IddObjectType())
swh_pipe = supply_components[0].to_PipeAdiabatic().get()
mixed_swh_loop.removeSupplyBranchWithComponent(swh_pipe)

supply_components = mixed_swh_loop.supplyComponents("OS:Pump:ConstantSpeed".to_IddObjectType())
swh_pump = supply_components[0].to_PumpConstantSpeed().get()

# storage water heating loop
storage_water_loop = openstudio.model.PlantLoop(model)
storage_water_loop.setName("Storage Water Loop")
storage_water_loop.setMaximumLoopTemperature(60)
storage_water_loop.setMinimumLoopTemperature(10)

# Temperature schedule type limits
temp_sch_type_limits = openstudio.model.ScheduleTypeLimits(model)
temp_sch_type_limits.setName("Temperature Schedule Type Limits")
temp_sch_type_limits.setLowerLimitValue(0.0)
temp_sch_type_limits.setUpperLimitValue(100.0)
temp_sch_type_limits.setNumericType("Continuous")
temp_sch_type_limits.setUnitType("Temperature")

# Storage water heating loop controls
storage_temp_f = 140
storage_delta_t_r = 9  # 9F delta-T
storage_temp_c = openstudio.convert(storage_temp_f, "F", "C").get()
storage_delta_t_k = openstudio.convert(storage_delta_t_r, "R", "K").get()
storage_temp_sch = openstudio.model.ScheduleRuleset(model)
storage_temp_sch.setName("Hot Water Loop Temp - #{storage_temp_f}F")
storage_temp_sch.defaultDaySchedule().setName("Hot Water Loop Temp - #{storage_temp_f}F Default")
storage_temp_sch.defaultDaySchedule().addValue(openstudio.Time(0, 24, 0, 0), storage_temp_c)
storage_temp_sch.setScheduleTypeLimits(temp_sch_type_limits)
storage_stpt_manager = openstudio.model.SetpointManagerScheduled(model, storage_temp_sch)
storage_stpt_manager.addToNode(storage_water_loop.supplyOutletNode())

storage_plant = storage_water_loop.sizingPlant()
storage_plant.setLoopType("Heating")
storage_plant.setDesignLoopExitTemperature(storage_temp_c)
storage_plant.setLoopDesignTemperatureDifference(storage_delta_t_k)

# Storage water heating pump
storage_pump_head_press_pa = 0.001
storage_pump_motor_efficiency = 1

storage_pump = openstudio.model.PumpConstantSpeed(model)
storage_pump.setName("Storage Water Loop Pump")
storage_pump.setRatedPumpHead(storage_pump_head_press_pa.to_f())
storage_pump.setMotorEfficiency(storage_pump_motor_efficiency)
storage_pump.setPumpControlType("Intermittent")
storage_pump.addToNode(storage_water_loop.supplyInletNode())

storage_water_heater = openstudio.model.WaterHeaterMixed(model)
storage_water_heater.setName("Storage Hot Water Tank")
storage_water_heater.setSetpointTemperatureSchedule(storage_temp_sch)
storage_water_heater.setHeaterMaximumCapacity(0.0)
# storage_water_heater.setDeadbandTemperatureDifference(openstudio.convert(3.6,'R','K').get)
# storage_water_heater.setHeaterControlType('Cycle')
# storage_water_heater.setTankVolume(openstudio.convert(water_heater_vol_gal,'gal','m^3').get)
storage_water_loop.addDemandBranchForComponent(storage_water_heater)

# Get the roof
roofs = sorted([s for s in model.getSurfaces() if s.surfaceType() == "RoofCeiling"], key=lambda s: s.nameString())
if len(roofs) != 1:
    raise ValueError("Unexpected number of Roofs in model")

roof = roofs[0]

# Use the explicit ctor for SolarCollectorFlatPlatePhotovoltaicThermal so it
# uses our BIPVT performance instead of creating a Simple performance object
performance = openstudio.model.SolarCollectorPerformancePhotovoltaicThermalBIPVT(model)
collector = openstudio.model.SolarCollectorFlatPlatePhotovoltaicThermal(performance)
storage_water_loop.addSupplyBranchForComponent(collector)

# Set the collector surface, and ensure the same SurfacePropertyOtherSideConditionsmodel is used
collector.setSurface(roof)
# Setting the Outside Boundary to OtherSideConditionsmodel means that the
# construction is no longer retrived from the default construction set, so
# explicit set it
roof_construction = roof.construction().get()
roof.setSurfacePropertyOtherSideConditionsmodel(performance.boundaryConditionsmodel())
roof.setConstruction(roof_construction)

# We need a PV object as well, and and ELCD, and an inverted
# create the panel
panel = openstudio.model.GeneratorPhotovoltaic.simple(model)
panel.setSurface(roof)
# create the inverter
inverter = openstudio.model.ElectricLoadCenterInverterSimple(model)
# create the distribution system
elcd = openstudio.model.ElectricLoadCenterDistribution(model)
elcd.addGenerator(panel)
elcd.setInverter(inverter)
elcd.setElectricalBussType("DirectCurrentWithInverter")
elcd.setGeneratorOperationSchemeType("TrackElectrical")

# Assign the PV Generator to the collector
collector.setGeneratorPhotovoltaic(panel)

collector.autosizeDesignFlowRate()

# Modify the Performance object
# (Here I hardset them exactly like the constructor does)
oscm = performance.boundaryConditionsmodel()
oscm.setTypeOfmodeling("GapConvectionRadiation")

alwaysOn = model.alwaysOnDiscreteSchedule()
performance.setAvailabilitySchedule(alwaysOn)

performance.setEffectivePlenumGapThicknessBehindPVModules(0.1)  # 10cm. Taken from ShopWithBIPVT.idf

# IDD Defaults
performance.setPVCellNormalTransmittanceAbsorptanceProduct(0.957)
performance.setBackingMaterialNormalTransmittanceAbsorptanceProduct(0.87)
performance.setCladdingNormalTransmittanceAbsorptanceProduct(0.85)
performance.setFractionofCollectorGrossAreaCoveredbyPVModule(0.85)
performance.setFractionofPVCellAreatoPVModuleArea(0.9)
performance.setPVModuleTopThermalResistance(0.0044)
performance.setPVModuleBottomThermalResistance(0.0039)
performance.setPVModuleFrontLongwaveEmissivity(0.85)
performance.setPVModuleBackLongwaveEmissivity(0.9)
performance.setGlassThickness(0.002)
performance.setGlassRefractionIndex(1.526)
performance.setGlassExtinctionCoefficient(4.0)

add_out_vars = False
if add_out_vars:
    for var in collector.outputVariableNames():
        openstudio.model.OutputVariable(var, model)


# add a storage tank to the swh loop
mixed_swh_loop.addSupplyBranchForComponent(storage_water_heater)

# add instantaneous swh water heater after the storage tank
swh_water_heater = openstudio.model.WaterHeaterMixed(model)
swh_water_heater.addToNode(mixed_swh_loop.supplyOutletNode())

# add a tempering valve
tempering_valve = openstudio.model.TemperingValve(model)
mixed_swh_loop.addSupplyBranchForComponent(tempering_valve)
tempering_valve.setStream2SourceNode(storage_water_heater.supplyOutletmodelObject().get().to_Node().get())
tempering_valve.setTemperatureSetpointNode(swh_water_heater.supplyOutletmodelObject().get().to_Node().get())
tempering_valve.setPumpOutletNode(swh_pump.outletmodelObject().get().to_Node().get())

# save the OpenStudio model (.osm)
model.save_openstudio_osm(osm_save_directory=None, osm_name="in.osm")
