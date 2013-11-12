require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "macadmin/common"
require "macadmin/version"

# Only build the extension for Mountian Lion or better
if MacAdmin::Common::MAC_OS_X_PRODUCT_VERSION > 10.7
  
  require "rake/extensiontask"
  
  Rake::ExtensionTask.new "crypto" do |ext|
    ext.lib_dir = 'lib/macadmin/password'
    ext.name    = 'crypto'
    ext.ext_dir = 'ext/macadmin/password'
  end
  
  Rake::Task[:spec].prerequisites << :compile
  
end

RSpec::Core::RakeTask.new

task :default => :spec
task :test => :spec

# Version handling tasks
namespace :version do
  
  namespace :bump do
    
    desc "Bump the patch version number"
    task :patch do
      MacAdmin::VERSION.bump_patch
      MacAdmin::VERSION.save
    end
    
    desc "Bump the minor version number"
    task :minor do
      MacAdmin::VERSION.bump_minor
      MacAdmin::VERSION.save
    end
    
    desc "Bump the major version number"
    task :major do
      MacAdmin::VERSION.bump_major
      MacAdmin::VERSION.save
    end
    
  end
  
end