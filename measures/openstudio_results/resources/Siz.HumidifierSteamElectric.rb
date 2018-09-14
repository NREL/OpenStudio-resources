class OpenStudio::Model::HumidifierSteamElectric
  def maxWaterFlowRate
    if ratedPower.is_initialized
      ratedPower
    else
      autosizedRatedPower
    end
  end

  def maxWaterFlowRateAutosized
    if ratedPower.is_initialized
      # Not autosized if hard size field value present
      return OpenStudio::OptionalBool.new(false)
    else
      return OpenStudio::OptionalBool.new(true)
    end
  end
end
