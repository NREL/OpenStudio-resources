class OpenStudio::Model::CoilHeatingDesuperheater
  def performanceCharacteristics
    effs = []
    effs << [heatReclaimRecoveryEfficiency, 'Heat Reclaim Recovery Efficiency']
    return effs
  end
end
