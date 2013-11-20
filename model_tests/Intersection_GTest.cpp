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

#include <model_tests/ModelFixture.hpp>
#include <model_tests/ModelBin.hxx> 

#include <model/Model.hpp>
#include <model/Space.hpp>
#include <model/Space_Impl.hpp>
#include <model/Surface.hpp>
#include <model/Surface_Impl.hpp>
#include <model/BuildingStory.hpp>

#include <osversion/VersionTranslator.hpp>

#include <utilities/core/Logger.hpp>
#include <utilities/core/StringStreamLogSink.hpp>
#include <utilities/data/Attribute.hpp>
#include <utilities/geometry/Transformation.hpp>
#include <utilities/geometry/BoundingBox.hpp>
#include <utilities/math/FloatCompare.hpp>

#include <boost/foreach.hpp>

#include <QThread>

using namespace openstudio;
using namespace openstudio::model;
using namespace openstudio::osversion;

bool intersectAndMatch(Model model){
  std::vector<Space> spaces = model.getModelObjects<Space>();
  unsigned N = spaces.size();
  std::vector<BoundingBox> boundingBoxes;
  BOOST_FOREACH(Space space, spaces){
    Transformation t = space.buildingTransformation();
    BoundingBox boundingBox = t*space.boundingBox();
    boundingBoxes.push_back(boundingBox);
  } 
  for (unsigned i = 0; i < N; ++i){
    for (unsigned j = i+1; j < N; ++j){
      if (boundingBoxes[i].intersects(boundingBoxes[j])){
        spaces[i].intersectSurfaces(spaces[j]);
        spaces[i].matchSurfaces(spaces[j]);
      }
    }
  }
  return true;
}

TEST_F(IntersectionFixture, Model_22) {
  VersionTranslator vt;
  
  boost::optional<model::Model> model = vt.loadModel(Paths::intersectionTestsPath() / toPath("22.osm"));
  ASSERT_TRUE(model);

  model->save(Paths::intersectionTestsRunPath() / toPath("22.osm"), true);

  StringStreamLogSink logSink;
  logSink.setLogLevel(Error);
  logSink.setThreadId(QThread::currentThread());

  bool test = intersectAndMatch(*model);
  EXPECT_TRUE(test);

  BOOST_FOREACH(LogMessage msg, logSink.logMessages()){
    EXPECT_NE(Error, msg.logLevel()) << msg.logMessage();
  }

  model->save(Paths::intersectionTestsRunPath() / toPath("22_intersected.osm"), true);
}


TEST_F(IntersectionFixture, Model_74) {
  VersionTranslator vt;

  boost::optional<model::Model> model = vt.loadModel(Paths::intersectionTestsPath() / toPath("74.osm"));
  ASSERT_TRUE(model);

  model->save(Paths::intersectionTestsRunPath() / toPath("74.osm"), true);

  StringStreamLogSink logSink;
  logSink.setLogLevel(Error);
  logSink.setThreadId(QThread::currentThread());

  bool test = intersectAndMatch(*model);
  EXPECT_TRUE(test);

  BOOST_FOREACH(LogMessage msg, logSink.logMessages()){
    EXPECT_NE(Error, msg.logLevel()) << msg.logMessage();
  }

  model->save(Paths::intersectionTestsRunPath() / toPath("74_intersected.osm"), true);
}

TEST_F(IntersectionFixture, Model_131) {
  VersionTranslator vt;

  boost::optional<model::Model> model = vt.loadModel(Paths::intersectionTestsPath() / toPath("131.osm"));
  ASSERT_TRUE(model);

  model->save(Paths::intersectionTestsRunPath() / toPath("131.osm"), true);

  StringStreamLogSink logSink;
  logSink.setLogLevel(Error);
  logSink.setThreadId(QThread::currentThread());

  bool test = intersectAndMatch(*model);
  EXPECT_TRUE(test);

  BOOST_FOREACH(LogMessage msg, logSink.logMessages()){
    EXPECT_NE(Error, msg.logLevel()) << msg.logMessage();
  }

  model->save(Paths::intersectionTestsRunPath() / toPath("131_intersected.osm"), true);
}

/*
TEST_F(IntersectionFixture, Model_136) {
  VersionTranslator vt;

  boost::optional<model::Model> model = vt.loadModel(Paths::intersectionTestsPath() / toPath("136.osm"));
  ASSERT_TRUE(model);

  model->save(Paths::intersectionTestsRunPath() / toPath("136.osm"), true);

  StringStreamLogSink logSink;
  logSink.setLogLevel(Error);
  logSink.setThreadId(QThread::currentThread());

  bool test = intersectAndMatch(*model);
  EXPECT_TRUE(test);

  BOOST_FOREACH(LogMessage msg, logSink.logMessages()){
    EXPECT_NE(Error, msg.logLevel()) << msg.logMessage();
  }

  model->save(Paths::intersectionTestsRunPath() / toPath("136_intersected.osm"), true);
}
*/

