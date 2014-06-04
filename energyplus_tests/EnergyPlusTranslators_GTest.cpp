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
#include "EnergyPlusTestFixture.hpp"
#include <energyplus_tests/EnergyPlusBin.hxx>

#include <runmanager/lib/JobFactory.hpp>
#include <runmanager/lib/RunManager.hpp>
#include <runmanager/lib/Workflow.hpp>
#include <runmanager/lib/RubyJobUtils.hpp>

#include <utilities/core/Application.hpp>
#include <utilities/core/System.hpp>
#include <utilities/core/Logger.hpp>

#include <boost/filesystem/path.hpp>
#include <boost/filesystem.hpp>

#include <resources.hxx>
#include <OpenStudio.hxx>

#include <QDir>

#ifdef _MSC_VER
#include <Windows.h>
#endif

std::string EnergyPlusTestFixture::loadFile(std::ifstream &t_ifs)
{
  std::stringstream ss;

  std::string line;

  while (std::getline(t_ifs, line))
  {
    size_t commentstart = line.find('!');

    if (commentstart != std::string::npos)
    {
      line.erase(commentstart); // erase from ! to end of line
    }

    boost::algorithm::trim(line);


    if (!line.empty())
    {
      if (line[0] != '!')
      {
        ss << line << std::endl;
      }
    }
  }

  return ss.str();

}

void EnergyPlusTestFixture::compareFiles(const openstudio::path &t_lhs, const openstudio::path &t_rhs)
{
  std::ifstream filelhs(openstudio::toString(t_lhs).c_str());
  std::ifstream filerhs(openstudio::toString(t_rhs).c_str());

  LOG(Info, "Comparing: " << openstudio::toString(t_lhs) << " and " << openstudio::toString(t_rhs));

  ASSERT_TRUE(filelhs.good());
  ASSERT_TRUE(filerhs.good());

  std::string lhs = loadFile(filelhs);
  std::string rhs = loadFile(filerhs);

  if (lhs != rhs)
  {
    LOG(Error, "Files do not match " << openstudio::toString(t_lhs) << " " << openstudio::toString(t_rhs));
    ASSERT_TRUE(false);
  }

}


void addComparisonGeneratorJob(openstudio::runmanager::Job &t_parent,
    const openstudio::path &t_inputfile, const openstudio::path &t_epw, openstudio::runmanager::Workflow t_workflow)
{
  t_workflow.setInputFiles(t_inputfile, t_epw);
  t_parent.addChild(t_workflow.create());
}

openstudio::runmanager::Job createPostProcessComparisonJob(const openstudio::path &t_outdir, const openstudio::path &t_filename)
{
  openstudio::runmanager::Workflow wf("Null");

  openstudio::runmanager::Tools tools 
    = openstudio::runmanager::ConfigOptions::makeTools(
        energyPlusExePath().parent_path(), openstudio::path(), openstudio::path(), rubyExePath().parent_path(), openstudio::path(),
        openstudio::path(), openstudio::path(), openstudio::path(), openstudio::path(), openstudio::path());

  wf.add(tools);

  openstudio::runmanager::Job j = wf.create(t_outdir);

  openstudio::runmanager::RubyJobBuilder rubyJobBuilder;
  openstudio::path p = resourcesPath() / openstudio::toPath("energyplus")  / openstudio::toPath("PostProcessComparison.rb");

  rubyJobBuilder.setScriptFile(p);
  rubyJobBuilder.addInputFile(openstudio::runmanager::FileSelection("All"),
                              openstudio::runmanager::FileSource("All"),
                              "report\\.xml",
                              "report.xml");

  rubyJobBuilder.addScriptArgument(openstudio::toString(t_filename));
  rubyJobBuilder.addScriptArgument( openstudio::toString(t_outdir.parent_path() / openstudio::toPath("RolledUpReport.csv")) );
  rubyJobBuilder.addToolArgument("-I" + rubyOpenStudioDir()) ;

  // create a dummy workflow and add ruby job
  openstudio::runmanager::Workflow rubyJob;
  rubyJobBuilder.addToWorkflow(rubyJob);

  j.setFinishedJob(rubyJob.create());

  return j;
}

