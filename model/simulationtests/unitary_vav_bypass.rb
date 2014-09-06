
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

schedule = model.alwaysOnDiscreteSchedule()

zones = model.getThermalZones()

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
cooling_curve_6.setCoefficient1Constant(0.42415)
cooling_curve_6.setCoefficient2x(0.04426)
cooling_curve_6.setCoefficient3xPOW2(-0.00042)
cooling_curve_6.setCoefficient4y(0.00333)
cooling_curve_6.setCoefficient5yPOW2(-0.00008)
cooling_curve_6.setCoefficient6xTIMESY(-0.00021)
cooling_curve_6.setMinimumValueofx(17.0)
cooling_curve_6.setMaximumValueofx(22.0)
cooling_curve_6.setMinimumValueofy(13.0)
cooling_curve_6.setMaximumValueofy(46.0)

cooling_curve_7 = OpenStudio::Model::CurveBiquadratic.new(model)
cooling_curve_7.setCoefficient1Constant(1.23649)
cooling_curve_7.setCoefficient2x(-0.02431)
cooling_curve_7.setCoefficient3xPOW2(0.00057)
cooling_curve_7.setCoefficient4y(-0.01434)
cooling_curve_7.setCoefficient5yPOW2(0.00063)
cooling_curve_7.setCoefficient6xTIMESY(-0.00038)
cooling_curve_7.setMinimumValueofx(17.0)
cooling_curve_7.setMaximumValueofx(22.0)
cooling_curve_7.setMinimumValueofy(13.0)
cooling_curve_7.setMaximumValueofy(46.0)

# Unitary System test 1
airLoop_1 = OpenStudio::Model::AirLoopHVAC.new(model)
airLoop_1_supplyNode = airLoop_1.supplyOutletNode()

fan_1 = OpenStudio::Model::FanConstantVolume.new(model, schedule)
cooling_coil_1 = OpenStudio::Model::CoilCoolingDXSingleSpeed.new(model, schedule, cooling_curve_1, cooling_curve_2, cooling_curve_3, cooling_curve_4, cooling_curve_5)
heating_coil_1 = OpenStudio::Model::CoilHeatingGas.new(model, schedule)
unitary_1 = OpenStudio::Model::AirLoopHVACUnitaryHeatCoolVAVChangeoverBypass.new(model,fan_1,cooling_coil_1,heating_coil_1)

unitary_1.addToNode(airLoop_1_supplyNode)

zones.each do |zone|
  terminal = OpenStudio::Model::AirTerminalSingleDuctVAVNoReheat.new(model, schedule)
  airLoop_1.addBranchForZone(zone, terminal)
end
   
# Request timeseries data for debugging
=begin
reporting_frequency = "hourly"
var_names << "Zone Thermostat Air Temperature"
var_names << "Zone Thermostat Heating Setpoint Temperature"
var_names << "Zone Air Terminal VAV Damper Position"
var_names << "System Node Temperature"
var_names << "System Node Mass Flow Rate"
var_names.each do |var_name|
  outputVariable = OpenStudio::Model::OutputVariable.new(var_name,model)
  outputVariable.setReportingFrequency(reporting_frequency)
end          
=end

   
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
                           "osm_name" => "out.osm"})
                           
