# frozen_string_literal: true

require 'openstudio'
require 'lib/baseline_model'

model = BaselineModel.new


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

#add thermostats
model.add_thermostats({"heating_setpoint" => 19,
                       "cooling_setpoint" => 26})

#assign constructions from a local library to the walls/windows/etc. in the model
model.set_constructions()

#set whole building space type; simplified 90.1-2004 Large Office Whole Building
model.set_space_type()

#add design days to the model (Chicago)
model.add_design_days()

# In order to produce more consistent results between different runs,
# we sort the zones by names
# (There's only one here, but just in case this would be copy pasted somewhere
# else...)
zones = model.getThermalZones.sort_by{|z| z.name.to_s}
z = zones[0]
z.setUseIdealAirLoads(true)

# make a shading surface
vertices = OpenStudio::Point3dVector.new
vertices << OpenStudio::Point3d.new(0,0,0)
vertices << OpenStudio::Point3d.new(10,0,0)
vertices << OpenStudio::Point3d.new(10,4,0)
vertices << OpenStudio::Point3d.new(0,4,0)
rotation = OpenStudio::createRotation(OpenStudio::Vector3d.new(1,0,0), OpenStudio::degToRad(30))
vertices = rotation*vertices

group = OpenStudio::Model::ShadingSurfaceGroup.new(model)
group.setXOrigin(20)
group.setYOrigin(10)
group.setZOrigin(8)

shade = OpenStudio::Model::ShadingSurface.new(vertices, model)
shade.setShadingSurfaceGroup(group)

# create the panel
# This creates a panel with the Sandia parameters for one random (static) entry
# in the embedded sandia Database
# panel = OpenStudio::Model::GeneratorPhotovoltaic::sandia(model)

#/// Factory method to creates a GeneratorPhotovoltaic object with PhotovoltaicPerformanceSandia by looking up characteristics in the embedded
#// Sandia database by its name. Please use the PhotovoltaicPerformanceSandia::sandiaModulePerformanceNames() static method
# / to look up the valid names as it will throw if it cannot find it
sandiaModulePerformanceName = OpenStudio::Model::PhotovoltaicPerformanceSandia::sandiaModulePerformanceNames.sort.reverse[0]
panel = OpenStudio::Model::GeneratorPhotovoltaic::fromSandiaDatabase(model, sandiaModulePerformanceName);

panel.setSurface(shade)

# create the inverter
inverter = OpenStudio::Model::ElectricLoadCenterInverterSimple.new(model)
inverter.setAvailabilitySchedule(model.alwaysOnDiscreteSchedule)
inverter.setRadiativeFraction(0.0)
inverter.setInverterEfficiency(1.0)

# create the distribution system
elcd = OpenStudio::Model::ElectricLoadCenterDistribution.new(model)
elcd.setName("PV ELCD")
elcd.addGenerator(panel)
elcd.setElectricalBussType("DirectCurrentWithInverter")
elcd.setInverter(inverter)

#save the OpenStudio model (.osm)
model.save_openstudio_osm({"osm_save_directory" => Dir.pwd,
                           "osm_name" => "out.osm"})
