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
#include "CONTAMSimulationFixture.hpp"

#include <resources.hxx>
#include <OpenStudio.hxx>
#include <contam_tests/CONTAM.hxx>

#include <model/Model.hpp>
#include <model/Space.hpp>
#include <model/ThermalZone.hpp>
#include <model/ThermalZone_Impl.hpp>
#include <model/HVACTemplates.hpp>
#include <model/AirLoopHVAC.hpp>
#include <model/AirLoopHVAC_Impl.hpp>
#include <model/ThermostatSetpointDualSetpoint.hpp>
#include <model/ThermostatSetpointDualSetpoint_Impl.hpp>
#include <model/SetpointManagerSingleZoneReheat.hpp>
#include <model/SetpointManagerSingleZoneReheat_Impl.hpp>
#include <model/SizingZone.hpp>
#include <model/DesignSpecificationOutdoorAir.hpp>
#include <model/Building.hpp>
#include <model/Building_Impl.hpp>
#include <model/SpaceType.hpp>
#include <model/DesignDay.hpp>
#include <model/DesignDay_Impl.hpp>
#include <model/OutputVariable.hpp>
#include <model/Node.hpp>
#include <model/Node_Impl.hpp>
#include <model/PortList.hpp>
#include <model/BuildingStory.hpp>

#include <osversion/VersionTranslator.hpp>

#include <energyplus/ReverseTranslator.hpp>

#include <contam/ForwardTranslator.hpp>


#include <runmanager/lib/JobFactory.hpp>
#include <runmanager/lib/RunManager.hpp>
#include <runmanager/lib/Workflow.hpp>
#include <runmanager/lib/RubyJobUtils.hpp>

#include <utilities/sql/SqlFile.hpp>
#include <utilities/geometry/Point3d.hpp>
#include <utilities/data/TimeSeries.hpp>
#include <utilities/core/System.hpp>

#include <QProcess>

#include <boost/filesystem.hpp>
#include <boost/foreach.hpp>
#include <boost/regex.hpp>
#include <boost/algorithm/string.hpp>

using namespace openstudio;

openstudio::SqlFile runEnergyPlus(const openstudio::path& filePath)
{ 
  openstudio::path outdir = contamRunPath(); 

  outdir /= filePath.filename();
  boost::filesystem::remove_all(outdir); // Clean up test dir before starting
  boost::filesystem::create_directories(outdir);

  openstudio::path p(openstudio::toPath("rm.db"));

  openstudio::path db = outdir / p;
  openstudio::runmanager::RunManager kit(db, true);
  kit.setPaused(true);

  openstudio::runmanager::Workflow wf;

  openstudio::runmanager::Tools tools 
    = openstudio::runmanager::ConfigOptions::makeTools(
        energyPlusExePath().parent_path(), openstudio::path(), openstudio::path(), rubyExePath().parent_path(), openstudio::path(),
        openstudio::path(), openstudio::path(), openstudio::path(), openstudio::path(), openstudio::path());


  openstudio::path epw = (resourcesPath() / openstudio::toPath("weatherdata") / openstudio::toPath("USA_IL_Chicago-OHare.Intl.AP.725300_TMY3.epw"));

  wf.addWorkflow(openstudio::runmanager::Workflow("ModelToIdf->EnergyPlus"));

  wf.add(tools);
  openstudio::runmanager::Job j = wf.create(outdir, filePath, epw);

  kit.enqueue(j, false);

  kit.setPaused(false);

  kit.waitForFinished();

  return openstudio::SqlFile(j.treeAllFiles().getLastByFilename("eplusout.sql").fullPath);
}