openstudio::path buildTestPath(const openstudio::path &t_path, int number)
{
  std::stringstream ss;
  ss << "test";
  ss << std::setw(5) << std::setfill('0') << number;

  return t_path / openstudio::toPath(ss.str());
}

TEST_P(EnergyPlusTestFixture, PostProcessComparison)
{ 
  bool isosm = openstudio::toString(GetParam().extension()) == ".osm";


  std::vector<openstudio::path> paths;
 
  openstudio::path outdir = openstudio::tempDir(); 

  if (isosm) {
    paths = osmPaths();
    outdir /= openstudio::toPath("ReferencePostProcessComparisonTest");
  } else {
    paths = idfPaths();
    outdir /= openstudio::toPath("ExamplePostProcessComparisonTest");
  }

  boost::filesystem::create_directories(outdir);

  openstudio::path p(openstudio::toPath("ComparisonTest.db"));

  openstudio::path db = outdir / p;
  openstudio::runmanager::RunManager kit(db, true);
  kit.setPaused(true);


  openstudio::path wfoutdir = buildTestPath(outdir, std::distance(paths.begin(), std::find(paths.begin(), paths.end(), GetParam())));

  boost::filesystem::remove_all(wfoutdir); // Clean up test dir before starting

  openstudio::runmanager::Job j = createPostProcessComparisonJob(wfoutdir, GetParam().filename());

  openstudio::path epw = (resourcesPath() / openstudio::toPath("weatherdata") / openstudio::toPath("USA_IL_Chicago-OHare.Intl.AP.725300_TMY3.epw"));

  if (isosm)
  {
    addComparisonGeneratorJob(j, GetParam(), epw, openstudio::runmanager::Workflow("ModelToIdf->EnergyPlusPreProcess->EnergyPlus->EnergyPlusPostProcess"));
    addComparisonGeneratorJob(j, GetParam(), epw,  
        openstudio::runmanager::Workflow("ModelToIdf->IdfToModel->ModelToIdf->EnergyPlusPreProcess->EnergyPlus->EnergyPlusPostProcess"));
  } else {
    addComparisonGeneratorJob(j, GetParam(), epw, openstudio::runmanager::Workflow("EnergyPlusPreProcess->EnergyPlus->EnergyPlusPostProcess"));
    addComparisonGeneratorJob(j, GetParam(), epw,  
        openstudio::runmanager::Workflow("EnergyPlusPreProcess->IdfToModel->ModelToIdf->EnergyPlus->EnergyPlusPostProcess"));
  }

  kit.enqueue(j, false);

  kit.setPaused(false);

  kit.waitForFinished();

  if (!j.treeErrors().succeeded())
  {
//    openstudio::path loggingoutdir = outdir / openstudio::toPath(boost::filesystem::stem(GetParam()));
    openstudio::path loggingoutdir = outdir / GetParam().stem();
    boost::filesystem::create_directories(loggingoutdir);

    std::ofstream ofs(openstudio::toString(loggingoutdir / openstudio::toPath("JobLogs.txt")).c_str(), std::ios_base::trunc);
    std::ofstream csv(openstudio::toString(outdir / openstudio::toPath("errorreport.csv")).c_str(), std::ios_base::app | std::ios_base::ate);

    std::vector<openstudio::runmanager::Job> jobs = kit.getJobs();

    boost::regex r1("Object=(.*),");
    boost::regex r2("type '(.*?)'");

    for (std::vector<openstudio::runmanager::Job>::const_iterator itr = jobs.begin();
        itr != jobs.end();
        ++itr)
    {
      openstudio::runmanager::JobErrors e = itr->errors();

      std::vector<std::string> errs = e.errors();
      std::vector<std::string> warnings = e.warnings();

      for (std::vector<std::string>::const_iterator itr2 = errs.begin();
          itr2 != errs.end();
          ++itr2)
      {
        ofs << "[" << itr->jobType().valueName() << "] {" << openstudio::toString(itr->uuid()) << "} (ERROR) " << *itr2 << std::endl;

        boost::smatch m;
        if (boost::regex_search(*itr2, m, r1))
        {
          csv << openstudio::toString(GetParam().filename()) << ", EnergyPlus, ERROR, " << std::string(m[1]) << std::endl;
        } 

        if (boost::regex_search(*itr2, m, r2))
        {
          csv << openstudio::toString(GetParam().filename()) << ", Translator, ERROR, " << std::string(m[1]) << std::endl;
        }
      }

      for (std::vector<std::string>::const_iterator itr2 = warnings.begin();
          itr2 != warnings.end();
          ++itr2)
      {
        ofs << "[" << itr->jobType().valueName() << "] {" << openstudio::toString(itr->uuid()) << "} (WARNING) " << *itr2 << std::endl;

        boost::smatch m;
        if (boost::regex_search(*itr2, m, r1))
        {
          csv << openstudio::toString(GetParam().filename()) << ", EnergyPlus, WARNING, " << std::string(m[1]) << std::endl;
        }

        if (boost::regex_search(*itr2, m, r2))
        {
          csv << openstudio::toString(GetParam().filename()) << ", Translator, WARNING, " << std::string(m[1]) << std::endl;
        }
      }
    }

    std::vector<openstudio::runmanager::FileInfo> files = j.treeOutputFiles().getAllByExtension("idf").files();
    if (files.size() == 3)
    {
      boost::filesystem::copy_file(GetParam(), loggingoutdir / openstudio::toPath("original.idf"), boost::filesystem::copy_option::overwrite_if_exists);
      boost::filesystem::copy_file(files[0].fullPath, loggingoutdir / openstudio::toPath("aftersqlenabled.idf"), boost::filesystem::copy_option::overwrite_if_exists);
      boost::filesystem::copy_file(files[2].fullPath, loggingoutdir / openstudio::toPath("aftertranslation.idf"), boost::filesystem::copy_option::overwrite_if_exists);
    }
  }


  EXPECT_TRUE(j.treeErrors().succeeded());
}



