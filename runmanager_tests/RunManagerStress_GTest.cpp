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
#include <runmanager/Test/ToolBin.hxx>
#include <resources.hxx>
#include <OpenStudio.hxx>
#include <runmanager/lib/JobFactory.hpp>
#include <boost/filesystem/path.hpp>
#include <runmanager/lib/RunManager.hpp>
#include <runmanager/lib/Workflow.hpp>
#include <runmanager/lib/RubyJobUtils.hpp>
#include <QDir>
#include <utilities/core/Application.hpp>
#include <utilities/core/System.hpp>
#include "SignalListener.hpp"
#include <utilities/core/Logger.hpp>

#ifdef _MSC_VER
#include <Windows.h>
#endif



void RunManagerTestFixture::run_stress_test(bool t_show_ui, bool t_listener, bool t_nullJob, 
    int t_runcount, bool t_kill, int t_min_time, int t_max_time, int t_numJobTrees = 30)
{
  openstudio::path outdir = openstudio::tempDir() / openstudio::toPath("RunManagerStress");

  if (t_show_ui)
  {
    outdir /= openstudio::toPath("show_ui");
  } else {
    outdir /= openstudio::toPath("no_show_ui");
  }
  
  if (t_listener)
  {
    outdir /= openstudio::toPath("with_listener");
  } else {
    outdir /= openstudio::toPath("without_listener");
  }

  if (t_nullJob)
  {
    outdir /= openstudio::toPath("null_jobs");
  } else {
    outdir /= openstudio::toPath("ruby_jobs");
  }

  std::stringstream ss; 
  ss << "StressNullJobsDB" << t_show_ui << t_listener << t_nullJob << "-" << t_numJobTrees;
  openstudio::path db = openstudio::toPath(QDir::tempPath()) / openstudio::toPath(ss.str());
  openstudio::runmanager::RunManager kit(db, true);
  kit.setPaused(true);


  for (int runiteration = 0; runiteration < t_runcount; ++runiteration)
  {
    {
      kit.clearJobs();
    }

    int totaljobs = 0;

    std::vector<openstudio::runmanager::Job> jobstoadd;

    for (int i=0; i<t_numJobTrees; ++i)
    {
      openstudio::runmanager::Workflow wf;
      openstudio::path rubyscriptfile = resourcesPath() / openstudio::toPath("runmanager/test.rb");
      for (int j=0; j<i+1; ++j)
      {
        ++totaljobs;
        if (t_nullJob)
        {
          wf.addJob(openstudio::runmanager::JobType::Null);
        } else {
          openstudio::runmanager::RubyJobBuilder rubyjobbuilder;
          rubyjobbuilder.setScriptFile(rubyscriptfile);
          rubyjobbuilder.addInputFile(openstudio::runmanager::FileSelection::Last,
              openstudio::runmanager::FileSource::All,
              ".*\\.file",
              "in.file");
          rubyjobbuilder.addToWorkflow(wf);
        }
      }
      openstudio::runmanager::Tools tools 
        = openstudio::runmanager::ConfigOptions::makeTools(energyPlusExePath().parent_path(), openstudio::path(), openstudio::path(), rubyExePath().parent_path(), openstudio::path(),
            openstudio::path(), openstudio::path(), openstudio::path(), openstudio::path(), openstudio::path());

      wf.add(tools);
      wf.addParam(openstudio::runmanager::JobParam("flatoutdir"));
      openstudio::path wfoutdir = outdir / openstudio::toPath("jobtree" + boost::lexical_cast<std::string>(i));
      boost::filesystem::remove_all(wfoutdir); // Clean up test dir before starting
//      kit.enqueue(wf.create(wfoutdir, resourcesPath() / openstudio::toPath("runmanager/in.file"), openstudio::path()), false);
      jobstoadd.push_back(wf.create(wfoutdir, resourcesPath() / openstudio::toPath("runmanager/in.file"), openstudio::path()));
    }

    kit.enqueue(jobstoadd, false);
    jobstoadd.clear();

    if (t_show_ui)
    {
      kit.showStatusDialog();
    }

    std::vector<openstudio::runmanager::Job> jobs = kit.getJobs();
    EXPECT_EQ(jobs.size(), static_cast<size_t>(totaljobs));


    openstudio::runmanager::test::Test_Listener listener;


    if (t_listener)
    {
      for (std::vector<openstudio::runmanager::Job>::iterator itr = jobs.begin();
          itr != jobs.end();
          ++itr)
      {
        itr->connect(SIGNAL(started(const openstudio::UUID &)), &listener, SLOT(listen()));
        itr->connect(SIGNAL(finished(const openstudio::UUID &, const openstudio::runmanager::JobErrors& )), &listener, SLOT(listen()));
        itr->connect(SIGNAL(outputFileChanged(const openstudio::UUID &, const openstudio::runmanager::FileInfo& )), &listener, SLOT(listen()));
        itr->connect(SIGNAL(stateChanged(const openstudio::UUID &)), &listener, SLOT(listen()));
        itr->connect(SIGNAL(outputDataAdded(const openstudio::UUID &, const std::string &)), &listener, SLOT(listen()));
        itr->connect(SIGNAL(statusChanged(const openstudio::runmanager::AdvancedStatus &)), &listener, SLOT(listen()));
        itr->connect(SIGNAL(childrenChanged(const openstudio::UUID &)), &listener, SLOT(listen()));
        itr->connect(SIGNAL(parentChanged(const openstudio::UUID &)), &listener, SLOT(listen()));
        itr->connect(SIGNAL(treeChanged(const openstudio::UUID &)), &listener, SLOT(listen()));
        itr->connect(SIGNAL(remoteProcessStarted(const openstudio::UUID &, int, int )), &listener, SLOT(listen()));
        itr->connect(SIGNAL(remoteProcessFinished(const openstudio::UUID &, int, int )), &listener, SLOT(listen()));
      }


      kit.connect(SIGNAL(pausedChanged(bool)), &listener, SLOT(listen()));
      kit.connect(SIGNAL(statsChanged()), &listener, SLOT(listen()));
    }

    kit.setPaused(false);

    if (!t_kill)
    {
      kit.waitForFinished();

      EXPECT_FALSE(kit.workPending());

      for (std::vector<openstudio::runmanager::Job>::iterator itr = jobs.begin();
          itr != jobs.end();
          ++itr)
      {
        openstudio::runmanager::JobErrors e = itr->errors();
        EXPECT_TRUE(e.succeeded());
        EXPECT_TRUE(e.errors().empty());
        EXPECT_TRUE(e.warnings().empty());
        EXPECT_FALSE(itr->outOfDate());

        if (!e.succeeded() || !e.errors().empty() || !e.warnings().empty())
        {
          LOG(Error, "Job failed " << openstudio::toString(itr->uuid()) << " " << openstudio::toString(itr->outdir()));

          for(std::vector<std::string>::const_iterator itr2 = e.errors().begin();
              itr2 != e.errors().end();
              ++itr2)
          {
            LOG(Error, "Job error: " << openstudio::toString(itr->uuid()) << " " << *itr2);
          }

          for(std::vector<std::string>::const_iterator itr2 = e.warnings().begin();
              itr2 != e.warnings().end();
              ++itr2)
          {
            LOG(Error, "Job warning: " << openstudio::toString(itr->uuid()) << " " << *itr2);
          }

        }
      }
    } else {
      // Sleep for a random time that coincides with the random wait requested, this is before shutting down the 
      // RunManager / removing jobs
      int sleeptime = qRound((double(qrand())/double(RAND_MAX)) * (t_max_time - t_min_time)) + t_min_time;
      LOG(Info, "Sleeping for " << sleeptime << "ms");
      openstudio::System::msleep(sleeptime);
      LOG(Info, "Exiting function, closing RunManager");
    }
  }

}

