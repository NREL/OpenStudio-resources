# frozen_string_literal: true

require 'openstudio'
require 'lib/baseline_model'

model = BaselineModel.new

# make a 1 story, 100m X 50m, 5 zone core/perimeter building
model.add_geometry({ 'length' => 100,
                     'width' => 50,
                     'num_floors' => 1,
                     'floor_to_floor_height' => 4,
                     'plenum_height' => 1,
                     'perimeter_zone_depth' => 3 })

# add windows at a 40% window-to-wall ratio
model.add_windows({ 'wwr' => 0.4,
                    'offset' => 1,
                    'application_type' => 'Above Floor' })

# add ASHRAE System type 01, PTAC, Residential
model.add_hvac({ 'ashrae_sys_num' => '01' })

# add thermostats
model.add_thermostats({ 'heating_setpoint' => 24,
                        'cooling_setpoint' => 28 })

# assign constructions from a local library to the walls/windows/etc. in the model
model.set_constructions

# set whole building space type; simplified 90.1-2004 Large Office Whole Building
model.set_space_type

# add design days to the model (Chicago)
model.add_design_days

# add wind turbine generators
generator1 = OpenStudio::Model::GeneratorWindTurbine.new(model)

generator2 = OpenStudio::Model::GeneratorWindTurbine.new(model)
generator2.setRotorType('VerticalAxisWindTurbine')
generator2.setPowerControl('FixedSpeedFixedPitch')
generator2.setBladeChordArea(100.0)

generator3 = OpenStudio::Model::GeneratorWindTurbine.new(model)
generator3.setPowerControl('FixedSpeedVariablePitch')

generator4 = OpenStudio::Model::GeneratorWindTurbine.new(model)
generator4.setPowerControl('VariableSpeedFixedPitch')

# add generators to electric load center distribution
elcd = OpenStudio::Model::ElectricLoadCenterDistribution.new(model)
elcd.addGenerator(generator1)
elcd.addGenerator(generator2)
elcd.addGenerator(generator3)
elcd.addGenerator(generator4)
elcd.setElectricalBussType('AlternatingCurrent')

# save the OpenStudio model (.osm)
model.save_openstudio_osm({ 'osm_save_directory' => Dir.pwd, 'osm_name' => 'in.osm' })
