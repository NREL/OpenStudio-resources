class OpenStudio::Model::ZoneVentilationDesignFlowRate
  def performanceCharacteristics
    effs = []
    effs << [fanPressureRise, 'Fan Pressure Rise']
    effs << [fanTotalEfficiency, 'Fan Total Efficiency']
    return effs
  end
end
