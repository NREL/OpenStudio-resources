# frozen_string_literal: true

# directories
$Measures_Dir = 'measures'
$IdfSource_Dir = 'C:/EnergyPlusV7-2-0/ExampleFiles'
$Weather_Dir = 'C:/EnergyPlusV7-2-0/WeatherData'
$Template_Dir = 'C:/SVN_OpenStudio_Trunk_Debug_Testing/openstudiocore/ruby/openstudio/sketchup_plugin/resources/templates'

require 'openstudio'
require "#{$Measures_Dir}/Assign_Building_Stories.rb"
require "#{$Measures_Dir}/Remove_HVAC.rb"
require "#{$Measures_Dir}/AddHVACSystem.rb"
require "#{$Measures_Dir}/GetLocalWeatherFile.rb"
require "#{$Measures_Dir}/Cleanup_Origins.rb"
require "#{$Measures_Dir}/RemoveLoadsWithoutSchedules.rb"
require "#{$Measures_Dir}/Remove_Hard_Assigned_Constructions.rb"
require "#{$Measures_Dir}/Remove_Loads_Directly_Assigned_To_Spaces.rb"

# inputs
# sourceIdfName = "RefBldgMediumOfficeNew2004_Chicago.idf"
sourceIdfName = 'RefBldgLargeHotelNew2004_Chicago.idf'
sourceIdfFile = "#{$IdfSource_Dir}/#{sourceIdfName}"
weatherFile = "#{$Weather_Dir}/USA_IL_Chicago-OHare.Intl.AP.725300_TMY3.epw"
saveName = sourceIdfName.gsub('.idf', '')
saveDir = "../../build/testruns/#{saveName}_rb"
templateFile = "#{$Template_Dir}/MediumOffice.osm"
# extra temp inputs that I want to get rid of
templateFile_default_thermostat = 'Medium Office_Thermostat' # later this will lookup by space type map
templateFile_attic_floor_construction = 'ASHRAE_90.1-2004_AtticFloor_ClimateZone 1-5' # later this will lookup by space type map

# add building type specifc lookup map for space types here (to feed space types, constructions, and thermostats)

runner = OpenStudio::Ruleset::UserScriptRunner.new

# copy the raw idf file so it lives next to the OSM models made from it
require 'fileutils'
puts ''
puts 'Saving a copy of the Source IDF file'
FileUtils.mkdir_p saveDir
FileUtils.cp(sourceIdfFile, "#{saveDir}/#{sourceIdfName}")

# make workspace from source idf
puts 'Importing IDF Reference Building'
workspace = OpenStudio::Workspace.load(OpenStudio::Path.new(sourceIdfFile))
rt = OpenStudio::EnergyPlus::ReverseTranslator.new
new_model = rt.translateWorkspace(workspace.get)
model = new_model

# saving untranslated objects to a new file
puts 'Saving Untranslated IDF objects to file'
untranslated = rt.untranslatedIdfObjects
untranslated_file = File.new("#{saveDir}/#{saveName}_untranslated_obj.idf", 'w')
untranslated_file.write(untranslated)
untranslated_file.close

# saving reverse translation errors to a file
puts 'Saving Reverse Translator Errors to file'
errors = rt.errors
errors_file = File.new("#{saveDir}/#{saveName}_errors_obj.idf", 'w')
rt.errors.each do |error|
  errors_file.write("#{error.logMessage}\n")
end
errors_file.close

# saving reverse translation warnings to a file
puts 'Saving Warnings Translator Warnings to file'
puts 'Saving Reverse Translator Errors to file'
warnings = rt.warnings
warnings_file = File.new("#{saveDir}/#{saveName}_warnings_obj.idf", 'w')
rt.warnings.each do |error|
  warnings_file.write("#{error.logMessage}\n")
end
warnings_file.close

# strip out HVAC (maybe this can be done by just importing zones vs. the entire model?)
puts 'Removing HVAC objects'
measure = RemoveHVAC.new
arguments = OpenStudio::Ruleset::UserScriptArgumentMap.new
measure.run(model, nil, arguments)

# infer stories so we can may air loop per story
puts 'Infering Building Stories'
measure = AssignBuildingStories.new
arguments = OpenStudio::Ruleset::UserScriptArgumentMap.new
measure.run(model, runner, arguments)

