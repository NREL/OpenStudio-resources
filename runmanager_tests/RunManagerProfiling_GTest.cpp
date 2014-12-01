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
#include "RunManagerTestFixture.hpp"
#include "SignalListener.hpp"
#include <runmanager/Test/ToolBin.hxx>
#include <runmanager/lib/JobFactory.hpp>
#include <runmanager/lib/RunManager.hpp>
#include <runmanager/lib/Workflow.hpp>
#include <runmanager/lib/RubyJobUtils.hpp>

#include <utilities/core/Application.hpp>
#include <utilities/core/System.hpp>
#include <utilities/core/Logger.hpp>

#include <resources.hxx>
#include <OpenStudio.hxx>

#include <boost/filesystem/path.hpp>

#include <QDir>

#include <algorithm>

#ifdef _MSC_VER
#include <Windows.h>
#endif

using namespace openstudio;
using namespace runmanager;

void RunManagerTestFixture::run_profiling_test(int t_numRubyVars,
                                               int t_workflows,
                                               int t_maxLocalJobs,
                                               PauseType t_pauseType)
{
  openstudio::path outdir = resourcesPath() / openstudio::toPath("../../../rm_profiling");
  // openstudio::path outdir = resourcesPath() / openstudio::toPath("runmanager/profiling");
  boost::filesystem::create_directory(outdir);
  std::stringstream ss;
  ss << t_numRubyVars << "_ruby_vars_" << t_maxLocalJobs << "_concurrent_jobs_pause_" << t_pauseType.valueName();
  outdir /= openstudio::toPath(ss.str());

  if (boost::filesystem::exists(outdir)) {
    boost::filesystem::remove_all(outdir);
  }
  boost::filesystem::create_directory(outdir);

  openstudio::path db = outdir / openstudio::toPath("rm.db");
  RunManager rm(db,false,false,false);
  if (t_pauseType != PauseType::none) {
    rm.setPaused(true);
  }

  ConfigOptions options = rm.getConfigOptions();
  options.setMaxLocalJobs(t_maxLocalJobs);
  rm.setConfigOptions(options);

  t_numRubyVars = std::max<int>(0,t_numRubyVars);
  t_numRubyVars = std::min<int>(100,t_numRubyVars);
  bool countRuby = (t_numRubyVars <= 50);
  int fullCount(0);
  if (countRuby) {
    fullCount = t_numRubyVars;
  }
  else {
    fullCount = 100 - t_numRubyVars;
  }

  openstudio::runmanager::test::Test_Listener listener;
  openstudio::path rubyscriptfile = resourcesPath() / openstudio::toPath("runmanager/test.rb");
  for (int i = 0; i < t_workflows; ++i) {

    // assemble workflow
    openstudio::runmanager::Workflow wf;

    // variables
    int cnt = 0;
    for (int j = 0; j < 100; ++j) { // profiling based on 100 measures
      // determine which kind of job
      bool nullJob(true);
      if (j % 2 == 0) { // even
        if (!countRuby) {
          nullJob = false;
        }
      }
      else { // odd
        if (cnt < fullCount) {
          ++cnt;
          if (countRuby) {
            nullJob = false;
          }
        }
        else {
          if (!countRuby) {
            nullJob = false;
          }
        }
      }

      if (nullJob)
      {
        wf.addJob(openstudio::runmanager::JobType::Null);
      }
      else {
        openstudio::runmanager::RubyJobBuilder rubyjobbuilder;
        rubyjobbuilder.setScriptFile(rubyscriptfile);
        rubyjobbuilder.addInputFile(openstudio::runmanager::FileSelection::Last,
            openstudio::runmanager::FileSource::All,
            ".*\\.file",
            "in.file");
        rubyjobbuilder.addToWorkflow(wf);
      }
    }

    // ModelToIdf (Null)
    // EnergyPlus (Ruby)
    // OpenStudioPostProcess (Null)
    // Ruby Post-Process
    wf.addJob(openstudio::runmanager::JobType::Null);
    openstudio::runmanager::RubyJobBuilder rubyjobbuilder;
    rubyjobbuilder.setScriptFile(rubyscriptfile);
    rubyjobbuilder.addInputFile(openstudio::runmanager::FileSelection::Last,
        openstudio::runmanager::FileSource::All,
        ".*\\.file",
        "in.file");
    rubyjobbuilder.addToWorkflow(wf);
    wf.addJob(openstudio::runmanager::JobType::Null);
    rubyjobbuilder = openstudio::runmanager::RubyJobBuilder();
    rubyjobbuilder.setScriptFile(rubyscriptfile);
    rubyjobbuilder.addInputFile(openstudio::runmanager::FileSelection::Last,
        openstudio::runmanager::FileSource::All,
        ".*\\.file",
        "in.file");
    rubyjobbuilder.addToWorkflow(wf);

    openstudio::runmanager::Tools tools = openstudio::runmanager::ConfigOptions::makeTools(
        energyPlusExePath().parent_path(),
        openstudio::path(),
        openstudio::path(),
        rubyExePath().parent_path(),
        openstudio::path());
    wf.add(tools);

    wf.addParam(runmanager::JobParam("flatoutdir"));

    openstudio::path wfoutdir = outdir / openstudio::toPath("dataPoint" + boost::lexical_cast<std::string>(i));
    Job job = wf.create(wfoutdir, resourcesPath() / openstudio::toPath("runmanager/in.file"), openstudio::path());
    job.connect(SIGNAL(outputFileChanged(const openstudio::UUID &, const openstudio::runmanager::FileInfo& )), &listener, SLOT(listen()));
    job.connect(SIGNAL(treeChanged(const openstudio::UUID &)), &listener, SLOT(listen()));

    if (t_pauseType == PauseType::while_queuing) {
      rm.setPaused(true);
    }
    rm.enqueue(job, false);
    if (t_pauseType == PauseType::while_queuing) {
      rm.setPaused(false);
    }
  }

  if (t_pauseType == PauseType::total) {
    rm.setPaused(false);
  }
  rm.waitForFinished();
}

