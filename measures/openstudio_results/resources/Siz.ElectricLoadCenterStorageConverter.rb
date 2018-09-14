class OpenStudio::Model::ElectricLoadCenterStorageConverter
  def performanceCharacteristics
    effs = []
    effs << [simpleFixedEfficiency, 'Simple Fixed Efficiency']
    return effs
  end
end
