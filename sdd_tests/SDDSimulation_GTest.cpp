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
#include "SDDSimulationFixture.hpp"
#include <sdd_tests/SDDBin.hxx> 
#include <runmanager/Test/ToolBin.hxx>

#include <sdd/ReverseTranslator.hpp>
#include <sdd/ForwardTranslator.hpp>

#include <model/Model.hpp>
#include <model/Facility.hpp>
#include <model/Facility_Impl.hpp>
#include <model/Building.hpp>
#include <model/Building_Impl.hpp>
#include <model/ThermalZone.hpp>
#include <model/ThermalZone_Impl.hpp>
#include <model/Space.hpp>
#include <model/Space_Impl.hpp>
#include <model/Surface.hpp>
#include <model/Surface_Impl.hpp>
#include <model/SimulationControl.hpp>
#include <model/SimulationControl_Impl.hpp>
#include <model/RunPeriod.hpp>
#include <model/RunPeriod_Impl.hpp>
#include <model/YearDescription.hpp>
#include <model/YearDescription_Impl.hpp>
#include <model/RunPeriodControlSpecialDays.hpp>
#include <model/RunPeriodControlSpecialDays_Impl.hpp>

#include <runmanager/lib/JobFactory.hpp>
#include <runmanager/lib/RunManager.hpp>
#include <runmanager/lib/Workflow.hpp>
#include <runmanager/lib/RubyJobUtils.hpp>
#include <runmanager/lib/JobParam.hpp>

#include <utilities/core/Application.hpp>
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

std::vector<openstudio::SqlFile> runSimulationNTimes(const std::string t_filename, unsigned N, const bool masterAutosize = false)
{ 
  openstudio::path filePath = Paths::testsPath() / openstudio::toPath(t_filename);
  openstudio::path outdir = Paths::testRunPath(); 
  openstudio::path scriptPath = Paths::testsPath() / openstudio::toPath("translate_sdd.rb");

  if( masterAutosize )
  {
    outdir /= openstudio::toPath( openstudio::toString(filePath.filename()) + ".autosize" );
  }
  else
  {
    outdir /= filePath.filename();
  }
  boost::filesystem::remove_all(outdir); // Clean up test dir before starting
  boost::filesystem::create_directories(outdir);

  openstudio::path p(openstudio::toPath("rm.db"));

  openstudio::path db = outdir / p;
  openstudio::runmanager::RunManager kit(db, true);
  kit.setPaused(true);

  std::vector<openstudio::runmanager::Job> jobs;
  for (unsigned i = 0; i < N; ++i){

    openstudio::runmanager::Workflow wf;

    std::string numString = boost::lexical_cast<std::string>(i);

    openstudio::path outdir2 = outdir / openstudio::toPath(numString); 

    openstudio::runmanager::Tools tools 
      = openstudio::runmanager::ConfigOptions::makeTools(
          energyPlusExePath().parent_path(), openstudio::path(), openstudio::path(), rubyExePath().parent_path(), openstudio::path());


    openstudio::path epw = (resourcesPath() / openstudio::toPath("weatherdata") / openstudio::toPath("SACRAMENTO-EXECUTIVE_724830_CZ2010.epw"));

    openstudio::runmanager::RubyJobBuilder rubyJobBuilder;

    rubyJobBuilder.setScriptFile(scriptPath);
    rubyJobBuilder.addToolArgument("-I" + rubyOpenStudioDir()) ;
    rubyJobBuilder.copyRequiredFiles("rb", "osm", "in.epw");
    rubyJobBuilder.addScriptParameter("sdd_path",openstudio::toString(filePath));
    if( masterAutosize )
    {
      rubyJobBuilder.addScriptParameter("master_autosize","true");
    }
    else
    {
      rubyJobBuilder.addScriptParameter("master_autosize","false");
    }

    rubyJobBuilder.addToWorkflow(wf);

    // temp code
    wf.addParam(openstudio::runmanager::JobParam("keepRunControlSpecialDays"));

    wf.addWorkflow(openstudio::runmanager::Workflow("ModelToIdf->EnergyPlus"));

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

openstudio::SqlFile runSimulation(const std::string t_filename, const bool masterAutosize = false)
{ 
  std::vector<openstudio::SqlFile>  sqls = runSimulationNTimes(t_filename, 1, masterAutosize);
  return sqls.front();
}

TEST_F(SDDSimulationFixture, 070015_HotSml_Run03_ab_xml) {
  openstudio::SqlFile sql = runSimulation("070015-HotSml-Run03 - ab.xml");

  boost::optional<double> totalSiteEnergy = sql.totalSiteEnergy();
  ASSERT_TRUE(totalSiteEnergy);
  EXPECT_LT(*totalSiteEnergy, 1000000);
}

TEST_F(SDDSimulationFixture, CSUS_Phase_2_8_19_15_final_v6_7_rlh_ap_xml) {
  openstudio::SqlFile sql = runSimulation("CSUS Phase 2 - 8-19-15 final v6_7-rlh - ap.xml");

  boost::optional<double> totalSiteEnergy = sql.totalSiteEnergy();
  ASSERT_TRUE(totalSiteEnergy);
  EXPECT_LT(*totalSiteEnergy, 1000000);
}

TEST_F(SDDSimulationFixture, fixed_dual_sp_xml) {
  openstudio::SqlFile sql = runSimulation("fixed_dual_sp.xml");

  boost::optional<double> totalSiteEnergy = sql.totalSiteEnergy();
  ASSERT_TRUE(totalSiteEnergy);
  EXPECT_LT(*totalSiteEnergy, 1000000);
}

TEST_F(SDDSimulationFixture, scheduled_dual_sp_xml) {
  openstudio::SqlFile sql = runSimulation("scheduled_dual_sp.xml");

  boost::optional<double> totalSiteEnergy = sql.totalSiteEnergy();
  ASSERT_TRUE(totalSiteEnergy);
  EXPECT_LT(*totalSiteEnergy, 1000000);
}

//TEST_F(SDDSimulationFixture, RetlSml_DOAS_FPFC_ap_Issue1220_xml) {
//  openstudio::SqlFile sql = runSimulation("RetlSml-DOAS_FPFC_ap_Issue1220.xml");
//
//  boost::optional<double> totalSiteEnergy = sql.totalSiteEnergy();
//  ASSERT_TRUE(totalSiteEnergy);
//  EXPECT_LT(*totalSiteEnergy, 1000000);
//}

