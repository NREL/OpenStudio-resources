class OpenStudio::Model::ElectricLoadCenterStorageSimple
  def performanceCharacteristics
    effs = []
    effs << [nominalEnergeticEfficiencyforCharging, 'Nominal Energetic Efficiencyfor Charging']
    effs << [nominalDischargingEnergeticEfficiency, 'Nominal Discharging Energetic Efficiency']
    return effs
  end
end
