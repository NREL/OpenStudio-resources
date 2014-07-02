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

#include "ProjectFixture.hpp"

#include <project/ProjectDatabase.hpp>
#include <project/AnalysisRecord.hpp>

#include <analysis/Analysis.hpp>
#include <analysis/Problem.hpp>
#include <analysis/MeasureGroup.hpp>
#include <analysis/NullMeasure.hpp>
#include <analysis/RubyMeasure.hpp>
#include <analysis/RubyMeasure_Impl.hpp>
#include <analysis/RubyContinuousVariable.hpp>
#include <analysis/RubyContinuousVariable_Impl.hpp>
#include <analysis/LinearFunction.hpp>
#include <analysis/NormalDistribution.hpp>
#include <analysis/OutputAttributeVariable.hpp>
#include <analysis/DataPoint.hpp>

#include <runmanager/lib/RunManager.hpp>
#include <runmanager/lib/Workflow.hpp>

#include <ruleset/OSArgument.hpp>

#include <utilities/core/Path.hpp>
#include <utilities/core/Containers.hpp>
#include <utilities/data/Tag.hpp>
#include <utilities/units/UnitFactory.hpp>
#include <utilities/units/Quantity.hpp>

#include <boost/filesystem.hpp>
#include <boost/random/mersenne_twister.hpp>
#include <boost/random/lognormal_distribution.hpp>
#include <boost/random/normal_distribution.hpp>
#include <boost/random/uniform_real.hpp>
#include <boost/random/variate_generator.hpp>

#include <stdlib.h>

using namespace openstudio;
using namespace openstudio::ruleset;
using namespace openstudio::runmanager;
using namespace openstudio::analysis;
using namespace openstudio::project;

void ProjectFixture::SetUp() {}

void ProjectFixture::TearDown() {}

void ProjectFixture::SetUpTestCase() {
  // set up logging
  logFile = FileLogSink(toPath("./ProjectFixture.log"));
  logFile->setLogLevel(Warn);
  openstudio::Logger::instance().standardOutLogger().disable();
}

void ProjectFixture::TearDownTestCase() {
  logFile->disable();
}

boost::optional<openstudio::FileLogSink> ProjectFixture::logFile;

openstudio::project::ProjectDatabase ProjectFixture::getCleanDatabase(openstudio::path projectDir) 
{
  if (boost::filesystem::exists(projectDir)) {
    boost::filesystem::remove_all(projectDir);
  }
  boost::filesystem::create_directory(projectDir);
  RunManager rm(projectDir / toPath("project.db"),true,false,false);
  ProjectDatabase db(projectDir / toPath("project.osp"), rm);
  return db;
}

openstudio::analysis::Analysis ProjectFixture::getAnalysisToRun(int numVariables, 
                                                                int numDataPoints)
{
  return getAnalysis(numVariables,numDataPoints,false);
}

openstudio::project::ProjectDatabase ProjectFixture::getPopulatedDatabase(
    int numVariables, 
    int numDataPoints,
    bool includeResults,
    openstudio::path projectDir)
{
  Analysis analysis = getAnalysis(numVariables,numDataPoints,includeResults);
  ProjectDatabase db = getCleanDatabase(projectDir);
  bool test = db.startTransaction();
  EXPECT_TRUE(test);
  AnalysisRecord ar(analysis,db);
  db.save();
  test = db.commitTransaction();
  EXPECT_TRUE(test);
  return db;
}

