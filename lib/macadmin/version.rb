module MacAdmin
  
  # Version
  # - Class for working with the version number
  class Version
    
    require 'yaml'
    
    FILE = File.expand_path('version.yaml')
    
    attr_accessor :major, :minor, :patch
    
    # Create from String
    # - ie. "0.0.1"
    def self.init_with_string(version)
      @major, @minor, @patch = version.split(".").each(&:to_i)
    end
    
    # Init from a YAML file
    def self.load_yaml_file(file = FILE)
      YAML.load_file FILE
    end
    
    # Returns a version String
    def to_s
      "#{@major}.#{@minor}.#{@patch}"
    end
    
    # Increment the major version number
    def bump_major
      @major += 1
    end
    
    # Increment the minor version number
    def bump_minor
      @minor += 1
    end
    
    # Increment the patch version number
    def bump_patch
      @patch += 1
    end
    
    # Serialize the object to YAML file
    def save(file = FILE)
      File.open(file, 'w') { |f| f.write self.to_yaml }
    end
    
  end
  
  VERSION = Version.load_yaml_file
  
  # Return a formatted string containing the Gem's name and version
  def self.version_string
    "macadmin version, #{MacAdmin::VERSION.to_s}"
  end
  
end