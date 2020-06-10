
require 'openstudio'
require 'lib/baseline_model'

m = BaselineModel.new

#make a 2 story, 100m X 50m, 10 zone core/perimeter building
m.add_geometry({"length" => 100,
                "width" => 50,
                "num_floors" => 2,
                "floor_to_floor_height" => 4,
                "plenum_height" => 1,
                "perimeter_zone_depth" => 3})

#add windows at a 40% window-to-wall ratio
m.add_windows({"wwr" => 0.4,
               "offset" => 1,
               "application_type" => "Above Floor"})

#add thermostats
m.add_thermostats({"heating_setpoint" => 24,
                   "cooling_setpoint" => 28})

#assign constructions from a local library to the walls/windows/etc. in the model
m.set_constructions()

#set whole building space type; simplified 90.1-2004 Large Office Whole Building
m.set_space_type()

#add design days to the model (Chicago)
m.add_design_days()

#add ASHRAE System type 07, VAV w/ Reheat
m.add_hvac({"ashrae_sys_num" => '07'})

# In order to produce more consistent results between different runs,
# we sort the zones by names
zones = m.getThermalZones.sort_by{|z| z.name.to_s}

# CoilCoolingDXCurveFitSpeed
curve_fit_speed_1 = OpenStudio::Model::CoilCoolingDXCurveFitSpeed.new(m)

# CoilCoolingDXCurveFitOperatingMode
curve_fit_operating_mode = OpenStudio::Model::CoilCoolingDXCurveFitOperatingMode.new(m)
curve_fit_operating_mode.addSpeed(curve_fit_speed_1)

# CoilCoolingDXCurveFitPerformance
curve_fit_performance = OpenStudio::Model::CoilCoolingDXCurveFitPerformance.new(m, curve_fit_operating_mode)

# CoilCoolingDX
coil = OpenStudio::Model::CoilCoolingDX.new(m, curve_fit_performance)

# AirLoopHVACUnitarySystem
air_loop_unitary = OpenStudio::Model::AirLoopHVACUnitarySystem.new(m)

# AirLoopHVAC
air_loop = OpenStudio::Model::AirLoopHVAC.new(m)
air_supply_inlet_node = air_loop.supplyInletNode

air_loop_unitary.addToNode(air_supply_inlet_node)
air_loop_unitary.setCoolingCoil(coil)
air_loop_unitary.setControllingZoneorThermostatLocation(zones[0])

#save the OpenStudio model (.osm)
m.save_openstudio_osm({"osm_save_directory" => Dir.pwd,
                       "osm_name" => "in.osm"})
