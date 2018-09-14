class OpenStudio::Model::CoilCoolingLowTempRadiantVarFlow
  def maxWaterFlowRate
    autosizedMaximumColdWaterFlow
  end

  def maxWaterFlowRateAutosized
    if autosizedMaximumColdWaterFlow.is_initialized
      return OpenStudio::OptionalBool.new(true)
    else
      return OpenStudio::OptionalBool.new(false)
    end
  end
end
