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

#create a foundation kiva settings object
foundation_kiva_settings = OpenStudio::Model::FoundationKivaSettings.new(model)
foundation_kiva_settings.setSoilConductivity(1.731)
foundation_kiva_settings.setSoilDensity(1842.3)

#get foundation kiva settings object from site
foundation_kiva_settings = model.getSite.foundationKivaSettings.get
foundation_kiva_settings.resetSoilDensity

#create a foundation kiva object
foundation_kiva = OpenStudio::Model::FoundationKiva.new(model)
foundation_kiva.setInteriorVerticalInsulationDepth(2.4384)
foundation_kiva.setWallHeightAboveGrade(0.2032)
foundation_kiva.setWallDepthBelowSlab(0.2032)
material = OpenStudio::Model::StandardOpaqueMaterial.new(model)
material.setThickness(0.0508)
material.setConductivity(0.02885)
material.setDensity(32.04)
material.setSpecificHeat(1214.23)
foundation_kiva.setInteriorVerticalInsulationMaterial(material)

#attach foundation kiva object to surfaces
model.getSurfaces.each do |surface|
  construction = surface.construction.get
  next if surface.outsideBoundaryCondition.downcase != "ground"
  surface.setAdjacentFoundation(foundation_kiva)
  surface.setConstruction(construction)
  next if surface.surfaceType.downcase != "floor"
  # surface.createSurfacePropertyExposedFoundationPerimeter("TotalExposedPerimeter")
end
       
# save the OpenStudio model (.osm)
model.save_openstudio_osm({"osm_save_directory" => Dir.pwd, "osm_name" => "in.osm"})