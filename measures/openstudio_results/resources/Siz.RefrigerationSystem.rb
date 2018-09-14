class OpenStudio::Model::RefrigerationSystem
  def performanceCharacteristics
    effs = []
    effs << [shellandCoilIntercoolerEffectiveness, 'Shelland Coil Intercooler Effectiveness']
    return effs
  end
end
