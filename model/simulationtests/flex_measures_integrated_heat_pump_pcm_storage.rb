# frozen_string_literal: true

require 'openstudio'
require 'lib/baseline_model'

model = BaselineModel.new

# make a 1 story, 100m X 50m, 10 zone core/perimeter building
model.add_geometry({ 'length' => 100,
                     'width' => 50,
                     'num_floors' => 1,
                     'floor_to_floor_height' => 4,
                     'plenum_height' => 1,
                     'perimeter_zone_depth' => 3 })

# add windows at a 40% window-to-wall ratio
model.add_windows({ 'wwr' => 0.4,
                    'offset' => 1,
                    'application_type' => 'Above Floor' })

# assign constructions from a local library to the walls/windows/etc. in the model
model.set_constructions

# set whole building space type; simplified 90.1-2004 Large Office Whole Building
model.set_space_type

# add design days to the model (Chicago)
model.add_design_days

# add thermostats
model.add_thermostats({ 'heating_setpoint' => 24,
                        'cooling_setpoint' => 28 })

# pick out on of the zone/system pairs and add a humidifier
# In order to produce more consistent results between different runs,
# we sort the zones by names
zones = model.getThermalZones.sort_by { |z| z.name.to_s }

zone = zones[0]

air_loop = OpenStudio::Model::AirLoopHVAC.new(model)
supplyOutletNode = air_loop.supplyOutletNode

chw_loop = OpenStudio::Model::PlantLoop.new(model)

schedule = model.alwaysOnDiscreteSchedule
fan = OpenStudio::Model::FanOnOff.new(model, schedule)
supp_heating_coil = OpenStudio::Model::CoilHeatingElectric.new(model, schedule)

heating_coil = OpenStudio::Model::CoilHeatingDXVariableSpeed.new(model)
heating_coil_speed_1 = OpenStudio::Model::CoilHeatingDXVariableSpeedSpeedData.new(model)
heating_coil.addSpeed(heating_coil_speed_1)

cooling_coil = OpenStudio::Model::CoilCoolingDXVariableSpeed.new(model)
cooling_coil_speed_1 = OpenStudio::Model::CoilCoolingDXVariableSpeedSpeedData.new(model)
cooling_coil.addSpeed(cooling_coil_speed_1)
# TODO: cooling_coil.setGridSignalSchedule(grid_signal_schedule)

chilling_coil = OpenStudio::Model::CoilChillerAirSourceVariableSpeed.new(model)
chilling_coil_speed_1 = OpenStudio::Model::CoilChillerAirSourceVariableSpeedSpeedData.new(model)
chilling_coil.addSpeed(chilling_coil_speed_1)
# TODO: chilling_coil.setGridSignalSchedule(grid_signal_schedule)

supp_chilling_coil = OpenStudio::Model::CoilCoolingWater.new(model)
supp_chilling_coil.addToNode(supplyOutletNode)
chw_loop.addDemandBranchForComponent(supp_chilling_coil)

thermal_storage = OpenStudio::Model::ThermalStoragePcmSimple.new(model)
chw_loop.addSupplyBranchForComponent(thermal_storage)

coil_system = OpenStudio::Model::CoilSystemIntegratedHeatPumpAirSource.new(model, cooling_coil)
coil_system.setHeatingCoil(heating_coil)
coil_system.setChillingCoil(chilling_coil)
coil_system.setSupplementalChillingCoil(supp_chilling_coil)
coil_system.setStorageTank(thermal_storage)

thermal_storage_cooling_pair = OpenStudio::Model::ThermalStorageCoolingPair.new(model)
thermal_storage_cooling_pair.setCoolingCoil(cooling_coil)
thermal_storage_cooling_pair.setTank(thermal_storage)

unitary = OpenStudio::Model::AirLoopHVACUnitaryHeatPumpAirToAir.new(model, schedule, fan, coil_system, coil_system, supp_heating_coil)
unitary.addToNode(supplyOutletNode)

terminal = OpenStudio::Model::AirTerminalSingleDuctConstantVolumeNoReheat.new(model, schedule)
air_loop.addBranchForZone(zone, terminal.to_StraightComponent)
unitary.setControllingZone(zone)

# save the OpenStudio model (.osm)
model.save_openstudio_osm({ 'osm_save_directory' => Dir.pwd,
                            'osm_name' => 'in.osm' })
