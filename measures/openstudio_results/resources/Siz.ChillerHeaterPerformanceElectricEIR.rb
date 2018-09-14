class OpenStudio::Model::ChillerHeaterPerformanceElectricEIR
  def maxCoolingCapacity
    if referenceCoolingModeEvaporatorCapacity.is_initialized
      referenceCoolingModeEvaporatorCapacity
    else
      autosizedReferenceCoolingModeEvaporatorCapacity
    end
  end

  def maxWaterFlowRate
    if designChilledWaterFlowRate.is_initialized
      designChilledWaterFlowRate
    else
      autosizedDesignChilledWaterFlowRate
    end
  end

  def maxCoolingCapacityAutosized
    if referenceCoolingModeEvaporatorCapacity.is_initialized
      # Not autosized if hard size field value present
      return OpenStudio::OptionalBool.new(false)
    else
      return OpenStudio::OptionalBool.new(true)
    end
  end

  def maxWaterFlowRateAutosized
    if designChilledWaterFlowRate.is_initialized
      # Not autosized if hard size field value present
      return OpenStudio::OptionalBool.new(false)
    else
      return OpenStudio::OptionalBool.new(true)
    end
  end

  def performanceCharacteristics
    effs = []
    effs << [referenceCoolingModeCOP, 'Reference Cooling Mode COP']
    effs << [compressorMotorEfficiency, 'Compressor Motor Efficiency']
    return effs
  end
end