# clean up zone origins
puts 'Cleaning up Zone Origins'
measure = CleanupOrigins.new
arguments = OpenStudio::Ruleset::UserScriptArgumentMap.new
measure.run(model, runner, arguments)

# removing loads without schedules to get EnergyPlus to run
# eventually the reverse translator should be fixed, and this removed.
puts 'Removing Loads instances without schedules'
measure = RemoveLoadsWithoutSchedules.new
arguments = OpenStudio::Ruleset::UserScriptArgumentMap.new
measure.run(model, runner, arguments)

# set not_in_area flag for model
puts 'Check for spaces not included in total building area'
# attic will show up here as well, and the attic won't want same infiltration loads, so may be an issue
# could add additional test using space name to determine if plenum or attic, or look do some basic test on roof geometry, or int. floor vs. ext roof const (which as bigger R value)
spaces = model.getSpaces
not_in_area_flag = false
not_in_area_spaces = []
in_area_spaces = [] # may want this to feed into HVAC script vs. entire model
spaces.each do |space|
  if !space.partofTotalFloorArea # Brent said this isnt' very relyable on typical IDF models. Will want to map just like any other space type)
    not_in_area_flag = true
    not_in_area_spaces << space
  else
    in_area_spaces << space
  end
end

# if exterior roof conductance > interior floor conductance then flag space as attic. Otherwise flag space as plenum.
puts 'Infering Plenum and Attic Zones'
plenum_spaces = [] # not_in_area_spaces
attic_spaces = []
plenum_flag = false
attic_flag = false

not_in_area_spaces.each do |not_in_area_space|
  # setup empty counductance arrays
  roof_conductance = []
  floor_conductance = []
  # get surfaces in space
  surfaces = not_in_area_space.surfaces
  surfaces.each do |surface|
    # look for surfaces that are type "roof" and boundary "outdoors". Make array and find average conductance
    if (surface.surfaceType == 'RoofCeiling') && (surface.outsideBoundaryCondition == 'Outdoors')
      ext_roof_const = surface.construction.get
      roof_conductance << ext_roof_const.thermalConductance
    end
    # look for surfaces that are type "floor" and boundary "surface" or "outdoors"
    if (surface.surfaceType == 'Floor') && (surface.outsideBoundaryCondition == 'Surface') # need to add in or statement to catch adiabatic
      int_floor_const = surface.construction.get
      floor_conductance << int_floor_const.thermalConductance
    end
  end

  # if avg ext roof > avg int floor then make attic, else push to plenum array
  if !roof_conductance.empty? && !floor_conductance.empty?
    roof_conductance_total = 0.0
    roof_conductance.each { |x| roof_conductance_total = roof_conductance_total.to_f + x.to_f }
    avg_roof_cond = roof_conductance_total / roof_conductance.size
    floor_conductance_total = 0.0
    floor_conductance.each { |y| floor_conductance_total = floor_conductance_total.to_f + y.to_f }
    avg_floor_cond = floor_conductance_total / floor_conductance.size
    if avg_roof_cond > avg_floor_cond
      attic_spaces << not_in_area_space
      attic_flag = true
      puts '> Space '"#{not_in_area_space.name}"" is an attic. Avg ext roof conductance (#{avg_roof_cond}) is greater than avg int floor conductance (#{avg_floor_cond})"
    else
      plenum_spaces << not_in_area_space
      plenum_flag = true
      puts '> Space '"#{not_in_area_space.name}"" is a plenum. Avg ext roof conductance (#{avg_roof_cond}) is less than avg int floor conductance (#{avg_floor_cond})"
    end

  else
    plenum_spaces << not_in_area_space
    plenum_flag = true
    puts '> Space '"#{not_in_area_space.name}"" is a plenum. It doesn't have an exterior roof and an interior floor"
  end
end

# set plenum flag stories if all spaces are plenum spaces
puts 'Making an array of stories in which all spaces are not included in the building area'
stories = model.getBuildingStorys
plenumAttic_stories = []
non_plenumAttic_stories = []
stories.each do |story|
  plenumAttic_story_flag = true
  story_spaces = story.spaces
  story_spaces.each do |story_space|
    # if any space on the story is part of buidling area, then the story gets an HVAC system, but still exclude the plenum spaces invdividually
    if story_space.partofTotalFloorArea
      plenumAttic_story_flag = false
    end
  end
  if plenumAttic_story_flag == true
    plenumAttic_stories << story
  else
    non_plenumAttic_stories << story
  end
