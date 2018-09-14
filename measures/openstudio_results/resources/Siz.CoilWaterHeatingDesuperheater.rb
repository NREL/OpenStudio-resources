class OpenStudio::Model::CoilWaterHeatingDesuperheater
  def performanceCharacteristics
    effs = []
    effs << [ratedHeatReclaimRecoveryEfficiency, 'Rated Heat Reclaim Recovery Efficiency']
    return effs
  end
end
