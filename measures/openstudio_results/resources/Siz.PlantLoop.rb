class OpenStudio::Model::PlantLoop
  def maxAirFlowRate
    if maximumLoopFlowRate.is_initialized
      maximumLoopFlowRate
    else
      autosizedMaximumLoopFlowRate
    end
  end

  def maxWaterFlowRate
    if maximumLoopFlowRate.is_initialized
      maximumLoopFlowRate
    else
      autosizedMaximumLoopFlowRate
    end
  end

  def maxAirFlowRateAutosized
    if maximumLoopFlowRate.is_initialized
      # Not autosized if hard size field value present
      return OpenStudio::OptionalBool.new(false)
    else
      return OpenStudio::OptionalBool.new(true)
    end
  end

  def maxWaterFlowRateAutosized
    if maximumLoopFlowRate.is_initialized
      # Not autosized if hard size field value present
      return OpenStudio::OptionalBool.new(false)
    else
      return OpenStudio::OptionalBool.new(true)
    end
  end
end
