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

#include <iostream>
#include <fstream>
#include <string>
#include <gtest/gtest.h>
#include "RadianceSimulationFixture.hpp"
#include <radiance_tests/RadianceBin.hxx> 
#include <runmanager/Test/ToolBin.hxx>

#include <runmanager/lib/JobFactory.hpp>
#include <runmanager/lib/RunManager.hpp>
#include <runmanager/lib/Workflow.hpp>
#include <runmanager/lib/WorkItem.hpp>
#include <runmanager/lib/RubyJobUtils.hpp>

#include <utilities/core/Application.hpp>
#include <utilities/core/ApplicationPathHelpers.hpp>
#include <utilities/core/System.hpp>
#include <utilities/core/Logger.hpp>
#include <utilities/core/Path.hpp>

#include <utilities/sql/SqlFile.hpp>

#include <boost/filesystem.hpp>

#include <resources.hxx>
#include <OpenStudio.hxx>

#include <QDir>

#ifdef _MSC_VER
#include <Windows.h>
#endif

std::vector<openstudio::SqlFile> runSimulationNTimes(const std::string t_filename, unsigned N, const std::string& epwName = "USA_IL_Chicago-OHare.Intl.AP.725300_TMY3.epw")
{ 
  openstudio::path filePath = Paths::testsPath() / openstudio::toPath(t_filename);
  openstudio::path outdir = Paths::testRunPath(); 

  outdir /= filePath.filename();
  boost::filesystem::remove_all(outdir); // Clean up test dir before starting
  boost::filesystem::create_directories(outdir);

  openstudio::path p(openstudio::toPath("rm.db"));

  openstudio::path db = outdir / p;
  openstudio::runmanager::RunManager kit(db, true);
  kit.setPaused(true);

  openstudio::runmanager::Tools tools 
    = openstudio::runmanager::ConfigOptions::makeTools(
        energyPlusExePath().parent_path(), openstudio::path(), openstudio::path(), rubyExePath().parent_path(), openstudio::path(),
        openstudio::path(), openstudio::path(), openstudio::path(), openstudio::path(), openstudio::path());

  openstudio::path epw = (resourcesPath() / openstudio::toPath("weatherdata") / openstudio::toPath(epwName));

  std::vector<openstudio::runmanager::Job> jobs;
  for (unsigned i = 0; i < N; ++i){

    openstudio::runmanager::Workflow wf;

    std::string numString = boost::lexical_cast<std::string>(i);

    openstudio::path outdir2 = outdir / openstudio::toPath(numString); 

    boost::filesystem::create_directories(outdir2);

    if (filePath.extension() == openstudio::toPath(".rb"))
    {
      openstudio::runmanager::RubyJobBuilder rubyJobBuilder;

      rubyJobBuilder.setScriptFile(filePath);
      rubyJobBuilder.addToolArgument("-I" + rubyOpenStudioDir()) ;
      rubyJobBuilder.addToolArgument("-I" + openstudio::toString(sourcePath()) + "/model/simulationtests/") ;
      rubyJobBuilder.copyRequiredFiles("rb", "osm", "in.epw");
      rubyJobBuilder.addToWorkflow(wf);
    }

    openstudio::runmanager::WorkItem radItem = openstudio::runmanager::Workflow::radianceDaylightCalculations(openstudio::getOpenStudioRubyIncludePath(), Paths::radPath());
    wf.addJob(radItem);

    wf.addWorkflow(openstudio::runmanager::Workflow("ModelToIdf->EnergyPlusPreProcess->EnergyPlus"));

    wf.add(tools);
    openstudio::runmanager::Job j = wf.create(outdir2, filePath, epw);

    jobs.push_back(j);

    kit.enqueue(j, false);
  }

  kit.setPaused(false);

  kit.waitForFinished();

  std::vector<openstudio::SqlFile> result;
  for (unsigned i = 0; i < N; ++i){
    result.push_back(openstudio::SqlFile(jobs[i].treeAllFiles().getLastByFilename("eplusout.sql").fullPath));
  }

  return result;
}

openstudio::SqlFile runSimulation(const std::string t_filename)
{
  std::vector<openstudio::SqlFile> sqls = runSimulationNTimes(t_filename, 1);
  return sqls.front();
}

