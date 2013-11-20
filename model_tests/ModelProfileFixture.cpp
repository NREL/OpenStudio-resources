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

#include "ModelProfileFixture.hpp"

#include <osversion/VersionTranslator.hpp>

#include <model/Model.hpp>

#include <utilities/core/Assert.hpp>

#include <resources.hxx>

using namespace openstudio;
using namespace openstudio::model;
using namespace openstudio::osversion;

// initialize static variables
boost::optional<openstudio::FileLogSink> ModelProfileFixture::logFile;

void ModelProfileFixture::SetUpTestCase() {
  // set up logging
  logFile = FileLogSink(toPath("./ModelProfileFixture.log"));
  logFile->setLogLevel(Info);
  openstudio::Logger::instance().standardOutLogger().disable();

  // load and save models
  VersionTranslator translator;
  Model toSave = exampleModel();
  toSave.save(smallModelPath(),true);
  OptionalModel temp = translator.loadModel(mediumGeometryHeavyModelOriginalPath());
  BOOST_ASSERT(temp);
  temp->save(mediumGeometryHeavyModelPath(),true);
  temp = translator.loadModel(mediumHVACHeavyModelOriginalPath());
  BOOST_ASSERT(temp);
  temp->save(mediumHVACHeavyModelPath(),true);
}

void ModelProfileFixture::TearDownTestCase() {
  logFile->disable();
}

openstudio::path ModelProfileFixture::smallModelPath() {
  return resourcesPath() / toPath("model/toLoad/Small.osm");
}

openstudio::path ModelProfileFixture::mediumGeometryHeavyModelPath() {
  return resourcesPath() / toPath("model/toLoad/Medium_GeometryHeavy.osm");
}

openstudio::path ModelProfileFixture::mediumHVACHeavyModelPath() {
  return resourcesPath() / toPath("model/toLoad/Medium_HVACHeavy.osm");
}

openstudio::path ModelProfileFixture::mediumGeometryHeavyModelOriginalPath() {
  return resourcesPath() / toPath("model/Medium_GeometryHeavy.osm");
}

openstudio::path ModelProfileFixture::mediumHVACHeavyModelOriginalPath() {
  return resourcesPath() / toPath("model/Medium_HVACHeavy.osm");
}
