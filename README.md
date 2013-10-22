# MacAdmin

Gem to assist in performing common systems administration tasks in OSX

## Version: 0.0.2

## About

MacAdmin endeavors to provide an OO programming interface for constituent OSX system resources. It's comprised of classes with the ability to parse Apple Property Lists (CFPropertyList) and manipulate them as native Ruby objects. The classes work directly with the Property Lists used to abstract OSX system resources -- users, groups, computers, computergroups, etc. -- bypassing the common utilities and APIs normally reserved for this kind of work.

This approach has trade-offs, but it does result in a very powerful and simple model for managing these resources (See Notes).

#### Notes:

Before forking/cloning/using/testing/etc MacAdmin, please read the license (LICENSE.txt).

One important trade-off worth mentioning when using this gem is that you must have root priviledge in order to access (read) any resources in the DSLocal domains or similarily protected directories and files. This is different from using utils like `dscl`, but not unlike using `defaults`. Naturally, as with any of these methods, you must also be root in order to make any changes. The code examples below will require root access when performing create operations.

Another important condition to mention is that it will often be necessary to restart OSX's directory service in order to see the changes you've made to any of the affected plists. This can be bothersome and susceptible to race conditions, but in general, it's a manageable issue.

## Requirements

- Mac OS X 10.5 and up
- Xcode Command Line Tools
- RubyGems: there are a few gem dependencies but they should be handled by bundler

## Installation

### Source:

Install the bundler gem:

    $ sudo gem install bundler

Clone this repo:

    $ cd ~/Downloads
    $ git clone http://github.com/dayglojesus/macadmin.git

Install the gem dependencies:

    $ sudo bundle install

Run the tests:

    $ cd macadmin
    $ rake test

Install the gem:

    $ sudo rake install

Test the installation:

##### Note the path parameter to #create -- use this for testing resource creation in arbitrary directories. Also works for #destroy.

    $ cd ~/Downloads
    $ irb -r 'macadmin'
    >> foobar = User.new 'foobar'
    => {"passwd"=>["********"], "gid"=>["20"], "uid"=>["501"], "shell"=>["/bin/bash"], "name"=>["foobar"], "realname"=>["foobar"], "generateduid"=>["4871DD7C-5C55-47DB-8A7B-B38CBD6DA5A9"], "comment"=>[""], "home"=>["/Users/foobar"]}
    >> foobar.exists?
    => false
    >> foobar.create "./foobar.plist"
    >> foobar.destroy "./foobar.plist"
    >> exit

### RubyGems:

Not Available

## Usage

Load the gems:

    require 'rubygems'
    require 'macadmin'

Create a new node:

    # Here's something cool: 
    # DSLocalNode will automatically add this custom node to OpenDirectory sandbox when running on 10.8 and up
    my_custom_node = DSLocalNode.new 'MCX'
    my_custom_node.create_and_activate

Create a computer record on that node:

    computer = Computer.new :name => `hostname -s`.chomp, :node => 'MCX'
    computer.create

Create a computer group, add the computer record as a member, and apply some policy (on that node):

    # Here's a bnuch of policy written as XML, but the mcximport method can also take a file path parameter and load it that way
    raw_xml_policy = <<-RAW_XML_CONTENT
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
    
    computer_group = ComputerGroup.new :name => 'mcx', :realname => 'MCX', :node => 'MCX'
    computer_group.add_user `hostname -s`.chomp
    computer_group.mcximport raw_xml_policy
    computer_group.create

Create an administrator for your new node:

    # Generate a platform appropriate password from a plaintext string
    password = SimplePassword.apropos "secret_passphrase"
    administrator = User.new :name => 'mcxadmin', :password => password, :gid => 80, :node => 'MCX'
    administrator.create

Restart the directory services to seal the deal:

    restart_directoryservice

Explore a bit...

    require 'pp'
    
    # Show the User object
    admin = User.new :name => 'mcxadmin', :node => 'MCX'
    pp admin.record if admin.exists?
    
    # Show the MCX policy attached to the ComputerGroup object
    comp_grp = ComputerGroup.new :name => 'mcx', :node => 'MCX'
    puts "Does this local computer group have MCX policy?"
    puts comp_grp.has_mcx? ? "Sweet!" : "Bummer..."
    puts comp_grp.mcxexport

Tear it down...

    # This will take down the entire node we just created and populated: user, computers, computer groups, etc.
    mcx_node = DSLocalNode.new 'MCX'
    mcx_node.destroy_and_deactivate
    
    restart_directoryservice

## Acknowledgments

This gem would not be possible without [ckuse's CFPropertyList](https://github.com/ckruse/CFPropertyList). Thanks, Christian.
