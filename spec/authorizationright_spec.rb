require 'spec_helper'
require 'macadmin/common'

describe MacAdmin::AuthorizationRight do
  
  describe "AUTHORIZATION_DB_DEFAULTS" do
    it 'is an OS X Property List file' do
      location = MacAdmin::AuthorizationRight::AUTHORIZATION_DB_DEFAULTS
      MacAdmin::Common.load_plist(location).should_not be_nil
    end
  end
  
  describe "#new" do
    
    context 'throws an ArgumentError when given fewer than 1 params' do
      subject { AuthorizationRight.new }
      it { expect { subject }.to raise_error(ArgumentError) }
    end
    
    context 'throws an ArgumentError when first param is not String' do
      subject { AuthorizationRight.new 1 }
      it { expect { subject }.to raise_error(ArgumentError) }
    end
    
    context 'throws an ArgumentError when second is param is not Hash' do
      subject { AuthorizationRight.new "foo.bar", 1 }
      it { expect { subject }.to raise_error(ArgumentError) }
    end
    
    context 'returns an AuthorizationRight object when given an valid name arg' do
      subject { AuthorizationRight.new 'foo.bar' }
      it 'takes a String argument and returns a AuthorizationRight object' do
        subject.should be_an_instance_of AuthorizationRight
      end
      it "responds to #name" do
        subject.name.should be_an_instance_of String
      end
      it "responds to #definition" do
        subject.definition.should be_an_instance_of Hash
      end
    end
    
    context 'returns an AuthorizationRight object when given an valid name and parameter Hash' do
      subject { AuthorizationRight.new 'foo.bar', { :group => "everyone" } }
      it 'takes one String and one Hash argument and returns a AuthorizationRight object' do
        subject.should be_an_instance_of AuthorizationRight
      end
    end
    
  end
  
  describe "#name" do
    subject { AuthorizationRight.new 'foo.bar', { :group => "everyone" } }
    it "responds to #name" do
      subject.name.should be_an_instance_of String
    end
  end
  
  describe "#name=" do
    auth = AuthorizationRight.new 'foo.bar', { :group => "everyone" }
    it { expect { auth.name=("bar.baz") }.to raise_error(NoMethodError) }
  end
  
  describe "#definition" do
    subject { AuthorizationRight.new 'foo.bar', { :group => "everyone" } }
    it "responds to #definition" do
      subject.definition.should be_an_instance_of Hash
    end
  end
  
  describe "#definition=" do
    auth = AuthorizationRight.new 'foo.bar', { :group => "everyone" }
    hash = { :group => "admin" }
    it "should return true" do
      auth.send(:definition=, hash).should be_true
    end
  end
  
  describe "#exists?" do
    
    context "when the object is different from its associated record" do
      subject { AuthorizationRight.new 'system.preferences', :group => "everyone" }
      it { subject.exists?.should be_false } 
    end
    
    context "when the object is identical to its associated file" do
      subject { AuthorizationRight.new  "system.preferences", 
                                        "allow-root" => true,
                                        "authenticate-user" => true,
                                        "shared" => true,
                                        "group" => "admin",
                                        "class" => "user",
                                        "session-owner" => false }
      it { subject.exists?.should be_true }
    end
    
  end
  
  describe "#create" do
    
    it "returns true when the record is created successfully" do
      AuthorizationRight.new('foo.bar', :group => "everyone").create.should be_true
    end
    
  end
  
end
