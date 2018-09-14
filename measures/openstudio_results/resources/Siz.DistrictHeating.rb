class OpenStudio::Model::DistrictHeating
  def maxHeatingCapacity
    if nominalCapacity.is_initialized
      nominalCapacity
    else
      autosizedNominalCapacity
    end
  end

  def maxHeatingCapacityAutosized
    if nominalCapacity.is_initialized
      # Not autosized if hard size field value present
      return OpenStudio::OptionalBool.new(false)
    else
      return OpenStudio::OptionalBool.new(true)
    end
  end
end
