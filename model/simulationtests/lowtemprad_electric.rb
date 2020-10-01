# frozen_string_literal: true

require 'openstudio'
require 'lib/baseline_model'

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

# In order to produce more consistent results between different runs,
# we sort the zones by names
zones = model.getThermalZones.sort_by { |z| z.name.to_s }

heatingTemperatureSched = OpenStudio::Model::ScheduleConstant.new(model)

heatingTemperatureSched.setValue(10.0)

zones.each do |z|
  lowtempradiant = OpenStudio::Model::ZoneHVACLowTemperatureRadiantElectric.new(model, model.alwaysOnDiscreteSchedule, heatingTemperatureSched)
  lowtempradiant.setRadiantSurfaceType('Floors')
  lowtempradiant.setMaximumElectricalPowertoPanel(1000)
  lowtempradiant.setTemperatureControlType('MeanRadiantTemperature')

  lowtempradiant.addToThermalZone(z)
end

# add thermostats
# model.add_thermostats({"heating_setpoint" => 24,"cooling_setpoint" => 28})

# assign constructions from a local library to the walls/windows/etc. in the model
model.set_constructions

# create an internalsourceconstruction

intSourceConst = OpenStudio::Model::ConstructionWithInternalSource.new(model)
intSourceConst.setSourcePresentAfterLayerNumber(3)
intSourceConst.setTemperatureCalculationRequestedAfterLayerNumber(3)
layers = [] # OpenStudio::Model::MaterialVector.new(model)
layers << concrete_sand_gravel = OpenStudio::Model::StandardOpaqueMaterial.new(model, 'MediumRough', 0.1014984, 1.729577, 2242.585, 836.8)
layers << rigid_insulation_2inch = OpenStudio::Model::StandardOpaqueMaterial.new(model, 'Rough', 0.05, 0.02, 56.06, 1210)
layers << gyp1 = OpenStudio::Model::StandardOpaqueMaterial.new(model, 'MediumRough', 0.0127, 0.7845, 1842.1221, 988)
layers << gyp2 = OpenStudio::Model::StandardOpaqueMaterial.new(model, 'MediumRough', 0.01905, 0.7845, 1842.1221, 988)
layers << finished_floor = OpenStudio::Model::StandardOpaqueMaterial.new(model, 'Smooth', 0.0016, 0.17, 1922.21, 1250)

intSourceConst.setLayers(layers)

# set whole building space type; simplified 90.1-2004 Large Office Whole Building
model.set_space_type

# find a surface that's of surface type floor and assign the surface internal source construction
model.getSurfaces.each do |s|
  if s.surfaceType == 'Floor'
    s.setConstruction(intSourceConst)
  end
end

# add design days to the model (Chicago)
model.add_design_days

# save the OpenStudio model (.osm)
model.save_openstudio_osm({ 'osm_save_directory' => Dir.pwd,
                            'osm_name' => 'in.osm' })
