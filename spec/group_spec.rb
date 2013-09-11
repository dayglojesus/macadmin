require 'spec_helper'

describe MacAdmin::Group do
  
  before :all do
    # Create a dslocal sandbox
    @test_dir = "/private/tmp/macadmin_group_test.#{rand(100000)}"
    MacAdmin::DSLocalRecord.send(:remove_const, :DSLOCAL_ROOT)
    MacAdmin::DSLocalRecord::DSLOCAL_ROOT = File.expand_path @test_dir
    FileUtils.mkdir_p "#{@test_dir}/Default/groups"
    FileUtils.mkdir_p "#{@test_dir}/Default/users"
    
    # Create two group record plists that we can load
    foo = { 
      "gid"           => ["501"],
      "realname"      => ["Foo"],
      "name"          => ["foo"],
      "generateduid"  => ["00000000-0000-0000-0000-000000000001"],
    }
    
    bar = { 
      "gid"           => ["502"],
      "realname"      => ["Bar"],
      "name"          => ["bar"],
      "generateduid"  => ["00000000-0000-0000-0000-000000000002"],
    }
    
    [foo, bar].each do |group|
      record = CFPropertyList::List.new
      record.value = CFPropertyList.guess(group)
      record.save("#{@test_dir}/Default/groups/#{group['name'].first}.plist", CFPropertyList::List::FORMAT_BINARY)
    end
  end
  
  describe '#new' do
    
    context 'throws an ArgumentError when given fewer than 1 params' do
      subject { Group.new }
      it { expect { subject }.to raise_error(ArgumentError) }
    end
    
    context 'when created from a parameter Hash' do
      subject { Group.new :name => 'baz', :gid => "666" }
      it { should be_an_instance_of Group }
      it 'should have a valid generateduid attribute' do 
        (UUID.valid?(subject.generateduid.first)).should be_true 
      end
      its (:gid)          { should eq ['666'] }
      its (:name)         { should eq ['baz'] }
      its (:realname)     { should eq ['baz'.capitalize] }
      its (:users)        { should eq [] }
      its (:groupmembers) { should eq [] }
    end
    
    context 'when created from a just a name (String)' do
      subject { Group.new 'baz' }
      it { should be_an_instance_of Group }
      it 'should have a valid generateduid attribute' do 
        (UUID.valid?(subject.generateduid.first)).should be_true 
      end
      its (:gid)          { should eq ['503'] } # 503 should be the next available GID
      its (:name)         { should eq ['baz'] }
      its (:realname)     { should eq ['baz'.capitalize] }
      its (:users)        { should eq [] }
      its (:groupmembers) { should eq [] }
    end
    
  end
  
  describe '#exists?' do
    
    context "when the object is different from its associated file" do
      subject { Group.new :name => 'foo', :gid => "503" }
      it 'should return false' do
        subject.exists?.should be_false
      end
    end
    
    context "when ALL the object's attributes match its associated file" do
      subject { Group.new :name => 'foo', :gid => "501" }
      it 'should return true' do
        subject.exists?.should be_true
      end
    end
    
    context "when the object does not have an associated file on disk" do
      subject { Group.new :name => 'baz' }
      it 'should return false' do
        subject.exists?.should be_false
      end
    end
    
  end
  
  describe '#create' do
    
    context "with NO path parameter (default)" do
      subject { Group.new :name => 'baz', :gid => "666" }
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
      subject { Group.new :name => 'baz', :gid => "666" }
      it 'saves the record to disk on the path specified' do
        subject.create(path).should be_true
      end
      after do
        FileUtils.rm_rf path
      end
    end
    
  end
  
  describe '#destroy' do
    subject { Group.new :name => 'baz', :gid => "666" }
    it 'removes the record on disk and returns true' do
      subject.create
      subject.destroy.should be_true
      File.exists?(subject.file).should be_false
    end
  end
  
  describe '#users=' do
    subject { Group.new 'foo' }
    before { subject.users = ['foo', 'bar'] }
    it 'replaces the membership array for users' do 
      subject['users'].should eq ['foo', 'bar'] 
    end
  end
  
  describe '#users' do
    subject { Group.new 'foo' }
    before { subject.users = ['foo', 'bar'] }
    it 'returns a membership array of users' do 
      subject.users.should eq ['foo', 'bar'] 
    end
  end
  
  describe '#has_user?' do
    subject { Group.new 'baz' }
    
    context 'when membership array is non-existent' do
      it 'should be false' do
        subject.has_user?('bender').should be_false
      end
    end
    
    context 'when membership array is populated' do
      before { subject.users = ['fry', 'bender'] }
      it 'should be true if the user is a member of the group' do
        subject.has_user?('fry').should be_true
      end
      
      it 'should be false if the user is NOT a member of the group' do
        subject.has_user?('leela').should be_false
      end
    end
    
  end
  
  describe '#add_user' do
    subject { Group.new 'baz' }
    
    context 'when the member does NOT exist' do
      it 'should raise an error' do
        expect { subject.add_user('invalid') }.to raise_error(StandardError)
      end
    end
    
    context 'when the member exists' do
      it "should add the user to the users array" do
        fry = User.new 'fry'
        fry.create
        subject.add_user('fry').should be_nil
        subject['users'].should eql ["fry"]
        fry.destroy
      end
    end
    
  end
  
  describe '#rm_user' do
    subject { Group.new 'foo' }
    
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
    subject { Group.new 'baz' }
    
    context 'when membership array is non-existent' do
      it 'should be false' do
        subject.has_groupmember?('foo').should be_false
      end
    end
    
    context 'when membership array is populated' do
      it 'should be true if the user is a member of the group' do
        subject.groupmembers = ['00000000-0000-0000-0000-000000000001']
        subject.has_groupmember?('foo').should be_true
      end
      
      it 'should be false if the user is NOT a member of the group' do
        subject.has_groupmember?('leela').should be_false
      end
    end
    
  end
  
  describe '#add_groupmember' do
    subject { Group.new 'baz' }
    
    context 'when the member does NOT exist' do
      it 'should raise an error' do
        expect { subject.add_groupmember('invalid') }.to raise_error(StandardError)
      end
    end
    
    context 'when the member exists' do
      it "should add named group's GeneratedUID to the groupmembers array" do
        subject.add_groupmember('foo').should be_nil
        subject['groupmembers'].should eql ["00000000-0000-0000-0000-000000000001"]
      end
    end
    
  end
  
  describe '#rm_groupmember' do
    subject { Group.new 'baz' }
    
    context 'when the member does NOT exist' do
      it 'should return nil' do
        subject.rm_groupmember('invalid').should be_nil
      end
    end
    
    context 'when the member exists' do
      it 'should remove the member from the array' do
        ['foo', 'bar'].each do |member|
          subject.add_groupmember member
        end
        subject.rm_groupmember('foo').should eq "00000000-0000-0000-0000-000000000001"
        subject.groupmembers.should eq ["00000000-0000-0000-0000-000000000002"]
      end
    end
    
  end
  
  
  after :all do
    FileUtils.rm_rf @test_dir
  end
  
end
