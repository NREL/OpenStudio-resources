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

#include <utilities/core/PathHelpers.hpp>

#include <resources.hxx>

TEST_F(SimpleProjectFixture, RelocateTest) {

  openstudio::path path1 = openstudio::toPath("./SimpleProject1");
  openstudio::path path2 = openstudio::toPath("./SimpleProject2");

  boost::optional<openstudio::analysisdriver::SimpleProject> project = makeSimpleProject(path1);
  ASSERT_TRUE(project);

  openstudio::analysisdriver::AnalysisDriver analysisDriver = project->analysisDriver();
  openstudio::analysisdriver::AnalysisRunOptions runOptions = openstudio::analysisdriver::standardRunOptions(*project);
  openstudio::analysis::Analysis analysis = project->analysis();
  analysisDriver.run(analysis, runOptions);

  EXPECT_TRUE(analysisDriver.waitForFinished());
  project->save();

  project.reset();

  ASSERT_TRUE(openstudio::copyDirectory(path1, path2));
  ASSERT_TRUE(openstudio::removeDirectory(path1));

  project = openstudio::analysisdriver::SimpleProject::open(path2);
  ASSERT_TRUE(project);
}
