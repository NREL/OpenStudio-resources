
require 'openstudio'
require 'lib/baseline_model'

model = BaselineModel.new

#make a 1 story, 100m X 50m, 1 zone building
model.add_geometry({"length" => 100,
                    "width" => 50,
                    "num_floors" => 1,
                    "floor_to_floor_height" => 4,
                    "plenum_height" => 1,
                    "perimeter_zone_depth" => 0})

#add windows at a 40% window-to-wall ratio
model.add_windows({"wwr" => 0.4,
                   "offset" => 1,
                   "application_type" => "Above Floor"})

#add ASHRAE System type 03, PSZ-AC
model.add_hvac({"ashrae_sys_num" => '03'})

#add thermostats
model.add_thermostats({"heating_setpoint" => 24,
                       "cooling_setpoint" => 28})

#assign constructions from a local library to the walls/windows/etc. in the model
model.set_constructions()

#set whole building space type; simplified 90.1-2004 Large Office Whole Building
model.set_space_type()

#add design days to the model (Chicago)
model.add_design_days()

# initialize some stuff
year_description = model.getYearDescription
start_date = year_description.makeDate(1, 1)
interval = OpenStudio::Time.new(0, 1, 0, 0)

# get some timeseries data
file_name = File.join(File.dirname(__FILE__), 'lib/schedulefile.csv')
file_name = File.realpath(file_name)
file_path = OpenStudio::Path.new(file_name)
csv_file = OpenStudio::CSVFile.load(file_path).get
values = csv_file.getColumnAsStringVector(2)
values = values[1..-1]
values = values.map{|x| x.to_f}
start_date = year_description.makeDate(1, 1)
interval = OpenStudio::Time.new(0, 1, 0, 0)
timeseries = OpenStudio::TimeSeries.new(start_date, interval, OpenStudio::createVector(values), "")

# create the schedule type limits
schedule_type_limits = OpenStudio::Model::ScheduleTypeLimits.new(model)
schedule_type_limits.setName("Fractional")
schedule_type_limits.setLowerLimitValue(0)
schedule_type_limits.setUpperLimitValue(1)
schedule_type_limits.setNumericType("Continuous")

# create the schedule fixed interval
schedule_fixed_interval = OpenStudio::Model::ScheduleFixedInterval.new(model)
schedule_fixed_interval.setTimeSeries(timeseries)
schedule_fixed_interval.setTranslatetoScheduleFile(false)
schedule_fixed_interval.setScheduleTypeLimits(schedule_type_limits)

# apply schedule to all lights
model.getLightss.each do |lights|
  lights.setSchedule(schedule_fixed_interval)
end

#save the OpenStudio model (.osm)
model.save_openstudio_osm({"osm_save_directory" => Dir.pwd,
                           "osm_name" => "in.osm"})
