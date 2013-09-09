require 'spec_helper'

describe MacAdmin::ComputerGroup do
  
  before :all do
    # Create a dslocal sandbox
    @test_dir = "/private/tmp/macadmin_computergroup_test.#{rand(100000)}"
    MacAdmin::DSLocalRecord::DSLOCAL_ROOT = File.expand_path @test_dir
    FileUtils.mkdir_p "#{@test_dir}/Default/computergroups"
    FileUtils.mkdir_p "#{@test_dir}/Default/computers"
    
    # Create two group record plists that we can load
    fratbots = {
      "gid"           => ["1010"],
      "realname"      => ["Fratbots"],
      "name"          => ["fratbots"],
      "generateduid"  => ["00000000-0000-0000-0000-000000000001"],
    }
    
    robot_mafia = { 
      "gid"           => ["502"],
      "realname"      => ["Robot Mafia"],
      "name"          => ["robot_mafia"],
      "generateduid"  => ["00000000-0000-0000-0000-000000000002"],
    }
    
    [fratbots, robot_mafia].each do |computergroup|
      record = CFPropertyList::List.new
      record.value = CFPropertyList.guess(computergroup)
      record.save("#{@test_dir}/Default/computergroups/#{computergroup['name'].first}.plist", CFPropertyList::List::FORMAT_BINARY)
    end
  end
  
  describe '#new' do
    
    context 'throws an ArgumentError when given fewer than 1 params' do
      subject { ComputerGroup.new }
      it { expect { subject }.to raise_error(ArgumentError) }
    end
    
    context 'when created from a parameter Hash' do
      subject { ComputerGroup.new :name => 'league-of-robots', :gid => "666" }
      it { should be_an_instance_of ComputerGroup }
      it 'should have a valid generateduid attribute' do 
        (UUID.valid?(subject.generateduid.first)).should be_true 
      end
      its (:gid)          { should eq ['666'] }
      its (:name)         { should eq ['league-of-robots'] }
      its (:realname)     { should eq ['league-of-robots'.capitalize] }
      its (:users)        { should eq [] }
      its (:groupmembers) { should eq [] }
    end
    
    context 'when created from a just a name (String)' do
      subject { ComputerGroup.new 'league-of-robots' }
      it { should be_an_instance_of ComputerGroup }
      it 'should have a valid generateduid attribute' do 
        (UUID.valid?(subject.generateduid.first)).should be_true 
      end
      its (:gid)          { should eq ['503'] } # 503 should be the next available GID
      its (:name)         { should eq ['league-of-robots'] }
      its (:realname)     { should eq ['league-of-robots'.capitalize] }
      its (:users)        { should eq [] }
      its (:groupmembers) { should eq [] }
    end
    
  end
  
  describe '#exists?' do
    
    context "when the object is different from its associated file" do
      subject { ComputerGroup.new :name => 'fratbots', :gid => "1111" }
      it 'should return false' do
        subject.exists?.should be_false
      end
    end
    
    context "when ALL the object's attributes match its associated file" do
      subject { ComputerGroup.new :name => 'fratbots', :gid => "1010" }
      it 'should return true' do
        subject.exists?.should be_true
      end
    end
    
    context "when the object does not have an associated file on disk" do
      subject { ComputerGroup.new :name => 'league-of-robots' }
      it 'should return false' do
        subject.exists?.should be_false
      end
    end
    
  end
  
  describe '#create' do
    
    context "with NO path parameter (default)" do
      subject { ComputerGroup.new :name => 'league-of-robots', :gid => "666" }
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
      subject { ComputerGroup.new :name => 'league-of-robots', :gid => "666" }
      it 'saves the record to disk on the path specified' do
        subject.create(path).should be_true
      end
      after do
        FileUtils.rm_rf path
      end
    end
    
  end
  
  describe '#destroy' do
    subject { ComputerGroup.new :name => 'league-of-robots', :gid => "666" }
    it 'removes the record on disk and returns true' do
      subject.create
      subject.destroy.should be_true
      File.exists?(subject.file).should be_false
    end
  end
  
  describe '#users=' do
    subject { ComputerGroup.new 'fratbots' }
    before { subject.users = ['fratbots', 'robot_mafia'] }
    it 'replaces the membership array for users' do 
      subject['users'].should eq ['fratbots', 'robot_mafia'] 
    end
  end
  
  describe '#users' do
    subject { ComputerGroup.new 'fratbots' }
    before { subject.users = ['fratbots', 'robot_mafia'] }
    it 'returns a membership array of users' do 
      subject.users.should eq ['fratbots', 'robot_mafia'] 
    end
  end
  
  describe '#has_user?' do
    subject { ComputerGroup.new 'league-of-robots' }
    
    context 'when membership array is non-existent' do
      it 'should be false' do
        subject.has_user?('bender').should be_false
      end
    end
    
    context 'when membership array is populated' do
      before { subject.users = ['bender', 'crushinator'] }
      it 'should be true if the user is a member of the group' do
        subject.has_user?('crushinator').should be_true
      end
      
      it 'should be false if the user is NOT a member of the group' do
        subject.has_user?('flexo').should be_false
      end
    end
    
  end
  
  describe '#add_user' do
    subject { ComputerGroup.new 'league-of-robots' }
    
    context 'when the member does NOT exist' do
      it 'should raise an error' do
        expect { subject.add_user('flexo') }.to raise_error(StandardError)
      end
    end
    
    context 'when the member exists' do
      it "should add the user to the users array" do
        crushinator = Computer.new 'crushinator'
        crushinator.create
        subject.add_user('crushinator').should be_nil
        subject['users'].should eql ["crushinator"]
        crushinator.destroy
      end
    end
    
  end
  
  describe '#rm_user' do
    subject { ComputerGroup.new 'fratbots' }
    
    context 'when user does NOT exist' do
      it 'should return nil' do 
        subject.users = ['fry', 'bender']
        subject.rm_user('leela').should be_nil
      end
    end
    
    context 'when user does exist' do
      it 'should remove the user from the membership array' do
        subject.users = ['fry', 'bender']
        subject.rm_user('fry').should eq 'fry'
        subject.users.should eq ['bender']
      end
    end
    
  end
  
  describe '#has_groupmember?' do
    subject { ComputerGroup.new 'league-of-robots' }
    
    context 'when membership array is non-existent' do
      it 'should be false' do
        subject.has_groupmember?('fratbots').should be_false
      end
    end
    
    context 'when membership array is populated' do
      it 'should be true if the user is a member of the group' do
        subject.groupmembers = ['00000000-0000-0000-0000-000000000001']
        subject.has_groupmember?('fratbots').should be_true
      end
      
      it 'should be false if the user is NOT a member of the group' do
        subject.has_groupmember?('killbots').should be_false
      end
    end
    
  end
  
  describe '#add_groupmember' do
    subject { ComputerGroup.new 'league-of-robots' }
    
    context 'when the member does NOT exist' do
      it 'should raise an error' do
        expect { subject.add_groupmember('killbots') }.to raise_error(StandardError)
      end
    end
    
    context 'when the member exists' do
      it "should add named group's GeneratedUID to the groupmembers array" do
        subject.add_groupmember('fratbots').should be_nil
        subject['groupmembers'].should eql ["00000000-0000-0000-0000-000000000001"]
      end
    end
    
  end
  
  describe '#rm_groupmember' do
    subject { ComputerGroup.new 'league-of-robots' }
    
    context 'when the member does NOT exist' do
      it 'should return nil' do
        subject.rm_groupmember('killbots').should be_nil
      end
    end
    
    context 'when the member exists' do
      it 'should remove the member from the array' do
        ['fratbots', 'robot_mafia'].each do |member|
          subject.add_groupmember member
        end
        subject.rm_groupmember('fratbots').should eq "00000000-0000-0000-0000-000000000001"
        subject.groupmembers.should eq ["00000000-0000-0000-0000-000000000002"]
      end
    end
    
  end
  
  after :all do
    FileUtils.rm_rf @test_dir
  end
  
end
