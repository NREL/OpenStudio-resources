# frozen_string_literal: true

require 'openstudio' unless defined?(OpenStudio)

# The config and helpers are inside this file
require_relative 'test_helpers'

# TODO: Include the other ones?
# require_relative 'highlevel_tests.rb'
# Ensure high level tests pass before continuing
# require 'minitest'
# success = Minitest.run(["-n", "/HighLevelTests/"])
# success = HighLevelTests::run Minitest::Reporters::DefaultReporter.new
# if not success
#  raise "High level tests failed"
# end

# the tests
class ModelTests < Minitest::Test
  parallelize_me!

  # simulation tests

  def test_absorption_chillers_rb
    result = sim_test('absorption_chillers.rb')
  end

  def test_absorption_chillers_osm
    result = sim_test('absorption_chillers.osm')
  end

  def test_adiabatic_construction_set_rb
    result = sim_test('adiabatic_construction_set.rb')
  end

  def test_adiabatic_construction_set_osm
    result = sim_test('adiabatic_construction_set.osm')
  end

  def test_airterminal_cooledbeam_osm
    result = sim_test('airterminal_cooledbeam.osm')
  end

  def test_airterminal_cooledbeam_rb
    result = sim_test('airterminal_cooledbeam.rb')
  end

  def test_airterminal_fourpipebeam_rb
    result = sim_test('airterminal_fourpipebeam.rb')
  end

  def test_airterminal_fourpipebeam_osm
    result = sim_test('airterminal_fourpipebeam.osm')
  end

  def test_airterminal_inletsidemixer_rb
    result = sim_test('airterminal_inletsidemixer.rb')
  end

  def test_airterminal_inletsidemixer_osm
    result = sim_test('airterminal_inletsidemixer.osm')
  end

  def test_air_chillers_osm
    result = sim_test('air_chillers.osm')
  end

  def test_air_chillers_rb
    result = sim_test('air_chillers.rb')
  end

  def test_air_terminals_osm
    result = sim_test('air_terminals.osm')
  end

  def test_air_terminals_rb
    result = sim_test('air_terminals.rb')
  end

  def test_airloop_and_zonehvac_rb
    result = sim_test('airloop_and_zonehvac.rb')
  end

  def test_airloop_and_zonehvac_osm
    result = sim_test('airloop_and_zonehvac.osm')
  end

  def test_ptac_othercoils_rb
    result = sim_test('ptac_othercoils.rb')
  end

  def test_ptac_othercoils_osm
    result = sim_test('ptac_othercoils.osm')
  end

  def test_pthp_othercoils_rb
    result = sim_test('pthp_othercoils.rb')
  end

  def test_pthp_othercoils_osm
    result = sim_test('pthp_othercoils.osm')
  end

  def test_airloop_avms_rb
    result = sim_test('airloop_avms.rb')
  end

  def test_airloop_avms_osm
    result = sim_test('airloop_avms.osm')
  end

  def test_asymmetric_interior_constructions_osm
    result = sim_test('asymmetric_interior_constructions.osm')
  end

  def test_availability_managers_rb
    result = sim_test('availability_managers.rb')
  end

  def test_availability_managers_osm
    result = sim_test('availability_managers.osm')
  end

  def test_baseline_sys01_osm
    result = sim_test('baseline_sys01.osm')
  end

  def test_baseline_sys01_rb
    result = sim_test('baseline_sys01.rb')
  end

  def test_baseline_sys02_osm
    result = sim_test('baseline_sys02.osm')
  end

  def test_baseline_sys02_rb
    result = sim_test('baseline_sys02.rb')
  end

  def test_baseline_sys03_osm
    result = sim_test('baseline_sys03.osm')
  end

  def test_baseline_sys03_rb
    result = sim_test('baseline_sys03.rb')
  end

  def test_baseline_sys04_osm
    result = sim_test('baseline_sys04.osm')
  end

  def test_baseline_sys04_rb
    result = sim_test('baseline_sys04.rb')
  end

  def test_baseline_sys05_osm
    result = sim_test('baseline_sys05.osm')
  end

  def test_baseline_sys05_rb
    result = sim_test('baseline_sys05.rb')
  end

  def test_baseline_sys06_osm
    result = sim_test('baseline_sys06.osm')
  end

  def test_baseline_sys06_rb
    result = sim_test('baseline_sys06.rb')
  end

  def test_baseline_sys07_osm
    result = sim_test('baseline_sys07.osm')
  end

  def test_baseline_sys07_rb
    result = sim_test('baseline_sys07.rb')
  end

  def test_baseline_sys08_osm
    result = sim_test('baseline_sys08.osm')
  end

  def test_baseline_sys08_rb
    result = sim_test('baseline_sys08.rb')
  end

  def test_baseline_sys09_osm
    result = sim_test('baseline_sys09.osm')
  end

  def test_baseline_sys09_rb
    result = sim_test('baseline_sys09.rb')
  end

  def test_baseline_sys10_osm
    result = sim_test('baseline_sys10.osm')
  end

  def test_baseline_sys10_rb
    result = sim_test('baseline_sys10.rb')
  end

  def test_coil_cooling_dx_rb
    result = sim_test('coil_cooling_dx.rb')
  end

  def test_coil_cooling_dx_osm
    result = sim_test('coil_cooling_dx.osm')
  end

  def test_centralheatpumpsystem_osm
    result = sim_test('centralheatpumpsystem.osm')
  end

  def test_centralheatpumpsystem_rb
    result = sim_test('centralheatpumpsystem.rb')
  end

  def test_chiller_reformulated_rb
    result = sim_test('chiller_reformulated.rb')
  end

  def test_chiller_reformulated_osm
    result = sim_test('chiller_reformulated.osm')
  end

  def test_chillers_tertiary_rb
    result = sim_test('chillers_tertiary.rb')
  end

  def test_chillers_tertiary_osm
    result = sim_test('chillers_tertiary.osm')
  end

  def test_coilsystem_waterhx_rb
    result = sim_test('coilsystem_waterhx.rb')
  end

  def test_coilsystem_waterhx_osm
    result = sim_test('coilsystem_waterhx.osm')
  end

  def test_coilsystem_dxhx_rb
    result = sim_test('coilsystem_dxhx.rb')
  end

  def test_coilsystem_dxhx_osm
    result = sim_test('coilsystem_dxhx.osm')
  end

  def test_coilsystem_dxhx_desiccant_balancedflow_rb
    result = sim_test('coilsystem_dxhx_desiccant_balancedflow.rb')
  end

  def test_coilsystem_dxhx_desiccant_balancedflow_osm
    result = sim_test('coilsystem_dxhx_desiccant_balancedflow.osm')
  end

  def test_coilsystem_integrated_heatpump_rb
    result = sim_test('coilsystem_integrated_heatpump.rb')
  end

  def test_coilsystem_integrated_heatpump_osm
    result = sim_test('coilsystem_integrated_heatpump.osm')
  end

  def test_coolingtowers_osm
    result = sim_test('coolingtowers.osm')
  end

  def test_coolingtowers_rb
    result = sim_test('coolingtowers.rb')
  end

  def test_cooling_coils_rb
    result = sim_test('cooling_coils.rb')
  end

  def test_cooling_coils_osm
    result = sim_test('cooling_coils.osm')
  end

  def test_daylighting_devices_rb
    result = sim_test('daylighting_devices.rb')
  end

  def test_daylighting_devices_osm
    result = sim_test('daylighting_devices.osm')
  end

  def test_daylighting_no_shades_rb
    result = sim_test('daylighting_no_shades.rb')
  end

  def test_daylighting_no_shades_osm
    result = sim_test('daylighting_no_shades.osm')
  end

  def test_daylighting_shades_rb
    result = sim_test('daylighting_shades.rb')
  end

  def test_daylighting_shades_osm
    result = sim_test('daylighting_shades.osm')
  end

  def test_dist_ht_cl_osm
    result = sim_test('dist_ht_cl.osm')
  end

  def test_dist_ht_cl_rb
    result = sim_test('dist_ht_cl.rb')
  end

  def test_doas_osm
    result = sim_test('doas.osm')
  end

  def test_doas_rb
    result = sim_test('doas.rb')
  end

  def test_doas_coil_cooling_dx_two_speed_osm
    result = sim_test('doas_coil_cooling_dx_two_speed.osm')
  end

  def test_doas_coil_cooling_dx_two_speed_rb
    result = sim_test('doas_coil_cooling_dx_two_speed.rb')
  end

  def test_doas_heatexchanger_airtoair_sensibleandlatent_osm
    result = sim_test('doas_heatexchanger_airtoair_sensibleandlatent.osm')
  end

  def test_doas_heatexchanger_airtoair_sensibleandlatent_rb
    result = sim_test('doas_heatexchanger_airtoair_sensibleandlatent.rb')
  end

  def test_dsn_oa_w_ideal_loads_osm
    result = sim_test('dsn_oa_w_ideal_loads.osm')
  end

  def test_dsn_oa_w_ideal_loads_rb
    result = sim_test('dsn_oa_w_ideal_loads.rb')
  end

  def test_ideal_loads_w_plenums_rb
    result = sim_test('ideal_loads_w_plenums.rb')
  end

  def test_ideal_loads_w_plenums_osm
    result = sim_test('ideal_loads_w_plenums.osm')
  end

  def test_dual_duct_rb
    result = sim_test('dual_duct.rb')
  end

  def test_dual_duct_osm
    result = sim_test('dual_duct.osm')
  end

  def test_ducts_and_pipes_rb
    result = sim_test('ducts_and_pipes.rb')
  end

  def test_ducts_and_pipes_osm
    result = sim_test('ducts_and_pipes.osm')
  end

  def test_elcd_no_generators_rb
    result = sim_test('elcd_no_generators.rb')
  end

  def test_elcd_no_generators_osm
    result = sim_test('elcd_no_generators.osm')
  end

  def test_electric_equipment_ITE_rb
    result = sim_test('electric_equipment_ITE.rb')
  end

  def test_electric_equipment_ITE_osm
    result = sim_test('electric_equipment_ITE.osm')
  end

  def test_ems_osm
    result = sim_test('ems.osm')
  end

  def test_ems_scott_osm
    result = sim_test('ems_scott.osm')
  end

  def test_ems_1floor_SpaceType_1space_osm
    result = sim_test('ems_1floor_SpaceType_1space.osm')
  end

  def test_ems_rb
    result = sim_test('ems.rb')
  end

  def test_environmental_factors_rb
    result = sim_test('environmental_factors.rb')
  end

  def test_environmental_factors_osm
    result = sim_test('environmental_factors.osm')
  end

  def test_evaporative_cooling_osm
    result = sim_test('evaporative_cooling.osm')
  end

  def test_evaporative_cooling_rb
    result = sim_test('evaporative_cooling.rb')
  end

  def test_ExampleModel_rb
    result = sim_test('ExampleModel.rb')
  end

  def test_exterior_equipment_rb
    result = sim_test('exterior_equipment.rb')
  end

  def test_exterior_equipment_osm
    result = sim_test('exterior_equipment.osm')
  end

  def test_fan_on_off_osm
    result = sim_test('fan_on_off.osm')
  end

  def test_fan_on_off_rb
    result = sim_test('fan_on_off.rb')
  end

  def test_fan_systemmodel_osm
    result = sim_test('fan_systemmodel.osm')
  end

  def test_fan_systemmodel_rb
    result = sim_test('fan_systemmodel.rb')
  end

  def test_fan_componentmodel_osm
    result = sim_test('fan_componentmodel.osm')
  end

  def test_fan_componentmodel_rb
    result = sim_test('fan_componentmodel.rb')
  end

  def test_fluid_coolers_rb
    result = sim_test('fluid_coolers.rb')
  end

  def test_fluid_coolers_osm
    result = sim_test('fluid_coolers.osm')
  end

  def test_foundation_kiva_rb
    result = sim_test('foundation_kiva.rb')
  end

  def test_foundation_kiva_osm
    result = sim_test('foundation_kiva.osm')
  end

  def test_foundation_kiva_customblocks_rb
    result = sim_test('foundation_kiva_customblocks.rb')
  end

  def test_foundation_kiva_customblocks_osm
    result = sim_test('foundation_kiva_customblocks.osm')
  end

  def test_fuelcell_osm
    result = sim_test('fuelcell.osm')
  end

  def test_fuelcell_rb
    result = sim_test('fuelcell.rb')
  end

  def test_generator_microturbine_rb
    result = sim_test('generator_microturbine.rb')
  end

  def test_generator_microturbine_osm
    result = sim_test('generator_microturbine.osm')
  end

  def test_generator_windturbine_rb
    result = sim_test('generator_windturbine.rb')
  end

  def test_generator_windturbine_osm
    result = sim_test('generator_windturbine.osm')
  end

  def test_coil_waterheating_desuperheater_osm
    result = sim_test('coil_waterheating_desuperheater.osm')
  end

  def test_coil_waterheating_desuperheater_rb
    result = sim_test('coil_waterheating_desuperheater.rb')
  end

  def test_headered_pumps_osm
    result = sim_test('headered_pumps.osm')
  end

  def test_headered_pumps_rb
    result = sim_test('headered_pumps.rb')
  end

  def test_heatexchanger_airtoair_sensibleandlatent_osm
    result = sim_test('heatexchanger_airtoair_sensibleandlatent.osm')
  end

  def test_heatexchanger_airtoair_sensibleandlatent_rb
    result = sim_test('heatexchanger_airtoair_sensibleandlatent.rb')
  end

  def test_heatexchanger_desiccant_balancedflow_rb
    result = sim_test('heatexchanger_desiccant_balancedflow.rb')
  end

  def test_heatexchanger_desiccant_balancedflow_osm
    result = sim_test('heatexchanger_desiccant_balancedflow.osm')
  end

  def test_heatpump_hot_water_rb
    result = sim_test('heatpump_hot_water.rb')
  end

  def test_heatpump_hot_water_osm
    result = sim_test('heatpump_hot_water.osm')
  end

  def test_heatpump_plantloop_eir_rb
    result = sim_test('heatpump_plantloop_eir.rb')
  end

  def test_heatpump_plantloop_eir_osm
    result = sim_test('heatpump_plantloop_eir.osm')
  end

  def test_heatpump_varspeed_rb
    result = sim_test('heatpump_varspeed.rb')
  end

  def test_heatpump_varspeed_osm
    result = sim_test('heatpump_varspeed.osm')
  end

  def test_hightemprad_rb
    result = sim_test('hightemprad.rb')
  end

  def test_hightemprad_osm
    result = sim_test('hightemprad.osm')
  end

  def test_hot_water_rb
    result = sim_test('hot_water.rb')
  end

  def test_hot_water_osm
    result = sim_test('hot_water.osm')
  end

  def test_humidity_control_rb
    result = sim_test('humidity_control.rb')
  end

  def test_humidity_control_osm
    result = sim_test('humidity_control.osm')
  end

  def test_humidity_control_2_rb
    result = sim_test('humidity_control_2.rb')
  end

  def test_humidity_control_2_osm
    result = sim_test('humidity_control_2.osm')
  end

  def test_ideal_plant_rb
    result = sim_test('ideal_plant.rb')
  end

  def test_ideal_plant_osm
    result = sim_test('ideal_plant.osm')
  end

  def test_infiltration_rb
    result = sim_test('infiltration.rb')
  end

  def test_infiltration_osm
    result = sim_test('infiltration.osm')
  end

  def test_interior_partitions_rb
    result = sim_test('interior_partitions.rb')
  end

  def test_interior_partitions_osm
    result = sim_test('interior_partitions.osm')
  end

  def test_lifecyclecostparameters_osm
    result = sim_test('lifecyclecostparameters.osm')
  end

  def test_lifecyclecostparameters_rb
    result = sim_test('lifecyclecostparameters.rb')
  end

  def test_lowtemprad_constflow_osm
    result = sim_test('lowtemprad_constflow.osm')
  end

  def test_lowtemprad_constflow_rb
    result = sim_test('lowtemprad_constflow.rb')
  end

  def test_lowtemprad_electric_osm
    result = sim_test('lowtemprad_electric.osm')
  end

  def test_lowtemprad_electric_rb
    result = sim_test('lowtemprad_electric.rb')
  end

  def test_lowtemprad_varflow_osm
    result = sim_test('lowtemprad_varflow.osm')
  end

  def test_lowtemprad_varflow_rb
    result = sim_test('lowtemprad_varflow.rb')
  end

  def test_meters_rb
    result = sim_test('meters.rb')
  end

  def test_meters_osm
    result = sim_test('meters.osm')
  end

  def test_moisture_settings_osm
    result = sim_test('moisture_settings.osm')
  end

  def test_moisture_settings_rb
    result = sim_test('moisture_settings.rb')
  end

  def test_multi_stage_rb
    result = sim_test('multi_stage.rb')
  end

  def test_multi_stage_osm
    result = sim_test('multi_stage.osm')
  end

  def test_multiple_airloops_rb
    result = sim_test('multiple_airloops.rb')
  end

  def test_multiple_airloops_osm
    result = sim_test('multiple_airloops.osm')
  end

  def test_multiple_loops_w_plenums_rb
    result = sim_test('multiple_loops_w_plenums.rb')
  end

  def test_multiple_loops_w_plenums_osm
    result = sim_test('multiple_loops_w_plenums.osm')
  end

  def test_outputcontrol_files_rb
    result = sim_test('outputcontrol_files.rb', { compare_eui: false })

    # We enabled only a few files, so check that
    run_dir = File.join($TestDir, 'outputcontrol_files.rb', 'run')
    assert(File.exist?(run_dir))

    all_files = [
      'eplusout.audit',
      'eplusout.bnd',
      'eplusout.dbg',
      'eplusout.dxf',
      'eplusout.edd',
      'eplusout.eio',
      'eplusout.end',
      'eplusout.epmidf',
      'eplusout.epmdet',
      'eplusout.err',
      'eplusout.eso',
      'eplusout.mdd',
      'eplusout.mtd',
      'eplusout.mtr',
      'eplusout_perflog.csv',
      'eplusout.rdd',
      'eplusout.shd',
      'eplusout.sln',
      'eplusout.sql',
      'eplustbl.htm',
      'eplusssz.csv',
      'epluszsz.csv',
      'eplusout.json',
      'eplusout.csv',
      'eplusmtr.csv',
      'eplustbl.htm',
      'eplusscreen.csv',
      'eplusout.svg',
      'eplusout.sci',
      'eplusout.wrm',
      'eplusout.delightin',
      'eplusout.delightout'
    ]

    expected_files = [
      'eplusout.end',
      'eplusout.sql',
      'eplusout.csv',
      'eplusmtr.csv',
      'eplusout.err',
      'eplusout.audit',
      'eplustbl.htm'
    ]

    assert((expected_files - all_files).empty?)

    expected_files.each do |fname|
      assert(File.exist?(File.join(run_dir, fname)), "Expected #{fname}")
    end

    (all_files - expected_files).each do |fname|
      assert(!File.exist?(File.join(run_dir, fname)), "Did not expect #{fname}")
    end
  end

  def test_outputcontrol_files_osm
    result = sim_test('outputcontrol_files.osm')
  end

  def test_output_objects_rb
    result = sim_test('output_objects.rb')
  end

  def test_output_objects_osm
    result = sim_test('output_objects.osm')
  end

  def test_performanceprecisiontradeoffs_rb
    result = sim_test('performanceprecisiontradeoffs.rb')
  end

  def test_performanceprecisiontradeoffs_osm
    result = sim_test('performanceprecisiontradeoffs.osm')
  end

  def test_photovoltaics_rb
    result = sim_test('photovoltaics.rb')
  end

  def test_photovoltaics_osm
    result = sim_test('photovoltaics.osm')
  end

  def test_photovoltaics_sandia_rb
    result = sim_test('photovoltaics_sandia.rb')
  end

  def test_photovoltaics_sandia_osm
    result = sim_test('photovoltaics_sandia.osm')
  end

  def test_plant_op_schemes_rb
    result = sim_test('plant_op_schemes.rb')
  end

  def test_plant_op_schemes_osm
    result = sim_test('plant_op_schemes.osm')
  end

  def test_plant_op_temp_schemes_rb
    result = sim_test('plant_op_temp_schemes.rb')
  end

  def test_plant_op_temp_schemes_osm
    result = sim_test('plant_op_temp_schemes.osm')
  end

  def test_plant_op_deltatemp_schemes_rb
    result = sim_test('plant_op_deltatemp_schemes.rb')
  end

  def test_plant_op_deltatemp_schemes_osm
    result = sim_test('plant_op_deltatemp_schemes.osm')
  end

  def test_plantloop_avms_rb
    result = sim_test('plantloop_avms.rb')
  end

  def test_plantloop_avms_osm
    result = sim_test('plantloop_avms.osm')
  end

  def test_plantloop_avms_temp_rb
    result = sim_test('plantloop_avms_temp.rb')
  end

  def test_plantloop_avms_temp_osm
    result = sim_test('plantloop_avms_temp.osm')
  end

  def test_plenums_rb
    result = sim_test('plenums.rb')
  end

  def test_plenums_osm
    result = sim_test('plenums.osm')
  end

  def test_pv_and_storage_facilityexcess_rb
    result = sim_test('pv_and_storage_facilityexcess.rb')
  end

  def test_pv_and_storage_facilityexcess_osm
    result = sim_test('pv_and_storage_facilityexcess.osm')
  end

  def test_pv_and_storage_demandleveling_rb
    result = sim_test('pv_and_storage_demandleveling.rb')
  end

  def test_pv_and_storage_demandleveling_osm
    result = sim_test('pv_and_storage_demandleveling.osm')
  end

  def test_refrigeration_system_rb
    result = sim_test('refrigeration_system.rb')
  end

  def test_refrigeration_system_osm
    result = sim_test('refrigeration_system.osm')
  end

  def test_refrigeration_system_2_rb
    result = sim_test('refrigeration_system_2.rb')
  end

  def test_refrigeration_system__2_osm
    result = sim_test('refrigeration_system_2.osm')
  end

  def test_roof_vegetation_rb
    result = sim_test('roof_vegetation.rb')
  end

  def test_roof_vegetation_osm
    result = sim_test('roof_vegetation.osm')
  end

  def test_scheduled_infiltration_osm
    result = sim_test('scheduled_infiltration.osm')
  end

  def test_schedule_ruleset_2012_LeapYear_rb
    result = sim_test('schedule_ruleset_2012_LeapYear.rb')
  end

  def test_schedule_ruleset_2012_LeapYear_osm
    result = sim_test('schedule_ruleset_2012_LeapYear.osm')
  end

  def test_schedule_ruleset_2012_NonLeapYear_rb
    result = sim_test('schedule_ruleset_2012_NonLeapYear.rb')
  end

  def test_schedule_ruleset_2012_NonLeapYear_osm
    result = sim_test('schedule_ruleset_2012_NonLeapYear.osm')
  end

  def test_schedule_ruleset_2013_rb
    result = sim_test('schedule_ruleset_2013.rb')
  end

  def test_schedule_ruleset_2013_osm
    result = sim_test('schedule_ruleset_2013.osm')
  end

  def test_schedule_file_rb
    result = sim_test('schedule_file.rb')
  end

  # Note JM: there is a special case in sim_test for this test to copy the
  # necessary CSV file to the testruns/schedule_file.osm/ folder
  # We cannot do it here since sim_test starts by deleting and recreating
  # this folder
  def test_schedule_file_osm
    result = sim_test('schedule_file.osm')
  end

  def test_schedule_fixed_interval_rb
    result = sim_test('schedule_fixed_interval.rb')
  end

  def test_schedule_fixed_interval_osm
    result = sim_test('schedule_fixed_interval.osm')
  end

  def test_schedule_fixed_interval_schedulefile_rb
    result = sim_test('schedule_fixed_interval_schedulefile.rb')
  end

  def test_schedule_fixed_interval_schedulefile_osm
    result = sim_test('schedule_fixed_interval_schedulefile.osm')
  end

  def test_setpoint_managers_rb
    result = sim_test('setpoint_managers.rb')
  end

  def test_setpoint_managers_osm
    result = sim_test('setpoint_managers.osm')
  end

  def test_shadingcontrol_singlezone_rb
    result = sim_test('shadingcontrol_singlezone.rb')
  end

  def test_shadingcontrol_singlezone_osm
    result = sim_test('shadingcontrol_singlezone.osm')
  end

  def test_shadowcalculation_rb
    result = sim_test('shadowcalculation.rb')
  end

  def test_shadowcalculation_osm
    result = sim_test('shadowcalculation.osm')
  end

  def test_sizing_zone_dszad_rb
    result = sim_test('sizing_zone_dszad.rb')
  end

  def test_sizing_zone_dszad_osm
    result = sim_test('sizing_zone_dszad.osm')
  end

  def test_solar_collector_flat_plate_water_rb
    result = sim_test('solar_collector_flat_plate_water.rb')
  end

  def test_solar_collector_flat_plate_water_osm
    result = sim_test('solar_collector_flat_plate_water.osm')
  end

  def test_solar_collector_flat_plate_photovoltaicthermal_rb
    result = sim_test('solar_collector_flat_plate_photovoltaicthermal.rb')
  end

  # Will fail up to 2.9.0 included due to missing reference in
  # ProposedEnergy+.idd (though this object has been added circa 1.8.4)
  def test_solar_collector_flat_plate_photovoltaicthermal_osm
    result = sim_test('solar_collector_flat_plate_photovoltaicthermal.osm')
  end

  def test_solar_collector_integralcollectorstorage_rb
    result = sim_test('solar_collector_integralcollectorstorage.rb')
  end

  # Will fail up to 2.9.0 included due to missing reference in
  # ProposedEnergy+.idd (though this object has been added circa 1.8.4)
  def test_solar_collector_integralcollectorstorage_osm
    result = sim_test('solar_collector_integralcollectorstorage.osm')
  end

  def test_space_load_instances_rb
    result = sim_test('space_load_instances.rb')
  end

  def test_space_load_instances_osm
    result = sim_test('space_load_instances.osm')
  end

  def test_storage_liion_battery_rb
    result = sim_test('storage_liion_battery.rb')
  end

  def test_storage_liion_battery_osm
    result = sim_test('storage_liion_battery.osm')
  end

  def test_surfacecontrol_moveableinsulation_rb
    result = sim_test('surfacecontrol_moveableinsulation.rb')
  end

  def test_surfacecontrol_moveableinsulation_osm
    result = sim_test('surfacecontrol_moveableinsulation.osm')
  end

  def test_surface_properties_osm
    result = sim_test('surface_properties.osm')
  end

  def test_surface_properties_rb
    result = sim_test('surface_properties.rb')
  end

  def test_swimmingpool_indoor_rb
    result = sim_test('swimmingpool_indoor.rb')
  end

  def test_swimmingpool_indoor_osm
    result = sim_test('swimmingpool_indoor.osm')
  end

  def test_tablemultivariablelookup_rb
    result = sim_test('tablemultivariablelookup.rb')
  end

  def test_tablemultivariablelookup_osm
    result = sim_test('tablemultivariablelookup.osm')
  end

  def test_thermal_storage_rb
    result = sim_test('thermal_storage.rb')
  end

  def test_thermal_storage_osm
    result = sim_test('thermal_storage.osm')
  end

  def test_transformer_rb
    result = sim_test('transformer.rb')
  end

  def test_transformer_osm
    result = sim_test('transformer.osm')
  end

  def test_unitary_system_osm
    result = sim_test('unitary_system.osm')
  end

  def test_unitary_system_rb
    result = sim_test('unitary_system.rb')
  end

  def test_unitary_system_performance_multispeed_rb
    result = sim_test('unitary_system_performance_multispeed.rb')
  end

  def test_unitary_system_performance_multispeed_osm
    result = sim_test('unitary_system_performance_multispeed.osm')
  end

  def test_unitary_test_rb
    result = sim_test('unitary_test.rb')
  end

  def test_unitary_test_osm
    result = sim_test('unitary_test.osm')
  end

  def test_unitary_vav_bypass_rb
    result = sim_test('unitary_vav_bypass.rb')
  end

  def test_unitary_vav_bypass_osm
    result = sim_test('unitary_vav_bypass.osm')
  end

  def test_unitary_vav_bypass_plenum_rb
    result = sim_test('unitary_vav_bypass_plenum.rb')
  end

  def test_unitary_vav_bypass_plenum_osm
    result = sim_test('unitary_vav_bypass_plenum.osm')
  end

  def test_unitary_vav_bypass_coiltypes_rb
    result = sim_test('unitary_vav_bypass_coiltypes.rb')
  end

  # TODO: To be added in the next official release after: 3.2.1
  # def test_unitary_vav_bypass_coiltypes_osm
  # result = sim_test('unitary_vav_bypass_coiltypes.osm')
  # end

  def test_unitary_systems_airloop_and_zonehvac_rb
    result = sim_test('unitary_systems_airloop_and_zonehvac.rb')
  end

  def test_unitary_systems_airloop_and_zonehvac_osm
    result = sim_test('unitary_systems_airloop_and_zonehvac.osm')
  end

  def test_utility_bill01_rb
    result = sim_test('utility_bill01.rb')
  end

  def test_utility_bill01_osm
    result = sim_test('utility_bill01.osm')
  end

  def test_utility_bill02_rb
    result = sim_test('utility_bill02.rb')
  end

  def test_utility_bill02_osm
    result = sim_test('utility_bill02.osm')
  end

  def test_vrf_osm
    result = sim_test('vrf.osm')
  end

  def test_vrf_rb
    result = sim_test('vrf.rb')
  end

  def test_vrf_watercooled_osm
    result = sim_test('vrf_watercooled.osm')
  end

  def test_vrf_watercooled_rb
    result = sim_test('vrf_watercooled.rb')
  end

  def test_vrf_airloophvac_osm
    result = sim_test('vrf_airloophvac.osm')
  end

  def test_vrf_airloophvac_rb
    result = sim_test('vrf_airloophvac.rb')
  end

  def test_water_economizer_osm
    result = sim_test('water_economizer.osm')
  end

  def test_water_economizer_rb
    result = sim_test('water_economizer.rb')
  end

  def test_water_heaters_rb
    result = sim_test('water_heaters.rb')
  end

  def test_water_heaters_osm
    result = sim_test('water_heaters.osm')
  end

  def test_zone_air_movement_rb
    result = sim_test('zone_air_movement.rb')
  end

  def test_zone_air_movement_osm
    result = sim_test('zone_air_movement.osm')
  end

  def test_zone_control_contaminant_controller_rb
    result = sim_test('zone_control_contaminant_controller.rb')
  end

  def test_zone_control_contaminant_controller_osm
    result = sim_test('zone_control_contaminant_controller.osm')
  end

  def test_zone_fan_exhaust_osm
    result = sim_test('zone_fan_exhaust.osm')
  end

  def test_zone_fan_exhaust_rb
    result = sim_test('zone_fan_exhaust.rb')
  end

  def test_zone_hvac_osm
    result = sim_test('zone_hvac.osm')
  end

  def test_zone_hvac_rb
    result = sim_test('zone_hvac.rb')
  end

  def test_zone_hvac2_rb
    result = sim_test('zone_hvac2.rb')
  end

  def test_zone_hvac2_osm
    result = sim_test('zone_hvac2.osm')
  end

  def test_zone_hvac_cooling_panel_rb
    result = sim_test('zone_hvac_cooling_panel.rb')
  end

  def test_zone_hvac_cooling_panel_osm
    result = sim_test('zone_hvac_cooling_panel.osm')
  end

  def test_zone_hvac_equipment_list_rb
    result = sim_test('zone_hvac_equipment_list.rb')
  end

  def test_zone_hvac_equipment_list_osm
    result = sim_test('zone_hvac_equipment_list.osm')
  end

  def test_zone_mixing_osm
    result = sim_test('zone_mixing.osm')
  end

  def test_zone_mixing_rb
    result = sim_test('zone_mixing.rb')
  end

  def test_zoneventilation_windandstackopenarea_rb
    result = sim_test('zoneventilation_windandstackopenarea.rb')
  end

  def test_zoneventilation_windandstackopenarea_osm
    result = sim_test('zoneventilation_windandstackopenarea.osm')
  end

  def test_zone_property_user_view_factors_by_surface_name_rb
    result = sim_test('zone_property_user_view_factors_by_surface_name.rb')
  end

  def test_zone_property_user_view_factors_by_surface_name_osm
    result = sim_test('zone_property_user_view_factors_by_surface_name.osm')
  end

  def test_afn_single_zone_nv_rb
    result = sim_test('afn_single_zone_nv.rb')
  end

  def test_afn_single_zone_nv_osm
    result = sim_test('afn_single_zone_nv.osm')
  end

  # TODO: feature is not yet working, uncomment to test it out
  # def test_afn_single_zone_ac_rb
  #   result = sim_test('afn_single_zone_ac.rb')
  # end

  # TODO: add this test once the ruby version works
  # def test_afn_single_zone_ac_osm
  #   result = sim_test('afn_single_zone_ac.osm')
  # end

  def test_additional_props_rb
    result = sim_test('additional_props.rb')
  end

  def test_additional_props_osm
    result = sim_test('additional_props.osm')
  end

  def test_pvwatts_rb
    result = sim_test('pvwatts.rb')
  end

  def test_pvwatts_osm
    result = sim_test('pvwatts.osm')
  end

  def test_epw_design_conditions_rb
    result = sim_test('epw_design_conditions.rb')
  end

  def test_epw_design_conditions_osm
    result = sim_test('epw_design_conditions.osm')
  end

  # model articulation tests
  def test_model_articulation1_osw
    result = sim_test('model_articulation1.osw')
  end

  def test_model_articulation1_bundle_no_git_osw
    gemfile_dir = bundle_install('bundle_no_git', true)
    gemfile = File.join(gemfile_dir, 'Gemfile')
    bundle_path = File.join(gemfile_dir, 'gems')
    extra_options = { outdir: 'model_articulation1_bundle_no_git.osw',
                      bundle: gemfile, bundle_path: bundle_path }
    result = sim_test('model_articulation1.osw', extra_options)

    # check that we got the right version of standards and workflow
    # standards = nil
    workflow = nil
    result[:steps].each do |step|
      if step[:measure_dir_name] == 'openstudio_results'
        step[:result][:step_values].each do |step_value|
          # if step_value[:name] == 'standards_gem_version'
          #  standards = step_value[:value]
          if step_value[:name] == 'workflow_gem_version'
            workflow = step_value[:value]
          end
        end
      end
    end
    # assert(standards.is_a? String)
    assert(workflow.is_a?(String))
    # puts "standards = #{standards}"
    # puts "workflow = #{workflow}"

    # assert(/0.2.7/.match(standards))
    assert(/2.2.0/.match(workflow))
  end

  def test_model_articulation1_bundle_git_osw
    gemfile_dir = bundle_install('bundle_git', true)
    gemfile = File.join(gemfile_dir, 'Gemfile')
    bundle_path = File.join(gemfile_dir, 'gems')
    extra_options = { outdir: 'model_articulation1_bundle_git.osw',
                      bundle: gemfile, bundle_path: bundle_path,
                      # TODO: Temp for debug for #134
                      verbose: true, debug: true }
    result = sim_test('model_articulation1.osw', extra_options)

    # check that we got the right version of standards and workflow
    # standards = nil
    workflow = nil
    result[:steps].each do |step|
      if step[:measure_dir_name] == 'openstudio_results'
        step[:result][:step_values].each do |step_value|
          # if step_value[:name] == 'standards_gem_version'
          #  standards = step_value[:value]
          if step_value[:name] == 'workflow_gem_version'
            workflow = step_value[:value]
          end
        end
      end
    end
    # assert(standards.is_a? String)
    assert(workflow.is_a?(String))
    # puts "standards = #{standards}"
    # puts "workflow = #{workflow}"

    # assert(/0.2.7/.match(standards))
    assert(/2.2.0/.match(workflow))
  end

  # intersection tests

  def test_intersect_22_osm
    result = intersect_test('22.osm')
  end

  def test_intersect_74_osm
    result = intersect_test('74.osm')
  end

  def test_intersect_131_osm
    result = intersect_test('131.osm')
  end

  def test_intersect_136_osm
    result = intersect_test('136.osm')
  end

  def test_intersect_145_osm
    result = intersect_test('145.osm')
  end

  def test_intersect_146_osm
    result = intersect_test('146.osm')
  end

  def test_intersect_156_osm
    result = intersect_test('156.osm')
  end

  def test_intersect_356_osm
    result = intersect_test('356.osm')
  end

  def test_intersect_370_osm
    result = intersect_test('370.osm')
  end

  def test_intersect_test3_osm
    result = intersect_test('test3.osm')
  end

  def test_intersect_test4_osm
    result = intersect_test('test4.osm')
  end

  # autosizing tests
  def test_autosizing_rb
    result = autosizing_test('autosize_hvac.rb')
  end

  # TODO: model/refbuildingtests/CreateRefBldgModel.rb is unused
  # Either implement as a test, or delete
end
