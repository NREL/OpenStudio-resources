
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
        
#add ASHRAE System type 07, VAV w/ Reheat
model.add_hvac({"ashrae_sys_num" => '07'})

tower = model.getCoolingTowerSingleSpeeds().first()

plant = tower.plantLoop().get()

plant.removeSupplyBranchWithComponent(tower)

# Default constructed tower
newTower = OpenStudio::Model::CoolingTowerVariableSpeed.new(model)
newTower.setSizingFactor(0.33)
plant.addSupplyBranchForComponent(newTower)

# CoolTools tower
newTower2 = OpenStudio::Model::CoolingTowerVariableSpeed.new(model)
newTower2.setSizingFactor(0.33)
plant.addSupplyBranchForComponent(newTower2)

modelCoefficient = OpenStudio::Model::CoolingTowerPerformanceCoolTools.new(model)

newTower2.setModelType("CoolToolsUserDefined")
newTower2.setModelCoefficient(modelCoefficient)
newTower2.setMinimumAirFlowRateRatio(0.2)
newTower2.setFractionofTowerCapacityinFreeConvectionRegime(0.125)
newTower2.setBasinHeaterCapacity(450.0)
newTower2.setBasinHeaterSetpointTemperature(4.5)
newTower2.setEvaporationLossMode("SaturatedExit")
newTower2.setDriftLossPercent(0.05)
newTower2.setBlowdownCalculationMode("ConcentrationRatio")
newTower2.setBlowdownConcentrationRatio(4.0)

# YorkCalc tower
newTower3 = OpenStudio::Model::CoolingTowerVariableSpeed.new(model)
newTower3.setSizingFactor(0.33)
plant.addSupplyBranchForComponent(newTower3)

modelCoefficient = OpenStudio::Model::CoolingTowerPerformanceYorkCalc.new(model)

newTower3.setModelType("YorkCalcUserDefined")
newTower3.setModelCoefficient(modelCoefficient)
newTower3.setDesignApproachTemperature(8.9)
newTower3.setDesignRangeTemperature(2.6)
newTower3.setMinimumAirFlowRateRatio(0.2)
newTower3.setFractionofTowerCapacityinFreeConvectionRegime(0.125)
newTower3.setBasinHeaterCapacity(450.0)
newTower3.setBasinHeaterSetpointTemperature(4.5)
newTower3.setEvaporationLossMode("SaturatedExit")
newTower3.setDriftLossPercent(0.05)
newTower3.setBlowdownCalculationMode("ConcentrationRatio")
newTower3.setBlowdownConcentrationRatio(4.0)


#add thermostats
model.add_thermostats({"heating_setpoint" => 24,
                      "cooling_setpoint" => 28})
              
#assign constructions from a local library to the walls/windows/etc. in the model
model.set_constructions()

#set whole building space type; simplified 90.1-2004 Large Office Whole Building
model.set_space_type()  

#add design days to the model (Chicago)
model.add_design_days()
       
#save the OpenStudio model (.osm)
model.save_openstudio_osm({"osm_save_directory" => Dir.pwd,
                           "osm_name" => "out.osm"})
                           
