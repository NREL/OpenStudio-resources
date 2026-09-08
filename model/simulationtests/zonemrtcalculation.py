import openstudio
from lib.baseline_model import BaselineModel

model = BaselineModel()

# make a 1 story, 100m X 50m, 5 zone core/perimeter building
model.add_geometry(length=100, width=50, num_floors=1, floor_to_floor_height=4, plenum_height=1, perimeter_zone_depth=3)

# add windows at a 40% window-to-wall ratio
model.add_windows(wwr=0.4, offset=1, application_type="Above Floor")

# add thermostats
model.add_thermostats(heating_setpoint=19, cooling_setpoint=26)

# assign constructions from a local library to the walls/windows/etc. in the model
model.set_constructions()

# set whole building space type; simplified 90.1-2004 Large Office Whole Building
model.set_space_type()

# add design days to the model (Chicago)
model.add_design_days()


# In order to produce more consistent results between different runs,
# we sort the spaces by names
spaces = sorted(model.getSpaces(), key=lambda s: s.nameString())

# Collapse all spaces into one thermal zone
thermal_zone = spaces[0].thermalZone().get()
for space in spaces:
    z = space.thermalZone().get()
    space.setThermalZone(thermal_zone)
    if z != thermal_zone:
        z.remove()
thermal_zone.setName("5 spaces zone")
if len(model.getThermalZones()) != 1:
    raise ValueError("Expected a single Thermal Zone")
if len(thermal_zone.spaces()) != len(spaces):
    raise ValueError("Expected the Thermal Zone to have all spaces")

# add windows at a 40% window-to-wall ratio
model.add_windows(wwr=0.4, offset=1, application_type="Above Floor")

# create the zone property user view factors by surface name object
# There are a number of preconditions you must meet:
# * All People objects should be assigned directly to a space,
# * All spaces should be assigned to the same Thermal Zone.
# The Sum of the MRT Weighting Factors for all People objects in the same Thermal Zone must be < 1.0
zonemrtcalc = thermal_zone.getZoneMRTCalculation()

# create thermal comfort schedules
workeffsch = openstudio.model.ScheduleConstant(model)
workeffsch.setValue(0.5)
cloinssch = openstudio.model.ScheduleConstant(model)
cloinssch.setValue(0.5)
airvelsch = openstudio.model.ScheduleConstant(model)
airvelsch.setValue(0.5)

# get all people in the zone
peoples = []
for space in spaces:
    definition1 = openstudio.model.PeopleDefinition(model)
    definition1.setNumberofPeople(1.0)
    definition1.setMeanRadiantTemperatureCalculationType("EnclosureAveraged")
    definition1.setThermalComfortModelType(0, "Fanger")

    people1 = openstudio.model.People(definition1)
    people1.setWorkEfficiencySchedule(workeffsch)
    people1.setClothingInsulationSchedule(cloinssch)
    people1.setAirVelocitySchedule(airvelsch)
    people1.setSpace(space)
    peoples.append(people1)

    definition2 = openstudio.model.PeopleDefinition(model)
    definition2.setNumberofPeople(1.0)
    definition2.setMeanRadiantTemperatureCalculationType("EnclosureAveraged")  # SurfaceWeighted, AngleFactor not supported?
    definition2.setThermalComfortModelType(0, "Pierce")

    people2 = openstudio.model.People(definition2)
    people2.setWorkEfficiencySchedule(workeffsch)
    people2.setClothingInsulationSchedule(cloinssch)
    people2.setAirVelocitySchedule(airvelsch)
    people2.setSpace(space)
    peoples.append(people2)

# Extensible: MRT Weighting Factors for people

people_one_mrt_weighting_factor = 0.37
people_other_mrt_weighting_factor = (1 - people_one_mrt_weighting_factor) / (len(peoples) - 1)
# people, mrt_weighting_factor
mrt_weighting_factor_infos = []
mrt_weighting_factor_infos.append([peoples[0], people_one_mrt_weighting_factor])
for people in peoples[1:]:
    mrt_weighting_factor_infos.append([people, people_other_mrt_weighting_factor])
# # To add a group, you can use the convenience method
# bool addMRTWeightingFactor(const People&, double mRTWeightingFactor)
zonemrtcalc.addMRTWeightingFactor(mrt_weighting_factor_infos[0][0], mrt_weighting_factor_infos[0][1])

# This will in turn actually use the helper class MRTWeightingFactor
zonemrtcalc.addMRTWeightingFactor(
    openstudio.model.MRTWeightingFactor(mrt_weighting_factor_infos[1][0], mrt_weighting_factor_infos[1][1])
)

# NOTE: if you call addMRTWeightingFactor with a People object that is already in the list, it will update the
# MRTWeightingFactor value for that People object.

if zonemrtcalc.numberofMRTWeightingFactors() != 2:
    raise ValueError("Expected 2 MRT Weighting Factors")
# This is a vector of MRTWeightingFactor
if len(zonemrtcalc.mRTWeightingFactors()) != 2:
    raise ValueError("Expected 2 MRT Weighting Factors")

if zonemrtcalc.mRTWeightingFactorIndex(peoples[0]).get() != 0:
    raise ValueError("Expected index 0 for peoples[0]")
if zonemrtcalc.mRTWeightingFactorIndex(peoples[1]).get() != 1:
    raise ValueError("Expected index 1 for peoples[1]")

first_mrt_group = zonemrtcalc.mRTWeightingFactors()[0]
# This returns an OptionalMRTWeightingFactor
first_mrt_group_ = zonemrtcalc.getMRTWeightingFactor(0)
if not first_mrt_group_.is_initialized():
    raise ValueError("Expected the MRTWeightingFactor at index 0 to be initialized")
if first_mrt_group.people() != first_mrt_group_.get().people():
    raise ValueError("Expected the same People object")

zonemrtcalc.removeMRTWeightingFactor(0)
if zonemrtcalc.numberofMRTWeightingFactors() != 1:
    raise ValueError("Expected 1 MRT Weighting Factor")
if zonemrtcalc.numExtensibleGroups() != 1:
    raise ValueError("Expected 1 extensible group")
if zonemrtcalc.mRTWeightingFactorIndex(peoples[1]).get() != 0:
    raise ValueError("Expected index 0 for peoples[1]")

zonemrtcalc.removeAllMRTWeightingFactors()
if zonemrtcalc.numberofMRTWeightingFactors() != 0:
    raise ValueError("Expected 0 MRT Weighting Factors")
if zonemrtcalc.numExtensibleGroups() != 0:
    raise ValueError("Expected 0 extensible groups")

# There is also a batch add
mrt_groups = [openstudio.model.MRTWeightingFactor(g[0], g[1]) for g in mrt_weighting_factor_infos]
zonemrtcalc.addMRTWeightingFactors(mrt_groups)
if zonemrtcalc.numberofMRTWeightingFactors() != len(peoples):
    raise ValueError("Expected as many MRT Weighting Factors as peoples")

# save the OpenStudio model (.osm)
model.save_openstudio_osm(osm_save_directory=None, osm_name="in.osm")
