class OpenStudio::Model::GeneratorFuelCellPowerModule
  def performanceCharacteristics
    effs = []
    effs << [nominalEfficiency, 'Nominal Efficiency']
    return effs
  end
end