TEST_F(IntersectionFixture, Model_145) {
  VersionTranslator vt;

  boost::optional<model::Model> model = vt.loadModel(Paths::intersectionTestsPath() / toPath("145.osm"));
  ASSERT_TRUE(model);

  model->save(Paths::intersectionTestsRunPath() / toPath("145.osm"), true);

  StringStreamLogSink logSink;
  logSink.setLogLevel(Error);
  logSink.setThreadId(QThread::currentThread());

  bool test = intersectAndMatch(*model);
  EXPECT_TRUE(test);

  BOOST_FOREACH(LogMessage msg, logSink.logMessages()){
    EXPECT_NE(Error, msg.logLevel()) << msg.logMessage();
  }

  model->save(Paths::intersectionTestsRunPath() / toPath("145_intersected.osm"), true);
}

TEST_F(IntersectionFixture, Model_146) {
  VersionTranslator vt;

  boost::optional<model::Model> model = vt.loadModel(Paths::intersectionTestsPath() / toPath("146.osm"));
  ASSERT_TRUE(model);

  model->save(Paths::intersectionTestsRunPath() / toPath("146.osm"), true);

  StringStreamLogSink logSink;
  logSink.setLogLevel(Error);
  logSink.setThreadId(QThread::currentThread());

  bool test = intersectAndMatch(*model);
  EXPECT_TRUE(test);

  BOOST_FOREACH(LogMessage msg, logSink.logMessages()){
    EXPECT_NE(Error, msg.logLevel()) << msg.logMessage();
  }

  model->save(Paths::intersectionTestsRunPath() / toPath("146_intersected.osm"), true);
}

TEST_F(IntersectionFixture, Model_156) {
  VersionTranslator vt;

  boost::optional<model::Model> model = vt.loadModel(Paths::intersectionTestsPath() / toPath("156.osm"));
  ASSERT_TRUE(model);

  model->save(Paths::intersectionTestsRunPath() / toPath("156.osm"), true);

  StringStreamLogSink logSink;
  logSink.setLogLevel(Error);
  logSink.setThreadId(QThread::currentThread());

  bool test = intersectAndMatch(*model);
  EXPECT_TRUE(test);

  BOOST_FOREACH(LogMessage msg, logSink.logMessages()){
    EXPECT_NE(Error, msg.logLevel()) << msg.logMessage();
  }

  model->save(Paths::intersectionTestsRunPath() / toPath("156_intersected.osm"), true);
}

TEST_F(IntersectionFixture, Model_356) {
  VersionTranslator vt;

  boost::optional<model::Model> model = vt.loadModel(Paths::intersectionTestsPath() / toPath("356.osm"));
  ASSERT_TRUE(model);

  model->save(Paths::intersectionTestsRunPath() / toPath("356.osm"), true);

  StringStreamLogSink logSink;
  logSink.setLogLevel(Error);
  logSink.setThreadId(QThread::currentThread());

  bool test = intersectAndMatch(*model);
  EXPECT_TRUE(test);

  BOOST_FOREACH(LogMessage msg, logSink.logMessages()){
    EXPECT_NE(Error, msg.logLevel()) << msg.logMessage();
  }

  model->save(Paths::intersectionTestsRunPath() / toPath("356_intersected.osm"), true);
}

TEST_F(IntersectionFixture, Model_370) {
  VersionTranslator vt;

  boost::optional<model::Model> model = vt.loadModel(Paths::intersectionTestsPath() / toPath("370.osm"));
  ASSERT_TRUE(model);

  model->save(Paths::intersectionTestsRunPath() / toPath("370.osm"), true);

  StringStreamLogSink logSink;
  logSink.setLogLevel(Error);
  logSink.setThreadId(QThread::currentThread());

  bool test = intersectAndMatch(*model);
  EXPECT_TRUE(test);

  BOOST_FOREACH(LogMessage msg, logSink.logMessages()){
    EXPECT_NE(Error, msg.logLevel()) << msg.logMessage();
  }

  model->save(Paths::intersectionTestsRunPath() / toPath("370_intersected.osm"), true);
}

TEST_F(IntersectionFixture, Model_test3) {
  VersionTranslator vt;

  boost::optional<model::Model> model = vt.loadModel(Paths::intersectionTestsPath() / toPath("test3.osm"));
  ASSERT_TRUE(model);

  model->save(Paths::intersectionTestsRunPath() / toPath("test3.osm"), true);

  StringStreamLogSink logSink;
  logSink.setLogLevel(Error);
  logSink.setThreadId(QThread::currentThread());

  bool test = intersectAndMatch(*model);
  EXPECT_TRUE(test);

  BOOST_FOREACH(LogMessage msg, logSink.logMessages()){
    EXPECT_NE(Error, msg.logLevel()) << msg.logMessage();
  }

  model->save(Paths::intersectionTestsRunPath() / toPath("test3_intersected.osm"), true);
}

TEST_F(IntersectionFixture, Model_test4) {
  VersionTranslator vt;

  boost::optional<model::Model> model = vt.loadModel(Paths::intersectionTestsPath() / toPath("test4.osm"));
  ASSERT_TRUE(model);

  model->save(Paths::intersectionTestsRunPath() / toPath("test4.osm"), true);
  
  StringStreamLogSink logSink;
  logSink.setLogLevel(Error);
  logSink.setThreadId(QThread::currentThread());

  bool test = intersectAndMatch(*model);
  EXPECT_TRUE(test);

  BOOST_FOREACH(LogMessage msg, logSink.logMessages()){
    EXPECT_NE(Error, msg.logLevel()) << msg.logMessage();
  }

  model->save(Paths::intersectionTestsRunPath() / toPath("test4_intersected.osm"), true);
}
