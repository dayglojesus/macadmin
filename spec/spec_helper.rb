$LOAD_PATH.push File.expand_path("../../lib", __FILE__)
require 'rubygems'
require 'rspec'
require 'macadmin'

RSpec.configure do |config|
  config.color_enabled = true
  config.formatter     = 'documentation'
end