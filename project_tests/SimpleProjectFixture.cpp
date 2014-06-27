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

#include <utilities/core/PathHelpers.hpp>
#include <utilities/bcl/BCLMeasure.hpp>

#include <project_tests/ProjectTests.hxx>

void SimpleProjectFixture::SetUp() 
{
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

boost::optional<openstudio::analysisdriver::SimpleProject> SimpleProjectFixture::makeSimpleProject(openstudio::path projectDir) 
{
  if (boost::filesystem::exists(projectDir)) {
    boost::filesystem::remove_all(projectDir);
  }
  boost::optional<openstudio::analysisdriver::SimpleProject> result = openstudio::analysisdriver::SimpleProject::create(projectDir);
  return result;
}