TEST_F(RadianceSimulationFixture, daylighting_no_shades_rb) {
  unsigned N = 1;
  std::vector<openstudio::SqlFile> sqls = runSimulationNTimes("daylighting_no_shades.rb", N);
  ASSERT_EQ(N, sqls.size());

  boost::optional<double> totalSiteEnergy;
  boost::optional<double> hoursHeatingSetpointNotMet;
  boost::optional<double> hoursCoolingSetpointNotMet;
  for (unsigned i = 0; i < N; ++i){
    if (!totalSiteEnergy){
      totalSiteEnergy = sqls[i].totalSiteEnergy();
      ASSERT_TRUE(totalSiteEnergy);
      EXPECT_LT(*totalSiteEnergy, 1000000);

      hoursHeatingSetpointNotMet = sqls[i].hoursHeatingSetpointNotMet();
      ASSERT_TRUE(hoursHeatingSetpointNotMet);
      EXPECT_LT(*hoursHeatingSetpointNotMet, 350);

      hoursCoolingSetpointNotMet = sqls[i].hoursCoolingSetpointNotMet();
      ASSERT_TRUE(hoursCoolingSetpointNotMet);
      EXPECT_LT(*hoursCoolingSetpointNotMet, 350);
    }else{
      boost::optional<double> test = sqls[i].totalSiteEnergy();
      ASSERT_TRUE(totalSiteEnergy);
      ASSERT_TRUE(test);
      EXPECT_DOUBLE_EQ(*totalSiteEnergy, *test);

      test = sqls[i].hoursHeatingSetpointNotMet();
      ASSERT_TRUE(hoursHeatingSetpointNotMet);
      ASSERT_TRUE(test);
      EXPECT_DOUBLE_EQ(*hoursHeatingSetpointNotMet, *test);

      test = sqls[i].hoursCoolingSetpointNotMet();
      ASSERT_TRUE(hoursCoolingSetpointNotMet);
      ASSERT_TRUE(test);
      EXPECT_DOUBLE_EQ(*hoursCoolingSetpointNotMet, *test);
    }
  }
}


TEST_F(RadianceSimulationFixture, daylighting_shades_rb) {
  unsigned N = 1;
  std::vector<openstudio::SqlFile> sqls = runSimulationNTimes("daylighting_shades.rb", N);
  ASSERT_EQ(N, sqls.size());

  boost::optional<double> totalSiteEnergy;
  boost::optional<double> hoursHeatingSetpointNotMet;
  boost::optional<double> hoursCoolingSetpointNotMet;
  for (unsigned i = 0; i < N; ++i){
    if (!totalSiteEnergy){
      totalSiteEnergy = sqls[i].totalSiteEnergy();
      ASSERT_TRUE(totalSiteEnergy);
      EXPECT_LT(*totalSiteEnergy, 1000000);

      hoursHeatingSetpointNotMet = sqls[i].hoursHeatingSetpointNotMet();
      ASSERT_TRUE(hoursHeatingSetpointNotMet);
      EXPECT_LT(*hoursHeatingSetpointNotMet, 350);

      hoursCoolingSetpointNotMet = sqls[i].hoursCoolingSetpointNotMet();
      ASSERT_TRUE(hoursCoolingSetpointNotMet);
      EXPECT_LT(*hoursCoolingSetpointNotMet, 350);
    }else{
      boost::optional<double> test = sqls[i].totalSiteEnergy();
      ASSERT_TRUE(totalSiteEnergy);
      ASSERT_TRUE(test);
      EXPECT_DOUBLE_EQ(*totalSiteEnergy, *test);

      test = sqls[i].hoursHeatingSetpointNotMet();
      ASSERT_TRUE(hoursHeatingSetpointNotMet);
      ASSERT_TRUE(test);
      EXPECT_DOUBLE_EQ(*hoursHeatingSetpointNotMet, *test);

      test = sqls[i].hoursCoolingSetpointNotMet();
      ASSERT_TRUE(hoursCoolingSetpointNotMet);
      ASSERT_TRUE(test);
      EXPECT_DOUBLE_EQ(*hoursCoolingSetpointNotMet, *test);
    }
  }
}
