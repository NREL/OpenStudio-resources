# frozen_string_literal: true

require 'openstudio'
require 'lib/baseline_model'

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

time_24hrs = OpenStudio::Time.new(0, 24, 0, 0)

cooling_sch = OpenStudio::Model::ScheduleRuleset.new(model)
cooling_sch.setName('Air Chiller Cooling Sch')
cooling_sch.defaultDaySchedule.setName('Air Chiller Cooling Sch Default')
cooling_sch.defaultDaySchedule.addValue(time_24hrs, 5)

heating_sch = OpenStudio::Model::ScheduleRuleset.new(model)
heating_sch.setName('Air Chiller Heating Sch')
heating_sch.defaultDaySchedule.setName('Air Chiller Heating Sch Default')
heating_sch.defaultDaySchedule.addValue(time_24hrs, 5)

# make a 2 story, 100m X 50m, 10 zone core/perimeter building
model.add_geometry({ 'length' => 100,
                     'width' => 50,
                     'num_floors' => 1,
                     'floor_to_floor_height' => 4,
                     'plenum_height' => 1,
                     'perimeter_zone_depth' => 3 })

# add windows at a 20% window-to-wall ratio
model.add_windows({ 'wwr' => 0.2,
                    'offset' => 1,
                    'application_type' => 'Above Floor' })

air_chiller1 = OpenStudio::Model::RefrigerationAirChiller.new(model, defrost_sch)
air_chiller2 = OpenStudio::Model::RefrigerationAirChiller.new(model, defrost_sch)

# In order to produce more consistent results between different runs,
# we sort the zones by names
zones = model.getThermalZones.sort_by { |z| z.name.to_s }

heating_coil1 = nil
heating_coil3 = nil
cooling_coil1 = nil
cooling_coil3 = nil
zones.each_with_index do |z, i|
  if i == 0
    schedule = model.alwaysOnDiscreteSchedule
    fan = OpenStudio::Model::FanOnOff.new(model, schedule)
    heating_coil1 = OpenStudio::Model::CoilHeatingWater.new(model, schedule)
    cooling_coil1 = OpenStudio::Model::CoilCoolingWater.new(model, schedule)
    four_pipe_fan_coil = OpenStudio::Model::ZoneHVACFourPipeFanCoil.new(model, schedule, fan, cooling_coil1, heating_coil1)
    four_pipe_fan_coil.addToThermalZone(z)
    air_chiller1.addToThermalZone(z)
  elsif i == 1
    air_chiller2.addToThermalZone(z)
    schedule = model.alwaysOnDiscreteSchedule
    fan = OpenStudio::Model::FanOnOff.new(model, schedule)
    heating_coil3 = OpenStudio::Model::CoilHeatingWater.new(model, schedule)
    cooling_coil3 = OpenStudio::Model::CoilCoolingWater.new(model, schedule)
    four_pipe_fan_coil = OpenStudio::Model::ZoneHVACFourPipeFanCoil.new(model, schedule, fan, cooling_coil3, heating_coil3)
    four_pipe_fan_coil.addToThermalZone(z)
  end
end

# add ASHRAE System type 07, VAV w/ Reheat
model.add_hvac({ 'ashrae_sys_num' => '07' })

# add thermostats
model.add_thermostats({ 'heating_setpoint' => 18,
                        'cooling_setpoint' => 32 })

# In order to produce more consistent results between different runs,
# We ensure we do get the same object each time
chillers = model.getChillerElectricEIRs.sort_by { |c| c.name.to_s }
boilers = model.getBoilerHotWaters.sort_by { |c| c.name.to_s }

cooling_loop = chillers.first.plantLoop.get
heating_loop = boilers.first.plantLoop.get

heating_loop.addDemandBranchForComponent(heating_coil1)
cooling_loop.addDemandBranchForComponent(cooling_coil1)
heating_loop.addDemandBranchForComponent(heating_coil3)
cooling_loop.addDemandBranchForComponent(cooling_coil3)

# assign constructions from a local library to the walls/windows/etc. in the model
model.set_constructions

# set whole building space type; simplified 90.1-2004 Large Office Whole Building
model.set_space_type

# add design days to the model (Chicago)
model.add_design_days

