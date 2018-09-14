class OpenStudio::Model::CoilCoolingDXMultiSpeed
  def maxCoolingCapacity
    stages.last.maxCoolingCapacity
  end

  def maxAirFlowRate
    stages.last.maxAirFlowRate
  end

  def maxCoolingCapacityAutosized
    stages.last.maxCoolingCapacityAutosized
  end

  def maxAirFlowRateAutosized
    stages.last.maxAirFlowRateAutosized
  end
end
