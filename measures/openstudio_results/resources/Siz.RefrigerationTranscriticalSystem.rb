class OpenStudio::Model::RefrigerationTranscriticalSystem
  def performanceCharacteristics
    effs = []
    effs << [receiverPressure, 'Receiver Pressure']
    effs << [subcoolerEffectiveness, 'Subcooler Effectiveness']
    return effs
  end
end
