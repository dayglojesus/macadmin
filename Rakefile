require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "macadmin/common"

# Only build the extension for Mountian Lion or better
if MacAdmin::Common::MAC_OS_X_PRODUCT_VERSION > 10.7
  
  require "rake/extensiontask"
  
  Rake::ExtensionTask.new "crypto" do |ext|
    ext.lib_dir = 'lib/macadmin/simplepassword'
    ext.name    = 'crypto'
    ext.ext_dir = 'ext/macadmin/simplepassword'
  end
  
  Rake::Task[:spec].prerequisites << :compile
  
end

RSpec::Core::RakeTask.new

task :default => :spec
task :test => :spec
