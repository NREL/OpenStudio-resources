class OpenStudio::Model::GeneratorMicroTurbineHeatRecovery
  def performanceCharacteristics
    effs = []
    effs << [referenceThermalEfficiencyUsingLowerHeatValue, 'Reference Thermal Efficiency Using Lower Heat Value']
    return effs
  end
end
