require 'openstudio'
require 'equivalent-xml'
require 'etc'

# Environment variables
if ENV['N'].nil?
  # Number of parallel runs caps to nproc - 1
  ENV['N'] = [1, Etc.nprocessors - 1].max.to_s
end

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

# config stuff
$OpenstudioCli = OpenStudio::getOpenStudioCLI
$RootDir = File.absolute_path(File.dirname(__FILE__))
$ModelDir = File.join($RootDir, 'model/simulationtests/')
$SddSimDir = File.join($RootDir, 'model/sddtests/')
$TestDirSddFT = File.join($RootDir, 'testruns/SddForwardTranslator/')
$TestDirSddRT = File.join($RootDir, 'testruns/SddReverseTranslator/')

if File.exists?($TestDirSddFT)
  FileUtils.mkdir_p($TestDirSddFT)
end

if File.exists?($TestDirSddRT)
  FileUtils.mkdir_p($TestDirSddRT)
end

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

###############################################################################
#                     For comparison, pass ENV variables                      #
###############################################################################

$IsCompareOK = true
if ENV['OLD_VERSION'].nil?
  $IsCompareOK = false
else
  $Old_Version = ENV['OLD_VERSION']
end
if ENV['NEW_VERSION'].nil?
  $IsCompareOK = false
else
  $New_Version = ENV['NEW_VERSION']
end


$all_model_paths = Dir.glob(File.join($ModelDir, '*.osm'));
$all_sddsimxml_paths = Dir.glob(File.join($SddSimDir, '*.xml'));

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

# Disable the logger (Switch to enable otherwise)
OpenStudio::Logger.instance.standardOutLogger.disable
# If enabled, set the LogLevel (Error, Warn, Info, Debug, Trace)
OpenStudio::Logger.instance.standardOutLogger.setLogLevel(OpenStudio::Error)

$Disabled_RT_Tests = [
  # These make both 2.7.1 and 2.7.2 hard crash
  #'OffSml_MiniSplit',

]

def escapeName(filename)
  return filename.gsub('-','_')
                 .gsub('+','_')
                 .gsub(' ','_')
                 .gsub("=",'_')
end

def sdd_ft_test(osm_path)
  full_path = File.join($ModelDir, osm_path)

  filename = File.basename(osm_path).gsub('.osm', '')
  #$i_ft += 1
  #puts "\n\n[#{$i_ft}/#{$all_model_paths.size}] Running for #{model_path}"
  m = osload(full_path)
  sdd_out = File.join($TestDirSddFT, "#{filename}_#{$SdkVersion}_out#{$Custom_tag}.xml")
  ft = OpenStudio::SDD::SddForwardTranslator.new
  test = ft.modelToSDD(m, sdd_out);
  assert test, "Failed SDD FT for #{filename}"
end

# Runs a single SddReverseTranslator path given the name of a SDD SIM XML file
# It will raise if the path (or the model) isn't valid
#
# @param sddsimxml_path [String] The name of the XML, eg: 'blabla.xml'
# It will go look in SddSimDir for this will
# @return None. Will assert that the model can be RT'ed, and save it in
# $TestDirSddRT for comparison
def sdd_rt_test(sddsimxml_path)

  full_path = File.join($SddSimDir, sddsimxml_path)

  filename = escapeName(sddsimxml_path.gsub(' - ap.xml', ''))

  #puts "\nRunning for #{filename}"
  #puts "Loading #{full_path}"

  if $Disabled_RT_Tests.include?(filename)
    skip "Test is disabled for #{filename}"
  end
  # Remove the semi colon to see the RT warnings/Errors
  rt = OpenStudio::SDD::SddReverseTranslator.new
  _m = rt.loadModel(full_path);
  # Test that RT Worked
  assert _m.is_initialized, "Failed SDD RT for #{filename}"

  # If so, then save resulting OSM for diffing
  m_out = File.join($TestDirSddRT, "#{filename}_#{$SdkVersion}_out#{$Custom_tag}.osm")
  _m.get.save(m_out, true)
end


