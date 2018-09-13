# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class CreateBarFromBuildingTypeRatios < OpenStudio::Measure::ModelMeasure
  require 'openstudio-standards'

  # require all .rb files in resources folder
  Dir[File.dirname(__FILE__) + '/resources/*.rb'].each { |file| require file }

  # resource file modules
  include OsLib_HelperMethods
  include OsLib_Geometry
  include OsLib_ModelGeneration
  include OsLib_ModelSimplification

  # human readable name
  def name
    return 'Create Bar From Building Type Ratios'
  end

  # human readable description
  def description
    return 'Create a core and perimeter bar sliced by space type.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Space Type collections are made from one or more building types passed in with user arguments.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # Make an argument for the bldg_type_a
    bldg_type_a = OpenStudio::Measure::OSArgument.makeChoiceArgument('bldg_type_a', get_building_types, true)
    bldg_type_a.setDisplayName('Primary Building Type')
    bldg_type_a.setDefaultValue('SmallOffice')
    args << bldg_type_a

    # Make argument for bldg_type_a_num_units
    bldg_type_a_num_units = OpenStudio::Measure::OSArgument.makeIntegerArgument('bldg_type_a_num_units', true)
    bldg_type_a_num_units.setDisplayName('Primary Building Type Number of Units')
    bldg_type_a_num_units.setDefaultValue(1)
    args << bldg_type_a_num_units

    # Make an argument for the bldg_type_b
    bldg_type_b = OpenStudio::Measure::OSArgument.makeChoiceArgument('bldg_type_b', get_building_types, true)
    bldg_type_b.setDisplayName('Building Type B')
    bldg_type_b.setDefaultValue('SmallOffice')
    args << bldg_type_b

    # Make argument for bldg_type_b_fract_bldg_area
    bldg_type_b_fract_bldg_area = OpenStudio::Measure::OSArgument.makeDoubleArgument('bldg_type_b_fract_bldg_area', true)
    bldg_type_b_fract_bldg_area.setDisplayName('Building Type B Fraction of Building Floor Area')
    bldg_type_b_fract_bldg_area.setDefaultValue(0.0)
    args << bldg_type_b_fract_bldg_area

    # Make argument for bldg_type_b_num_units
    bldg_type_b_num_units = OpenStudio::Measure::OSArgument.makeIntegerArgument('bldg_type_b_num_units', true)
    bldg_type_b_num_units.setDisplayName('Building Type B Number of Units')
    bldg_type_b_num_units.setDefaultValue(1)
    args << bldg_type_b_num_units

    # Make an argument for the bldg_type_c
    bldg_type_c = OpenStudio::Measure::OSArgument.makeChoiceArgument('bldg_type_c', get_building_types, true)
    bldg_type_c.setDisplayName('Building Type C')
    bldg_type_c.setDefaultValue('SmallOffice')
    args << bldg_type_c

    # Make argument for bldg_type_c_fract_bldg_area
    bldg_type_c_fract_bldg_area = OpenStudio::Measure::OSArgument.makeDoubleArgument('bldg_type_c_fract_bldg_area', true)
    bldg_type_c_fract_bldg_area.setDisplayName('Building Type C Fraction of Building Floor Area')
    bldg_type_c_fract_bldg_area.setDefaultValue(0.0)
    args << bldg_type_c_fract_bldg_area

    # Make argument for bldg_type_c_num_units
    bldg_type_c_num_units = OpenStudio::Measure::OSArgument.makeIntegerArgument('bldg_type_c_num_units', true)
    bldg_type_c_num_units.setDisplayName('Building Type C Number of Units')
    bldg_type_c_num_units.setDefaultValue(1)
    args << bldg_type_c_num_units

    # Make an argument for the bldg_type_d
    bldg_type_d = OpenStudio::Measure::OSArgument.makeChoiceArgument('bldg_type_d', get_building_types, true)
    bldg_type_d.setDisplayName('Building Type D')
    bldg_type_d.setDefaultValue('SmallOffice')
    args << bldg_type_d

    # Make argument for bldg_type_d_fract_bldg_area
    bldg_type_d_fract_bldg_area = OpenStudio::Measure::OSArgument.makeDoubleArgument('bldg_type_d_fract_bldg_area', true)
    bldg_type_d_fract_bldg_area.setDisplayName('Building Type D Fraction of Building Floor Area')
    bldg_type_d_fract_bldg_area.setDefaultValue(0.0)
    args << bldg_type_d_fract_bldg_area

    # Make argument for bldg_type_d_num_units
    bldg_type_d_num_units = OpenStudio::Measure::OSArgument.makeIntegerArgument('bldg_type_d_num_units', true)
    bldg_type_d_num_units.setDisplayName('Building Type D Number of Units')
    bldg_type_d_num_units.setDefaultValue(1)
    args << bldg_type_d_num_units

    # Make argument for single_floor_area
    single_floor_area = OpenStudio::Measure::OSArgument.makeDoubleArgument('single_floor_area', true)
    single_floor_area.setDisplayName('Single Floor Area')
    single_floor_area.setDescription('Non-zero value will fix the single floor area, overriding a user entry for Total Building Floor Area')
    single_floor_area.setUnits('ft^2')
    single_floor_area.setDefaultValue(0.0)

    args << single_floor_area

    # Make argument for total_bldg_floor_area
    total_bldg_floor_area = OpenStudio::Measure::OSArgument.makeDoubleArgument('total_bldg_floor_area', true)
    total_bldg_floor_area.setDisplayName('Total Building Floor Area')
    total_bldg_floor_area.setUnits('ft^2')
    total_bldg_floor_area.setDefaultValue(10000.0)

    args << total_bldg_floor_area

    # Make argument for floor_height
    floor_height = OpenStudio::Measure::OSArgument.makeDoubleArgument('floor_height', true)
    floor_height.setDisplayName('Typical Floor to FLoor Height')
    floor_height.setDescription('Selecting a typical floor height of 0 will trigger a smart building type default.')
    floor_height.setUnits('ft')
    floor_height.setDefaultValue(0.0)
    args << floor_height

    # Make argument for num_stories_above_grade
    num_stories_above_grade = OpenStudio::Measure::OSArgument.makeDoubleArgument('num_stories_above_grade', true)
    num_stories_above_grade.setDisplayName('Number of Stories Above Grade')
    num_stories_above_grade.setDefaultValue(1.0)
    args << num_stories_above_grade

    # Make argument for num_stories_below_grade
    num_stories_below_grade = OpenStudio::Measure::OSArgument.makeIntegerArgument('num_stories_below_grade', true)
    num_stories_below_grade.setDisplayName('Number of Stories Below Grade')
    num_stories_below_grade.setDefaultValue(0)
    args << num_stories_below_grade

    # Make argument for building_rotation
    building_rotation = OpenStudio::Measure::OSArgument.makeDoubleArgument('building_rotation', true)
    building_rotation.setDisplayName('Building Rotation')
    building_rotation.setDescription('Set Building Rotation off of North (positive value is clockwise).')
    building_rotation.setUnits('Degrees')
    building_rotation.setDefaultValue(0.0)
    args << building_rotation

    # Make argument for template
    template = OpenStudio::Measure::OSArgument.makeChoiceArgument('template', get_templates, true)
    template.setDisplayName('Target Standard')
    template.setDefaultValue('90.1-2004')
    args << template

    # Make argument for ns_to_ew_ratio
    ns_to_ew_ratio = OpenStudio::Measure::OSArgument.makeDoubleArgument('ns_to_ew_ratio', true)
    ns_to_ew_ratio.setDisplayName('Ratio of North/South Facade Length Relative to East/West Facade Length.')
    ns_to_ew_ratio.setDescription('Selecting an aspect ratio of 0 will trigger a smart building type default. Aspect ratios less than one are not recommended for sliced bar geometry, instead rotate building and use a greater than 1 aspect ratio')
    ns_to_ew_ratio.setDefaultValue(0.0)
    args << ns_to_ew_ratio

    # Make argument for wwr (in future add lookup for smart default)
    wwr = OpenStudio::Measure::OSArgument.makeDoubleArgument('wwr', true)
    wwr.setDisplayName('Window to Wall Ratio.')
    wwr.setDescription('Selecting a window to wall ratio of 0 will trigger a smart building type default.')
    wwr.setDefaultValue(0.0)
    args << wwr

    # Make argument for party_wall_fraction
    party_wall_fraction = OpenStudio::Measure::OSArgument.makeDoubleArgument('party_wall_fraction', true)
    party_wall_fraction.setDisplayName('Fraction of Exterior Wall Area with Adjacent Structure')
    party_wall_fraction.setDescription('This will impact how many above grade exterior walls are modeled with adiabatic boundary condition.')
    party_wall_fraction.setDefaultValue(0.0)
    args << party_wall_fraction

    # party_wall_fraction was used where we wanted to represent some party walls but didn't know where they are, it ends up using methods to make whole surfaces adiabiatc by story and orientaiton to try to come close to requested fraction

    # Make argument for party_wall_stories_north
    party_wall_stories_north = OpenStudio::Measure::OSArgument.makeIntegerArgument('party_wall_stories_north', true)
    party_wall_stories_north.setDisplayName('Number of North facing stories with party wall')
    party_wall_stories_north.setDescription('This will impact how many above grade exterior north walls are modeled with adiabatic boundary condition. If this is less than the number of above grade stoes, upper flor will reamin exterior')
    party_wall_stories_north.setDefaultValue(0)
    args << party_wall_stories_north

    # Make argument for party_wall_stories_south
    party_wall_stories_south = OpenStudio::Measure::OSArgument.makeIntegerArgument('party_wall_stories_south', true)
    party_wall_stories_south.setDisplayName('Number of South facing stories with party wall')
    party_wall_stories_south.setDescription('This will impact how many above grade exterior south walls are modeled with adiabatic boundary condition. If this is less than the number of above grade stoes, upper flor will reamin exterior')
    party_wall_stories_south.setDefaultValue(0)
    args << party_wall_stories_south

    # Make argument for party_wall_stories_east
    party_wall_stories_east = OpenStudio::Measure::OSArgument.makeIntegerArgument('party_wall_stories_east', true)
    party_wall_stories_east.setDisplayName('Number of East facing stories with party wall')
    party_wall_stories_east.setDescription('This will impact how many above grade exterior east walls are modeled with adiabatic boundary condition. If this is less than the number of above grade stoes, upper flor will reamin exterior')
    party_wall_stories_east.setDefaultValue(0)
    args << party_wall_stories_east

    # Make argument for party_wall_stories_west
    party_wall_stories_west = OpenStudio::Measure::OSArgument.makeIntegerArgument('party_wall_stories_west', true)
    party_wall_stories_west.setDisplayName('Number of West facing stories with party wall')
    party_wall_stories_west.setDescription('This will impact how many above grade exterior west walls are modeled with adiabatic boundary condition. If this is less than the number of above grade stoes, upper flor will reamin exterior')
    party_wall_stories_west.setDefaultValue(0)
    args << party_wall_stories_west

    # make an argument for bottom_story_ground_exposed_floor
    bottom_story_ground_exposed_floor = OpenStudio::Measure::OSArgument.makeBoolArgument('bottom_story_ground_exposed_floor', true)
    bottom_story_ground_exposed_floor.setDisplayName('Is the Bottom Story Exposed to Ground?')
    bottom_story_ground_exposed_floor.setDescription("This should be true unless you are modeling a partial building which doesn't include the lowest story. The bottom story floor will have an adiabatic boundary condition when false.")
    bottom_story_ground_exposed_floor.setDefaultValue(true)
    args << bottom_story_ground_exposed_floor

    # make an argument for top_story_exterior_exposed_roof
    top_story_exterior_exposed_roof = OpenStudio::Measure::OSArgument.makeBoolArgument('top_story_exterior_exposed_roof', true)
    top_story_exterior_exposed_roof.setDisplayName('Is the Top Story an Exterior Roof?')
    top_story_exterior_exposed_roof.setDescription("This should be true unless you are modeling a partial building which doesn't include the highest story. The top story ceiling will have an adiabatic boundary condition when false.")
    top_story_exterior_exposed_roof.setDefaultValue(true)
    args << top_story_exterior_exposed_roof

    # Make argument for story_multiplier
    choices = OpenStudio::StringVector.new
    choices << 'None'
    choices << 'Basements Ground Mid Top'
    # choices << "Basements Ground Midx5 Top"
    story_multiplier = OpenStudio::Measure::OSArgument.makeChoiceArgument('story_multiplier', choices, true)
    story_multiplier.setDisplayName('Calculation Method for Story Multiplier')
    story_multiplier.setDefaultValue('Basements Ground Mid Top')
    args << story_multiplier

    # make an argument for bar sub-division approach
    choices = OpenStudio::StringVector.new
    choices << 'Multiple Space Types - Simple Sliced'
    choices << 'Multiple Space Types - Individual Stories Sliced'
    choices << 'Single Space Type - Core and Perimeter'
    # choices << "Multiple Space Types - Individual Stories Sliced Keep Building Types Together"
    # choices << "Building Type Specific Smart Division"
    bar_division_method = OpenStudio::Measure::OSArgument.makeChoiceArgument('bar_division_method', choices, true)
    bar_division_method.setDisplayName('Division Method for Bar Space Types.')
    bar_division_method.setDefaultValue('Multiple Space Types - Individual Stories Sliced')
    args << bar_division_method

    # make an argument for make_mid_story_surfaces_adiabatic (added to avoid issues with intersect and to lower surface count when using individual stories sliced)
    make_mid_story_surfaces_adiabatic = OpenStudio::Measure::OSArgument.makeBoolArgument('make_mid_story_surfaces_adiabatic', true)
    make_mid_story_surfaces_adiabatic.setDisplayName('Make Mid Story Floor Surfaces Adibatic')
    make_mid_story_surfaces_adiabatic.setDescription('If set to true, this will skip surface intersection and make mid story floors and celings adiabiatc, not just at multiplied gaps.')
    make_mid_story_surfaces_adiabatic.setDefaultValue(false)
    args << make_mid_story_surfaces_adiabatic

    # make an argument for use_upstream_args
    use_upstream_args = OpenStudio::Measure::OSArgument.makeBoolArgument('use_upstream_args', true)
    use_upstream_args.setDisplayName('Use Upstream Argument Values')
    use_upstream_args.setDescription('When true this will look for arguments or registerValues in upstream measures that match arguments from this measure, and will use the value from the upstream measure in place of what is entered for this measure.')
    use_upstream_args.setDefaultValue(true)
    args << use_upstream_args

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # assign the user inputs to variables
    args = OsLib_HelperMethods.createRunVariables(runner, model, user_arguments, arguments(model))
    if !args then return false end

    # lookup and replace argument values from upstream measures
    if args['use_upstream_args'] == true
      args.each do |arg,value|
        next if arg == 'use_upstream_args' # this argument should not be changed
        value_from_osw = OsLib_HelperMethods.check_upstream_measure_for_arg(runner, arg)
        if !value_from_osw.empty?
          runner.registerInfo("Replacing argument named #{arg} from current measure with a value of #{value_from_osw[:value]} from #{value_from_osw[:measure_name]}.")
          new_val = value_from_osw[:value]
          # todo - make code to handle non strings more robust. check_upstream_measure_for_arg coudl pass bakc the argument type
          if arg == 'total_bldg_floor_area'
            args[arg] = new_val.to_f
          elsif arg == 'num_stories_above_grade'
            args[arg] = new_val.to_f
          elsif arg == 'zipcode'
            args[arg] = new_val.to_i
          else
            args[arg] = new_val
          end
        end
      end
    end

    # check expected values of double arguments
    fraction_args = ['bldg_type_b_fract_bldg_area',
                     'bldg_type_c_fract_bldg_area',
                     'bldg_type_d_fract_bldg_area',
                     'wwr', 'party_wall_fraction']
    fraction = OsLib_HelperMethods.checkDoubleAndIntegerArguments(runner, user_arguments, 'min' => 0.0, 'max' => 1.0, 'min_eq_bool' => true, 'max_eq_bool' => true, 'arg_array' => fraction_args)

    positive_args = ['total_bldg_floor_area']
    positive = OsLib_HelperMethods.checkDoubleAndIntegerArguments(runner, user_arguments, 'min' => 0.0, 'max' => nil, 'min_eq_bool' => false, 'max_eq_bool' => false, 'arg_array' => positive_args)

    one_or_greater_args = ['num_stories_above_grade']
    one_or_greater = OsLib_HelperMethods.checkDoubleAndIntegerArguments(runner, user_arguments, 'min' => 1.0, 'max' => nil, 'min_eq_bool' => true, 'max_eq_bool' => false, 'arg_array' => one_or_greater_args)

    non_neg_args = ['bldg_type_a_num_units',
                    'bldg_type_c_num_units',
                    'bldg_type_d_num_units',
                    'num_stories_below_grade',
                    'floor_height',
                    'ns_to_ew_ratio',
                    'party_wall_stories_north',
                    'party_wall_stories_south',
                    'party_wall_stories_east',
                    'party_wall_stories_west',
                    'single_floor_area']
    non_neg = OsLib_HelperMethods.checkDoubleAndIntegerArguments(runner, user_arguments, 'min' => 0.0, 'max' => nil, 'min_eq_bool' => true, 'max_eq_bool' => false, 'arg_array' => non_neg_args)

    # return false if any errors fail
    if !fraction then return false end
    if !positive then return false end
    if !one_or_greater then return false end
    if !non_neg then return false end

    # if aspect ratio, story height or wwr have argument value of 0 then use smart building type defaults
    building_form_defaults = building_form_defaults(args['bldg_type_a'])
    if args['ns_to_ew_ratio'] == 0.0
      args['ns_to_ew_ratio'] = building_form_defaults[:aspect_ratio]
      runner.registerInfo("0.0 value for aspect ratio will be replaced with smart default for #{args['bldg_type_a']} of #{building_form_defaults[:aspect_ratio]}.")
    end
    if args['floor_height'] == 0.0
      args['floor_height'] = building_form_defaults[:typical_story]
      runner.registerInfo("0.0 value for floor height will be replaced with smart default for #{args['bldg_type_a']} of #{building_form_defaults[:typical_story]}.")
    end
    # because of this can't set wwr to 0.0. If that is desired then we can change this to check for 1.0 instead of 0.0
    if args['wwr'] == 0.0
      args['wwr'] = building_form_defaults[:wwr]
      runner.registerInfo("0.0 value for window to wall ratio will be replaced with smart default for #{args['bldg_type_a']} of #{building_form_defaults[:wwr]}.")
    end

    # check that sum of fractions for b,c, and d is less than 1.0 (so something is left for primary building type)
    bldg_type_a_fract_bldg_area = 1.0 - args['bldg_type_b_fract_bldg_area'] - args['bldg_type_c_fract_bldg_area'] - args['bldg_type_d_fract_bldg_area']
    if bldg_type_a_fract_bldg_area <= 0.0
      runner.registerError('Primary Building Type fraction of floor area must be greater than 0. Please lower one or more of the fractions for Building Type B-D.')
      return false
    end

    # Make the standard applier
    standard = Standard.build("#{args['template']}_#{args['bldg_type_a']}")

    # report initial condition of model
    runner.registerInitialCondition("The building started with #{model.getSpaces.size} spaces.")

    # set building rotation
    initial_rotation = model.getBuilding.northAxis
    if args['building_rotation'] != initial_rotation
      model.getBuilding.setNorthAxis(args['building_rotation'])
      runner.registerInfo("Set Building Rotation to #{model.getBuilding.northAxis}")
    end

    # hash to old building type data
    building_type_hash = {}

    # gather data for bldg_type_a
    building_type_hash[args['bldg_type_a']] = {}
    building_type_hash[args['bldg_type_a']][:frac_bldg_area] = bldg_type_a_fract_bldg_area
    building_type_hash[args['bldg_type_a']][:num_units] = args['bldg_type_a_num_units']
    building_type_hash[args['bldg_type_a']][:space_types] = get_space_types_from_building_type(args['bldg_type_a'], args['template'], true)

    # gather data for bldg_type_b
    if args['bldg_type_b_fract_bldg_area'] > 0
      building_type_hash[args['bldg_type_b']] = {}
      building_type_hash[args['bldg_type_b']][:frac_bldg_area] = args['bldg_type_b_fract_bldg_area']
      building_type_hash[args['bldg_type_b']][:num_units] = args['bldg_type_b_num_units']
      building_type_hash[args['bldg_type_b']][:space_types] = get_space_types_from_building_type(args['bldg_type_b'], args['template'], true)
    end

    # gather data for bldg_type_c
    if args['bldg_type_c_fract_bldg_area'] > 0
      building_type_hash[args['bldg_type_c']] = {}
      building_type_hash[args['bldg_type_c']][:frac_bldg_area] = args['bldg_type_c_fract_bldg_area']
      building_type_hash[args['bldg_type_c']][:num_units] = args['bldg_type_c_num_units']
      building_type_hash[args['bldg_type_c']][:space_types] = get_space_types_from_building_type(args['bldg_type_c'], args['template'], true)
    end

    # gather data for bldg_type_d
    if args['bldg_type_d_fract_bldg_area'] > 0
      building_type_hash[args['bldg_type_d']] = {}
      building_type_hash[args['bldg_type_d']][:frac_bldg_area] = args['bldg_type_d_fract_bldg_area']
      building_type_hash[args['bldg_type_d']][:num_units] = args['bldg_type_d_num_units']
      building_type_hash[args['bldg_type_d']][:space_types] = get_space_types_from_building_type(args['bldg_type_d'], args['template'], true)
    end

    # creating space types for requested building types
    building_type_hash.each do |building_type, building_type_hash|
      runner.registerInfo("Creating Space Types for #{building_type}.")

      # mapping building_type name is needed for a few methods
      building_type = standard.model_get_lookup_name(building_type)

      # create space_type_map from array
      sum_of_ratios = 0.0
      building_type_hash[:space_types].each do |space_type_name, hash|
        next if hash[:space_type_gen] == false # space types like undeveloped and basement are skipped.

        # create space type
        space_type = OpenStudio::Model::SpaceType.new(model)
        space_type.setStandardsBuildingType(building_type)
        space_type.setStandardsSpaceType(space_type_name)
        space_type.setName("#{building_type} #{space_type_name}")

        # set color
        test = standard.space_type_apply_rendering_color(space_type) # this uses openstudio-standards
        if !test
          runner.registerWarning("Could not find color for #{args['template']} #{space_type.name}")
        end

        # extend hash to hold new space type object
        hash[:space_type] = space_type

        # add to sum_of_ratios counter for adjustment multiplier
        sum_of_ratios += hash[:ratio]
      end

      # store multiplier needed to adjsut sum of ratios to equl 1.0
      building_type_hash[:ratio_adjustment_multiplier] = 1.0 / sum_of_ratios
    end

    # calculate length and with of bar
    # todo - update slicing to nicely handle aspect ratio less than 1

    total_bldg_floor_area_si = OpenStudio.convert(args['total_bldg_floor_area'], 'ft^2', 'm^2').get
    single_floor_area_si = OpenStudio.convert(args['single_floor_area'], 'ft^2', 'm^2').get

    num_stories = args['num_stories_below_grade'] + args['num_stories_above_grade']

    # handle user-assigned single floor plate size condition
    if args['single_floor_area'] > 0.0
      footprint_si = single_floor_area_si
      total_bldg_floor_area_si = single_floor_area_si * num_stories.to_f
      runner.registerWarning('User-defined single floor area was used for calculation of total building floor area')
    else
      footprint_si = total_bldg_floor_area_si / num_stories.to_f
    end
    floor_height_si = OpenStudio.convert(args['floor_height'], 'ft', 'm').get
    width = Math.sqrt(footprint_si / args['ns_to_ew_ratio'])
    length = footprint_si / width

    # populate space_types_hash
    space_types_hash = {}
    building_type_hash.each do |building_type, building_type_hash|
      building_type_hash[:space_types].each do |space_type_name, hash|
        next if hash[:space_type_gen] == false

        space_type = hash[:space_type]
        ratio_of_bldg_total = hash[:ratio] * building_type_hash[:ratio_adjustment_multiplier] * building_type_hash[:frac_bldg_area]
        final_floor_area = ratio_of_bldg_total * total_bldg_floor_area_si # I think I can just pass ratio but passing in area is cleaner
        space_types_hash[space_type] = { floor_area: final_floor_area }
      end
    end

    # create envelope
    # populate bar_hash and create envelope with data from envelope_data_hash and user arguments
    bar_hash = {}
    bar_hash[:length] = length
    bar_hash[:width] = width
    bar_hash[:num_stories_below_grade] = args['num_stories_below_grade']
    bar_hash[:num_stories_above_grade] = args['num_stories_above_grade']
    bar_hash[:floor_height] = floor_height_si
    # bar_hash[:center_of_footprint] = OpenStudio::Point3d.new(length* 0.5,width * 0.5,0.0)
    bar_hash[:center_of_footprint] = OpenStudio::Point3d.new(0, 0, 0)
    bar_hash[:bar_division_method] = args['bar_division_method']
    bar_hash[:make_mid_story_surfaces_adiabatic] = args['make_mid_story_surfaces_adiabatic']
    bar_hash[:space_types] = space_types_hash
    bar_hash[:building_wwr_n] = args['wwr']
    bar_hash[:building_wwr_s] = args['wwr']
    bar_hash[:building_wwr_e] = args['wwr']
    bar_hash[:building_wwr_w] = args['wwr']

    # round up non integer stoires to next integer
    num_stories_round_up = num_stories.ceil

    # party_walls_array to be used by orientation specific or fractional party wall values
    party_walls_array = [] # this is an array of arrays, where each entry is effective building story with array of directions

    if args['party_wall_stories_north'] + args['party_wall_stories_south'] + args['party_wall_stories_east'] + args['party_wall_stories_west'] > 0

      # loop through effective number of stories add orientation specific party walls per user arguments
      num_stories_round_up.times do |i|
        test_value = i + 1 - bar_hash[:num_stories_below_grade]

        array = []
        if args['party_wall_stories_north'] >= test_value
          array << 'north'
        end
        if args['party_wall_stories_south'] >= test_value
          array << 'south'
        end
        if args['party_wall_stories_east'] >= test_value
          array << 'east'
        end
        if args['party_wall_stories_west'] >= test_value
          array << 'west'
        end

        # populate party_wall_array for this story
        party_walls_array << array
      end
    end

    # calculate party walls if using party_wall_fraction method
    if args['party_wall_fraction'] > 0 && !party_walls_array.empty?
      runner.registerWarning('Both orientaiton and fractional party wall values arguments were populated, will ignore fractional party wall input')
    elsif args['party_wall_fraction'] > 0

      # orientation of long and short side of building will vary based on building rotation

      # full story ext wall area
      typical_length_facade_area = length * floor_height_si
      typical_width_facade_area = width * floor_height_si

      # top story ext wall area, may be partial story
      partial_story_multiplier = (1.0 - args['num_stories_above_grade'].ceil + args['num_stories_above_grade'])
      area_multiplier = partial_story_multiplier
      edge_multiplier = Math.sqrt(area_multiplier)
      top_story_length = length * edge_multiplier
      top_story_width = width * edge_multiplier
      top_story_length_facade_area = top_story_length * floor_height_si
      top_story_width_facade_area = top_story_width * floor_height_si

      total_exterior_wall_area = 2 * (length + width) * (args['num_stories_above_grade'].ceil - 1.0) * floor_height_si + 2 * (top_story_length + top_story_width) * floor_height_si
      target_party_wall_area = total_exterior_wall_area * args['party_wall_fraction']

      width_counter = 0
      width_area = 0.0
      facade_area = typical_width_facade_area
      until (width_area + facade_area >= target_party_wall_area) || (width_counter == args['num_stories_above_grade'].ceil * 2)
        # update facade area for top story
        if width_counter == args['num_stories_above_grade'].ceil - 1 || width_counter == args['num_stories_above_grade'].ceil * 2 - 1
          facade_area = top_story_width_facade_area
        else
          facade_area = typical_width_facade_area
        end

        width_counter += 1
        width_area += facade_area

      end
      width_area_remainder = target_party_wall_area - width_area

      length_counter = 0
      length_area = 0.0
      facade_area = typical_length_facade_area
      until (length_area + facade_area >= target_party_wall_area) || (length_counter == args['num_stories_above_grade'].ceil * 2)
        # update facade area for top story
        if length_counter == args['num_stories_above_grade'].ceil - 1 || length_counter == args['num_stories_above_grade'].ceil * 2 - 1
          facade_area = top_story_length_facade_area
        else
          facade_area = typical_length_facade_area
        end

        length_counter += 1
        length_area += facade_area
      end
      length_area_remainder = target_party_wall_area - length_area

      # get rotation and best fit to adjust orientation for fraction party wall
      rotation = args['building_rotation'] % 360.0 # should result in value between 0 and 360
      card_dir_array = [0.0, 90.0, 180.0, 270.0, 360.0]
      # reverse array to properly handle 45, 135, 225, and 315
      best_fit = card_dir_array.reverse.min_by { |x| (x.to_f - rotation).abs }

      if ![90.0, 270.0].include? best_fit
        width_card_dir = ['east', 'west']
        length_card_dir = ['north', 'south']
      else # if rotation is closest to 90 or 270 then reverse which orientation is used for length and width
        width_card_dir = ['north', 'south']
        length_card_dir = ['east', 'west']
      end

      # if dont' find enough on short sides
      if width_area_remainder <= typical_length_facade_area

        num_stories_round_up.times do |i|
          if i + 1 <= args['num_stories_below_grade']
            party_walls_array << []
            next
          end
          if i + 1 - args['num_stories_below_grade'] <= width_counter
            if i + 1 - args['num_stories_below_grade'] <= width_counter - args['num_stories_above_grade']
              party_walls_array << width_card_dir
            else
              party_walls_array << [width_card_dir.first]
            end
          else
            party_walls_array << []
          end
        end

      else # use long sides instead

        num_stories_round_up.times do |i|
          if i + 1 <= args['num_stories_below_grade']
            party_walls_array << []
            next
          end
          if i + 1 - args['num_stories_below_grade'] <= length_counter
            if i + 1 - args['num_stories_below_grade'] <= length_counter - args['num_stories_above_grade']
              party_walls_array << length_card_dir
            else
              party_walls_array << [length_card_dir.first]
            end
          else
            party_walls_array << []
          end
        end

      end

      # TODO: - currently won't go past making two opposing sets of walls party walls. Info and registerValue are after create_bar in measure.rb

    end

    # populate bar hash with story information
    bar_hash[:stories] = {}
    num_stories_round_up.times do |i|
      if party_walls_array.empty?
        party_walls = []
      else
        party_walls = party_walls_array[i]
      end

      # add below_partial_story
      if num_stories.ceil > num_stories && i == num_stories_round_up - 2
        below_partial_story = true
      else
        below_partial_story = false
      end

      # bottom_story_ground_exposed_floor and top_story_exterior_exposed_roof already setup as bool

      bar_hash[:stories]["key #{i}"] = { story_party_walls: party_walls, story_min_multiplier: 1, story_included_in_building_area: true, below_partial_story: below_partial_story, bottom_story_ground_exposed_floor: args['bottom_story_ground_exposed_floor'], top_story_exterior_exposed_roof: args['top_story_exterior_exposed_roof'] }
    end

    # remove non-resource objects not removed by removing the building
    remove_non_resource_objects(runner, model)

    # rename building to infer template in downstream measure
    name_array = [args['template'], args['bldg_type_a']]
    if args['bldg_type_b_fract_bldg_area'] > 0 then name_array << args['bldg_type_b'] end
    if args['bldg_type_c_fract_bldg_area'] > 0 then name_array << args['bldg_type_c'] end
    if args['bldg_type_d_fract_bldg_area'] > 0 then name_array << args['bldg_type_d'] end
    model.getBuilding.setName(name_array.join('|').to_s)

    # store expected floor areas to check after bar made
    target_areas = {}
    bar_hash[:space_types].each do |k, v|
      target_areas[k] = v[:floor_area]
    end

    # create bar
    create_bar(runner, model, bar_hash, args['story_multiplier'])

    # check expected floor areas against actual
    model.getSpaceTypes.sort.each do |space_type|
      next if !target_areas.key? space_type

      # convert to IP
      actual_ip = OpenStudio.convert(space_type.floorArea, 'm^2', 'ft^2').get
      target_ip = OpenStudio.convert(target_areas[space_type], 'm^2', 'ft^2').get

      if (space_type.floorArea - target_areas[space_type]).abs >= 1.0

        if !args['bar_division_method'].include? 'Single Space Type'
          runner.registerError("#{space_type.name} doesn't have the expected floor area (actual #{OpenStudio.toNeatString(actual_ip, 0, true)} ft^2, target #{OpenStudio.toNeatString(target_ip, 0, true)} ft^2)")
          return false
        else
          # will see this if use Single Space type division method on multi-use building or single building type without whole building space type
          runner.registerWarning("#{space_type.name} doesn't have the expected floor area (actual #{OpenStudio.toNeatString(actual_ip, 0, true)} ft^2, target #{OpenStudio.toNeatString(target_ip, 0, true)} ft^2)")
        end

      end
    end

    # check party wall fraction by looping through surfaces.
    actual_ext_wall_area = model.getBuilding.exteriorWallArea
    actual_party_wall_area = 0.0
    model.getSurfaces.each do |surface|
      next if surface.outsideBoundaryCondition != 'Adiabatic'
      next if surface.surfaceType != 'Wall'
      actual_party_wall_area += surface.grossArea * surface.space.get.multiplier
    end
    actual_party_wall_fraction = actual_party_wall_area / (actual_party_wall_area + actual_ext_wall_area)
    runner.registerInfo("Target party wall fraction is #{args['party_wall_fraction']}. Realized fraction is #{actual_party_wall_fraction.round(2)}")
    runner.registerValue('party_wall_fraction_actual', actual_party_wall_fraction)

    # test for excessive exterior roof area (indication of problem with intersection and or surface matching)
    ext_roof_area = model.getBuilding.exteriorSurfaceArea - model.getBuilding.exteriorWallArea
    expected_roof_area = args['total_bldg_floor_area'] / (args['num_stories_above_grade'] + args['num_stories_below_grade']).to_f
    if ext_roof_area > expected_roof_area && single_floor_area_si == 0.0 # only test if using whole-building area input
      runner.registerError('Roof area larger than expected, may indicate problem with inter-floor surface intersection or matching.')
      return false
    end

    # report final condition of model
    runner.registerFinalCondition("The building finished with #{model.getSpaces.size} spaces.")

    return true
  end
end

# register the measure to be used by the application
CreateBarFromBuildingTypeRatios.new.registerWithApplication
