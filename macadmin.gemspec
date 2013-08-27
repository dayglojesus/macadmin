# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'macadmin/version'

Gem::Specification.new do |spec|
  spec.name          = "macadmin"
  spec.version       = Macadmin::VERSION
  spec.date          = '2012-07-08'
  spec.authors       = ["Brian Warsing"]
  spec.email         = ['dayglojesus@gmail.com']
  spec.description   = "Libraries for performing common systems administration tasks in Mac OS X"
  spec.summary       = "Ruby Mac Systems Administration Library"
  spec.homepage      = "http://github.com/dayglojesus/rbmacadmin"
  spec.license       = "MIT"
  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
