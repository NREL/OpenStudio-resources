require 'openstudio'

require 'minitest/autorun'

require 'equivalent-xml'

begin
  require "minitest/reporters"
  require "minitest/reporters/default_reporter"
  reporter = Minitest::Reporters::DefaultReporter.new
  reporter.start # had to call start manually otherwise was failing when trying to report elapsed time when run in CLI
  Minitest::Reporters.use! reporter
rescue LoadError
  puts "Minitest Reporters not installed"
end

# config stuff
$OpenstudioCli = OpenStudio::getOpenStudioCLI
$RootDir = File.absolute_path(File.dirname(__FILE__))
$ModelDir = File.join($RootDir, 'model/simulationtests/')
$TestDir = File.join($RootDir, 'testruns/sdd/')
$SdkVersion = OpenStudio.openStudioVersion
$SdkLongVersion = OpenStudio::openStudioLongVersion
$Build_Sha = $SdkLongVersion.split('.')[-1]

puts "Running for OpenStudio #{$SdkLongVersion}"

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
  puts "Custom tag will be appended, files will be named like 'testname_#{$SdkVersion}_out#{$Custom_tag}.osw'\n"
end

if File.exists?($TestDir)
  FileUtils.mkdir_p($TestDir)
end

$all_model_paths = Dir.glob('./model/simulationtests/*.osm');

$ft = OpenStudio::SDD::SddForwardTranslator.new

# Helper to load a model in one line
# It will raise if the path (or the model) isn't valid
#
# @param path [String] The path to the osm
# @return [OpenStudio::Model::Model] the resulting model.
def osload(path)
  translator = OpenStudio::OSVersion::VersionTranslator.new
  ospath = OpenStudio::Path.new(path)
  model = translator.loadModel(ospath)
  if model.empty?
      raise "Path '#{path}' is not a valid path to an OpenStudio Model"
  else
      model = model.get
  end
  return model
end

def apply_known_changes(doc_new)
  # Previously, CoilHtg was incorrectly mapped to CoilClg
  doc_new.xpath("//CoilHtg").each do |node|
    node.name = 'CoilClg'
  end

  return doc_new
end

# the tests
class ModelTests < MiniTest::Unit::TestCase
  parallelize_me!

  def test_run_all
    $all_model_paths.each_with_index do |model_path, i|
      puts "\n\n[#{i}/#{$all_model_paths.size}] Running for #{model_path}"
      m = osload(model_path)
      filename = File.basename(model_path)

      sdd_out = File.join($TestDir, "#{filename}_#{$SdkVersion}_out#{$Custom_tag}.xml")
      test = $ft.modelToSDD(m, sdd_out);
      assert test
    end
  end

  def test_compare
    all_old_sdds = Dir.glob(File.join($TestDir, "*2.7.1_out.xml"))
    all_old_sdds.each do |sdd_ori|
      sdd_new = sdd_ori.sub("2.7.1", "2.7.2")
      assert File.exist?(sdd_new)
      doc_ori = File.open(sdd_ori) {|f| Nokogiri::XML(f) };
      doc_new = File.open(sdd_new) {|f| Nokogiri::XML(f) };

      # Know-changes
      doc_new = apply_known_changes(doc_new)


            # Know-changes
      doc_new = apply_known_changes(doc_new)

      opts = { :element_order => false, :normalize_whitespace => true }
      if sdd_ori.include?('scheduled_infiltration.osm_2.7.1_out.xml')
        # BlgAz is "0" in ori, '-0' in new
        opts[:ignore_content] = ["Proj > Bldg > BldgAz"]
      end
      assert EquivalentXml.equivalent?(doc_ori, doc_new, opts), "Failed: #{sdd_ori}"

    end
  end




end
