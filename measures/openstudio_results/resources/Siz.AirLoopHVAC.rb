class OpenStudio::Model::AirLoopHVAC
  def maxAirFlowRate
    if designSupplyAirFlowRate.is_initialized
      designSupplyAirFlowRate
    else
      autosizedDesignSupplyAirFlowRate
    end
  end

  def maxAirFlowRateAutosized
    if designSupplyAirFlowRate.is_initialized
      # Not autosized if hard size field value present
      return OpenStudio::OptionalBool.new(false)
    else
      return OpenStudio::OptionalBool.new(true)
    end
  end
end
