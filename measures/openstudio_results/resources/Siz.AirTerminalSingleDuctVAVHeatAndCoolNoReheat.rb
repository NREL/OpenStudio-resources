class OpenStudio::Model::AirTerminalSingleDuctVAVHeatAndCoolNoReheat
  def maxAirFlowRate
    if maximumAirFlowRate.is_initialized
      maximumAirFlowRate
    else
      autosizedMaximumAirFlowRate
    end
  end

  def maxAirFlowRateAutosized
    if maximumAirFlowRate.is_initialized
      # Not autosized if hard size field value present
      return OpenStudio::OptionalBool.new(false)
    else
      return OpenStudio::OptionalBool.new(true)
    end
  end
end
