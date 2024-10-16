import openstudio

from lib.baseline_model import BaselineModel

model = BaselineModel()

# make a 2 story, 100m X 50m, 10 zone core/perimeter building
model.add_geometry(length=100, width=50, num_floors=1, floor_to_floor_height=4, plenum_height=1, perimeter_zone_depth=3)

# add windows at a 40% window-to-wall ratio
model.add_windows(wwr=0.4, offset=1, application_type="Above Floor")

# add thermostats
model.add_thermostats(heating_setpoint=24, cooling_setpoint=28)

# assign constructions from a local library to the walls/windows/etc. in the model
model.set_constructions()

# set whole building space type; simplified 90.1-2004 Large Office Whole Building
model.set_space_type()

# add design days to the model (Chicago)
model.add_design_days()

# add ASHRAE System type 03, PSZ-AC
model.add_hvac(ashrae_sys_num="03")

air_systems = model.getAirLoopHVACs()

for s in air_systems:
    oa_node = s.airLoopHVACOutdoorAirSystem().get().outboardOANode().get()

    hx = openstudio.model.HeatExchangerAirToAirSensibleAndLatent(model)
    if openstudio.VersionString(openstudio.openStudioVersion()) >= openstudio.VersionString("3.8.0"):
        hx.assignHistoricalEffectivenessCurves()

    hx.addToNode(oa_node)

    spm = openstudio.model.SetpointManagerMixedAir(model)

    outlet_node = hx.primaryAirOutletModelObject().get().to_Node().get()

    spm.addToNode(outlet_node)


# save the OpenStudio model (.osm)
model.save_openstudio_osm(osm_save_directory=None, osm_name="in.osm")
