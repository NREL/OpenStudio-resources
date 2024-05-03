import openstudio

from lib.baseline_model import BaselineModel

model = BaselineModel()

# make a 2 story, 100m X 50m, 10 zone core/perimeter building
model.add_geometry(length=100, width=50, num_floors=2, floor_to_floor_height=4, plenum_height=1, perimeter_zone_depth=3)

# add windows at a 40% window-to-wall ratio
model.add_windows(wwr=0.4, offset=1, application_type="Above Floor")

# add ASHRAE System type 01, PTAC, Residential
model.add_hvac(ashrae_sys_num="01")

# add thermostats
model.add_thermostats(heating_setpoint=24, cooling_setpoint=28)

# assign constructions from a local library to the walls/windows/etc. in the model
model.set_constructions()

# set whole building space type; simplified 90.1-2004 Large Office Whole Building
model.set_space_type()

# add design days to the model (Chicago)
model.add_design_days()

# make the run period
rp = model.getRunPeriod()

# set the calendar year
yd = model.getYearDescription()
yd.setCalendarYear(1999)

# add utility bills
average_electric = 760808.333 / 12.0
electric_bill = openstudio.model.UtilityBill("Electricity".to_FuelType(), model)
electric_bill.setConsumptionUnit("kWh")
billing_period = electric_bill.addBillingPeriod()
billing_period.setConsumption(average_electric)
billing_period = electric_bill.addBillingPeriod()
billing_period.setConsumption(average_electric)
billing_period = electric_bill.addBillingPeriod()
billing_period.setConsumption(average_electric)
billing_period = electric_bill.addBillingPeriod()
billing_period.setConsumption(average_electric)
billing_period = electric_bill.addBillingPeriod()
billing_period.setConsumption(average_electric)
billing_period = electric_bill.addBillingPeriod()
billing_period.setConsumption(average_electric)

average_gas = 3079002.87 / 12.0
gas_bill = openstudio.model.UtilityBill("Gas".to_FuelType(), model)
gas_bill.setConsumptionUnit("kBtu")
billing_period = gas_bill.addBillingPeriod()
billing_period.setConsumption(average_gas)
billing_period = gas_bill.addBillingPeriod()
billing_period.setConsumption(average_gas)
billing_period = gas_bill.addBillingPeriod()
billing_period.setConsumption(average_gas)
billing_period = gas_bill.addBillingPeriod()
billing_period.setConsumption(average_gas)
billing_period = gas_bill.addBillingPeriod()
billing_period.setConsumption(average_gas)
billing_period = gas_bill.addBillingPeriod()
billing_period.setConsumption(average_gas)

# save the OpenStudio model (.osm)
model.save_openstudio_osm(osm_save_directory=None, osm_name="in.osm")
