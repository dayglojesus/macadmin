require 'mkmf'
$LDFLAGS << " -framework Ruby"
dir_config('macadmin')
create_makefile('macadmin/password/crypto')
