
require 'openstudio'
require_relative 'lib/baseline_model'

model = BaselineModel.new

#Schedule Ruleset
defrost_sch = OpenStudio::Model::ScheduleRuleset.new(model)
defrost_sch.setName("Refrigeration Defrost Schedule")
#All other days
defrost_sch.defaultDaySchedule.setName("Refrigeration Defrost Schedule Default")
defrost_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,4,0,0), 0)
defrost_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,4,45,0), 1)
defrost_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,8,0,0), 0)
defrost_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,8,45,0), 1)
defrost_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,12,0,0), 0)
defrost_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,12,45,0), 1)
defrost_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,16,0,0), 0)
defrost_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,16,45,0), 1)
defrost_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,20,0,0), 0)
defrost_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,20,45,0), 1)
defrost_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,24,0,0), 0)

def add_case(model, thermal_zone, defrost_sch)
  ref_case = OpenStudio::Model::RefrigerationCase.new(model, defrost_sch)
  ref_case.setThermalZone(thermal_zone)
  return ref_case
end

def add_walkin(model, thermal_zone, defrost_sch)
  ref_walkin = OpenStudio::Model::RefrigerationWalkIn.new(model, defrost_sch)
  zone_boundaries = ref_walkin.zoneBoundaries()
  zone_boundaries[0].setThermalZone(thermal_zone)
  return ref_walkin
end

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

#add thermostats
model.add_thermostats({"heating_setpoint" => 20,
                      "cooling_setpoint" => 28})

#assign constructions from a local library to the walls/windows/etc. in the model
model.set_constructions()

#set whole building space type; simplified 90.1-2004 Large Office Whole Building
model.set_space_type()

#add design days to the model (Chicago)
model.add_design_days()

# In order to produce more consistent results between different runs,
# we sort the zones by names
zones = model.getThermalZones.sort_by{|z| z.name.to_s}

boilers = model.getBoilerHotWaters.sort_by{|c| c.name.to_s}
heating_loop = boilers.first.plantLoop.get

i = 0
therm_zone = nil
ref_sys1 = nil
cascade_condenser = nil

