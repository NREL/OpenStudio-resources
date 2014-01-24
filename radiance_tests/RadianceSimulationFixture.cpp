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

#include <radiance_tests/RadianceSimulationFixture.hpp>

#include <utilities/core/FileLogSink.hpp>
#include <utilities/core/Path.hpp>
#include <utilities/core/ApplicationPathHelpers.hpp>

#include <openstudio_lib/FileOperations.hpp>

#include <OpenStudio.hxx>

#include <QDir>

void RadianceSimulationFixture::SetUp() {}

void RadianceSimulationFixture::TearDown() {}

void RadianceSimulationFixture::SetUpTestCase() {

  // set up logging
  logFile = openstudio::FileLogSink(openstudio::toPath("./RadianceTestFixture.log"));
  logFile->setLogLevel(Debug);

  // have to copy ruby libs to where getOpenStudioRubyScriptsPath thinks they are
  QString src = QDir(openstudio::toQString(rubyLibDir())).canonicalPath();
  QString dest = QDir(openstudio::toQString(openstudio::getOpenStudioRubyScriptsPath())).canonicalPath();
  if (src != dest){
    bool test = openstudio::copyDir(src, dest);
    ASSERT_TRUE(test);
  }
}

void RadianceSimulationFixture::TearDownTestCase() {}

boost::optional<openstudio::FileLogSink> RadianceSimulationFixture::logFile;




