require 'spec_helper'
require 'fileutils'

describe MacAdmin::Computer do
  
  describe '#new' do
    name = 'planet-express'
    subject { Computer.new name }
    it { should be_an_instance_of Computer }
    it 'should have a valid GeneratedUID attribute' do
      value = subject[:generateduid].first
      UUID.valid?(value).should be_true
    end
    its (:name)       { should eq [name] }
    its (:realname)   { should eq [name] }
    its (:en_address) { should eq [name] }
  end
  
end