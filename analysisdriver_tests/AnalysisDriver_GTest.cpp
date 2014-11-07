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
#include "AnalysisDriverFixture.hpp"

#include <analysisdriver/AnalysisDriver.hpp>
#include <analysisdriver/CurrentAnalysis.hpp>
#include <analysisdriver/AnalysisRunOptions.hpp>
#include <analysisdriver/SimpleProject.hpp>

#include <project/ProjectDatabase.hpp>
#include <project/AnalysisRecord.hpp>
#include <project/ProblemRecord.hpp>
#include <project/DataPointRecord.hpp>
#include <project/FileReferenceRecord.hpp>
#include <project/AttributeRecord.hpp>
#include <project/TagRecord.hpp>

#include <analysis/Analysis.hpp>
#include <analysis/Problem.hpp>
#include <analysis/OptimizationProblem.hpp>
#include <analysis/MeasureGroup.hpp>
#include <analysis/MeasureGroup_Impl.hpp>
#include <analysis/DesignOfExperimentsOptions.hpp>
#include <analysis/NullMeasure.hpp>
#include <analysis/NullMeasure_Impl.hpp>
#include <analysis/RubyMeasure.hpp>
#include <analysis/RubyMeasure_Impl.hpp>
#include <analysis/OutputAttributeVariable.hpp>
#include <analysis/OutputAttributeVariable_Impl.hpp>
#include <analysis/LinearFunction.hpp>
#include <analysis/LinearFunction_Impl.hpp>
#include <analysis/DesignOfExperiments.hpp>
#include <analysis/SequentialSearch.hpp>
#include <analysis/SequentialSearch_Impl.hpp>
#include <analysis/SequentialSearchOptions.hpp>
#include <analysis/DataPoint.hpp>
#include <analysis/OptimizationDataPoint.hpp>
#include <analysis/OptimizationDataPoint_Impl.hpp>
#include <analysis/OpenStudioAlgorithm.hpp>  //-BLB
#include <analysis/OpenStudioAlgorithm_Impl.hpp>

#include <model/Model.hpp>

#include <runmanager/lib/RunManager.hpp>
#include <runmanager/lib/Workflow.hpp>
#include <runmanager/lib/RubyJob.hpp>
#include <runmanager/lib/RubyJobUtils.hpp>
#include <runmanager/Test/ToolBin.hxx>

#include <utilities/economics/Economics.hpp>
#include <utilities/data/Attribute.hpp>
#include <utilities/core/Optional.hpp>
#include <utilities/core/Path.hpp>
#include <utilities/core/Finder.hpp>
#include <utilities/core/Checksum.hpp>
#include <utilities/core/FileReference.hpp>
#include <utilities/core/Containers.hpp>

#include <resources.hxx>
#include <OpenStudio.hxx>

#include <QFileInfo>
#include <QDateTime>

#include <boost/foreach.hpp>

using namespace openstudio;
using namespace openstudio::model;
using namespace openstudio::ruleset;
using namespace openstudio::analysis;
using namespace openstudio::project;
using namespace openstudio::analysisdriver;

