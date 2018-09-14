class OpenStudio::Model::ZoneHVACTerminalUnitVariableRefrigerantFlow
  def maxHeatingCapacity
    heatingCoil.maxHeatingCapacity
  end

  def maxCoolingCapacity
    coolingCoil.maxCoolingCapacity
  end

  def maxAirFlowRate
    vals = []
    if supplyAirFlowRateDuringCoolingOperation.is_initialized
      vals << supplyAirFlowRateDuringCoolingOperation.get
    elsif autosizedSupplyAirFlowRateDuringCoolingOperation.is_initialized
      vals << autosizedSupplyAirFlowRateDuringCoolingOperation.get
    end
    if supplyAirFlowRateWhenNoCoolingisNeeded.is_initialized
      vals << supplyAirFlowRateWhenNoCoolingisNeeded.get
    elsif autosizedSupplyAirFlowRateWhenNoCoolingisNeeded.is_initialized
      vals << autosizedSupplyAirFlowRateWhenNoCoolingisNeeded.get
    end
    if supplyAirFlowRateDuringHeatingOperation.is_initialized
      vals << supplyAirFlowRateDuringHeatingOperation.get
    elsif autosizedSupplyAirFlowRateDuringHeatingOperation.is_initialized
      vals << autosizedSupplyAirFlowRateDuringHeatingOperation.get
    end
    if supplyAirFlowRateWhenNoHeatingisNeeded.is_initialized
      vals << supplyAirFlowRateWhenNoHeatingisNeeded.get
    elsif autosizedSupplyAirFlowRateWhenNoHeatingisNeeded.is_initialized
      vals << autosizedSupplyAirFlowRateWhenNoHeatingisNeeded.get
    end
    if vals.size.zero?
      OpenStudio::OptionalDouble.new
    else
      OpenStudio::OptionalDouble.new(vals.max)
    end
  end

  def maxWaterFlowRate
    vals = []
    if coolingCoil.maxWaterFlowRate.is_initialized
      vals << coolingCoil.maxWaterFlowRate.get
    end
    if heatingCoil.maxWaterFlowRate.is_initialized
      vals << heatingCoil.maxWaterFlowRate.get
    end
    if vals.size.zero?
      OpenStudio::OptionalDouble.new
    else
      OpenStudio::OptionalDouble.new(vals.max)
    end
  end

  def maxHeatingCapacityAutosized
    heatingCoil.maxHeatingCapacityAutosized
  end

  def maxCoolingCapacityAutosized
    coolingCoil.maxCoolingCapacityAutosized
  end

  def maxAirFlowRateAutosized
    if supplyAirFlowRateDuringCoolingOperation.is_initialized
      return OpenStudio::OptionalBool.new(false)
    elsif supplyAirFlowRateWhenNoCoolingisNeeded.is_initialized
      return OpenStudio::OptionalBool.new(false)
    elsif supplyAirFlowRateDuringHeatingOperation.is_initialized
      return OpenStudio::OptionalBool.new(false)
    elsif supplyAirFlowRateWhenNoHeatingisNeeded.is_initialized
      return OpenStudio::OptionalBool.new(false)
    else
      return OpenStudio::OptionalBool.new(true)
    end
  end

  def maxWaterFlowRateAutosized
    if coolingCoil.maxWaterFlowRate.is_initialized
      return OpenStudio::OptionalBool.new(false)
    elsif heatingCoil.maxWaterFlowRate.is_initialized
      return OpenStudio::OptionalBool.new(false)
    else
      return OpenStudio::OptionalBool.new(true)
    end
  end

  def performanceCharacteristics
    effs = []
    effs += supplyAirFan.performanceCharacteristics
    effs += coolingCoil.get.performanceCharacteristics if coolingCoil.is_initialized
    effs += heatingCoil.get.performanceCharacteristics if heatingCoil.is_initialized
    return effs
  end
end