TEST_F(RunManagerTestFixture, StressNullJobsWithUI)
{
  run_stress_test(true, false, true, 1, false, 0, 0);
}

TEST_F(RunManagerTestFixture, StressNullJobs)
{
  run_stress_test(false, false, true, 1, false, 0, 0);
}

TEST_F(RunManagerTestFixture, StressNullJobsHuge)
{
  run_stress_test(false, false, true, 1, false, 0, 0, 200);
}

TEST_F(RunManagerTestFixture, StressNullJobsWithUIWithQTSignals)
{
  run_stress_test(true, true, true, 1, false, 0, 0);
}

TEST_F(RunManagerTestFixture, StressNullJobsWithQTSignals)
{
  run_stress_test(false, true, true, 1, false, 0, 0);
}

TEST_F(RunManagerTestFixture, StressRubyJobsHuge)
{
  run_stress_test(false, false, false, 1, false, 0, 0, 100);
}

TEST_F(RunManagerTestFixture, StressRubyJobsWithUI)
{
  run_stress_test(true, false, false, 1, false, 0, 0);
}

TEST_F(RunManagerTestFixture, StressRubyJobs)
{
  run_stress_test(false, false, false, 1, false, 0, 0);
}

TEST_F(RunManagerTestFixture, StressRubyJobsWithUIWithQtSignals)
{
  run_stress_test(true, true, false, 1, false, 0, 0);
}

