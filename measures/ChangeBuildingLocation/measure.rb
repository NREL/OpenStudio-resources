# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2018, Alliance for Sustainable Energy, LLC.
# All rights reserved.
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# (1) Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# (2) Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# (3) Neither the name of the copyright holder nor the names of any contributors
# may be used to endorse or promote products derived from this software without
# specific prior written permission from the respective party.
#
# (4) Other than as required in clauses (1) and (2), distributions in any form
# of modifications or other derivative works may not use the "OpenStudio"
# trademark, "OS", "os", or any other confusingly similar designation without
# specific prior written permission from Alliance for Sustainable Energy, LLC.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER(S) AND ANY CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER(S), ANY CONTRIBUTORS, THE
# UNITED STATES GOVERNMENT, OR THE UNITED STATES DEPARTMENT OF ENERGY, NOR ANY OF
# THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
# OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# *******************************************************************************

# Authors : Nicholas Long, David Goldwasser
# Simple measure to load the EPW file and DDY file

class ChangeBuildingLocation < OpenStudio::Measure::ModelMeasure

  Dir[File.dirname(__FILE__) + '/resources/*.rb'].each { |file| require file }

  # resource file modules
  include OsLib_HelperMethods

  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    'ChangeBuildingLocation'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    weather_file_name = OpenStudio::Measure::OSArgument.makeStringArgument('weather_file_name', true)
    weather_file_name.setDisplayName('Weather File Name')
    weather_file_name.setDescription('Name of the weather file to change to. This is the filename with the extension (e.g. NewWeather.epw). Optionally this can inclucde the full file path, but for most use cases should just be file name.')
    args << weather_file_name

    # make choice argument for climate zone
    choices = OpenStudio::StringVector.new
    choices << '1A'
    choices << '1B'
    choices << '2A'
    choices << '2B'
    choices << '3A'
    choices << '3B'
    choices << '3C'
    choices << '4A'
    choices << '4B'
    choices << '4C'
    choices << '5A'
    choices << '5B'
    choices << '5C'
    choices << '6A'
    choices << '6B'
    choices << '7'
    choices << '8'
    choices << 'Lookup From Stat File'
    climate_zone = OpenStudio::Measure::OSArgument.makeChoiceArgument('climate_zone', choices, true)
    climate_zone.setDisplayName('Climate Zone.')
    climate_zone.setDefaultValue('Lookup From Stat File')
    args << climate_zone

    # make an argument for use_upstream_args
    use_upstream_args = OpenStudio::Measure::OSArgument.makeBoolArgument('use_upstream_args', true)
    use_upstream_args.setDisplayName('Use Upstream Argument Values')
    use_upstream_args.setDescription('When true this will look for arguments or registerValues in upstream measures that match arguments from this measure, and will use the value from the upstream measure in place of what is entered for this measure.')
    use_upstream_args.setDefaultValue(true)
    args << use_upstream_args

    args
  end

  # Define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # assign the user inputs to variables
    args = OsLib_HelperMethods.createRunVariables(runner, model, user_arguments, arguments(model))
    if !args then return false end

    # lookup and replace argument values from upstream measures
    if args['use_upstream_args'] == true
      args.each do |arg,value|
        next if arg == 'use_upstream_args' # this argument should not be changed
        value_from_osw = OsLib_HelperMethods.check_upstream_measure_for_arg(runner, arg)
        if !value_from_osw.empty?
          runner.registerInfo("Replacing argument named #{arg} from current measure with a value of #{value_from_osw[:value]} from #{value_from_osw[:measure_name]}.")
          new_val = value_from_osw[:value]
          # todo - make code to handle non strings more robust. check_upstream_measure_for_arg coudl pass bakc the argument type
          if arg == 'total_bldg_floor_area'
            args[arg] = new_val.to_f
          elsif arg == 'num_stories_above_grade'
            args[arg] = new_val.to_f
          elsif arg == 'zipcode'
            args[arg] = new_val.to_i
          else
            args[arg] = new_val
          end
        end
      end
    end

    # create initial condition
    if model.getWeatherFile.city != ''
      runner.registerInitialCondition("The initial weather file is #{model.getWeatherFile.city} and the model has #{model.getDesignDays.size} design day objects")
    else
      runner.registerInitialCondition("No weather file is set. The model has #{model.getDesignDays.size} design day objects")
    end

    # find weather file
    osw_file = runner.workflow.findFile(args['weather_file_name'])
    if osw_file.is_initialized
      weather_file = osw_file.get.to_s
    else
      runner.registerError("Did not find #{args['weather_file_name']} in paths described in OSW file.")
      return false
    end

    # Parse the EPW manually because OpenStudio can't handle multiyear weather files (or DATA PERIODS with YEARS)
    epw_file = OpenStudio::Weather::Epw.load(weather_file)

    weather_file = model.getWeatherFile
    weather_file.setCity(epw_file.city)
    weather_file.setStateProvinceRegion(epw_file.state)
    weather_file.setCountry(epw_file.country)
    weather_file.setDataSource(epw_file.data_type)
    weather_file.setWMONumber(epw_file.wmo.to_s)
    weather_file.setLatitude(epw_file.lat)
    weather_file.setLongitude(epw_file.lon)
    weather_file.setTimeZone(epw_file.gmt)
    weather_file.setElevation(epw_file.elevation)
    weather_file.setString(10, "file:///#{epw_file.filename}")

    weather_name = "#{epw_file.city}_#{epw_file.state}_#{epw_file.country}"
    weather_lat = epw_file.lat
    weather_lon = epw_file.lon
    weather_time = epw_file.gmt
    weather_elev = epw_file.elevation

    # Add or update site data
    site = model.getSite
    site.setName(weather_name)
    site.setLatitude(weather_lat)
    site.setLongitude(weather_lon)
    site.setTimeZone(weather_time)
    site.setElevation(weather_elev)

    runner.registerInfo("city is #{epw_file.city}. State is #{epw_file.state}")

    # Add SiteWaterMainsTemperature -- via parsing of STAT file.
    stat_file = "#{File.join(File.dirname(epw_file.filename), File.basename(epw_file.filename, '.*'))}.stat"
    unless File.exist? stat_file
      runner.registerInfo 'Could not find STAT file by filename, looking in the directory'
      stat_files = Dir["#{File.dirname(epw_file.filename)}/*.stat"]
      if stat_files.size > 1
        runner.registerError('More than one stat file in the EPW directory')
        return false
      end
      if stat_files.empty?
        runner.registerError('Cound not find the stat file in the EPW directory')
        return false
      end

      runner.registerInfo "Using STAT file: #{stat_files.first}"
      stat_file = stat_files.first
    end
    unless stat_file
      runner.registerError 'Could not find stat file'
      return false
    end

    stat_model = EnergyPlus::StatFile.new(stat_file)
    water_temp = model.getSiteWaterMainsTemperature
    water_temp.setAnnualAverageOutdoorAirTemperature(stat_model.mean_dry_bulb)
    water_temp.setMaximumDifferenceInMonthlyAverageOutdoorAirTemperatures(stat_model.delta_dry_bulb)
    runner.registerInfo("mean dry bulb is #{stat_model.mean_dry_bulb}")

    # Remove all the Design Day objects that are in the file
    model.getObjectsByType('OS:SizingPeriod:DesignDay'.to_IddObjectType).each(&:remove)

    # find the ddy files
    ddy_file = "#{File.join(File.dirname(epw_file.filename), File.basename(epw_file.filename, '.*'))}.ddy"
    unless File.exist? ddy_file
      ddy_files = Dir["#{File.dirname(epw_file.filename)}/*.ddy"]
      if ddy_files.size > 1
        runner.registerError('More than one ddy file in the EPW directory')
        return false
      end
      if ddy_files.empty?
        runner.registerError('could not find the ddy file in the EPW directory')
        return false
      end

      ddy_file = ddy_files.first
    end

    unless ddy_file
      runner.registerError "Could not find DDY file for #{ddy_file}"
      return error
    end

    ddy_model = OpenStudio::EnergyPlus.loadAndTranslateIdf(ddy_file).get
    ddy_model.getObjectsByType('OS:SizingPeriod:DesignDay'.to_IddObjectType).each do |d|
      # grab only the ones that matter
      ddy_list = /(Htg 99.6. Condns DB)|(Clg .4. Condns WB=>MDB)|(Clg .4% Condns DB=>MWB)/
      if d.name.get =~ ddy_list
        runner.registerInfo("Adding object #{d.name}")

        # add the object to the existing model
        model.addObject(d.clone)
      end
    end

    # Set climate zone
    climateZones = model.getClimateZones
    if args['climate_zone'] == 'Lookup From Stat File'

      # get climate zone from stat file
      text = nil
      File.open(stat_file) do |f|
        text = f.read.force_encoding('iso-8859-1')
      end

      # Get Climate zone.
      # - Climate type "3B" (ASHRAE Standard 196-2006 Climate Zone)**
      # - Climate type "6A" (ASHRAE Standards 90.1-2004 and 90.2-2004 Climate Zone)**
      regex = /Climate type \"(.*?)\" \(ASHRAE Standards?(.*)\)\*\*/
      match_data = text.match(regex)
      if match_data.nil?
        runner.registerWarning("Can't find ASHRAE climate zone in stat file.")
      else
        args['climate_zone'] = match_data[1].to_s.strip
      end

    end
    # set climate zone
    climateZones.clear
    climateZones.setClimateZone('ASHRAE', args['climate_zone'])
    runner.registerInfo("Setting Climate Zone to #{climateZones.getClimateZones('ASHRAE').first.value}")

    # add final condition
    runner.registerFinalCondition("The final weather file is #{model.getWeatherFile.city} and the model has #{model.getDesignDays.size} design day objects.")

    true
  end
end

# This allows the measure to be use by the application
ChangeBuildingLocation.new.registerWithApplication
