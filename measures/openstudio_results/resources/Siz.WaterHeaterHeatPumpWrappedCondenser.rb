class OpenStudio::Model::WaterHeaterHeatPumpWrappedCondenser
  def performanceCharacteristics
    effs = []
    effs += fan.performanceCharacteristics
    return effs
  end
end
