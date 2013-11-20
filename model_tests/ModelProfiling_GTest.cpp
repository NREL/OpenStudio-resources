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
#include "ModelProfileFixture.hpp"

#include <model/Model.hpp>
#include <osversion/VersionTranslator.hpp>

using namespace openstudio;
using namespace openstudio::model;
using namespace openstudio::osversion;

TEST_F(ModelProfileFixture,ModelLoadAndSave_SmallModel) {
  for (int i = 0; i < 100; ++i) {
    OptionalModel model = Model::load(smallModelPath());
    ASSERT_TRUE(model);
    bool test = model->save(smallModelPath(),true);
    EXPECT_TRUE(test);
  }
}

TEST_F(ModelProfileFixture,ModelLoadAndSave_MediumModel_GeometryHeavy) {
  for (int i = 0; i < 5; ++i) {
    OptionalModel model = Model::load(mediumGeometryHeavyModelPath());
    ASSERT_TRUE(model);
    bool test = model->save(mediumGeometryHeavyModelPath(),true);
    EXPECT_TRUE(test);
  }
}

TEST_F(ModelProfileFixture,ModelLoadAndSave_MediumModel_HVACHeavy) {
  for (int i = 0; i < 5; ++i) {
    OptionalModel model = Model::load(mediumHVACHeavyModelPath());
    ASSERT_TRUE(model);
    bool test = model->save(mediumHVACHeavyModelPath(),true);
    EXPECT_TRUE(test);
  }
}

TEST_F(ModelProfileFixture,VersionTranslator_MediumModel_GeometryHeavy) {
  // these results will not be confounded with IddFile loading because
  // this was already done in the fixture
  for (int i = 0; i < 5; ++i) {
    VersionTranslator translator;
    OptionalModel temp = translator.loadModel(mediumGeometryHeavyModelOriginalPath());
    EXPECT_TRUE(temp);
  }
}

TEST_F(ModelProfileFixture,VersionTranslator_MediumModel_HVACHeavy) {
  // these results will not be confounded with IddFile loading because
  // this was already done in the fixture
  for (int i = 0; i < 5; ++i) {
    VersionTranslator translator;
    OptionalModel temp = translator.loadModel(mediumHVACHeavyModelOriginalPath());
    EXPECT_TRUE(temp);
  }
}

