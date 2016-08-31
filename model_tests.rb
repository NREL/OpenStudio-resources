require 'fileutils'
require 'minitest/autorun'

# config stuff
$OpenstudioCli = 'E:\openstudio-2-0\core-build\Products\Debug\openstudio.exe'
$RootDir = File.absolute_path(File.dirname(__FILE__))
$OswFile = File.join($RootDir, 'test.osw')
$ModelDir = File.join($RootDir, 'model/simulationtests/')
$TestDir = File.join($RootDir, 'testruns')

# run a test
def run_test(filename)
  dir = File.join($TestDir, filename)
  osw = File.join(dir, 'in.osw')
 
  FileUtils.rm_rf(dir) if File.exists?(dir)
  FileUtils.mkdir_p(dir)
  FileUtils.cp($OswFile, osw)
  
  ext = File.extname(filename)
  if (ext == '.osm')
    FileUtils.cp(File.join($ModelDir,filename), File.join(dir, 'in.osm'))  
  elsif (ext == '.rb')
    pwd = Dir.pwd
    Dir.chdir(dir)
    system("'#{$OpenstudioCli}' '#{File.join($ModelDir,filename)}'") # creates in.osm
    Dir.chdir(pwd)
  end
  
  system("'#{$OpenstudioCli}' run -w '#{osw}'") 
  
  # todo, stick a QAQC measure on the end and check for reasonableness
  
  # todo, allow other measures to be passed in to add to the workflow, e.g. to check for custom results
end


class Minitest::Test
  parallelize_me!
end

# the tests
class ModelTests < MiniTest::Test
  def test_refrigeration_system_rb
    run_test('refrigeration_system.rb')
  end

  def test_refrigeration_system_osm
    run_test('refrigeration_system.osm')
  end
end