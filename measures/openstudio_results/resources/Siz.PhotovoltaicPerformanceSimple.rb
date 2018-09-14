class OpenStudio::Model::PhotovoltaicPerformanceSimple
  def performanceCharacteristics
    effs = []
    effs << [fixedEfficiency, 'Fixed Efficiency']
    return effs
  end
end
