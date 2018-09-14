class OpenStudio::Model::GeneratorFuelCellElectricalStorage
  def performanceCharacteristics
    effs = []
    effs << [nominalChargingEnergeticEfficiency, 'Nominal Charging Energetic Efficiency']
    effs << [nominalDischargingEnergeticEfficiency, 'Nominal Discharging Energetic Efficiency']
    return effs
  end
end
