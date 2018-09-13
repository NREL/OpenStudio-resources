class OpenStudio::Model::Model
  # Adds the HVAC system as derived from the combinations of
  # CBECS 2012 MAINHT and MAINCL fields.
  # Mapping between combinations and HVAC systems per
  # http://www.nrel.gov/docs/fy08osti/41956.pdf
  # Table C-31
  def add_cbecs_hvac_system(standard, system_type, zones)
    case system_type
    when 'PTAC with hot water heat'
      standard.model_add_hvac_system(self, 'PTAC', ht = 'NaturalGas', znht = nil, cl = 'Electricity', zones)

    when 'PTAC with gas coil heat'
      standard.model_add_hvac_system(self, 'PTAC', ht = nil, znht = 'NaturalGas', cl = 'Electricity', zones)

    when 'PTAC with electric baseboard heat'
      standard.model_add_hvac_system(self, 'PTAC', ht = nil, znht = nil, cl = 'Electricity', zones)
      standard.model_add_hvac_system(self, 'Baseboards', ht = 'Electricity', znht = nil, cl = nil, zones)

    when 'PTAC with no heat'
      standard.model_add_hvac_system(self, 'PTAC', ht = nil, znht = nil, cl = 'Electricity', zones)

    when 'PTAC with district hot water heat'
      standard.model_add_hvac_system(self, 'PTAC', ht = 'DistrictHeating', znht = nil, cl = 'Electricity', zones)

    when 'PTHP'
      standard.model_add_hvac_system(self, 'PTHP', ht = 'Electricity', znht = nil, cl = 'Electricity', zones)

    when 'PSZ-AC with gas coil heat'
      standard.model_add_hvac_system(self, 'PSZ-AC', ht = 'NaturalGas', znht = nil, cl = 'Electricity', zones)

    when 'PSZ-AC with electric baseboard heat'
      standard.model_add_hvac_system(self, 'PSZ-AC', ht = nil, znht = nil, cl = 'Electricity', zones)
      standard.model_add_hvac_system(self, 'Baseboards', ht = 'Electricity', znht = nil, cl = nil, zones)

    when 'PSZ-AC with no heat'
      standard.model_add_hvac_system(self, 'PSZ-AC', ht = nil, znht = nil, cl = 'Electricity', zones)

    when 'PSZ-AC with district hot water heat'
      standard.model_add_hvac_system(self, 'PSZ-AC', ht = 'DistrictHeating', znht = nil, cl = 'Electricity', zones)

    when 'PSZ-HP'
      standard.model_add_hvac_system(self, 'PSZ-HP', ht = 'Electricity', znht = nil, cl = 'Electricity', zones)

    when 'Fan coil district chilled water with no heat'
      standard.model_add_hvac_system(self, 'Fan Coil', ht = nil, znht = nil, cl = 'DistrictCooling', zones)

    when 'Fan coil district chilled water and boiler'
      standard.model_add_hvac_system(self, 'Fan Coil', ht = 'NaturalGas', znht = nil, cl = 'DistrictCooling', zones)

    when 'Fan coil district chilled water unit heaters'
      standard.model_add_hvac_system(self, 'Fan Coil', ht = nil, znht = nil, cl = 'DistrictCooling', zones)
      standard.model_add_hvac_system(self, 'Unit Heaters', ht = 'NaturalGas', znht = nil, cl = nil, zones)

    when 'Fan coil district chilled water electric baseboard heat'
      standard.model_add_hvac_system(self, 'Fan Coil', ht = nil, znht = nil, cl = 'DistrictCooling', zones)
      standard.model_add_hvac_system(self, 'Baseboards', ht = 'Electricity', znht = nil, cl = nil, zones)

    when 'Fan coil district hot and chilled water'
      standard.model_add_hvac_system(self, 'Fan Coil', ht = 'DistrictHeating', znht = nil, cl = 'DistrictCooling', zones)

    when 'Fan coil district hot water and chiller'
      standard.model_add_hvac_system(self, 'Fan Coil', ht = 'DistrictHeating', znht = nil, cl = 'Electricity', zones)

    when 'Fan coil chiller with no heat'
      standard.model_add_hvac_system(self, 'Fan Coil', ht = nil, znht = nil, cl = 'Electricity', zones)

    when 'Baseboard district hot water heat'
      standard.model_add_hvac_system(self, 'Baseboards', ht = 'DistrictHeating', znht = nil, cl = nil, zones)

    when 'Baseboard district hot water heat with direct evap coolers'
      standard.model_add_hvac_system(self, 'Baseboards', ht = 'DistrictHeating', znht = nil, cl = nil, zones)
      standard.model_add_hvac_system(self, 'Evaporative Cooler', ht = nil, znht = nil, cl = 'Electricity', zones)

    when 'Baseboard electric heat'
      standard.model_add_hvac_system(self, 'Baseboards', ht = 'Electricity', znht = nil, cl = nil, zones)

    when 'Baseboard electric heat with direct evap coolers'
      standard.model_add_hvac_system(self, 'Baseboards', ht = 'Electricity', znht = nil, cl = nil, zones)
      standard.model_add_hvac_system(self, 'Evaporative Cooler', ht = nil, znht = nil, cl = 'Electricity', zones)

    when 'Baseboard hot water heat'
      standard.model_add_hvac_system(self, 'Baseboards', ht = 'NaturalGas', znht = nil, cl = nil, zones)

    when 'Baseboard hot water heat with direct evap coolers'
      standard.model_add_hvac_system(self, 'Baseboards', ht = 'NaturalGas', znht = nil, cl = nil, zones)
      standard.model_add_hvac_system(self, 'Evaporative Cooler', ht = nil, znht = nil, cl = 'Electricity', zones)

    when 'Window AC with no heat'
      standard.model_add_hvac_system(self, 'Window AC', ht = nil, znht = nil, cl = 'Electricity', zones)

    when 'Window AC with forced air furnace'
      standard.model_add_hvac_system(self, 'Window AC', ht = nil, znht = nil, cl = 'Electricity', zones)
      standard.model_add_hvac_system(self, 'Forced Air Furnace', ht = 'NaturalGas', znht = nil, cl = nil, zones)

    when 'Window AC with district hot water baseboard heat'
      standard.model_add_hvac_system(self, 'Window AC', ht = nil, znht = nil, cl = 'Electricity', zones)
      standard.model_add_hvac_system(self, 'Baseboards', ht = 'DistrictHeating', znht = nil, cl = nil, zones)

    when 'Window AC with hot water baseboard heat'
      standard.model_add_hvac_system(self, 'Window AC', ht = nil, znht = nil, cl = 'Electricity', zones)
      standard.model_add_hvac_system(self, 'Baseboards', ht = 'NaturalGas', znht = nil, cl = nil, zones)

    when 'Window AC with electric baseboard heat'
      standard.model_add_hvac_system(self, 'Window AC', ht = nil, znht = nil, cl = 'Electricity', zones)
      standard.model_add_hvac_system(self, 'Baseboards', ht = 'Electricity', znht = nil, cl = nil, zones)

    when 'Window AC with unit heaters'
      standard.model_add_hvac_system(self, 'Window AC', ht = nil, znht = nil, cl = 'Electricity', zones)
      standard.model_add_hvac_system(self, 'Unit Heaters', ht = 'NaturalGas', znht = nil, cl = nil, zones)

    when 'Direct evap coolers'
      standard.model_add_hvac_system(self, 'Evaporative Cooler', ht = nil, znht = nil, cl = 'Electricity', zones)

    when 'Direct evap coolers with unit heaters'
      standard.model_add_hvac_system(self, 'Evaporative Cooler', ht = nil, znht = nil, cl = 'Electricity', zones)
      standard.model_add_hvac_system(self, 'Unit Heaters', ht = 'NaturalGas', znht = nil, cl = nil, zones)

    when 'Unit heaters'
      standard.model_add_hvac_system(self, 'Unit Heaters', ht = 'NaturalGas', znht = nil, cl = nil, zones)

    when 'Heat pump heat with no cooling'
      standard.model_add_hvac_system(self, 'Residential Air Source Heat Pump', ht = nil, znht = nil, cl = 'Electricity', zones)

    when 'Heat pump heat with direct evap cooler'
      # standard.model_add_hvac_system(self, 'Residential Air Source Heat Pump', ht=nil, znht=nil, cl='Electricity', zones)
      # Using PTHP to represent zone heat pump for this configuration
      # because only one airloop may be connected to each thermal zone.
      standard.model_add_hvac_system(self, 'PTHP', ht = 'Electricity', znht = nil, cl = 'Electricity', zones)
      # disable the cooling coils in all the PTHPs
      getZoneHVACPackagedTerminalHeatPumps.each do |pthp|
        clg_coil = pthp.heatingCoil.to_CoilHeatingDXSingleSpeed.get
        clg_coil.setAvailabilitySchedule(alwaysOffDiscreteSchedule)
      end
      standard.model_add_hvac_system(self, 'Evaporative Cooler', ht = nil, znht = nil, cl = 'Electricity', zones)

    when 'VAV with reheat'
      standard.model_add_hvac_system(self, 'VAV Reheat', ht = 'NaturalGas', znht = 'NaturalGas', cl = 'Electricity', zones)

    when 'VAV with PFP boxes'
      standard.model_add_hvac_system(self, 'VAV PFP Boxes', ht = 'NaturalGas', znht = 'NaturalGas', cl = 'Electricity', zones)

    when 'VAV with gas reheat'
      standard.model_add_hvac_system(self, 'VAV Gas Reheat', ht = 'NaturalGas', ht = 'NaturalGas', cl = 'Electricity', zones)

    when 'VAV with zone unit heaters'
      standard.model_add_hvac_system(self, 'VAV No Reheat', ht = 'NaturalGas', znht = nil, cl = 'Electricity', zones)
      standard.model_add_hvac_system(self, 'Unit Heaters', ht = 'NaturalGas', znht = nil, cl = nil, zones)

    when 'VAV with electric baseboard heat'
      standard.model_add_hvac_system(self, 'VAV No Reheat', ht = 'NaturalGas', znht = nil, cl = 'Electricity', zones)
      standard.model_add_hvac_system(self, 'Baseboards', ht = 'Electricity', znht = nil, cl = nil, zones)

    when 'VAV cool with zone heat pump heat'
      standard.model_add_hvac_system(self, 'VAV No Reheat', ht = 'NaturalGas', znht = nil, cl = 'Electricity', zones)
      # standard.model_add_hvac_system(self, 'Residential Air Source Heat Pump', ht=nil, znht=nil, cl='Electricity', zones)
      # Using PTHP to represent zone heat pump for this configuration
      # because only one airloop may be connected to each thermal zone.
      standard.model_add_hvac_system(self, 'PTHP', ht = 'Electricity', znht = nil, cl = 'Electricity', zones)
      # disable the cooling coils in all the PTHPs
      getZoneHVACPackagedTerminalHeatPumps.each do |pthp|
        clg_coil = pthp.heatingCoil.to_CoilHeatingDXSingleSpeed.get
        clg_coil.setAvailabilitySchedule(alwaysOffDiscreteSchedule)
      end

    when 'PVAV with reheat', 'Packaged VAV Air Loop with Boiler' # second enumeration for backwards compatibility with Tenant Star project
      standard.model_add_hvac_system(self, 'PVAV Reheat', ht = 'NaturalGas', znht = 'NaturalGas', cl = 'Electricity', zones)

    when 'PVAV with PFP boxes'
      standard.model_add_hvac_system(self, 'PVAV PFP Boxes', ht = 'Electricity', znht = 'Electricity', cl = 'Electricity', zones)

    when 'Residential forced air'
      standard.model_add_hvac_system(self, 'Unit Heaters', ht = 'NaturalGas', znht = nil, cl = nil, zones)

    when 'Residential forced air cooling hot water baseboard heat'
      standard.model_add_hvac_system(self, 'Residential AC', ht = nil, znht = nil, cl = 'Electricity', zones)
      standard.model_add_hvac_system(self, 'Baseboards', ht = 'NaturalGas', znht = nil, cl = nil, zones)

    when 'Residential forced air with district hot water'
      standard.model_add_hvac_system(self, 'Residential AC', ht = nil, znht = nil, cl = 'Electricity', zones)

    when 'Residential heat pump'
      standard.model_add_hvac_system(self, 'Residential Air Source Heat Pump', ht = 'Electricity', znht = nil, cl = 'Electricity', zones)

    when 'Forced air furnace'
      standard.model_add_hvac_system(self, 'Forced Air Furnace', ht = 'NaturalGas', znht = nil, cl = nil, zones)

    when 'Forced air furnace district chilled water fan coil'
      standard.model_add_hvac_system(self, 'Forced Air Furnace', ht = 'NaturalGas', znht = nil, cl = nil, zones)
      standard.model_add_hvac_system(self, 'Fan Coil', ht = nil, znht = nil, cl = 'DistrictCooling', zones)

    when 'Forced air furnace direct evap cooler'
      # standard.model_add_hvac_system(self, 'Forced Air Furnace', ht='NaturalGas', znht=nil, cl=nil, zones)
      # Using unit heater to represent forced air furnace for this configuration
      # because only one airloop may be connected to each thermal zone.
      standard.model_add_hvac_system(self, 'Unit Heaters', ht = 'NaturalGas', znht = nil, cl = nil, zones)
      standard.model_add_hvac_system(self, 'Evaporative Cooler', ht = nil, znht = nil, cl = 'Electricity', zones)

    when 'Residential AC with no heat'
      standard.model_add_hvac_system(self, 'Residential AC', ht = nil, znht = nil, cl = 'Electricity', zones)

    when 'Residential AC with electric baseboard heat'
      standard.model_add_hvac_system(self, 'Residential AC', ht = nil, znht = nil, cl = 'Electricity', zones)
      standard.model_add_hvac_system(self, 'Baseboards', ht = 'Electricity', znht = nil, cl = nil, zones)

    else
      puts "HVAC system type '#{system_type}' not recognized"

    end
  end
end
