# frozen_string_literal: true

# This tests the classes that derive from ExteriorLoadDefinition and ExteriorLoadInstance

require 'openstudio'
require_relative 'lib/baseline_model'

model = BaselineModel.new

# make a 2 story, 100m X 50m, 10 zone core/perimeter building
model.add_geometry({ 'length' => 100,
                     'width' => 50,
                     'num_floors' => 2,
                     'floor_to_floor_height' => 4,
                     'plenum_height' => 1,
                     'perimeter_zone_depth' => 3 })

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
# we sort the zones by names
zones = model.getThermalZones.sort_by { |z| z.name.to_s }

# Get spaces, ordered by name to ensure consistency
spaces = model.getSpaces.sort_by { |s| s.name.to_s }

# Use Ideal Air Loads
zones.each { |z| z.setUseIdealAirLoads(true) }

spaces.each_with_index do |space, i|
  case i
  when 0
    steam_def = OpenStudio::Model::SteamEquipmentDefinition.new(model)
    steam_def.setDesignLevel(1000)
    steam_def.setName('Steam Equipment Def 1kW')
    steam_def.setFractionLatent(0.5)
    steam_def.setFractionRadiant(0.3)
    steam_def.setFractionLost(0.0)

    steam_eq = OpenStudio::Model::SteamEquipment.new(steam_def)
    steam_eq.setSchedule(model.alwaysOnDiscreteSchedule)
    steam_eq.setMultiplier(1.0)
    steam_eq.setEndUseSubcategory('Laundry')
    steam_eq.setSpace(space)
    steam_eq.setName("#{space.name} Steam Equipment")

  when 1
    gas_def = OpenStudio::Model::GasEquipmentDefinition.new(model)
    gas_def.setWattsperSpaceFloorArea(10)
    gas_def.setName('Gas Equipment Def 10W/m2')
    gas_def.setFractionLatent(0.0)
    gas_def.setFractionRadiant(0.3)
    gas_def.setFractionLost(0.0)
    gas_def.setCarbonDioxideGenerationRate(0)

    gas_eq = OpenStudio::Model::GasEquipment.new(gas_def)
    gas_eq.setSchedule(model.alwaysOnDiscreteSchedule)
    gas_eq.setMultiplier(1.0)
    gas_eq.setEndUseSubcategory('Cooking')
    gas_eq.setSpace(space)
    gas_eq.setName("#{space.name} Gas Equipment")

  when 2
    hw_def = OpenStudio::Model::HotWaterEquipmentDefinition.new(model)
    # (Unusual to set dishwashing as per person, but I want to showcase the
    # ability to do so...)
    hw_def.setWattsperPerson(10)
    hw_def.setName('HotWater Equipment Def 10W/p')
    hw_def.setFractionLatent(0.2)
    hw_def.setFractionRadiant(0.1)
    hw_def.setFractionLost(0.5)

    hw_eq = OpenStudio::Model::HotWaterEquipment.new(hw_def)
    hw_eq.setSchedule(model.alwaysOnDiscreteSchedule)
    hw_eq.setMultiplier(1.0)
    hw_eq.setEndUseSubcategory('Dishwashing')

    hw_eq.setSpace(space)
    hw_eq.setName("#{space.name} HotWater Equipment")

  when 3
    other_def = OpenStudio::Model::OtherEquipmentDefinition.new(model)
    other_def.setDesignLevel(6766)
    other_def.setName('Other Equipment Def')
    other_def.setFractionLatent(0)
    other_def.setFractionRadiant(0.3)
    other_def.setFractionLost(0.0)
    # TODO: this isn't implemented in OpenStudio...
    # other_def.setCarbonDioxideGenerationRate(1.2E-7)

    other_eq = OpenStudio::Model::OtherEquipment.new(other_def)
    other_eq.setSchedule(model.alwaysOnDiscreteSchedule)
    other_eq.setMultiplier(1.0)
    other_eq.setEndUseSubcategory('Propane stuff')
    if Gem::Version.new(OpenStudio.openStudioVersion) < Gem::Version.new('3.0.0')
      other_eq.setFuelType('PropaneGas')
    else
      other_eq.setFuelType('Propane')
    end

    other_eq.setSpace(space)
    other_eq.setName("#{space.name} Other Equipment")

  when 4
    luminaire_def = OpenStudio::Model::LuminaireDefinition.new(model)
    luminaire_def.setLightingPower(40)
    luminaire_def.setName('A Luminaire')
    luminaire_def.setFractionRadiant(0.3)
    luminaire_def.setFractionVisible(0.7)
    luminaire_def.setReturnAirFractionFunctionofPlenumTemperatureCoefficient1(0.0)
    luminaire_def.setReturnAirFractionFunctionofPlenumTemperatureCoefficient2(0.0)

    luminaire_eq = OpenStudio::Model::Luminaire.new(luminaire_def)
    luminaire_eq.setSchedule(model.alwaysOnDiscreteSchedule)
    luminaire_eq.setMultiplier(1.0)
    luminaire_eq.setEndUseSubcategory('Luminaires')

    luminaire_eq.setSpace(space)
    luminaire_eq.setName("#{space.name} Luminaire")

  end
end

# save the OpenStudio model (.osm)
model.save_openstudio_osm({ 'osm_save_directory' => Dir.pwd,
                            'osm_name' => 'in.osm' })
