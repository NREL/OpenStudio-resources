# This test aims to test the new **Unique** ModelObjects related to Output
# added in 3.0.0:
# * OutputDiagnostics,
# * OutputDebuggingData,
# * OutputJSON, and
# * OutputTableSummaryReports

require 'openstudio'
require 'lib/baseline_model'


model = BaselineModel.new

#make a 1 story, 100m X 50m, 1 zone building
model.add_geometry({"length" => 100,
                    "width" => 50,
                    "num_floors" => 1,
                    "floor_to_floor_height" => 4,
                    "plenum_height" => 0,
                    "perimeter_zone_depth" => 0})

#add windows at a 40% window-to-wall ratio
model.add_windows({"wwr" => 0.4,
                  "offset" => 1,
                  "application_type" => "Above Floor"})

#add thermostats
model.add_thermostats({"heating_setpoint" => 19,
                       "cooling_setpoint" => 26})

#assign constructions from a local library to the walls/windows/etc. in the model
model.set_constructions()

#set whole building space type; simplified 90.1-2004 Large Office Whole Building
model.set_space_type()

#add design days to the model (Chicago)
model.add_design_days()

# In order to produce more consistent results between different runs,
# we sort the zones by names
# (There's only one here, but just in case this would be copy pasted somewhere
# else...)
zones = model.getThermalZones.sort_by{|z| z.name.to_s}
z = zones[0]
z.setUseIdealAirLoads(true)

###############################################################################
#                            OUTPUTCONTROL:FILES                              #
###############################################################################

outputcontrol_files = model.getOutputControlFiles
outputcontrol_files.setOutputCSV(true)
outputcontrol_files.setOutputMTR(true)
assert(File.exist?(File.join(File.dirname(__FILE__), '../../testruns/outputcontrol_files.rb/run/eplusout.csv')))
assert(File.exist?(File.join(File.dirname(__FILE__), '../../testruns/outputcontrol_files.rb/run/eplusout.mtr')))
outputcontrol_files.setOutputBND(false)
outputcontrol_files.setOutputDBG(false)
assert(!File.exist?(File.join(File.dirname(__FILE__), '../../testruns/outputcontrol_files.rb/run/eplusout.bnd')))
assert(!File.exist?(File.join(File.dirname(__FILE__), '../../testruns/outputcontrol_files.rb/run/eplusout.dbg')))

#save the OpenStudio model (.osm)
model.save_openstudio_osm({"osm_save_directory" => Dir.pwd,
                           "osm_name" => "out.osm"})
