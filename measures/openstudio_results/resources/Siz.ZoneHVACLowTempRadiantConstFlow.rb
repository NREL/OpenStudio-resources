class OpenStudio::Model::ZoneHVACLowTempRadiantConstFlow
  def performanceCharacteristics
    effs = []
    effs << [ratedPumpHead, 'Rated Pump Head']
    effs << [motorEfficiency, 'Motor Efficiency']
    return effs
  end

  def performanceCharacteristics
    effs = []
    effs += heatingCoil.performanceCharacteristics
    effs += coolingCoil.performanceCharacteristics
    return effs
  end
end
