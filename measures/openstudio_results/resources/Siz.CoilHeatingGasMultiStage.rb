class OpenStudio::Model::CoilHeatingGasMultiStage
  def maxHeatingCapacity
    stages.last.maxHeatingCapacity
  end

  def maxHeatingCapacityAutosized
    stages.last.maxHeatingCapacityAutosized
  end
end
