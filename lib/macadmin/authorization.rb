module MacAdmin

  module Authorization
  end
  
  # AuthorizationRight
  # - creates and manages OS X Authorization database rithgs
  # - params: :name, :definition
  # - name param is a String, the name of the authorization right
  # - definition is a Hash containing keys defining the rules
  # - https://developer.apple.com/library/mac/documentation/security/Reference/authorization_ref
  class AuthorizationRight
    
    include Authorization
    
    # This file contains the defaults for all the rights & rules
    AUTHORIZATION_DB_DEFAULTS = '/System/Library/Security/authorization.plist'
    
    attr_reader :name, :definition
    
    def initialize(name, definition = {})
      validate(name, definition)
      @name = name
      @real = Authorization.get_authorization_right(@name)
      @definition = @real.merge(normalize(definition))
      self
    end
    
    # definition setter
    # - accepts a Hash and normalizes keys
    def definition=(hash)
      @definition = normalize(hash)
    end
    
    private
    
    # validate
    # - ensure we have the correct parameters
    def validate(*params)
      unless params.first.is_a?(String)
        raise ArgumentError.new "expected String, got #{params.first.class}"
      end
      unless params.last.is_a?(Hash)
        raise ArgumentError.new "expected Hash, got #{params.last.class}"
      end
    end
    
    # Format the user input so it can be processed
    # - input is key/value pairs
    # - keys are converted to strings if they're symbols
    # - values are preserved
    def normalize(input)
      input.inject({}){ |memo,(k,v)| memo[k.to_s] = v; memo }
    end
    
  end

end