# the tests
class SddTests < Minitest::Test
  parallelize_me!
  # i_suck_and_my_tests_are_order_dependent! # To debug a crash

  # Dynamically create the SddForwardTranslator tests
  # by discovering all OSMs in model/simulationtests
  $all_model_paths.each do |model_path|
    filename = escapeName(File.basename(model_path).gsub('.osm', ''))
    define_method("test_FT_#{filename}") do
      sdd_ft_test(File.basename(model_path))
    end
  end

  # To be called manually after both the old and new have run
  def test_FT_compare

    assert $IsCompareOK, "You must pass the environment variables " +
                         "OLD_VERSION & NEW_VERSION in order to run " +
                         "the SddForwardTranslator_compare test.\n" +
                         "eg: `OLD_VERSION=2.7.1 NEW_VERSION=2.7.2 ruby SDD_tests.rb -n /compare/`"

    puts "Running XML Diffs for #{$Old_Version} > #{$New_Version}"

    all_old_sdds = Dir.glob(File.join($TestDirSddFT, "*#{$Old_Version}_out.xml"))
    puts "Discovered #{all_old_sdds.size} SDD XMLs to compare"
    all_old_sdds.each do |sdd_ori|
      sdd_new = sdd_ori.sub($Old_Version, $New_Version)
      assert File.exist?(sdd_new)
      doc_ori = File.open(sdd_ori) {|f| Nokogiri::XML(f) };
      doc_new = File.open(sdd_new) {|f| Nokogiri::XML(f) };

      # Known-changes to XML structure itself
      doc_new = apply_known_changes(doc_new)

      # Local only ignores
      opts = { :element_order => false, :normalize_whitespace => true }
      if sdd_ori.include?('scheduled_infiltration.osm_2.7.1_out.xml')
        # BlgAz is "0" in ori, '-0' in new
        opts[:ignore_content] = ["Proj > Bldg > BldgAz"]
      end

      # Assert XMLs are the same
      assert EquivalentXml.equivalent?(doc_ori, doc_new, opts), "Failed: #{sdd_ori}"

    end
  end

  #  Note: JM 2019-01-18
  #  Not used because you can't parallelize this
  #
  # Dynamically create the SddReverseTranslator tests
  # by discovering all SDD Sim XMLs in model/sddtests
  #$all_sddsimxml_paths.each do |sddsimxml_path|
    #filename = escapeName(File.basename(sddsimxml_path).gsub(' - ap.xml', ''))
    #define_method("test_RT_auto#{filename}") do
      #sdd_rt_test(File.basename(sddsimxml_path))
    #end
  #end

