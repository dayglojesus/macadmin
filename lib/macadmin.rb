# macadmin, version 0.0.1
# Sat Aug 11 16:14:56 PDT 2012
require 'rubygems'
require 'cgi'
require 'time'
require 'stringio'
require 'delegate'
require 'fileutils'
require 'cfpropertylist'
require 'macadmin/version'
require 'macadmin/common'
require 'macadmin/mcx'
require 'macadmin/password'
require 'macadmin/dslocal'
require 'macadmin/dslocal/user'
require 'macadmin/dslocal/group'
require 'macadmin/dslocal/computer'
require 'macadmin/dslocal/computergroup'
require 'macadmin/dslocal/dslocalnode'

include MacAdmin
include MacAdmin::Common

# Monkey patch a bug in CFPropertyList
# https://github.com/ckruse/CFPropertyList/issues/22
class Hash
  # convert a hash to plist format
  def to_plist(options={})
    options[:plist_format] ||= CFPropertyList::List::FORMAT_BINARY
    plist = CFPropertyList::List.new
    plist.value = CFPropertyList.guess(self, options)
    plist.to_str(options[:plist_format], options)
  end
end
