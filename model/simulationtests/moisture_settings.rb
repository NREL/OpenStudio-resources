
require 'openstudio'
require 'lib/baseline_model'

model = BaselineModel.new

# /c/OpenStudio/OpenStudio/core-build/Products/Debug/openstudio.exe model_tests.rb -n test_moisture_settings_rb

heat_balance_algorithm = model.getHeatBalanceAlgorithm
heat_balance_algorithm.setAlgorithm("MoisturePenetrationDepthConductionTransferFunction")

#make a 2 story, 100m X 50m, 10 zone core/perimeter building
model.add_geometry({"length" => 100,
                    "width" => 50,
                    "num_floors" => 2,
                    "floor_to_floor_height" => 4,
                    "plenum_height" => 1,
                    "perimeter_zone_depth" => 3})
              
#assign constructions from a local library to the walls/windows/etc. in the model
model.set_constructions()

#assign material property moisture penetration depth settings to walls
model.getSurfaces.each do |surface|
  next unless surface.surfaceType.downcase == "wall"
  surface.construction.get.to_Construction.get.layers.each do |layer|
    layer.createMaterialPropertyMoisturePenetrationDepthSettings(8.9, 0.0069, 0.9066, 0.0404, 22.1121, 0.005, 140) # drywall
  end
end
       
# save the OpenStudio model (.osm)
model.save_openstudio_osm({"osm_save_directory" => Dir.pwd, "osm_name" => "in.osm"})