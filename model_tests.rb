require 'openstudio'

require 'fileutils'
require 'json'
require 'minitest/unit'
require 'minitest/parallel_each'
require 'minitest/autorun'

# config stuff
$OpenstudioCli = OpenStudio::getOpenStudioCLI
$RootDir = File.absolute_path(File.dirname(__FILE__))
$OswFile = File.join($RootDir, 'test.osw')
$ModelDir = File.join($RootDir, 'model/simulationtests/')
$TestDir = File.join($RootDir, 'testruns')

ENV['RUBYLIB'] = $ModelDir 

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
    pwd = Dir.pwd
    Dir.chdir(dir)
    command = "\"#{$OpenstudioCli}\" \"#{File.join($ModelDir,filename)}\""
    system(command) # creates in.osm
    Dir.chdir(pwd)
    
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

  result = system(command) 
  
  fail "Cannot find file #{out_osw}" if !File.exists?(out_osw)

  result = nil
  File.open(out_osw, 'r') do |f|
    result = JSON::parse(f.read, :symbolize_names=>true)
  end
  
  # standard checks
  assert_equal("Success", result[:completed_status])
  
  # return out_osw for further checks
  return result
end



# the tests
class ModelTests < MiniTest::Unit::TestCase
  parallelize_me!
  
  def test_baseline_sys01_rb
    result = sim_test('baseline_sys01.rb')
  end

  def test_baseline_sys01_osm
    result = sim_test('baseline_sys01.osm')
  end
end