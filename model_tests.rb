require 'openstudio'

require 'fileutils'
require 'json'
require 'erb'
require 'timeout'
require 'open3'

require 'etc'
ENV['N'] = [1, Etc.nprocessors - 1].max.to_s

require 'minitest/autorun'

# config stuff
$OpenstudioCli = OpenStudio::getOpenStudioCLI
$RootDir = File.absolute_path(File.dirname(__FILE__))
$OswFile = File.join($RootDir, 'test.osw')
$ModelDir = File.join($RootDir, 'model/simulationtests/')
$IntersectDir = File.join($RootDir, 'model/intersectiontests/')
$IntersectFile = File.join($RootDir, 'intersect.rb.erb')
$TestDir = File.join($RootDir, 'testruns')

$:.unshift($ModelDir)
ENV['RUBYLIB'] = $ModelDir
ENV['RUBYPATH'] = $ModelDir

# run a command in directory dir, throws exception on timeout or exit status != 0, always returns to initial directory
def run_command(command, dir, timeout = Float::INFINITY)
  pwd = Dir.pwd
  Dir.chdir(dir)
  
  result = nil
  Open3.popen3(command) do |i,o,e,w|
    out = ""
    begin
      Timeout.timeout(timeout) do 
        # process output of the process. it will produce EOF when done.
        until o.eof? do
          out += o.read_nonblock(100)
        end
        until e.eof? do
          out += e.read_nonblock(100)
        end        
      end
      
      result = w.value.exitstatus
      if result != 0
        Dir.chdir(pwd)
        fail "Exit code #{result}:\n#{out}"
      end
      
    rescue Timeout::Error
      Process.kill("KILL", w.pid)
      Dir.chdir(pwd)
      fail "Timeout #{timeout}:\n#{out}"
    end
  end
  
  Dir.chdir(pwd)
end

# run a simulation test
def sim_test(filename, weather_file = nil, model_measures = [], energyplus_measures = [], reporting_measures = [])
  dir = File.join($TestDir, filename)
  osw = File.join(dir, 'in.osw')
  out_osw = File.join(dir, 'out.osw')
  in_osm = File.join(dir, 'in.osm')
  
  # todo, modify different weather file in osw
  
  # todo, add other measures to the workflow
 
  FileUtils.rm_rf(dir) if File.exists?(dir)
  FileUtils.mkdir_p(dir)
  FileUtils.cp($OswFile, osw)
  
  ext = File.extname(filename)
  if (ext == '.osm')
    FileUtils.cp(File.join($ModelDir,filename), in_osm)  
  elsif (ext == '.rb')
    command = "\"#{$OpenstudioCli}\" \"#{File.join($ModelDir,filename)}\""
    run_command(command, dir, 600)
    
    # tests used to write out.osm
    out_osm = File.join(dir, 'out.osm')
    if File.exists?(out_osm)
      puts "moving #{out_osm} to #{in_osm}"
      FileUtils.mv(out_osm, in_osm)
    end
    
    fail "Cannot find file #{in_osm}" if !File.exists?(in_osm)
  end
  
  command = "\"#{$OpenstudioCli}\" run -w \"#{osw}\""
  #command = "\"#{$OpenstudioCli}\" run --debug -w \"#{osw}\""

  run_command(command, dir, 1200)
  
  fail "Cannot find file #{out_osw}" if !File.exists?(out_osw)

  result_osw = nil
  File.open(out_osw, 'r') do |f|
    result_osw = JSON::parse(f.read, :symbolize_names=>true)
  end
  
  # standard checks
  assert_equal("Success", result_osw[:completed_status])
  
  # return result_osw for further checks
  return result_osw
end

def intersect_test(filename)

  dir = File.join($TestDir, 'intersections', filename)
  src_osm = File.join($IntersectDir, filename)
  in_osm = File.join(dir, 'in.osm')
  out_osm = File.join(dir, 'out.osm')
  rb_file = File.join(dir, 'intersect.rb')
  
  FileUtils.rm_rf(dir) if File.exists?(dir)
  FileUtils.mkdir_p(dir)
  
  erb_in = ''
  File.open($IntersectFile, 'r') do |file|
    erb_in = file.read
  end

  # configure template with variable values
  renderer = ERB.new(erb_in)
  erb_out = renderer.result(binding)
 
  File.open(rb_file, 'w') do |file|
    file.puts erb_out
  end

  command = "\"#{$OpenstudioCli}\" intersect.rb"
  run_command(command, dir, 360)
end