end

# adjusting number of non plenum stories for stories where all zones have >1 multiplier
puts 'Calculating adjusted number of storires by looking at ThermalZone multipliers'
adjusted_story_count = 0
non_plenumAttic_stories.each do |story|
  story_spaces = story.spaces
  multipliers = []
  story_spaces.each do |space|
    space_thermal_zone = space.thermalZone.get
    space_thermal_zone_multiplier = space_thermal_zone.multiplier
    multipliers << space_thermal_zone_multiplier
  end
  min_multiplier = multipliers.min
  if min_multiplier > 1
    puts "> Thermal Zones on #{story.name} have a minimum multiplier of #{min_multiplier}"
  end
  adjusted_story_count += multipliers.min
end
if adjusted_story_count > non_plenumAttic_stories.size
  puts "> Raw Story Count is #{non_plenumAttic_stories.size}"
  puts "> Adjusted Story Count is #{adjusted_story_count}"
end

# if all spaces on a story are set to "no" for include in building area, then skip HVAC on this story
# will need input for building sector (use commercial), sqft, and number of floors)
puts 'Calculating inputs for HVAC Measure'
building_sector = 'commercial'
model_building = model.getBuilding
sqft = model_building.floorArea * 10.76 # I confimred that this accounts for zone multipliers
puts "> Building is #{sqft.to_i} square feet"
adjusted_number_of_non_plenumAttic_stories = adjusted_story_count
puts "> Number of Stories: #{adjusted_number_of_non_plenumAttic_stories} (excluding plenum and attic)"

# making on array of zones to condition
# also need to add check for thermostat so un-conditioned spaces that are not plenum show up.
hvac_zones = []
zones = model.getThermalZones
in_area_spaces.each do |non_plenum_space|
  hvac_zones << non_plenum_space.thermalZone.get
end

# add in hvac
puts 'Adding HVAC'
# building_sector
# area_sqft
# number of stories
# array of stories that should have air loops or zone equipment
# array of thermal zones that should be conditioned
measure = AddHVACSystem.new
args = measure.getDefaultArgumentsForNationalGrid(model, building_sector, sqft, adjusted_number_of_non_plenumAttic_stories)
measure.run(model, nil, args)

# add weather file
puts 'Assigning Weather File'
measure = GetLocalWeatherFile.new
arguments = OpenStudio::Ruleset::UserScriptArgumentMap.new
weatherFileArg = OpenStudio::Ruleset::UserScriptArgument.makeStringArgument('epw_path')
weatherFileArg.setValue(weatherFile)
arguments['epw_path'] = weatherFileArg
measure.run(model, nil, arguments)

# set simulation to run for weather file run periods
puts 'Setting Simulation to Run for Weather File Run Period'
sim_control = model.getSimulationControl
sim_control.setRunSimulationforWeatherFileRunPeriods(true)

# change solar distribution
puts 'Setting Soloar Distribution to Full Exterior'
sim_control.setSolarDistribution('FullExterior')

# save the model with original loads and constructions adn thermostats
# this shoudl test the HVAC system and reverse translation
puts 'Saving Model a'
model.save(OpenStudio::Path.new("#{saveDir}/#{saveName}_a.osm"), true)

# run the model

# next strip out hard assigned construction
puts 'Removing Hard Assigned Constructions'
measure = RemoveHardAssignedConstructions.new
arguments = OpenStudio::Ruleset::UserScriptArgumentMap.new
measure.run(model, runner, arguments)

# next strip out internal loads (leave external lighting alone?)
puts 'Removing Internal Loads assigned directly to Spaces'
measure = RemoveLoadsDirectlyAssignedToSpaces.new
arguments = OpenStudio::Ruleset::UserScriptArgumentMap.new
measure.run(model, runner, arguments)

# load template
puts 'Loading building type template to use for next few steps'
model_template = OpenStudio::Model::Model.load(OpenStudio::Path.new(templateFile)).get
template_building = model_template.getBuilding

# import and set default building space type
puts 'Setting Default Space Type for Building'
template_spaceType = template_building.spaceType.get
model_spaceType = template_spaceType.clone(model).to_SpaceType.get
model_building = model.getBuilding
model_building.setSpaceType(model_spaceType)

