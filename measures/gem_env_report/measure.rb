# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

# start the measure
class GemEnvironmentReport < OpenStudio::Ruleset::ModelUserScript

  require_relative 'resources/gem_env_info'
  require_relative 'resources/openstudio_info'
  require 'json'

  # human readable name
  def name
    return "gem environment report"
  end

  # human readable description
  def description
    return "For OpenStudio testing and development; this measure reports out information about the gem path and gems that are available and loaded.  Used for debugging different runtime environments."
  end

  # human readable description of modeling approach
  def modeler_description
    return "For OpenStudio testing and development; this measure reports out information about the gem path and gems that are available and loaded.  Used for debugging different runtime environments."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    result = {}
    
    # Info from the measure's run environment
    result[:measure] = {}

    result[:measure][:openstudio_info] = openstudio_information

    result[:measure][:gem_env] = gem_env_information

    # Info from if measure calls the CLI
    cli_path = OpenStudio.getOpenStudioCLI

    result[:cli] = {}

    os_info_path = File.expand_path("../resources/run_openstudio_info.rb", __FILE__)
    os_info_cmd = "\"#{cli_path}\" \"#{os_info_path}\""
    result[:cli][:openstudio_info_cmd] = os_info_cmd
    begin
      os_info = `#{os_info_cmd}`
      begin
        os_info_parsed = JSON.parse(os_info)
      rescue => exception
        os_info_parsed = os_info.to_s
      end
    rescue => exception
      os_info_parsed = [exception.backtrace.to_s]
    end
    result[:cli][:openstudio_info] = os_info_parsed

    gem_env_info_path = File.expand_path("../resources/run_gem_env_info.rb", __FILE__)
    gem_env_info_cmd = "\"#{cli_path}\" \"#{gem_env_info_path}\""
    result[:cli][:gem_env_info_cmd] = gem_env_info_cmd
    begin
      gem_info = `#{gem_env_info_cmd}`
      begin
        gem_info_parsed = JSON.parse(gem_info)
      rescue => exception
        gem_info_parsed = gem_info.to_s
      end
    rescue => exception
      gem_info_parsed = [exception.backtrace.to_s]
    end
    result[:cli][:gem_env] = gem_info_parsed

    pretty_result = JSON.pretty_generate(result)

    pretty_result.each_line do |ln|
      runner.registerInfo("#{ln}")
    end

    # Write out to file
    json_name = 'report_gem_env.json'
    json_path = File.expand_path("./#{json_name}")
    File.open(json_path, "wb") do |f|
      f.puts pretty_result
    end
    json_path = File.absolute_path(json_path)
    runner.registerFinalCondition("Report saved to: #{json_path}")

    return true

  end
  
end

# register the measure to be used by the application
GemEnvironmentReport.new.registerWithApplication
