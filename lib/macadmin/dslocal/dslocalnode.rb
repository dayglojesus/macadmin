module MacAdmin
  
  class DSLocalNodeError < StandardError
  end
  
  class DSLocalNode
    
    require 'find'
    
    PREFERENCES        = '/Library/Preferences/OpenDirectory/Configurations/Search.plist'
    PREFERENCES_LEGACY = '/Library/Preferences/DirectoryService/SearchNodeConfig.plist'
    CHILD_DIRS         = ['aliases', 'computer_lists', 'computergroups', 'computers', 'config', 'groups', 'networks', 'users']
    DSLOCAL_ROOT       = '/private/var/db/dslocal/nodes'
    DIRMODE            = 16832
    FILEMODE           = 33152
    OWNER              = 0
    GROUP              = 0
    
    attr_reader :name, :label, :root
    
    def initialize(name='Default')
      @name   = name
      @label  = "/Local/#{name}"
      @root   = "#{DSLOCAL_ROOT}/#{name}"
      load_configuration_file
      self
    end
    
    def create_and_activate
      create
      activate
    end
    
    def destroy_and_deactivate
      destroy
      deactivate
    end
    
    def exists_and_active?
      exists? and active?
    end
    
    # Does the directory structure exist?
    def exists?
      validate_directory_structure
    end
    
    # Test whether or not the node is in the search path
    def active?
      load_configuration_file
      return false if cspsearchpath.nil?
      cspsearchpath.member?(@label)
    end
    
    # Create the directory structure
    def create
      create_directories
    end
    
    # Destroy the directory structure
    def destroy
      FileUtils.rm_rf @root
    end
    
    # Add the node to the list of searchable directory services
    def activate
      insert_node
      save_config
    end
    
    # Remove the node to the list of searchable directory services
    def deactivate
      remove_node
      save_config
    end
    
    # Returns the search policy
    def searchpolicy
      eval @policy_key
    end
    
    # Replaces the search policy
    def searchpolicy=(val)
      if val.is_a?(String)
        eval @policy_key+"= val"
      else
        eval @policy_key+"= #{val}"
      end
    end
    
    # Returns the search path array
    def cspsearchpath
      eval @paths_key
    end
    
    # Replaces the search path array
    def cspsearchpath=(array)
      eval @paths_key+"= array"
    end
    
    private
        
    # Insert the node into the search path immediately after any builtin local nodes
    def insert_node
      self.cspsearchpath ||= []
      dslocal_node  = '/Local/Default'
      bsd_node      = '/BSD/local'
      
      if index = cspsearchpath.index(bsd_node)
        cspsearchpath.insert(index + 1, @label)
      elsif index = cspsearchpath.index(dslocal_node)
        cspsearchpath.insert(index + 1, @label)
      else
        cspsearchpath.unshift(@label)
      end
    end
    
    # Remove the node from the search path
    def remove_node
      cspsearchpath.delete(@label)
    end
    
    # Has custom ds searching been enabled?
    def searchpolicy_is_custom?
      searchpolicy.eql?(@custom)
    end
    
    # Set the search opolicy to custom
    def set_custom_searchpolicy
      self.searchpolicy = @custom
    end
    
    # Save the configuraton file to disk
    def save_config
      plist = CFPropertyList::List.new
      plist.value = CFPropertyList.guess(@config)
      plist.save(@file, CFPropertyList::List::FORMAT_XML)
    end
    
    # Check hierarchy and permissions and ownership are valid
    # - returns bool
    def validate_directory_structure
      return false unless File.exists? @root
      Find.find(@root) do |path|
        stat = File::Stat.new path
        return false unless stat.uid == OWNER and stat.gid == GROUP
        if File.directory? path
         return false unless stat.mode == DIRMODE
       else
         return false unless stat.mode == FILEMODE
       end
      end
      true
    end
    
    # Create the dir structure for a DSLocal node
    def create_directories
      begin
        FileUtils.mkdir_p @root unless File.exist? @root
        FileUtils.chmod(0700, @root)
        CHILD_DIRS.each do |child|
          FileUtils.mkdir_p("#{@root}/#{child}") unless File.exist?("#{@root}/#{child}")
          FileUtils.chmod(0700, "#{@root}/#{child}")
        end
        FileUtils.chown_R(OWNER, GROUP, @root)
      rescue Exception => e
        p e.message
        p e.backtrace.inspect
      end
    end
    
    # Decide which configuration file we should be trying to access
    def get_configuration_file
      file = PREFERENCES_LEGACY
      file = PREFERENCES if File.exists? '/usr/libexec/opendirectoryd'
      file
    end
    
    # If the file we need is still not on disk, we HUP the dir service
    # Try 3 times, and then fail
    def load_configuration_file
      3.times do
        @file = get_configuration_file
        if File.exists? @file
          break
        else
          restart_directoryservice(11)
        end
      end
      raise DSLocalNodeError "Cannot read the Search policy file, #{@file}" unless File.exists?(@file)
      @config = load_plist @file
      # Setup some configuration key paths that can be evaluated and plugged into
      # the standard methods. Which paths are used is based on which config file 
      # we are working with.
      if @config['modules']
        @paths_key  = %q{@config['modules']['session'][0]['options']['dsAttrTypeStandard:CSPSearchPath']}
        @policy_key = %q{@config['modules']['session'][0]['options']['dsAttrTypeStandard:SearchPolicy']}
        @custom     = 'dsAttrTypeStandard:CSPSearchPath'
      else
        @paths_key  = %q{@config['Search Node Custom Path Array']}
        @policy_key = %q{@config['Search Policy']}
        @custom     = 3
      end
    end
    
  end
  
end