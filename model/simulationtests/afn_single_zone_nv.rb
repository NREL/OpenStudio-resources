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
    if !surface.outsideBoundaryCondition().start_with?('Ground') then
      # Create a surface linkage
      link = surface.createAirflowNetworkSurface(@interiorCrack)
    end
  end

  def interiorRoofCeiling(model, surface, adjacentSurface)
    # Create a surface linkage
    link = surface.createAirflowNetworkSurface.new(@interiorCrack)
  end

  def interiorWall(model, surface, adjacentSurface)
    # Create a surface linkage
    link = surface.createAirflowNetworkSurface(@interiorCrack)
  end

  def exteriorSurface(model, surface)
    # Create an external node?
    if !surface.outsideBoundaryCondition().start_with?('Ground') then
      # Create a surface linkage
      link = surface.createAirflowNetworkSurface(@exteriorCrack)
    end
  end
end


model = BaselineModel.new

#make a 1 story, 100m X 50m, 1 zone building
model.add_geometry({"length" => 100,
              "width" => 50,
              "num_floors" => 1,
              "floor_to_floor_height" => 4,
              "plenum_height" => 0,
              "perimeter_zone_depth" => 0})

#add windows at a 40% window-to-wall ratio
model.add_windows({"wwr" => 0.4,
                  "offset" => 1,
                  "application_type" => "Above Floor"})
        
#add ASHRAE System type 03, PSZ-AC
#model.add_hvac({"ashrae_sys_num" => '03'})

#add ASHRAE System type 08, VAV w/ PFP Boxes
#DLM: this invokes weird mass conservation rules with VAV
#model.add_hvac({"ashrae_sys_num" => '08'})

#add thermostats
#model.add_thermostats({"heating_setpoint" => 24, "cooling_setpoint" => 28})
              
#assign constructions from a local library to the walls/windows/etc. in the model
model.set_constructions()

#set whole building space type; simplified 90.1-2004 Large Office Whole Building
model.set_space_type()  

#remove all infiltration
model.getSpaceInfiltrationDesignFlowRates.each do |infil|
  infil.remove
end

#add design days to the model (Chicago)
model.add_design_days()

#add simulation control
afn_control =  model.getAirflowNetworkSimulationControl
afn_control.setAirflowNetworkControl("MultizoneWithoutDistribution")

#make an afn zone
zone = model.getThermalZones()[0] # There should only be one...
optafnzone = zone.createAirflowNetworkZone
afnzone = optafnzone.get

#connect up
visitor = SurfaceNetworkBuilder.new(model)

# add output reports
OpenStudio::Model::OutputVariable.new("AFN Node Temperature", model)
OpenStudio::Model::OutputVariable.new("AFN Node Wind Pressure", model)
OpenStudio::Model::OutputVariable.new("AFN Linkage Node 1 to Node 2 Mass Flow Rate", model)
OpenStudio::Model::OutputVariable.new("AFN Linkage Node 1 to Node 2 Pressure Difference", model)
 
#save the OpenStudio model (.osm)
model.save_openstudio_osm({"osm_save_directory" => Dir.pwd,
                           "osm_name" => "in.osm"})
