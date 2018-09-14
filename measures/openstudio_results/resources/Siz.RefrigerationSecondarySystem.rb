class OpenStudio::Model::RefrigerationSecondarySystem
  def performanceCharacteristics
    effs = []
    effs << [totalPumpHead, 'Total Pump Head']
    return effs
  end
end
