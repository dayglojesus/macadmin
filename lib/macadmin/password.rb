module MacAdmin
  
  # Password
  # - module containing methods for converting a plain String into Mac OS X password hash
  module Password
    
    require 'openssl'
    require 'securerandom'
    
    extend self
    
    # This method is only available in Mountain Lion or better
    if MacAdmin::Common::MAC_OS_X_PRODUCT_VERSION > 10.7
      
      require "macadmin/password/crypto"
      
      # Creates a SaltedSHA512PBKDF2 password from String
      # - single param: String
      # - returns: SaltedSHA512PBKDF2
      def salted_sha512_pbkdf2(password)
        hash = salted_sha512_pbkdf2_from_string password
        SaltedSHA512PBKDF2.new hash
      end
      
    end
    
    # Creates a SaltedSHA512 password from String
    # - single param: String
    # - returns: SaltedSHA512
    def salted_sha512(password)
      salt = SecureRandom.random_bytes(4)
      hash = Digest::SHA512.hexdigest(salt + password)
      SaltedSHA512.new(MacAdmin::ShadowHash.convert_to_hex(salt) + hash)
    end
    
    # Creates a SaltedSHA1 password from String
    # - single param: String
    # - returns: SaltedSHA1
    def salted_sha1(password)
      salt = SecureRandom.random_bytes(4)
      hash = Digest::SHA1.hexdigest(salt + password)
      SaltedSHA1.new((MacAdmin::ShadowHash.convert_to_hex(salt) + hash).upcase)
    end
    
    # Create a platform appropriate password
    # - single param: String
    # - returns: SaltedSHA512PBKDF2 or SaltedSHA512 or SaltedSHA1 depending on platform
    def apropos(password)
      platform = MacAdmin::Common::MAC_OS_X_PRODUCT_VERSION
      if platform >= 10.8
        return salted_sha512_pbkdf2 password
      elsif platform == 10.7
        return salted_sha512 password
      else
        return salted_sha1 password
      end
    end
    
  end
    
end