# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'macadmin/version'

Gem::Specification.new do |s|
  s.name          = "macadmin"
  s.version       = MacAdmin::VERSION
  s.date          = '2012-07-08'
  s.authors       = ["Brian Warsing"]
  s.email         = ['dayglojesus@gmail.com']
  s.description   = "Libraries for performing common systems administration tasks in Mac OS X"
  s.summary       = "Ruby Mac Systems Administration Library"
  s.homepage      = "http://github.com/dayglojesus/macadmin"
  s.license       = "MIT"
  s.files         = `git ls-files`.split($/)
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]

  s.add_development_dependency "bundler", "~> 1.3"
  s.add_development_dependency "rake"
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'CFPropertyList'
  
  s.add_runtime_dependency "bundler", "~> 1.3"
  s.add_runtime_dependency "rake"
  s.add_runtime_dependency 'CFPropertyList'
  
end
