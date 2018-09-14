class OpenStudio::Model::SolarCollectorFlatPlatePhotovoltaicThermal
  def maxWaterFlowRate
    if designFlowRate.is_initialized
      designFlowRate
    else
      autosizedDesignFlowRate
    end
  end

  def maxWaterFlowRateAutosized
    if designFlowRate.is_initialized
      # Not autosized if hard size field value present
      return OpenStudio::OptionalBool.new(false)
    else
      return OpenStudio::OptionalBool.new(true)
    end
  end
end
