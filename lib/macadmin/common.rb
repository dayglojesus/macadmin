module MacAdmin
  
  module Common
    
    extend self
    
    # Mac OS X major version number
    MAC_OS_X_PRODUCT_VERSION = `/usr/bin/sw_vers`.split("\n")[1].split("\t").last.to_f
   
    # Class for creating and checking UUID strings
    class UUID < String
    
      # 897A6343-628F-4964-80F1-C86D0FFA3F91
      UUID_REGEX = '([A-Z0-9]{8})-([A-Z0-9]{4}-){3}([A-Z0-9]{12})'
      
      # Create a new UUID string
      def initialize
        uuid = %x{/usr/bin/uuidgen}.chomp
        super(uuid)
      end
      
      # Class methods
      class << self
        
        # Matches any string containing a UUID
        # - returns Boolean
        def match(string, options = nil)
          string =~ Regexp.new(UUID_REGEX, options) ? $& : false
        end
        
        # Validates the format of a UUID string
        # - only true is the entire string is a UUID match
        # - returns Boolean
        def valid?(uuid, options = nil)
          strictlyuuid = '^' + UUID_REGEX + '$'
          uuid =~ Regexp.new(strictlyuuid, options) ? true : false
        end
        
      end
        
    end
    
    # Get the primary ethernet's MAC address
    # - returns String
    def get_primary_mac_address
      raw = %x{/sbin/ifconfig en0}
      raw.grep(/ether/).first.split.last.chomp
    end
    
    # Load a PropertyList file
    # - convenience method
    # - single parameter is a path to the ProperyList file
    # - returns a Hash is if can parse the file
    # - returns nil if it cannot parse the file 
    def load_plist(file)
      return nil unless File.exists? file
      plist = CFPropertyList::List.new(:file => file)
      CFPropertyList.native_types(plist.value)
    end
    
    # Restart the local directory service daemon
    # - single param wait (Integer) measured in seconds
    # - default wait is 10 seconds
    def restart_directoryservice(wait=10)
      if MAC_OS_X_PRODUCT_VERSION < 11
        system('/usr/bin/killall DirectoryService')
      else
        system('/usr/bin/killall opendirectoryd')
      end
      sleep wait
    end
  
    # Alias for convenience
    alias :restart_opendirectoryd :restart_directoryservice
  
  end
  
end