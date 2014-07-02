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

#include <gtest/gtest.h>
#include "ProjectFixture.hpp"

#include <project/ProjectDatabase.hpp>
#include <project/AnalysisRecord.hpp>
#include <project/ProblemRecord.hpp>
#include <project/DataPointRecord.hpp>
#include <project/FileReferenceRecord.hpp>
#include <project/AttributeRecord.hpp>

#include <analysis/Analysis.hpp>
#include <analysis/Problem.hpp>
#include <analysis/Function.hpp>
#include <analysis/Algorithm.hpp>
#include <analysis/DataPoint.hpp>

#include <utilities/data/Attribute.hpp>
#include <utilities/data/Tag.hpp>
#include <utilities/core/Containers.hpp>
#include <utilities/core/FileReference.hpp>

#include <boost/filesystem.hpp>
#include <boost/foreach.hpp>
#include <boost/random/mersenne_twister.hpp>
#include <boost/random/uniform_real.hpp>
#include <boost/random/variate_generator.hpp>

// use posix_time directly (instead of Time.hpp) so can get milliseconds
#include <boost/date_time/posix_time/posix_time.hpp>

#include <resources.hxx>

using namespace openstudio;
using namespace openstudio::runmanager;
using namespace openstudio::analysis;
using namespace openstudio::project;

using namespace boost::posix_time;

TEST_F(ProjectFixture,Profile_ProblemSave) {
  Analysis analysis = getAnalysisToRun(100,0);

  // time the process of saving to database
  ptime start = microsec_clock::local_time();
  ProjectDatabase db = getCleanDatabase(toPath("./ProblemSave"));
  ASSERT_TRUE(db.startTransaction());
  ProblemRecord record = ProblemRecord::factoryFromProblem(analysis.problem(),db);
  db.save();
  ASSERT_TRUE(db.commitTransaction());
  time_duration saveTime = microsec_clock::local_time() - start;

  std::cout << "Time: " << to_simple_string(saveTime) << std::endl;
}

// Test not yet to scale re: data points.
TEST_F(ProjectFixture,Profile_SaveAnalysis) {
  Analysis analysis = getAnalysisToRun(100,500);

  // time the process of saving to database
  ptime start = microsec_clock::local_time();
  ProjectDatabase db = getCleanDatabase(toPath("./SaveAnalysis"));
  ASSERT_TRUE(db.startTransaction());
  AnalysisRecord record(analysis,db);
  db.save();
  ASSERT_TRUE(db.commitTransaction());
  time_duration saveTime = microsec_clock::local_time() - start;

  std::cout << "Time: " << to_simple_string(saveTime) << std::endl;
}

// Test not yet to scale re: total data points.
TEST_F(ProjectFixture,Profile_UpdateAnalysis) {
  Analysis analysis = getAnalysisToRun(100,500);

  // save to database
  ProjectDatabase db = getCleanDatabase(toPath("./UpdateAnalysis"));
  ASSERT_TRUE(db.startTransaction());
  AnalysisRecord record(analysis,db);
  db.save();
  ASSERT_TRUE(db.commitTransaction());

  // add output data to 1 data point
  DataPointVector dataPoints = analysis.dataPoints();
  boost::mt19937 mt;
  typedef boost::uniform_real<> uniform_dist_type;
  typedef boost::variate_generator<boost::mt19937&, uniform_dist_type> uniform_gen_type;
  uniform_gen_type responseGenerator(mt,uniform_dist_type(50.0,500.0));
  for (int i = 0; i < 1; ++i) {
    std::stringstream ss;
    ss << "dataPoint" << i + 1;
    DoubleVector responseValues;
    for (int j = 0, n = analysis.problem().responses().size(); j < n; ++j) {
      responseValues.push_back(responseGenerator());
    }
    openstudio::path runDir = toPath(ss.str());
    dataPoints[i] = DataPoint(dataPoints[i].uuid(),
                              createUUID(),
                              dataPoints[i].name(),
                              dataPoints[i].displayName(),
                              dataPoints[i].description(),
                              analysis.problem(),
                              true,
                              false,
                              true,
                              DataPointRunType::Local,
                              dataPoints[i].variableValues(),
                              responseValues,
                              runDir,
                              FileReference(runDir / toPath("ModelToIdf/in.osm")),
                              FileReference(runDir / toPath("ModelToIdf/out.idf")),
                              FileReference(runDir / toPath("EnergyPlus/eplusout.sql")),
                              boost::optional<runmanager::Job>(),
                              std::vector<openstudio::path>(),
                              TagVector(),
                              AttributeVector());
    dataPoints[i].setName(dataPoints[i].name()); // set dirty
  }
  analysis = Analysis(analysis.uuid(),
                      analysis.versionUUID(),
                      analysis.name(),
                      analysis.displayName(),
                      analysis.description(),
                      analysis.problem(),
                      analysis.algorithm(),
                      analysis.seed(),
                      analysis.weatherFile(),
                      dataPoints,
                      false,
                      false);
  analysis.setName(analysis.name()); // set dirty

  // time the process of updating the database
  ptime start = microsec_clock::local_time();
  db.unloadUnusedCleanRecords();
  ASSERT_TRUE(db.startTransaction());
  record = AnalysisRecord(analysis,db);
  db.save();
  ASSERT_TRUE(db.commitTransaction());
  time_duration updateTime = microsec_clock::local_time() - start;

  std::cout << "Time: " << to_simple_string(updateTime) << std::endl;
}