TEST_F(RunManagerTestFixture, StressRubyJobsWithQtSignals)
{
  run_stress_test(false, true, false, 1, false, 0, 0);
}



TEST_F(RunManagerTestFixture, StressKillNullJobsWithUI)
{
  run_stress_test(true, false, true, 5, true, 0, 0);
  for (int i = 0; i < 5; ++i)
  {
    run_stress_test(true, false, true, 1, true, 0, 0);
  }


  run_stress_test(true, false, true, 5, true, 0, 250);
  for (int i = 0; i < 5; ++i)
  {
    run_stress_test(true, false, true, 1, true, 0, 250);
  }
}

TEST_F(RunManagerTestFixture, StressKillNullJobs)
{
  run_stress_test(false, false, true, 5, true, 0, 0);
  for (int i = 0; i < 5; ++i)
  {
    run_stress_test(false, false, true, 1, true, 0, 0);
  }


  run_stress_test(false, false, true, 5, true, 0, 250);
  for (int i = 0; i < 5; ++i)
  {
    run_stress_test(false, false, true, 1, true, 0, 250);
  }
}

TEST_F(RunManagerTestFixture, StressKillNullJobsWithUIWithQTSignals)
{
  run_stress_test(true, true, true, 5, true, 0, 0);
  for (int i = 0; i < 5; ++i)
  {
    run_stress_test(true, true, true, 1, true, 0, 0);
  }


  run_stress_test(true, true, true, 5, true, 0, 250);
  for (int i = 0; i < 5; ++i)
  {
    run_stress_test(true, true, true, 1, true, 0, 250);
  }
}

TEST_F(RunManagerTestFixture, StressKillNullJobsWithQTSignals)
{
  run_stress_test(false, true, true, 5, true, 0, 0);
  for (int i = 0; i < 5; ++i)
  {
    run_stress_test(false, true, true, 1, true, 0, 0);
  }


  run_stress_test(false, true, true, 5, true, 0, 250);
  for (int i = 0; i < 5; ++i)
  {
    run_stress_test(false, true, true, 1, true, 0, 250);
  }
}

TEST_F(RunManagerTestFixture, StressKillRubyJobsWithUI)
{
  run_stress_test(true, false, false, 5, true, 0, 0);
  for (int i = 0; i < 5; ++i)
  {
    run_stress_test(true, false, false, 1, true, 0, 0);
  }


  run_stress_test(true, false, false, 5, true, 0, 250);
  for (int i = 0; i < 5; ++i)
  {
    run_stress_test(true, false, false, 1, true, 0, 250);
  }

}

TEST_F(RunManagerTestFixture, StressKillRubyJobs)
{
  run_stress_test(false, false, false, 5, true, 0, 0);
  for (int i = 0; i < 5; ++i)
  {
    run_stress_test(false, false, false, 1, true, 0, 0);
  }


  run_stress_test(false, false, false, 5, true, 0, 250);
  for (int i = 0; i < 5; ++i)
  {
    run_stress_test(false, false, false, 1, true, 0, 250);
  }
}

TEST_F(RunManagerTestFixture, StressKillRubyJobsWithUIWithQtSignals)
{
  run_stress_test(true, true, false, 5, true, 0, 0);
  for (int i = 0; i < 5; ++i)
  {
    run_stress_test(true, true, false, 1, true, 0, 0);
  }


  run_stress_test(true, true, false, 5, true, 0, 250);
  for (int i = 0; i < 5; ++i)
  {
    run_stress_test(true, true, false, 1, true, 0, 250);
  }
}

TEST_F(RunManagerTestFixture, StressKillRubyJobsWithQtSignals)
{
  run_stress_test(false, true, false, 5, true, 0, 0);
  for (int i = 0; i < 5; ++i)
  {
    run_stress_test(false, true, false, 1, true, 0, 0);
  }


  run_stress_test(false, true, false, 5, true, 0, 250);
  for (int i = 0; i < 5; ++i)
  {
    run_stress_test(false, true, false, 1, true, 0, 250);
  }
}




TEST_F(RunManagerTestFixture, DBNotOpenedTwice)
{
  {
    openstudio::path db = openstudio::toPath(QDir::tempPath()) / openstudio::toPath("DBNotOpenedTwiceDB");
    openstudio::runmanager::RunManager kit(db, true);
    kit.setPaused(true);
    kit.showStatusDialog();
  }

  {
    openstudio::path db = openstudio::toPath(QDir::tempPath()) / openstudio::toPath("DBNotOpenedTwiceDB");
    EXPECT_NO_THROW(openstudio::runmanager::RunManager kit(db, true));
  }


}

