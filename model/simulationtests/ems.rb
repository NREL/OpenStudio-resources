
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

#add ASHRAE System type 01, PTAC, Residential
model.add_hvac({"ashrae_sys_num" => '01'})

#add thermostats
model.add_thermostats({"heating_setpoint" => 24,
                      "cooling_setpoint" => 28})

#assign constructions from a local library to the walls/windows/etc. in the model
model.set_constructions()

#set whole building space type; simplified 90.1-2004 Large Office Whole Building
model.set_space_type()

#add design days to the model (Chicago)
model.add_design_days()

# Create an output variable for OATdb
output_var = "Site Outdoor Air Drybulb Temperature"
output_var_oat = OpenStudio::Model::OutputVariable.new(output_var, model)

# Create a sensor to sense the outdoor air temperature
oat_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, output_var_oat)
oat_sensor_name = "OATdb Sensor"
oat_sensor.setName(oat_sensor_name)

# starting on OS E+ 8.9.0, it Fatals if you don't do this
oat_sensor.setKeyName("*")

#oat_sensor.setOutputVariable(output_var_oat)

# Assertions for sensor setters and getters
#assert_equal oat_sensor_name, oat_sensor.name.get.to_s
#assert_equal output_var, oat_sensor.outputVariable.get.variableName

### Actuator ###

# If we get the first fan from the example model using getFanConstantVolumes[0]
# We cannot ensure we'll get the same one each time on subsequent runs
# (they may be in different order in the model)
# So we rely on ThermalZone names, and get the fan from there
# Sort the zones by name
zones = model.getThermalZones.sort_by{|z| z.name.to_s}
# Get the first zone, get its PTAC's fan.
z = zones[0]
ptac = z.equipment[0].to_ZoneHVACPackagedTerminalAirConditioner.get
fan = ptac.supplyAirFan.to_FanConstantVolume.get
#always_on = model.alwaysOnDiscreteSchedule
#fan = OpenStudio::Model::FanConstantVolume.new(model,always_on)

# Create an actuator to set the fan pressure rise
fan_press = "Fan Pressure Rise"
fan_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(fan, "fan", fan_press)
fan_actuator.setName("#{fan.name} Press Actuator")
#fan_actuator.setActuatedComponentControlType(fan_press)
#fan_actuator.setActuatedComponentType("fan")
#fan_actuator.setActuatedComponent(fan)

# Assertions for actuator setters and getters
#assert_equal(fan, fan_actuator.actuatedComponent)
#assert_equal(fan_press, fan_actuator.actuatedComponentControlType)

### Program ###

# Create a program all at once
fan_program_1 = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
fan_program_1.setName("#{fan.name} Pressure Rise Program by Line")
fan_program_1_body = <<-EMS
  SET mult = #{oat_sensor.handle} / 15.0 !- This is nonsense
  SET #{fan_actuator.handle} = 250 * mult !- More nonsense
EMS
fan_program_1.setBody(fan_program_1_body)

# Assertion for the number of lines
#assert_equal(2, fan_program_1.lines.get.size)
# Assertion for the objects that are referenced
#assert_equal(2, fan_program_1.referencedObjects.size)
# Assertion for the number of invalid objects
#assert_equal(0, fan_program_1.invalidReferencedObjects.size)
# Delete the actuator
#fan_actuator.remove
# Assertion for the new number of invalid objects
#assert_equal(1, fan_program_1.invalidReferencedObjects.size)

# Create a third program from a vector of lines
fan_program_2 = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
fan_program_2.setName("#{fan.name} Pressure Rise Program by Line")
fan_program_2.addLine("SET mult = #{oat_sensor.handle} / 15.0 !- This is nonsense")
fan_program_2.addLine("SET #{fan_actuator.handle} = 250 * mult !- More nonsense")

# Assertion for the number of lines
#assert_equal(2, fan_program_2.lines.get.size)
# Assertion for the objects that are referenced
#assert_equal(1, fan_program_2.referencedObjects.size)
# Assertion for the new number of invalid objects
#assert_equal(1, fan_program_2.invalidReferencedObjects.size)

# Create a third program from vector of lines
fan_program_3 = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
fan_program_3.setName("#{fan.name} Pressure Rise Program by Vector of Lines")
fan_program_3_lines = []
fan_program_3_lines << "SET mult = #{oat_sensor.handle} / 15.0 !- This is nonsense"
fan_program_3_lines << "SET #{fan_actuator.handle} = 250 * mult !- More nonsense"
fan_program_3.setLines(fan_program_3_lines)

# Assertion for the number of lines
#assert_equal(2, fan_program_3.lines.get.size)
# Assertion for the objects that are referenced
#assert_equal(1, fan_program_3.referencedObjects.size)
# Assertion for the new number of invalid objects
#assert_equal(1, fan_program_3.invalidReferencedObjects.size)

#save the OpenStudio model (.osm)
model.save_openstudio_osm({"osm_save_directory" => Dir.pwd,
                           "osm_name" => "in.osm"})

