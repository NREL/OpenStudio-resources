# frozen_string_literal: true

require 'openstudio'
require_relative 'lib/baseline_model'

m = BaselineModel.new

# make a 1 story, 100m X 50m, 1 zone core/perimeter building
m.add_geometry({ 'length' => 100,
                 'width' => 50,
                 'num_floors' => 1,
                 'floor_to_floor_height' => 4,
                 'plenum_height' => 1,
                 'perimeter_zone_depth' => 0 })

# add windows at a 40% window-to-wall ratio
m.add_windows({ 'wwr' => 0.4,
                'offset' => 1,
                'application_type' => 'Above Floor' })

# add thermostats
m.add_thermostats({ 'heating_setpoint' => 24,
                    'cooling_setpoint' => 28 })

# assign constructions from a local library to the walls/windows/etc. in the model
m.set_constructions

# set whole building space type; simplified 90.1-2004 Large Office Whole Building
m.set_space_type

# add design days to the model (Chicago)
m.add_design_days

# In order to produce more consistent results between different runs,
# we sort the zones by names (only one here anyways...)
zones = m.getThermalZones.sort_by { |z| z.name.to_s }

# Use Ideal Air Loads
zones.each { |z| z.setUseIdealAirLoads(true) }

# Get the **Unique** ModelObject
sc = m.getShadowCalculation

if Gem::Version.new(OpenStudio.openStudioVersion) < Gem::Version.new('3.0.0')
  # This one was added only in 2.9.0
  if Gem::Version.new(OpenStudio.openStudioVersion) >= Gem::Version.new('2.9.0')
    sc.setCalculationMethod('AverageOverDaysInFrequency')
  end
  sc.setCalculationFrequency(20)
else
  sc.setShadingCalculationUpdateFrequencyMethod('Periodic')
  sc.setShadingCalculationUpdateFrequency(20)
end

sc.setMaximumFiguresInShadowOverlapCalculations(15000)

sc.setPolygonClippingAlgorithm('SutherlandHodgman')
sc.setSkyDiffuseModelingAlgorithm('SimpleSkyDiffuseModeling')

if Gem::Version.new(OpenStudio.openStudioVersion) > Gem::Version.new('2.9.1')
  sc.setPixelCountingResolution(512)
  sc.setOutputExternalShadingCalculationResults(false)
  sc.setDisableSelfShadingWithinShadingZoneGroups(false)
  sc.setDisableSelfShadingFromShadingZoneGroupstoOtherZones(false)
  sc.setShadingCalculationMethod('PolygonClipping')

  # This will be ignored by E+ since we didn't enabled any of the disable
  # self-shading options, but showcases the API
  v = OpenStudio::Model::ThermalZoneVector.new
  v << zones[0]
  sc.addShadingZoneGroup(v)
end

# save the OpenStudio model (.osm)
m.save_openstudio_osm({ 'osm_save_directory' => Dir.pwd,
                        'osm_name' => 'in.osm' })
