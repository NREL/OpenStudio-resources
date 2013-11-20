/**********************************************************************
*  Copyright (c) 2008-2013, Alliance for Sustainable Energy.  
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

#include "CloudFixture.hpp"

#include <analysisdriver/test/AnalysisDriverTestLibrary.hpp>

#include <analysisdriver/CloudAnalysisDriver.hpp>
#include <analysisdriver/SimpleProject.hpp>

#include <analysis/Analysis.hpp>
#include <analysis/DataPoint.hpp>
#include <analysis/Problem.hpp>

#include <model/Model.hpp>

#include <utilities/cloud/VagrantProvider.hpp>
#include <utilities/data/Attribute.hpp>
#include <utilities/idf/Workspace.hpp>

#include <boost/foreach.hpp>

#include <Vagrant.hxx>

using namespace openstudio;
using namespace openstudio::analysis;
using namespace openstudio::analysisdriver;
using namespace openstudio::model;

TEST_F(CloudFixture,CloudAnalysisDriver_RunPrototypeProject) {
  {
    // open prototype project
    openstudio::path projectDir = vagrantServerPath().parent_path().parent_path() / 
                                   toPath("prototype/pat/PATTest");  
    SimpleProjectOptions options;
    options.setLogLevel(Debug);
    SimpleProject project = openPATProject(projectDir,options).get();

    // save as into new folder
    projectDir = AnalysisDriverTestLibrary::instance().outputDataDirectory() / toPath("CloudAnalysisDriver_RunPrototypeProject");
    if (boost::filesystem::exists(projectDir)) {
      boost::filesystem::remove_all(projectDir);
    }
    OptionalSimpleProject temp = saveAs(project,projectDir);
    ASSERT_TRUE(temp);
    project = temp.get();

    // run it
    CloudAnalysisDriver driver(provider->session(),project);
    driver.run();
    EXPECT_TRUE(driver.lastRunSuccess());

    // check data points
    BOOST_FOREACH(const DataPoint& dataPoint,project.analysis().dataPoints()) {
      EXPECT_TRUE(dataPoint.isComplete());
      EXPECT_TRUE(dataPoint.runType() == DataPointRunType::CloudSlim);
      EXPECT_FALSE(dataPoint.outputAttributes().empty());
      EXPECT_TRUE(dataPoint.directory().empty());
      std::vector<WorkflowStepJob> jobsByStep = project.analysis().problem().getJobsByWorkflowStep(dataPoint);
      unsigned jobCount(0);
      unsigned messageCount(0);
      BOOST_FOREACH(const WorkflowStepJob& jobStep,jobsByStep) {
        if (jobStep.job) {
          ++jobCount;
          messageCount += jobStep.job.get().errors().errors().size();
          messageCount += jobStep.job.get().errors().warnings().size();
          messageCount += jobStep.job.get().errors().infos().size();
          messageCount += jobStep.job.get().errors().initialConditions().size();
          messageCount += jobStep.job.get().errors().finalConditions().size();
        }
      }
      EXPECT_GT(jobCount,0u);
      EXPECT_GT(messageCount,0u);
    }
  }

  {
    // reopen prototype project and make sure data is still there
    openstudio::path projectDir = AnalysisDriverTestLibrary::instance().outputDataDirectory() / toPath("CloudAnalysisDriver_RunPrototypeProject");
    SimpleProjectOptions options;
    options.setLogLevel(Debug);
    SimpleProject project = openPATProject(projectDir,options).get();

    // check data points
    BOOST_FOREACH(const DataPoint& dataPoint,project.analysis().dataPoints()) {
      EXPECT_TRUE(dataPoint.isComplete());
      EXPECT_TRUE(dataPoint.runType() == DataPointRunType::CloudSlim);
      EXPECT_FALSE(dataPoint.outputAttributes().empty());
      EXPECT_TRUE(dataPoint.directory().empty());
      std::vector<WorkflowStepJob> jobsByStep = project.analysis().problem().getJobsByWorkflowStep(dataPoint);
      unsigned jobCount(0);
      unsigned messageCount(0);
      BOOST_FOREACH(const WorkflowStepJob& jobStep,jobsByStep) {
        if (jobStep.job) {
          ++jobCount;
          messageCount += jobStep.job.get().errors().errors().size();
          messageCount += jobStep.job.get().errors().warnings().size();
          messageCount += jobStep.job.get().errors().infos().size();
          messageCount += jobStep.job.get().errors().initialConditions().size();
          messageCount += jobStep.job.get().errors().finalConditions().size();
        }
      }
      EXPECT_GT(jobCount,0u);
      EXPECT_GT(messageCount,0u);
    }

    // now request detailed results
    CloudAnalysisDriver driver(provider->session(),project);
    DataPointVector dataPoints = project.analysis().dataPoints();
    BOOST_FOREACH(DataPoint& dataPoint,dataPoints) {
      driver.requestDownloadDetailedResults(dataPoint);
    }
    driver.waitForFinished();
    EXPECT_TRUE(driver.lastDownloadDetailedResultsSuccess());
    // check outcome
    BOOST_FOREACH(const DataPoint& dataPoint,project.analysis().dataPoints()) {
      EXPECT_TRUE(dataPoint.isComplete());
      EXPECT_TRUE(dataPoint.runType() == DataPointRunType::CloudDetailed);
      EXPECT_FALSE(dataPoint.outputAttributes().empty());
      EXPECT_FALSE(dataPoint.directory().empty());
      EXPECT_TRUE(dataPoint.model());
      if (OptionalModel model = dataPoint.model()) {
        LOG(Debug,"DataPoint '" << dataPoint.name() << "' has " << model->numObjects() 
            << " in its OpenStudio Model.");
      }
    }
  }

  {
    // reopen prototype project and make sure data is still there
    openstudio::path projectDir = AnalysisDriverTestLibrary::instance().outputDataDirectory() / toPath("CloudAnalysisDriver_RunPrototypeProject");
    SimpleProjectOptions options;
    options.setLogLevel(Debug);
    SimpleProject project = openPATProject(projectDir,options).get();

    // check data points
    BOOST_FOREACH(const DataPoint& dataPoint,project.analysis().dataPoints()) {
      EXPECT_TRUE(dataPoint.isComplete());
      EXPECT_TRUE(dataPoint.runType() == DataPointRunType::CloudDetailed);
      EXPECT_FALSE(dataPoint.outputAttributes().empty());
      EXPECT_FALSE(dataPoint.directory().empty());
      EXPECT_TRUE(dataPoint.model());
    }
  }
}

TEST_F(CloudFixture,CloudAnalysisDriver_MinimalRun) {
  // check test library
  EXPECT_FALSE(AnalysisDriverTestLibrary::instance().outputDataDirectory().empty());
  EXPECT_EQ(1u,AnalysisDriverTestLibrary::instance().baselineModelNames().size());
  ASSERT_FALSE(AnalysisDriverTestLibrary::instance().baselineModelNames().empty());
  EXPECT_EQ("example",AnalysisDriverTestLibrary::instance().baselineModelNames()[0]);

  // create a new project
  SimpleProject project = AnalysisDriverTestLibrary::instance().createProject(
      "CloudAnalysisDriver_MinimalRun",
      true,
      LibraryProblem::Default,
      "example");
  
  // make the baseline model (will be selected by default)
  DataPoint baseline = project.baselineDataPoint();
  EXPECT_FALSE(baseline.isComplete());
  EXPECT_TRUE(baseline.runType() == DataPointRunType::Local);

  // run the baseline
  CloudAnalysisDriver driver(provider->session(),project);
  driver.run();
  EXPECT_TRUE(driver.lastRunSuccess());

  EXPECT_TRUE(baseline.isComplete());
  EXPECT_TRUE(baseline.runType() == DataPointRunType::CloudSlim);
  EXPECT_FALSE(baseline.outputAttributes().empty());
  EXPECT_TRUE(baseline.directory().empty());

  // download details
  driver.downloadDetailedResults(baseline);
  EXPECT_TRUE(driver.lastDownloadDetailedResultsSuccess());
  EXPECT_TRUE(baseline.isComplete());
  EXPECT_TRUE(baseline.runType() == DataPointRunType::CloudDetailed);
  EXPECT_FALSE(baseline.outputAttributes().empty());
  EXPECT_FALSE(baseline.directory().empty());
  EXPECT_TRUE(baseline.model());
  EXPECT_TRUE(baseline.workspace());
}

