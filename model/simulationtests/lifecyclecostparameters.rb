require 'openstudio'

model = OpenStudio::Model::exampleModel()

lifeCycleCostParameters = model.getLifeCycleCostParameters
lifeCycleCostParameters.setAnalysisType("FEMP")
lifeCycleCostParameters.setLengthOfStudyPeriodInYears(25)

model.getConstructions.each do |construction|

  layers = construction.layers
  if layers.size == 1
    if not layers[0].to_AirWallMaterial.empty?
      next
    end
  end

  material_cost = OpenStudio::Model::LifeCycleCost::createLifeCycleCost("Material Cost", construction, 10.0, "CostPerArea", "Construction", 10, 0)
  demolition_cost = OpenStudio::Model::LifeCycleCost::createLifeCycleCost("Demolition Cost", construction, 2.0, "CostPerArea", "Replacement", 10, 10)
  salvage_cost = OpenStudio::Model::LifeCycleCost::createLifeCycleCost("Salvage Cost", construction, -1.0, "CostPerArea", "Replacement", 10, 10)
  maintenance_cost = OpenStudio::Model::LifeCycleCost::createLifeCycleCost("Maintenance Cost", construction, 1.0, "CostPerArea", "Maintenance", 1, 1)
end

# save the OpenStudio model (.osm)
model.save(OpenStudio::Path.new("in.osm") , true);