openstudio::analysis::Analysis ProjectFixture::getAnalysis(int numVariables, 
                                                           int numDataPoints, 
                                                           bool includeResults)
{
  // Set up random number generators for variables
  boost::mt19937 mt;
  typedef boost::lognormal_distribution<> lognormal_dist_type;
  typedef boost::normal_distribution<> normal_dist_type;
  typedef boost::uniform_real<> uniform_dist_type;
  typedef boost::variate_generator<boost::mt19937&, lognormal_dist_type> lognormal_gen_type;
  typedef boost::variate_generator<boost::mt19937&, normal_dist_type> normal_gen_type;
  typedef boost::variate_generator<boost::mt19937&, uniform_dist_type> uniform_gen_type;
  lognormal_gen_type surfaceAreaGenerator(mt,lognormal_dist_type(50.0,10.0));
  uniform_gen_type minFanOnFlowGenerator(mt,uniform_dist_type(0.1,0.3));
  uniform_gen_type maxFanOnFlowGenerator(mt,uniform_dist_type(0.5,0.8));
  normal_gen_type outOfRangeValueGenerator(mt,normal_dist_type(0.0,3.0));
  normal_gen_type radiantFractionGenerator(mt,normal_dist_type(0.65,0.05));
  uniform_gen_type wwrGenerator(mt,uniform_dist_type(0.1,0.7));
  lognormal_gen_type floorAreaGenerator(mt,lognormal_dist_type(1000.0,100.0));
  normal_gen_type gasWeight(mt,normal_dist_type(0.95,0.05));
  normal_gen_type elecWeight(mt,normal_dist_type(3.0,0.5));

  // Create variables
  VariableVector variables;
  for (int i = 0; i < numVariables; ++i) {
    std::stringstream ss;
    ss << "Variable " << i+1;
    int modVal = i % 2;
    if (modVal == 0) {
      // discrete variable
      MeasureVector measures;

      measures.push_back(NullMeasure());

      measures.push_back(RubyMeasure(toPath("setWindowToWallRatio.rb"),
                                            FileReferenceType::OSM,
                                            FileReferenceType::OSM,
                                            true));
      measures.back().cast<RubyMeasure>().addArgument("wwr",toString(wwrGenerator()));

      measures.push_back(RubyMeasure(toPath("createGeometry.rb"),
                                            FileReferenceType::OSM,
                                            FileReferenceType::OSM,
                                            true));
      StringVector choices;
      choices.push_back("rectangular");
      choices.push_back("H");
      choices.push_back("E");
      choices.push_back("circle");
      OSArgument arg = OSArgument::makeChoiceArgument("shape",choices);
      arg.setValue(choices[rand() % 4]);
      measures.back().cast<RubyMeasure>().addArgument(arg);
      arg = OSArgument::makeIntegerArgument("numFloors");
      arg.setValue((rand() % 5) + 1);
      measures.back().cast<RubyMeasure>().addArgument(arg);
      arg = OSArgument::makeQuantityArgument("floorArea");
      arg.setValue(Quantity(floorAreaGenerator(),createUnit("m^2").get()));
      measures.back().cast<RubyMeasure>().addArgument(arg);

      measures.push_back(RubyMeasure(toPath("setWindowToWallRatio.rb"),
                                            FileReferenceType::OSM,
                                            FileReferenceType::OSM,
                                            true));
      measures.back().cast<RubyMeasure>().addArgument("wwr",toString(wwrGenerator()));

      measures.push_back(RubyMeasure(toPath("createGeometry.rb"),
                                            FileReferenceType::OSM,
                                            FileReferenceType::OSM,
                                            true));
      arg = OSArgument::makeChoiceArgument("shape",choices);
      arg.setValue(choices[rand() % 4]);
      measures.back().cast<RubyMeasure>().addArgument(arg);
      arg = OSArgument::makeIntegerArgument("numFloors");
      arg.setValue((rand() % 5) + 1);
      measures.back().cast<RubyMeasure>().addArgument(arg);
      arg = OSArgument::makeQuantityArgument("floorArea");
      arg.setValue(Quantity(floorAreaGenerator(),createUnit("m^2").get()));
      measures.back().cast<RubyMeasure>().addArgument(arg);

      variables.push_back(MeasureGroup(ss.str(),measures));
    }
    else {
      // ruby continuous variable
      RubyMeasure script(toPath("setHVACSystem.rb"),
                              FileReferenceType::OSM,
                              FileReferenceType::OSM,
                              true);
      StringVector choices;
      choices.push_back("byZone");
      choices.push_back("byFloor");
      choices.push_back("wholeBuilding");
      OSArgument arg = OSArgument::makeChoiceArgument("systemScope",choices);
      arg.setValue("byFloor");
      script.addArgument(arg);
      arg = OSArgument::makeIntegerArgument("systemType");
      arg.setValue(1);
      script.addArgument(arg);
      arg = OSArgument::makeDoubleArgument("coolingCOP");
      variables.push_back(RubyContinuousVariable("Cooling COP",arg,script));
      NormalDistribution dist(3.1,0.35);
      variables.back().cast<RubyContinuousVariable>().setUncertaintyDescription(dist);
    }
  }

  // Create response functions
  FunctionVector responses;
  int numResponses = numVariables/5;
  for (int i = 0; i < numResponses; ++i) {
    std::stringstream ss;
    ss << "Response " << i;
    VariableVector outvars;
    outvars.push_back(OutputAttributeContinuousVariable("Gas Use","annualGasEnergyUse"));
    outvars.push_back(OutputAttributeContinuousVariable("Electricity Use","annualElecEnergyUse"));
    DoubleVector coefficients;
    coefficients.push_back(gasWeight());
    coefficients.push_back(elecWeight());
    responses.push_back(LinearFunction(ss.str(),outvars,coefficients));
  }

  // Create problem
  Problem problem("Problem",variables,responses,Workflow());

  // Create analysis
  FileReference seed(toPath("seed.osm"));
  Analysis analysis("Analysis",problem,seed);

  // Create data points
  uniform_gen_type coefficientGenerator(mt,uniform_dist_type(0.0,1.0));
  normal_gen_type copGenerator(mt,normal_dist_type(3.1,0.35));
  uniform_gen_type responseGenerator(mt,uniform_dist_type(50.0,500.0));
  for (int j = 0; j < numDataPoints; ++j) {
    std::stringstream ss;
    ss << "dataPoint" << j + 1;
    std::vector<QVariant> variableValues;
    for (int i = 0; i < numVariables; ++i) {
      int modVal = i % 2;
      if (modVal == 0) {
        // discrete variable -- choose 0-4
        variableValues.push_back(rand() % 5);
      }
      else {
        // ruby continuous variable -- choose normal(3.1,0.35)
        variableValues.push_back(copGenerator());
      }
    }

    if (includeResults) {
      DoubleVector responseValues;
      for (int i = 0; i < numResponses; ++i) {
        responseValues.push_back(responseGenerator());
      }
      openstudio::path runDir = toPath(ss.str());
      DataPoint dataPoint(createUUID(),
                          createUUID(),
                          "","","",
                          problem,
                          true,
                          false,
                          true,
                          DataPointRunType::Local,
                          variableValues,
                          responseValues,
                          runDir,
                          FileReference(runDir / toPath("ModelToIdf/in.osm")),
                          FileReference(runDir / toPath("ModelToIdf/out.idf")),
                          FileReference(runDir / toPath("EnergyPlus/eplusout.sql")),
                          boost::optional<runmanager::Job>(),
                          std::vector<openstudio::path>(),
                          TagVector(),
                          AttributeVector());
      analysis.addDataPoint(dataPoint);
    }
    else {
      OptionalDataPoint dataPoint = problem.createDataPoint(variableValues);
      bool test = dataPoint.is_initialized();
      EXPECT_TRUE(test);
      test = analysis.addDataPoint(*dataPoint);
      EXPECT_TRUE(test);
    }
  }

  return analysis;
}
