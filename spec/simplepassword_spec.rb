require 'spec_helper'
require 'macadmin/common'

describe MacAdmin::SimplePassword do
  
  if MacAdmin::Common::MAC_OS_X_PRODUCT_VERSION > 10.7
    
    describe '#salted_sha512_pbkdf2' do
      it 'should return an SaltedSHA512PBKDF2 object' do
        MacAdmin::SimplePassword.salted_sha512_pbkdf2('').should be_an_instance_of SaltedSHA512PBKDF2
      end
    end
  
    describe '#salted_sha512_pbkdf2_from_string' do
      it 'should return an Hash object' do
        MacAdmin::SimplePassword.salted_sha512_pbkdf2_from_string('').should be_an_instance_of Hash
      end
    end
    
  end
  
end
