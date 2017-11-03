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

# test the autosizing methods
def autosizing_test(filename, weather_file = nil, model_measures = [], energyplus_measures = [], reporting_measures = [])
  dir = File.join($TestDir, filename)
  osw = File.join(dir, 'in.osw')
  out_osw = File.join(dir, 'out.osw')
  in_osm = File.join(dir, 'in.osm')
  sql_path = File.join(dir, 'run', 'eplusout.sql')
  
  $OPENSTUDIO_LOG = OpenStudio::StringStreamLogSink.new
  $OPENSTUDIO_LOG.setLogLevel(OpenStudio::Debug)

  # Run the workflow
  run_sim = false
  if run_sim
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
  end
  
  fail "Cannot find file #{out_osw}" if !File.exists?(out_osw)
  
  result_osw = nil
  File.open(out_osw, 'r') do |f|
    result_osw = JSON::parse(f.read, :symbolize_names=>true)
  end

  # Load the model
  versionTranslator = OpenStudio::OSVersion::VersionTranslator.new 
  model = versionTranslator.loadModel(in_osm)
  if model.empty?
    assert(model.is_initialized, "Could not load the resulting model, #{in_osm}")
  end
  model = model.get
  
  # Load and attach the sql file to the model
  sql_path = OpenStudio::Path.new(sql_path)
  if OpenStudio.exists(sql_path)
    sql = OpenStudio::SqlFile.new(sql_path)
    # Check to make sure the sql file is readable,
    # which won't be true if EnergyPlus crashed during simulation.
    unless sql.connectionOpen
      OpenStudio.logFree(OpenStudio::Error, 'openstudio.model.Model', "The run failed, cannot create model.  Look at the eplusout.err file in #{File.dirname(sql_path.to_s)} to see the cause.")
      return false
    end
    # Attach the sql file from the run to the model
    model.setSqlFile(sql)
  else
    OpenStudio.logFree(OpenStudio::Error, 'openstudio.model.Model', "Results for the run couldn't be found here: #{sql_path}.")
    return false
  end
  
  # Assert that the sizing run succeeded
  assert_equal("Success", result_osw[:completed_status]) 

  # Skip testing all methods for some objects
  # Skip testing some methods for other objects
  obj_types_to_skip = {
    'OS:WaterHeater:Mixed' => 'all', # WH sizing object not wrapped
    'OS:WaterHeater:Stratified' => 'all', # WH sizing object not wrapped
    'OS:WaterHeater:HeatPump' => 'all', # WH sizing object not wrapped
    'OS:WaterHeater:HeatPump:PumpedCondenser' => 'all', # WH sizing object not wrapped
    'OS:Boiler:Steam' => 'all', # CoilHeatingSteam is not wrapped, cannot use steam boiler in OS
    'OS:ChillerHeaterPerformance:Electric:EIR' => 'all', # TODO Not in test model (central HP system)
    'OS:SolarCollector:FlatPlate:PhotovoltaicThermal' => 'all', # TODO Not in test model
    'OS:Chiller:Absorption' => [
      'autosizedDesignGeneratorFluidFlowRate' # Generator loop not supported by OS
    ],
    'OS:Chiller:Absorption:Indirect' => [
      'autosizedDesignGeneratorFluidFlowRate' # Generator loop not supported by OS
    ],
    'OS:AirConditioner:VariableRefrigerantFlow' => [
      'autosizedWaterCondenserVolumeFlowRate' # Water-cooled VRF not supported by OS
    ],
    'OS:CoolingTower:TwoSpeed' => [
      'autosizedLowSpeedNominalCapacity', # Method only works on cooling towers sized a certain way, which test model isn't using
      'autosizedFreeConvectionNominalCapacity' # Method only works on cooling towers sized a certain way, which test model isn't using
    ],
    'OS:ZoneHVAC:LowTemperatureRadiant:VariableFlow' => [
      'autosizedHeatingDesignCapacity', # No OS methods for this field
      'autosizedCoolingDesignCapacity' # No OS methods for this field
    ]
  }
  
  # Aliases for some OS onjects
  os_type_aliases = {
    'OS:Coil:Cooling:LowTemperatureRadiant:VariableFlow' => 'OS:Coil:Cooling:LowTempRadiant:VarFlow',
    'OS:Coil:Heating:LowTemperatureRadiant:VariableFlow' => 'OS:Coil:Heating:LowTempRadiant:VarFlow',
    'OS:ZoneHVAC:LowTemperatureRadiant:VariableFlow' => 'OS:ZoneHVAC:LowTempRadiant:VarFlow',
  }
  
  # List of objects and fields where the autosized output does
  # not exist in the E+ output, even under a different name.
  # These are things the E+ team should fix.
  missing_getters = {
    'OS:Coil:Heating:Water:Baseboard:Radiant' => [
      'autosizedHeatingDesignCapacity'
    ],
    'OS:AirLoopHVAC:Unitary:HeatPump:AirToAir' => [
      'autosizedSupplyAirFlowRateWhenNoCoolingorHeatingisNeeded'
    ],
    'OS:Coil:Heating:Water:Baseboard' => [
      'autosizedHeatingDesignCapacity'
    ],
    'OS:EvaporativeFluidCooler:TwoSpeed' => [
      'autosizedLowSpeedUserSpecifiedDesignCapacity',
      'autosizedLowSpeedStandardDesignCapacity'
    ],
    'OS:ZoneHVAC:IdealLoadsAirSystem' => [
      'autosizedMaximumSensibleHeatingCapacity',
      'autosizedMaximumTotalCoolingCapacity'
    ],
    'OS:ZoneHVAC:FourPipeFanCoil' => [
      'autosizedMinimumSupplyAirTemperatureinCoolingMode',
      'autosizedMaximumSupplyAirTemperatureinHeatingMode'
    ],
    'OS:ZoneHVAC:UnitHeater' => [
      'autosizedMaximumHotWaterFlowRate'
    ],
    'OS:FluidCooler:TwoSpeed' => [
      'autosizedLowSpeedStandardDesignCapacity',
      'autosizedLowSpeedUserSpecifiedDesignCapacity'
    ],
    'OS:ZoneHVAC:Baseboard:RadiantConvective:Water' => [
      'autosizedHeatingDesignCapacity' # OS method for child coil, but E+ is missing output
    ],
    'OS:ZoneHVAC:Baseboard:Convective:Water' => [
      'autosizedHeatingDesignCapacity' # OS method for child coil, but E+ is missing output
    ],
    'OS:ThermalStorage:ChilledWater:Stratified' => [
      'autosizedUseSideInletHeight',
      'autosizedSourceSideOutletHeight'
    ]
    
  }
 
  # List of objects and methods where the getter name does not
  # match the IDD field name because of IDD shift, capitalization, etc.
  getter_aliases = {
    'OS:AirTerminal:SingleDuct:VAV:Reheat' => {
      'autosizedMaximumHotWaterorSteamFlowRate' => 'autosizedMaximumHotWaterOrSteamFlowRate', # Capitalization of 'Or'
      'autosizedMaximumFlowperZoneFloorAreaDuringReheat' => 'autosizedMaximumFlowPerZoneFloorAreaDuringReheat', # Capitalization of 'Per'
    },
    'OS:HeatPump:WaterToWater:EquationFit:Heating' => {
      'autosizedReferenceHeatingCapacity' => 'autosizedRatedHeatingCapacity',
      'autosizedReferenceHeatingPowerConsumption' => 'autosizedRatedHeatingPowerConsumption',
    },
    'OS:HeatPump:WaterToWater:EquationFit:Cooling' => {
      'autosizedReferenceCoolingCapacity' => 'autosizedRatedCoolingCapacity',
      'autosizedReferenceCoolingPowerConsumption' => 'autosizedRatedCoolingPowerConsumption',
    }
  }
  
  # Search the IDD associated with this model
  # and assert that there is at least one of every object
  # that has autosized fields in the test model.
  obj_counts = {}
  not_wrapped = []
  missing_autosizedFoo = []
  failed_autosizedFoo = []
  succeeded_autosizedFoo = []
  model.iddFile.objects.each do |idd_obj_type|
    autosizable_field_names = []
    idd_obj_type.nonextensibleFields.each do |idd_field|
      if idd_field.properties.autosizable
        autosizable_field_names << idd_field.name
      end
    end
    
    # Get the OS type
    os_type = idd_obj_type.type.valueDescription
    
    # Check if this object type has a different name in OS
    os_type = os_type_aliases[os_type] if os_type_aliases[os_type]  
    
    # Convert to IDD type
    type = os_type.gsub('OS:','').gsub(':','')

    # Skip objects with no autosizable fields
    next if autosizable_field_names.empty?

    # Skip certain object types entirely
    methods_to_skip = obj_types_to_skip[os_type]
    next if methods_to_skip == 'all'
    methods_to_skip = [] if methods_to_skip.nil?
    
    # Convert the type name into a getter for objects from model
    method_name = "get#{type}s"
    
    # Skip objects that are in the IDD but not wrapped
    unless model.respond_to? method_name
      not_wrapped << type
      next
    end
   
    # Get the total number count of the objects
    # Add the objects to a hash by object type
    objs = model.public_send(method_name)
    obj_counts[type] = objs.size
    next if objs.size == 0
    
    # Get the first instance of this object type in the model
    obj = objs.sort[0]
    
    # Special cases
    case type 
    when 'SizingSystem' # Need to check an AirLoop with an OA system
      objs.sort.each do |o| 
        obj = o if o.airLoopHVAC.name.get == 'Air Loop'
      end
    when 'SizingZone' # Need to check a zone sized w/ DOAS
      objs.sort.each do |o|
        obj = o if o.thermalZone.name.get == 'Story 5 North Perimeter Thermal Zone'
      end
    when 'AirLoopHVACUnitarySystem' # Need to check a unitary where no load flow is autosized
      objs.sort.each do |o|
        obj = o if o.name.get == 'Air Loop HVAC Unitary System 3'
      end  
    end
    
    # Test all autosizedFoo methods on this instance
    autosizable_field_names.each do |auto_field|
      # Make the getter name from the IDD field
      getter_name = "autosized#{auto_field.gsub(/\W/,'').strip}"

      # Replace the getter name with known alias, if one exists
      obj_aliases = getter_aliases[os_type]
      if obj_aliases
        getter_name = obj_aliases[getter_name] unless obj_aliases[getter_name].nil?
      end

      # Don't test this getter if it is designated to be skipped
      next if methods_to_skip.include?(getter_name)
      
      # Don't test this getter if it is known to be missing from E+ output
      obj_missing_getters = missing_getters[os_type]
      if obj_missing_getters
        next if obj_missing_getters.include?(getter_name)
      end
      
      # Check if the autosizedFoo method has been implemented for this object
      unless obj.respond_to? getter_name
        missing_autosizedFoo << "#{getter_name} not a valid method for object of type #{type}"
        next
      end
        
      # Try the method on the object to ensure that the SQL query in C++ is correct
      val = obj.public_send(getter_name)
      if val.is_initialized
        succeeded_autosizedFoo << "#{getter_name} succeeded for #{obj.name} of type #{type}"
      else
        failed_autosizedFoo << "#{getter_name} failed for #{obj.name} of type #{type}"
      end

    end

  end

  puts "\n*** Autosizable Objects not Wrapped by OpenStudio ***"
  not_wrapped.each { |f| puts f }

  puts "\n*** Failures ***"
  failed_autosizedFoo.each { |f| puts f }
  
  puts "\n*** Methods that aren't implemented in C++ (but should be) ***"
  missing_autosizedFoo.each { |f| puts f }

  puts "\n*** Missing Objects ***"
  missing_objs = []
  obj_counts.each do |type, count|
    if count.zero?
      missing_objs << type
      puts "#{type} is missing from test model"
    end
  end
  
  # Assert that no autosizable objects are missing from the test model
  # so that if someone wraps a new object and doesn't add it to this file, the test will fail.
  assert_equal(0, missing_objs.size, "There are #{missing_objs.size} autosizable objects missing from the test model:\n#{missing_objs.join("\n")}.")

  # Assert that every autosizable field for every object has a corresponding method implemented
  assert_equal(0, missing_autosizedFoo.size, "#{missing_autosizedFoo.size} autosizedFoo methods not implemented in C++:\n#{missing_autosizedFoo.join("\n")}.")
  
  # Assert that every autosizable field's getter returns a value 
  assert_equal(0, failed_autosizedFoo.size, "#{failed_autosizedFoo.size} autosizedFoo methods failed to return a value:\n#{failed_autosizedFoo.join("\n")}.")

  # Add a few more object types to skip testing for based on test file object inputs
  obj_types_to_skip['OS:EvaporativeFluidCooler:TwoSpeed'] = [
      'autosizedDesignWaterFlowRate', # Value only present for some fluid cooler sizing input methods in test file
    ]
  obj_types_to_skip['OS:Sizing:System'] = [
      'autosizedDesignOutdoorAirFlowRate', # Not all AirLoopHVACs in model have OA system, needed for this output to exist
    ]
  obj_types_to_skip['OS:AirLoopHVAC:UnitarySystem'] = [
      'autosizedNoLoadSupplyAirFlowRate', # Not all Unitarys in test model have this field autosized
    ]
    
  # Count the number of autosized fields in the model
  def autosized_fields(model, obj_types_to_skip, missing_getters)
  
    # Convert to IDF
    idf = OpenStudio::EnergyPlus::ForwardTranslator.new.translateModel(model).toIdfFile

    # Ensure that all fields are set to "Autosize" or "Autocalculate"
    fields_autosized = []
    autosize_aliases = ['AutoSize', 'Autocalculate', 'Autosize', 'autocalculate']  
    idf.objects.sort.each do |obj|
      os_type = "OS:#{obj.iddObject.type.valueDescription}"
      
      # Skip certain object types entirely
      methods_to_skip = obj_types_to_skip[os_type]
      next if methods_to_skip == 'all'
      methods_to_skip = [] if methods_to_skip.nil?
      
      # Get the list of getters to skip because missing from E+
      fields_to_skip = missing_getters[os_type]
      fields_to_skip = [] if fields_to_skip.nil?
      
      for field_num in 0..obj.numFields
        field_name = obj.fieldComment(field_num, true).to_s.gsub('!-','').gsub(/{.*}/,'').gsub(' ', '').strip
        getter_name = "autosized#{field_name}"
        # Don't check fields whose getters aren't being tested
        next if methods_to_skip.include?(getter_name)
        # Don't check fields whose getters aren't working because of E+ defficiencies
        next if fields_to_skip.include?(getter_name)
        # Check the value of the field
        val = obj.getString(field_num).to_s
        if autosize_aliases.include?(val)
          fields_still_autosized << "field #{field_name} in #{obj.iddObject.type.valueDescription}"
        end
      end
      
      return fields_autosized
    end
    
    # return result_osw for further checks
    return result_osw
  end
  
  # Get the autosized fields before hard sizing
  autosized_fields_before_hard_size = autosized_fields(model, obj_types_to_skip, missing_getters)
  
  # Hard-size the entire model
  model.applySizingValues()
    
  # Get the autosized fields after hard sizing
  autosized_fields_after_hard_size = autosized_fields(model, obj_types_to_skip, missing_getters)
  
  # Auto-size the entire model
  model.autosize()
  
  # Get the autosized fields after hard sizing
  autosized_fields_after_auto_size = autosized_fields(model, obj_types_to_skip, missing_getters)

  puts "\n*** Fields that are still autosized after hard sizing (but should not be) ***"
  autosized_fields_after_hard_size.each { |f| puts f }
  
  # Assert that all fields were hard-sized appropriately
  assert_equal(0, autosized_fields_after_hard_size.size, "#{autosized_fields_after_hard_size.size} autosized fields should be hard-sized, but aren't:\n#{failed_autosizedFoo.join("\n")}.")  
  
  # Assert that all fields were set back to autosized
  assert_equal(autosized_fields_before_hard_size.size, autosized_fields_after_auto_size.size, "The number of autosized fields before hard sizing and after autosizing don't match.")  

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
  
  def test_moisture_settings_rb
    result = sim_test('moisture_settings.rb')
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
  
end