# the tests
class ModelTests < MiniTest::Unit::TestCase
  parallelize_me!
  
  # simulation tests
  
  def test_absorption_chillers_rb
    result = sim_test('absorption_chillers.rb')
  end

  def test_airterminal_cooledbeam_osm
    result = sim_test('airterminal_cooledbeam.osm')
  end

  def test_airterminal_cooledbeam_rb
    result = sim_test('airterminal_cooledbeam.rb')
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

  def test_asymmetric_interior_constructions_osm
    result = sim_test('asymmetric_interior_constructions.osm')
  end

  def test_availability_managers_rb
    result = sim_test('availability_managers.rb')
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

  def test_coolingtowers_osm
    result = sim_test('coolingtowers.osm')
  end

  def test_coolingtowers_rb
    result = sim_test('coolingtowers.rb')
  end

  def test_cooling_coils_rb
    result = sim_test('cooling_coils.rb')
  end

  def test_daylighting_no_shades_rb
    result = sim_test('daylighting_no_shades.rb')
  end

  def test_daylighting_shades_rb
    result = sim_test('daylighting_shades.rb')
  end

  def test_dist_ht_cl_osm
    result = sim_test('dist_ht_cl.osm')
  end

  def test_dist_ht_cl_rb
    result = sim_test('dist_ht_cl.rb')
  end

  def test_dsn_oa_w_ideal_loads_osm
    result = sim_test('dsn_oa_w_ideal_loads.osm')
  end

  def test_dsn_oa_w_ideal_loads_rb
    result = sim_test('dsn_oa_w_ideal_loads.rb')
  end

  def test_dual_duct_rb
    result = sim_test('dual_duct.rb')
  end

  def test_ducts_and_pipes_rb
    result = sim_test('ducts_and_pipes.rb')
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

  def test_fan_on_off_osm
    result = sim_test('fan_on_off.osm')
  end

  def test_fan_on_off_rb
    result = sim_test('fan_on_off.rb')
  end

  def test_fluid_coolers_rb
    result = sim_test('fluid_coolers.rb')
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

  def test_heatpump_hot_water_rb
    result = sim_test('heatpump_hot_water.rb')
  end

  def test_hightemprad_rb
    result = sim_test('hightemprad.rb')
  end

  def test_hot_water_rb
    result = sim_test('hot_water.rb')
  end

  def test_humidity_control_rb
    result = sim_test('humidity_control.rb')
  end

  def test_ideal_plant_rb
    result = sim_test('ideal_plant.rb')
  end

  def test_interior_partitions_rb
    result = sim_test('interior_partitions.rb')
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

  def test_Medium_HVACHeavy_osm
    result = sim_test('Medium_HVACHeavy.osm')
  end

  def test_multi_stage_rb
    result = sim_test('multi_stage.rb')
  end

  def test_plant_op_schemes_rb
    result = sim_test('plant_op_schemes.rb')
  end

  def test_plenums_rb
    result = sim_test('plenums.rb')
  end

  def test_refrigeration_system_osm
    result = sim_test('refrigeration_system.osm')
  end

  def test_refrigeration_system_rb
    result = sim_test('refrigeration_system.rb')
  end

  def test_scheduled_infiltration_osm
    result = sim_test('scheduled_infiltration.osm')
  end

  def test_schedule_ruleset_2012_LeapYear_rb
    result = sim_test('schedule_ruleset_2012_LeapYear.rb')
  end

  def test_schedule_ruleset_2012_NonLeapYear_rb
    result = sim_test('schedule_ruleset_2012_NonLeapYear.rb')
  end

  def test_schedule_ruleset_2013_rb
    result = sim_test('schedule_ruleset_2013.rb')
  end

  def test_setpoint_managers_rb
    result = sim_test('setpoint_managers.rb')
  end

  def test_solar_collector_flat_plate_water_rb
    result = sim_test('solar_collector_flat_plate_water.rb')
  end

  def test_surface_properties_osm
    result = sim_test('surface_properties.osm')
  end

  def test_surface_properties_rb
    result = sim_test('surface_properties.rb')
  end

  def test_thermal_storage_rb
    result = sim_test('thermal_storage.rb')
  end

  def test_unitary_system_osm
    result = sim_test('unitary_system.osm')
  end

  def test_unitary_system_rb
    result = sim_test('unitary_system.rb')
  end

  def test_unitary_test_rb
    result = sim_test('unitary_test.rb')
  end

  def test_unitary_vav_bypass_rb
    result = sim_test('unitary_vav_bypass.rb')
  end

  def test_utility_bill01_rb
    result = sim_test('utility_bill01.rb')
  end

  def test_utility_bill02_rb
    result = sim_test('utility_bill02.rb')
  end

  def test_vrf_osm
    result = sim_test('vrf.osm')
  end

  def test_vrf_rb
    result = sim_test('vrf.rb')
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

  def test_zone_air_movement_rb
    result = sim_test('zone_air_movement.rb')
  end

  def test_zone_control_contaminant_controller_rb
    result = sim_test('zone_control_contaminant_controller.rb')
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

  def test_zone_mixing_osm
    result = sim_test('zone_mixing.osm')
  end

  def test_zone_mixing_rb
    result = sim_test('zone_mixing.rb')
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
end