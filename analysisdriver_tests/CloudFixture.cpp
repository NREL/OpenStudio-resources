/**********************************************************************
*  Copyright (c) 2008-2013, Alliance for Sustainable Energy.  
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

#include "CloudFixture.hpp"

#include <analysisdriver/test/AnalysisDriverTestLibrary.hpp>

#include <utilities/cloud/OSServer.hpp>
#include <utilities/cloud/VagrantProvider.hpp>

#include <boost/filesystem.hpp>
#include <boost/foreach.hpp>

#include <resources.hxx>
#include <Vagrant.hxx>

using namespace openstudio;
using namespace openstudio::analysisdriver;

void CloudFixture::SetUp() {}

void CloudFixture::TearDown() {}

void CloudFixture::SetUpTestCase() {
  // set up logging
  openstudio::path outputDataDirectory = productsPath() / toPath("CloudFixtureData");
  if (!boost::filesystem::exists(outputDataDirectory)) {
    boost::filesystem::create_directory(outputDataDirectory);
  }
  logFile = FileLogSink(outputDataDirectory / toPath("CloudFixture.log"));
  logFile->setLogLevel(Debug);  
  logFile->setChannelRegex(boost::regex("(.*analysis.*|.*cloud.*)"));
  Logger::instance().standardOutLogger().disable();

  // set up library
  AnalysisDriverTestLibrary::instance().initialize( 
    outputDataDirectory,
    sourcePath() / toPath("analysisdriver/BaselineModels"));
  
  // start virtual box
  // virtualBox = new QProcess();
  // virtualBox->start("VirtualBox.exe",QStringList());
  // virtualBox->waitForStarted();  
  
  // start vagrant provider
  provider = boost::shared_ptr<VagrantProvider>(new VagrantProvider());
  // configure
  VagrantSettings settings;
  settings.setServerPath(vagrantServerPath());
  settings.setServerUrl(Url("http://localhost:8080"));
  settings.setWorkerPath(vagrantWorkerPath());
  settings.setWorkerUrl(Url("http://localhost:8081"));
  settings.setHaltOnStop(true);
  settings.setUsername("vagrant");
  settings.setPassword("vagrant");
  settings.signUserAgreement(true);
  provider->setSettings(settings);
  // start machines
  LOG(Debug,"Starting Server.");
  provider->requestStartServer();
  provider->waitForServer();
  LOG(Debug,"Starting Worker.");
  provider->requestStartWorkers();
  provider->waitForWorkers();
  if (!(provider->serverRunning() && provider->workersRunning())) {
    LOG_AND_THROW("Unable to start up VagrantProvider.");
  }

  // clear out existing projects
  OptionalUrl serverUrl = provider->session().serverUrl();
  if (!serverUrl) {
    LOG_AND_THROW("No server url");
  }
  OSServer server(*serverUrl);
  UUIDVector projectUUIDs = server.projectUUIDs();
  BOOST_FOREACH(const UUID& projectUUID,projectUUIDs) {
    server.deleteProject(projectUUID);
  }
}

void CloudFixture::TearDownTestCase() {
  // stop vagrant provider
  // provider->requestTerminate();
  // provider->waitForTerminated();
  // provider = boost::shared_ptr<VagrantProvider>();

  // stop VirtualBox
  // virtualBox->close();
  // virtualBox->waitForFinished();
  // virtualBox->deleteLater();
  
  // stop logging
  logFile->disable();
}

boost::optional<openstudio::FileLogSink> CloudFixture::logFile;
QProcess* CloudFixture::virtualBox;
boost::shared_ptr<openstudio::VagrantProvider> CloudFixture::provider;
