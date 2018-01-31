require 'openstudio'
require 'lib/baseline_model'

m = BaselineModel.new

# make a 1 story, 100m X 50m, 5 zone core/perimeter building
m.add_geometry({"length" => 100,
                "width" => 50,
                "num_floors" => 1,
                "floor_to_floor_height" => 3,
                "plenum_height" => 1,
                "perimeter_zone_depth" => 3})

# add windows at a 40% window-to-wall ratio
m.add_windows({"wwr" => 0.4,
               "offset" => 1,
               "application_type" => "Above Floor"})

# Add ASHRAE System type 07, VAV w/ Reheat, this creates a ChW, a HW loop and a
# Condenser Loop
m.add_hvac({"ashrae_sys_num" => '07'})


# add thermostats
m.add_thermostats({"heating_setpoint" => 24,
                   "cooling_setpoint" => 28})

# assign constructions from a local library to the walls/windows/etc. in the model
m.set_constructions()

# set whole building space type; simplified 90.1-2004 Large Office Whole Building
m.set_space_type()

# add design days to the model (Chicago)
m.add_design_days()




ct = m.getCoolingTowerSingleSpeeds.first
p_cnd = ct.plantLoop.get

b = m.getBoilerHotWaters.first
p_hw = b.plantLoop.get

ch = m.getChillerElectricEIRs.first
p_chw = ch.plantLoop.get


# Create a central heat pump system and two modules
central_hp = OpenStudio::Model::CentralHeatPumpSystem.new(m)
central_hp.setName("CentralHeatPumpSystem")

central_hp_module = OpenStudio::Model::CentralHeatPumpSystemModule.new(m)
central_hp.addModule(central_hp_module)

central_hp_module2 = OpenStudio::Model::CentralHeatPumpSystemModule.new(m)
central_hp.addModule(central_hp_module2)
central_hp_module2.setNumberofChillerHeaterModules(2)

# Add to to the demand side of the condenser loop
p_cnd.addDemandBranchForComponent(central_hp)

# Supply side of the chw loop, remove chiller
ch.remove
p_chw.addSupplyBranchForComponent(central_hp)

# Supply side to HW loop: tertiary. Remove boiler
# Since we need to use addToTertiaryNode,
# The trick is to add it to the boiler inlet node first, then remove boiler
n = b.inletModelObject.get.to_Node.get
central_hp.addToTertiaryNode(n)
b.remove



###############################################################################
#         R E N A M E    E Q U I P M E N T    A N D    N O D E S
###############################################################################
# Remove pipes
m.getPipeAdiabatics.each {|pipe| pipe.remove}

# Rename loops
p_cnd.setName("CndW Loop")
p_hw.setName("HW Loop")
p_chw.setName("ChW Loop")


m.getCoilCoolingWaters[0].setName("VAV Central ChW Coil")

m.getCoilHeatingWaters.each do |coil|
  next if !coil.airLoopHVAC.is_initialized
  coil.setName("VAV Central HW Coil")
end

a = m.getAirLoopHVACs[0]
a.thermalZones.each do |z|
  atu = z.equipment[0].to_AirTerminalSingleDuctVAVReheat.get
  atu.setName("#{z.name} ATU VAV Reheat")
  atu.reheatCoil.setName("#{z.name} ATU Reheat HW Coil")
end



