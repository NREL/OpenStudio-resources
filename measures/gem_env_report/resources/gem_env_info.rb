# Reports out information about the gem path and gems that are available and loaded.
# Used for debugging different runtime environments.
# Messages are put to stdout and returned in a hash.
# @return [Hash] a hash of information about the gems.
def gem_env_information

  require 'json'

  result = {}

  # Environment variables
  result[:env] = {}
  ENV.each do |k, v|
    vals = []
    v.split(';').each do |sub_v|
      vals << sub_v
    end
    result[:env][k] = vals
  end

  # Ruby executable
  require 'rbconfig'
  result[:rb_config] = RbConfig::CONFIG

  # Rubygems info
  require 'rubygems'
  require 'rubygems/version'
  result[:gem] = {}
  result[:gem][:version] = Gem::VERSION
  # result[:gem][:config_file] = Gem.config_file
  # result[:gem][:default_bindir] = Gem.default_bindir
  # result[:gem][:default_cert_path] = Gem.default_cert_path
  # result[:gem][:default_dir] = Gem.default_dir
  # result[:gem][:default_exec_format] = Gem.default_exec_format
  # result[:gem][:default_key_path] = Gem.default_key_path
  # result[:gem][:default_path] = Gem.default_path
  # result[:gem][:default_rubygems_dirs] = Gem.default_rubygems_dirs
  # result[:gem][:default_sources] = Gem.default_sources
  result[:gem][:dir] = Gem.dir
  # result[:gem][:host] = Gem.host
  result[:gem][:path] = Gem.path
  # result[:gem][:path_separator] = Gem.path_separator
  # result[:gem][:platforms] = Gem.platforms
  # result[:gem][:ruby] = Gem.ruby
  # result[:gem][:ruby_engine] = Gem.ruby_engine
  # result[:gem][:ruby_version] = Gem.ruby_version
  # result[:gem][:rubygems_version] = Gem.rubygems_version
  # result[:gem][:sources] = Gem.sources
  # result[:gem][:suffix_pattern] = Gem.suffix_pattern
  # result[:gem][:suffixes] = Gem.suffixes
  result[:gem][:user_dir] = Gem.user_dir
  result[:gem][:user_home] = Gem.user_home
  # result[:gem][:win_platform] = Gem.win_platform?
  
  # Available Gems
  result[:gem_specs_in_path] = {}
  local_gems = Gem::Specification.sort_by{ |g| [g.name.downcase, g.version] }.group_by{ |g| g.name }
  local_gems.each do |name, specs|
    versions = []
    specs.sort.each do |spec|
      versions << "- #{spec.version} from #{spec.spec_dir}"  
    end
    result[:gem_specs_in_path][name] = versions
  end

  # Loaded Gems
  result[:gem_specs_loaded] = {}
  loaded_gems = Gem.loaded_specs.sort_by { |g| g[0] }
  loaded_gems.each do |name, spec|
    result[:gem_specs_loaded][name] = ["- #{spec.version} from #{spec.spec_dir}"]
  end

  pretty_result = JSON.pretty_generate(result)

  puts pretty_result

  return result
end
