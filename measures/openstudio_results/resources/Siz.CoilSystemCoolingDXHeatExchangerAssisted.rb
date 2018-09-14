class OpenStudio::Model::CoilSystemCoolingDXHeatExchangerAssisted
  def performanceCharacteristics
    effs = []
    effs += coolingCoil.performanceCharacteristics
    return effs
  end
end
