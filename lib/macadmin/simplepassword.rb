module MacAdmin
  
  module SimplePassword
    
    extend self
    
    if MacAdmin::Common::MAC_OS_X_PRODUCT_VERSION > 10.7
      
      require 'macadmin/simplepassword/crypto'
      
      def salted_sha512_pbkdf2(password)
        hash = salted_sha512_pbkdf2_from_string password
        SaltedSHA512PBKDF2.new hash
      end
      
    end
    
  end
    
end