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

#ifndef PROJECT_TEST_PROJECTFIXTURE_HPP
#define PROJECT_TEST_PROJECTFIXTURE_HPP

#include <gtest/gtest.h>

#include <resources.hxx>

#include <utilities/core/Logger.hpp>
#include <utilities/core/FileLogSink.hpp>

#include <boost/optional.hpp>

namespace openstudio {
namespace analysis {
  class Analysis;
}
namespace project {
  class ProjectDatabase;
}
}

class ProjectFixture : public ::testing::Test {
 protected:
  // initialize for each test
  virtual void SetUp();

  // tear down after each test
  virtual void TearDown();

  // initiallize static members
  static void SetUpTestCase();

  // tear down static members
  static void TearDownTestCase();

  // set up logging
  REGISTER_LOGGER("ProjectFixture");

  static boost::optional<openstudio::FileLogSink> logFile;

  // Goal is 100 variables; 50,000 data points; runtime overhead per data point < 6s; 
  // retrieval of high level results in < 10s.

  static openstudio::project::ProjectDatabase getCleanDatabase(openstudio::path projectDir);

  /** Creates an analysis containing numVariables variables and numDataPoints dataPointsToQueue.
   *  The variables are created by looping through:
   *  \li MeasureGroup
   *  \li RubyContinuousVariable (with uncertainty description)
   *  The discrete variables contain five measures each: one NullMeasure, and four 
   *  RubyMeasures. In addition, floor(numVariables/5) response functions are defined. */
  static openstudio::analysis::Analysis getAnalysisToRun(int numVariables,
                                                         int numDataPoints);

  /** As getAnalysisToRun, except that output data is added to the DataPoints, and the data is
   *  all pushed to a ProjectDatabase in projectDir. */
  static openstudio::project::ProjectDatabase getPopulatedDatabase(int numVariables, 
                                                                   int numDataPoints,
                                                                   bool includeResults,
                                                                   openstudio::path projectDir);

 private:
  static openstudio::analysis::Analysis getAnalysis(int numVariables, 
                                                    int numDataPoints, 
                                                    bool includeResults);
};

#endif // PROJECT_TEST_PROJECTFIXTURE_HPP
