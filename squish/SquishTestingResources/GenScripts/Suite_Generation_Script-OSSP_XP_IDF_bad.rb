# rubyscript to generate squish testcases for importing IDF's into OpenStudio
# David Goldwasser, NREL 2011

# variables, cmake could configure these paths
svnPath = 'C:/OpenStudio_Squish_SVN/squish'
genScriptsPath = svnPath + '/SquishTestingResources/GenScripts'
sourcePath = 'C:/OpenStudio_Squish_SVN/squish/SquishTestingResources/bad_IDF_files'
testSuiteSuffix = 'OSSP_XP_IDF_bad'
testSuitePath = svnPath + '/suite_' + testSuiteSuffix
exportpath = svnPath + '/SquishTestingExports/' + testSuiteSuffix + '-exports'
sharedScriptName = testSuiteSuffix + '_script_shared.js'
testScriptName = testSuiteSuffix + '_test.js'
suiteConfName = testSuiteSuffix + '_suite.conf'
suiteMapName = testSuiteSuffix + '_objects.map'
fileType = '*.idf'
testPrefix = 'tst_'

# load file utilties from standard ruby library
require 'FileUtils'

# changes current directory and then prints it out
Dir.chdir(sourcePath)
puts 'path to source files - ' + Dir.pwd
# makes array of files with .idf extension
puts 'searching for "' + fileType + '" files'
# **/ looks in subdirectories
idfFiles = Dir['**/' + fileType]

# set directory to TestSuitePath
FileUtils.mkdir_p(testSuitePath)
Dir.chdir(testSuitePath)
puts 'path to test suite - ' + Dir.pwd

# loop through IdfFiles array to make directory and copy script file
puts 'generating test cases'
for rawfile in idfFiles
  # remove path of necessary
  file = File.basename(rawfile)
  # make directory for each idf file
  FileUtils.mkdir(testPrefix + file)
  # copy test.js file into each new directory
  FileUtils.cp(genScriptsPath + '/' + testScriptName,testPrefix + file + '/test.js')
end

# make and populate shared directory
puts 'making and populating  and export shared directory'
FileUtils.mkdir_p('shared/scripts')
FileUtils.cp(genScriptsPath + '/' + sharedScriptName, 'shared/scripts/script_shared.js')
FileUtils.mkdir_p(exportpath)

# add object.map and suite.conf
puts 'making suite.conf and object.map files'
FileUtils.cp(genScriptsPath + '/' + suiteConfName, './suite.conf')
FileUtils.cp(genScriptsPath + '/' + suiteMapName, './objects.map')

puts 'done'