// Test not yet to scale re: total data points.
TEST_F(ProjectFixture,Profile_DeserializeAnalysis) {
  // ETH@20121108 - When this test is running reasonably well, replace the beginning of
  // UpdateAnalysis with this.
  ProjectDatabase db = getPopulatedDatabase(100,500,false,toPath("./UpdateAnalysis"));
  AnalysisRecordVector records = AnalysisRecord::getAnalysisRecords(db);
  ASSERT_EQ(1u,records.size());
  AnalysisRecord record = records[0];

  // time the process of deserializing an analysis
  ptime start = microsec_clock::local_time();
  Analysis analysis = record.analysis();
  time_duration deserializeTime = microsec_clock::local_time() - start;

  std::cout << "Time: " << to_simple_string(deserializeTime) << std::endl;
}

// Test not yet to scale re: data points.
TEST_F(ProjectFixture,Profile_OpenDatabase) {
  {
    ProjectDatabase db = getPopulatedDatabase(100,500,true,toPath("./OpenDatabase"));
  }

  {
    ptime start = microsec_clock::local_time();
    OptionalProjectDatabase odb = ProjectDatabase::open(toPath("./OpenDatabase/project.osp"));
    ASSERT_TRUE(odb);
    time_duration openTime = microsec_clock::local_time() - start;

    std::cout << "Time: " << to_simple_string(openTime) << std::endl;
  }
}

// Test not yet to scale re: data points.
TEST_F(ProjectFixture,Profile_RetrieveResponses) {
  ProjectDatabase db = getPopulatedDatabase(100,500,true,toPath("./RetrieveResponses"));

  // time the process of retrieving response function data
  ptime start = microsec_clock::local_time();
  DataPointRecordVector dataPointRecords = DataPointRecord::getDataPointRecords(db);
  EXPECT_EQ(500u,dataPointRecords.size());
  std::vector<DoubleVector> responseValues(dataPointRecords.size(),DoubleVector());
  for (int i = 0, n = dataPointRecords.size(); i < n; ++i) {
    responseValues[i] = dataPointRecords[i].responseValues();
  }
  time_duration retrieveTime = microsec_clock::local_time() - start;

  std::cout << "Time: " << to_simple_string(retrieveTime) << std::endl;
}

// Test not yet to scale re: data points.
TEST_F(ProjectFixture,Profile_ClearAnalysisResults) {
  ProjectDatabase db = getPopulatedDatabase(100,500,true,toPath("./ClearAnalysisResults"));

  // mimic code in AnalysisDriver to avoid adding AnalysisDriver as a dependency

  // time the process of retrieving response function data
  ptime start = microsec_clock::local_time();
  db.unloadUnusedCleanRecords();
  ASSERT_TRUE(db.startTransaction());
  DataPointRecordVector dataPointRecords = DataPointRecord::getDataPointRecords(db);
  EXPECT_EQ(500u,dataPointRecords.size());
  BOOST_FOREACH(project::DataPointRecord& dataPointRecord,dataPointRecords) {
    // in AnalysisDriver, removes DataPoint directories, but they don't exist here
    db.removeRecord(dataPointRecord);
  }
  db.save();
  ASSERT_TRUE(db.commitTransaction());
  AnalysisRecordVector analysisRecords = AnalysisRecord::getAnalysisRecords(db);
  ASSERT_EQ(1u,analysisRecords.size());
  Analysis analysis = analysisRecords[0].analysis();
  analysis.clearAllResults();
  db.unloadUnusedCleanRecords();
  ASSERT_TRUE(db.startTransaction());
  AnalysisRecord analysisRecord(analysis,db);
  db.save();
  ASSERT_TRUE(db.commitTransaction());
  time_duration clearTime = microsec_clock::local_time() - start;

  std::cout << "Time: " << to_simple_string(clearTime) << std::endl;
}

