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
task :test    => :spec

# macadmin tasks
namespace :macadmin do
  
  desc "Fix permissions on Gem"
  task :fix_perms do
    require 'find'
    Find.find(File.expand_path("./")) do |path|
      FileUtils.chmod(0755, path) if FileTest.directory?(path)
      FileUtils.chmod(0644, path) if FileTest.file?(path)
    end
  end
  
  desc "Cleans out any elements of the gem build compile process"
  task :clean do
    require 'fileutils'
    files = ["./lib/macadmin/password", "./tmp", "./pkg", "./vendor"]
    files.each do |obj|
      FileUtils.rm_rf(File.expand_path(obj))
    end
  end
  
  # Version handling tasks
  desc "Bump the patch version number"
  task :bump_version_patch do
    MacAdmin::VERSION.bump_patch
    MacAdmin::VERSION.save
    `git add ./version.yaml`
    `git commit -m "bump patch version, #{MacAdmin::VERSION.to_s}"`
  end
  
  desc "Bump the minor version number"
  task :bump_version_minor do
    MacAdmin::VERSION.bump_minor
    MacAdmin::VERSION.save
    `git add ./version.yaml`
    `git commit -m "bump minor version, #{MacAdmin::VERSION.to_s}"`
  end
  
  desc "Bump the major version number"
  task :bump_version_major do
    MacAdmin::VERSION.bump_major
    MacAdmin::VERSION.save
    `git add ./version.yaml`
    `git commit -m "bump major version, #{MacAdmin::VERSION.to_s}"`
  end
  
end
