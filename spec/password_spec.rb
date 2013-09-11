require 'spec_helper'
require 'fileutils'

# Override the constant
MacAdmin::SaltedSHA1.send(:remove_const, :SHADOWHASH_STORE)
MacAdmin::SaltedSHA1::SHADOWHASH_STORE = '/private/tmp'

describe MacAdmin::Password do
  
  before :all do
    @lion_user = <<-USER
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>ShadowHashData</key>
	<array>
		<data>
		YnBsaXN0MDDRAQJdU0FMVEVELVNIQTUxMk8QRKYGXxe13dYD0oQmTHNjt7IR
		34GbwhH34AR2aOTzXsVYo7Xe4aXMOih7nDslKBN4IzbQfxvQV57qzrAPm8mc
		QuNJvB9kCAsZAAAAAAAAAQEAAAAAAAAAAwAAAAAAAAAAAAAAAAAAAGA=
		</data>
	</array>
</dict>
</plist>
USER

    @mtnlion_user = <<-USER
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>ShadowHashData</key>
	<array>
		<data>
		YnBsaXN0MDDRAQJfEBRTQUxURUQtU0hBNTEyLVBCS0RGMtMDBAUGBwhXZW50
		cm9weVRzYWx0Wml0ZXJhdGlvbnNPEIConLEEdxPt9cDsU3xFk6FmdnPj/0F9
		l5KbKL9sn6iz7N/CiltPryTpMJl6I7v0SpO0WkjTzyswmS/ZSfs6lQC8Ecqw
		x5H2N/7C0o6w11PodU1APCIrDoeUJOqO5Zfd3FS/1v6bkhAk3cNYugQvIIsG
		hXHfsg/h5FKpwfK1eUB3Mk8QIGGMkcvRWusdYs5gUqmj0Aw6AO3B8anWCHH+
		b00A2+xrEV0BCAsiKTE2QcTnAAAAAAAAAQEAAAAAAAAACQAAAAAAAAAAAAAA
		AAAAAOo=
		</data>
	</array>
</dict>
</plist>
USER
  end
  
  describe '#create_from_user_record' do
    subject { Password.create_from_user_record record }
    
    context "given a Legacy user record" do
      before do
        @string = 'AA9E81CD14C2BE42D6D85E6ED3B1A8C6176FAEF3EF4E91B7'
        # override the constant
        
        # create a password file to read
        @guid = "37C25EE9-C151-4015-9D2B-0402D1CFF50B"
        @shadowhash_file = "#{MacAdmin::SaltedSHA1::SHADOWHASH_STORE}/#{@guid}"        
        File.open(@shadowhash_file, mode='w') do |f|
          f.write "0" * 168 + @string + "0" * 1024
        end
      end
      
      let(:record) do
        @test_data = { 'generateduid' => @guid }
      end
      it { should be_an_instance_of SaltedSHA1 }
      it { should respond_to :password }
      it { subject.password.should be_an_instance_of String }
      
      after do
        FileUtils.rm @shadowhash_file
      end
    end
    
    context "given a Lion user record" do
      let(:record) do
        plist = CFPropertyList::List.new(:data => @lion_user)
        @test_data = CFPropertyList.native_types(plist.value)
      end
      it { should be_an_instance_of SaltedSHA512 }
      it { should respond_to :password }
      it { subject.password.should be_an_instance_of Hash }
    end
    
    context "given a Mountain Lion user record" do
      let(:record) do
        plist = CFPropertyList::List.new(:data => @mtnlion_user)
        @test_data = CFPropertyList.native_types(plist.value)
      end
      it { should be_an_instance_of SaltedSHA512PBKDF2 }
      it { should respond_to :password }
      it { subject.password.should be_an_instance_of Hash }
    end
    
  end
  
end

