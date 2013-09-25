require 'spec_helper'

describe MacAdmin::DSLocalNode do
  
  before :all do
    require 'etc'
    this_user = Etc.getpwnam(Etc.getlogin)
    this_uid = this_user.uid
    this_gid = this_user.gid
    # Create a dslocal sandbox
    @test_dir = "/private/tmp/macadmin_dslocalnode_test.#{rand(100000)}"
    @child_dirs = ['aliases', 'computer_lists', 'computergroups', 'computers', 'config', 'groups', 'networks', 'users']
    MacAdmin::DSLocalNode.send(:remove_const, :SANDBOX_FILE)
    MacAdmin::DSLocalNode.send(:remove_const, :DSLOCAL_ROOT)
    MacAdmin::DSLocalNode.send(:remove_const, :PREFERENCES)
    MacAdmin::DSLocalNode.send(:remove_const, :PREFERENCES_LEGACY)
    MacAdmin::DSLocalNode.send(:remove_const, :OWNER)
    MacAdmin::DSLocalNode.send(:remove_const, :GROUP)
    MacAdmin::DSLocalNode::DSLOCAL_ROOT       = File.expand_path @test_dir
    MacAdmin::DSLocalNode::SANDBOX_FILE       = File.expand_path "#{@test_dir}/opendirectoryd.sb"
    MacAdmin::DSLocalNode::PREFERENCES        = File.expand_path "#{@test_dir}/config.plist"
    MacAdmin::DSLocalNode::PREFERENCES_LEGACY = File.expand_path "#{@test_dir}/legacy.plist"
    MacAdmin::DSLocalNode::OWNER = this_uid
    MacAdmin::DSLocalNode::GROUP = this_gid
    @root = "#{@test_dir}/Default"
    FileUtils.mkdir_p @root
    begin
      FileUtils.mkdir_p @root unless File.exist? @root
      FileUtils.chmod(0700, @root)
      @child_dirs.each do |child|
        FileUtils.mkdir_p("#{@root}/#{child}") unless File.exist?("#{@root}/#{child}")
        FileUtils.chmod(0700, "#{@root}/#{child}")
      end
      FileUtils.chown_R this_uid, this_gid, @root
    rescue Exception => e
      p e.message
    end
    
    @config = <<-CONFIG
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>comment</key>
	<string>Default search policy</string>
	<key>enabled</key>
	<true/>
	<key>mappings</key>
	<dict/>
	<key>modules</key>
	<dict>
		<key>session</key>
		<array>
			<dict>
				<key>module</key>
				<string>search</string>
				<key>options</key>
				<dict>
					<key>dsAttrTypeStandard:CSPSearchPath</key>
					<array>
						<string>/Local/Default</string>
					</array>
					<key>dsAttrTypeStandard:LSPSearchPath</key>
					<array>
						<string>/Local/Default</string>
					</array>
					<key>dsAttrTypeStandard:NSPSearchPath</key>
					<array>
						<string>/Local/Default</string>
					</array>
					<key>dsAttrTypeStandard:SearchPolicy</key>
					<string>dsAttrTypeStandard:NSPSearchPath</string>
					<key>notify_of_changes</key>
					<true/>
					<key>requiredNodes</key>
					<array>
						<string>/Local/Default</string>
					</array>
				</dict>
				<key>uuid</key>
				<string>A840FC81-A6CD-4665-899E-F8B52B1C6EC4</string>
			</dict>
		</array>
	</dict>
	<key>node name</key>
	<string>/Search</string>
</dict>
</plist>
    CONFIG
    
    @legacy = <<-CONFIG
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>DHCP LDAP</key>
	<dict>
		<key>/Sets/2A7FEC83-9B78-4BD1-A4E3-29F685EFD97A</key>
		<false/>
	</dict>
	<key>Search Node PlugIn Version</key>
	<string>Search Node PlugIn Version 1.7</string>
	<key>Search Policy</key>
	<integer>1</integer>
