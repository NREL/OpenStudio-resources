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
*  Likey = cense along with this library; if not, write to the Free Software
*  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
**********************************************************************/

#include <gtest/gtest.h>
#include "RunManagerTestFixture.hpp"
#include <runmanager/Test/ToolBin.hxx>
#include <resources.hxx>

#include <runmanager/lib/JobFactory.hpp>
#include <runmanager/lib/EnergyPlusPostProcessJob.hpp>
#include <runmanager/lib/RunManager.hpp>
#include <runmanager/lib/Workflow.hpp>

#include <model/Model.hpp>

#include <utilities/idf/IdfFile.hpp>
#include <utilities/idf/IdfObject.hpp>
#include <utilities/data/EndUses.hpp>
#include <utilities/data/Attribute.hpp>
#include <utilities/sql/SqlFile.hpp>

#include <boost/filesystem/path.hpp>

#include <QDir>

using openstudio::Attribute;
using openstudio::IdfFile;
using openstudio::IdfObject;
using openstudio::IddObjectType;
using openstudio::SqlFile;

TEST_F(RunManagerTestFixture, BasementAndSlabJobs)
{

  openstudio::path outdir = openstudio::toPath(QDir::tempPath()) / openstudio::toPath("BasementandSlabJobsTest");
  openstudio::path outdirslab = outdir / openstudio::toPath("slab");
  openstudio::path outdirbasement = outdir / openstudio::toPath("basement");

  boost::filesystem::remove_all(outdir);

  boost::filesystem::create_directories(outdirslab);
  boost::filesystem::create_directories(outdirbasement);

  openstudio::path db = outdir / openstudio::toPath("BasementandSlabJobsTestDB");
  openstudio::runmanager::RunManager kit(db, true);

  openstudio::path slabfile = resourcesPath() / openstudio::toPath("runmanager") / openstudio::toPath("5ZoneAirCooledWithSlab.idf");
  openstudio::path basementfile = resourcesPath() / openstudio::toPath("runmanager") / openstudio::toPath("LgOffVAVusingBasement.idf");
  openstudio::path weatherdir = resourcesPath() / openstudio::toPath("runmanager");

  openstudio::runmanager::Workflow workflowslab("expandobjects->slab->energyplus");
  workflowslab.setInputFiles(slabfile, weatherdir);
  
  openstudio::runmanager::Workflow workflowbasement("expandobjects->basement->energyplus");
  workflowbasement.setInputFiles(basementfile, weatherdir);

  // Build list of tools
  openstudio::runmanager::Tools tools 
    = openstudio::runmanager::ConfigOptions::makeTools(energyPlusExePath().parent_path(), openstudio::path(), openstudio::path(), openstudio::path(), openstudio::path());

  workflowslab.add(tools);
  workflowbasement.add(tools);

  openstudio::runmanager::Job slabjob = workflowslab.create(outdirslab);
  openstudio::runmanager::Job basementjob = workflowbasement.create(outdirbasement);

  kit.enqueue(slabjob, true);
  kit.enqueue(basementjob, true);

  kit.waitForFinished();


  EXPECT_TRUE(slabjob.treeErrors().succeeded());
  EXPECT_TRUE(basementjob.treeErrors().succeeded());
}

