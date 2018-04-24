######################################################################
#  Copyright (c) 2008-2013, Alliance for Sustainable Energy.  
#  All rights reserved.
#  
#  This library is free software; you can redistribute it and/or
#  modify it under the terms of the GNU Lesser General Public
#  License as published by the Free Software Foundation; either
#  version 2.1 of the License, or (at your option) any later version.
#  
#  This library is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#  Lesser General Public License for more details.
#  
#  You should have received a copy of the GNU Lesser General Public
#  License along with this library; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
######################################################################

# Each user script is implemented within a class that derives from OpenStudio::Ruleset::UserScript
class RemoveLoadsDirectlyAssignedToSpaces < OpenStudio::Ruleset::ModelUserScript

  # override name to return the name of your script
  def name
    return "Remove Loads Directly Assigned to Spaces"
  end
  
  # returns a vector of arguments, the runner will present these arguments to the user
  # then pass in the results on run
  def arguments(model)
    result = OpenStudio::Ruleset::OSArgumentVector.new
    return result
  end
    
  # override run to implement the functionality of your script
  # model is an OpenStudio::Model::Model, runner is a OpenStudio::Ruleset::UserScriptRunner
  def run(model, runner, arguments)
    
    spaces = model.getSpaces
    
    spaces.each do |space|
  
      # removing or detaching loads directly assigned to space objects.
      space.internalMass.each {|instance| instance.remove }
      space.people.each {|instance| instance.remove }
      space.lights.each {|instance| instance.remove }
      space.luminaires.each {|instance| instance.remove }
      space.electricEquipment.each {|instance| instance.remove }
      space.gasEquipment.each {|instance| instance.remove }
      space.hotWaterEquipment.each {|instance| instance.remove }
      space.steamEquipment.each {|instance| instance.remove }
      space.otherEquipment.each {|instance| instance.remove }
      space.spaceInfiltrationDesignFlowRates.each {|object| object.remove }
      space.spaceInfiltrationEffectiveLeakageAreas.each {|object| object.remove }   
    
      space.resetDesignSpecificationOutdoorAir
  
    end
    
  end

end

RemoveLoadsDirectlyAssignedToSpaces.new
