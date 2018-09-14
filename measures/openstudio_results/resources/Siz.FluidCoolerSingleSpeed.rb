class OpenStudio::Model::FluidCoolerSingleSpeed
  def maxAirFlowRate
    if designAirFlowRate.is_initialized
      designAirFlowRate
    else
      autosizedDesignAirFlowRate
    end
  end

  def maxWaterFlowRate
    if designWaterFlowRate.is_initialized
      designWaterFlowRate
    else
      autosizedDesignWaterFlowRate
    end
  end

  def maxAirFlowRateAutosized
    if designAirFlowRate.is_initialized
      # Not autosized if hard size field value present
      return OpenStudio::OptionalBool.new(false)
    else
      return OpenStudio::OptionalBool.new(true)
    end
  end

  def maxWaterFlowRateAutosized
    if designWaterFlowRate.is_initialized
      # Not autosized if hard size field value present
      return OpenStudio::OptionalBool.new(false)
    else
      return OpenStudio::OptionalBool.new(true)
    end
  end
end