###############################################################################
#                             Hardcoded RT tests                              #
###############################################################################

  def test_RT_010012_SchSml_CECStd
    sdd_rt_test('010012-SchSml-CECStd - ap.xml')
  end

  def test_RT_010112_SchSml_PSZ16
    sdd_rt_test('010112-SchSml-PSZ16 - ap.xml')
  end

  def test_RT_010212_SchSml_PVAVAirZnSys16
    sdd_rt_test('010212-SchSml-PVAVAirZnSys16 - ap.xml')
  end

  def test_RT_010312_SchSml_VAVFluidZnSys16
    sdd_rt_test('010312-SchSml-VAVFluidZnSys16 - ap.xml')
  end

  def test_RT_020006_OffSml_Run01
    sdd_rt_test('020006-OffSml-Run01 - ap.xml')
  end

  def test_RT_020006_OffSml_Run14
    sdd_rt_test('020006-OffSml-Run14 - ap.xml')
  end

  def test_RT_020006_OffSml_Run18
    sdd_rt_test('020006-OffSml-Run18 - ap.xml')
  end

  def test_RT_020006_OffSml_Run24
    sdd_rt_test('020006-OffSml-Run24 - ap.xml')
  end

  def test_RT_020006_OffSml_Run25
    sdd_rt_test('020006-OffSml-Run25 - ap.xml')
  end

  def test_RT_020006_OffSml_Run26
    sdd_rt_test('020006-OffSml-Run26 - ap.xml')
  end

  def test_RT_020006S_OffSml_Run01
    sdd_rt_test('020006S-OffSml-Run01 - ap.xml')
  end

  def test_RT_020006S_OffSml_Run14
    sdd_rt_test('020006S-OffSml-Run14 - ap.xml')
  end

  def test_RT_020006S_OffSml_Run18
    sdd_rt_test('020006S-OffSml-Run18 - ap.xml')
  end

  def test_RT_020012_OffSml_CECStd
    sdd_rt_test('020012-OffSml-CECStd - ap.xml')
  end

  def test_RT_020012S_OffSml_CECStd
    sdd_rt_test('020012S-OffSml-CECStd - ap.xml')
  end

  def test_RT_020015_OffSml_Run02
    sdd_rt_test('020015-OffSml-Run02 - ap.xml')
  end

  def test_RT_020015S_OffSml_Run02
    sdd_rt_test('020015S-OffSml-Run02 - ap.xml')
  end

  def test_RT_030006_OffMed_Run04
    sdd_rt_test('030006-OffMed-Run04 - ap.xml')
  end

  def test_RT_030006_OffMed_Run12
    sdd_rt_test('030006-OffMed-Run12 - ap.xml')
  end

  def test_RT_030006_OffMed_Run13
    sdd_rt_test('030006-OffMed-Run13 - ap.xml')
  end

  def test_RT_030006_OffMed_Run19
    sdd_rt_test('030006-OffMed-Run19 - ap.xml')
  end

  def test_RT_030006_OffMed_Run23
    sdd_rt_test('030006-OffMed-Run23 - ap.xml')
  end

  def test_RT_030006_OffMed_Run29
    sdd_rt_test('030006-OffMed-Run29 - ap.xml')
  end

  def test_RT_030006_OffMed_Run30
    sdd_rt_test('030006-OffMed-Run30 - ap.xml')
  end

  def test_RT_030006S_OffMed_Run04
    sdd_rt_test('030006S-OffMed-Run04 - ap.xml')
  end

  def test_RT_030006S_OffMed_Run12
    sdd_rt_test('030006S-OffMed-Run12 - ap.xml')
  end

  def test_RT_030006S_OffMed_Run13
    sdd_rt_test('030006S-OffMed-Run13 - ap.xml')
  end

  def test_RT_030012_OffMed_CECStd
    sdd_rt_test('030012-OffMed-CECStd - ap.xml')
  end

  def test_RT_030012S_OffMed_CECStd
    sdd_rt_test('030012S-OffMed-CECStd - ap.xml')
  end

  def test_RT_040006_OffLrg_Run05
    sdd_rt_test('040006-OffLrg-Run05 - ap.xml')
  end

  def test_RT_040006_OffLrg_Run06
    sdd_rt_test('040006-OffLrg-Run06 - ap.xml')
  end

  def test_RT_040006_OffLrg_Run11
    sdd_rt_test('040006-OffLrg-Run11 - ap.xml')
  end

  def test_RT_040006_OffLrg_Run20
    sdd_rt_test('040006-OffLrg-Run20 - ap.xml')
  end

  def test_RT_040012_OffLrg_CECStd
    sdd_rt_test('040012-OffLrg-CECStd - ap.xml')
  end

  def test_RT_040112_OffLrg_AbsorptionChiller16
    sdd_rt_test('040112-OffLrg-AbsorptionChiller16 - ap.xml')
  end

  def test_RT_040112_OffLrg_VAVPriSec16
    sdd_rt_test('040112-OffLrg-VAVPriSec16 - ap.xml')
  end

  def test_RT_040112_OffLrg_Waterside_Economizer16
    sdd_rt_test('040112-OffLrg-Waterside Economizer16 - ap.xml')
  end

  def test_RT_050006_RetlMed_Run16
    sdd_rt_test('050006-RetlMed-Run16 - ap.xml')
  end

  def test_RT_050006_RetlMed_Run27
    sdd_rt_test('050006-RetlMed-Run27 - ap.xml')
  end

  def test_RT_050006_RetlMed_Run28
    sdd_rt_test('050006-RetlMed-Run28 - ap.xml')
  end

  def test_RT_050012_RetlMed_CECStd
    sdd_rt_test('050012-RetlMed-CECStd - ap.xml')
  end

  def test_RT_050112_RetlMed_SZVAV16
    sdd_rt_test('050112-RetlMed-SZVAV16 - ap.xml')
  end

  def test_RT_050312_RetlMed_Alterations16
    sdd_rt_test('050312-RetlMed-Alterations16 - ap.xml')
  end

  def test_RT_060012_RstntSml_CECStd
    sdd_rt_test('060012-RstntSml-CECStd - ap.xml')
  end

  def test_RT_070012_HotSml_CECStd
    sdd_rt_test('070012-HotSml-CECStd - ap.xml')
  end

  def test_RT_070015_HotSml_Run03
    sdd_rt_test('070015-HotSml-Run03 - ap.xml')
  end

  def test_RT_070015_HotSml_Run22
    sdd_rt_test('070015-HotSml-Run22 - ap.xml')
  end

  def test_RT_080006_Whse_Run07
    sdd_rt_test('080006-Whse-Run07 - ap.xml')
  end

  def test_RT_080006_Whse_Run08
    sdd_rt_test('080006-Whse-Run08 - ap.xml')
  end

  def test_RT_080006_Whse_Run15
    sdd_rt_test('080006-Whse-Run15 - ap.xml')
  end

  def test_RT_080006_Whse_Run21
    sdd_rt_test('080006-Whse-Run21 - ap.xml')
  end

  def test_RT_080012_Whse_CECStd
    sdd_rt_test('080012-Whse-CECStd - ap.xml')
  end

  def test_RT_090012_RetlLrg_CECStd
    sdd_rt_test('090012-RetlLrg-CECStd - ap.xml')
  end

  def test_RT_OffLrg_PlenumsFPBsData16
    sdd_rt_test('OffLrg-PlenumsFPBsData16 - ap.xml')
  end

  def test_RT_OffLrg_PrkgExhaust16
    sdd_rt_test('OffLrg-PrkgExhaust16 - ap.xml')
  end

  def test_RT_OffLrg_PrkgLab16
    sdd_rt_test('OffLrg-PrkgLab16 - ap.xml')
  end

  def test_RT_OffLrg_PrkgLabKitchen16
    sdd_rt_test('OffLrg-PrkgLabKitchen16 - ap.xml')
  end

  def test_RT_OffLrg_ThermalEnergyStorage_ChillerPriority
    sdd_rt_test('OffLrg-ThermalEnergyStorage_ChillerPriority - ap.xml')
  end

  def test_RT_OffLrg_ThermalEnergyStorage_StoragePriority
    sdd_rt_test('OffLrg-ThermalEnergyStorage_StoragePriority - ap.xml')
  end

  def test_RT_OffMed_CoreAndShell
    sdd_rt_test('OffMed-CoreAndShell - ap.xml')
  end

  def test_RT_OffSml_ActiveBeams
    sdd_rt_test('OffSml-ActiveBeams - ap.xml')
  end

  def test_RT_OffSml_CombDHWSpcHt16
    sdd_rt_test('OffSml-CombDHWSpcHt16 - ap.xml')
  end

  def test_RT_OffSml_CommKit_SZVAV16
    sdd_rt_test('OffSml-CommKit_SZVAV16 - ap.xml')
  end

  def test_RT_OffSml_Data_SZVAV16
    sdd_rt_test('OffSml-Data_SZVAV16 - ap.xml')
  end

  def test_RT_OffSml_HtRcvry16
    sdd_rt_test('OffSml-HtRcvry16 - ap.xml')
  end

  def test_RT_OffSml_Lab_SZVAV16
    sdd_rt_test('OffSml-Lab_SZVAV16 - ap.xml')
  end

  def test_RT_OffSml_MiniSplit
    sdd_rt_test('OffSml-MiniSplit - ap.xml')
  end

  def test_RT_OffSml_Office_SZVAV16
    sdd_rt_test('OffSml-Office_SZVAV16 - ap.xml')
  end

  def test_RT_OffSml_PSZ_Evap16
    sdd_rt_test('OffSml-PSZ-Evap16 - ap.xml')
  end

  def test_RT_OffSml_PassiveBeams
    sdd_rt_test('OffSml-PassiveBeams - ap.xml')
  end

  def test_RT_OffSml_PassiveBeams_DOASCV_HtRcvry
    sdd_rt_test('OffSml-PassiveBeams-DOASCV+HtRcvry - ap.xml')
  end

  def test_RT_OffSml_PassiveBeams_DOASVAV
    sdd_rt_test('OffSml-PassiveBeams-DOASVAV - ap.xml')
  end

  def test_RT_OffSml_WSHP16
    sdd_rt_test('OffSml-WSHP16 - ap.xml')
  end

  def test_RT_RetlMed_PVAV_IndirDirEvap16
    sdd_rt_test('RetlMed-PVAV-IndirDirEvap16 - ap.xml')
  end

  def test_RT_RetlSml_DOAS_FPFC16
    sdd_rt_test('RetlSml-DOAS+FPFC16 - ap.xml')
  end

  def test_RT_RetlSml_DOAS_GravityFurnace
    sdd_rt_test('RetlSml-DOAS+GravityFurnace - ap.xml')
  end

  def test_RT_RetlSml_DOAS_GravityFurnace_HasNoClg_0
    sdd_rt_test('RetlSml-DOAS+GravityFurnace_HasNoClg=0 - ap.xml')
  end

  def test_RT_RetlSml_DOAS_GravityFurnace_HasNoClg_1
    sdd_rt_test('RetlSml-DOAS+GravityFurnace_HasNoClg=1 - ap.xml')
  end

end