TEST_F(AnalysisDriverFixture, DesignOfExperiments_IdfOnly_NoSimulation) {
  // SET UP PROJECT
  SimpleProject project = getCleanSimpleProject("DesignOfExperiments_IdfOnly_NoSimulation");
  Analysis analysis = project.analysis();
  EXPECT_EQ(0,analysis.problem().combinatorialSize(true).get());

  // DEFINE SEED
  FileReference seedModel(resourcesPath() / openstudio::toPath("energyplus/8-0-0/5ZoneAirCooled/in.idf"));
  project.setSeed(seedModel);

  // RETRIEVE PROBLEM
  Problem problem = retrieveProblem("IdfOnly",false,false);
  // down select to give 32 instead of 128 data points.
  problem.variables()[1].cast<MeasureGroup>().measures(false)[1].setIsSelected(false);
  problem.variables()[4].cast<MeasureGroup>().measures(false)[1].setIsSelected(false);
  EXPECT_TRUE(analysis.setProblem(problem));
  EXPECT_EQ(32,analysis.problem().combinatorialSize(true).get());

  // ADD ALGORITHM
  DesignOfExperimentsOptions algOptions(DesignOfExperimentsType::FullFactorial);
  DesignOfExperiments algorithm(algOptions);
  analysis.setAlgorithm(algorithm);

  // RUN ANALYSIS
  project.save();
  AnalysisDriver analysisDriver = project.analysisDriver();
  AnalysisRunOptions runOptions = standardRunOptions(project.projectDir());
  CurrentAnalysis currentAnalysis = analysisDriver.run(analysis,runOptions);
  EXPECT_TRUE(analysisDriver.waitForFinished());

  // CHECK RESULTS
  AnalysisRecord analysisRecord = project.analysisRecord();
  EXPECT_EQ(32,analysisRecord.problemRecord().combinatorialSize(true).get());
  EXPECT_EQ(128,analysisRecord.problemRecord().combinatorialSize(false).get());
  EXPECT_EQ(32u, analysisRecord.dataPointRecords().size());
  BOOST_FOREACH(const DataPointRecord& dataPointRecord, analysisRecord.dataPointRecords()) {
    EXPECT_TRUE(dataPointRecord.isComplete());
    EXPECT_FALSE(dataPointRecord.failed());
  }
}