describe MacAdmin::SaltedSHA1 do
  
  before :all do
    @string = 'AA9E81CD14C2BE42D6D85E6ED3B1A8C6176FAEF3EF4E91B7'
    @password = SaltedSHA1.new @string
  end
  
  describe '#new' do
    it 'returns a new SaltedSHA1 object' do
      @password.should be_an_instance_of SaltedSHA1
    end
    
    it 'throws an ArgumentError when given fewer than 1 params' do
      lambda { SaltedSHA1.new }.should raise_exception ArgumentError
    end
    
    it 'only accepts a valid 24 byte hexadecimal string' do      
      short_string = 'AA9E81CD14C2BE42D6D85E6ED3B1A8C6176FAEF3EF4E91B' # 23 bytes
      lambda { SaltedSHA1.new short_string }.should raise_exception ArgumentError
    end
    
  end
  
  describe '#validate' do
    it 'returns the original hexadecimal string when successfully parsed' do
      @password.validate(@string).should eq @string
    end
  end
  
  describe '#data' do
      subject { @password.data }
      it { should be_an_instance_of String }
      it { subject.length.should eq 48 }
  end
  
  describe '#password' do
      subject { @password.password }
      it { should be_an_instance_of String }
      it { subject.length.should eq 48 }
  end
  
  describe '#write_to_shadowhash_file' do
    before do
      @guid = '6D11E403-1F9E-481B-874A-75FA45AB4AF9'
      @user = User.new :name => 'foo', :generateduid => @guid
    end
    it 'creates a new ShadowHash file' do
      @password.send(:write_to_shadowhash_file, @user).should be_true
    end
    after do
      FileUtils.rm "/private/tmp/#{@guid}"
    end
    
  end
  
  describe '#remove_shadowhash_file' do
    before do
      @guid = '72196697-FE91-40B2-9B11-B3ACF1031E79'
      @user = User.new :name => 'foo', :generateduid => @guid
      @password.send(:write_to_shadowhash_file, @user)
    end
    it 'removes the associated ShadowHash file' do
      @password.send(:remove_shadowhash_file, @user).should be_true
    end
    after do
      FileUtils.rm "/private/tmp/#{@guid}" if File.exists? "/private/tmp/#{@guid}"
    end
  end
  
  describe '#create_from_shadowhash_file' do
    before do
      @guid = "37C25EE9-C151-4015-9D2B-0402D1CFF50B"
      @shadowhash_file = "#{MacAdmin::SaltedSHA1::SHADOWHASH_STORE}/#{@guid}"
      File.open(@shadowhash_file, mode='w') do |f|
        f.write "0" * 168 + @string + "0" * 1024
      end
    end
    subject { SaltedSHA1.create_from_shadowhash_file @guid }
    # subject { SaltedSHA512PBKDF2.create_from_shadowhashdata(@test_data) }
    it { should be_an_instance_of SaltedSHA1 }
    it { should respond_to :password }
    it { subject.password.should be_an_instance_of String }
    after do
      FileUtils.rm @shadowhash_file
    end
  end
  
end

describe MacAdmin::SaltedSHA512 do
  
  before :all do
    @string = 'a6055f17b5ddd603d284264c7363b7b211df819bc211f7e0047668e4f35ec558a3b5dee1a5cc3a287b9c3b252813782336d07f1bd0579eeaceb00f9bc99c42e349bc1f64'
    @password = SaltedSHA512.new @string
  end
  
  describe '#new' do
    it 'returns a new SaltedSHA512 object' do
      @password.should be_an_instance_of SaltedSHA512
    end
    
    it 'throws an ArgumentError when given fewer than 1 params' do
      lambda { SaltedSHA512.new }.should raise_exception ArgumentError
    end
    
    it 'only accepts a valid 68 byte hexadecimal string' do      
      short_string = 'a6055f17b5ddd603d284264c7363b7b211df819bc211f7e0047668e4f35ec558a3b5dee1a5cc3a287b9c3b252813782336d07f1bd0579eeaceb00f9bc99c42e349bc1f' # 67 bytes
      lambda { SaltedSHA512.new }.should raise_exception ArgumentError
    end
    
  end
  
  describe '#validate' do
    it 'returns the original hexadecimal string when successfully parsed' do
      @password.validate(@string).should eq @string
    end
  end
  
  describe '#data' do
    it 'returns a string-encoded Binary Property List' do
      @password.data.should match /^bplist/
    end
  end
  
  describe '#password' do
    it 'returns a Hash representation of the password' do
      @password.password.should be_an_instance_of Hash
    end
  end
  
  describe '#create_from_shadowhashdata' do
    before do
      plist = CFPropertyList::List.new(:data => @password.data)
      @test_data = CFPropertyList.native_types(plist.value)
    end
    subject { SaltedSHA512.create_from_shadowhashdata(@test_data) }
    it { should be_an_instance_of SaltedSHA512 }
    it { should respond_to :password }
    it { subject.password.should be_an_instance_of Hash }
  end
  
