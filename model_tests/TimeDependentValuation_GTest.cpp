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
#include <model/TimeDependentValuation.hpp>
#include <model/TimeDependentValuation_Impl.hpp>

#include <model/Model.hpp>
#include <model/Site.hpp>
#include <model/Site_Impl.hpp>
#include <model/Facility.hpp>
#include <model/Facility_Impl.hpp>

#include <utilities/data/Attribute.hpp>
#include <utilities/math/FloatCompare.hpp>

#include <boost/foreach.hpp>

using namespace openstudio;
using namespace openstudio::model;

TEST_P(TimeDependentValuationFixture, DirectQueries) {
  TimeDependentValuation tdv = m_model.getUniqueModelObject<TimeDependentValuation>();

  // test direct TDV queries

  // total TDV (Commercial)
  OptionalDouble od = tdv.energyTimeDependentValuation();
  ASSERT_TRUE(od);
  double energyTDV = *od;
  od = tdv.costTimeDependentValuation();
  ASSERT_TRUE(od);
  double costTDV = *od;
  EXPECT_TRUE(energyTDV > 0);
  EXPECT_TRUE(costTDV > 0);
  EXPECT_NE(energyTDV,costTDV);

  // Commercial/Residential differences in total TDV
  tdv.setActiveBuildingSector(BuildingSector::Residential);
  od = tdv.energyTimeDependentValuation();
  ASSERT_TRUE(od);
  double resEnergyTDV = *od;
  od = tdv.costTimeDependentValuation();
  ASSERT_TRUE(od);
  double resCostTDV = *od;
  EXPECT_TRUE(resEnergyTDV > 0);
  EXPECT_TRUE(resCostTDV > 0);
  EXPECT_NE(energyTDV,resEnergyTDV);
  EXPECT_NE(costTDV,resCostTDV);
  EXPECT_NE(resEnergyTDV,resCostTDV);
  // expect Commercial/Residential difference within an order of magnitude
  double diffEnergyTDVLog = std::log10(energyTDV) - std::log10(resEnergyTDV);
  double diffCostTDVLog = std::log10(costTDV) - std::log10(resCostTDV);
  EXPECT_TRUE(diffEnergyTDVLog > -1.0); EXPECT_TRUE(diffEnergyTDVLog < 1.0);
  EXPECT_TRUE(diffCostTDVLog > -1.0); EXPECT_TRUE(diffCostTDVLog < 1.0);
  tdv.setActiveBuildingSector(BuildingSector::Commercial);

  // TDV by FuelType (Commercial)
  double energyTDVTotal(0.0);
  double costTDVTotal(0.0);
  FuelTypeVector fuelTypes = tdv.availableFuelTypes();
  BOOST_FOREACH(const FuelType& fuelType,fuelTypes) {
    od = tdv.getEnergyTimeDependentValuation(fuelType);
    if ((fuelType == FuelType::Electricity) || (fuelType == FuelType::Gas)) {
      EXPECT_TRUE(od);
    }
    if (!od) { continue; }
    double oneFuelTypeEnergyTDV = *od;
    od = tdv.getCostTimeDependentValuation(fuelType);
    ASSERT_TRUE(od);
    double oneFuelTypeCostTDV = *od;
    if (fuelType == FuelType::Electricity) {
      EXPECT_TRUE(oneFuelTypeEnergyTDV > 0.0);
      EXPECT_TRUE(oneFuelTypeCostTDV > 0.0);
    }
    if (!equal(oneFuelTypeEnergyTDV,0.0)) {
      EXPECT_NE(oneFuelTypeEnergyTDV,oneFuelTypeCostTDV);
    }
    energyTDVTotal += oneFuelTypeEnergyTDV;
    costTDVTotal += oneFuelTypeCostTDV;
  }
  EXPECT_DOUBLE_EQ(energyTDV,energyTDVTotal);
  EXPECT_DOUBLE_EQ(costTDV,costTDVTotal);
}

TEST_P(TimeDependentValuationFixture, FacilityAttributes) {
  TimeDependentValuation tdv = m_model.getUniqueModelObject<TimeDependentValuation>();

  // get relevant values from tdv
  OptionalDouble od  = tdv.energyTimeDependentValuation();
  ASSERT_TRUE(od); double energyTDV = *od;
  od = tdv.costTimeDependentValuation();
  ASSERT_TRUE(od); double costTDV = *od;
  od = tdv.getEnergyTimeDependentValuation(FuelType::Electricity);
  ASSERT_TRUE(od); double elecEnergyTDV = *od;
  od = tdv.getCostTimeDependentValuation(FuelType::Electricity);
  ASSERT_TRUE(od); double elecCostTDV = *od;

  // query Facility for TDV values
  Facility facility = tdv.model().getUniqueModelObject<Facility>();

  OptionalAttribute oAttribute = facility.getAttribute("totalEnergyTimeDependentValuation");
  ASSERT_TRUE(oAttribute); Attribute attribute = *oAttribute;
  EXPECT_TRUE(attribute.valueType() == AttributeValueType::Double);
  double attributeValue = attribute.valueAsDouble();
  EXPECT_DOUBLE_EQ(energyTDV,attributeValue);

  oAttribute = facility.getAttribute("totalCostTimeDependentValuation");
  ASSERT_TRUE(oAttribute); attribute = *oAttribute;
  EXPECT_TRUE(attribute.valueType() == AttributeValueType::Double);
  attributeValue = attribute.valueAsDouble();
  EXPECT_DOUBLE_EQ(costTDV,attributeValue);

  oAttribute = facility.getAttribute("electricityEnergyTimeDependentValuation");
  ASSERT_TRUE(oAttribute); attribute = *oAttribute;
  EXPECT_TRUE(attribute.valueType() == AttributeValueType::Double);
  attributeValue = attribute.valueAsDouble();
  EXPECT_DOUBLE_EQ(elecEnergyTDV,attributeValue);

  oAttribute = facility.getAttribute("electricityCostTimeDependentValuation");
  ASSERT_TRUE(oAttribute); attribute = *oAttribute;
  EXPECT_TRUE(attribute.valueType() == AttributeValueType::Double);
  attributeValue = attribute.valueAsDouble();
  EXPECT_DOUBLE_EQ(elecCostTDV,attributeValue);

  oAttribute = facility.getAttribute("fossilFuelEnergyTimeDependentValuation");
  ASSERT_TRUE(oAttribute); attribute = *oAttribute;
  EXPECT_TRUE(attribute.valueType() == AttributeValueType::Double);
  attributeValue = attribute.valueAsDouble();
  EXPECT_NEAR(energyTDV - elecEnergyTDV,attributeValue,1.0E-4);

  oAttribute = facility.getAttribute("fossilFuelCostTimeDependentValuation");
  ASSERT_TRUE(oAttribute); attribute = *oAttribute;
  EXPECT_TRUE(attribute.valueType() == AttributeValueType::Double);
  attributeValue = attribute.valueAsDouble();
  EXPECT_NEAR(costTDV - elecCostTDV,attributeValue,1.0E-8);
}

// INSTANTIATE_TEST_CASE_P(ComputeTimeDependentValuations,
//                         TimeDependentValuationFixture,
//                         ::testing::Values(std::pair<std::string,std::string>("model/Daylighting_Office/","standardsinterface/CEC_TDVs/TDV_2008_kBtu_CZ02.csv"),
//                                           std::pair<std::string,std::string>("model/Daylighting_Office/","standardsinterface/CEC_TDVs/TDV_2008_kBtu_CZ16.csv")));
