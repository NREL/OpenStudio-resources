class OpenStudio::Model::CoilCoolingWaterToAirHeatPumpVariableSpeedEquationFitSpeedData
  def performanceCharacteristics
    effs = []
    effs << [referenceUnitGrossRatedCoolingCOP, 'Reference Unit Gross Rated Cooling COP']
    return effs
  end
end