</dict>
</plist>
    CONFIG
    
    @sandbox = <<-SANDBOX
    ;; Copyright (c) 2011 Apple Inc.  All Rights reserved.
    ;;
    ;; WARNING: The sandbox rules in this file currently constitute
    ;; Apple System Private Interface and are subject to change at any time and
    ;; without notice.
    ;;

    (version 1)

    (allow default)

    ;; deny lookup to coreservicesd to avoid deadlocks
    (deny mach-lookup
        (global-name "com.apple.CoreServices.coreservicesd")
        (with no-log)
        (with no-callout)
    )

    ;; we don't allow inbound or bound ports
    (deny network-inbound (with no-callout))
    (deny network-bind (with no-callout))

    (allow network-inbound (local udp))
    (allow network-bind (local ip))

    ;; deny all file writes except those explicity allowed
    (deny file-write* (with no-callout))

    (allow process-exec (literal "/usr/bin/nsupdate"))

    ;; allow slapconfig to be launched without sandbox due to denial of file-write
    (allow process-exec (literal "/usr/sbin/slapconfig") (with no-sandbox))

    ;; 10735867
    (allow process-exec (literal "/usr/sbin/kextcache") (with no-sandbox))

    ;; restrict where we write
    (allow file-write*
        ;; key OpenDirectory files
        (mount-relative-regex 
            ;; our database and shadowhash files
            ;; we might be targeting '/' or some other volume
            #"^(/private)?/var/db/dslocal/nodes/Default(/|$)"
            #"^(/private)?/var/db/dslocal/nodes/Earth(/|$)"
            #"^(/private)?/var/db/dslocal/nodes/MCX(/|$)"
            #"^(/private)?/var/db/shadow(/|$)"
        )

        (regex 
            ;; configuration files
            ;; we ignore DirectoryService files because they are handled by dspluginhelperd
            #"^/Library/Preferences/OpenDirectory"

            ;; our log files
            #"^(/private)?/var/log/opendirectoryd.log"

            ;; configuration files
            #"^/Library/Preferences/SystemConfiguration/"
        )

        ;; our SystemCache related files
        (regex 
            #"^(/private)?/etc/memberd.conf"	;;; for unlinking
        )

        ;; update system keychain
        (regex 
            #"^/Library/Keychains/System.keychain"
            #"^/Library/Keychains/\."
            #"^(/private)?/var/db/mds/system/mds.lock$"
        )

        ;; kerberos keytab updates
        (regex 
            #"^(/private)?/etc/krb5.keytab$"
            #"^(/private)?/tmp/krb5cc_"
        )

        ;; additional required
        (literal "/dev/dtracehelper")
        (literal "/dev/null")
        (literal "/dev/random")

        ;; for NIS support
        (regex 
            #"^(/private)?/var/yp/"
            #"^(/private)?/etc/defaultdomain$"
        )
    )

    SANDBOX
    
    File.open(MacAdmin::DSLocalNode::PREFERENCES, 'w')        { |f| f.write(@config) }
    File.open(MacAdmin::DSLocalNode::PREFERENCES_LEGACY, 'w') { |f| f.write(@legacy) }
    
  end
  
  before :each do
    File.open(MacAdmin::DSLocalNode::SANDBOX_FILE, 'w') { |f| f.write(@sandbox) }
  end
  
  after :each do
    if subject.name.eql? 'Earth'
      FileUtils.rm_rf subject.root if File.exists? subject.root
      FileUtils.rm_rf MacAdmin::DSLocalNode::SANDBOX_FILE if File.exists? MacAdmin::DSLocalNode::SANDBOX_FILE
    end
  end
  
  describe '#new' do
    
    context 'when intialized without arguments it returns the Default node' do
      subject { DSLocalNode.new }
      it { should be_an_instance_of DSLocalNode }
      its (:name)   { should eq 'Default' }
      its (:label)  { should eq '/Local/Default' }
      its (:root)   { should eq "#{MacAdmin::DSLocalNode::DSLOCAL_ROOT}/Default" }
    end
    
    context 'when intialized with a name (String)' do
      subject { DSLocalNode.new 'Earth' }
      it { should be_an_instance_of DSLocalNode }
      its (:name)   { should eq 'Earth' }
      its (:label)  { should eq '/Local/Earth' }
      its (:root)   { should eq "#{MacAdmin::DSLocalNode::DSLOCAL_ROOT}/Earth" }
    end
    
  end
  
  describe '#exists?' do
    
    context 'when the defined directory structure exists' do
      subject { DSLocalNode.new }
      it { subject.exists?.should be_true }
    end
    
    context 'when the defined directory structure does NOT exist' do
      subject { DSLocalNode.new 'Earth' }
      it { subject.exists?.should be_false }
    end
    
  end
  
  describe '#active?' do
    
    context "when the node is in the Directory Service's search path" do
      subject { DSLocalNode.new }
      it { subject.active?.should be_true }
    end
    
    context "when the node is NOT in the Directory Service's search path" do
      subject { DSLocalNode.new 'Earth' }
      it { subject.active?.should be_false }
    end
    
  end
  
  describe '#create' do
    
    subject { DSLocalNode.new 'Earth' }
    it 'creates the defined directory structure' do
      subject.create.should be_true
      subject.exists?.should be_true
    end
    
  end
  
  describe '#activate' do
    
    subject { DSLocalNode.new 'Earth' }
    it "add the node to Directory Service's search path" do
      subject.activate.should be_true
      subject.active?.should be_true
    end
    
  end
  
  describe '#deactivate' do
    
    subject { DSLocalNode.new 'Earth' }
    it "removes the node from the Directory Service's search path" do
      subject.activate
      subject.deactivate.should be_true
      subject.active?.should be_false
    end
    
  end
  
  describe "#exists_and_active?" do
    
    context "when the node exists and is active" do
      subject { DSLocalNode.new }
      it { subject.exists_and_active?.should be_true }
    end
    
    context "when the node exists but is NOT active" do
      subject { DSLocalNode.new 'Earth' }
      it 'should be_false' do
        subject.create
        subject.exists_and_active?.should be_false
      end
    end
    
    context "when the node is active but does NOT exist" do
      subject { DSLocalNode.new 'Earth' }
      it 'should be_false' do
        subject.activate
        subject.exists_and_active?.should be_false
      end
    end
    
  end
  
  describe "#create_and_activate" do
    subject { DSLocalNode.new 'Earth' }
    it "should be_true" do
      subject.create_and_activate
      subject.exists_and_active?.should be_true
    end
  end
  
  describe "#destroy_and_deactivate" do
    subject { DSLocalNode.new 'Earth' }
    it "should be_false" do
      subject.create_and_activate
      subject.destroy_and_deactivate
      subject.exists_and_active?.should be_false
    end
  end
  
  after :all do
    FileUtils.rm_rf @test_dir
  end
  
end