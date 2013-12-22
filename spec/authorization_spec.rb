require 'spec_helper'
require 'macadmin/common'

describe MacAdmin::Authorization do
  
  describe '#get_authorization_right' do
    it "should return an Hash object" do
      MacAdmin::Authorization.get_authorization_right("system.preferences").should be_an_instance_of Hash
    end
  end
  
  describe '#set_authorization_right' do
    it "should return an Fixnum object" do
      MacAdmin::Authorization.set_authorization_right("foo.bar", {}).should be_an_instance_of Fixnum
    end
  end
  
  describe '#rm_authorization_right' do
    it "should return an Fixnum object" do
      MacAdmin::Authorization.rm_authorization_right("foo.bar").should be_an_instance_of Fixnum
    end
  end
  
end