TEST_F(CONTAMSimulationFixture, CONTAM_Demo_2012) {

  // load model from template
  osversion::VersionTranslator vt;
  boost::optional<model::Model> optionalModel = vt.loadModel(contamTemplatePath());
  ASSERT_TRUE(optionalModel);
  model::Model model = optionalModel.get();

  // add design days
  openstudio::path ddyPath = (resourcesPath() / openstudio::toPath("weatherdata") / openstudio::toPath("USA_IL_Chicago-OHare.Intl.AP.725300_TMY3.ddy"));
  boost::optional<Workspace> ddyWorkspace = Workspace::load(ddyPath);
  ASSERT_TRUE(ddyWorkspace);

  energyplus::ReverseTranslator rt;
  boost::optional<model::Model> ddyModel = rt.translateWorkspace(*ddyWorkspace);
  ASSERT_TRUE(ddyModel);
  BOOST_FOREACH(model::DesignDay designDay, ddyModel->getModelObjects<model::DesignDay>()){
    model.addObject(designDay);
  }

  // set outdoor air specifications
  model::Building building = model.getUniqueModelObject<model::Building>();
  boost::optional<model::SpaceType> spaceType = building.spaceType();
  ASSERT_TRUE(spaceType);
  boost::optional<model::DesignSpecificationOutdoorAir> oa = spaceType->designSpecificationOutdoorAir();
  ASSERT_TRUE(oa);

  EXPECT_TRUE(oa->setOutdoorAirMethod("Sum"));
  EXPECT_TRUE(oa->setOutdoorAirFlowperPerson(0.0));
  EXPECT_TRUE(oa->setOutdoorAirFlowperFloorArea(0.00508)); // 1 cfm/ft^2 = 0.00508 m/s
  EXPECT_TRUE(oa->setOutdoorAirFlowRate(0.0));
  EXPECT_TRUE(oa->setOutdoorAirFlowAirChangesperHour(0.0));

  // create geometry
  double floorHeight = 3.0;

  model::BuildingStory story1(model);
  story1.setName("Story 1");
  story1.setNominalZCoordinate(0.0);
  story1.setNominalFloortoFloorHeight(floorHeight);

  std::vector<Point3d> points;
  points.push_back(Point3d(0,0,0));
  points.push_back(Point3d(0,17,0));
  points.push_back(Point3d(8,17,0));
  points.push_back(Point3d(8,10,0));
  points.push_back(Point3d(8,0,0));

  boost::optional<model::Space> library = model::Space::fromFloorPrint(points, floorHeight, model);
  ASSERT_TRUE(library);
  library->setName("Library");

  points.clear();
  points.push_back(Point3d(8,10,0));
  points.push_back(Point3d(8,17,0));
  points.push_back(Point3d(18,17,0));
  points.push_back(Point3d(18,10,0));
  points.push_back(Point3d(11,10,0));

  boost::optional<model::Space> office2 = model::Space::fromFloorPrint(points, floorHeight, model);
  ASSERT_TRUE(office2);
  office2->setName("Office 2");

  points.clear();
  points.push_back(Point3d(8,0,0));
  points.push_back(Point3d(8,10,0));
  points.push_back(Point3d(11,10,0));
  points.push_back(Point3d(11,0,0));

  boost::optional<model::Space> hallway = model::Space::fromFloorPrint(points, floorHeight, model);
  ASSERT_TRUE(hallway);
  hallway->setName("Hallway");

  points.clear();
  points.push_back(Point3d(11,0,0));
  points.push_back(Point3d(11,10,0));
  points.push_back(Point3d(18,10,0));
  points.push_back(Point3d(18,0,0));

  boost::optional<model::Space> office1 = model::Space::fromFloorPrint(points, floorHeight, model);
  ASSERT_TRUE(office1);
  office1->setName("Office 1");

  library->matchSurfaces(*office2);
  library->matchSurfaces(*hallway);
  hallway->matchSurfaces(*office1);
  hallway->matchSurfaces(*office2);
  office1->matchSurfaces(*office2);

  // find thermostat
  boost::optional<model::ThermostatSetpointDualSetpoint> thermostat;
  BOOST_FOREACH(model::ThermostatSetpointDualSetpoint t, model.getModelObjects<model::ThermostatSetpointDualSetpoint>()){
    thermostat = t;
    break;
  }
  ASSERT_TRUE(thermostat);
  
  // create  thermal zones
  model::ThermalZone libraryZone(model);
  model::SizingZone librarySizing(model, libraryZone);
  libraryZone.setName("Library Zone");
  libraryZone.setThermostatSetpointDualSetpoint(*thermostat);
  library->setThermalZone(libraryZone);
  library->setBuildingStory(story1);

  model::ThermalZone hallwayZone(model);
  //model::SizingZone hallwaySizing(model, hallwayZone);
  hallwayZone.setName("Hallway Zone");
  //hallwayZone.setThermostatSetpointDualSetpoint(*thermostat);
  hallway->setThermalZone(hallwayZone);
  hallway->setBuildingStory(story1);

  model::ThermalZone office1Zone(model);
  model::SizingZone office1Sizing(model, office1Zone);
  office1Zone.setName("Office 1 Zone");
  office1Zone.setThermostatSetpointDualSetpoint(*thermostat);
  office1->setThermalZone(office1Zone);
  office1->setBuildingStory(story1);

  model::ThermalZone office2Zone(model);
  model::SizingZone office2Sizing(model, office2Zone);
  office2Zone.setName("Office 2 Zone");
  office2Zone.setThermostatSetpointDualSetpoint(*thermostat);
  office2->setThermalZone(office2Zone);
  office2->setBuildingStory(story1);

  // add the air system
  model::Loop loop = addSystemType3(model);
  model::AirLoopHVAC airLoop = loop.cast<model::AirLoopHVAC>();
  airLoop.addBranchForZone(libraryZone);
  airLoop.addBranchForZone(office1Zone);
  airLoop.addBranchForZone(office2Zone);

  boost::optional<model::SetpointManagerSingleZoneReheat> setpointManager;
  BOOST_FOREACH(model::SetpointManagerSingleZoneReheat t, model.getModelObjects<model::SetpointManagerSingleZoneReheat>()){
    setpointManager = t;
    break;
  }
  ASSERT_TRUE(setpointManager);
  setpointManager->setControlZone(libraryZone);

  // request report variables we will need
  model::OutputVariable("System Node MassFlowRate", model);
  model::OutputVariable("System Node Volume Flow Rate Standard Density", model);
  model::OutputVariable("System Node Volume Flow Rate Current Density", model);
  model::OutputVariable("AirLoopHVAC Actual Outdoor Air Fraction", model);
  
  // save the openstudio model
  openstudio::path modelPath = contamOSMPath() / toPath("CONTAM_Demo_2012.osm");

  bool test = model.save(modelPath, true);
  ASSERT_TRUE(test);

  // run energyplus
  openstudio::SqlFile sqlFile = runEnergyPlus(modelPath);
  model.setSqlFile(sqlFile);

  std::string envPeriod; 
  BOOST_FOREACH(std::string t, sqlFile.availableEnvPeriods()){
    envPeriod = t; // should only ever be one
    break;
  }

  // get sizing results, get flow rate schedules for each zone's inlet, return, and exhaust nodes
  // This should be moved to inside the contam translator
  BOOST_FOREACH(model::ThermalZone thermalZone, model.getModelObjects<model::ThermalZone>()){
    // todo: this does not include OA from zone equipment (PTAC, PTHP, etc) or exhaust fans
    
    boost::optional<model::Node> returnAirNode;
    boost::optional<model::ModelObject> returnAirModelObject = thermalZone.returnAirModelObject();
    if (returnAirModelObject){
      returnAirNode = returnAirModelObject->optionalCast<model::Node>();
    }
    if (returnAirNode){
      std::string keyValue = returnAirNode->name().get();
      keyValue = boost::regex_replace(keyValue, boost::regex("([a-z])"),"\\u$1");
      boost::optional<TimeSeries> timeSeries = sqlFile.timeSeries(envPeriod, "Hourly", "System Node MassFlowRate", keyValue);
      if (timeSeries){
        openstudio::Vector values = timeSeries->values();
      }
    }

    boost::optional<model::Node> supplyAirNode;
    boost::optional<model::ModelObject> supplyAirModelObject = thermalZone.inletPortList().airLoopHVACModelObject();
    if (supplyAirModelObject){
      supplyAirNode = supplyAirModelObject->optionalCast<model::Node>();
    }
    if (supplyAirNode){
      std::string keyValue = supplyAirNode->name().get();
      keyValue = boost::regex_replace(keyValue, boost::regex("([a-z])"),"\\u$1");
      boost::optional<TimeSeries> timeSeries = sqlFile.timeSeries(envPeriod, "Hourly", "System Node MassFlowRate", keyValue);
      if (timeSeries){
        openstudio::Vector values = timeSeries->values();
      }
    }
  }

  // convert to prj file
  openstudio::path prjPath = contamOSMPath() / toPath("CONTAM_Demo_2012.prj");
  openstudio::path mapPath = contamOSMPath() / toPath("CONTAM_Demo_2012.map");
  test = openstudio::contam::ForwardTranslator::modelToContam(model, prjPath, mapPath);
  ASSERT_TRUE(test);

  // run contam on prj file, use contamExePath()
  {
    QProcess contamProcess;
    contamProcess.start(toQString(contamExePath()), QStringList() << toQString(prjPath));
    test = contamProcess.waitForStarted(-1);
    ASSERT_TRUE(test);
    test = contamProcess.waitForFinished(-1);
    ASSERT_TRUE(test);
  }

  // put this in so we can check contamx is done before simread is run
  // DLM: these are being called in the correct order but no simread output is created
  //openstudio::System::msleep(120000);

  // run simread on prj file, use simreadExePath()
  {
    // write out input commands for simread
    openstudio::path simreadInputPath = contamOSMPath() / toPath("CONTAM_Demo_2012.sri");
    QFile file(toQString(simreadInputPath));
    file.open(QIODevice::WriteOnly | QIODevice::Text);
    QTextStream out(&file);
    //out << "n\nn\n"; // This will get the xrf file but not much else, only works with no contaminant simulation
    out << "y\n\ny\n\n"; // This will get the lfr and nfr, only works with no contaminant simulation
    file.close(); 

    QProcess simreadProcess;
    simreadProcess.setStandardInputFile(toQString(simreadInputPath));
    simreadProcess.start(toQString(simreadExePath()), QStringList() << toQString(prjPath));
    test = simreadProcess.waitForStarted(-1);
    ASSERT_TRUE(test);
    test = simreadProcess.waitForFinished(-1);
    ASSERT_TRUE(test);
  }

  // todo: check that contam runs successfully, check results
}

