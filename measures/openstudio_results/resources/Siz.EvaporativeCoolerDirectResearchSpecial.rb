class OpenStudio::Model::EvaporativeCoolerDirectResearchSpecial
  def maxAirFlowRate
    if primaryAirDesignFlowRate.is_initialized
      primaryAirDesignFlowRate
    else
      autosizedPrimaryAirDesignFlowRate
    end
  end

  def maxAirFlowRateAutosized
    if primaryAirDesignFlowRate.is_initialized
      # Not autosized if hard size field value present
      return OpenStudio::OptionalBool.new(false)
    else
      return OpenStudio::OptionalBool.new(true)
    end
  end

  def performanceCharacteristics
    effs = []
    effs << [coolerEffectiveness, 'Cooler Effectiveness']
    return effs
  end
end
