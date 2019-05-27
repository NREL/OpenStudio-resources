require 'openstudio' unless defined?(OpenStudio)

# The config and helpers are inside this file
require_relative 'test_helpers.rb'

def name_result()
  test_name = caller[0][/`.*'/][1..-2].gsub('test_', '')
  file_name = "#{test_name}_#{$SdkVersion}_#{$Platform}_out#{$Custom_tag}.status"
  return File.join($OutOSWDir,
                   file_name)
end

# (Over)write a hash as a pretty json into a file
def output_json_status(test_result_file, result_h)
  File.open(test_result_file,"w") do |f|
    f.write(JSON.pretty_generate(result_h))
  end
end

# the tests
class UtilitiesTest < MiniTest::Unit::TestCase
  parallelize_me!

  # simulation tests

  def test_path_special_chars_str

    test_result_file = name_result

    # Assume it fails
    result_h = {
      'Status' => "Fail",
      'Plaftorm' => $Platform,
    }
    output_json_status(test_result_file, result_h)

    dir_str = "#{$TestDir}/AfolderwithspécialCHar#%ù".encode(Encoding::UTF_8)
    FileUtils.mkdir_p(dir_str)
    assert File.exists?(dir_str)

    p = OpenStudio::Path.new(dir_str)
    assert OpenStudio::exists(p)

    model_path = p / OpenStudio::toPath("model.osm")
    m = OpenStudio::Model::Model.new
    if OpenStudio::exists(model_path)
      FileUtils.rm(model_path.to_s)
    end
    m.save(model_path, true)
    assert File.exists?(File.join(dir_str, "model.osm"))
    assert File.exists?(model_path.to_s)

    translator = OpenStudio::OSVersion::VersionTranslator.new
    model = translator.loadModel(model_path)
    assert !model.empty?

    # If we got here, then all good
    result_h['Status'] = 'Success'
    output_json_status(test_result_file, result_h)

  end

  def test_path_special_chars_pwd

    original_dir = Dir.pwd

    test_result_file = name_result
    # Assume it fails
    result_h = {
      'Status' => "Fail",
      'Plaftorm' => $Platform,
    }
    output_json_status(test_result_file, result_h)

    dir_str = "#{$TestDir}/AfolderwithspécialCHar#%ù".encode(Encoding::UTF_8)
    FileUtils.mkdir_p(dir_str)
    assert File.exists?(dir_str), "dir_str doesn't exists... '#{dir_str}'"

    Dir.chdir(dir_str)
    dir_str = Dir.pwd
    result_h['Dir.pwd_Encoding'] = dir_str.encoding
    output_json_status(test_result_file, result_h)

    p = OpenStudio::Path.new(dir_str)
    assert OpenStudio::exists(p)

    model_path = p / OpenStudio::toPath("model.osm")
    m = OpenStudio::Model::Model.new
    if OpenStudio::exists(model_path)
      FileUtils.rm(model_path.to_s)
    end
    m.save(model_path, true)
    assert File.exists?(File.join(dir_str, "model.osm"))
    assert File.exists?(model_path.to_s)

    translator = OpenStudio::OSVersion::VersionTranslator.new
    model = translator.loadModel(model_path)
    assert !model.empty?

    # If we got here, then all good
    result_h['Status'] = 'Success'
    output_json_status(test_result_file, result_h)

  ensure
    Dir.chdir(original_dir)
  end


end