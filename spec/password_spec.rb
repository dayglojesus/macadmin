require 'spec_helper'
require 'macadmin/common'

describe MacAdmin::Password do
  
  if MacAdmin::Common::MAC_OS_X_PRODUCT_VERSION > 10.7
    
    describe '#salted_sha512_pbkdf2' do
      it 'should return an SaltedSHA512PBKDF2 object' do
        MacAdmin::Password.salted_sha512_pbkdf2('').should be_an_instance_of SaltedSHA512PBKDF2
      end
    end
  
    describe '#salted_sha512_pbkdf2_from_string' do
      it 'should return an Hash object' do
        MacAdmin::Password.salted_sha512_pbkdf2_from_string('').should be_an_instance_of Hash
      end
    end
    
  end
  
  describe "#salted_sha512" do
    it "should return a SaltedSHA512 object" do
      MacAdmin::Password.salted_sha512('').should be_an_instance_of SaltedSHA512
    end
  end
  
  describe "#salted_sha1" do
    it "should return a SaltedSHA1 object" do
      MacAdmin::Password.salted_sha1('').should be_an_instance_of SaltedSHA1
    end
  end

  describe "#apropos" do
    it "should return a Password object" do
      MacAdmin::Password.salted_sha1('').should be_an_instance_of SaltedSHA1 or SaltedSHA512 or SaltedSHA512PBKDF2
    end
  end
  
end
