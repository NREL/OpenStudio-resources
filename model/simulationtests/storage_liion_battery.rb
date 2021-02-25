# frozen_string_literal: true

# This test aims to test the new 'Adiabatic Surface Construction Name' field
# added in the OS:DefaultConstructionSet

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
model.add_thermostats({ 'heating_setpoint' => 19,
                        'cooling_setpoint' => 26 })

# assign constructions from a local library to the walls/windows/etc. in the model
model.set_constructions

# set whole building space type; simplified 90.1-2004 Large Office Whole Building
model.set_space_type

# add design days to the model (Chicago)
model.add_design_days

# In order to produce more consistent results between different runs,
# we sort the zones by names
# (There's only one here, but just in case this would be copy pasted somewhere
# else...)
zones = model.getThermalZones.sort_by { |z| z.name.to_s }
z = zones[0]

# create the distribution system
elcd = OpenStudio::Model::ElectricLoadCenterDistribution.new(model)
elcd.setElectricalBussType('DirectCurrentWithInverterDCStorage')

# create a generator
generator = OpenStudio::Model::GeneratorPhotovoltaic.simple(model)

# create the inverter
inverter = OpenStudio::Model::ElectricLoadCenterInverterLookUpTable.new(model)

# create the storage
storage = OpenStudio::Model::ElectricLoadCenterStorageLiIonNMCBattery.new(model)
storage.setRadiativeFraction(0)
storage.setLifetimeModel("KandlerSmith")
storage.setNumberofCellsinSeries(139)
storage.setNumberofStringsinParallel(25)
storage.setInitialFractionalStateofCharge(0.7)
storage.setDCtoDCChargingEfficiency(0.95)
storage.setBatteryMass(342)
storage.setBatterySurfaceArea(4.26)
storage.setBatterySpecificHeatCapacity(1500)
storage.setHeatTransferCoefficientBetweenBatteryandAmbient(7.5)
storage.setFullyChargedCellVoltage(4.2)
storage.setCellVoltageatEndofExponentialZone(3.53)
storage.setCellVoltageatEndofNominalZone(3.342)
storage.setDefaultNominalCellVoltage(3.342)
storage.setFullyChargedCellCapacity(3.2)
storage.setFractionofCellCapacityRemovedattheEndofExponentialZone(0.8075)
storage.setFractionofCellCapacityRemovedattheEndofNominalZone(0.976875)
storage.setChargeRateatWhichVoltagevsCapacityCurveWasGenerated(1)
storage.setBatteryCellInternalElectricalResistance(0.09)

# Add them to the ELCD
elcd.addGenerator(generator)
elcd.setInverter(inverter)
elcd.setElectricalStorage(storage)

# save the OpenStudio model (.osm)
model.save_openstudio_osm({ 'osm_save_directory' => Dir.pwd,
                            'osm_name' => 'out.osm' })
