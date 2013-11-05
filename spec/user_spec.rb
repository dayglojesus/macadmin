require 'spec_helper'
require 'fileutils'

describe MacAdmin::User do
  
  before :all do
    @sha1_string   = 'AA9E81CD14C2BE42D6D85E6ED3B1A8C6176FAEF3EF4E91B7'
    @sha512_string = 'a6055f17b5ddd603d284264c7363b7b211df819bc211f7e0047668e4f35ec558a3b5dee1a5cc3a287b9c3b252813782336d07f1bd0579eeaceb00f9bc99c42e349bc1f64'
    
    # Create a dslocal sandbox
    @test_dir = "/private/tmp/macadmin_user_test.#{rand(100000)}"
    MacAdmin::DSLocalRecord.send(:remove_const, :DSLOCAL_ROOT)
    MacAdmin::SaltedSHA1.send(:remove_const, :SHADOWHASH_STORE)
    MacAdmin::SaltedSHA1::SHADOWHASH_STORE = File.expand_path @test_dir
    MacAdmin::DSLocalRecord::DSLOCAL_ROOT  = File.expand_path @test_dir
    FileUtils.mkdir_p "#{@test_dir}/Default/groups"
    FileUtils.mkdir_p "#{@test_dir}/Default/users"
    
    # # Create a user record plist that we can load
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
  
  describe '#new' do
    name = 'bender'
    subject { User.new name }
    it { should be_an_instance_of User }
    it 'should have a valid GeneratedUID attribute' do
      value = subject[:generateduid].first
      UUID.valid?(value).should be_true
    end
    it 'should have a UID greater or equal to MacAdmin::User::MIN_UID' do
      value = subject[:uid].first
      value.to_i.should >= MacAdmin::User::MIN_UID
    end
    its (:gid)  { should eq ['20'] }
    its (:name) { should eq [name] }
    its (:home) { should eq ["/Users/#{name}"] }
    its (:shell)  { should eq ["/bin/bash"] }
    its (:realname) { should eq [name] }
  end
  
  describe '#password' do
    subject { User.new 'fry' }
    
    context "when the User's password is NOT set" do
      it { subject.password.should be_nil }
    end
    
    context "when the User's password _is_ set" do
      before do
        subject.password = SaltedSHA512.new @sha512_string
      end
      it { subject.instance_variable_get(:@password).should be_a_kind_of ShadowHash }
    end
    
  end
  
  describe '#password=' do
    user = User.new 'fry'
    modified = nil
    subject { user.password = object }
    
    context 'given a nil object' do
      let(:object) do
        nil
      end
      it { subject.should be nil }
    end
    
    context "given a Password object" do
      let(:object) do
        modified = SaltedSHA512.new @sha512_string.reverse
      end
      it { subject.password.should eq modified.password }
    end
    
    context "given a String object" do
      let(:object) do
        String.new
      end
      it { expect { subject.password=('') }.to raise_error(ArgumentError) }
    end
    
  end
  
  describe '#legacy?' do
    subject { User.new :name => 'fry', :password => password }
    
    context 'when the User record has a SHA1 password' do
      let(:password) do
        SaltedSHA1.new @sha1_string
      end
      it { subject.legacy?.should be_true }
    end
    
    context 'when the User record has a SaltedSHA512 password' do
      let(:password) do
        SaltedSHA512.new @sha512_string
      end
      it { subject.legacy?.should be_false }
    end
    
  end
  
  describe '#exists?' do
    
    context 'when the user has a Legacy password' do
      
      guid = "00000000-0000-0000-0000-000000000001"
      subject { User.new :name => 'fry', :generateduid => guid, :password => password }
      
      context 'and the password file exists' do
        let(:password) do
          SaltedSHA1.new @sha1_string
        end
        let(:password_file) do
          "#{@test_dir}/#{guid}"
        end
        before do
          File.open(password_file, mode='w') { |f| f.write "0" * 168 + @sha1_string + "0" * 1024 }
        end
        it { subject.exists?.should be_true }
        after do
          FileUtils.rm password_file
        end
      end
      
      context 'and the password file does NOT exist' do
        let(:password) do
          SaltedSHA1.new @sha1_string
        end
        it { subject.exists?.should be_false }
      end
      
    end
    
    context 'when the user has a SHA512 password' do
      
      subject { User.new :name => 'fry', :password => SaltedSHA512.new(@sha512_string) }
      before  { subject.create }
      
      context 'the password matches the value in the corresponding user plist' do
        it { subject.exists?.should be_true }
      end
      
      context 'the password does NOT match the value in the corresponding user plist' do
        before { subject.password = SaltedSHA512.new(@sha512_string.reverse) }
        it { subject.exists?.should be_false }
      end
      
      after  { subject.destroy }
    end
    
  end
  
  describe '#create' do
    
    guid = "00000000-0000-0000-0000-000000000001"
    subject { User.new :name => 'fry', :generateduid => guid, :password => password }
    
    context 'when the User record has a SHA1 password' do
      let(:password) do
        SaltedSHA1.new @sha1_string
      end
      let(:password_file) do
        "#{@test_dir}/#{guid}"
      end
      let(:user_file) do
        subject.file
      end
      it do
        subject.create.should be_true 
        File.exist?(user_file).should be_true
        File.exist?(password_file).should be_true
      end
      after { FileUtils.rm password_file }
    end
    
    context 'when the User record has a SHA512 password' do
      subject { User.new :name => 'bender', :password => password }
      let(:password) do
        SaltedSHA512.new @sha512_string
      end
      let(:user_file) do
        subject.file
      end
      it do
        subject.create.should be_true 
        File.exist?(user_file).should be_true
      end
      after { FileUtils.rm user_file }
    end
    
  end
  
  describe '#destroy' do
    
    context 'when the User record has a SHA1 password' do
      guid = "00000000-0000-0000-0000-000000000001"
      subject { User.new :name => 'leela', :generateduid => '331D5FCC-DBE1-4193-9DBF-BC955E997B3E', :password => password }  
      let(:password) do
        SaltedSHA1.new @sha1_string
      end
      let(:password_file) do
        "#{@test_dir}/#{guid}"
      end
      let(:user_file) do
        subject.file
      end
      before { subject.create }
      it do 
        subject.destroy.should be_true
        File.exist?(user_file).should be_false
        File.exist?(password_file).should be_false
      end
    end
    
    context 'when the User record has a SHA512 password' do
      subject { User.new :name => 'zoidberg', :password => password }  
      let(:password) do
        SaltedSHA512.new @sha512_string
      end
      let(:user_file) do
        subject.file
      end
      before { subject.create }
      it do 
        subject.destroy.should be_true
        File.exist?(user_file).should be_false
      end
    end
    
  end
  
  after :all do
    FileUtils.rm_rf @test_dir
  end
  
end
