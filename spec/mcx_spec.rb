require 'spec_helper'
require 'fileutils'

describe MacAdmin::MCX do
  
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
    
    @policy_as_file = "#{@test_dir}/policy.plist"
    @raw_xml_content = <<-RAW_XML_CONTENT
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
<key>com.apple.SoftwareUpdate</key>
<dict>
	<key>CatalogURL</key>
	<dict>
		<key>state</key>
		<string>always</string>
		<key>value</key>
		<string>http://foo.bar.com/reposado/html/content/catalogs/index.sucatalog</string>
	</dict>
</dict>
<key>com.apple.screensaver</key>
<dict>
	<key>askForPassword</key>
	<dict>
		<key>state</key>
		<string>once</string>
		<key>value</key>
		<integer>1</integer>
	</dict>
</dict>
</dict>
</plist>
    RAW_XML_CONTENT
    
    File.open(@policy_as_file, 'w') { |f| f.write(@raw_xml_content) }
    
  end
  
  describe "#mcx_import" do
    
    context "when the content is XML (String)" do
      subject { Computer.new :name => 'planet-express' }
      it { subject.send(:mcx_import, @raw_xml_content).should be_an_instance_of Array }
    end
    
    context "when the content is a file path (String)" do
      subject { Computer.new :name => 'planet-express' }
      it { subject.send(:mcx_import, @policy_as_file).should be_an_instance_of Array }
    end
    
  end
  
  describe "#mcx_export" do
    subject { Computer.new :name => 'planet-express' }
    it "should return a valid String" do
      subject.mcx_import @raw_xml_content
      subject.mcx_export.should be_an_instance_of String
    end
  end
  
  describe '#has_mcx?' do
    
    context "when the record has a valid mcx_settings attribute" do
      subject { Computer.new :name => 'planet-express' }
      it do
        subject.send(:mcx_import, @raw_xml_content)
        subject.send(:has_mcx?).should be_true
      end
    end

    context "when the record has an empty mcx_settings attribute" do
      subject { Computer.new :name => 'planet-express' }
      it do
        subject['mcx_settings'] = []
        subject.send(:has_mcx?).should be_false
      end
    end
    
    context "when the record has a bad mcx_settings attribute" do
      subject { Computer.new :name => 'planet-express' }
      it do
        subject['mcx_settings'] = ''
        subject.send(:has_mcx?).should be_false
      end
    end

    context "when the record has NO mcx_settings attribute" do
      subject { Computer.new :name => 'planet-express' }
      it do
        subject.send(:has_mcx?).should be_false
      end
    end
    
  end
  
  describe "#mcx_delete" do
    
    context "when the object has NO MCX attached" do
      subject { Computer.new :name => 'planet-express' }
      it do
        subject.mcx_delete.should be_nil 
        subject['mcx_settings'].should be_nil
        subject['mcx_flags'].should be_nil
      end
    end
    
    context "when the object has MCX attached" do
      subject { Computer.new :name => 'planet-express' }
      before { subject.send(:mcx_import, @raw_xml_content) }
      it do
        subject.mcx_delete.should be_true
        subject['mcx_settings'].should be_nil
        subject['mcx_flags'].should be_nil
      end
    end
    
  end
  
  after :all do
    FileUtils.rm_rf @test_dir
  end
  
end