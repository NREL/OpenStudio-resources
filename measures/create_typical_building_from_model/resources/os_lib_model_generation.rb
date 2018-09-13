# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2018, Alliance for Sustainable Energy, LLC.
# All rights reserved.
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# (1) Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# (2) Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# (3) Neither the name of the copyright holder nor the names of any contributors
# may be used to endorse or promote products derived from this software without
# specific prior written permission from the respective party.
#
# (4) Other than as required in clauses (1) and (2), distributions in any form
# of modifications or other derivative works may not use the "OpenStudio"
# trademark, "OS", "os", or any other confusingly similar designation without
# specific prior written permission from Alliance for Sustainable Energy, LLC.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER(S) AND ANY CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER(S), ANY CONTRIBUTORS, THE
# UNITED STATES GOVERNMENT, OR THE UNITED STATES DEPARTMENT OF ENERGY, NOR ANY OF
# THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
# OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# *******************************************************************************

module OsLib_ModelGeneration
  # simple list of building types that are valid for get_space_types_from_building_type
  def get_building_types
    array = OpenStudio::StringVector.new
    array << 'SecondarySchool'
    array << 'PrimarySchool'
    array << 'SmallOffice'
    array << 'MediumOffice'
    array << 'LargeOffice'
    array << 'SmallHotel'
    array << 'LargeHotel'
    array << 'Warehouse'
    array << 'RetailStandalone'
    array << 'RetailStripmall'
    array << 'QuickServiceRestaurant'
    array << 'FullServiceRestaurant'
    array << 'MidriseApartment'
    array << 'HighriseApartment'
    array << 'Hospital'
    array << 'Outpatient'
    array << 'SuperMarket'

    return array
  end

  # simple list of templates that are valid for get_space_types_from_building_type
  def get_templates
    array = OpenStudio::StringVector.new
    array << 'DOE Ref Pre-1980'
    array << 'DOE Ref 1980-2004'
    array << '90.1-2004'
    array << '90.1-2007'
    # array << '189.1-2009' # if turn this on need to update space_type_array for RetailStripmall
    array << '90.1-2010'
    array << '90.1-2013'
    array << 'NREL ZNE Ready 2017'

    return array
  end

  # calculate aspect ratio from area and perimeter
  def calc_aspect_ratio(a, p)
    l = 0.25 * (p + Math.sqrt(p**2 - 16 * a))
    w = 0.25 * (p - Math.sqrt(p**2 - 16 * a))
    aspect_ratio = l / w

    return aspect_ratio
  end

  # Building Form Defaults from Table 4.2 in Achieving the 30% Goal: Energy and Cost Savings Analysis of ASHRAE Standard 90.1-2010
  # aspect ratio for NA repaced with floor area to perimeter ratio from prototype model
  def building_form_defaults(building_type)
    hash = {}

    # calculate aspect ratios not represented on Table 4.2
    primary_aspet_ratio = calc_aspect_ratio(73958.0, 2060.0)
    secondary_aspet_ratio = calc_aspect_ratio(128112.0, 2447.0)
    outpatient_aspet_ratio = calc_aspect_ratio(14782.0, 588.0)
    supermarket_a = 45001.0
    supermarket_p = 866.0
    supermarket_wwr = 1880.0 / (supermarket_p * 20.0)
    supermarket_aspet_ratio = calc_aspect_ratio(supermarket_a, supermarket_p)

    hash['SmallOffice'] = { aspect_ratio: 1.5, wwr: 0.15, typical_story: 10.0 }
    hash['MediumOffice'] = { aspect_ratio: 1.5, wwr: 0.33, typical_story: 13.0 }
    hash['LargeOffice'] = { aspect_ratio: 1.5, wwr: 0.15, typical_story: 13.0 }
    hash['RetailStandalone'] = { aspect_ratio: 1.28, wwr: 0.07, typical_story: 20.0 }
    hash['RetailStripmall'] = { aspect_ratio: 4.0, wwr: 0.11, typical_story: 17.0 }
    hash['PrimarySchool'] = { aspect_ratio: primary_aspet_ratio.round(1), wwr: 0.35, typical_story: 13.0 }
    hash['SecondarySchool'] = { aspect_ratio: secondary_aspet_ratio.round(1), wwr: 0.33, typical_story: 13.0 }
    hash['Outpatient'] = { aspect_ratio: outpatient_aspet_ratio.round(1), wwr: 0.20, typical_story: 10.0 }
    hash['Hospital'] = { aspect_ratio: 1.33, wwr: 0.16, typical_story: 14.0 }
    hash['SmallHotel'] = { aspect_ratio: 3.0, wwr: 0.11, typical_story: 9.0, first_story: 11.0 }
    hash['LargeHotel'] = { aspect_ratio: 5.1, wwr: 0.27, typical_story: 10.0, first_story: 13.0 }
    # wwr for Warehouse is just for Office space type, all others is building wide
    hash['Warehouse'] = { aspect_ratio: 2.2, wwr: 0.71, typical_story: 28.0 }
    hash['QuickServiceRestaurant'] = { aspect_ratio: 1.0, wwr: 0.14, typical_story: 10.0 }
    hash['FullServiceRestaurant'] = { aspect_ratio: 1.0, wwr: 0.18, typical_story: 10.0 }
    hash['QuickServiceRestaurant'] = { aspect_ratio: 1.0, wwr: 0.18, typical_story: 10.0 }
    hash['MidriseApartment'] = { aspect_ratio: 2.75, wwr: 0.15, typical_story: 10.0 }
    hash['HighriseApartment'] = { aspect_ratio: 2.75, wwr: 0.15, typical_story: 10.0 }
    # SuperMarket inputs come from prototype model
    hash['SuperMarket'] = { aspect_ratio: supermarket_aspet_ratio.round(1), wwr: supermarket_wwr.round(2), typical_story: 20.0 }

    return hash[building_type]
  end

  # create hash of space types and generic ratios of building floor area
  def get_space_types_from_building_type(building_type, template, whole_building = true)
    hash = {}

    # TODO: - Confirm that these work for all standards

    if building_type == 'SecondarySchool'
      hash['Auditorium'] = { ratio: 0.0504, space_type_gen: true, default: false }
      hash['Cafeteria'] = { ratio: 0.0319, space_type_gen: true, default: false }
      hash['Classroom'] = { ratio: 0.3528, space_type_gen: true, default: true }
      hash['Corridor'] = { ratio: 0.2144, space_type_gen: true, default: false }
      hash['Gym'] = { ratio: 0.1646, space_type_gen: true, default: false }
      hash['Kitchen'] = { ratio: 0.0110, space_type_gen: true, default: false }
      hash['Library'] = { ratio: 0.0429, space_type_gen: true, default: false } # not in prototype
      hash['Lobby'] = { ratio: 0.0214, space_type_gen: true, default: false }
      hash['Mechanical'] = { ratio: 0.0349, space_type_gen: true, default: false }
      hash['Office'] = { ratio: 0.0543, space_type_gen: true, default: false }
      hash['Restroom'] = { ratio: 0.0214, space_type_gen: true, default: false }
    elsif building_type == 'PrimarySchool'
      hash['Cafeteria'] = { ratio: 0.0458, space_type_gen: true, default: false }
      hash['Classroom'] = { ratio: 0.5610, space_type_gen: true, default: true }
      hash['Corridor'] = { ratio: 0.1633, space_type_gen: true, default: false }
      hash['Gym'] = { ratio: 0.0520, space_type_gen: true, default: false }
      hash['Kitchen'] = { ratio: 0.0244, space_type_gen: true, default: false }
      # TODO: - confirm if Library is 0.0 for all templates
      hash['Library'] = { ratio: 0.0, space_type_gen: true, default: false }
      hash['Lobby'] = { ratio: 0.0249, space_type_gen: true, default: false }
      hash['Mechanical'] = { ratio: 0.0367, space_type_gen: true, default: false }
      hash['Office'] = { ratio: 0.0642, space_type_gen: true, default: false }
      hash['Restroom'] = { ratio: 0.0277, space_type_gen: true, default: false }
    elsif building_type == 'SmallOffice'
      # TODO: - populate Small, Medium, and Large office for whole_building false
      if whole_building
        hash['WholeBuilding - Sm Office'] = { ratio: 1.0, space_type_gen: true, default: true }
      else
        hash['SmallOffice - Breakroom'] = { ratio: 0.99, space_type_gen: true, default: false }
        hash['SmallOffice - ClosedOffice'] = { ratio: 0.99, space_type_gen: true, default: false }
        hash['SmallOffice - Conference'] = { ratio: 0.99, space_type_gen: true, default: false }
        hash['SmallOffice - Corridor'] = { ratio: 0.99, space_type_gen: true, default: false }
        hash['SmallOffice - Elec/MechRoom'] = { ratio: 0.99, space_type_gen: true, default: false }
        hash['SmallOffice - Lobby'] = { ratio: 0.99, space_type_gen: true, default: false }
        hash['SmallOffice - OpenOffice'] = { ratio: 0.99, space_type_gen: true, default: true }
        hash['SmallOffice - Restroom'] = { ratio: 0.99, space_type_gen: true, default: false }
        hash['SmallOffice - Stair'] = { ratio: 0.99, space_type_gen: true, default: false }
        hash['SmallOffice - Storage'] = { ratio: 0.99, space_type_gen: true, default: false }
        hash['SmallOffice - Classroom'] = { ratio: 0.99, space_type_gen: true, default: false }
        hash['SmallOffice - Dining'] = { ratio: 0.99, space_type_gen: true, default: false }
        hash['WholeBuilding - Sm Office'] = { ratio: 0.0, space_type_gen: true, default: false }
      end
    elsif building_type == 'MediumOffice'
      if whole_building
        hash['WholeBuilding - Md Office'] = { ratio: 1.0, space_type_gen: true, default: true }
      else
        hash['MediumOffice - Breakroom'] = { ratio: 0.99, space_type_gen: true, default: false }
        hash['MediumOffice - ClosedOffice'] = { ratio: 0.99, space_type_gen: true, default: false }
        hash['MediumOffice - Conference'] = { ratio: 0.99, space_type_gen: true, default: false }
        hash['MediumOffice - Corridor'] = { ratio: 0.99, space_type_gen: true, default: false }
        hash['MediumOffice - Elec/MechRoom'] = { ratio: 0.99, space_type_gen: true, default: false }
        hash['MediumOffice - Lobby'] = { ratio: 0.99, space_type_gen: true, default: false }
        hash['MediumOffice - OpenOffice'] = { ratio: 0.99, space_type_gen: true, default: true }
        hash['MediumOffice - Restroom'] = { ratio: 0.99, space_type_gen: true, default: false }
        hash['MediumOffice - Stair'] = { ratio: 0.99, space_type_gen: true, default: false }
        hash['MediumOffice - Storage'] = { ratio: 0.99, space_type_gen: true, default: false }
        hash['MediumOffice - Classroom'] = { ratio: 0.99, space_type_gen: true, default: false }
        hash['MediumOffice - Dining'] = { ratio: 0.99, space_type_gen: true, default: false }
        hash['WholeBuilding - Md Office'] = { ratio: 0.0, space_type_gen: true, default: false }
      end
    elsif building_type == 'LargeOffice'
      if ['DOE Ref Pre-1980', 'DOE Ref 1980-2004'].include?(template)
        if whole_building
          hash['WholeBuilding - Lg Office'] = { ratio: 1.0, space_type_gen: true, default: true }
        else
          hash['BreakRoom'] = { ratio: 0.99, space_type_gen: true, default: false }
          hash['ClosedOffice'] = { ratio: 0.99, space_type_gen: true, default: false }
          hash['Conference'] = { ratio: 0.99, space_type_gen: true, default: false }
          hash['Corridor'] = { ratio: 0.99, space_type_gen: true, default: false }
          hash['Elec/MechRoom'] = { ratio: 0.99, space_type_gen: true, default: false }
          hash['IT_Room'] = { ratio: 0.99, space_type_gen: true, default: false }
          hash['Lobby'] = { ratio: 0.99, space_type_gen: true, default: false }
          hash['OpenOffice'] = { ratio: 0.99, space_type_gen: true, default: true }
          hash['PrintRoom'] = { ratio: 0.99, space_type_gen: true, default: false }
          hash['Restroom'] = { ratio: 0.99, space_type_gen: true, default: false }
          hash['Stair'] = { ratio: 0.99, space_type_gen: true, default: false }
          hash['Storage'] = { ratio: 0.99, space_type_gen: true, default: false }
          hash['Vending'] = { ratio: 0.99, space_type_gen: true, default: false }
          hash['WholeBuilding - Lg Office'] = { ratio: 0.0, space_type_gen: true, default: false }
        end
      else
        if whole_building
          hash['WholeBuilding - Lg Office'] = { ratio: 0.9737, space_type_gen: true, default: true }
          hash['OfficeLarge Data Center'] = { ratio: 0.0094, space_type_gen: true, default: false }
          hash['OfficeLarge Main Data Center'] = { ratio: 0.0169, space_type_gen: true, default: false }
        else
          hash['BreakRoom'] = { ratio: 0.99, space_type_gen: true, default: false }
          hash['ClosedOffice'] = { ratio: 0.99, space_type_gen: true, default: false }
          hash['Conference'] = { ratio: 0.99, space_type_gen: true, default: false }
          hash['Corridor'] = { ratio: 0.99, space_type_gen: true, default: false }
          hash['Elec/MechRoom'] = { ratio: 0.99, space_type_gen: true, default: false }
          hash['IT_Room'] = { ratio: 0.99, space_type_gen: true, default: false }
          hash['Lobby'] = { ratio: 0.99, space_type_gen: true, default: false }
          hash['OpenOffice'] = { ratio: 0.99, space_type_gen: true, default: true }
          hash['PrintRoom'] = { ratio: 0.99, space_type_gen: true, default: false }
          hash['Restroom'] = { ratio: 0.99, space_type_gen: true, default: false }
          hash['Stair'] = { ratio: 0.99, space_type_gen: true, default: false }
          hash['Storage'] = { ratio: 0.99, space_type_gen: true, default: false }
          hash['Vending'] = { ratio: 0.99, space_type_gen: true, default: false }
          hash['WholeBuilding - Lg Office'] = { ratio: 0.0, space_type_gen: true, default: false }
          hash['OfficeLarge Data Center'] = { ratio: 0.0, space_type_gen: true, default: false }
          hash['OfficeLarge Main Data Center'] = { ratio: 0.0, space_type_gen: true, default: false }
        end
      end
    elsif building_type == 'SmallHotel'
      if ['DOE Ref Pre-1980', 'DOE Ref 1980-2004'].include?(template)
        hash['Corridor'] = { ratio: 0.1313, space_type_gen: true, default: false }
        hash['Elec/MechRoom'] = { ratio: 0.0038, space_type_gen: true, default: false }
        hash['ElevatorCore'] = { ratio: 0.0113, space_type_gen: true, default: false }
        hash['Exercise'] = { ratio: 0.0081, space_type_gen: true, default: false }
        hash['GuestLounge'] = { ratio: 0.0406, space_type_gen: true, default: false }
        hash['GuestRoom'] = { ratio: 0.6313, space_type_gen: true, default: true }
        hash['Laundry'] = { ratio: 0.0244, space_type_gen: true, default: false }
        hash['Mechanical'] = { ratio: 0.0081, space_type_gen: true, default: false }
        hash['Meeting'] = { ratio: 0.0200, space_type_gen: true, default: false }
        hash['Office'] = { ratio: 0.0325, space_type_gen: true, default: false }
        hash['PublicRestroom'] = { ratio: 0.0081, space_type_gen: true, default: false }
        hash['StaffLounge'] = { ratio: 0.0081, space_type_gen: true, default: false }
        hash['Stair'] = { ratio: 0.0400, space_type_gen: true, default: false }
        hash['Storage'] = { ratio: 0.0325, space_type_gen: true, default: false }
      else
        hash['Corridor'] = { ratio: 0.1313, space_type_gen: true, default: false }
        hash['Elec/MechRoom'] = { ratio: 0.0038, space_type_gen: true, default: false }
        hash['ElevatorCore'] = { ratio: 0.0113, space_type_gen: true, default: false }
        hash['Exercise'] = { ratio: 0.0081, space_type_gen: true, default: false }
        hash['GuestLounge'] = { ratio: 0.0406, space_type_gen: true, default: false }
        hash['GuestRoom123Occ'] = { ratio: 0.4081, space_type_gen: true, default: true }
        hash['GuestRoom123Vac'] = { ratio: 0.2231, space_type_gen: true, default: false }
        hash['Laundry'] = { ratio: 0.0244, space_type_gen: true, default: false }
        hash['Mechanical'] = { ratio: 0.0081, space_type_gen: true, default: false }
        hash['Meeting'] = { ratio: 0.0200, space_type_gen: true, default: false }
        hash['Office'] = { ratio: 0.0325, space_type_gen: true, default: false }
        hash['PublicRestroom'] = { ratio: 0.0081, space_type_gen: true, default: false }
        hash['StaffLounge'] = { ratio: 0.0081, space_type_gen: true, default: false }
        hash['Stair'] = { ratio: 0.0400, space_type_gen: true, default: false }
        hash['Storage'] = { ratio: 0.0325, space_type_gen: true, default: false }
      end
    elsif building_type == 'LargeHotel'
      hash['Banquet'] = { ratio: 0.0585, space_type_gen: true, default: false }
      hash['Basement'] = { ratio: 0.1744, space_type_gen: false, default: false }
      hash['Cafe'] = { ratio: 0.0166, space_type_gen: true, default: false }
      hash['Corridor'] = { ratio: 0.1736, space_type_gen: true, default: false }
      hash['GuestRoom'] = { ratio: 0.4099, space_type_gen: true, default: true }
      hash['Kitchen'] = { ratio: 0.0091, space_type_gen: true, default: false }
      hash['Laundry'] = { ratio: 0.0069, space_type_gen: true, default: false }
      hash['Lobby'] = { ratio: 0.1153, space_type_gen: true, default: false }
      hash['Mechanical'] = { ratio: 0.0145, space_type_gen: true, default: false }
      hash['Retail'] = { ratio: 0.0128, space_type_gen: true, default: false }
      hash['Storage'] = { ratio: 0.0084, space_type_gen: true, default: false }
    elsif building_type == 'Warehouse'
      hash['Bulk'] = { ratio: 0.6628, space_type_gen: true, default: true }
      hash['Fine'] = { ratio: 0.2882, space_type_gen: true, default: false }
      hash['Office'] = { ratio: 0.0490, space_type_gen: true, default: false }
    elsif building_type == 'RetailStandalone'
      hash['Back_Space'] = { ratio: 0.1656, space_type_gen: true, default: false }
      hash['Entry'] = { ratio: 0.0052, space_type_gen: true, default: false }
      hash['Point_of_Sale'] = { ratio: 0.0657, space_type_gen: true, default: false }
      hash['Retail'] = { ratio: 0.7635, space_type_gen: true, default: true }
    elsif building_type == 'RetailStripmall'
      hash['Strip mall - type 1'] = { ratio: 0.25, space_type_gen: true, default: false }
      hash['Strip mall - type 2'] = { ratio: 0.25, space_type_gen: true, default: false }
      hash['Strip mall - type 3'] = { ratio: 0.50, space_type_gen: true, default: true }
    elsif building_type == 'QuickServiceRestaurant'
      hash['Dining'] = { ratio: 0.5, space_type_gen: true, default: true }
      hash['Kitchen'] = { ratio: 0.5, space_type_gen: true, default: false }
    elsif building_type == 'FullServiceRestaurant'
      hash['Dining'] = { ratio: 0.7272, space_type_gen: true, default: true }
      hash['Kitchen'] = { ratio: 0.2728, space_type_gen: true, default: false }
    elsif building_type == 'MidriseApartment'
      hash['Apartment'] = { ratio: 0.8727, space_type_gen: true, default: true }
      hash['Corridor'] = { ratio: 0.0991, space_type_gen: true, default: false }
      hash['Office'] = { ratio: 0.0282, space_type_gen: true, default: false }
    elsif building_type == 'HighriseApartment'
      hash['Apartment'] = { ratio: 0.8896, space_type_gen: true, default: true }
      hash['Corridor'] = { ratio: 0.0991, space_type_gen: true, default: false }
      hash['Office'] = { ratio: 0.0113, space_type_gen: true, default: false }
    elsif building_type == 'Hospital'
      hash['Basement'] = { ratio: 0.1667, space_type_gen: false, default: false }
      hash['Corridor'] = { ratio: 0.1741, space_type_gen: true, default: false }
      hash['Dining'] = { ratio: 0.0311, space_type_gen: true, default: false }
      hash['ER_Exam'] = { ratio: 0.0099, space_type_gen: true, default: false }
      hash['ER_NurseStn'] = { ratio: 0.0551, space_type_gen: true, default: false }
      hash['ER_Trauma'] = { ratio: 0.0025, space_type_gen: true, default: false }
      hash['ER_Triage'] = { ratio: 0.0050, space_type_gen: true, default: false }
      hash['ICU_NurseStn'] = { ratio: 0.0298, space_type_gen: true, default: false }
      hash['ICE_Open'] = { ratio: 0.0275, space_type_gen: true, default: false }
      hash['ICU_PatRm'] = { ratio: 0.0115, space_type_gen: true, default: false }
      hash['Kitchen'] = { ratio: 0.0414, space_type_gen: true, default: false }
      hash['Lab'] = { ratio: 0.0236, space_type_gen: true, default: false }
      hash['Lobby'] = { ratio: 0.0657, space_type_gen: true, default: false }
      hash['NurseStn'] = { ratio: 0.1723, space_type_gen: true, default: false }
      hash['Office'] = { ratio: 0.0286, space_type_gen: true, default: false }
      hash['OR'] = { ratio: 0.0273, space_type_gen: true, default: false }
      hash['PatCorridor'] = { ratio: 0.0, space_type_gen: true, default: false } # not in prototype
      hash['PatRoom'] = { ratio: 0.0845, space_type_gen: true, default: true }
      hash['PhysTherapy'] = { ratio: 0.0217, space_type_gen: true, default: false }
      hash['Radiology'] = { ratio: 0.0217, space_type_gen: true, default: false }
    elsif building_type == 'Outpatient'
      hash['Anesthesia'] = { ratio: 0.0026, space_type_gen: true, default: false }
      hash['BioHazard'] = { ratio: 0.0014, space_type_gen: true, default: false }
      hash['Cafe'] = { ratio: 0.0103, space_type_gen: true, default: false }
      hash['CleanWork'] = { ratio: 0.0071, space_type_gen: true, default: false }
      hash['Conference'] = { ratio: 0.0082, space_type_gen: true, default: false }
      hash['DresingRoom'] = { ratio: 0.0021, space_type_gen: true, default: false }
      hash['Elec/MechRoom'] = { ratio: 0.0109, space_type_gen: true, default: false }
      hash['ElevatorPumpRoom'] = { ratio: 0.0022, space_type_gen: true, default: false }
      hash['Exam'] = { ratio: 0.1029, space_type_gen: true, default: true }
      hash['Hall'] = { ratio: 0.1924, space_type_gen: true, default: false }
      hash['IT_Room'] = { ratio: 0.0027, space_type_gen: true, default: false }
      hash['Janitor'] = { ratio: 0.0672, space_type_gen: true, default: false }
      hash['Lobby'] = { ratio: 0.0152, space_type_gen: true, default: false }
      hash['LockerRoom'] = { ratio: 0.0190, space_type_gen: true, default: false }
      hash['Lounge'] = { ratio: 0.0293, space_type_gen: true, default: false }
      hash['MedGas'] = { ratio: 0.0014, space_type_gen: true, default: false }
      hash['MRI'] = { ratio: 0.0107, space_type_gen: true, default: false }
      hash['MRI_Control'] = { ratio: 0.0041, space_type_gen: true, default: false }
      hash['NurseStation'] = { ratio: 0.0189, space_type_gen: true, default: false }
      hash['Office'] = { ratio: 0.1828, space_type_gen: true, default: false }
      hash['OR'] = { ratio: 0.0346, space_type_gen: true, default: false }
      hash['PACU'] = { ratio: 0.0232, space_type_gen: true, default: false }
      hash['PhysicalTherapy'] = { ratio: 0.0462, space_type_gen: true, default: false }
      hash['PreOp'] = { ratio: 0.0129, space_type_gen: true, default: false }
      hash['ProcedureRoom'] = { ratio: 0.0070, space_type_gen: true, default: false }
      hash['Reception'] = { ratio: 0.0365, space_type_gen: true, default: false }
      hash['Soil Work'] = { ratio: 0.0088, space_type_gen: true, default: false }
      hash['Stair'] = { ratio: 0.0146, space_type_gen: true, default: false }
      hash['Toilet'] = { ratio: 0.0193, space_type_gen: true, default: false }
      hash['Undeveloped'] = { ratio: 0.0835, space_type_gen: false, default: false }
      hash['Xray'] = { ratio: 0.0220, space_type_gen: true, default: false }
    elsif building_type == 'SuperMarket'
      # TODO: - populate ratios for SuperMarket
      hash['Bakery'] = { ratio: 0.99, space_type_gen: true, default: false }
      hash['Deli'] = { ratio: 0.99, space_type_gen: true, default: false }
      hash['DryStorage'] = { ratio: 0.99, space_type_gen: true, default: false }
      hash['Office'] = { ratio: 0.99, space_type_gen: true, default: false }
      hash['Produce'] = { ratio: 0.99, space_type_gen: true, default: true }
      hash['Sales'] = { ratio: 0.99, space_type_gen: true, default: true }
      hash['Corridor'] = { ratio: 0.99, space_type_gen: true, default: true }
      hash['Dining'] = { ratio: 0.99, space_type_gen: true, default: true }
      hash['Elec/MechRoom'] = { ratio: 0.99, space_type_gen: true, default: true }
      hash['Meeting'] = { ratio: 0.99, space_type_gen: true, default: true }
      hash['Restroom'] = { ratio: 0.99, space_type_gen: true, default: true }
      hash['Vestibule'] = { ratio: 0.99, space_type_gen: true, default: true }
    else
      return false
    end

    return hash
  end

  # remove existing non resource objects from the model
  # technically thermostats and building stories are resources but still want to remove them.
  def remove_non_resource_objects(runner, model, options = nil)
    if options.nil?
      options = {}
      options[:remove_building_stories] = true
      options[:remove_thermostats] = true
      options[:remove_air_loops] = true
      options[:remove_non_swh_plant_loops] = true

      # leave these in by default unless requsted when method called
      options[:remove_swh_plant_loops] = false
      options[:remove_exterior_lights] = false
      options[:remove_site_shading] = false
    end

    num_model_objects = model.objects.size

    # remove non-resource objects not removed by removing the building
    if options[:remove_building_stories] then model.getBuildingStorys.each(&:remove) end
    if options[:remove_thermostats] then model.getThermostats.each(&:remove) end
    if options[:remove_air_loops] then model.getAirLoopHVACs.each(&:remove) end
    if options[:remove_exterior_lights] then model.getFacility.exteriorLights.each(&:remove) end
    if options[:remove_site_shading] then model.getSite.shadingSurfaceGroups.each(&:remove) end

    # see if plant loop is swh or not and take proper action (booter loop doesn't have water use equipment)
    model.getPlantLoops.each do |plant_loop|
      is_swh_loop = false
      plant_loop.supplyComponents.each do |component|
        if component.to_WaterHeaterMixed.is_initialized
          is_swh_loop = true
          next
        end
      end

      if is_swh_loop
        if options[:remove_swh_plant_loops] then plant_loop.remove end
      else
        if options[:remove_non_swh_plant_loops] then plant_loop.remove end
      end
    end

    # remove water use connections (may be removed when loop is removed)
    if options[:remove_swh_plant_loops] then model.getWaterConnectionss.each(&:remove) end
    if options[:remove_swh_plant_loops] then model.getWaterUseEquipments.each(&:remove) end

    # remove building but reset fields on new building object.
    building_fields = []
    building = model.getBuilding
    num_fields = building.numFields
    num_fields.times.each do |i|
      building_fields << building.getString(i).get
    end
    # removes spaces, space's child objects, thermal zones, zone equipment, non site surfaces, building stories and water use connections.
    model.getBuilding.remove
    building = model.getBuilding
    num_fields.times.each do |i|
      next if i == 0 # don't try and set handle
      building_fields << building.setString(i, building_fields[i])
    end

    # other than optionally site shading and exterior lights not messing with site characteristics

    if num_model_objects - model.objects.size > 0
      runner.registerInfo("Removed #{num_model_objects - model.objects.size} non resource objects from the model.")
    end

    return true
  end

  # create_bar(runner,model,bar_hash)
  # measures using this method should include OsLibGeometry and OsLibHelperMethods
  def create_bar(runner, model, bar_hash, story_multiplier_method = 'Basements Ground Mid Top')
    # warn about site shading
    if !model.getSite.shadingSurfaceGroups.empty?
      runner.registerWarning('The model has one or more site shading surafces. New geometry may not be positioned where expected, it will be centered over the center of the original geometry.')
    end

    # make custom story hash when number of stories below grade > 0
    # todo - update this so have option basements are not below 0? (useful for simplifying existing model and maintaining z position relative to site shading)
    story_hash = {}
    eff_below = bar_hash[:num_stories_below_grade]
    eff_above = bar_hash[:num_stories_above_grade]
    footprint_origin = bar_hash[:center_of_footprint]
    typical_story_height = bar_hash[:floor_height]

    # flatten story_hash out to individual stories included in building area
    stories_flat = []
    stories_flat_counter = 0
    bar_hash[:stories].each_with_index do |(k, v), i|
      # k is invalid in some cases, old story object that has been removed, should be from low to high including basement
      # skip if source story insn't included in building area
      if v[:story_included_in_building_area].nil? || (v[:story_included_in_building_area] == true)

        # add to counter
        stories_flat_counter += v[:story_min_multiplier]

        flat_hash = {}
        flat_hash[:story_party_walls] = v[:story_party_walls]
        flat_hash[:below_partial_story] = v[:below_partial_story]
        flat_hash[:bottom_story_ground_exposed_floor] = v[:bottom_story_ground_exposed_floor]
        flat_hash[:top_story_exterior_exposed_roof] = v[:top_story_exterior_exposed_roof]
        if i < eff_below
          flat_hash[:story_type] = 'B'
          flat_hash[:multiplier] = 1
        elsif i == eff_below
          flat_hash[:story_type] = 'Ground'
          flat_hash[:multiplier] = 1
        elsif stories_flat_counter == eff_below + eff_above.ceil
          flat_hash[:story_type] = 'Top'
          flat_hash[:multiplier] = 1
        else
          flat_hash[:story_type] = 'Mid'
          flat_hash[:multiplier] = v[:story_min_multiplier]
        end

        compare_hash = {}
        if !stories_flat.empty?
          stories_flat.last.each { |k, v| compare_hash[k] = flat_hash[k] if flat_hash[k] != v }
        end
        if (story_multiplier_method != 'None' && stories_flat.last == flat_hash) || (story_multiplier_method != 'None' && compare_hash.size == 1 && compare_hash.include?(:multiplier))
          stories_flat.last[:multiplier] += v[:story_min_multiplier]
        else
          stories_flat << flat_hash
        end
      end
    end

    if bar_hash[:num_stories_below_grade] > 0

      # add in below grade levels (may want to add below grade multipliers at some point if we start running deep basements)
      eff_below.times do |i|
        story_hash["B#{i + 1}"] = { space_origin_z: footprint_origin.z - typical_story_height * (i + 1), space_height: typical_story_height, multiplier: 1 }
      end
    end

    # add in above grade levels
    if eff_above > 2
      story_hash['Ground'] = { space_origin_z: footprint_origin.z, space_height: typical_story_height, multiplier: 1 }

      footprint_counter = 0
      effective_stories_counter = 1
      stories_flat.each do |hash|
        next if hash[:story_type] != 'Mid'
        if footprint_counter == 0
          string = 'Mid'
        else
          string = "Mid#{footprint_counter + 1}"
        end
        story_hash[string] = { space_origin_z: footprint_origin.z + typical_story_height * effective_stories_counter + typical_story_height * (hash[:multiplier] - 1) / 2.0, space_height: typical_story_height, multiplier: hash[:multiplier] }
        footprint_counter += 1
        effective_stories_counter += hash[:multiplier]
      end

      story_hash['Top'] = { space_origin_z: footprint_origin.z + typical_story_height * (eff_above.ceil - 1), space_height: typical_story_height, multiplier: 1 }
    elsif eff_above > 1
      story_hash['Ground'] = { space_origin_z: footprint_origin.z, space_height: typical_story_height, multiplier: 1 }
      story_hash['Top'] = { space_origin_z: footprint_origin.z + typical_story_height * (eff_above.ceil - 1), space_height: typical_story_height, multiplier: 1 }
    else # one story only
      story_hash['Ground'] = { space_origin_z: footprint_origin.z, space_height: typical_story_height, multiplier: 1 }
    end

    # create footprints
    if bar_hash[:bar_division_method] == 'Multiple Space Types - Simple Sliced'
      footprints = []
      story_hash.size.times do |i|
        # adjust size of bar of top story is not a full story
        if i + 1 == story_hash.size
          area_multiplier = (1.0 - bar_hash[:num_stories_above_grade].ceil + bar_hash[:num_stories_above_grade])
          edge_multiplier = Math.sqrt(area_multiplier)
          length = bar_hash[:length] * edge_multiplier
          width = bar_hash[:width] * edge_multiplier
        else
          length = bar_hash[:length]
          width = bar_hash[:width]
        end
        footprints << OsLib_Geometry.make_sliced_bar_simple_polygons(runner, bar_hash[:space_types], length, width, bar_hash[:center_of_footprint])
      end

    elsif bar_hash[:bar_division_method] == 'Multiple Space Types - Individual Stories Sliced'

      # update story_hash for partial_story_above
      story_hash.each_with_index do |(k, v), i|
        # adjust size of bar of top story is not a full story
        if i + 1 == story_hash.size
          story_hash[k][:partial_story_multiplier] = (1.0 - bar_hash[:num_stories_above_grade].ceil + bar_hash[:num_stories_above_grade])
        end
      end

      footprints = OsLib_Geometry.make_sliced_bar_multi_polygons(runner, bar_hash[:space_types], bar_hash[:length], bar_hash[:width], bar_hash[:center_of_footprint], story_hash)

    else
      footprints = []
      story_hash.size.times do |i|
        # adjust size of bar of top story is not a full story
        if i + 1 == story_hash.size
          area_multiplier = (1.0 - bar_hash[:num_stories_above_grade].ceil + bar_hash[:num_stories_above_grade])
          edge_multiplier = Math.sqrt(area_multiplier)
          length = bar_hash[:length] * edge_multiplier
          width = bar_hash[:width] * edge_multiplier
        else
          length = bar_hash[:length]
          width = bar_hash[:width]
        end
        footprints << OsLib_Geometry.make_core_and_perimeter_polygons(runner, length, width, bar_hash[:center_of_footprint]) # perimeter defaults to 15'
      end

      # set primary space type to building default space type
      space_types = bar_hash[:space_types].sort_by { |k, v| v[:floor_area] }
      model.getBuilding.setSpaceType(space_types.last.first)

    end

    # makeSpacesFromPolygons
    OsLib_Geometry.makeSpacesFromPolygons(runner, model, footprints, bar_hash[:floor_height], bar_hash[:num_stories], bar_hash[:center_of_footprint], story_hash)

    # put all of the spaces in the model into a vector for intersection and surface matching
    spaces = OpenStudio::Model::SpaceVector.new
    model.getSpaces.sort.each do |space|
      spaces << space
    end

    # only intersect if make_mid_story_surfaces_adiabatic false
    if !(bar_hash[:make_mid_story_surfaces_adiabatic])
      # intersect surfaces
      # (when bottom floor has many space types and one above doesn't will end up with heavily subdivided floor. Maybe use adiabatic and don't intersect floor/ceilings)
      intersect_surfaces = true
      if intersect_surfaces
        OpenStudio::Model.intersectSurfaces(spaces)
        runner.registerInfo('Intersecting surfaces, this will create additional geometry.')
      end
    end

    # match surfaces for each space in the vector
    OpenStudio::Model.matchSurfaces(spaces)

    # set boundary conditions if not already set when geometry was created
    # todo - update this to use space original z value vs. story name
    if bar_hash[:num_stories_below_grade] > 0
      model.getBuildingStorys.each do |story|
        next if !story.name.to_s.include?('Story B')
        story.spaces.each do |space|
          space.surfaces.each do |surface|
            next if surface.surfaceType != 'Wall'
            next if surface.outsideBoundaryCondition != 'Outdoors'
            surface.setOutsideBoundaryCondition('Ground')
          end
        end
      end
    end

    # sort stories (by name for now but need better way)
    # todo - need to change this so doesn't create issues when models have existing stories and spaces. Should be able to run it multiple times
    sorted_stories = {}
    model.getBuildingStorys.each do |story|
      sorted_stories[story.name.to_s] = story
    end

    # loop through building stories, spaces, and surfaces
    sorted_stories.sort.each_with_index do |(key, story), i|
      # flag for adiabatic floor if building doesn't have ground exposed floor
      if stories_flat[i][:bottom_story_ground_exposed_floor] == false
        adiabatic_floor = true
      end
      # flag for adiabatic roof if building doesn't have exterior exposed roof
      if stories_flat[i][:top_story_exterior_exposed_roof] == false
        adiabatic_ceiling = true
      end

      # make all mid story floor and celings adiabiatc if requested
      if bar_hash[:make_mid_story_surfaces_adiabatic]
        if i > 0
          adiabatic_floor = true
        end
        if i < sorted_stories.size - 1
          adiabatic_ceiling = true
        end
      end

      # flag orientations for this story to recieve party walls
      party_wall_facades = stories_flat[i][:story_party_walls]

      story.spaces.each do |space|
        space.surfaces. each do |surface|
          # set floor to adiabatic if requited
          if adiabatic_floor && surface.surfaceType == 'Floor'
            make_surfaces_adiabatic([surface])
          elsif adiabatic_ceiling && surface.surfaceType == 'RoofCeiling'
            make_surfaces_adiabatic([surface])
          end

          # skip of not exterior wall
          next if surface.surfaceType != 'Wall'
          next if surface.outsideBoundaryCondition != 'Outdoors'

          # get the absoluteAzimuth for the surface so we can categorize it
          absoluteAzimuth = OpenStudio.convert(surface.azimuth, 'rad', 'deg').get + surface.space.get.directionofRelativeNorth + model.getBuilding.northAxis
          absoluteAzimuth = absoluteAzimuth % 360.0 # should result in value between 0 and 360
          absoluteAzimuth = absoluteAzimuth.round(5) # this was creating issues at 45 deg angles with opposing facades

          # add fenestration (wwr for now, maybe overhang and overhead doors later)
          if (absoluteAzimuth >= 315.0) || (absoluteAzimuth < 45.0)
            if party_wall_facades.include?('north')
              make_surfaces_adiabatic([surface])
            else
              surface.setWindowToWallRatio(bar_hash[:building_wwr_n])
            end
          elsif (absoluteAzimuth >= 45.0) && (absoluteAzimuth < 135.0)
            if party_wall_facades.include?('east')
              make_surfaces_adiabatic([surface])
            else
              surface.setWindowToWallRatio(bar_hash[:building_wwr_e])
            end
          elsif (absoluteAzimuth >= 135.0) && (absoluteAzimuth < 225.0)
            if party_wall_facades.include?('south')
              make_surfaces_adiabatic([surface])
            else
              surface.setWindowToWallRatio(bar_hash[:building_wwr_s])
            end
          elsif (absoluteAzimuth >= 225.0) && (absoluteAzimuth < 315.0)
            if party_wall_facades.include?('west')
              make_surfaces_adiabatic([surface])
            else
              surface.setWindowToWallRatio(bar_hash[:building_wwr_w])
            end
          else
            runner.registerError('Unexpected value of facade: ' + absoluteAzimuth + '.')
            return false
          end
        end
      end
    end

    final_floor_area_ip = OpenStudio.convert(model.getBuilding.floorArea, 'm^2', 'ft^2').get
    runner.registerInfo("Created Bar envlope with floor area of #{OpenStudio.toNeatString(final_floor_area_ip, 0, true)} (ft^2)")
  end

  # make selected surfaces adiabatic
  def make_surfaces_adiabatic(surfaces)
    surfaces.each do |surface|
      if surface.construction.is_initialized
        surface.setConstruction(surface.construction.get)
      end
      surface.setOutsideBoundaryCondition('Adiabatic')
    end
  end

  # get length and width of rectangle matching bounding box aspect ratio will maintaining proper floor area
  def calc_bar_reduced_bounding_box(envelope_data_hash)
    bar = {}

    bounding_length = envelope_data_hash[:building_max_xyz][0] - envelope_data_hash[:building_min_xyz][0]
    bounding_width = envelope_data_hash[:building_max_xyz][1] - envelope_data_hash[:building_min_xyz][1]
    bounding_area = bounding_length * bounding_width
    footprint_area = envelope_data_hash[:building_floor_area] / envelope_data_hash[:effective__num_stories].to_f
    area_multiplier = footprint_area / bounding_area
    edge_multiplier = Math.sqrt(area_multiplier)
    bar[:length] = bounding_length * edge_multiplier
    bar[:width] = bounding_width * edge_multiplier

    return bar
  end

  # get length and width of rectangle matching longer of two edges, and reducing the other way until floor area matches
  def calc_bar_reduced_width(envelope_data_hash)
    bar = {}

    bounding_length = envelope_data_hash[:building_max_xyz][0] - envelope_data_hash[:building_min_xyz][0]
    bounding_width = envelope_data_hash[:building_max_xyz][1] - envelope_data_hash[:building_min_xyz][1]
    footprint_area = envelope_data_hash[:building_floor_area] / envelope_data_hash[:effective__num_stories].to_f

    if bounding_length >= bounding_width
      bar[:length] = bounding_length
      bar[:width] = footprint_area / bounding_length
    else
      bar[:width] = bounding_width
      bar[:length] = footprint_area / bounding_width
    end

    return bar
  end

  # get length and width of rectangle by stretching it until both floor area and exterior wall area or perimeter match
  def calc_bar_stretched(envelope_data_hash)
    bar = {}

    bounding_length = envelope_data_hash[:building_max_xyz][0] - envelope_data_hash[:building_min_xyz][0]
    bounding_width = envelope_data_hash[:building_max_xyz][1] - envelope_data_hash[:building_min_xyz][1]
    a = envelope_data_hash[:building_floor_area] / envelope_data_hash[:effective__num_stories].to_f
    p = envelope_data_hash[:building_perimeter]

    if bounding_length >= bounding_width
      bar[:length] = 0.25 * (p + Math.sqrt(p**2 - 16 * a))
      bar[:width] = 0.25 * (p - Math.sqrt(p**2 - 16 * a))
    else
      bar[:length] = 0.25 * (p - Math.sqrt(p**2 - 16 * a))
      bar[:width] = 0.25 * (p + Math.sqrt(p**2 - 16 * a))
    end

    return bar
  end
end
