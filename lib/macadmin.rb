# macadmin, version 0.0.1
# Sat Aug 11 16:14:56 PDT 2012
require 'rubygems'
require 'delegate'
require 'fileutils'
require 'cfpropertylist'
require 'macadmin/version'
require 'macadmin/common'
require 'macadmin/password'
require 'macadmin/dslocal'
require 'macadmin/dslocal/user'
require 'macadmin/dslocal/group'
require 'macadmin/dslocal/computer'

include MacAdmin
include MacAdmin::Common
