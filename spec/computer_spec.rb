require 'spec_helper'
require 'fileutils'

describe MacAdmin::Computer do
  
  before :all do
    # Create a dslocal sandbox
    @test_dir = "/private/tmp/macadmin_computer_test.#{rand(100000)}"
    MacAdmin::DSLocalRecord.send(:remove_const, :DSLOCAL_ROOT)
    MacAdmin::DSLocalRecord::DSLOCAL_ROOT = File.expand_path @test_dir
    FileUtils.mkdir_p "#{@test_dir}/Default/computers"
    
    # Create two computer record plists that we can load
    planet_express = { 
      "en_address"    => ["aa:aa:aa:aa:aa:aa"],
      "realname"      => ["Planet Express"],
      "name"          => ["planet-express"],
      "generateduid"  => ["00000000-0000-0000-0000-000000000001"],
    }
    
    [planet_express].each do |computer|
      record = CFPropertyList::List.new
      record.value = CFPropertyList.guess(computer)
      record.save("#{@test_dir}/Default/computers/#{computer['name'].first}.plist", CFPropertyList::List::FORMAT_BINARY)
    end
    
  end
  
  describe '#new' do
    
    context 'throws an ArgumentError when given fewer than 1 params' do
      subject { Computer.new }
      it { expect { subject }.to raise_error(ArgumentError) }
    end
    
    context 'when created from a parameter Hash' do
      subject { Computer.new :name => 'nimbus', :en_address => 'dd:dd:dd:dd:dd:dd' }
      it { should be_an_instance_of Computer }
      it 'should have a valid generateduid attribute' do 
        (UUID.valid?(subject.generateduid.first)).should be_true 
      end
      its (:name)       { should eq ['nimbus'] }
      its (:realname)   { should eq ['nimbus'.capitalize] }
      its (:en_address) { should eq ['dd:dd:dd:dd:dd:dd'] }
    end
    
    context 'when created from a just a name (String)' do
      subject { Computer.new 'nimbus' }
      it { should be_an_instance_of Computer }
      it 'should have a valid generateduid attribute' do 
        (UUID.valid?(subject.generateduid.first)).should be_true 
      end
      its (:name)       { should eq ['nimbus'] }
      its (:realname)   { should eq ['nimbus'.capitalize] }
      its (:en_address) { should eq [MacAdmin::Common.get_primary_mac_address] }
    end
    
  end
  
  describe '#exists?' do
    
    context "when the object is different from its associated file" do
      subject { Computer.new :name => 'planet-express', :en_address => "ff:ff:ff:ff:ff:ff" }
      it 'has an associated file' do
        File.exists?(subject.file).should be_true
      end
      it 'returns false because file and object do not match' do
        subject.exists?.should be_false
      end
    end
    
    context "when ALL the object's attributes match its associated file" do
      subject { Computer.new :name => 'planet-express', :en_address => "aa:aa:aa:aa:aa:aa" }
      it 'has an associated file' do
        File.exists?(subject.file).should be_true
      end
      it 'returns false because file and object do not match' do
        subject.exists?.should be_true
      end
    end
    
    context "when the object does not have an associated file on disk" do
      subject { Computer.new :name => 'nimbus' }
      it 'does not have an associated file' do
        File.exists?(subject.file).should be_false
      end
      it 'should return false' do
        subject.exists?.should be_false
      end
    end
    
  end
  
  describe '#create' do
    
    context "with NO path parameter (default)" do
      subject { Computer.new :name => 'nimbus', :en_address => "bb:bb:bb:bb:bb:bb" }
      it 'saves the record to disk on the derived path' do
        subject.create.should be_true
        File.exists?(subject.file).should be_true
      end
      after do
        FileUtils.rm_rf subject.file
      end
    end
    
    context "with a path parameter" do
      path = "/private/tmp/group-create-method-test.plist"
      subject { Computer.new :name => 'nimbus', :en_address => "bb:bb:bb:bb:bb:bb" }
      it 'saves the record to disk on the path specified' do
        subject.create(path).should be_true
      end
      after do
        FileUtils.rm_rf path
      end
    end
    
  end
  
  describe '#destroy' do
    subject { Computer.new :name => 'nimbus', :en_address => "bb:bb:bb:bb:bb:bb" }
    it 'removes the record on disk and returns true' do
      subject.create
      subject.destroy.should be_true
      File.exists?(subject.file).should be_false
    end
  end
  
  after :all do
    FileUtils.rm_rf @test_dir
  end
  
end