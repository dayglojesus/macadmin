module MacAdmin
  
  # Custom error
  class ShadowHashError < StandardError
    UNSUPPORTED_OBJECT_ERR = 'Unsupported object: cannot store ShadowHashData'
  end
  
  # ShadowHash (super class)
  # - common methods for password sub-classes
  class ShadowHash
    
    include MacAdmin::Password
    
    attr_reader :label
    
    class << self
      
      # Reads the password data from the user record
      # - returns an appropriate ShadowHash object
      def create_from_user_record(user)
        if user['ShadowHashData']
          password = read_shadowhashdata(user['ShadowHashData'])
          if password[SaltedSHA512::LABEL]
            return SaltedSHA512.create_from_shadowhashdata(password)
          else
            return SaltedSHA512PBKDF2.create_from_shadowhashdata(password)
          end
        else
          if guid = user['generateduid']
            return SaltedSHA1.create_from_shadowhash_file(guid)
          end
        end
        nil
      end
            
      # Returns Hash
      # - key: label, value: password data
      def read_shadowhashdata(data)
        plist = CFPropertyList::List.new(:data => data[0].to_s)
        CFPropertyList.native_types(plist.value)
      end
            
    end # end self
    
  end
  
  # Legacy ShadowHash
  # - password management for Mac OS X 10.6 and below
  # - passwords are managed in separate files in /var/db/shadow/hash
  class SaltedSHA1 < ShadowHash
    
    SHADOWHASH_STORE = '/private/var/db/shadow/hash'
    
    attr_accessor :hash
    
    class << self
      
      def create_from_shadowhash_file(guid)
        file = "#{SHADOWHASH_STORE}/#{guid}"
        if File.exists? file
          hash = read_from_shadowhash_file(file)
          return nil unless hash
          self.new(hash)
        end
      end
      
      def read_from_shadowhash_file(file)
        content = File.readlines(file).first
        content[168,48]
      end
      
    end
    
    # Initializes a SaltedSHA512 ShadowHash object from string
    # - string param should be a hex string, 24 bytes
    def initialize(string)
      @hash = validate(string)
    end
    
    # Validates the string param
    # - ensure the string param is hex string 24 bytes long
    def validate(string)
      error = "Invalid: arg must be hexadecimal string (24 bytes)"
      raise ArgumentError.new(error) unless string =~ /([A-F0-9]{2}){24}/
      string
    end
    
    # Return a String representation of the ShadowHash data
    def password
      @hash.to_s
    end
    
    # Return the ShadowHash as a Salted SHA1 String
    def data
      @data ||= @hash.to_s
    end
    
    private
    
    # Pseudo callback
    # - this method does not modify User objects
    # - SHA1 passwords are not stored as part of the User object
    # - They're stored in separate files on disk
    def store(sender)
      raise ShadowHashError.new(ShadowHashError::UNSUPPORTED_OBJECT_ERR) unless sender.is_a? MacAdmin::User
      @data = @hash.to_s
    end
    
    # Write password to file
    # - success based on the length of the file, must be 1240 bytes
    # - returns boolean
    def write_to_shadowhash_file(sender)
      raise ShadowHashError.new(ShadowHashError::UNSUPPORTED_OBJECT_ERR) unless sender.is_a? MacAdmin::User
      path = "#{SHADOWHASH_STORE}/#{sender[:generateduid].first}"
      file = File.open(path, mode='w+')
      content = file.read
      content = "0" * 1240 if content.length < 1240
      file.rewind
      content[168...(168 + 48)] = @hash.to_s
      file.write content
      file.close
      File.size(path) == 1240
    end
    alias :to_file :write_to_shadowhash_file
    
    # Remove the ShadowHash file associated with the sender
    # - returns boolean
    def remove_shadowhash_file(sender)
      raise ShadowHashError.new(ShadowHashError::UNSUPPORTED_OBJECT_ERR) unless sender.is_a? MacAdmin::User
      path = "#{SHADOWHASH_STORE}/#{sender[:generateduid].first}"
      FileUtils.rm path if File.exists? path
      !File.exists? path
    end
    alias :rm_file :remove_shadowhash_file
    
  end
  
  # Lion ShadowHash
  # - Mac OS X 10.7 store passwords as Salted SHA512 hashes
  # - hash is stored directly in the user's plist
  class SaltedSHA512 < ShadowHash
    
    LABEL = 'SALTED-SHA512'
    
    attr_accessor :hash
    
    class << self
      
      # Constructs a SaltedSHA512 ShadowHash object from ShadowHashData
      # - param is raw ShadowHashData object
      def create_from_shadowhashdata(data)
        value = data[SaltedSHA512::LABEL].to_s
        hex = MacAdmin::Password.convert_to_hex(value)
        self.new(hex)
      end
      
    end
    
    # Initializes a SaltedSHA512 ShadowHash object from string
    # - string param should be a hex string, 68 bytes
    def initialize(string)
      @label = LABEL
      @hash = validate(string)
    end
    
    # Validates the string param
    # - ensure the string param is hex string 68 bytes long
    def validate(string)
      error = "Invalid: arg must be hexadecimal string (68 bytes)"
      raise ArgumentError.new(error) unless string =~ /([a-f0-9]{2}){68}/
      string
    end
    
    # Return the ShadowHash as a ShadowHashData object
    # - Binary Plist
    def data
      @data ||= { @label => convert_to_blob(@hash) }.to_plist
    end
    
    # Return a Hash representation of the ShadowHash data
    def password
      { @label => @hash }
    end
    
    private
    
    # Pseudo callback for inserting a ShadowHashData object into the User object
    def store(sender)
      raise ShadowHashError.new(ShadowHashError::UNSUPPORTED_OBJECT_ERR) unless sender.is_a? MacAdmin::User
      @data = { @label => convert_to_blob(@hash) }.to_plist
      sender['ShadowHashData'] = [@data]
    end
    
  end
  
  # Current ShadowHash Scheme
  # - Mac OS X 10.8 and up store passwords as Salted SHA512-PBKDF2 hashes
  # - hash is stored directly in the user's plist
  class SaltedSHA512PBKDF2 < ShadowHash
    
    LABEL = 'SALTED-SHA512-PBKDF2'
    
    class << self
      
      # Constructs a SaltedSHA512PBKDF2 ShadowHash object from ShadowHashData
      # - param is raw ShadowHashData object
      def create_from_shadowhashdata(data)
        hash = data[SaltedSHA512PBKDF2::LABEL]
        hash = hash.inject({}) do |memo, (key, value)|
          if key.eql? 'iterations'
            value = value.to_i
          else
            value = MacAdmin::Password.convert_to_hex(value)
          end
          memo[key.to_sym] = value
          memo
        end
        self.new(hash)
      end
      
    end
    
    # Initializes a SaltedSHA512PBKDF2 ShadowHash object from Hash or Array
    # - if passing an array, you must order the elements: entropy, salt, iterations
    # - pass a Hash with keys: entropy, salt, iterations
    def initialize(args)
      @label = LABEL
      @hash = validate(args)
    end
    
    # Validates the params
    # - ensure that we have the required params
    # - an Array that maps to required_keys structure
    # - a Hash that contains the required keys
    # - all values are qualified according to requirements
    def validate(args)
      error = nil
      hash = nil
      required_keys = [:entropy, :salt, :iterations]
      if args.is_a? Array
        hash = Hash[required_keys.zip(args)]
      elsif args.is_a? Hash
        hash = args
      end
      # validate hash
      unless (hash.keys - required_keys).empty?
        error = "Invalid: args must contain, #{required_keys.join(', ')}"
      end
      unless hash[:entropy] =~ /([a-f0-9]{2}){128}/
        error = "Invalid: entropy must be hexadecimal string (128 bytes)"
      end
      unless hash[:salt] =~ /([a-f0-9]{2}){32}/
        error = "Invalid: salt must be hexadecimal string (32 bytes)"
      end
      unless hash[:iterations] >= 0
        error = "Invalid: entropy must positive integer"
      end
      raise ArgumentError.new(error) if error
      hash
    end
    
    # Return the ShadowHash as a ShadowHashData object
    # - Binary Plist
    def data
      @data ||= { @label => format(@hash) }.to_plist
    end
    
    # Return a Hash representation of the ShadowHash data
    def password
      { @label => @hash }
    end
    
    private

    # Pseudo callback for inserting a ShadowHashData object into the User object
    def store(sender)
      raise ShadowHashError.new(ShadowHashError::UNSUPPORTED_OBJECT_ERR) unless sender.is_a? MacAdmin::User
      @data = { @label => format(@hash) }.to_plist
      sender['ShadowHashData'] = [@data]
    end
    
    # Format the password data for ShadowHashData object compatibility
    def format(hash)
      hash.inject({}) do |memo, (key, value)|
        if key.to_s.eql? 'iterations'
          value = value.to_i
        else
          value = convert_to_blob value
        end
        memo[key.to_s] = value
        memo
      end
    end
    
  end
  
end