end

describe MacAdmin::SaltedSHA512PBKDF2 do
  
  before :all do
    @entropy = '969b62dca51304cc0852dc547309643b480d656f83df441aeaed342c836ddc730bc6350a1a61dd847a1aee910c8648a4a895b07addd066a45cf1233c52c3c73adb5f77d0ba82b71d134a8e9a0c0ed5d6a0e789bfae6beb48bf48e34bfd20509e7b22763753fbd4ae302e27717cea3deede0b38fc52640e5229a7dcbc8d66d609'    
    @salt = '79e5cb312d40cc7e89b00f67f928a31c221213bd73cba0f58dc3bcd4215f6552'
    @iterations = 29069
    
    @hash_params  = { :iterations => @iterations, :entropy => @entropy, :salt => @salt }
    @array_params = [ @entropy, @salt, @iterations ]
    
    @password_with_hash  = SaltedSHA512PBKDF2.new @hash_params
    @password_with_array = SaltedSHA512PBKDF2.new @array_params
  end
  
  describe '#new' do
    it 'returns a new SaltedSHA512PBKDF2 object when given a Hash' do
      @password_with_hash.should be_an_instance_of SaltedSHA512PBKDF2
    end
    
    it 'returns a new SaltedSHA512PBKDF2 object when given a Array' do
      @password_with_array.should be_an_instance_of SaltedSHA512PBKDF2
    end
    
    it "throws an ArgumentError when given fewer than 3 params" do
      lambda { SaltedSHA512PBKDF2.new @entropy, @iterations }.should raise_exception ArgumentError
    end
    
    it 'only accepts a valid 68 byte hexadecimal string' do      
      short_string = 'a6055f17b5ddd603d284264c7363b7b211df819bc211f7e0047668e4f35ec558a3b5dee1a5cc3a287b9c3b252813782336d07f1bd0579eeaceb00f9bc99c42e349bc1f' # 67 bytes
      lambda { SaltedSHA512PBKDF2.new }.should raise_exception ArgumentError
    end
    
  end
  
  describe '#validate' do
    it 'returns a Hash representation of the original parameters' do
      @password_with_array.validate(@array_params).should eq @hash_params
    end
  end
  
  describe '#data' do
    it 'returns a string-encoded Binary Property List' do
      @password_with_array.data.should match /^bplist/
    end
  end
  
  describe '#password' do
    it 'returns a Hash representation of the password' do
      @password_with_array.password.should be_an_instance_of Hash
    end
  end
  
  describe '#create_from_shadowhashdata' do
    before do
      plist = CFPropertyList::List.new(:data => @password_with_array.data)
      @test_data = CFPropertyList.native_types(plist.value)
    end
    subject { SaltedSHA512PBKDF2.create_from_shadowhashdata(@test_data) }
    it { should be_an_instance_of SaltedSHA512PBKDF2 }
    it { should respond_to :password }
    it { subject.password.should be_an_instance_of Hash }
  end
  
end