if plenum_flag
  # apply special SpaceType to plenum spaces. Emtpy excpet for borrowing infiltration from Building Default SpaceType
  # note: our current templates use ACH while BCL on Demand uses per ext area which is what the ref building uses.
  puts 'Creating and assigning Plenum SpaceType with only infiltration and assigning it to attic zones in model'
  plenum_spaceType = OpenStudio::Model::SpaceType.new(model)
  plenum_spaceType.setName('Plenum SpaceType')
  # set infiltration object to match the default space type. (get first object or all of them? At least in our templates only have one)
  model_infiltration_objects = model_spaceType.spaceInfiltrationDesignFlowRates
  model_infiltration_objects.each do |model_infiltration_object|
    plenum_infiltration_object = model_infiltration_object.clone(model).to_SpaceInfiltrationDesignFlowRate.get
    # set name
    plenum_infiltration_object.setName('Plenum Space Infiltration')
    # set space type
    plenum_infiltration_object.setSpaceType(plenum_spaceType)
  end
  # could do space.each do with if not space.partofTotalFloorArea
  plenum_spaces.each do |plenum_space|
    plenum_space.setSpaceType(plenum_spaceType)
  end

end
if attic_flag == true
  puts 'Creating and assigning attic SpaceType with only infiltration and assigning it to attic zones in model'
  # import attic space type
  attic_spaceType = ''
  template_space_types = model_template.getSpaceTypes
  template_space_types.each do |template_space_type|
    if template_space_type.name.to_s == '_Attic'
      attic_spaceType = template_space_type.clone(model).to_SpaceType.get
      break
    end
  end

  # apply attic space type to attic_spaces
  attic_spaces.each do |attic_space|
    attic_space.setSpaceType(attic_spaceType)
  end

end

# set custom space types as needed based on space naming (not required for whole building templates)

# import and set default building construction set
puts 'Setting Default Construction Set for Building'
template_constSet = template_building.defaultConstructionSet.get
model_constSet = template_constSet.clone(model).to_DefaultConstructionSet.get
model_building.setDefaultConstructionSet(model_constSet)

# try and use air gap material to split const apart so it is more generic, e.g. to work on constructions with jsut conc, or conc and carpet.
if plenum_flag
  puts 'Creating and assigning ConstructionSet for Plenums'
  # this will create a mis match, but tie breaker at run time should fix and make mirrored construction if necssary
  plenum_constSet = OpenStudio::Model::DefaultConstructionSet.new(model)
  plenum_constSet.setName('Plenum Construction Set')
  plenum_int_constSet = OpenStudio::Model::DefaultSurfaceConstructions.new(model)
  plenum_int_constSet.setName('Plenum Interior Surface Constructions')
  plenum_constSet.setDefaultInteriorSurfaceConstructions(plenum_int_constSet)

  # this should exist unless something failed earlier. Maybe put in check for it?
  plenum_spaceType.setDefaultConstructionSet(plenum_constSet)

  # clone floor construction and setup in construction set
  model_def_int_surf = model_constSet.defaultInteriorSurfaceConstructions.get
  model_def_int_surf_floor = model_def_int_surf.floorConstruction.get
  plenum_def_int_surf_floor = model_def_int_surf_floor.clone(model).to_Construction.get
  plenum_int_constSet.setFloorConstruction(plenum_def_int_surf_floor)
  plenum_def_int_surf_floor.setName('Plenum Interior Surface Floor')
  # good idea to set new color for cloned construction

  # edit floor construction
  air_gap_material_exists = false
  plenum_floor_layers = plenum_def_int_surf_floor.layers
  plenum_floor_layers_counter = plenum_floor_layers.size
  plenum_floor_layers.reverse_each do |plenum_floor_layer|
    plenum_floor_layers_counter -= 1
    is_air_gap = plenum_floor_layer.to_AirGap
    if is_air_gap.empty?
      plenum_def_int_surf_floor.eraseLayer(plenum_floor_layers_counter)
    else
      plenum_def_int_surf_floor.eraseLayer(plenum_floor_layers_counter)
      air_gap_material_exists = true
      break
    end
  end
  if air_gap_material_exists == false
    puts '>** Warning, the plenum interior floor construction had no air gap material and will be empty.'
  end

  # clone roofCeiling construction and setup in construction set
  model_def_int_surf = model_constSet.defaultInteriorSurfaceConstructions.get
  model_def_int_surf_roof = model_def_int_surf.roofCeilingConstruction.get
  plenum_def_int_surf_roof = model_def_int_surf_roof.clone(model).to_Construction.get
  plenum_int_constSet.setRoofCeilingConstruction(plenum_def_int_surf_roof)
  plenum_def_int_surf_roof.setName('Plenum Interior Surface RoofCeiling')
  # good idea to set new color for cloned construction

  # edit roofCeiling construction
  air_gap_material_exists = false
  plenum_roof_layers = plenum_def_int_surf_roof.layers
  plenum_roof_layers_counter = plenum_roof_layers.size
  plenum_roof_layers.reverse_each do |plenum_roof_layer|
    plenum_roof_layers_counter -= 1
    is_air_gap = plenum_roof_layer.to_AirGap
    if is_air_gap.empty?
      plenum_def_int_surf_roof.eraseLayer(plenum_roof_layers_counter)
    else
      plenum_def_int_surf_roof.eraseLayer(plenum_roof_layers_counter)
      air_gap_material_exists = true
      break
    end
  end
  if air_gap_material_exists == false
    puts '> ** Warning, the plenum interior ceiling construction had no air gap material and will be empty.'
  end

