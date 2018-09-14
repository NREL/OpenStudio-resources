class OpenStudio::Model::DistrictCooling
  def maxCoolingCapacity
    if nominalCapacity.is_initialized
      nominalCapacity
    else
      autosizedNominalCapacity
    end
  end

  def maxCoolingCapacityAutosized
    if nominalCapacity.is_initialized
      # Not autosized if hard size field value present
      return OpenStudio::OptionalBool.new(false)
    else
      return OpenStudio::OptionalBool.new(true)
    end
  end
end
