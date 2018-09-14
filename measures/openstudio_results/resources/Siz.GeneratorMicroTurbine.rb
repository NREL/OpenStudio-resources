class OpenStudio::Model::GeneratorMicroTurbine
  def performanceCharacteristics
    effs = []
    effs << [referenceElectricalEfficiencyUsingLowerHeatingValue, 'Reference Electrical Efficiency Using Lower Heating Value']
    return effs
  end
end
