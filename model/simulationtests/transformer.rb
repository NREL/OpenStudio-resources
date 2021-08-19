# frozen_string_literal: true

require 'openstudio'
require_relative 'lib/baseline_model'

model = BaselineModel.new

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

# add ASHRAE System type 01, PTAC, Residential
model.add_hvac({ 'ashrae_sys_num' => '01' })

# add thermostats
model.add_thermostats({ 'heating_setpoint' => 24,
                        'cooling_setpoint' => 28 })

# assign constructions from a local library to the walls/windows/etc. in the model
model.set_constructions

# set whole building space type; simplified 90.1-2004 Large Office Whole Building
model.set_space_type

# add design days to the model (Chicago)
model.add_design_days

# add schedule
sch = OpenStudio::Model::ScheduleCompact.new(model, 10)
sch.setName('Transformer Output Electric Energy Schedule')

# assign the user inputs to variables
name_plate_rating = 100

# check for transformer schedule in the starting model
schedules = model.getObjectsByName('Transformer Output Electric Energy Schedule')

# if schedules.empty?
#  runner.registerAsNotApplicable("Transformer Output Electric Energy Schedule not found")
#  return true
# end

# if schedules[0].iddObject.type != "OS:Schedule:Year".to_IddObjectType and
#  schedules[0].iddObject.type != "OS:Schedule:Compact".to_IddObjectType
#  runner.registerError("Transformer Output Electric Energy Schedule is not a Schedule:Year or a Schedule:Compact")
#  return false
# end

# DLM: these could be inputs
name_plate_efficiency = 0.985
unit_load_at_name_plate_efficiency = 0.35

if name_plate_rating == 0
  max_energy = 0

  if schedules[0].iddObject.type == 'Schedule:Year'.to_IddObjectType
    schedules[0].targets.each do |week_target|
      next if week_target.iddObject.type != 'Schedule:Week:Daily'.to_IddObjectType

      week_target.targets.each do |day_target|
        next if day_target.iddObject.type != 'Schedule:Day:Interval'.to_IddObjectType

        day_target.extensibleGroups.each do |eg|
          value = eg.getDouble(1)
          next if !value.is_initialized
          next if value.get <= max_energy

          max_energy = value.get
        end
      end
    end
  elsif schedules[0].iddObject.type == 'Schedule:Compact'.to_IddObjectType
    schedules[0].extensibleGroups.each do |eg|
      if /\A[+-]?\d+?(_?\d+)*(\.\d+e?\d*)?\Z/.match(eg.getString(0).to_s.strip)
        value = eg.getDouble(0)
        if value.is_initialized && (value.get > max_energy)
          max_energy = value.get
        end
      end
    end

  end
  # runner.registerInfo("Max energy is #{max_energy} J")

  minutes_per_timestep = nil
  model.getObjectsByType('Timestep'.to_IddObjectType).each do |timestep|
    timestep_per_hour = timestep.getDouble(0)
    if timestep_per_hour.empty?
      # runner.registerError("Cannot determine timesteps per hour")
      # return false
    end
    minutes_per_timestep = 60 / timestep_per_hour.get
  end

  if minutes_per_timestep.nil?
    # runner.registerError("Cannot determine minutes per timestep")
    # return false
  end

  seconds_per_timestep = minutes_per_timestep * 60
  max_power = max_energy / seconds_per_timestep

  # runner.registerInfo("Max power is #{max_power} W")

  name_plate_rating = max_power / unit_load_at_name_plate_efficiency
end

sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Schedule Value')
sensor.setKeyName('Transformer Output Electric Energy Schedule')
sensor.setName('TransformerOutputElectricEnergyScheduleEMSSensor')

meteredOutputVariable = OpenStudio::Model::EnergyManagementSystemMeteredOutputVariable.new(model, sensor)
meteredOutputVariable.setEMSVariableName(sensor.name.to_s)
meteredOutputVariable.setUpdateFrequency('ZoneTimeStep')
meteredOutputVariable.setResourceType('Electricity')
meteredOutputVariable.setGroupType('Building')
meteredOutputVariable.setEndUseCategory('ExteriorEquipment')
meteredOutputVariable.setEndUseSubcategory('Transformers')
meteredOutputVariable.setUnits('J')

# add 8 lines to deal with E+ bug; can be removed in E+ 9.0
program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
program.setName('DummyProgram')
program.addLine('SET N = 0')
program.addLine('SET N = 0')
program.addLine('SET N = 0')
program.addLine('SET N = 0')
program.addLine('SET N = 0')
program.addLine('SET N = 0')
program.addLine('SET N = 0')
program.addLine('SET N = 0')

pcm = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
pcm.setName('DummyManager')
pcm.setCallingPoint('BeginTimestepBeforePredictor')
pcm.addProgram(program)

meter = OpenStudio::Model::OutputMeter.new(model)
meter.setName('Transformer:ExteriorEquipment:Electricity')
meter.setReportingFrequency('Timestep')

transformer = OpenStudio::Model::ElectricLoadCenterTransformer.new(model)
transformer.setTransformerUsage('PowerInFromGrid')
transformer.setRatedCapacity(name_plate_rating.to_s.to_f)
transformer.setPhase('3')
transformer.setConductorMaterial('Aluminum')
transformer.setFullLoadTemperatureRise(150)
transformer.setFractionofEddyCurrentLosses(0.1)
transformer.setPerformanceInputMethod('NominalEfficiency')
transformer.setNameplateEfficiency(name_plate_efficiency.to_s.to_f)
transformer.setPerUnitLoadforNameplateEfficiency(unit_load_at_name_plate_efficiency.to_s.to_f)
transformer.setReferenceTemperatureforNameplateEfficiency(75)
transformer.setConsiderTransformerLossforUtilityCost(true)
transformer.addMeter('Transformer:ExteriorEquipment:Electricity')

# add output reports
add_out_vars = false
if add_out_vars
  # Request timeseries data for debugging
  reporting_frequency = 'Timestep'
  # Enable all output Variables for the object
  transformer.outputVariableNames.each do |var_name|
    outputVariable = OpenStudio::Model::OutputVariable.new(var_name, model)
    outputVariable.setReportingFrequency(reporting_frequency)
  end
end

# save the OpenStudio model (.osm)
model.save_openstudio_osm({ 'osm_save_directory' => Dir.pwd,
                            'osm_name' => 'in.osm' })