TEST_F(RunManagerTestFixture, Profile_FullWorkflow_NoRuby_Serial_PauseNone) {
  run_profiling_test(0, 16, 1, PauseType(PauseType::none));
}

TEST_F(RunManagerTestFixture, Profile_FullWorkflow_NoRuby_TwoJobs_PauseNone) {
  run_profiling_test(0, 16, 2, PauseType(PauseType::none));
}

TEST_F(RunManagerTestFixture, Profile_FullWorkflow_NoRuby_FourJobs_PauseNone) {
  run_profiling_test(0, 16, 4, PauseType(PauseType::none));
}

TEST_F(RunManagerTestFixture, Profile_FullWorkflow_NoRuby_SixJobs_PauseNone) {
  run_profiling_test(0, 16, 6, PauseType(PauseType::none));
}

TEST_F(RunManagerTestFixture, Profile_FullWorkflow_NoRuby_EightJobs_PauseNone) {
  run_profiling_test(0, 16, 8, PauseType(PauseType::none));
}

TEST_F(RunManagerTestFixture, Profile_FullWorkflow_NoRuby_TwelveJobs_PauseNone) {
  run_profiling_test(0, 16, 12, PauseType(PauseType::none));
}

TEST_F(RunManagerTestFixture, Profile_FullWorkflow_NoRuby_SixteenJobs_PauseNone) {
  run_profiling_test(0, 16, 16, PauseType(PauseType::none));
}

// ETH@20121011 Commenting out because slower than molasses.
// TEST_F(RunManagerTestFixture, Profile_FullWorkflow_AllRuby_Serial_PauseNone) {
//   run_profiling_test(100, 16, 1, PauseType(PauseType::none));
// }

// ETH@20121011 Commenting out because slower than molasses.
// TEST_F(RunManagerTestFixture, Profile_FullWorkflow_AllRuby_TwoJobs_PauseNone) {
//   run_profiling_test(100, 16, 2, PauseType(PauseType::none));
// }

// ETH@20121011 Commenting out because slower than molasses.
// TEST_F(RunManagerTestFixture, Profile_FullWorkflow_AllRuby_FourJobs_PauseNone) {
//   run_profiling_test(100, 16, 4, PauseType(PauseType::none));
// }

// ETH@20121011 Commenting out because slower than molasses.
// TEST_F(RunManagerTestFixture, Profile_FullWorkflow_AllRuby_SixJobs_PauseNone) {
//   run_profiling_test(100, 16, 6, PauseType(PauseType::none));
// }

TEST_F(RunManagerTestFixture, Profile_FullWorkflow_AllRuby_EightJobs_PauseNone) {
  run_profiling_test(100, 16, 8, PauseType(PauseType::none));
}

// ETH@20121011 Commenting out because slower than molasses.
// TEST_F(RunManagerTestFixture, Profile_FullWorkflow_AllRuby_TwelveJobs_PauseNone) {
//   run_profiling_test(100, 16, 12, PauseType(PauseType::none));
// }

// ETH@20121011 Commenting out because slower than molasses.
// TEST_F(RunManagerTestFixture, Profile_FullWorkflow_AllRuby_SixteenJobs_PauseNone) {
//   run_profiling_test(100, 16, 16, PauseType(PauseType::none));
// }
