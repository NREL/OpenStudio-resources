class OpenStudio::Model::CoilCoolingDXVariableSpeedSpeedData
  def performanceCharacteristics
    effs = []
    effs << [referenceUnitGrossRatedCoolingCOP, 'Reference Unit Gross Rated Cooling COP']
    effs << [referenceUnitRatedPadEffectivenessofEvapPrecooling, 'Reference Unit Rated Pad Effectivenessof Evap Precooling']
    return effs
  end
end
