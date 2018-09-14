class OpenStudio::Model::SolarCollectorPerformancePhotovoltaicThermalSimple
  def performanceCharacteristics
    effs = []
    effs << [thermalConversionEfficiency, 'Thermal Conversion Efficiency']
    return effs
  end
end
