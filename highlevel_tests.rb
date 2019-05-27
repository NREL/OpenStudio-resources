require 'openstudio' unless defined?(OpenStudio)

# The config and helpers are inside this file
require_relative 'test_helpers.rb'

# Some High level tests, that should help us in maintaining the repo/test suite
# in an orderly fashion. These tests should ALWAYS pass, and other tests should
# probably not be run until these do.
class HighLevelTests < MiniTest::Test
  parallelize_me!

  puts "Running HighLevelTests"

  # Ensures that all OSM files are included in an actual model_test
  def test_osms_are_defined_sim_tests
    all_model_paths = Dir.glob(File.join($ModelDir, '*.osm'));
    all_model_filenames = all_model_paths.map{|p| File.basename(p)};

    content = File.read('model_tests.rb')
    sim_test_re = Regexp.new('def test_.*\n(?:\s*#)*\s+result = sim_test\(\'(?<filename>.*\.osm)\'\)\n(?:\s*#)*\s+end')
    osms_in_sim_test = content.scan(sim_test_re).map{|m| m.first}
    missing_osms = all_model_filenames - osms_in_sim_test

    # These are the OSMS we expect NOT to find in a sim_test
    expected_sim_missing = [ ]
    missing_osms = missing_osms - expected_sim_missing

    assert missing_osms.empty?, "Error in model_tests.rb: The following OSMs are not in any sim_tests:\n  * #{missing_osms.join("\n  * ")}"
  end

  # Ensures that all Ruby files are included in an actual model_test
  def test_rbs_are_defined_sim_tests
    all_ruby_paths = Dir.glob(File.join($ModelDir, '*.rb'));
    all_ruby_filenames = all_ruby_paths.map{|p| File.basename(p)};

    content = File.read('model_tests.rb')
    sim_test_re = Regexp.new('def test_.*\n(?:\s*#)*\s+result = sim_test\(\'(?<filename>.*\.rb)\'\)\n(?:\s*#)*\s+end')
    rbs_in_sim_test = content.scan(sim_test_re).map{|m| m.first}
    missing_rbs = all_ruby_filenames - rbs_in_sim_test

    # These are the ruby tests we expect NOT to find in a sim_test
    expected_sim_missing = [
      # This is autosizing_test
      'autosize_hvac.rb',
    ]

    missing_rbs = missing_rbs - expected_sim_missing

    assert missing_rbs.empty?, "Error in model_tests.rb: The following Ruby tests are not in any sim_tests:\n  * #{missing_rbs.join("\n  * ")}"
  end

  # Ensures that all Ruby tests have a matching OSM tests in model_tests,
  # unless explicitly expected
  def test_rbs_have_matching_osm_tests
    # List of tests that don't have a matching OSM test for a valid reason
    # No "Warn" will be issued for these
    # input the ruby file name, eg `xxxx.rb` NOT `test_xxx_rb`
    noMatchingOSMTests = ['ExampleModel.rb',
                          'autosize_hvac.rb',
                          # Not enabled
                          'afn_single_zone_ac.rb']

    base_dir = $ModelDir
    all_ruby_paths = Dir.glob(File.join(base_dir, '*.rb'));
    all_ruby_filenames = all_ruby_paths.map{|p| File.basename(p)};

    all_ruby_filenames.each do |filename|
      if !noMatchingOSMTests.include?(filename)
        # Check if there is a matching OSM file
        matching_osm = File.join(base_dir, filename.sub('.rb', '.osm'))

        # If you want to be stricter than warn, uncomment this
        # assert File.exists?(matching_osm), "There is no matching OSM test for #{filename}"

        if File.exists?(matching_osm)
          v = OpenStudio::IdfFile.loadVersionOnly(matching_osm)
          # Seems like something we should definitely fix anyways, so throwing
          if not v
            fail "Cannot find versionString in #{matching_osm}"
          end

          # If there is a version, check that it's not newer than current bindings
          model_version = v.get.str

          if Gem::Version.new(model_version) > Gem::Version.new($SdkVersion)
            # Skip instead of fail
            skip "Matching OSM Model version is newer than the SDK version used (#{model_version} versus #{$SdkVersion})"
          end
        else
          # If there isn't a matching, we warn, but we'll still run it
          # It might make sense if you have just added it recently
          warn "There is no matching OSM test for #{filename}"
        end
      end
    end
  end

  # Ensures that all OSM files are included in an actual
  # SDD ForwardTranslator test
  def test_osms_are_defined_sdd_ft_tests
    all_model_paths = Dir.glob(File.join($ModelDir, '*.osm'));
    all_model_filenames = all_model_paths.map{|p| File.basename(p)};

    content = File.read('SDD_tests.rb');

    sdd_ft_test_re = Regexp.new('def test_FT_.*\n(?:\s*#)*\s+sdd_ft_test\(\'(?<filename>.*\.osm)\'\)\n(?:\s*#)*\s+end')
    osms_in_sdd_test = content.scan(sdd_ft_test_re).map{|m| m.first}
    missing_osms = all_model_filenames - osms_in_sdd_test

    # These are the OSMS we expect NOT to find in a sdd_ft_test
    expected_sdd_missing = ["schedule_file.osm"]
    missing_osms = missing_osms - expected_sdd_missing

    assert missing_osms.empty?, "Error in SDD_tests.rb: The following OSMs are not in any sdd_ft_tests:\n  * #{missing_osms.join("\n  * ")}"
  end

  # Ensures that all SDD XML files are included in an actual
  # SDD ReverseTranslator test
  def test_simsddxmls_are_defined_sdd_rt_tests
    all_sddsimxml_paths = Dir.glob(File.join($SddSimDir, '*.xml'));
    all_sdd_simxml_filenames = all_sddsimxml_paths.map{|p| File.basename(p)};

    content = File.read('SDD_tests.rb');

    sdd_rt_test_re = Regexp.new('def test_RT_.*\n(?:\s*#)*\s+sdd_rt_test\(\'(?<filename>.*\.xml)\'\)\n(?:\s*#)*\s+end')
    xmls_in_sdd_test = content.scan(sdd_rt_test_re).map{|m| m.first}
    missing_xmls = all_sdd_simxml_filenames - xmls_in_sdd_test

    # These are the XMLs we expect NOT to find in a sdd_rt_test
    expected_sdd_missing = []
    missing_xmls = missing_xmls - expected_sdd_missing

    assert missing_xmls.empty?, "Error in SDD_tests.rb: The following XMLs are not in any sdd_rt_tests:\n  * #{missing_xmls.join("\n  * ")}"
  end

end


