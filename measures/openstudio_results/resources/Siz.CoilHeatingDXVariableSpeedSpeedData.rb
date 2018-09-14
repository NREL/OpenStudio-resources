class OpenStudio::Model::CoilHeatingDXVariableSpeedSpeedData
  def performanceCharacteristics
    effs = []
    effs << [referenceUnitGrossRatedHeatingCOP, 'Reference Unit Gross Rated Heating COP']
    return effs
  end
end
