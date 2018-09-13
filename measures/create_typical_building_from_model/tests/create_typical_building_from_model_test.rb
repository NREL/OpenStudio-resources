require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class CreateTypicalBuildingFromModel_Test < Minitest::Test
  def run_dir(test_name)
    # will make directory if it doesn't exist
    output_dir = File.expand_path('output', File.dirname(__FILE__))
    FileUtils.mkdir output_dir unless Dir.exist? output_dir

    # always generate test output in specially named 'output' directory so result files are not made part of the measure
    "#{File.dirname(__FILE__)}/output/#{test_name}"
  end

  # method to apply arguments, run measure, and assert results (only populate args hash with non-default argument values)
  def apply_measure_to_model(test_name, args, model_name = nil, result_value = 'Success', warnings_count = 0, info_count = nil)
    # create an instance of the measure
    measure = CreateTypicalBuildingFromModel.new

    # create an instance of a runner with OSW
    osw_path = OpenStudio::Path.new(File.dirname(__FILE__) + '/test.osw')
    osw = OpenStudio::WorkflowJSON.load(osw_path).get
    runner = OpenStudio::Measure::OSRunner.new(osw)

    if model_name.nil?
      # make an empty model
      model = OpenStudio::Model::Model.new
    else
      # load the test model
      translator = OpenStudio::OSVersion::VersionTranslator.new
      path = OpenStudio::Path.new(File.dirname(__FILE__) + '/' + model_name)
      model = translator.loadModel(path)
      assert(!model.empty?)
      model = model.get
    end

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args.key?(arg.name)
        assert(temp_arg_var.setValue(args[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # temporarily change directory to the run directory and run the measure (because of sizing run)
    start_dir = Dir.pwd
    begin
      unless Dir.exist?(run_dir(test_name))
        Dir.mkdir(run_dir(test_name))
      end
      Dir.chdir(run_dir(test_name))

      # run the measure
      measure.run(model, runner, argument_map)
      result = runner.result
    ensure
      Dir.chdir(start_dir)

      # delete sizing run dir
      FileUtils.rm_rf(run_dir(test_name))
    end

    # show the output
    puts "measure results for #{test_name}"
    show_output(result)

    # assert that it ran correctly
    if result_value.nil? then result_value = 'Success' end
    assert_equal(result_value, result.value.valueName)

    # check count of warning and info messages
    unless info_count.nil? then assert(result.info.size == info_count) end
    unless warnings_count.nil? then assert(result.warnings.size == warnings_count) end

    # if 'Fail' passed in make sure at least one error message (while not typical there may be more than one message)
    if result_value == 'Fail' then assert(result.errors.size >= 1) end

    # save the model to test output directory
    output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + "/output/#{test_name}_test_output.osm")
    model.save(output_file_path, true)
  end

  def test_midrise_apartment
    apply_measure_to_model(__method__.to_s.gsub('test_', ''), {}, 'MidriseApartment.osm', nil, nil)
  end

  def test_small_office
    apply_measure_to_model(__method__.to_s.gsub('test_', ''), {}, 'SmallOffice.osm', nil, nil)
  end

  # might be cleaner to update standards to not make ext light object with multipler of 0, but for now it does seem to run through E+ fine.
  def test_no_onsite_parking
    args = {}
    args['onsite_parking_fraction'] = 0.0
    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, 'SmallOffice.osm', nil, nil)
  end

  def test_large_office
    args = {}
    args['add_elevators'] = false
    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, 'LargeOffice04.osm', nil, nil)
  end

  def test_small_office_no_extra_loads_with_pvav
    args = {}
    args['add_elevators'] = false
    args['add_exhaust'] = false
    args['add_exterior_lights'] = false
    args['add_swh'] = false
    # args['system_type'] = "Packaged VAV Air Loop with Boiler"

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, 'SmallOffice.osm', nil, nil)
  end

  # maade this test for temp work around for night cycle mode
  def test_pfp_boxes
    args = {}
    args['system_type'] = 'VAV with PFP boxes'
    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, 'SmallOffice.osm', nil, nil)
  end
end
