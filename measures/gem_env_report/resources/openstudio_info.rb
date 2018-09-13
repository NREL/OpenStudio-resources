# Reports out information about the OpenStudio environment.
# Used for debugging different runtime environments.
# Messages are put to stdout and returned in an array.
# @return [Array<String>] an array of information about OpenStudio.
def openstudio_information

  require 'json'

  result = {}
  result[:openstudio] = {}

  begin
    require 'openstudio'

    result[:openstudio]['openStudioVersion'] = OpenStudio.openStudioVersion.to_s
    result[:openstudio]['openStudioLongVersion'] = OpenStudio.openStudioLongVersion.to_s
    result[:openstudio]['getOpenStudioModule'] = OpenStudio.getOpenStudioModule.to_s
    result[:openstudio]['getOpenStudioCLI'] = OpenStudio.getOpenStudioCLI.to_s
    result[:openstudio]['getEnergyPlusExecutable'] = OpenStudio.getEnergyPlusExecutable.to_s
    result[:openstudio]['getRadianceDirectory'] = OpenStudio.getRadianceDirectory.to_s
    result[:openstudio]['getPerlExecutable'] = OpenStudio.getPerlExecutable.to_s

  rescue => exception
    result[:openstudio][:error] = exception.backtrace

    pretty_result = JSON.pretty_generate(result)

    puts pretty_result

    return result
  end

  pretty_result = JSON.pretty_generate(result)

  puts pretty_result

  return result
end
