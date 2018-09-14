require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class CreateBarFromBuildingTypeRatios_Test < Minitest::Test
  # method to apply arguments, run measure, and assert results (only populate args hash with non-default argument values)
  def apply_measure_to_model(test_name, args, model_name = nil, result_value = 'Success', warnings_count = 0, info_count = nil)
    # create an instance of the measure
    measure = CreateBarFromBuildingTypeRatios.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

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
        assert(temp_arg_var.setValue(args[arg.name]), "could not set #{arg.name} to #{args[arg.name]}.")
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result

    # show the output
    puts "measure results for #{test_name}"
    show_output(result)

    # assert that it ran correctly
    if result_value.nil? then result_value = 'Success' end
    assert_equal(result_value, result.value.valueName)

    # check count of warning and info messages
    unless info_count.nil? then assert(result.info.size == info_count) end
    unless warnings_count.nil? then assert(result.warnings.size == warnings_count, "warning count (#{result.warnings.size}) did not match expectation (#{warnings_count})") end

    # if 'Fail' passed in make sure at least one error message (while not typical there may be more than one message)
    if result_value == 'Fail' then assert(result.errors.size >= 1) end

    # save the model to test output directory
    output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + "/output/#{test_name}_test_output.osm")
    model.save(output_file_path, true)
  end

  def test_good_argument_values
    args = {}
    args['total_bldg_floor_area'] = 10000.0

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, 'example_model.osm')
  end

  def test_no_multiplier
    args = {}
    args['total_bldg_floor_area'] = 50000.0
    args['num_stories_above_grade'] = 5
    args['story_multiplier'] = 'None'

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, 'example_model.osm')
  end

  def test_smart_defaults
    args = {}
    args['total_bldg_floor_area'] = 10000.0
    args['ns_to_ew_ratio'] = 0.0
    args['floor_height'] = 0.0
    args['wwr'] = 0.0

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args)
  end

  def test_bad_fraction
    args = {}
    args['total_bldg_floor_area'] = 10000.0
    args['bldg_type_b_fract_bldg_area'] = 2.0

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, 'Fail')
  end

  def test_bad_positive
    args = {}
    args['total_bldg_floor_area'] = 10000.0
    args['bldg_type_a_num_units'] = -2

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, 'Fail')
  end

  def test_bad_non_neg
    args = {}
    args['total_bldg_floor_area'] = 10000.0
    args['floor_height'] = -1.0

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, 'Fail')
  end

  def test_bad_building_type_fractions
    args = {}
    args['total_bldg_floor_area'] = 10000.0
    args['bldg_type_b_fract_bldg_area'] = 0.4
    args['bldg_type_c_fract_bldg_area'] = 0.4
    args['bldg_type_d_fract_bldg_area'] = 0.4
    # using defaults values from measure.rb for other arguments

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, 'Fail')
  end

  def test_non_zero_rotation_primary_school
    args = {}
    args['total_bldg_floor_area'] = 100000.0
    args['num_stories_above_grade'] = 3
    args['bldg_type_a'] = 'PrimarySchool'
    args['building_rotation'] = -90.0
    args['party_wall_stories_east'] = 2

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args)
  end

  def test_large_hotel_restaurant
    args = {}
    args['total_bldg_floor_area'] = 100000.0
    args['num_stories_above_grade'] = 3
    args['bldg_type_a'] = 'LargeHotel'
    args['bldg_type_b'] = 'FullServiceRestaurant'
    args['bldg_type_b_fract_bldg_area'] = 0.1

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args)
  end

  def test_large_hotel_restaurant_multiplier
    args = {}
    args['total_bldg_floor_area'] = 100000.0
    args['num_stories_above_grade'] = 8
    args['bldg_type_a'] = 'LargeHotel'
    args['bldg_type_b'] = 'FullServiceRestaurant'
    args['bldg_type_b_fract_bldg_area'] = 0.1

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args)
  end

  def test_large_hotel_restaurant_multiplier_simple_slice
    args = {}
    args['total_bldg_floor_area'] = 100000.0
    args['num_stories_above_grade'] = 8
    args['bldg_type_a'] = 'LargeHotel'
    args['bldg_type_b'] = 'FullServiceRestaurant'
    args['bldg_type_b_fract_bldg_area'] = 0.1
    args['bar_division_method'] = 'Multiple Space Types - Simple Sliced'

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args)
  end

  def test_large_hotel_restaurant_multiplier_party_wall
    args = {}
    args['total_bldg_floor_area'] = 100000.0
    args['num_stories_above_grade'] = 8
    args['bldg_type_a'] = 'LargeHotel'
    args['bldg_type_b'] = 'FullServiceRestaurant'
    args['bldg_type_b_fract_bldg_area'] = 0.1
    args['party_wall_fraction'] = 0.25
    args['ns_to_ew_ratio'] = 2.15

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args)
  end

  def test_large_hotel_restaurant_multiplier_party_big
    args = {}
    args['total_bldg_floor_area'] = 100000.0
    args['num_stories_below_grade'] = 1
    args['num_stories_above_grade'] = 11
    args['bldg_type_a'] = 'LargeHotel'
    args['bldg_type_b'] = 'FullServiceRestaurant'
    args['bldg_type_b_fract_bldg_area'] = 0.1
    args['party_wall_fraction'] = 0.5
    args['ns_to_ew_ratio'] = 2.15

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args)
  end

  def test_two_and_half_stories
    args = {}
    args['total_bldg_floor_area'] = 50000.0
    args['bldg_type_a'] = 'SmallOffice'
    args['num_stories_above_grade'] = 5.5
    args['bar_division_method'] = 'Single Space Type - Core and Perimeter'

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args)
  end

  def test_two_and_half_stories_simple_sliced
    args = {}
    args['total_bldg_floor_area'] = 40000.0
    args['bldg_type_a'] = 'MidriseApartment'
    args['num_stories_above_grade'] = 5.5
    args['bar_division_method'] = 'Multiple Space Types - Simple Sliced'

    # 1 warning because to small for core and perimeter zoning
    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, 1)
  end

  def test_two_and_half_stories_individual_sliced
    args = {}
    args['total_bldg_floor_area'] = 40000.0
    args['bldg_type_a'] = 'LargeHotel'
    args['num_stories_above_grade'] = 5.5
    args['bar_division_method'] = 'Multiple Space Types - Individual Stories Sliced'

    # 1 warning because to small for core and perimeter zoning
    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, 1)
  end

  def test_party_wall_stories_test_a
    args = {}
    args['total_bldg_floor_area'] = 40000.0
    args['bldg_type_a'] = 'MediumOffice'
    args['num_stories_below_grade'] = 1
    args['num_stories_above_grade'] = 6
    args['bar_division_method'] = 'Single Space Type - Core and Perimeter'
    args['party_wall_stories_north'] = 4
    args['party_wall_stories_south'] = 6

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args)
  end

  # this test is failing intermittently due to unexpected warning
  # Office WholeBuilding - Md Office doesn't have the expected floor area (actual 41,419 ft^2, target 40,000 ft^2) 40,709, 40,000
  # footprint size is always fine, intersect is probably creating issue with extra surfaces on top of each other adding the extra area
  # haven't seen this on other partial story models
  #   Error:  Surface 138
  #   This planar surface shares the same SketchUp face as Surface 143.
  #       This error cannot be automatically fixed.  The surface will not be drawn.
  #
  #       Error:  Surface 91
  #   This planar surface shares the same SketchUp face as Surface 141.
  #       This error cannot be automatically fixed.  The surface will not be drawn.
  #
  #       Error:  Surface 125
  #   This planar surface shares the same SketchUp face as Surface 143.
  #       This error cannot be automatically fixed.  The surface will not be drawn.
  def test_mid_story_model
    skip "For some reason this specific test locks up testing framework but passes in raw ruby test."

    args = {}
    args['total_bldg_floor_area'] = 40000.0
    args['bldg_type_a'] = 'MediumOffice'
    args['num_stories_above_grade'] = 4.5
    args['bar_division_method'] = 'Single Space Type - Core and Perimeter'
    args['bottom_story_ground_exposed_floor'] = false
    args['top_story_exterior_exposed_roof'] = false

    puts "starting bad test"
    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args)
    puts "finishing bad test"
  end

  def test_mid_story_model_no_intersect
    args = {}
    args['total_bldg_floor_area'] = 40000.0
    args['bldg_type_a'] = 'MediumOffice'
    args['num_stories_above_grade'] = 4.5
    args['bar_division_method'] = 'Single Space Type - Core and Perimeter'
    args['bottom_story_ground_exposed_floor'] = false
    args['top_story_exterior_exposed_roof'] = false
    args['make_mid_story_surfaces_adiabatic'] = true

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args)
  end

  def test_same_bar_both_ends
    args = {}
    args['bldg_type_a'] = 'PrimarySchool'
    args['total_bldg_floor_area'] = 10000.0
    args['ns_to_ew_ratio'] = 1.5
    args['num_stories_above_grade'] = 2
    # args["bar_division_method"] = 'Multiple Space Types - Simple Sliced'

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args)
  end

  def test_rotation_45_party_wall_fraction
    args = {}
    args['total_bldg_floor_area'] = 100000.0
    args['num_stories_below_grade'] = 1
    args['num_stories_above_grade'] = 3.5
    args['bldg_type_a'] = 'SecondarySchool'
    args['building_rotation'] = 45.0
    args['party_wall_fraction'] = 0.65
    args['ns_to_ew_ratio'] = 3.0
    args['bar_division_method'] = 'Single Space Type - Core and Perimeter'

    # 11 warning messages because using single space type division method with multi-space type building type
    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, 11)
  end

  def test_fixed_single_floor_area
    args = {}
    args['total_bldg_floor_area'] = 100000.0
    args['single_floor_area'] = 2000.0
    args['ns_to_ew_ratio'] = 1.5
    args['num_stories_above_grade'] = 5.0

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, nil)
  end
end
