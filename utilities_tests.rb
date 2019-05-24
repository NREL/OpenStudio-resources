require 'openstudio' unless defined?(OpenStudio)

require 'json'
require 'fileutils'
require 'minitest/autorun'

begin
  require "minitest/reporters"
  require "minitest/reporters/default_reporter"
  reporter = Minitest::Reporters::DefaultReporter.new
  reporter.start # had to call start manually otherwise was failing when trying to report elapsed time when run in CLI
  Minitest::Reporters.use! reporter
rescue LoadError
  puts "Minitest Reporters not installed"
end

# TODO: a lot of that is a duplicate code. Once SDD PR is merged in, it won't
# be a problem anymore and we can delete all of this, but I'd rather have a
# separate test file right from the start
# cf https://github.com/NREL/OpenStudio-resources/pull/66
$Platform = "Unknown"

begin
  require 'os'

  if OS.mac?
    $Platform = "Darwin"
  elsif OS.linux?
    $Platform = "Linux"
  elsif OS.windows?
    $Platform = "Windows"
  else
    puts "Unknown Plaftorm?!"
  end
rescue Exception
  require 'rbconfig'

  host_os = RbConfig::CONFIG['host_os']
  case host_os
  when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
    $Platform = "Windows"
  when /darwin|mac os/
    $Platform = "Darwin"
  when /linux|solaris|bsd/
    $Platform = "Linux"
  else
    puts "Unknown Plaftorm?! #{host_os.inspect}"
  end
end


$RootDir = File.absolute_path(File.dirname(__FILE__))
$TestDir = File.join($RootDir, 'testruns')
$SdkVersion = OpenStudio.openStudioVersion
$SdkLongVersion = OpenStudio::openStudioLongVersion
$Build_Sha = $SdkLongVersion.split('.')[-1]


puts "Running for OpenStudio #{$SdkLongVersion}"

# Where to cp the out.osw for regression
# Depends on whether you are in a docker env or not
proc_file = '/proc/1/cgroup'
is_docker = File.file?(proc_file) && (File.readlines(proc_file).grep(/docker/).size > 0)
if is_docker
  # Mounted directory is at /root/test
  $OutOSWDir = File.join(ENV['HOME'], 'test')
else
  # Directly in here
  $OutOSWDir = File.join($RootDir, 'test')
end

# Variables to store the environment variables
$Custom_tag=''
if !ENV["CUSTOMTAG"].nil?
  $Custom_tag = ENV['CUSTOMTAG']
  # Debug
  # puts "Setting custom tag to #{$Custom_tag}"
end

if not $Custom_tag.empty?
  if $Custom_tag.downcase == 'sha'
    $Custom_tag = $Build_Sha
  end
  $Custom_tag = "_#{$Custom_tag}"
  puts "Custom tag will be appended, files will be named like 'testname_#{$SdkVersion}_#{$Platform}_out#{$Custom_tag}.osw'\n"
end

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
