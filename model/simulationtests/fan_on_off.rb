
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

#add ASHRAE System type 07, VAV w/ Reheat
model.add_hvac({"ashrae_sys_num" => '07'})

unitaryAirLoopHVAC = OpenStudio::Model::AirLoopHVAC.new(model)
unitaryAirLoopHVAC.setName("Unitary AirLoopHVAC")
schedule = model.alwaysOnDiscreteSchedule()
fan = OpenStudio::Model::FanOnOff.new(model,schedule)

heating_curve_1 = OpenStudio::Model::CurveCubic.new(model)
heating_curve_1.setCoefficient1Constant(0.758746)
heating_curve_1.setCoefficient2x(0.027626)
heating_curve_1.setCoefficient3xPOW2(0.000148716)
heating_curve_1.setCoefficient4xPOW3(0.0000034992)
heating_curve_1.setMinimumValueofx(-20.0)
heating_curve_1.setMaximumValueofx(20.0)

heating_curve_2 = OpenStudio::Model::CurveCubic.new(model)
heating_curve_2.setCoefficient1Constant(0.84)
heating_curve_2.setCoefficient2x(0.16)
heating_curve_2.setCoefficient3xPOW2(0.0)
heating_curve_2.setCoefficient4xPOW3(0.0)
heating_curve_2.setMinimumValueofx(0.5)
heating_curve_2.setMaximumValueofx(1.5)

heating_curve_3 = OpenStudio::Model::CurveCubic.new(model)
heating_curve_3.setCoefficient1Constant(1.19248)
heating_curve_3.setCoefficient2x(-0.0300438)
heating_curve_3.setCoefficient3xPOW2(0.00103745)
heating_curve_3.setCoefficient4xPOW3(-0.000023328)
heating_curve_3.setMinimumValueofx(-20.0)
heating_curve_3.setMaximumValueofx(20.0)

heating_curve_4 = OpenStudio::Model::CurveQuadratic.new(model)
heating_curve_4.setCoefficient1Constant(1.3824)
heating_curve_4.setCoefficient2x(-0.4336)
heating_curve_4.setCoefficient3xPOW2(0.0512)
heating_curve_4.setMinimumValueofx(0.0)
heating_curve_4.setMaximumValueofx(1.0)

heating_curve_5 = OpenStudio::Model::CurveQuadratic.new(model)
heating_curve_5.setCoefficient1Constant(0.75)
heating_curve_5.setCoefficient2x(0.25)
heating_curve_5.setCoefficient3xPOW2(0.0)
heating_curve_5.setMinimumValueofx(0.0)
heating_curve_5.setMaximumValueofx(1.0)

heating_coil = OpenStudio::Model::CoilHeatingDXSingleSpeed.new(model, schedule, heating_curve_1, heating_curve_2, heating_curve_3, heating_curve_4, heating_curve_5)

cooling_curve_1 = OpenStudio::Model::CurveBiquadratic.new(model)
cooling_curve_1.setCoefficient1Constant(0.766956)
cooling_curve_1.setCoefficient2x(0.0107756)
cooling_curve_1.setCoefficient3xPOW2(-0.0000414703)
cooling_curve_1.setCoefficient4y(0.00134961)
cooling_curve_1.setCoefficient5yPOW2(-0.000261144)
cooling_curve_1.setCoefficient6xTIMESY(0.000457488)
cooling_curve_1.setMinimumValueofx(17.0)
cooling_curve_1.setMaximumValueofx(22.0)
cooling_curve_1.setMinimumValueofy(13.0)
cooling_curve_1.setMaximumValueofy(46.0)

cooling_curve_2 = OpenStudio::Model::CurveQuadratic.new(model)
cooling_curve_2.setCoefficient1Constant(0.8)
cooling_curve_2.setCoefficient2x(0.2)
cooling_curve_2.setCoefficient3xPOW2(0.0)
cooling_curve_2.setMinimumValueofx(0.5)
cooling_curve_2.setMaximumValueofx(1.5)

cooling_curve_3 = OpenStudio::Model::CurveBiquadratic.new(model)
cooling_curve_3.setCoefficient1Constant(0.297145)
cooling_curve_3.setCoefficient2x(0.0430933)
cooling_curve_3.setCoefficient3xPOW2(-0.000748766)
cooling_curve_3.setCoefficient4y(0.00597727)
cooling_curve_3.setCoefficient5yPOW2(0.000482112)
cooling_curve_3.setCoefficient6xTIMESY(-0.000956448)
cooling_curve_3.setMinimumValueofx(17.0)
cooling_curve_3.setMaximumValueofx(22.0)
cooling_curve_3.setMinimumValueofy(13.0)
cooling_curve_3.setMaximumValueofy(46.0)

cooling_curve_4 = OpenStudio::Model::CurveQuadratic.new(model)
cooling_curve_4.setCoefficient1Constant(1.156)
cooling_curve_4.setCoefficient2x(-0.1816)
cooling_curve_4.setCoefficient3xPOW2(0.0256)
cooling_curve_4.setMinimumValueofx(0.5)
cooling_curve_4.setMaximumValueofx(1.5)

cooling_curve_5 = OpenStudio::Model::CurveQuadratic.new(model)
cooling_curve_5.setCoefficient1Constant(0.75)
cooling_curve_5.setCoefficient2x(0.25)
cooling_curve_5.setCoefficient3xPOW2(0.0)
cooling_curve_5.setMinimumValueofx(0.0)
cooling_curve_5.setMaximumValueofx(1.0)

