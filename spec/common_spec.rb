require 'spec_helper'

describe MacAdmin::Common do

  describe 'MAC_OS_X_PRODUCT_VERSION' do
    it 'is a float greater than 10' do
      version = MacAdmin::Common::MAC_OS_X_PRODUCT_VERSION
      version.should > 10
    end
  end
  
  describe '#load_plist' do
    it 'should return an Hash object' do
      file = '/System/Library/CoreServices/SystemVersion.plist'
      MacAdmin::Common::load_plist(file).should be_an_instance_of Hash
    end
  end
  
end

describe MacAdmin::Common::UUID do

  before :all do
    @uuid = '897A6343-628F-4964-80F1-C86D0FFA3F91'
  end
  
  describe '#new' do
    it 'should return a UUID string' do
      UUID.new.should =~ /([A-Z0-9]{8})-([A-Z0-9]{4}-){3}([A-Z0-9]{12})/
    end
  end
  
  describe '#match' do
    it 'should match and return a UUID in _any_ string' do
      UUID.match("com.apple.loginwindow.#{@uuid}.plist").should == @uuid
    end
  end
  
  describe '#valid?' do
    it 'should return true if handed a valid UUID string' do
      UUID.valid?(@uuid).should == true
    end
    
    it 'should return false if handed a _bad_ UUID string' do
      UUID.valid?(@uuid.chop).should == false
    end
  end
  
end
