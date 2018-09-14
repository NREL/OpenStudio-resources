class OpenStudio::Model::FanZoneExhaust
  def performanceCharacteristics
    effs = []
    effs << [fanEfficiency, 'Fan Efficiency']
    effs << [pressureRise, 'Pressure Rise']
    return effs
  end
end
