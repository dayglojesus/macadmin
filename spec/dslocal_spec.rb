require 'spec_helper'

describe MacAdmin::DSLocalRecord do
  
  before :all do
    # Create a dslocal sandbox
    @test_dir = "/private/tmp/macadmin_dslocal_test.#{rand(100000)}"
    MacAdmin::DSLocalRecord.send(:remove_const, :DSLOCAL_ROOT)
    MacAdmin::DSLocalRecord::DSLOCAL_ROOT = File.expand_path @test_dir
    FileUtils.mkdir_p "#{@test_dir}/Default/groups"
    FileUtils.mkdir_p "#{@test_dir}/Default/users"
    
    # Create a user record plist that we can load
    fry = { 
      "uid"           => ["501"],
      "name"          => ["fry"],
      "realname"      => ["Phillip J. Fry"],
      "generateduid"  => ["00000000-0000-0000-0000-000000000001"],
    }
    
    record = CFPropertyList::List.new
    record.value = CFPropertyList.guess(fry)
    record.save("#{@test_dir}/Default/users/#{fry['name'].first}.plist", CFPropertyList::List::FORMAT_BINARY)
  end
  
  describe '#init_with_file' do
    before do
        @user = <<-RECORD
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>generateduid</key>
	<array>
		<string>331D5FCC-DBE1-4193-9DBF-BC955E997B3E</string>
	</array>
	<key>name</key>
	<array>
		<string>foo</string>
	</array>
	<key>uid</key>
	<array>
		<string>411</string>
	</array>
	<key>gid</key>
	<array>
		<string>80</string>
	</array>
  <key>home</key>
  <array>
    <string>/Users/foo</string>
  </array>
  <key>shell</key>
  <array>
    <string>/bin/bash</string>
  </array>
  <key>realname</key>
  <array>
    <string>foo</string>
  </array>
</dict>
</plist>
RECORD
    @test_dir = "/private/tmp/test.#{rand(100000)}"
    @file = "#{@test_dir}/Default/users/foo.plist"
    FileUtils.mkdir_p "#{@test_dir}/Default/users"
    File.open(@file, mode='w') { |f| f.write @user }
    end
    
    subject { User.init_with_file @file }
    it { should be_an_instance_of User }
    its (:uid)  { should eq ['411'] }
    its (:gid)  { should eq ['80'] }
    its (:name) { should eq ['foo'] }
    its (:home) { should eq ["/Users/foo"] }
    its (:shell)  { should eq ["/bin/bash"] }
    its (:realname) { should eq ['foo'] }
    its (:generateduid) { should eq ['331D5FCC-DBE1-4193-9DBF-BC955E997B3E'] }
    
    after do
      FileUtils.rm_rf @test_dir
    end
    
  end
  
  describe '#new' do
    
    context 'throws an ArgumentError when given fewer than 1 params' do
      subject { DSLocalRecord.new }
      it { expect { subject }.to raise_error(ArgumentError) }
    end
    
    context 'throws a DSLocalError when given an invalid name attribute' do
      subject { DSLocalRecord.new 'bad name' }
      it { expect { subject }.to raise_error(DSLocalError) }
    end
    
    context 'throws a DSLocalError when given an invalid name attribute' do
      subject { DSLocalRecord.new 'fry' }
      it 'takes a String argument and returns a DSLocalRecord object' do
        subject.should be_an_instance_of DSLocalRecord
      end
    end
    
    context 'throws a DSLocalError when given an invalid name attribute' do
      subject { DSLocalRecord.new :name => 'fry', :gid => 80, :uid => 666 }
      it 'takes a Hash argument and returns a DSLocalRecord object' do
        subject.should be_an_instance_of DSLocalRecord
      end
    end
    
  end
  
  describe '#exists?' do

    context "when the object is different from its associated file" do
      subject { DSLocalRecord.new :name => 'fry', :uid => 666 }
      it { subject.exists?.should be_false } 
    end
    
    context "when the object is identical to its associated file" do
      subject { DSLocalRecord.new :name => 'fry', 
                                  :uid => "501", 
                                  :generateduid => "00000000-0000-0000-0000-000000000001", 
                                  :file => @test_dir + '/Default/users/fry.plist' }
      it { subject.exists?.should be_true }
    end
        
    context "when the object does not have an associated file on disk" do
      subject { DSLocalRecord.new 'bender' }
      it { subject.exists?.should be_false }
    end
    
  end
  
  describe '#create' do
    
    context "with NO path parameter (default)" do
      subject { DSLocalRecord.new :name => 'bender', :uid => "666", :file => @test_dir + '/Default/users/bender.plist' }
      it 'saves the record to disk on the derived path' do
        subject.create.should be_true
        File.exists?(subject.file).should be_true
      end
      after do
        FileUtils.rm_rf subject.file
      end
    end
    
    context "with a path parameter" do
      mode = 33152
      path = "/private/tmp/group-create-method-test.plist"
      subject { DSLocalRecord.new :name => 'leela', :uid => "609" }
      it 'saves the record to disk on the path specified' do
        subject.create(path).should be_true
        stat = File::Stat.new path
        File.exists?(path).should be_true
        stat.mode.should eq mode
      end
      after do
        FileUtils.rm_rf path
      end
    end
    
  end
  
  describe '#destroy' do
    subject { DSLocalRecord.new :name => 'zoidberg', :file => @test_dir + '/Default/users/bender.plist' }
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
