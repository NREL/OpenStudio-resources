# frozen_string_literal: true

require 'openstudio'
require 'lib/baseline_model'
require 'lib/surface_visitor'

class SurfaceNetworkBuilder < SurfaceVisitor
  def initialize(model)
    refcond = OpenStudio::Model::AirflowNetworkReferenceCrackConditions.new(model, 20.0, 101325.0, 0.0)
    @interiorCrack = OpenStudio::Model::AirflowNetworkCrack.new(model, 0.050, 0.65, refcond)
    @exteriorCrack = OpenStudio::Model::AirflowNetworkCrack.new(model, 0.025, 0.65, refcond)
    super(model)
  end

  def interiorFloor(model, surface, adjacentSurface)
    return if surface.outsideBoundaryCondition.start_with?('Ground')

    # Create a surface linkage
    link = surface.getAirflowNetworkSurface(@interiorCrack)
  end

  def interiorRoofCeiling(model, surface, adjacentSurface)
    # Create a surface linkage
    link = surface.getAirflowNetworkSurface.new(@interiorCrack)
  end

  def interiorWall(model, surface, adjacentSurface)
    # Create a surface linkage
    link = surface.getAirflowNetworkSurface(@interiorCrack)
  end

  def exteriorSurface(model, surface)
    # Create an external node?
    return if surface.outsideBoundaryCondition.start_with?('Ground')
    # Create a surface linkage
    link = surface.getAirflowNetworkSurface(@exteriorCrack)
  end
end

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

# add ASHRAE System type 03, PSZ-AC
# model.add_hvac({"ashrae_sys_num" => '03'})

zone = model.getThermalZones[0] # There should only be one...

# add ASHRAE System type 08, VAV w/ PFP Boxes
# DLM: this invokes weird mass conservation rules with VAV
# model.add_hvac({"ashrae_sys_num" => '08'})

# add thermostats
# model.add_thermostats({"heating_setpoint" => 24, "cooling_setpoint" => 28})

# assign constructions from a local library to the walls/windows/etc. in the model
model.set_constructions

# set whole building space type; simplified 90.1-2004 Large Office Whole Building
model.set_space_type

# remove all infiltration
model.getSpaceInfiltrationDesignFlowRates.each(&:remove)

# add design days to the model (Chicago)
model.add_design_days

# add simulation control
afn_control = model.getAirflowNetworkSimulationControl
afn_control.setAirflowNetworkControl('MultizoneWithoutDistribution')

# In order to produce more consistent results between different runs,
# we sort the zones by names
# It doesn't matter here since there's only ony, but just in case
zones = model.getThermalZones.sort_by { |z| z.name.to_s }

# make an afn zone
zone = zones[0] # There should only be one...
afnzone = zone.getAirflowNetworkZone

# Connect up envelope
visitor = SurfaceNetworkBuilder.new(model)

# add output reports
add_out_vars = false
if add_out_vars
  OpenStudio::Model::OutputVariable.new('AFN Node Temperature', model)
  OpenStudio::Model::OutputVariable.new('AFN Node Wind Pressure', model)
  OpenStudio::Model::OutputVariable.new('AFN Linkage Node 1 to Node 2 Mass Flow Rate', model)
  OpenStudio::Model::OutputVariable.new('AFN Linkage Node 1 to Node 2 Pressure Difference', model)
end

# save the OpenStudio model (.osm)
model.save_openstudio_osm({ 'osm_save_directory' => Dir.pwd,
                            'osm_name' => 'in.osm' })
