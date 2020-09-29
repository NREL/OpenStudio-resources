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

# If you set this to false, reporting measures will fail, including
# openstudio_results
outputcontrol_files.setOutputSQLite(true)
# openstudio_results needs the tabular output since it queries it:
# "Can't find any contents in Building Area Table to get tabular units. Measure can't run"
outputcontrol_files.setOutputTabular(true)

outputcontrol_files.setOutputCSV(true)
outputcontrol_files.setOutputAUDIT(true)

outputcontrol_files.setOutputJSON(false)
outputcontrol_files.setOutputMTR(false)
outputcontrol_files.setOutputESO(false)
outputcontrol_files.setOutputEIO(false)
outputcontrol_files.setOutputZoneSizing(false)
outputcontrol_files.setOutputSystemSizing(false)
outputcontrol_files.setOutputDXF(false)
outputcontrol_files.setOutputBND(false)
outputcontrol_files.setOutputRDD(false)
outputcontrol_files.setOutputMDD(false)
outputcontrol_files.setOutputMTD(false)

outputcontrol_files.setOutputSHD(false)
outputcontrol_files.setOutputDFS(false)
outputcontrol_files.setOutputGLHE(false)
outputcontrol_files.setOutputDelightIn(false)
outputcontrol_files.setOutputDelightELdmp(false)
outputcontrol_files.setOutputDelightDFdmp(false)
outputcontrol_files.setOutputEDD(false)
outputcontrol_files.setOutputDBG(false)
outputcontrol_files.setOutputPerfLog(false)
outputcontrol_files.setOutputSLN(false)
outputcontrol_files.setOutputSCI(false)
outputcontrol_files.setOutputWRL(false)
outputcontrol_files.setOutputScreen(false)
outputcontrol_files.setOutputExtShd(false)
outputcontrol_files.setOutputTarcog(false)

#save the OpenStudio model (.osm)
model.save_openstudio_osm({"osm_save_directory" => Dir.pwd,
                           "osm_name" => "out.osm"})
