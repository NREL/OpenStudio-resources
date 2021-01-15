# frozen_string_literal: true

require 'openstudio'
require_relative 'lib/baseline_model'

model = BaselineModel.new

# Schedule Ruleset
defrost_sch = OpenStudio::Model::ScheduleRuleset.new(model)
defrost_sch.setName('Refrigeration Defrost Schedule')
# All other days
defrost_sch.defaultDaySchedule.setName('Refrigeration Defrost Schedule Default')
defrost_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0, 4, 0, 0), 0)
defrost_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0, 4, 45, 0), 1)
defrost_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0, 8, 0, 0), 0)
defrost_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0, 8, 45, 0), 1)
defrost_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0, 12, 0, 0), 0)
defrost_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0, 12, 45, 0), 1)
defrost_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0, 16, 0, 0), 0)
defrost_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0, 16, 45, 0), 1)
defrost_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0, 20, 0, 0), 0)
defrost_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0, 20, 45, 0), 1)
defrost_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0, 24, 0, 0), 0)

def add_case(model, thermal_zone, defrost_sch)
  ref_case = OpenStudio::Model::RefrigerationCase.new(model, defrost_sch)
  ref_case.setThermalZone(thermal_zone)
  return ref_case
end

def add_walkin(model, thermal_zone, defrost_sch)
  ref_walkin = OpenStudio::Model::RefrigerationWalkIn.new(model, defrost_sch)
  zone_boundaries = ref_walkin.zoneBoundaries
  zone_boundaries[0].setThermalZone(thermal_zone)
  return ref_walkin
end

# make a 2 story, 100m X 50m, 10 zone core/perimeter building
model.add_geometry({ 'length' => 100,
                     'width' => 50,
                     'num_floors' => 2,
                     'floor_to_floor_height' => 4,
                     'plenum_height' => 1,
                     'perimeter_zone_depth' => 3 })

# add windows at a 40% window-to-wall ratio
model.add_windows({ 'wwr' => 0.4,
                    'offset' => 1,
                    'application_type' => 'Above Floor' })

# add ASHRAE System type 07, VAV w/ Reheat
model.add_hvac({ 'ashrae_sys_num' => '07' })

# add thermostats
model.add_thermostats({ 'heating_setpoint' => 20,
                        'cooling_setpoint' => 28 })

# assign constructions from a local library to the walls/windows/etc. in the model
model.set_constructions

# set whole building space type; simplified 90.1-2004 Large Office Whole Building
model.set_space_type

# add design days to the model (Chicago)
model.add_design_days

# In order to produce more consistent results between different runs,
# we sort the zones by names
zones = model.getThermalZones.sort_by { |z| z.name.to_s }

boilers = model.getBoilerHotWaters.sort_by { |c| c.name.to_s }
heating_loop = boilers.first.plantLoop.get

i = 0

zones.each do |z|
  if i == 2
    compressor_rack = OpenStudio::Model::RefrigerationCompressorRack.new(model)
    compressor_rack.addCase(add_case(model, z, defrost_sch))
    compressor_rack.addCase(add_case(model, z, defrost_sch))
    compressor_rack.addWalkin(add_walkin(model, z, defrost_sch))
    compressor_rack.addWalkin(add_walkin(model, z, defrost_sch))

    cooling_tower = model.getCoolingTowerSingleSpeeds.first
    plant = cooling_tower.plantLoop.get
    plant.addDemandBranchForComponent(compressor_rack)

    water_tank = OpenStudio::Model::WaterHeaterMixed.new(model)
    water_tank.setAmbientTemperatureIndicator('ThermalZone')
    water_tank.setAmbientTemperatureThermalZone(z)
    heating_loop.addSupplyBranchForComponent(water_tank)
    # Schedule Ruleset
    setpointTemperatureSchedule = OpenStudio::Model::ScheduleRuleset.new(model)
    setpointTemperatureSchedule.setName('Setpoint Temperature Schedule')
    setpointTemperatureSchedule.defaultDaySchedule.setName('Setpoint Temperature Schedule Default')
    setpointTemperatureSchedule.defaultDaySchedule.addValue(OpenStudio::Time.new(0, 24, 0, 0), 70)

    desuperheater = OpenStudio::Model::CoilWaterHeatingDesuperheater.new(model, setpointTemperatureSchedule)
    water_tank.setSetpointTemperatureSchedule(setpointTemperatureSchedule)
    desuperheater.addToHeatRejectionTarget(water_tank)
    desuperheater.setHeatingSource(compressor_rack)
  end

  i += 1
end

# save the OpenStudio model (.osm)
model.save_openstudio_osm({ 'osm_save_directory' => Dir.pwd,
                            'osm_name' => 'in.osm' })
