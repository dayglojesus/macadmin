require 'spec_helper'

describe MacAdmin do
  
  describe '#version_string' do
    
    it 'should return correct version string' do
      MacAdmin.version_string.should == "macadmin version, #{MacAdmin::VERSION}"
    end
    
  end
  
end