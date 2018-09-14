class OpenStudio::Model::GeneratorFuelCellInverter
  def performanceCharacteristics
    effs = []
    effs << [inverterEfficiency, 'Inverter Efficiency']
    return effs
  end
end
