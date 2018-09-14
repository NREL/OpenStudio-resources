class OpenStudio::Model::CoilSystemCoolingWaterHeatExchangerAssisted
  def performanceCharacteristics
    effs = []
    effs += coolingCoil.performanceCharacteristics
    return effs
  end
end
