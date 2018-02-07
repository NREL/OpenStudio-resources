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

#create 8in concrete material
material = OpenStudio::Model::StandardOpaqueMaterial.new(model)
material.setThickness(0.2032)
material.setConductivity(1.3114056)
material.setDensity(2242.8)
material.setSpecificHeat(837.4)

#create the additional properties object
additional_properties = material.additionalProperties
additional_properties.setFeature("isNiceMaterial", true)

#create construction with the material
construction = OpenStudio::Model::Construction.new(model)
construction.insertLayer(0, material)

#create the additional properties object
additional_properties = construction.additionalProperties
additional_properties.setFeature("isNiceConstruction", true)

#update all additional properties objects
model.getAdditionalPropertiess.each do |additional_properties|

  #retrieve an additional properties object and set a new feature
  additional_properties.setFeature("newFeature", 1)
  
  #retrieve the parent object from the additional properties object
  model_object = additional_properties.modelObject
  if model_object.to_StandardOpaqueMaterial.is_initialized
    material = model_object.to_StandardOpaqueMaterial.get
    material.setThickness(0.3)
  end
  if model_object.to_Construction.is_initialized
    material = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    material.setThickness(0.2032)
    material.setConductivity(1.3114056)
    material.setDensity(2242.8)
    material.setSpecificHeat(837.4)
    construction = model_object.to_Construction.get
    construction.insertLayer(1, material)
  end

end
       
# save the OpenStudio model (.osm)
model.save_openstudio_osm({"osm_save_directory" => Dir.pwd, "osm_name" => "in.osm"})