end

if attic_flag == true
  puts 'Creating and assigning ConstructionSet for Attic'
  # this will create a mis match, but tie breaker at run time should fix and make mirrored construction if necssary
  attic_constSet = OpenStudio::Model::DefaultConstructionSet.new(model)
  attic_constSet.setName('Attic Construction Set')
  attic_int_constSet = OpenStudio::Model::DefaultSurfaceConstructions.new(model)
  attic_int_constSet.setName('Attic Interior Surface Constructions')
  attic_constSet.setDefaultInteriorSurfaceConstructions(attic_int_constSet)
  attic_ext_constSet = OpenStudio::Model::DefaultSurfaceConstructions.new(model)
  attic_ext_constSet.setName('Attic Exterior Surface Constructions')
  attic_constSet.setDefaultExteriorSurfaceConstructions(attic_ext_constSet)
  # this should exist unless something failed earlier. Maybe put in check for it?
  attic_spaceType.setDefaultConstructionSet(attic_constSet)

  # import attic constructions to add to construction set
  found_floor_flag = false
  found_roof_flag = false
  attic_floor_const = ''
  attic_roof_const = ''
  template_constructions = model_template.getConstructions
  template_constructions.each do |template_construction|
    if template_construction.name.to_s == templateFile_attic_floor_construction.to_s
      attic_floor_const = template_construction.clone(model).to_Construction.get
      found_floor_flag = true
    end
    if template_construction.name.to_s == '000_AtticRoof_ClimateZone 1-8'
      attic_roof_const = template_construction.clone(model).to_Construction.get
      found_roof_flag = true
    end
    if (found_roof_flag == true) && (found_roof_flag == true)
      break
    end
  end
  # add int floor and ext roof constructions to newly made sets
  attic_int_constSet.setFloorConstruction(attic_floor_const)
  attic_ext_constSet.setRoofCeilingConstruction(attic_roof_const)

end

# set custom construction sets as needed (hotels use multiple const sets, and anything with attic will require special work as well)

# replace thermostats with the ones from template
thermostats = model_template.getThermostatSetpointDualSetpoints
cloned_thermostat = []
thermostats.each do |thermostat|
  if thermostat.name.to_s == templateFile_default_thermostat
    cloned_thermostat = thermostat.clone(model).to_ThermostatSetpointDualSetpoint.get
  end
end

# zones = model.getThermalZones
zones.each do |zone|
  zone.setThermostatSetpointDualSetpoint(cloned_thermostat)
end

# purge unused objects after removing loads,constructions, thermostats, and schedules
puts 'Purging Unsed Object'
model.purgeUnusedResourceObjects

# save the model with updated loads constructions and thermostats
# this should test the local templates. Should also make something to test BCL, or maybe change this to use BCL for space types
puts 'Saving Model b'
model.save(OpenStudio::Path.new("#{saveDir}/#{saveName}_b.osm"), true)

# next create measure that that strips out zones, and merges common spaces into a zone. This will test our space merging
# to do this where multipliers were used I may have to find a way to re-create new ones by cloning and moving spaces

# maybe test blended space type vs. descrete space type

# then could make best rectagnular equivilant to see the difference.

puts 'Finished creating Reference Building OSM'
