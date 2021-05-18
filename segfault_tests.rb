# frozen_string_literal: true

require 'openstudio' unless defined?(OpenStudio)

require 'etc'
require 'fileutils'
require 'json'
require 'erb'
require 'timeout'
require 'open3'

require 'minitest/autorun'
begin
  require 'minitest/reporters'
  require 'minitest/reporters/default_reporter'
  reporter = Minitest::Reporters::DefaultReporter.new
  reporter.start # had to call start manually otherwise was failing when trying to report elapsed time when run in CLI
  Minitest::Reporters.use! reporter
rescue LoadError
  puts 'Minitest Reporters not installed'
end

# Backward compat
Minitest::Test = MiniTest::Unit::TestCase unless defined?(Minitest::Test)

class SegfaultTests < Minitest::Test
  def test_segfault1
    m = OpenStudio::Model::Model.new
    puts '1'
    m.save('1.osm', true)
  end

  def test_segfault2
    m = OpenStudio::Model::Model.new
    puts '2'
    m.save('2.osm', true)
  end

  def test_segfault3
    m = OpenStudio::Model::Model.new
    puts '3'
    m.save('3.osm', true)
  end

  def test_segfault4
    m = OpenStudio::Model::Model.new
    puts '4'
    m.save('4.osm', true)
  end

  def test_segfault5
    m = OpenStudio::Model::Model.new
    puts '5'
    m.save('5.osm', true)
  end

  def test_segfault6
    m = OpenStudio::Model::Model.new
    puts '6'
    m.save('6.osm', true)
  end

  def test_segfault7
    m = OpenStudio::Model::Model.new
    puts '7'
    m.save('7.osm', true)
  end

  # def test_segfault8
  # m = OpenStudio::Model::Model.new
  # puts "8"
  # m.save("8.osm", true)
  # end
end
