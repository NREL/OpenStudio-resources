class OpenStudio::Model::ZoneHVACHighTemperatureRadiant
  def performanceCharacteristics
    effs = []
    effs << [combustionEfficiency, 'Combustion Efficiency']
    return effs
  end
end
