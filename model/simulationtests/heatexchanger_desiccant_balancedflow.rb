# frozen_string_literal: true

require 'openstudio'
require 'lib/baseline_model'

model = BaselineModel.new

# make a 2 story, 100m X 50m, 3 zone core building
model.add_geometry({ 'length' => 100,
                     'width' => 50,
                     'num_floors' => 2,
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

# add ASHRAE System type 03, PSZ-AC
model.add_hvac({ 'ashrae_sys_num' => '03' })

air_systems = model.getAirLoopHVACs

air_systems.each_with_index do |s, i|
  if i == 0
    hx_performance = OpenStudio::Model::HeatExchangerDesiccantBalancedFlowPerformanceDataType1.new(model)
    hx_performance.autosizeNominalAirFlowRate();
    hx_performance.autosizeNominalAirFaceVelocity();
    hx_performance.setNominalElectricPower(0);
    hx_performance.setTemperatureEquationCoefficient1(-7.18302E+00)
    hx_performance.setTemperatureEquationCoefficient2(-1.84967E+02)
    hx_performance.setTemperatureEquationCoefficient3(1.00051E+00)
    hx_performance.setTemperatureEquationCoefficient4(1.16033E+04)
    hx_performance.setTemperatureEquationCoefficient5(-5.07550E+01)
    hx_performance.setTemperatureEquationCoefficient6(-1.68467E-02)
    hx_performance.setTemperatureEquationCoefficient7(5.82213E+01)
    hx_performance.setTemperatureEquationCoefficient8(5.98863E-01)
    hx_performance.setMinimumRegenerationInletAirHumidityRatioforTemperatureEquation(0.007143)
    hx_performance.setMaximumRegenerationInletAirHumidityRatioforTemperatureEquation(0.024286)
    hx_performance.setMinimumRegenerationInletAirTemperatureforTemperatureEquation(17.83333)
    hx_performance.setMaximumRegenerationInletAirTemperatureforTemperatureEquation(48.88889)
    hx_performance.setMinimumProcessInletAirHumidityRatioforTemperatureEquation(0.005000)
    hx_performance.setMaximumProcessInletAirHumidityRatioforTemperatureEquation(0.015714)
    hx_performance.setMinimumProcessInletAirTemperatureforTemperatureEquation(4.583333)
    hx_performance.setMaximumProcessInletAirTemperatureforTemperatureEquation(21.83333)
    hx_performance.setMinimumRegenerationAirVelocityforTemperatureEquation(2.286)
    hx_performance.setMaximumRegenerationAirVelocityforTemperatureEquation(4.826)
    hx_performance.setMinimumRegenerationOutletAirTemperatureforTemperatureEquation(16.66667)
    hx_performance.setMaximumRegenerationOutletAirTemperatureforTemperatureEquation(46.11111)
    hx_performance.setMinimumRegenerationInletAirRelativeHumidityforTemperatureEquation(10.0)
    hx_performance.setMaximumRegenerationInletAirRelativeHumidityforTemperatureEquation(100.0)
    hx_performance.setMinimumProcessInletAirRelativeHumidityforTemperatureEquation(80.0)
    hx_performance.setMaximumProcessInletAirRelativeHumidityforTemperatureEquation(100.0)
    hx_performance.setHumidityRatioEquationCoefficient1(3.13878E-03)
    hx_performance.setHumidityRatioEquationCoefficient2(1.09689E+00)
    hx_performance.setHumidityRatioEquationCoefficient3(-2.63341E-05)
    hx_performance.setHumidityRatioEquationCoefficient4(-6.33885E+00)
    hx_performance.setHumidityRatioEquationCoefficient5(9.38196E-03)
    hx_performance.setHumidityRatioEquationCoefficient6(5.21186E-05)
    hx_performance.setHumidityRatioEquationCoefficient7(6.70354E-02)
    hx_performance.setHumidityRatioEquationCoefficient8(-1.60823E-04)
    hx_performance.setMinimumRegenerationInletAirHumidityRatioforHumidityRatioEquation(0.007143)
    hx_performance.setMaximumRegenerationInletAirHumidityRatioforHumidityRatioEquation(0.024286)
    hx_performance.setMinimumRegenerationInletAirTemperatureforHumidityRatioEquation(17.83333)
    hx_performance.setMaximumRegenerationInletAirTemperatureforHumidityRatioEquation(48.88889)
    hx_performance.setMinimumProcessInletAirHumidityRatioforHumidityRatioEquation(0.005000)
    hx_performance.setMaximumProcessInletAirHumidityRatioforHumidityRatioEquation(0.015714)
    hx_performance.setMinimumProcessInletAirTemperatureforHumidityRatioEquation(4.583333)
    hx_performance.setMaximumProcessInletAirTemperatureforHumidityRatioEquation(21.83333)
    hx_performance.setMinimumRegenerationAirVelocityforHumidityRatioEquation(2.286)
    hx_performance.setMaximumRegenerationAirVelocityforHumidityRatioEquation(4.826)
    hx_performance.setMinimumRegenerationOutletAirHumidityRatioforHumidityRatioEquation(0.007811)
    hx_performance.setMaximumRegenerationOutletAirHumidityRatioforHumidityRatioEquation(0.026707)
    hx_performance.setMinimumRegenerationInletAirRelativeHumidityforHumidityRatioEquation(10.0)
    hx_performance.setMaximumRegenerationInletAirRelativeHumidityforHumidityRatioEquation(100.0)
    hx_performance.setMinimumProcessInletAirRelativeHumidityforHumidityRatioEquation(80.0)
    hx_performance.setMaximumProcessInletAirRelativeHumidityforHumidityRatioEquation(100.0)
    hx = OpenStudio::Model::HeatExchangerDesiccantBalancedFlow.new(model, hx_performance)
    availability_schedule = OpenStudio::Model::ScheduleConstant.new(model)
    availability_schedule.setValue(0.5)
    hx.setAvailabilitySchedule(availability_schedule)
    hx.setEconomizerLockout(false)    
  elsif i == 1 # try convenience ctor
    hx = OpenStudio::Model::HeatExchangerDesiccantBalancedFlow.new(model)
    availability_schedule = OpenStudio::Model::ScheduleConstant.new(model)
    availability_schedule.setValue(0.75)
    hx.setAvailabilitySchedule(availability_schedule)
    hx.setEconomizerLockout(true)
    hx_performance = OpenStudio::Model::HeatExchangerDesiccantBalancedFlowPerformanceDataType1.new(model)
    hx_performance.setNominalAirFlowRate(1.0)
    hx_performance.setNominalAirFaceVelocity(2.0)
    hx_performance.setNominalElectricPower(0);
    hx_performance.setTemperatureEquationCoefficient1(-7.18302E+00)
    hx_performance.setTemperatureEquationCoefficient2(-1.84967E+02)
    hx_performance.setTemperatureEquationCoefficient3(1.00051E+00)
    hx_performance.setTemperatureEquationCoefficient4(1.16033E+04)
    hx_performance.setTemperatureEquationCoefficient5(-5.07550E+01)
    hx_performance.setTemperatureEquationCoefficient6(-1.68467E-02)
    hx_performance.setTemperatureEquationCoefficient7(5.82213E+01)
    hx_performance.setTemperatureEquationCoefficient8(5.98863E-01)
    hx_performance.setMinimumRegenerationInletAirHumidityRatioforTemperatureEquation(0.007143)
    hx_performance.setMaximumRegenerationInletAirHumidityRatioforTemperatureEquation(0.024286)
    hx_performance.setMinimumRegenerationInletAirTemperatureforTemperatureEquation(17.83333)
    hx_performance.setMaximumRegenerationInletAirTemperatureforTemperatureEquation(48.88889)
    hx_performance.setMinimumProcessInletAirHumidityRatioforTemperatureEquation(0.005000)
    hx_performance.setMaximumProcessInletAirHumidityRatioforTemperatureEquation(0.015714)
    hx_performance.setMinimumProcessInletAirTemperatureforTemperatureEquation(4.583333)
    hx_performance.setMaximumProcessInletAirTemperatureforTemperatureEquation(21.83333)
    hx_performance.setMinimumRegenerationAirVelocityforTemperatureEquation(2.286)
    hx_performance.setMaximumRegenerationAirVelocityforTemperatureEquation(4.826)
    hx_performance.setMinimumRegenerationOutletAirTemperatureforTemperatureEquation(16.66667)
    hx_performance.setMaximumRegenerationOutletAirTemperatureforTemperatureEquation(46.11111)
    hx_performance.setMinimumRegenerationInletAirRelativeHumidityforTemperatureEquation(10.0)
    hx_performance.setMaximumRegenerationInletAirRelativeHumidityforTemperatureEquation(100.0)
    hx_performance.setMinimumProcessInletAirRelativeHumidityforTemperatureEquation(80.0)
    hx_performance.setMaximumProcessInletAirRelativeHumidityforTemperatureEquation(100.0)
    hx_performance.setHumidityRatioEquationCoefficient1(3.13878E-03)
    hx_performance.setHumidityRatioEquationCoefficient2(1.09689E+00)
    hx_performance.setHumidityRatioEquationCoefficient3(-2.63341E-05)
    hx_performance.setHumidityRatioEquationCoefficient4(-6.33885E+00)
    hx_performance.setHumidityRatioEquationCoefficient5(9.38196E-03)
    hx_performance.setHumidityRatioEquationCoefficient6(5.21186E-05)
    hx_performance.setHumidityRatioEquationCoefficient7(6.70354E-02)
    hx_performance.setHumidityRatioEquationCoefficient8(-1.60823E-04)
    hx_performance.setMinimumRegenerationInletAirHumidityRatioforHumidityRatioEquation(0.007143)
    hx_performance.setMaximumRegenerationInletAirHumidityRatioforHumidityRatioEquation(0.024286)
    hx_performance.setMinimumRegenerationInletAirTemperatureforHumidityRatioEquation(17.83333)
    hx_performance.setMaximumRegenerationInletAirTemperatureforHumidityRatioEquation(48.88889)
    hx_performance.setMinimumProcessInletAirHumidityRatioforHumidityRatioEquation(0.005000)
    hx_performance.setMaximumProcessInletAirHumidityRatioforHumidityRatioEquation(0.015714)
    hx_performance.setMinimumProcessInletAirTemperatureforHumidityRatioEquation(4.583333)
    hx_performance.setMaximumProcessInletAirTemperatureforHumidityRatioEquation(21.83333)
    hx_performance.setMinimumRegenerationAirVelocityforHumidityRatioEquation(2.286)
    hx_performance.setMaximumRegenerationAirVelocityforHumidityRatioEquation(4.826)
    hx_performance.setMinimumRegenerationOutletAirHumidityRatioforHumidityRatioEquation(0.007811)
    hx_performance.setMaximumRegenerationOutletAirHumidityRatioforHumidityRatioEquation(0.026707)
    hx_performance.setMinimumRegenerationInletAirRelativeHumidityforHumidityRatioEquation(10.0)
    hx_performance.setMaximumRegenerationInletAirRelativeHumidityforHumidityRatioEquation(100.0)
    hx_performance.setMinimumProcessInletAirRelativeHumidityforHumidityRatioEquation(80.0)
    hx_performance.setMaximumProcessInletAirRelativeHumidityforHumidityRatioEquation(100.0)
    hx.setHeatExchangerPerformance(hx_performance)
  end

  oa_node = s.airLoopHVACOutdoorAirSystem.get.outboardOANode.get

  hx.addToNode(oa_node)

  spm = OpenStudio::Model::SetpointManagerMixedAir.new(model)

  outlet_node = hx.primaryAirOutletModelObject.get.to_Node.get

  spm.addToNode(outlet_node)
end

# save the OpenStudio model (.osm)
model.save_openstudio_osm({ 'osm_save_directory' => Dir.pwd,
                            'osm_name' => 'in.osm' })
