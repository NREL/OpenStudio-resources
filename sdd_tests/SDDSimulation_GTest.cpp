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
          energyPlusExePath().parent_path(), openstudio::path(), openstudio::path(), rubyExePath().parent_path(), openstudio::path(),
          openstudio::path(), openstudio::path(), openstudio::path(), openstudio::path(), openstudio::path());


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
// TEST_F(SDDSimulationFixture, 00100_SchoolPrimary_CustomStd_p_xml) {
// 
//   openstudio::path inputPath = Paths::testsPath() / openstudio::toPath("00100-SchoolPrimary-CustomStd - p.xml");
// 
//   openstudio::sdd::ReverseTranslator reverseTranslator;
//   boost::optional<openstudio::model::Model> model = reverseTranslator.loadModel(inputPath);
//   ASSERT_TRUE(model);
// 
//   openstudio::model::Building building = model->getUniqueModelObject<openstudio::model::Building>();
//   EXPECT_EQ(0.0, building.northAxis());
//   EXPECT_FALSE(building.isNorthAxisDefaulted());
// 
//   boost::optional<openstudio::model::RunPeriod> runPeriod = model->getOptionalUniqueModelObject<openstudio::model::RunPeriod>();
//   ASSERT_TRUE(runPeriod);
//   EXPECT_EQ(1, runPeriod->getBeginMonth());
//   EXPECT_EQ(1, runPeriod->getBeginDayOfMonth());
//   EXPECT_EQ(12, runPeriod->getEndMonth());
//   EXPECT_EQ(31, runPeriod->getEndDayOfMonth());
//   EXPECT_FALSE(runPeriod->getUseWeatherFileHolidays());
//   EXPECT_FALSE(runPeriod->getUseWeatherFileDaylightSavings());
//   EXPECT_TRUE(runPeriod->getApplyWeekendHolidayRule());
// 
//   boost::optional<openstudio::model::YearDescription> yearDescription = model->getOptionalUniqueModelObject<openstudio::model::YearDescription>();
//   ASSERT_TRUE(yearDescription);
//   EXPECT_EQ(2009, yearDescription->calendarYear());
// 
//   boost::optional<openstudio::model::SimulationControl> simulationControl = model->getOptionalUniqueModelObject<openstudio::model::SimulationControl>();
//   ASSERT_TRUE(simulationControl);
//   EXPECT_TRUE(simulationControl->runSimulationforWeatherFileRunPeriods());
// 
//   std::vector<openstudio::model::RunPeriodControlSpecialDays> runPeriodControlSpecialDays = model->getModelObjects<openstudio::model::RunPeriodControlSpecialDays>();
//   EXPECT_EQ(10u, runPeriodControlSpecialDays.size());
// 
//   openstudio::SqlFile sql = runSimulation("00100-SchoolPrimary-CustomStd - p.xml");
// 
//   boost::optional<double> totalSiteEnergy = sql.totalSiteEnergy();
//   ASSERT_TRUE(totalSiteEnergy);
//   EXPECT_LT(*totalSiteEnergy, 1000000);
// 
//   //boost::optional<double> hoursCoolingSetpointNotMet = sql.hoursCoolingSetpointNotMet();
//   //ASSERT_TRUE(hoursCoolingSetpointNotMet);
//   //EXPECT_LT(*hoursCoolingSetpointNotMet, 350);
// }
 
 //TEST_F(SDDSimulationFixture, 00100_SchoolPrimary_CustomStd_p_xml_autosize) {
 //  openstudio::SqlFile sql = runSimulation("00100-SchoolPrimary-CustomStd - p.xml",true);
 //
 //  boost::optional<double> totalSiteEnergy = sql.totalSiteEnergy();
 //  ASSERT_TRUE(totalSiteEnergy);
 //  EXPECT_LT(*totalSiteEnergy, 1000000);
 //
 //  //boost::optional<double> hoursCoolingSetpointNotMet = sql.hoursCoolingSetpointNotMet();
 //  //ASSERT_TRUE(hoursCoolingSetpointNotMet);
 //  //EXPECT_LT(*hoursCoolingSetpointNotMet, 350);
 //}
 //

 TEST_F(SDDSimulationFixture, 010012_SchSml_CECStd_ab_xml) {
   openstudio::SqlFile sql = runSimulation("010012-SchSml-CECStd - ab.xml");
 
   boost::optional<double> totalSiteEnergy = sql.totalSiteEnergy();
   ASSERT_TRUE(totalSiteEnergy);
   EXPECT_LT(*totalSiteEnergy, 1000000);
 }


010012-SchSml-CECStd - ap.xml
010012-SchSml-CECStd - zb.xml
010112-SchSml-PSZ - ab.xml
010112-SchSml-PSZ - ap.xml
010112-SchSml-PSZ - zb.xml
010212-SchSml-PVAVAirZnSys - ab.xml
010212-SchSml-PVAVAirZnSys - ap.xml
010212-SchSml-PVAVAirZnSys - zb.xml
010312-SchSml-VAVFluidZnSys - ab.xml
010312-SchSml-VAVFluidZnSys - ap.xml
010312-SchSml-VAVFluidZnSys - zb.xml
020012-OffSml-CECStd - ab.xml
020012-OffSml-CECStd - ap.xml
020012-OffSml-CECStd - zb.xml
020212-OffSml-SimpleGeometry - ab.xml
020212-OffSml-SimpleGeometry - ap.xml
020212-OffSml-SimpleGeometry - zb.xml
030012-OffMed-CECStd - ab.xml
030012-OffMed-CECStd - ap.xml
030012-OffMed-CECStd - zb.xml
030212-OffMed-SimpleGeometry - ab.xml
030212-OffMed-SimpleGeometry - ap.xml
030212-OffMed-SimpleGeometry - zb.xml
040012-OffLrg-CECStd - ab.xml
040012-OffLrg-CECStd - ap.xml
040012-OffLrg-CECStd - zb.xml
040112-OffLrg-VAVPriSec - ab.xml
040112-OffLrg-VAVPriSec - ap.xml
040112-OffLrg-VAVPriSec - zb.xml
040112-OffLrg-VAVPriSec - zp.xml
050012-RetlMed-CECStd - ab.xml
050012-RetlMed-CECStd - ap.xml
050012-RetlMed-CECStd - zb.xml
070012-HotSml-CECStd - ab.xml
070012-HotSml-CECStd - ap.xml
070012-HotSml-CECStd - zb.xml
080012-Whse-CECStd - ab.xml
080012-Whse-CECStd - ap.xml
080012-Whse-CECStd - zb.xml
090012-RetlLrg-CECStd - ab.xml
090012-RetlLrg-CECStd - ap.xml
090012-RetlLrg-CECStd - zb.xml

