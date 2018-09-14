class OpenStudio::Model::CoilWaterHeatingAirToWaterHeatPumpWrapped
  def performanceCharacteristics
    effs = []
    effs << [ratedCOP, 'Rated COP']
    return effs
  end
end
