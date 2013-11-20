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

#include "EnergyPlusProfileFixture.hpp"

#include <osversion/VersionTranslator.hpp>

#include <utilities/core/Assert.hpp>

#include <resources.hxx>

using namespace openstudio;
using namespace openstudio::model;
using namespace openstudio::osversion;

// initialize static variables
boost::optional<openstudio::FileLogSink> EnergyPlusProfileFixture::logFile;
Model EnergyPlusProfileFixture::mediumGeometryHeavyModel;
Model EnergyPlusProfileFixture::mediumHVACHeavyModel;

void EnergyPlusProfileFixture::SetUpTestCase() {
  // set up logging
  logFile = FileLogSink(toPath("./EnergyPlusProfileFixture.log"));
  logFile->setLogLevel(Info);
  openstudio::Logger::instance().standardOutLogger().disable();

  // load models
  VersionTranslator translator;
  OptionalModel temp = translator.loadModel(resourcesPath() / toPath("model/Medium_GeometryHeavy.osm"));
  BOOST_ASSERT(temp);
  mediumGeometryHeavyModel = temp.get();
  temp = translator.loadModel(resourcesPath() / toPath("model/Medium_HVACHeavy.osm"));
  BOOST_ASSERT(temp);
  mediumHVACHeavyModel = temp.get();
}

void EnergyPlusProfileFixture::TearDownTestCase() {
  logFile->disable();;
}

