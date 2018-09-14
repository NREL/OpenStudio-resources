class OpenStudio::Model::CoilCoolingWaterToAirHeatPumpEquationFit
  def maxCoolingCapacity
    if ratedTotalCoolingCapacity.is_initialized
      ratedTotalCoolingCapacity
    else
      autosizedRatedTotalCoolingCapacity
    end
  end

  def maxAirFlowRate
    if ratedAirFlowRate.is_initialized
      ratedAirFlowRate
    else
      autosizedRatedAirFlowRate
    end
  end

  def maxWaterFlowRate
    if ratedWaterFlowRate.is_initialized
      ratedWaterFlowRate
    else
      autosizedRatedWaterFlowRate
    end
  end

  def maxCoolingCapacityAutosized
    if ratedTotalCoolingCapacity.is_initialized
      # Not autosized if hard size field value present
      return OpenStudio::OptionalBool.new(false)
    else
      return OpenStudio::OptionalBool.new(true)
    end
  end

  def maxAirFlowRateAutosized
    if ratedAirFlowRate.is_initialized
      # Not autosized if hard size field value present
      return OpenStudio::OptionalBool.new(false)
    else
      return OpenStudio::OptionalBool.new(true)
    end
  end

  def maxWaterFlowRateAutosized
    if ratedWaterFlowRate.is_initialized
      # Not autosized if hard size field value present
      return OpenStudio::OptionalBool.new(false)
    else
      return OpenStudio::OptionalBool.new(true)
    end
  end
end