TEST_P(EnergyPlusTestFixture, ConversionFileComparison)
{ 
  bool isosm = openstudio::toString(GetParam().extension()) == ".osm";


  std::vector<openstudio::path> paths;
 
  openstudio::path outdir = openstudio::tempDir(); 

  if (isosm) {
    paths = osmPaths();
    outdir /= openstudio::toPath("ReferenceConversionComparisonTest");
  } else {
    paths = idfPaths();
    outdir /= openstudio::toPath("ExampleConversionComparisonTest");
  }

  boost::filesystem::create_directories(outdir);

  openstudio::path p(openstudio::toPath("ComparisonTest.db"));

  boost::filesystem::create_directories(outdir);


  openstudio::path db = outdir / p;
  openstudio::runmanager::RunManager kit(db, true);
  kit.setPaused(true);


  openstudio::runmanager::Workflow wf;

  if (isosm)
  {
     wf = openstudio::runmanager::Workflow("ModelToIdf->IdfToModel");
  } else {
     wf = openstudio::runmanager::Workflow("IdfToModel->ModelToIdf->IdfToModel");
  }

  openstudio::runmanager::Tools tools 
    = openstudio::runmanager::ConfigOptions::makeTools(energyPlusExePath().parent_path(), 
        openstudio::path(), openstudio::path(), rubyExePath().parent_path(), openstudio::path(),
        openstudio::path(), openstudio::path(), openstudio::path(), openstudio::path(), openstudio::path());

  wf.add(tools);

  openstudio::path wfoutdir = buildTestPath(outdir, std::distance(paths.begin(), std::find(paths.begin(), paths.end(), GetParam())));


  boost::filesystem::remove_all(wfoutdir); // Clean up test dir before starting
  openstudio::runmanager::Job j = wf.create(wfoutdir, GetParam(), openstudio::path());
  kit.enqueue(j, false);

  kit.setPaused(false);

  kit.waitForFinished();

  std::vector<openstudio::runmanager::FileInfo> files = j.treeOutputFiles().getAllByExtension("osm").files();

  ASSERT_EQ(3u, files.size());

  compareFiles(files[0].fullPath, files[1].fullPath);

}

INSTANTIATE_TEST_CASE_P(TranslatorExampleFileComparisonTest,
                        EnergyPlusTestFixture,
                        ::testing::ValuesIn(idfPaths()));


INSTANTIATE_TEST_CASE_P(TranslatorReferenceFileComparisonTest,
                        EnergyPlusTestFixture,
                        ::testing::ValuesIn(osmPaths()));