zones.each do |z|
  if i == 0
    therm_zone = z
    ref_sys1 = OpenStudio::Model::RefrigerationSystem.new(model)
    ref_sys1.addCase(add_case(model, z, defrost_sch))
    ref_sys1.addWalkin(add_walkin(model, z, defrost_sch))
    ref_sys1.addCompressor(OpenStudio::Model::RefrigerationCompressor.new(model))
    condenser = OpenStudio::Model::RefrigerationCondenserAirCooled.new(model)
    ref_sys1.setRefrigerationCondenser(condenser)
    ref_sys1.setSuctionPipingZone(z)
    desuperheater = OpenStudio::Model::CoilHeatingDesuperheater.new(model)
    desuperheater.setHeatingSource(condenser)
    air_loop = z.airLoopHVAC.get
    coilCoolingWaters = air_loop.supplyComponents(OpenStudio::IddObjectType.new("OS:Coil:Cooling:Water"))
    setpointMMA1 = OpenStudio::Model::SetpointManagerMixedAir.new(model)
    node = coilCoolingWaters.first.to_CoilCoolingWater.get.airOutletModelObject().get.to_Node.get
    desuperheater.addToNode(node)
    node = desuperheater.outletModelObject().get.to_Node.get
    setpointMMA1.addToNode(node)
  elsif i == 1
    ref_sys2 = OpenStudio::Model::RefrigerationSystem.new(model)
    ref_sys2.addCase(add_case(model, z, defrost_sch))
    ref_case_2 = add_case(model, z, defrost_sch)
    ref_case_2.setDurationofDefrostCycle(25)
    ref_case_2.setDripDownTime(5)
    ref_case_2.setDefrost1StartTime(OpenStudio::Time.new(0,1,15))
    ref_case_2.setDefrost2StartTime(OpenStudio::Time.new(0,4,16))
    ref_case_2.setDefrost3StartTime(OpenStudio::Time.new(0,7,17))
    ref_case_2.setDefrost4StartTime(OpenStudio::Time.new(0,10,18))
    ref_case_2.setDefrost5StartTime(OpenStudio::Time.new(0,14,19))
    ref_case_2.setDefrost6StartTime(OpenStudio::Time.new(0,17,20))
    ref_case_2.setDefrost7StartTime(OpenStudio::Time.new(0,20,21))
    ref_case_2.setDefrost8StartTime(OpenStudio::Time.new(0,23,22))
    ref_case_3 = add_case(model, z, defrost_sch)
    ref_case_3.setUnitType("NumberOfDoors")
    ref_case_3.setNumberOfDoors(10)
    ref_case_3.setCaseLength(10)
    ref_case_3.setRatedTotalCoolingCapacityperDoor(2000)
    ref_case_3.setStandardCaseFanPowerperDoor(80)
    ref_case_3.setOperatingCaseFanPowerperDoor(80)
    ref_case_3.setStandardCaseLightingPowerperDoor(100)
    ref_case_3.setInstalledCaseLightingPowerperDoor(100)
    ref_case_3.setCaseAntiSweatHeaterPowerperDoor(20)
    ref_case_3.setMinimumAntiSweatHeaterPowerperDoor(20)
    ref_case_3.setCaseDefrostPowerperDoor(150)
    ref_sys2.addCase(ref_case_2)
    ref_sys2.addCase(ref_case_3)
    ref_sys2.addWalkin(add_walkin(model, z, defrost_sch))
    ref_walkin_2 = add_walkin(model, z, defrost_sch)
    ref_walkin_2.setDurationofDefrostCycle(25)
    ref_walkin_2.setDripDownTime(5)
    ref_walkin_2.setDefrost1StartTime(OpenStudio::Time.new(0,1,15))
    ref_walkin_2.setDefrost2StartTime(OpenStudio::Time.new(0,4,16))
    ref_walkin_2.setDefrost3StartTime(OpenStudio::Time.new(0,7,17))
    ref_walkin_2.setDefrost4StartTime(OpenStudio::Time.new(0,10,18))
    ref_walkin_2.setDefrost5StartTime(OpenStudio::Time.new(0,14,19))
    ref_walkin_2.setDefrost6StartTime(OpenStudio::Time.new(0,17,20))
    ref_walkin_2.setDefrost7StartTime(OpenStudio::Time.new(0,20,21))
    ref_walkin_2.setDefrost8StartTime(OpenStudio::Time.new(0,23,22))
    ref_sys2.addWalkin(ref_walkin_2)
    ref_sys2.addWalkin(add_walkin(model, z, defrost_sch))
    ref_sys2.addCompressor(OpenStudio::Model::RefrigerationCompressor.new(model))
    ref_sys2.addHighStageCompressor(OpenStudio::Model::RefrigerationCompressor.new(model))
    ref_sys2.setRefrigerationCondenser(OpenStudio::Model::RefrigerationCondenserEvaporativeCooled.new(model))
    ref_sys2.setSuctionPipingZone(z)
    ref_sys2.setIntercoolerType("Shell-and-Coil Intercooler")
    mech_subcooler = OpenStudio::Model::RefrigerationSubcoolerMechanical.new(model)
    mech_subcooler.setCapacityProvidingSystem(ref_sys1)
    ref_sys2.setMechanicalSubcooler(mech_subcooler)
    ref_sys2.setLiquidSuctionHeatExchangerSubcooler(OpenStudio::Model::RefrigerationSubcoolerLiquidSuction.new(model))
  elsif i == 2
    ref_sys3 = OpenStudio::Model::RefrigerationSystem.new(model)
    ref_sys3.addCase(add_case(model, z, defrost_sch))
    ref_sys3.addCase(add_case(model, z, defrost_sch))
    ref_sys3.addWalkin(add_walkin(model, z, defrost_sch))
    ref_sys3.addWalkin(add_walkin(model, z, defrost_sch))
    ref_sys3.addCompressor(OpenStudio::Model::RefrigerationCompressor.new(model))
    ref_sys3.addCompressor(OpenStudio::Model::RefrigerationCompressor.new(model))
    water_cooled_condenser = OpenStudio::Model::RefrigerationCondenserWaterCooled.new(model)
    cooling_tower = model.getCoolingTowerSingleSpeeds.first
    plant = cooling_tower.plantLoop.get
    plant.addDemandBranchForComponent(water_cooled_condenser)
    ref_sys3.setRefrigerationCondenser(water_cooled_condenser)
    ref_sys3.setSuctionPipingZone(z)

    water_tank = OpenStudio::Model::WaterHeaterMixed.new(model)
    water_tank.setAmbientTemperatureIndicator("ThermalZone")
    water_tank.setAmbientTemperatureThermalZone(z)
    heating_loop.addSupplyBranchForComponent(water_tank)
    #Schedule Ruleset
    setpointTemperatureSchedule = OpenStudio::Model::ScheduleRuleset.new(model)
    setpointTemperatureSchedule.setName("Setpoint Temperature Schedule")
    setpointTemperatureSchedule.defaultDaySchedule.setName("Setpoint Temperature Schedule Default")
    setpointTemperatureSchedule.defaultDaySchedule.addValue(OpenStudio::Time.new(0,24,0,0), 70)

    desuperheater = OpenStudio::Model::CoilWaterHeatingDesuperheater.new(model, setpointTemperatureSchedule)
    water_tank.setSetpointTemperatureSchedule(setpointTemperatureSchedule)
    desuperheater.addToHeatRejectionTarget(water_tank)
    desuperheater.setHeatingSource(water_cooled_condenser)
  elsif i == 3
    ref_sys4 = OpenStudio::Model::RefrigerationSystem.new(model)
    ref_sys4.addCase(add_case(model, z, defrost_sch))
    ref_sys4.addWalkin(add_walkin(model, z, defrost_sch))
    ref_sys4.addCompressor(OpenStudio::Model::RefrigerationCompressor.new(model))
    cascade_condenser = OpenStudio::Model::RefrigerationCondenserCascade.new(model)
    ref_sys4.setRefrigerationCondenser(cascade_condenser)
    ref_sys4.setSuctionPipingZone(z)

    ref_sys5 = OpenStudio::Model::RefrigerationSystem.new(model)
    ref_sys5.addCase(add_case(model, z, defrost_sch))
    ref_sys5.addWalkin(add_walkin(model, z, defrost_sch))
    ref_sys5.addCompressor(OpenStudio::Model::RefrigerationCompressor.new(model))
    ref_sys5.addCascadeCondenserLoad(cascade_condenser)

    secondary_sys = OpenStudio::Model::RefrigerationSecondarySystem.new(model)
    secondary_sys.addCase(add_case(model, z, defrost_sch))
    secondary_sys.addCase(add_case(model, z, defrost_sch))
    secondary_sys.addWalkin(add_walkin(model, z, defrost_sch))
    secondary_sys.addWalkin(add_walkin(model, z, defrost_sch))
    secondary_sys.setDistributionPipingZone(z)
    secondary_sys.setReceiverSeparatorZone(z)

    ref_sys5.addSecondarySystemLoad(secondary_sys)
    ref_sys5.setRefrigerationCondenser(OpenStudio::Model::RefrigerationCondenserAirCooled.new(model))
    ref_sys5.setSuctionPipingZone(z)
  elsif i == 4
    ref_sys6 = OpenStudio::Model::RefrigerationTranscriticalSystem.new(model)
    ref_sys6.addMediumTemperatureCase(add_case(model, z, defrost_sch))
    ref_sys6.addMediumTemperatureCase(add_case(model, z, defrost_sch))
    ref_sys6.addLowTemperatureCase(add_case(model, z, defrost_sch))
    ref_sys6.addLowTemperatureCase(add_case(model, z, defrost_sch))
    ref_sys6.addMediumTemperatureWalkin(add_walkin(model, z, defrost_sch))
    ref_sys6.addMediumTemperatureWalkin(add_walkin(model, z, defrost_sch))
    ref_sys6.addLowTemperatureWalkin(add_walkin(model, z, defrost_sch))
    ref_sys6.addLowTemperatureWalkin(add_walkin(model, z, defrost_sch))
    compressor1 = OpenStudio::Model::RefrigerationCompressor.new(model)
    compressor1.setTranscriticalCompressorPowerCurve(compressor1.refrigerationCompressorPowerCurve().clone().to_CurveBicubic.get)
    compressor1.setTranscriticalCompressorCapacityCurve(compressor1.refrigerationCompressorCapacityCurve().clone().to_CurveBicubic.get)
    compressor2 = OpenStudio::Model::RefrigerationCompressor.new(model)
    compressor2.setTranscriticalCompressorPowerCurve(compressor2.refrigerationCompressorPowerCurve().clone().to_CurveBicubic.get)
    compressor2.setTranscriticalCompressorCapacityCurve(compressor2.refrigerationCompressorCapacityCurve().clone().to_CurveBicubic.get)
    ref_sys6.addHighPressureCompressor(compressor1)
    ref_sys6.addLowPressureCompressor(compressor2)
    gas_cooler = OpenStudio::Model::RefrigerationGasCoolerAirCooled.new(model)
    # gas_cooler.setAirInletNode(z)
    ref_sys6.setRefrigerationGasCooler(gas_cooler)
    ref_sys6.setMediumTemperatureSuctionPipingZone(z)
    ref_sys6.setLowTemperatureSuctionPipingZone(z)
  end

  i = i + 1
end

#save the OpenStudio model (.osm)
model.save_openstudio_osm({"osm_save_directory" => Dir.pwd,
                           "osm_name" => "in.osm"})

