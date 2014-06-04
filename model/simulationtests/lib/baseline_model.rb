
require 'openstudio'

class BaselineModel < OpenStudio::Model::Model

  def add_geometry(params)
    length = params["length"]
    width = params["width"]
    num_floors = params["num_floors"]
    floor_to_floor_height = params["floor_to_floor_height"]
    plenum_height = params["plenum_height"]
    perimeter_zone_depth = params["perimeter_zone_depth"]
    
    #input error checking
    if length <= 1e-4
      return false
    end
    
    if width <= 1e-4
      return false
    end
    
    if num_floors <= 1e-4
      return false
    end
    
    if floor_to_floor_height <= 1e-4
      return false
    end
    
    if plenum_height < 0
      return false
    end
    
    shortest_side = [length,width].min
    if perimeter_zone_depth < 0 or 2*perimeter_zone_depth >= (shortest_side - 1e-4)
      return false
    end
        
    #Loop through the number of floors
    for floor in (0..num_floors-1)
      
      z = floor_to_floor_height * floor
      
      #Create a new story within the building
      story = OpenStudio::Model::BuildingStory.new(self)
      story.setNominalFloortoFloorHeight(floor_to_floor_height)
      story.setName("Story #{floor+1}")
      
      nw_point = OpenStudio::Point3d.new(0,width,z)
      ne_point = OpenStudio::Point3d.new(length,width,z)
      se_point = OpenStudio::Point3d.new(length,0,z)
      sw_point = OpenStudio::Point3d.new(0,0,z)
      
      # Identity matrix for setting space origins
      m = OpenStudio::Matrix.new(4,4,0)
        m[0,0] = 1
        m[1,1] = 1
        m[2,2] = 1
        m[3,3] = 1
      
      #Define polygons for a rectangular building
      if perimeter_zone_depth > 0
        perimeter_nw_point = nw_point + OpenStudio::Vector3d.new(perimeter_zone_depth,-perimeter_zone_depth,0)
        perimeter_ne_point = ne_point + OpenStudio::Vector3d.new(-perimeter_zone_depth,-perimeter_zone_depth,0)
        perimeter_se_point = se_point + OpenStudio::Vector3d.new(-perimeter_zone_depth,perimeter_zone_depth,0)
        perimeter_sw_point = sw_point + OpenStudio::Vector3d.new(perimeter_zone_depth,perimeter_zone_depth,0)
      
        west_polygon = OpenStudio::Point3dVector.new
          west_polygon << sw_point
          west_polygon << nw_point
          west_polygon << perimeter_nw_point
          west_polygon << perimeter_sw_point
        west_space = OpenStudio::Model::Space::fromFloorPrint(west_polygon, floor_to_floor_height, self)
        west_space = west_space.get
        m[0,3] = sw_point.x
        m[1,3] = sw_point.y
        m[2,3] = sw_point.z
        west_space.changeTransformation(OpenStudio::Transformation.new(m))
        west_space.setBuildingStory(story)
        west_space.setName("Story #{floor+1} West Perimeter Space")
  
        north_polygon = OpenStudio::Point3dVector.new
          north_polygon << nw_point
          north_polygon << ne_point
          north_polygon << perimeter_ne_point
          north_polygon << perimeter_nw_point
        north_space = OpenStudio::Model::Space::fromFloorPrint(north_polygon, floor_to_floor_height, self)
        north_space = north_space.get
        m[0,3] = perimeter_nw_point.x
        m[1,3] = perimeter_nw_point.y
        m[2,3] = perimeter_nw_point.z
        north_space.changeTransformation(OpenStudio::Transformation.new(m))
        north_space.setBuildingStory(story)
        north_space.setName("Story #{floor+1} North Perimeter Space")
        
        east_polygon = OpenStudio::Point3dVector.new
          east_polygon << ne_point
          east_polygon << se_point
          east_polygon << perimeter_se_point
          east_polygon << perimeter_ne_point
        east_space = OpenStudio::Model::Space::fromFloorPrint(east_polygon, floor_to_floor_height, self)
        east_space = east_space.get
        m[0,3] = perimeter_se_point.x
        m[1,3] = perimeter_se_point.y
        m[2,3] = perimeter_se_point.z
        east_space.changeTransformation(OpenStudio::Transformation.new(m))
        east_space.setBuildingStory(story)
        east_space.setName("Story #{floor+1} East Perimeter Space")
        
        south_polygon = OpenStudio::Point3dVector.new
          south_polygon << se_point
          south_polygon << sw_point
          south_polygon << perimeter_sw_point
          south_polygon << perimeter_se_point
        south_space = OpenStudio::Model::Space::fromFloorPrint(south_polygon, floor_to_floor_height, self)
        south_space = south_space.get
        m[0,3] = sw_point.x
        m[1,3] = sw_point.y
        m[2,3] = sw_point.z
        south_space.changeTransformation(OpenStudio::Transformation.new(m))
        south_space.setBuildingStory(story)
        south_space.setName("Story #{floor+1} South Perimeter Space")
        
        core_polygon = OpenStudio::Point3dVector.new
          core_polygon << perimeter_sw_point
          core_polygon << perimeter_nw_point
          core_polygon << perimeter_ne_point
          core_polygon << perimeter_se_point
        core_space = OpenStudio::Model::Space::fromFloorPrint(core_polygon, floor_to_floor_height, self)
        core_space = core_space.get
        m[0,3] = perimeter_sw_point.x
        m[1,3] = perimeter_sw_point.y
        m[2,3] = perimeter_sw_point.z
        core_space.changeTransformation(OpenStudio::Transformation.new(m))
        core_space.setBuildingStory(story)
        core_space.setName("Story #{floor+1} Core Space")
        
      # Minimal zones
      else
        core_polygon = OpenStudio::Point3dVector.new
          core_polygon << sw_point
          core_polygon << nw_point
          core_polygon << ne_point
          core_polygon << se_point
        core_space = OpenStudio::Model::Space::fromFloorPrint(core_polygon, floor_to_floor_height, self)
        core_space = core_space.get
        m[0,3] = sw_point.x
        m[1,3] = sw_point.y
        m[2,3] = sw_point.z
        core_space.changeTransformation(OpenStudio::Transformation.new(m))
        core_space.setBuildingStory(story)
        core_space.setName("Story #{floor+1} Core Space")
        
      end
      
      #Set vertical story position
      story.setNominalZCoordinate(z)
      
    end #End of floor loop
    
    #Put all of the spaces in the model into a vector
    spaces = OpenStudio::Model::SpaceVector.new
    self.getSpaces.each { |space| spaces << space }

    #Match surfaces for each space in the vector
    OpenStudio::Model.matchSurfaces(spaces) 
    
    #Apply a thermal zone to each space in the model if that space has no thermal zone already
    self.getSpaces.each do |space|
      if space.thermalZone.empty?
        new_thermal_zone = OpenStudio::Model::ThermalZone.new(self)
        space.setThermalZone(new_thermal_zone)
      end
    end
    
  end
  
  def add_windows(params)
    wwr = params["wwr"]
    offset = params["offset"]
    application_type = params["application_type"]
    
    #input checking
    if not wwr or not offset or not application_type
      return false
    end

    if wwr <= 0 or wwr >= 1
      return false
    end

    if offset <= 0
      return false
    end

    heightOffsetFromFloor = nil
    if application_type == "Above Floor"
      heightOffsetFromFloor = true
    else
      heightOffsetFromFloor = false
    end
    
    self.getSurfaces.each do |s|
      next if not s.outsideBoundaryCondition == "Outdoors"
      new_window = s.setWindowToWallRatio(wwr, offset, heightOffsetFromFloor)
    end
  
  end
  
  def add_daylighting(params)
    shades = params["shades"]
    
    shading_control_hash = Hash.new
    
    self.getThermalZones.each do |zone|
      biggestWindow = nil
      zone.spaces.each do |space|
        space.surfaces.each do |surface|
          if surface.surfaceType == "Wall" and surface.outsideBoundaryCondition == "Outdoors" 
            surface.subSurfaces.each do |subSurface|
              if subSurface.subSurfaceType == "FixedWindow" or subSurface.subSurfaceType == "OperableWindow"
                if biggestWindow.nil? or subSurface.netArea > biggestWindow.netArea
                  biggestWindow = subSurface
                end 
                
                if shades
                  construction = subSurface.construction.get
                  shading_control = shading_control_hash[construction.handle.to_s]
                  if not shading_control
                    material = OpenStudio::Model::Blind.new(self)
                    shading_control = OpenStudio::Model::ShadingControl.new(material)
                    shading_control_hash[construction.handle.to_s] = shading_control
                  end
                  subSurface.setShadingControl(shading_control)
                  
                end
              end
            end
          end
        end
      end
      
      if biggestWindow
        vertices = biggestWindow.vertices
        centroid = OpenStudio::getCentroid(vertices).get
        outwardNormal = biggestWindow.outwardNormal
        outwardNormal.setLength(-2.0)
        position = centroid + outwardNormal
        offsetX = 0.0
        offsetY = 0.0
        offsetZ = -1.0
        
        dc = OpenStudio::Model::DaylightingControl.new(self)
        dc.setSpace(biggestWindow.surface.get.space.get)
        dc.setPositionXCoordinate(position.x + offsetX)
        dc.setPositionYCoordinate(position.y + offsetY)
        dc.setPositionZCoordinate(position.z + offsetZ)
        zone.setPrimaryDaylightingControl(dc)
        
        ill = OpenStudio::Model::IlluminanceMap.new(self)
        ill.setSpace(biggestWindow.surface.get.space.get)
        ill.setOriginXCoordinate(position.x + offsetX - 0.5)
        ill.setOriginYCoordinate(position.y + offsetY - 0.5)
        ill.setOriginZCoordinate(position.z + offsetZ)
        ill.setXLength(1)
        ill.setYLength(1)
        zone.setIlluminanceMap(ill)
  
      end
    end
    
  end

  def add_hvac(params)
    sys_num = params["ashrae_sys_num"]
    
    sys_num_array = ['01','02','03','04','05','06','07','08','09','10']

    #check the requested system number
    unless sys_num_array.include? sys_num
      puts "System type: #{sys_num} is not a valid choice"
      exit
    end
    
    #get the thermal zones in the self
    zones = self.getThermalZones

    #Add HVAC system type
    case sys_num
      #1: PTAC, Residential
      when '01' 
        hvac = OpenStudio::Model::addSystemType1(self, zones)
      #2: PTHP, Residential
      when '02'
        hvac = OpenStudio::Model::addSystemType2(self, zones)
      #3: PSZ-AC
      when '03'
        zones.each do|zone|
          hvac = OpenStudio::Model::addSystemType3(self)
          hvac = hvac.to_AirLoopHVAC.get
          hvac.addBranchForZone(zone)      
          outlet_node = hvac.supplyOutletNode
          setpoint_manager = outlet_node.getSetpointManagerSingleZoneReheat.get  
          setpoint_manager.setControlZone(zone)
        end
      #4: PSZ-HP
      when '04'
       zones.each do|zone|
          hvac = OpenStudio::Model::addSystemType4(self)
          hvac = hvac.to_AirLoopHVAC.get
          hvac.addBranchForZone(zone)
          outlet_node = hvac.supplyOutletNode
          setpoint_manager = outlet_node.getSetpointManagerSingleZoneReheat.get  
          setpoint_manager.setControlZone(zone)
        end
      #5: Packaged VAV w/ Reheat
      when '05'
        hvac = OpenStudio::Model::addSystemType5(self)
        hvac = hvac.to_AirLoopHVAC.get      
        zones.each do|zone|
          hvac.addBranchForZone(zone)      
        end
      #6: Packaged VAV w/ PFP Boxes
      when '06'
        hvac = OpenStudio::Model::addSystemType6(self)
        hvac = hvac.to_AirLoopHVAC.get      
        zones.each do|zone|
          hvac.addBranchForZone(zone)      
        end
      #7: VAV w/ Reheat
      when '07'
        hvac = OpenStudio::Model::addSystemType7(self)
        hvac = hvac.to_AirLoopHVAC.get      
        zones.each do|zone|
          hvac.addBranchForZone(zone)      
        end
      #8: VAV w/ PFP Boxes
      when '08'
        hvac = OpenStudio::Model::addSystemType8(self)
        hvac = hvac.to_AirLoopHVAC.get      
        zones.each do|zone|
          hvac.addBranchForZone(zone)      
        end
      #9: Warm air furnace, gas fired
      when '09'
        zones.each do|zone|
          hvac = OpenStudio::Model::addSystemType9(self)  
          hvac = hvac.to_AirLoopHVAC.get
          hvac.addBranchForZone(zone)      
          outlet_node = hvac.supplyOutletNode
          setpoint_manager = outlet_node.getSetpointManagerSingleZoneReheat.get  
          setpoint_manager.setControlZone(zone)
        end
      #10: Warm air furnace, electric
      when '10'
        zones.each do|zone|
          hvac = OpenStudio::Model::addSystemType10(self)  
          hvac = hvac.to_AirLoopHVAC.get
          hvac.addBranchForZone(zone)      
          outlet_node = hvac.supplyOutletNode
          setpoint_manager = outlet_node.getSetpointManagerSingleZoneReheat.get  
          setpoint_manager.setControlZone(zone)
        end
      #if system number is not recognized  
      else 
        puts 'cannot find system number ' + sys_num
    end    
    
  end

  def set_constructions()
    construction_library_path = "#{File.dirname(__FILE__)}/baseline_model_constructions.osm"

    #make sure the file exists on the filesystem; if it does, open it
    construction_library_path = OpenStudio::Path.new(construction_library_path)
    if OpenStudio::exists(construction_library_path)
      construction_library = OpenStudio::IdfFile::load(construction_library_path, "OpenStudio".to_IddFileType).get
    else
      puts "#{construction_library_path} couldn't be found"
    end

    #add the objects in the construction library to the model
    self.addObjects(construction_library.objects)
    
    #apply the newly-added construction set to the model
    building = self.getBuilding
    default_construction_set = OpenStudio::Model::getDefaultConstructionSets(self)[0]
    building.setDefaultConstructionSet(default_construction_set)
  
  end
  
  def set_space_type()
  
    #method for converting from IP to SI if you know the strings of the input and the output
    def ip_to_si(number, ip_unit_string, si_unit_string)     
      ip_unit = OpenStudio::createUnit(ip_unit_string, "IP".to_UnitSystem).get
      si_unit = OpenStudio::createUnit(si_unit_string, "SI".to_UnitSystem).get
      #puts "#{ip_unit} --> #{si_unit}"
      ip_quantity = OpenStudio::Quantity.new(number, ip_unit)
      si_quantity = OpenStudio::convert(ip_quantity, si_unit).get
      #puts "#{ip_quantity} = #{si_quantity}" 
      return si_quantity.value
    end
  
    #baseline space type taken from 90.1-2004 Large Office, Whole Building on-demand space type generator
    space_type = OpenStudio::Model::SpaceType.new(self)
    space_type.setName("Baseline Model Space Type")
    
    #create the schedule set for the space type
    default_sch_set = OpenStudio::Model::DefaultScheduleSet.new(self)
    default_sch_set.setName("Baseline Model Schedule Set")
    space_type.setDefaultScheduleSet(default_sch_set)   
    
    #schedule for infiltration
    sch_ruleset = OpenStudio::Model::ScheduleRuleset.new(self)
    sch_ruleset.setName("Baseline Model Infiltration Schedule")  
    #Winter Design Day
    winter_dsn_day = OpenStudio::Model::ScheduleDay.new(self)  
    sch_ruleset.setWinterDesignDaySchedule(winter_dsn_day)
    winter_dsn_day = sch_ruleset.winterDesignDaySchedule
    winter_dsn_day.setName("Baseline Model Infiltration Schedule Winter Design Day")
    winter_dsn_day.addValue(OpenStudio::Time.new(0, 24, 0, 0), 1 )
    #Summer Design Day
    summer_dsn_day = OpenStudio::Model::ScheduleDay.new(self)
    sch_ruleset.setSummerDesignDaySchedule(summer_dsn_day)
    summer_dsn_day = sch_ruleset.summerDesignDaySchedule
    summer_dsn_day.setName("Baseline Model Infiltration Schedule Summer Design Day")
    summer_dsn_day.addValue(OpenStudio::Time.new(0, 24, 0, 0), 1 )
    #Weekdays
    week_day = sch_ruleset.defaultDaySchedule  
    week_day.setName("Baseline Model Infiltration Schedule Schedule All Days")
    week_day.addValue(OpenStudio::Time.new(0, 6, 0, 0), 1 )     
    week_day.addValue(OpenStudio::Time.new(0, 22, 0, 0), 0.25 )     
    week_day.addValue(OpenStudio::Time.new(0, 24, 0, 0), 1 )     
    #set the infiltration schedule
    infiltration_sch = default_sch_set.setInfiltrationSchedule(sch_ruleset)
  
    #schedule for occupancy, lights, electric equipment
    sch_ruleset = OpenStudio::Model::ScheduleRuleset.new(self)
    sch_ruleset.setName("Baseline Model People Lights and Equipment Schedule")  
    #Winter Design Day
    winter_dsn_day = OpenStudio::Model::ScheduleDay.new(self)  
    sch_ruleset.setWinterDesignDaySchedule(winter_dsn_day)
    winter_dsn_day = sch_ruleset.winterDesignDaySchedule
    winter_dsn_day.setName("Baseline Model People Lights and Equipment Schedule Winter Design Day")
    winter_dsn_day.addValue(OpenStudio::Time.new(0, 24, 0, 0), 0 )
    #Summer Design Day
    summer_dsn_day = OpenStudio::Model::ScheduleDay.new(self)
    sch_ruleset.setSummerDesignDaySchedule(summer_dsn_day)
    summer_dsn_day = sch_ruleset.summerDesignDaySchedule
    summer_dsn_day.setName("Baseline Model People Lights and Equipment Schedule Summer Design Day")
    summer_dsn_day.addValue(OpenStudio::Time.new(0, 24, 0, 0), 1 )
    #Weekdays
    week_day = sch_ruleset.defaultDaySchedule  
    week_day.setName("Baseline Model People Lights and Equipment Schedule Schedule Week Day")
    week_day.addValue(OpenStudio::Time.new(0, 6, 0, 0), 0 )     
    week_day.addValue(OpenStudio::Time.new(0, 7, 0, 0), 0.1 )     
    week_day.addValue(OpenStudio::Time.new(0, 8, 0, 0), 0.2 )     
    week_day.addValue(OpenStudio::Time.new(0, 12, 0, 0), 0.95 )     
    week_day.addValue(OpenStudio::Time.new(0, 13, 0, 0), 0.5 )     
    week_day.addValue(OpenStudio::Time.new(0, 17, 0, 0), 0.95 )     
    week_day.addValue(OpenStudio::Time.new(0, 18, 0, 0), 0.7 )     
    week_day.addValue(OpenStudio::Time.new(0, 20, 0, 0), 0.4 )     
    week_day.addValue(OpenStudio::Time.new(0, 22, 0, 0), 0.1 )     
    week_day.addValue(OpenStudio::Time.new(0, 24, 0, 0), 0.05 )
    #Saturdays
    saturday_rule = OpenStudio::Model::ScheduleRule.new(sch_ruleset)
    saturday_rule.setName("Baseline Model People Lights and Equipment Schedule Saturday Rule")
    saturday_rule.setApplySaturday(true)   
    saturday = saturday_rule.daySchedule  
    saturday.setName("Baseline Model People Lights and Equipment Schedule Saturday")
    saturday.addValue(OpenStudio::Time.new(0, 6, 0, 0), 0 )
    saturday.addValue(OpenStudio::Time.new(0, 8, 0, 0), 0.1 )
    saturday.addValue(OpenStudio::Time.new(0, 14, 0, 0), 0.5 )
    saturday.addValue(OpenStudio::Time.new(0, 17, 0, 0), 0.1 )
    saturday.addValue(OpenStudio::Time.new(0, 24, 0, 0), 0 )
    #Sundays
    sunday_rule = OpenStudio::Model::ScheduleRule.new(sch_ruleset)
    sunday_rule.setName("Baseline Model People Lights and Equipment Schedule Sunday Rule")
    sunday_rule.setApplySunday(true)   
    sunday = sunday_rule.daySchedule  
    sunday.setName("Baseline Model People Lights and Equipment Schedule Schedule Sunday")
    sunday.addValue(OpenStudio::Time.new(0, 24, 0, 0), 0 )
    #assign the schedule to the ruleset
    default_sch_set.setNumberofPeopleSchedule(sch_ruleset)
    default_sch_set.setLightingSchedule(sch_ruleset)
    default_sch_set.setElectricEquipmentSchedule(sch_ruleset)
    
    #schedule for occupant activity level = 120 W constant
    occ_activity_sch = OpenStudio::Model::ScheduleRuleset.new(self)
    occ_activity_sch.setName("Baseline Model People Activity Schedule")
    occ_activity_sch.defaultDaySchedule.setName("Baseline Model People Activity Schedule Default")
    occ_activity_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0, 24, 0, 0), 120 )
    default_sch_set.setPeopleActivityLevelSchedule(occ_activity_sch)
        
    #outdoor air = 0.0094 m^3/s*person (20 cfm/person)
    ventilation = OpenStudio::Model::DesignSpecificationOutdoorAir.new(self)
    ventilation.setName("Baseline Model OA")
    space_type.setDesignSpecificationOutdoorAir(ventilation)
    ventilation.setOutdoorAirMethod("Sum")
    ventilation.setOutdoorAirFlowperPerson(ip_to_si(20,"ft^3/min*person","m^3/s*person"))
    
    #infiltration = 0.00030226 m^3/s*m^2 exterior (0.06 cfm/ft^2 exterior)
    make_infiltration = false
    infiltration = OpenStudio::Model::SpaceInfiltrationDesignFlowRate.new(self)
    infiltration.setName("Baseline Model Infiltration")
    infiltration.setSpaceType(space_type)
    infiltration.setFlowperExteriorSurfaceArea(ip_to_si(0.06,"ft^3/min*ft^2","m^3/s*m^2"))
    
    #people = 0.053820 people/m^2 (0.005 people/ft^2)
    #create the people definition
    people_def = OpenStudio::Model::PeopleDefinition.new(self)
    people_def.setName("Baseline Model People Definition")
    people_def.setPeopleperSpaceFloorArea(ip_to_si(0.005,"people/ft^2","people/m^2"))
    #create the people instance and hook it up to the space type
    people = OpenStudio::Model::People.new(people_def)
    people.setName("Baseline Model People")
    people.setSpaceType(space_type)
    
    #lights = 10.763910 W/m^2 (1 W/ft^2)
    #create the lighting definition 
    lights_def = OpenStudio::Model::LightsDefinition.new(self)
    lights_def.setName("Baseline Model Lights Definition")
    lights_def.setWattsperSpaceFloorArea(ip_to_si(1,"W/ft^2","W/m^2"))
    #create the lighting instance and hook it up to the space type
    lights = OpenStudio::Model::Lights.new(lights_def)
    lights.setName("Baseline Model Lights")
    lights.setSpaceType(space_type)  
    
    #equipment = 10.763910 W/m^2 (1 W/ft^2)
    #create the electric equipment definition
    elec_equip_def = OpenStudio::Model::ElectricEquipmentDefinition.new(self)
    elec_equip_def.setName("Baseline Model Electric Equipment Definition")  
    elec_equip_def.setWattsperSpaceFloorArea(ip_to_si(1,"W/ft^2","W/m^2"))
    #create the electric equipment instance and hook it up to the space type
    elec_equip = OpenStudio::Model::ElectricEquipment.new(elec_equip_def)
    elec_equip.setName("Baseline Model Electric Equipment")
    elec_equip.setSpaceType(space_type)
           
    #set the space type of all spaces by setting it at the building level
    self.getBuilding.setSpaceType(space_type)

  end

  def add_thermostats(params)
    
    heating_setpoint = params["heating_setpoint"]
    cooling_setpoint = params["cooling_setpoint"]
    
    time_24hrs = OpenStudio::Time.new(0,24,0,0)

    cooling_sch = OpenStudio::Model::ScheduleRuleset.new(self)
    cooling_sch.setName("Cooling Sch")
    cooling_sch.defaultDaySchedule.setName("Cooling Sch Default")
    cooling_sch.defaultDaySchedule.addValue(time_24hrs,cooling_setpoint)

    heating_sch = OpenStudio::Model::ScheduleRuleset.new(self)
    heating_sch.setName("Heating Sch")
    heating_sch.defaultDaySchedule.setName("Heating Sch Default")
    heating_sch.defaultDaySchedule.addValue(time_24hrs,heating_setpoint)      

    new_thermostat = OpenStudio::Model::ThermostatSetpointDualSetpoint.new(self)
    
    new_thermostat.setHeatingSchedule(heating_sch)
    new_thermostat.setCoolingSchedule(cooling_sch)
    
    self.getThermalZones.each do |zone|
      zone.setThermostatSetpointDualSetpoint(new_thermostat)
    end

  end  
  
  def save_openstudio_osm(params)
  
    osm_save_directory = params["osm_save_directory"]
    osm_name = params["osm_name"]
  
    save_path = OpenStudio::Path.new("#{osm_save_directory}/#{osm_name}")
    self.save(save_path,true)
    
  end
  
  def add_design_days()
      
    require 'openstudio/energyplus/find_energyplus'
     
    # find energyplus
    ep_hash = OpenStudio::EnergyPlus::find_energyplus(8,0)
    weather_path = OpenStudio::Path.new(ep_hash[:energyplus_weatherdata].to_s)
      
    #load the design days for Chicago
    ddy_path = OpenStudio::Path.new("#{weather_path.to_s}/USA_IL_Chicago-OHare.Intl.AP.725300_TMY3.ddy")    
    #make sure the file exists on the filesystem; if it does, open it
    if OpenStudio::exists(ddy_path)
      ddy_idf = OpenStudio::IdfFile::load(ddy_path, "EnergyPlus".to_IddFileType).get
      ddy_workspace = OpenStudio::Workspace.new(ddy_idf)
      reverse_translator = OpenStudio::EnergyPlus::ReverseTranslator.new()
      ddy_model = reverse_translator.translateWorkspace(ddy_workspace)
      ddy_objects = ddy_model.getDesignDays().select { |d| d.name.get.include?('.4%') || d.name.get.include?('99.6%') }
      #add the objects in the ddy file to the model
      self.addObjects(ddy_objects)
    else
      puts "#{ddy_path} couldn't be found"
    end  

  end
  
  def self.run_energyplus_simulation(params)
    
    require 'openstudio/energyplus/find_energyplus'

    idf_directory = params["idf_directory"]
    idf_name = params["idf_name"]
     
    # find energyplus
    ep_hash = OpenStudio::EnergyPlus::find_energyplus(8,0)
    ep_path = OpenStudio::Path.new(ep_hash[:energyplus_exe].to_s)
    idd_path = OpenStudio::Path.new(ep_hash[:energyplus_idd].to_s)
    weather_path = OpenStudio::Path.new(ep_hash[:energyplus_weatherdata].to_s)

    # just run in Chicago for now
    #weather_paths = Dir.glob("#{weather_path.to_s}/USA_IL_Chicago-OHare.Intl.AP.725300_TMY3.epw")
    #raise "Unable to find weather files." if weather_paths.empty?
    #epw_path = OpenStudio::Path.new(weather_paths.first)
    epw_path = OpenStudio::Path.new("#{weather_path.to_s}/USA_IL_Chicago-OHare.Intl.AP.725300_TMY3.epw")
        
    # make a run manager
    run_manager_db_path = OpenStudio::Path.new("#{idf_directory}/VirtualPULSE.db")
    run_manager = OpenStudio::Runmanager::RunManager.new(run_manager_db_path, true)

    #setup tool info to pass run manager the location of energy plus
    ep_tool = OpenStudio::Runmanager::ToolInfo.new(ep_path)
    ep_tool_info = OpenStudio::Runmanager::Tools.new()
    ep_tool_info.append(ep_tool)

    #get the run manager configuration options
    config_options = run_manager.getConfigOptions()

    sys_num_array = Array.new

    idf_path = OpenStudio::Path.new("#{idf_directory}/#{idf_name}")
    
    output_path = OpenStudio::Path.new("#{idf_directory}/ENERGYPLUS/#{idf_name}")

    #make the ENERGYPLUS directory to store the results
    output_path_string = File.dirname(output_path.to_s)
      
    # make a job for the file we want to run
    job = OpenStudio::Runmanager::JobFactory::createEnergyPlusJob(ep_tool,
                                                                 idd_path,
                                                                 idf_path,
                                                                 epw_path,
                                                                 output_path)
    
    #put the job in the run queue
    run_manager.enqueue(job, true)

    # wait for jobs to complete
    while run_manager.workPending()
      sleep 1
      OpenStudio::Application::instance().processEvents()
    end

    puts "finished running #{idf_name}"

  end  
  
end
