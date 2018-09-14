class OpenStudio::Model::ElectricLoadCenterInverterSimple
  def performanceCharacteristics
    effs = []
    effs << [inverterEfficiency, 'Inverter Efficiency']
    return effs
  end
end