TEST_F(AnalysisDriverFixture, DesignOfExperiments_IdfOnly_WithSimulation) {
  // SET UP PROJECT
  SimpleProject project = getCleanSimpleProject("DesignOfExperiments_IdfOnly_WithSimulation");
  Analysis analysis = project.analysis();

  // DEFINE SEED
  FileReference seedModel(resourcesPath() / openstudio::toPath("energyplus/8-0-0/5ZoneAirCooled/in.idf"));
  FileReference weatherFile(energyPlusWeatherDataPath() / toPath("USA_IL_Chicago-OHare.Intl.AP.725300_TMY3.epw"));
  project.setSeed(seedModel);
  analysis.setWeatherFile(weatherFile);

  // RETRIEVE PROBLEM
  Problem problem = retrieveProblem("IdfOnly",false,true);
  // turn off most measures
  InputVariableVector variables = problem.variables();
  ASSERT_EQ(7u,variables.size());
  // set up single custom point to run in addition to the limited mesh
  MeasureVector customPointMeasures;
  // Lighting Power Density (2,2)
  EXPECT_EQ("Lighting Power Density",variables[0].name());
  MeasureVector measures = variables[0].cast<MeasureGroup>().measures(false);
  ASSERT_EQ(2u,measures.size());
  EXPECT_TRUE(measures[0].optionalCast<NullMeasure>());
  customPointMeasures.push_back(measures[1]);
  // Plug Load Density (2,1)
  EXPECT_EQ("Plug Load Density",variables[1].name());
  measures = variables[1].cast<MeasureGroup>().measures(false);
  ASSERT_EQ(2u,measures.size());
  EXPECT_TRUE(measures[0].optionalCast<NullMeasure>());
  measures[1].setIsSelected(false);
  customPointMeasures.push_back(measures[1]);
  // Window Construction (2,2)
  EXPECT_EQ("Window Construction",variables[2].name());
  measures = variables[2].cast<MeasureGroup>().measures(false);
  ASSERT_EQ(2u,measures.size());
  EXPECT_TRUE(measures[0].optionalCast<NullMeasure>());
  customPointMeasures.push_back(measures[1]);
  // Fan Efficiency (2,1)
  EXPECT_EQ("Fan Efficiency",variables[3].name());
  measures = variables[3].cast<MeasureGroup>().measures(false);
  ASSERT_EQ(2u,measures.size());
  EXPECT_TRUE(measures[0].optionalCast<NullMeasure>());
  measures[1].setIsSelected(false);
  customPointMeasures.push_back(measures[1]);
  // Fan Motor Efficiency (2,1)
  EXPECT_EQ("Fan Motor Efficiency",variables[4].name());
  measures = variables[4].cast<MeasureGroup>().measures(false);
  ASSERT_EQ(2u,measures.size());
  EXPECT_TRUE(measures[0].optionalCast<NullMeasure>());
  measures[1].setIsSelected(false);
  customPointMeasures.push_back(measures[1]);
  // Boiler Efficiency (2,1)
  EXPECT_EQ("Boiler Efficiency",variables[5].name());
  measures = variables[5].cast<MeasureGroup>().measures(false);
  ASSERT_EQ(2u,measures.size());
  EXPECT_TRUE(measures[0].optionalCast<NullMeasure>());
  measures[1].setIsSelected(false);
  customPointMeasures.push_back(measures[1]);
  // Chiller COP (2,1)
  EXPECT_EQ("Chiller COP",variables[6].name());
  measures = variables[6].cast<MeasureGroup>().measures(false);
  ASSERT_EQ(2u,measures.size());
  EXPECT_TRUE(measures[0].optionalCast<NullMeasure>());
  measures[1].setIsSelected(false);
  customPointMeasures.push_back(measures[1]);
  analysis.setProblem(problem);

  // CREATE ANALYSIS
  DesignOfExperimentsOptions algOptions(DesignOfExperimentsType::FullFactorial);
  DesignOfExperiments algorithm(algOptions);
  analysis.setAlgorithm(algorithm);

  // ADD CUSTOM POINT TO ANALYSIS
  analysis.addDataPoint(customPointMeasures);

  // RUN ANALYSIS
  AnalysisDriver analysisDriver = project.analysisDriver();
  AnalysisRunOptions runOptions = standardRunOptions(analysisDriver.database().path().parent_path());
  CurrentAnalysis currentAnalysis = analysisDriver.run(analysis,runOptions);
  EXPECT_TRUE(analysisDriver.waitForFinished());

  // CHECK RESULTS
  AnalysisRecord analysisRecord = project.analysisRecord();
  EXPECT_EQ(4,analysisRecord.problemRecord().combinatorialSize(true).get());
  EXPECT_EQ(128,analysisRecord.problemRecord().combinatorialSize(false).get());
  // problem w/ selected measures + one custom point
  EXPECT_EQ(5u, analysisRecord.dataPointRecords().size());
  BOOST_FOREACH(const DataPointRecord& dataPointRecord, analysisRecord.dataPointRecords()) {
    EXPECT_TRUE(dataPointRecord.isComplete());
    EXPECT_FALSE(dataPointRecord.failed());
  }

  // CREATE CSV REPORT
  StringVector row;

  row.push_back("Id");             // data point record id
  row.push_back("LPD");            // on/off for each measure
  row.push_back("PLD");
  row.push_back("Win. Cons.");
  row.push_back("Fan Eff.");
  row.push_back("Fan Motor Eff.");
  row.push_back("Boiler Eff.");
  row.push_back("Chiller COP");
  row.push_back("Total Site Energy");
  row.push_back("Total Source Energy");
// TODO: Put economics back into EnergyPlusPostProces?!
//  row.push_back("Annual Total Utility Cost");
//  row.push_back("Delta Annual Total Utility Cost");
//  row.push_back("Cost Estimate");
//  row.push_back("Delta Cost Estimate");
  row.push_back("Percent Savings");
//  row.push_back("Simple Payback");
//  row.push_back("5 Year TLCC");

  row.clear();
  row.push_back("");
  row.push_back("");
  row.push_back("");
  row.push_back("");
  row.push_back("");
  row.push_back("");
  row.push_back("");
  row.push_back("");
  row.push_back("(GJ)");
  row.push_back("(GJ)");
//  row.push_back("($)");
//  row.push_back("($)");
//  row.push_back("($)");
//  row.push_back("($)");
  row.push_back("(%)");
//  row.push_back("(y)");
//  row.push_back("($)");

  // Get baseline information.
  std::vector<QVariant> baselineValues(7u,QVariant(0));
  DataPointRecordVector dataPointRecords = analysisRecord.getDataPointRecords(baselineValues);
  ASSERT_EQ(1u,dataPointRecords.size());
  DataPointRecord baselineDataPointRecord = dataPointRecords[0];
  ASSERT_TRUE(baselineDataPointRecord.isComplete());
  ASSERT_FALSE(baselineDataPointRecord.failed());
  AttributeRecordVector attributeRecords = baselineDataPointRecord.attributeRecords();
  NameFinder<AttributeRecord> siteFinder("Total Site Energy",false);
  AttributeRecordVector::const_iterator it = std::find_if(attributeRecords.begin(),
                                                          attributeRecords.end(),
                                                          siteFinder);
  ASSERT_FALSE(it == attributeRecords.end());
  double baselineTotalSiteEnergy = it->attributeValueAsDouble();
  NameFinder<AttributeRecord> sourceFinder("Total Source Energy",false);
  // it = std::find_if(attributeRecords.begin(),attributeRecords.end(),sourceFinder);
  // ASSERT_FALSE(it == attributeRecords.end());
  // double baselineTotalSourceEnergy = it->attributeValueAsDouble();

  dataPointRecords = analysisRecord.successfulDataPointRecords();
  std::stringstream fileName;
  fileName << analysis.name() << "_Report.csv";
//  openstudio::path reportPath = defaultWorkingDirectory(analysisDriver.database()) /
//      toPath(fileName.str());
  openstudio::path reportPath = analysisDriver.database().path().parent_path() /
      toPath(fileName.str());
}

