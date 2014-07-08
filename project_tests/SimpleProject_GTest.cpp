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
#include "SimpleProjectFixture.hpp"

#include <analysisdriver/SimpleProject.hpp>
#include <analysisdriver/AnalysisDriver.hpp>
#include <analysisdriver/AnalysisRunOptions.hpp>
#include <analysisdriver/CurrentAnalysis.hpp>

#include <analysis/Analysis.hpp>
#include <analysis/DataPoint.hpp>

#include <utilities/core/PathHelpers.hpp>

#include <resources.hxx>

#include <boost/foreach.hpp>

TEST_F(SimpleProjectFixture, RelocateTest) {

  openstudio::path path1 = openstudio::toPath("./RelocateTest/SimpleProject1");
  openstudio::path path2 = openstudio::toPath("./RelocateTest/SimpleProject2");
  openstudio::path path3 = openstudio::toPath("./RelocateTest/SimpleProject3");
  openstudio::path save1 = openstudio::toPath("./RelocateTest/SimpleProject1-Save");
  openstudio::path save2 = openstudio::toPath("./RelocateTest/SimpleProject2-Save");

  if (boost::filesystem::exists(path1)) {
    openstudio::removeDirectory(path1);
  }
  if (boost::filesystem::exists(path2)) {
    openstudio::removeDirectory(path2);
  }
  if (boost::filesystem::exists(path3)) {
    openstudio::removeDirectory(path3);
  }
  if (boost::filesystem::exists(save1)) {
    openstudio::removeDirectory(save1);
  }
  if (boost::filesystem::exists(save2)) {
    openstudio::removeDirectory(save2);
  }

  unsigned numDataPoints = 0;

  // First run succeeds
  {
    boost::optional<openstudio::analysisdriver::SimpleProject> project = makePATProject(path1);
    ASSERT_TRUE(project);
    project->clearAllResults();

    openstudio::analysisdriver::AnalysisDriver analysisDriver = project->analysisDriver();
    openstudio::analysisdriver::AnalysisRunOptions runOptions = openstudio::analysisdriver::standardRunOptions(*project);
    openstudio::analysis::Analysis analysis = project->analysis();

    std::vector<openstudio::analysis::DataPoint> dataPoints = analysis.dataPoints();
    numDataPoints = dataPoints.size();

    // DLM: todo, eventually add some alternatives
    EXPECT_EQ(1u, numDataPoints);
    BOOST_FOREACH(const openstudio::analysis::DataPoint& dataPoint, dataPoints){
      EXPECT_FALSE(dataPoint.complete());
    }

    analysisDriver.run(analysis, runOptions);
    analysisDriver.unpauseQueue();
    EXPECT_TRUE(analysisDriver.waitForFinished());

    dataPoints = analysis.dataPoints();
    EXPECT_EQ(numDataPoints, dataPoints.size());
    BOOST_FOREACH(const openstudio::analysis::DataPoint& dataPoint, dataPoints){
      EXPECT_TRUE(dataPoint.complete());
      EXPECT_FALSE(dataPoint.failed());
    }
    
    project->stop();
    project->save();
    project.reset();
  }

  ASSERT_TRUE(openstudio::copyDirectory(path1, save1));
  ASSERT_TRUE(openstudio::copyDirectory(path1, path2));
  ASSERT_TRUE(openstudio::removeDirectory(path1));

  // Second run succeeds, paths are fixed up in memory only
  {
    boost::optional<openstudio::analysisdriver::SimpleProject> project = openstudio::analysisdriver::openPATProject(path2);
    ASSERT_TRUE(project);
    project->clearAllResults();

    openstudio::analysisdriver::AnalysisDriver analysisDriver = project->analysisDriver();
    openstudio::analysisdriver::AnalysisRunOptions runOptions = openstudio::analysisdriver::standardRunOptions(*project);
    openstudio::analysis::Analysis analysis = project->analysis();

    std::vector<openstudio::analysis::DataPoint> dataPoints = analysis.dataPoints();
    EXPECT_EQ(numDataPoints, dataPoints.size());
    BOOST_FOREACH(const openstudio::analysis::DataPoint& dataPoint, dataPoints){
      EXPECT_FALSE(dataPoint.complete());
    }
    
    analysisDriver.run(analysis, runOptions);
    analysisDriver.unpauseQueue();
    EXPECT_TRUE(analysisDriver.waitForFinished());

    dataPoints = analysis.dataPoints();
    EXPECT_EQ(numDataPoints, dataPoints.size());
    BOOST_FOREACH(const openstudio::analysis::DataPoint& dataPoint, dataPoints){
      EXPECT_TRUE(dataPoint.complete());
      EXPECT_FALSE(dataPoint.failed());
    }
    
    project->stop();
    project->save();
    project.reset();
  }

  ASSERT_TRUE(openstudio::copyDirectory(path2, save2));
  ASSERT_TRUE(openstudio::copyDirectory(path2, path3));
  ASSERT_TRUE(openstudio::removeDirectory(path2));

  // Third run fails
  {
    boost::optional<openstudio::analysisdriver::SimpleProject> project = openstudio::analysisdriver::openPATProject(path3);
    ASSERT_TRUE(project);
    project->clearAllResults();

    openstudio::analysisdriver::AnalysisDriver analysisDriver = project->analysisDriver();
    openstudio::analysisdriver::AnalysisRunOptions runOptions = openstudio::analysisdriver::standardRunOptions(*project);
    openstudio::analysis::Analysis analysis = project->analysis();

    std::vector<openstudio::analysis::DataPoint> dataPoints = analysis.dataPoints();
    EXPECT_EQ(numDataPoints, dataPoints.size());
    BOOST_FOREACH(const openstudio::analysis::DataPoint& dataPoint, dataPoints){
      EXPECT_FALSE(dataPoint.complete());
    }
    
    analysisDriver.run(analysis, runOptions);
    analysisDriver.unpauseQueue();
    EXPECT_TRUE(analysisDriver.waitForFinished());

    dataPoints = analysis.dataPoints();
    EXPECT_EQ(numDataPoints, dataPoints.size());
    BOOST_FOREACH(const openstudio::analysis::DataPoint& dataPoint, dataPoints){
      EXPECT_TRUE(dataPoint.complete());
      EXPECT_FALSE(dataPoint.failed());
    }
    
    project->stop();
    project->save();
    project.reset();
  }
}
