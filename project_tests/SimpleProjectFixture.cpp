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

#include <utilities/core/FileReference.hpp>
#include <utilities/core/PathHelpers.hpp>
#include <utilities/bcl/BCLMeasure.hpp>
#include <utilities/filetypes/EpwFile.hpp>

#include <project_tests/ProjectTests.hxx>

#include <QCoreApplication>

void SimpleProjectFixture::SetUp() 
{
  // have to set these so config options can save to QSettings
  QCoreApplication::setOrganizationName("OpenStudioResources");
  QCoreApplication::setApplicationName("SimpleProjectFixture");

  // have to copy these to where OpenStudio will expect them
  if (boost::filesystem::exists(openstudio::BCLMeasure::patApplicationMeasuresDir())){
    ASSERT_TRUE(openstudio::removeDirectory(openstudio::BCLMeasure::patApplicationMeasuresDir()));
  }
  ASSERT_TRUE(openstudio::copyDirectory(patApplicationMeasureSourceDir(), openstudio::BCLMeasure::patApplicationMeasuresDir()));
}

void SimpleProjectFixture::TearDown() {}

void SimpleProjectFixture::SetUpTestCase() {
  // set up logging
  logFile = openstudio::FileLogSink(openstudio::toPath("./SimpleProjectFixture.log"));
  logFile->setLogLevel(Warn);
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