TEST_F(AnalysisDriverFixture, SequentialSearch_IdfOnly) {
  // SET UP PROJECT
  SimpleProject project = getCleanSimpleProject("SequentialSearch_IdfOnly");
  Analysis analysis = project.analysis();

  // DEFINE SEED
  FileReference seedModel(resourcesPath() / openstudio::toPath("energyplus/8-0-0/5ZoneAirCooled/in.idf"));
  FileReference weatherFile(energyPlusWeatherDataPath() / toPath("USA_IL_Chicago-OHare.Intl.AP.725300_TMY3.epw"));
  project.setSeed(seedModel);
  analysis.setWeatherFile(weatherFile);

  // RETRIEVE PROBLEM, SET OBJECTIVE FUNCTIONS
  Problem problem = retrieveProblem("IdfOnly",false,true);
  OutputAttributeContinuousVariable objective1Variable("Cooling Electricity Use","EndUses.Electricity.Cooling.General");
  OutputAttributeContinuousVariable objective2Variable("Heating Gas Use","EndUses.Gas.Heating.General");
  FunctionVector objectiveFunctions;
  LinearFunction objective1(objective1Variable.name(),VariableVector(1u,objective1Variable.cast<Variable>()));
  objectiveFunctions.push_back(objective1.cast<Function>());
  LinearFunction objective2(objective2Variable.name(),VariableVector(1u,objective2Variable.cast<Variable>()));
  objectiveFunctions.push_back(objective2.cast<Function>());
  OptimizationProblem optimizationProblem("IdfOnly Minimize Site and Source Energy",
                                          objectiveFunctions,
                                          problem.workflow());
  analysis.setProblem(optimizationProblem);

  // DEFINE ALGORITHM, INCLUDING OPTIONS
  SequentialSearchOptions options(1);
  options.setMaxIter(1); // just run baseline
  SequentialSearch sequentialSearch(options);
  analysis.setAlgorithm(sequentialSearch);

  // RUN ANALYSIS
  AnalysisDriver analysisDriver = project.analysisDriver();
  AnalysisRunOptions runOptions = standardRunOptions(analysisDriver.database().path().parent_path());
  CurrentAnalysis currentAnalysis = analysisDriver.run(analysis,runOptions);
  EXPECT_TRUE(analysisDriver.waitForFinished());

  // CHECK RESULTS
  AnalysisRecord analysisRecord = project.analysisRecord();
  DataPointRecordVector dataPointRecords = analysisRecord.dataPointRecords();
  EXPECT_EQ(1u,dataPointRecords.size());
  ASSERT_FALSE(dataPointRecords.empty());
  EXPECT_TRUE(dataPointRecords[0].isComplete());
  EXPECT_FALSE(dataPointRecords[0].failed());
  TagRecordVector baselineTags = dataPointRecords[0].tagRecords();
  EXPECT_EQ(3u,baselineTags.size());
  dataPointRecords = analysisRecord.getDataPointRecords("current");
  EXPECT_EQ(1u,dataPointRecords.size());
  dataPointRecords = analysisRecord.getDataPointRecords("iter0");
  EXPECT_EQ(1u,dataPointRecords.size());
  dataPointRecords = analysisRecord.getDataPointRecords("ss");
  EXPECT_EQ(1u,dataPointRecords.size());
  // Get timestamp on xml file and make sure it doesn't change during the remainder of
  // the test.
  DataPoint dataPoint = dataPointRecords[0].dataPoint();
  FileReferenceVector xmlFileRefs = dataPoint.xmlOutputData();
  ASSERT_FALSE(xmlFileRefs.empty());
  FileReference xmlFileRef = xmlFileRefs[0];
  QFileInfo xmlFileInfo(toQString(xmlFileRef.path()));
  QDateTime xmlFileModifiedTestTime = xmlFileInfo.lastModified();

  project.save();
  analysisRecord = project.analysisRecord();

  // CREATE AND CHECK NEXT ITERATION OF DATA POINTS
  sequentialSearch = analysis.algorithm().get().cast<SequentialSearch>();
  EXPECT_EQ(0,sequentialSearch.iter());
  sequentialSearch.sequentialSearchOptions().setMaxIter(3); // do two more iterations
  sequentialSearch.createNextIteration(analysis);
  EXPECT_EQ(1,sequentialSearch.iter());
  // 7 variables with two options (null, other) each
  DataPointVector dataPoints = analysis.dataPointsToQueue();
  EXPECT_EQ(7u,dataPoints.size());
  BOOST_FOREACH(const DataPoint& dataPoint,dataPoints) {
    EXPECT_TRUE(dataPoint.optionalCast<OptimizationDataPoint>());
  }

  // RUN THE NEXT TWO ITERATIONS
  currentAnalysis = analysisDriver.run(analysis,runOptions);
  EXPECT_TRUE(analysisDriver.waitForFinished());

  // CHECK RESULTS
  analysisRecord = project.analysisRecord();
  sequentialSearch = analysis.algorithm().get().cast<SequentialSearch>();
  EXPECT_EQ(2,sequentialSearch.iter());
  EXPECT_TRUE(analysis.dataPointsToQueue().empty());
  EXPECT_TRUE(analysis.failedDataPoints().empty());
  // RunManager should not re-run the first (or any other) point
  EXPECT_EQ(xmlFileModifiedTestTime,xmlFileInfo.lastModified());

  project.save();
  analysisRecord = project.analysisRecord();

  // RUN TO COMPLETION
 // options.clearMaxIter();
  sequentialSearch.sequentialSearchOptions().clearMaxIter();
  currentAnalysis = analysisDriver.run(analysis,runOptions);
  EXPECT_TRUE(analysisDriver.waitForFinished());

  // CHECK RESULTS
  analysisRecord = project.analysisRecord();
  sequentialSearch = analysis.algorithm().get().cast<SequentialSearch>();
  EXPECT_TRUE(analysis.dataPointsToQueue().empty());
  EXPECT_TRUE(analysis.failedDataPoints().empty());
  std::stringstream ss;
  for (int i = 0, n = sequentialSearch.iter(); i <= n; ++i) {
    ss << "iter" << i;
    if (i < n) {
      EXPECT_FALSE(analysis.getDataPoints(ss.str()).empty());
    }
    ss.str("");
  }
  // RunManager should not re-run the first (or any other) point
  EXPECT_EQ(xmlFileModifiedTestTime,xmlFileInfo.lastModified());

  analysisRecord = project.analysisRecord();
}
