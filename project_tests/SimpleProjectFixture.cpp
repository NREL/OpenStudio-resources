/**********************************************************************
*  Copyright (c) 2008-2010, Alliance for Sustainable Energy.  
*  All rights reserved.
*  
*  This library is free software; you can redistribute it and/or
*  modify it under the terms of the GNU Lesser General Public
*  License as published by the Free Software Foundation; either
*  version 2.1 of the License, or (at your option) any later version.
*  
*  This library is distributed in the hope that it will be useful,
*  but WITHOUT ANY WARRANTY; without even the implied warranty of
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
*  Lesser General Public License for more details.
*  
*  You should have received a copy of the GNU Lesser General Public
*  License along with this library; if not, write to the Free Software
*  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
**********************************************************************/

#include "SimpleProjectFixture.hpp"

#include <analysisdriver/SimpleProject.hpp>

#include <analysis/DataPoint.hpp>

#include <model/Model.hpp>
#include <model/WeatherFile.hpp>

#include <runmanager/lib/RunManager.hpp>
#include <runmanager/lib/ConfigOptions.hpp>

#include <utilities/core/ApplicationPathHelpers.hpp>
#include <utilities/core/FileReference.hpp>
#include <utilities/core/PathHelpers.hpp>
#include <utilities/bcl/BCLMeasure.hpp>
#include <utilities/filetypes/EpwFile.hpp>

#include <project_tests/ProjectTests.hxx>

#include <QCoreApplication>
#include <QtGlobal>
#include <QByteArray>
#include <QString>

void SimpleProjectFixture::SetUp() 
{
  // have to set these so config options can save to QSettings
  QCoreApplication::setOrganizationName("OpenStudioResources");
  QCoreApplication::setApplicationName("SimpleProjectFixture");

  QString pathAddition;
#if defined(Q_OS_LINUX) || defined(Q_OS_MAC)
  pathAddition = ":";
  pathAddition += openstudio::toQString(openstudio::getApplicationRunDirectory());
#else
  pathAddition = ";";
  pathAddition += openstudio::toQString(openstudio::getApplicationRunDirectory());
#endif

  QByteArray env = qgetenv("PATH");
  env.append(pathAddition);
  qputenv("PATH", env);

  env = qgetenv("RUBYLIB");
  env.append(pathAddition);
  qputenv("RUBYLIB", env);

  env = qgetenv("DLN_LIBRARY_PATH");
  env.append(pathAddition);
  qputenv("DLN_LIBRARY_PATH", env);

  // DLM: the code below is a hack and should not be required, we should be able to set these paths somehow
  // JMT: I have no idea why you thought this was necessary, but it deletes the files in your source directory and
  //      makes it impossible to run the tests. Worse then a hack, by far.
  //
  // have to copy measure to where OpenStudio will expect them (it thinks we are running from OpenStudio installer)
//  if (boost::filesystem::exists(openstudio::BCLMeasure::patApplicationMeasuresDir())){
//    ASSERT_TRUE(openstudio::removeDirectory(openstudio::BCLMeasure::patApplicationMeasuresDir()));
//  }
//  ASSERT_TRUE(openstudio::copyDirectory(patApplicationMeasureSourceDir(), openstudio::BCLMeasure::patApplicationMeasuresDir()));

  // have to copy measure to where OpenStudio will expect them (it thinks we are running from OpenStudio
//  if (boost::filesystem::exists(openstudio::getOpenStudioRubyScriptsPath())){
//    ASSERT_TRUE(openstudio::removeDirectory(openstudio::getOpenStudioRubyScriptsPath()));
//  }
//  ASSERT_TRUE(openstudio::copyDirectory(getOpenStudioRubyScriptsSourcePath(), openstudio::getOpenStudioRubyScriptsPath()));
}

void SimpleProjectFixture::TearDown() {}

void SimpleProjectFixture::SetUpTestCase() {
  // set up logging
  logFile = openstudio::FileLogSink(openstudio::toPath("./SimpleProjectFixture.log"));
  logFile->setLogLevel(Trace);
  openstudio::Logger::instance().standardOutLogger().disable();
}

void SimpleProjectFixture::TearDownTestCase() {
  logFile->disable();
}

boost::optional<openstudio::FileLogSink> SimpleProjectFixture::logFile;

boost::optional<openstudio::analysisdriver::SimpleProject> SimpleProjectFixture::makePATProject(openstudio::path projectDir) 
{
  if (boost::filesystem::exists(projectDir)) {
    boost::filesystem::remove_all(projectDir);
  }
  openstudio::analysisdriver::SimpleProjectOptions options;
  boost::optional<openstudio::analysisdriver::SimpleProject> result = openstudio::analysisdriver::createPATProject(projectDir, options);

  // scan for tools
  openstudio::runmanager::RunManager rm = result->runManager();
  openstudio::runmanager::ConfigOptions co = rm.getConfigOptions();
  co.findTools(false, false, false, true);
  rm.setConfigOptions(co);
  co.saveQSettings();

  // seed
  openstudio::EpwFile epwFile(resourcesPath() / openstudio::toPath("project/USA_CO_Golden-NREL.724666_TMY3.epw"));
  openstudio::model::Model model = openstudio::model::exampleModel();
  openstudio::model::WeatherFile::setWeatherFile(model, epwFile);
  openstudio::path p = projectDir.parent_path() / openstudio::toPath("example.osm");
  model.save(p,true);
  openstudio::FileReference seedModel(p);
  result->setSeed(seedModel);

  // create baseline
  result->baselineDataPoint();

  return result;
}
