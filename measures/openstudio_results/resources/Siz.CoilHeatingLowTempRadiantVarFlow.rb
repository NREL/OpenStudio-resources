class OpenStudio::Model::CoilHeatingLowTempRadiantVarFlow
  def maxWaterFlowRate
    autosizedMaximumHotWaterFlow
  end

  def maxWaterFlowRateAutosized
    if autosizedMaximumHotWaterFlow.is_initialized
      return OpenStudio::OptionalBool.new(true)
    else
      return OpenStudio::OptionalBool.new(false)
    end
  end
end