# Rename nodes
m.getPlantLoops.each do |p|
  prefix = p.name.to_s

  p.supplyComponents.reverse.each do |c|
    next if c.to_Node.is_initialized

    if c.to_ConnectorMixer.is_initialized
      c.setName("#{prefix} Supply ConnectorMixer")
    elsif c.to_ConnectorSplitter.is_initialized
      c.setName("#{prefix} Supply ConnectorSplitter")
    else

      obj_type = c.iddObjectType.valueName
      obj_type_name = obj_type.gsub('OS_','').gsub('_','')

      if c.to_PumpVariableSpeed.is_initialized
        c.setName("#{prefix} VSD Pump")
      elsif c.to_PumpConstantSpeed.is_initialized
        c.setName("#{prefix} CstSpeed Pump")
      elsif c.to_HeaderedPumpsVariableSpeed.is_initialized
        c.setName("#{prefix} Headered VSD Pump")
      elsif c.to_HeaderedPumpsConstantSpeed.is_initialized
        c.setName("#{prefix} Headered CstSpeed Pump")
      elsif !c.to_CentralHeatPumpSystem.is_initialized
        c.setName("#{prefix} #{obj_type_name}")
      end


      method_name = "to_#{obj_type_name}"
      next if !c.respond_to?(method_name)
      actual_thing = c.method(method_name).call
      next if actual_thing.empty?
      actual_thing = actual_thing.get
      if actual_thing.respond_to?("inletModelObject") && actual_thing.inletModelObject.is_initialized
        inlet_mo = actual_thing.inletModelObject.get
        inlet_mo.setName("#{prefix} Supply Side #{actual_thing.name.to_s} Inlet Node")
      end
      if actual_thing.respond_to?("outletModelObject") && actual_thing.outletModelObject.is_initialized
        outlet_mo = actual_thing.outletModelObject.get
        outlet_mo.setName("#{prefix} Supply Side #{actual_thing.name.to_s} Outlet Node")
      end
    end
  end

  p.demandComponents.reverse.each do |c|
    next if c.to_Node.is_initialized

    if c.to_ConnectorMixer.is_initialized
      c.setName("#{prefix} Demand ConnectorMixer")
    elsif c.to_ConnectorSplitter.is_initialized
      c.setName("#{prefix} Demand ConnectorSplitter")
    else
      obj_type = c.iddObjectType.valueName
      obj_type_name = obj_type.gsub('OS_','').gsub('_','')
      method_name = "to_#{obj_type_name}"
      next if !c.respond_to?(method_name)
      actual_thing = c.method(method_name).call
      next if actual_thing.empty?
      actual_thing = actual_thing.get
      if actual_thing.respond_to?("inletModelObject") && actual_thing.inletModelObject.is_initialized
        inlet_mo = actual_thing.inletModelObject.get
        inlet_mo.setName("#{prefix} Demand Side #{actual_thing.name.to_s} Inlet Node")
      end
      if actual_thing.respond_to?("outletModelObject") && actual_thing.outletModelObject.is_initialized
        outlet_mo = actual_thing.outletModelObject.get
        outlet_mo.setName("#{prefix} Demand Side #{actual_thing.name.to_s} Outlet Node")
      end

      # WaterToAirComponent
      if actual_thing.respond_to?("waterInletModelObject") && actual_thing.waterInletModelObject.is_initialized
        inlet_mo = actual_thing.waterInletModelObject.get
        inlet_mo.setName("#{prefix} Demand Side #{actual_thing.name.to_s} Inlet Node")
      end
      if actual_thing.respond_to?("waterOutletModelObject") && actual_thing.waterOutletModelObject.is_initialized
        outlet_mo = actual_thing.waterOutletModelObject.get
        outlet_mo.setName("#{prefix} Demand Side #{actual_thing.name.to_s} Outlet Node")
      end

    end
  end


  node = p.supplyInletNode
  new_name = 'Supply Inlet Node'
  new_name = "#{prefix} #{new_name}"
  node.setName(new_name)

  node = p.supplyOutletNode
  new_name = 'Supply Outlet Node'
  new_name = "#{prefix} #{new_name}"
  node.setName(new_name)

  # Demand Side
  node = p.demandInletNode
  new_name = 'Demand Inlet Node'
  new_name = "#{prefix} #{new_name}"
  node.setName(new_name)

  node = p.demandOutletNode
  new_name = 'Demand Outlet Node'
  new_name = "#{prefix} #{new_name}"
  node.setName(new_name)
