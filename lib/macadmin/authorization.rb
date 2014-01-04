module MacAdmin

  module Authorization
  end
  
  # AuthorizationStatus
  # - object comprising a code and description pertaining to the exit status of the database operation
  # - see Result Codes: https://developer.apple.com/library/mac/documentation/security/Reference/authorization_ref
  class AuthorizationStatus
    
    RESULT_CODES = {
            0 => "The operation completed successfully.",
       -60001 => "The set parameter is invalid.",
       -60002 => "The authorization parameter is invalid.",
       -60003 => "The tag parameter is invalid.",
       -60004 => "The authorizedRights parameter is invalid.",
       -60005 => "The Security Server denied authorization for one or more requested rights. This error is also returned if there was no definition found in the policy database, or a definition could not be created.",
       -60006 => "The user canceled the operation.",
       -60007 => "The Security Server denied authorization because no user interaction is allowed.",
       -60008 => "An unrecognized internal error occurred.",
       -60009 => "The Security Server denied externalization of the authorization reference.",
       -60010 => "The Security Server denied internalization of the authorization reference.",
       -60011 => "The flags parameter is invalid.",
       -60031 => "The tool failed to execute.",
       -60032 => "The attempt to execute the tool failed to return a success or an error code.",
    }
    
    attr_reader :code, :description
    
    def initialize(code)
      @code = code
      @description = RESULT_CODES[@code]
    end
    
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
    
    attr_reader :name, :definition, :status
    
    def initialize(name, definition = {})
      validate(name, definition)
      @name = name
      @real = Authorization.get_authorization_right @name
      @definition = @real.merge normalize(definition)
      self
    end
    
    # definition setter
    # - accepts a Hash and normalizes keys
    def definition=(hash)
      @definition = normalize(hash)
    end
    
    # Create the right in the OS X Authorization database
    # - returns true if successful, false otherwise
    # - sets @status using AuthorizationStatus object
    def create
      result  = Authorization.set_authorization_right @name, @definition
      @status = AuthorizationStatus.new result
      return false unless result == 0
      @definition = Authorization.get_authorization_right @name
      true
    end
    
    # Does the specified resource already exist?
    # - returns Boolean
    def exists?
      @real = Authorization.get_authorization_right @name
      @definition = @real.merge @definition
      @definition.eql? @real
    end
    
    # Destroy the right in the OS X Authorization database
    # - returns true if successful, false otherwise
    # - sets @status using AuthorizationStatus object
    def destroy
      result  = Authorization.rm_authorization_right @name
      @status = AuthorizationStatus.new result
      return false unless result == 0
      true
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