zones.each_with_index do |z, i|
  if i == 0
    new_thermostat = OpenStudio::Model::ThermostatSetpointDualSetpoint.new(model)

    new_thermostat.setHeatingSchedule(heating_sch)
    new_thermostat.setCoolingSchedule(cooling_sch)

    z.setThermostatSetpointDualSetpoint(new_thermostat)

    sizing_zone = z.sizingZone
    sizing_zone.setZoneCoolingDesignSupplyAirTemperature(0)
    sizing_zone.setZoneHeatingDesignSupplyAirTemperature(0)

    ref_sys7 = OpenStudio::Model::RefrigerationSystem.new(model)
    ref_sys7.addCompressor(OpenStudio::Model::RefrigerationCompressor.new(model))
    ref_sys7.setRefrigerationCondenser(OpenStudio::Model::RefrigerationCondenserAirCooled.new(model))
    ref_sys7.setSuctionPipingZone(z)
    air_chiller3 = OpenStudio::Model::RefrigerationAirChiller.new(model, defrost_sch)
    air_chiller3.addToThermalZone(z)
    air_chiller3.setCapacityRatingType('EuropeanSC1Standard')
    air_chiller3.setRatedCapacity(100000.0)
    air_chiller4 = OpenStudio::Model::RefrigerationAirChiller.new(model, defrost_sch)
    air_chiller4.addToThermalZone(z)
    ref_sys7.addAirChiller(air_chiller1)
    ref_sys7.addAirChiller(air_chiller3)
    ref_sys7.addAirChiller(air_chiller4)

    schedule = model.alwaysOnDiscreteSchedule
    fan = OpenStudio::Model::FanOnOff.new(model, schedule)
    heating_coil2 = OpenStudio::Model::CoilHeatingWater.new(model, schedule)
    cooling_coil2 = OpenStudio::Model::CoilCoolingWater.new(model, schedule)
    four_pipe_fan_coil = OpenStudio::Model::ZoneHVACFourPipeFanCoil.new(model, schedule, fan, cooling_coil2, heating_coil2)
    four_pipe_fan_coil.addToThermalZone(z)
    heating_loop.addDemandBranchForComponent(heating_coil2)
    cooling_loop.addDemandBranchForComponent(cooling_coil2)
  elsif i == 1
    new_thermostat = OpenStudio::Model::ThermostatSetpointDualSetpoint.new(model)

    new_thermostat.setHeatingSchedule(heating_sch)
    new_thermostat.setCoolingSchedule(cooling_sch)

    z.setThermostatSetpointDualSetpoint(new_thermostat)

    sizing_zone = z.sizingZone
    sizing_zone.setZoneCoolingDesignSupplyAirTemperature(0)
    sizing_zone.setZoneHeatingDesignSupplyAirTemperature(0)

    ref_sys7 = OpenStudio::Model::RefrigerationSystem.new(model)
    ref_sys7.addCompressor(OpenStudio::Model::RefrigerationCompressor.new(model))
    ref_sys7.setRefrigerationCondenser(OpenStudio::Model::RefrigerationCondenserAirCooled.new(model))
    ref_sys7.setSuctionPipingZone(z)
    air_chiller3 = OpenStudio::Model::RefrigerationAirChiller.new(model, defrost_sch)
    air_chiller3.addToThermalZone(z)
    air_chiller4 = OpenStudio::Model::RefrigerationAirChiller.new(model, defrost_sch)
    air_chiller4.addToThermalZone(z)
    ref_sys7.addAirChiller(air_chiller3)
    ref_sys7.addAirChiller(air_chiller4)
  elsif i == 2
    air_loop = z.airLoopHVAC.get
    air_loop.removeBranchForZone(z)
    new_thermostat = OpenStudio::Model::ThermostatSetpointDualSetpoint.new(model)

    new_thermostat.setHeatingSchedule(heating_sch)
    new_thermostat.setCoolingSchedule(cooling_sch)

    z.setThermostatSetpointDualSetpoint(new_thermostat)

    sizing_zone = z.sizingZone
    sizing_zone.setZoneCoolingDesignSupplyAirTemperature(0)
    sizing_zone.setZoneHeatingDesignSupplyAirTemperature(0)

    ref_sys7 = OpenStudio::Model::RefrigerationSystem.new(model)
    ref_sys7.addCompressor(OpenStudio::Model::RefrigerationCompressor.new(model))
    ref_sys7.setRefrigerationCondenser(OpenStudio::Model::RefrigerationCondenserAirCooled.new(model))
    ref_sys7.setSuctionPipingZone(z)
    air_chiller3 = OpenStudio::Model::RefrigerationAirChiller.new(model, defrost_sch)
    air_chiller3.addToThermalZone(z)
    air_chiller4 = OpenStudio::Model::RefrigerationAirChiller.new(model, defrost_sch)
    air_chiller4.addToThermalZone(z)
    ref_sys7.addAirChiller(air_chiller3)
    ref_sys7.addAirChiller(air_chiller4)
  end
end

# save the OpenStudio model (.osm)
model.save_openstudio_osm({ 'osm_save_directory' => Dir.pwd,
                            'osm_name' => 'in.osm' })
