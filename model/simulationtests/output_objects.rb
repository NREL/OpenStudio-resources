# frozen_string_literal: true

# This test aims to test the new **Unique** ModelObjects related to Output
# added in 3.0.0:
# * OutputDiagnostics,
# * OutputDebuggingData,
# * OutputJSON, and
# * OutputTableSummaryReports

require 'openstudio'
require 'lib/baseline_model'

model = BaselineModel.new

# make a 1 story, 100m X 50m, 1 zone building
model.add_geometry({ 'length' => 100,
                     'width' => 50,
                     'num_floors' => 1,
                     'floor_to_floor_height' => 4,
                     'plenum_height' => 0,
                     'perimeter_zone_depth' => 0 })

# add windows at a 40% window-to-wall ratio
model.add_windows({ 'wwr' => 0.4,
                    'offset' => 1,
                    'application_type' => 'Above Floor' })

# add thermostats
model.add_thermostats({ 'heating_setpoint' => 19,
                        'cooling_setpoint' => 26 })

# assign constructions from a local library to the walls/windows/etc. in the model
model.set_constructions

# set whole building space type; simplified 90.1-2004 Large Office Whole Building
model.set_space_type

# add design days to the model (Chicago)
model.add_design_days

# In order to produce more consistent results between different runs,
# we sort the zones by names
# (There's only one here, but just in case this would be copy pasted somewhere
# else...)
zones = model.getThermalZones.sort_by { |z| z.name.to_s }
z = zones[0]
z.setUseIdealAirLoads(true)

###############################################################################
#                             OUTPUT:DIAGNOSTICS                              #
###############################################################################

output_diagnostics = model.getOutputDiagnostics
# Helper to add the most common report: "DisplayExtraWarnings"
output_diagnostics.enableDisplayExtraWarnings
# To find the possible choices:
# OpenStudio::Model::OutputDiagnostics::keyValues
# OpenStudio::Model::OutputDiagnostics::validKeyValues
output_diagnostics.addKey('DisplayAdvancedReportVariables')
# Or you can directly use a list (it calls clearKeys() before setting the new
# keys)
# NOTE: until https://github.com/NREL/EnergyPlus/issues/7742 is addressed
# You can only add maximum TWO diagnostics
output_diagnostics.setKeys(['DisplayExtraWarnings',
                            'ReportDuringWarmup'])
# 'DisplayAdvancedReportVariables'

###############################################################################
#                                 OUTPUT:JSON                                 #
###############################################################################

output_json = model.getOutputJSON
# OpenStudio::Model::OutputJSON::optionTypeValues
output_json.setOptionType('TimeSeriesAndTabular')
output_json.setOutputJSON(true)
output_json.setOutputCBOR(false)
output_json.setOutputMessagePack(false)

###############################################################################
#                            OUTPUT:DEBUGGINGDATA                             #
###############################################################################

output_debugging = model.getOutputDebuggingData
output_debugging.setReportDebuggingData(true)
output_debugging.setReportDuringWarmup(true)

###############################################################################
#                         OUTPUT:TABLE:SUMMARYREPORTS                         #
###############################################################################

output_table = model.getOutputTableSummaryReports
# OpenStudio::Model::OutputTableSummaryReports::reportNameValues
# Convenience to add the most common (and default if you don't manually
# instantiate the OutputTableSummaryReports manually): "AllSummary"
output_table.enableAllSummaryReport
output_table.addSummaryReport('AdaptiveComfortSummary')
output_table.addSummaryReports(['OutdoorAirSummary', 'ObjectCountSummary'])
# output_table.getSummaryReport(1).get == "AdaptiveComfortSummary"
# output_table.summaryReportIndex("AdaptiveComfortSummary").get == 1

# save the OpenStudio model (.osm)
model.save_openstudio_osm({ 'osm_save_directory' => Dir.pwd,
                            'osm_name' => 'out.osm' })