cooling_coil = OpenStudio::Model::CoilCoolingDXSingleSpeed.new(model, schedule, cooling_curve_1, cooling_curve_2, cooling_curve_3, cooling_curve_4, cooling_curve_5)
supp_heating_coil = OpenStudio::Model::CoilHeatingElectric.new(model, schedule)
unitary = OpenStudio::Model::AirLoopHVACUnitaryHeatPumpAirToAir.new(model, schedule, fan, heating_coil, cooling_coil, supp_heating_coil)

supplyOutletNode = unitaryAirLoopHVAC.supplyOutletNode
unitary.addToNode(supplyOutletNode)

# In order to produce more consistent results between different runs,
# we sort the zones by names
zones = model.getThermalZones.sort_by{|z| z.name.to_s}


# In order to produce more consistent results between different runs,
# We ensure we do get the same object each time
chillers = model.getChillerElectricEIRs.sort_by{|c| c.name.to_s}
boilers = model.getBoilerHotWaters.sort_by{|c| c.name.to_s}

cooling_loop = chillers.first.plantLoop.get
heating_loop = boilers.first.plantLoop.get

zones.each_with_index do |z, i|
  if i == 0
    schedule = model.alwaysOnDiscreteSchedule()
    fan = OpenStudio::Model::FanOnOff.new(model,schedule)
    heating_coil = OpenStudio::Model::CoilHeatingWater.new(model, schedule)
    cooling_coil = OpenStudio::Model::CoilCoolingWater.new(model, schedule)
    four_pipe_fan_coil = OpenStudio::Model::ZoneHVACFourPipeFanCoil.new(model, schedule, fan, cooling_coil, heating_coil)
    four_pipe_fan_coil.addToThermalZone(z)
    heating_loop.addDemandBranchForComponent(heating_coil)
    cooling_loop.addDemandBranchForComponent(cooling_coil)
  elsif i == 1
    schedule = model.alwaysOnDiscreteSchedule()
    fan = OpenStudio::Model::FanOnOff.new(model,schedule)
    heating_coil = OpenStudio::Model::CoilHeatingWaterToAirHeatPumpEquationFit.new(model)
    cooling_coil = OpenStudio::Model::CoilCoolingWaterToAirHeatPumpEquationFit.new(model)
    supp_heating_coil = OpenStudio::Model::CoilHeatingElectric.new(model, schedule)
    water_to_air_heat_pump = OpenStudio::Model::ZoneHVACWaterToAirHeatPump.new(model, schedule, fan, heating_coil, cooling_coil, supp_heating_coil)
    water_to_air_heat_pump.addToThermalZone(z)
    heating_loop.addDemandBranchForComponent(heating_coil)
    cooling_loop.addDemandBranchForComponent(cooling_coil)
  elsif i == 2
    thermal_zone_vector = OpenStudio::Model::ThermalZoneVector.new()
    thermal_zone_vector << z
    hvac = OpenStudio::Model::addSystemType1(model, thermal_zone_vector)
    schedule = model.alwaysOnDiscreteSchedule()
    fan = OpenStudio::Model::FanOnOff.new(model,schedule)
    ptacs = model.getZoneHVACPackagedTerminalAirConditioners
    fan_cv = ptacs[0].supplyAirFan
    ptacs[0].setSupplyAirFan(fan)
    fan_cv.remove
  elsif i == 3
    thermal_zone_vector = OpenStudio::Model::ThermalZoneVector.new()
    thermal_zone_vector << z
    hvac = OpenStudio::Model::addSystemType2(model, thermal_zone_vector)
    schedule = model.alwaysOnDiscreteSchedule()
    fan = OpenStudio::Model::FanOnOff.new(model,schedule)
    pthps = model.getZoneHVACPackagedTerminalHeatPumps
    fan_cv = pthps[0].supplyAirFan
    pthps[0].setSupplyAirFan(fan)
    fan_cv.remove
  elsif i == 4
    air_loop = z.airLoopHVAC.get
    air_loop.removeBranchForZone(z)

    schedule = model.alwaysOnDiscreteSchedule()
    # Starting with E 9.0.0, Uncontrolled is deprecated and replaced with
    # ConstantVolume:NoReheat
    if Gem::Version.new(OpenStudio::openStudioVersion) >= Gem::Version.new("2.7.0")
      new_terminal = OpenStudio::Model::AirTerminalSingleDuctConstantVolumeNoReheat.new(model, schedule)
    else
      new_terminal = OpenStudio::Model::AirTerminalSingleDuctUncontrolled.new(model, schedule)
    end

    unitaryAirLoopHVAC.addBranchForZone(z,new_terminal.to_StraightComponent)
    unitary.setControllingZone(z)
  end
end

#add thermostats
model.add_thermostats({"heating_setpoint" => 24,
                      "cooling_setpoint" => 28})

#assign constructions from a local library to the walls/windows/etc. in the model
model.set_constructions()

#set whole building space type; simplified 90.1-2004 Large Office Whole Building
model.set_space_type()

#add design days to the model (Chicago)
model.add_design_days()

#save the OpenStudio model (.osm)
model.save_openstudio_osm({"osm_save_directory" => Dir.pwd,
                           "osm_name" => "in.osm"})