end


# central hp has a tertiary loop, so need to do it manually

# Supply = cooling
central_hp.supplyInletModelObject.get.setName("#{central_hp.coolingPlantLoop.get.name} Supply Side #{central_hp.name} Inlet Node")
central_hp.supplyOutletModelObject.get.setName("#{central_hp.coolingPlantLoop.get.name} Supply Side #{central_hp.name} Outlet Node")

# Demand = Source (Condenser)
central_hp.demandInletModelObject.get.setName("#{central_hp.sourcePlantLoop.get.name} Demand Side #{central_hp.name} Inlet Node")
central_hp.demandOutletModelObject.get.setName("#{central_hp.sourcePlantLoop.get.name} Demand Side #{central_hp.name} Outlet Node")

# tertiary = heating
central_hp.tertiaryInletModelObject.get.setName("#{central_hp.heatingPlantLoop.get.name} Supply Side #{central_hp.name} Inlet Node")
central_hp.tertiaryOutletModelObject.get.setName("#{central_hp.heatingPlantLoop.get.name} Supply Side #{central_hp.name} Outlet Node")



########################### Request output variables ##########################

freq = 'Detailed'

# CentralHeatPumpSystem outputs, implemented in the class
central_hp.outputVariableNames.each do |varname|
  outvar = OpenStudio::Model::OutputVariable.new(varname, m)
  outvar.setReportingFrequency(freq)
end


# ChillerHeaterPerformance:Electric:EIR Outputs: one for each Unit, not
# implemented in class (can't be static really...)

n_chiller_heater = central_hp.modules.inject(0){|sum, mod| sum += mod.numberofChillerHeaterModules}

chiller_heater_perf_vars = ['Chiller Heater Operation Mode Unit',
 'Chiller Heater Part Load Ratio Unit',
 'Chiller Heater Cycling Ratio Unit',
 'Chiller Heater Cooling Electric Power Unit',
 'Chiller Heater Heating Electric Power Unit',
 'Chiller Heater Cooling Electric Energy Unit',
 'Chiller Heater Heating Electric Energy Unit',
 'Chiller Heater Cooling Rate Unit',
 'Chiller Heater Cooling Energy Unit',
 'Chiller Heater False Load Heat Transfer Rate Unit',
 'Chiller Heater False Load Heat Transfer Energy Unit',
 'Chiller Heater Evaporator Inlet Temperature Unit',
 'Chiller Heater Evaporator Outlet Temperature Unit',
 'Chiller Heater Evaporator Mass Flow Rate Unit',
 'Chiller Heater Condenser Heat Transfer Rate Unit',
 'Chiller Heater Condenser Heat Transfer Energy Unit',
 'Chiller Heater COP Unit',
 'Chiller Heater Capacity Temperature Modifier Multiplier Unit',
 'Chiller Heater EIR Temperature Modifier Multiplier Unit',
 'Chiller Heater EIR Part Load Modifier Multiplier Unit',
 'Chiller Heater Condenser Inlet Temperature Unit',
 'Chiller Heater Condenser Outlet Temperature Unit',
 'Chiller Heater Condenser Mass Flow Rate Unit']


n_chiller_heater.times do |i|
  chiller_heater_perf_vars.each do |varname|
    outvar = OpenStudio::Model::OutputVariable.new("#{varname} #{i+1}", m)
    outvar.setReportingFrequency(freq)
  end
end


# Due to this bug: https://github.com/NREL/EnergyPlus/issues/6445
# Need to hardsize the Reference capacity of the
# chillerHeaterPerformanceElectricEIR objects
m.getChillerHeaterPerformanceElectricEIRs.each{|comp| comp.setReferenceCoolingModeEvaporatorCapacity(600000)}

# save the OpenStudio model (.osm)
m.save_openstudio_osm({"osm_save_directory" => Dir.pwd,
                       "osm_name" => "in.osm"})

