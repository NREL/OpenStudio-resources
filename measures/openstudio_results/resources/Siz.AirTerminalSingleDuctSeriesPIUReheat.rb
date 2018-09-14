class OpenStudio::Model::AirTerminalSingleDuctSeriesPIUReheat
  def maxHeatingCapacity
    reheatCoil.maxHeatingCapacity
  end

  def maxAirFlowRate
    if maximumAirFlowRate.is_initialized
      maximumAirFlowRate
    else
      autosizedMaximumAirFlowRate
    end
  end

  def maxWaterFlowRate
    reheatCoil.maxWaterFlowRate
  end

  def maxHeatingCapacityAutosized
    reheatCoil.maxHeatingCapacityAutosized
  end

  def maxAirFlowRateAutosized
    if maximumAirFlowRate.is_initialized
      # Not autosized if hard size field value present
      return OpenStudio::OptionalBool.new(false)
    else
      return OpenStudio::OptionalBool.new(true)
    end
  end

  def maxWaterFlowRateAutosized
    reheatCoil.maxWaterFlowRateAutosized
  end

  def performanceCharacteristics
    effs = []
    effs += fan.performanceCharacteristics
    effs += reheatCoil.performanceCharacteristics
    return effs
  end
end
