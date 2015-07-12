
require 'openstudio'
require 'lib/baseline_model'

model = BaselineModel.new

#make a 2 story, 100m X 50m, 10 zone core/perimeter building
model.add_geometry({"length" => 100,
              "width" => 50,
              "num_floors" => 1,
              "floor_to_floor_height" => 4,
              "plenum_height" => 1,
              "perimeter_zone_depth" => 3})

#add windows at a 40% window-to-wall ratio
model.add_windows({"wwr" => 0.4,
                  "offset" => 1,
                  "application_type" => "Above Floor"})

always_on = model.alwaysOnDiscreteSchedule()

zones = model.getThermalZones().sort
        
#add thermostats
model.add_thermostats({"heating_setpoint" => 20,
                      "cooling_setpoint" => 30})

# get the heating and cooling setpoint schedule to use later 
thermostat = model.getThermostatSetpointDualSetpoints[0]
heating_schedule = thermostat.heatingSetpointTemperatureSchedule().get
cooling_schedule = thermostat.coolingSetpointTemperatureSchedule().get

# Unitary System test
zone = zones.sort[0]

staged_thermostat = OpenStudio::Model::ZoneControlThermostatStagedDualSetpoint.new(model)
staged_thermostat.setHeatingTemperatureSetpointSchedule(heating_schedule)
staged_thermostat.setNumberofHeatingStages(2)
staged_thermostat.setCoolingTemperatureSetpointBaseSchedule(cooling_schedule)
staged_thermostat.setNumberofCoolingStages(2)
zone.setThermostat(staged_thermostat)

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
cooling_curve_1_alt = cooling_curve_1.clone().to_CurveBiquadratic.get

cooling_curve_2 = OpenStudio::Model::CurveQuadratic.new(model)
cooling_curve_2.setCoefficient1Constant(0.8)
cooling_curve_2.setCoefficient2x(0.2)
cooling_curve_2.setCoefficient3xPOW2(0.0)
cooling_curve_2.setMinimumValueofx(0.5)
cooling_curve_2.setMaximumValueofx(1.5)
cooling_curve_2_alt = cooling_curve_2.clone().to_CurveQuadratic.get

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
cooling_curve_3_alt = cooling_curve_3.clone().to_CurveBiquadratic.get

cooling_curve_4 = OpenStudio::Model::CurveQuadratic.new(model)
cooling_curve_4.setCoefficient1Constant(1.156)
cooling_curve_4.setCoefficient2x(-0.1816)
cooling_curve_4.setCoefficient3xPOW2(0.0256)
cooling_curve_4.setMinimumValueofx(0.5)
cooling_curve_4.setMaximumValueofx(1.5)
cooling_curve_4_alt = cooling_curve_4.clone().to_CurveQuadratic.get

cooling_curve_5 = OpenStudio::Model::CurveQuadratic.new(model)
cooling_curve_5.setCoefficient1Constant(0.75)
cooling_curve_5.setCoefficient2x(0.25)
cooling_curve_5.setCoefficient3xPOW2(0.0)
cooling_curve_5.setMinimumValueofx(0.0)
cooling_curve_5.setMaximumValueofx(1.0)
cooling_curve_5_alt = cooling_curve_5.clone().to_CurveQuadratic.get

cooling_curve_6 = OpenStudio::Model::CurveBiquadratic.new(model)
cooling_curve_6.setCoefficient1Constant(1)
cooling_curve_6.setCoefficient2x(0.0)
cooling_curve_6.setCoefficient3xPOW2(0.0)
cooling_curve_6.setCoefficient4y(0.0)
cooling_curve_6.setCoefficient5yPOW2(0.0)
cooling_curve_6.setCoefficient6xTIMESY(0.0)
cooling_curve_6.setMinimumValueofx(0.0)
cooling_curve_6.setMaximumValueofx(0.0)
cooling_curve_6.setMinimumValueofy(0.0)
cooling_curve_6.setMaximumValueofy(0.0)
cooling_curve_6_alt = cooling_curve_6.clone().to_CurveBiquadratic.get

air_system = OpenStudio::Model::AirLoopHVAC.new(model)
supply_outlet_node = air_system.supplyOutletNode()

# Modify the sizing parameters for the air system
air_loop_sizing = air_system.sizingSystem
air_loop_sizing.setCentralHeatingDesignSupplyAirTemperature(OpenStudio.convert(104, "F", "C").get)

controllerOutdoorAir = OpenStudio::Model::ControllerOutdoorAir.new(model)
outdoorAirSystem = OpenStudio::Model::AirLoopHVACOutdoorAirSystem.new(model,controllerOutdoorAir)
outdoorAirSystem.addToNode(supply_outlet_node)

fan = OpenStudio::Model::FanConstantVolume.new(model,always_on)
heat = OpenStudio::Model::CoilHeatingGasMultiStage.new(model)
heat.setName("Multi Stage Gas Htg Coil")
heat_stage_1 = OpenStudio::Model::CoilHeatingGasMultiStageStageData.new(model)
heat_stage_2 = OpenStudio::Model::CoilHeatingGasMultiStageStageData.new(model)
heat.addStage(heat_stage_1)
heat.addStage(heat_stage_2)
cool = OpenStudio::Model::CoilCoolingDXMultiSpeed.new(model)
cool.setName("Multi Stage DX Clg Coil")
cool_stage_1 = OpenStudio::Model::CoilCoolingDXMultiSpeedStageData.new(model,
  cooling_curve_1,
  cooling_curve_2,
  cooling_curve_3,
  cooling_curve_4,
  cooling_curve_5,
  cooling_curve_6)
cool_stage_2 = OpenStudio::Model::CoilCoolingDXMultiSpeedStageData.new(model,
  cooling_curve_1_alt,
  cooling_curve_2_alt,
  cooling_curve_3_alt,
  cooling_curve_4_alt,
  cooling_curve_5_alt,
  cooling_curve_6_alt)
cool.addStage(cool_stage_1)
cool.addStage(cool_stage_2)
supp_heat = OpenStudio::Model::CoilHeatingElectric.new(model,always_on)
supp_heat.setName("Sup Elec Htg Coil")
unitary = OpenStudio::Model::AirLoopHVACUnitaryHeatPumpAirToAirMultiSpeed.new(model,fan,heat,cool,supp_heat)
unitary.addToNode(supply_outlet_node)
unitary.setControllingZoneorThermostatLocation(zone)

terminal = OpenStudio::Model::AirTerminalSingleDuctUncontrolled.new(model,always_on)
air_system.addBranchForZone(zone,terminal)

# Put all of the other zones on a system type 3
zones[1..-1].each do |z|
  air_system = OpenStudio::Model::addSystemType3(model).to_AirLoopHVAC.get
  air_system.addBranchForZone(z)
end
              
#assign constructions from a local library to the walls/windows/etc. in the model
model.set_constructions()

#set whole building space type; simplified 90.1-2004 Large Office Whole Building
model.set_space_type()  

#add design days to the model (Chicago)
model.add_design_days()
       
#save the OpenStudio model (.osm)
model.save_openstudio_osm({"osm_save_directory" => Dir.pwd,
                           "osm_name" => "out.osm"})
                           