TEST_F(ProjectFixture,Profile_OpenDatabaseWithUpdate) {
  openstudio::path dbFilename = toPath("MS-BESX-2_Heating_DDACE-Random_1000.osp");
  openstudio::path rmFilename = toPath("MS-BESX-2_Heating_DDACE-Random_1000.db");
  openstudio::path originalFolder = resourcesPath() / toPath("project");
  openstudio::path newFolder = toPath("./OpenDatabaseWithUpdate");

  if (boost::filesystem::exists(newFolder)) {
    boost::filesystem::remove_all(newFolder);
  }
  boost::filesystem::create_directory(newFolder);
  boost::filesystem::copy_file(originalFolder/dbFilename,newFolder/dbFilename);
  boost::filesystem::copy_file(originalFolder/rmFilename,newFolder/rmFilename);

  // time the process of opening this ProjectDatabase
  // will update paths and do version updating as needed
  ptime start = microsec_clock::local_time();
  OptionalProjectDatabase odb = ProjectDatabase::open(newFolder / dbFilename);
  ASSERT_TRUE(odb);
  odb->save();
  time_duration openTime = microsec_clock::local_time() - start;

  std::cout << "Time: " << to_simple_string(openTime) << std::endl;
}

TEST_F(ProjectFixture,Profile_OpenDatabaseWithoutUpdate) {
  openstudio::path dbFilename = toPath("MS-BESX-2_Heating_DDACE-Random_1000.osp");
  openstudio::path rmFilename = toPath("MS-BESX-2_Heating_DDACE-Random_1000.db");
  openstudio::path originalFolder = resourcesPath() / toPath("project");
  openstudio::path newFolder = toPath("./OpenDatabaseWithoutUpdate");

  if (boost::filesystem::exists(newFolder)) {
    boost::filesystem::remove_all(newFolder);
  }
  boost::filesystem::create_directory(newFolder);
  boost::filesystem::copy_file(originalFolder/dbFilename,newFolder/dbFilename);
  boost::filesystem::copy_file(originalFolder/rmFilename,newFolder/rmFilename);

  // open once to do updating
  {
    OptionalProjectDatabase odb = ProjectDatabase::open(newFolder / dbFilename);
    ASSERT_TRUE(odb);
    odb->save();
  }

  // time the process of opening this ProjectDatabase after update already done
  ptime start = microsec_clock::local_time();
  OptionalProjectDatabase odb = ProjectDatabase::open(newFolder / dbFilename);
  ASSERT_TRUE(odb);
  time_duration openTime = microsec_clock::local_time() - start;

  std::cout << "Time: " << to_simple_string(openTime) << std::endl;
}

TEST_F(ProjectFixture,Profile_RetrieveRealResults) {
  openstudio::path dbFilename = toPath("MS-BESX-2_Heating_DDACE-Random_1000.osp");
  openstudio::path rmFilename = toPath("MS-BESX-2_Heating_DDACE-Random_1000.db");
  openstudio::path originalFolder = resourcesPath() / toPath("project");
  openstudio::path newFolder = toPath("./RetrieveRealResults");

  if (boost::filesystem::exists(newFolder)) {
    boost::filesystem::remove_all(newFolder);
  }
  boost::filesystem::create_directory(newFolder);
  boost::filesystem::copy_file(originalFolder/dbFilename,newFolder/dbFilename);
  boost::filesystem::copy_file(originalFolder/rmFilename,newFolder/rmFilename);

  OptionalProjectDatabase odb = ProjectDatabase::open(newFolder / dbFilename);
  ASSERT_TRUE(odb);
  ProjectDatabase db = *odb;
  db.save();

  // time the process of retrieving results
  ptime start = microsec_clock::local_time();
  DataPointRecordVector dataPointRecords = DataPointRecord::getDataPointRecords(db);
  EXPECT_EQ(1000u,dataPointRecords.size());
  std::vector<AttributeVector> attributes(dataPointRecords.size(),AttributeVector());
  for (int i = 0, n = dataPointRecords.size(); i < n; ++i) {
    AttributeRecordVector attributeRecords = dataPointRecords[i].attributeRecords();
    EXPECT_FALSE(attributeRecords.empty());
    BOOST_FOREACH(const AttributeRecord& attributeRecord,attributeRecords) {
      attributes[i].push_back(attributeRecord.attribute());
    }
  }
  time_duration retrieveTime = microsec_clock::local_time() - start;

  std::cout << "Time: " << to_simple_string(retrieveTime) << std::endl;

}
