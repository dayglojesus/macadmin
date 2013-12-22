require 'mkmf'
$LDFLAGS << " -framework Ruby"
$LDFLAGS << " -framework CoreFoundation"
$LDFLAGS << " -framework Security"
create_makefile("macadmin/corefoundation")