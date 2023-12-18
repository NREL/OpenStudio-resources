# frozen_string_literal: true

require 'openstudio'
require_relative 'lib/baseline_model'

model = BaselineModel.new

# add ASHRAE System type 03, PSZ-AC
model.add_hvac({ 'ashrae_sys_num' => '03' })

zones = model.getThermalZones.sort_by { |z| z.name.to_s }

if zones.nil?
  puts 'hello'
end
