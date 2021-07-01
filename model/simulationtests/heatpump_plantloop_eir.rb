# frozen_string_literal: true

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
model.add_thermostats({ 'heating_setpoint' => 24,
                        'cooling_setpoint' => 28 })

# assign constructions from a local library to the walls/windows/etc. in the model
model.set_constructions

# set whole building space type; simplified 90.1-2004 Large Office Whole Building
model.set_space_type

# add design days to the model (Chicago)
model.add_design_days

# In order to produce more consistent results between different runs,
# we sort the zones by names (only one here anyways...)
zones = m.getThermalZones.sort_by { |z| z.name.to_s }
zone = zones[0]

# PlantLoopHeatPump_EIR_WaterSource.idf
hw_loop = OpenStudio::Model::PlantLoop.new(model)
cw_loop = OpenStudio::Model::PlantLoop.new(model)
chw_loop = OpenStudio::Model::PlantLoop.new(model)

plhp_htg = OpenStudio::Model::HeatPumpPlantLoopEIRHeating.new(model)
plhp_clg = OpenStudio::Model::HeatPumpPlantLoopEIRCooling.new(model)

plhp_htg.setName('Heating Coil')
plhp_htg.setCompanionCoolingHeatPump(plhp_clg)
plhp_htg.setCondenserType('WaterSource')
plhp_htg.setReferenceLoadSideFlowRate(0.005)
plhp_htg.setReferenceSourceSideFlowRate(0.002)
plhp_htg.setReferenceCapacity(80000)
plhp_htg.setReferenceCoefficientofPerformance(3.5)
plhp_htg.setSizingFactor(1)

plhp_clg.setName('Cooling Coil')
plhp_clg.setCompanionHeatingHeatPump(plhp_htg)
plhp_clg.setCondenserType('WaterSource')
plhp_clg.setReferenceLoadSideFlowRate(0.005)
plhp_clg.setReferenceSourceSideFlowRate(0.003)
plhp_clg.setReferenceCapacity(400000)
plhp_clg.setReferenceCoefficientofPerformance(3.5)
plhp_clg.setSizingFactor(1)

hw_loop.addSupplyBranchForComponent(plhp_htg)
chw_loop.addDemandBranchForComponent(plhp_htg)

cw_loop.addSupplyBranchForComponent(plhp_clg)
chw_loop.addDemandBranchForComponent(plhp_clg)

# save the OpenStudio model (.osm)
model.save_openstudio_osm({ 'osm_save_directory' => Dir.pwd,
                            'osm_name' => 'in.osm' })
