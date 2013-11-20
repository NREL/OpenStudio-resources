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

#include <model_tests/ModelFixture.hpp>

#include <model/TimeDependentValuation.hpp>

#include <utilities/filetypes/TimeDependentValuationFile.hpp>
#include <utilities/sql/SqlFile.hpp>
#include <utilities/core/FileLogSink.hpp>
#include <utilities/core/Path.hpp>



void ModelFixture::SetUp() {}

void ModelFixture::TearDown() {}

void ModelFixture::SetUpTestCase() {
  // set up logging
  logFile = openstudio::FileLogSink(openstudio::toPath("./ModelTestFixture.log"));
  logFile->setLogLevel(Debug);

}

void ModelFixture::TearDownTestCase() {}

boost::optional<openstudio::FileLogSink> ModelFixture::logFile;


void TimeDependentValuationFixture::SetUp() {
  // load model
  openstudio::path modelPath = resourcesPath()/
                               openstudio::toPath(GetParam().first)/
                               openstudio::toPath("in.osm");
  openstudio::model::OptionalModel oModel = openstudio::model::Model::load(modelPath);
  ASSERT_TRUE(oModel);
  m_model = *oModel;

  // set TDV file
  openstudio::path tdvPath = resourcesPath()/openstudio::toPath(GetParam().second);
  openstudio::OptionalTimeDependentValuationFile oTdvFile = openstudio::TimeDependentValuationFile::load(tdvPath);
  ASSERT_TRUE(oTdvFile);
  openstudio::model::OptionalTimeDependentValuation oTdv = openstudio::model::TimeDependentValuation::setTimeDependentValuation(m_model,*oTdvFile);
  ASSERT_TRUE(oTdv);

  // set SqlFile
  openstudio::path sqlPath = resourcesPath()/
                             openstudio::toPath(GetParam().first)/
                             openstudio::toPath("eplusout.sql");
  if (!boost::filesystem::exists(sqlPath)) {
    sqlPath = resourcesPath()/
              openstudio::toPath(GetParam().first)/
              openstudio::toPath("in.sql");
  }
  openstudio::SqlFile sqlFile(sqlPath);
  m_model.setSqlFile(sqlFile);
}

void TimeDependentValuationFixture::TearDown() {}

void TimeDependentValuationFixture::SetUpTestCase() {
  // set up logging
  logFile = openstudio::FileLogSink(openstudio::toPath("./TimeDependentValuationFixture.log"));
  logFile->setLogLevel(Info);
}

void TimeDependentValuationFixture::TearDownTestCase() {
  logFile->disable();
}

boost::optional<openstudio::FileLogSink> TimeDependentValuationFixture::logFile;
openstudio::model::Model TimeDependentValuationFixture::m_model;


void IntersectionFixture::SetUp() {}

void IntersectionFixture::TearDown() {}

void IntersectionFixture::SetUpTestCase() {
  // set up logging
  logFile = openstudio::FileLogSink(openstudio::toPath("./IntersectionFixture.log"));
  logFile->setLogLevel(Debug);

}

void IntersectionFixture::TearDownTestCase() {}

boost::optional<openstudio::FileLogSink> IntersectionFixture::logFile;
