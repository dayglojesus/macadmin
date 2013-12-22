/*
 *  authorization.h
 *  MacAdmin::Authorization
 *  - Ruby C extension for managing Authorization related operations
 *  - https://developer.apple.com/library/mac/documentation/security/Reference/authorization_ref
 *  
 *  Created by Brian Warsing on 2013-12-22.
 *  Copyright (c) 2013 Brian Warsing. All rights reserved.
 */

#include <Security/AuthorizationDB.h>
#include "corefoundation.h"

static VALUE cAuthorization;
static VALUE cAuthorizationError;

// Prototypes
void  Init_authorization();
VALUE get_authorization_right(VALUE self, VALUE name);
VALUE set_authorization_right(VALUE self, VALUE name, VALUE definition);
VALUE rm_authorization_right(VALUE self, VALUE name);