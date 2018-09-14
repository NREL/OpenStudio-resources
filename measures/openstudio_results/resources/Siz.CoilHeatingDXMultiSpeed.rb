class OpenStudio::Model::CoilHeatingDXMultiSpeed
  def maxHeatingCapacity
    stages.last.maxHeatingCapacity
  end

  def maxAirFlowRate
    stages.last.maxAirFlowRate
  end

  def maxHeatingCapacityAutosized
    stages.last.maxHeatingCapacityAutosized
  end

  def maxAirFlowRateAutosized
    stages.last.maxAirFlowRateAutosized
  end
end
