/*
 *  corefoundation.h
 *  MacAdmin
 *  - Ruby C extension housing a collection of CoreFoundation wrappers and converion functions
 *  
 *  Created by Brian Warsing on 2013-12-22.
 *  Copyright (c) 2013 Brian Warsing. All rights reserved.
 */

#include "corefoundation.h"

VALUE cMacAdmin;

// Ruby Init
void Init_corefoundation() {
    cMacAdmin = rb_define_module("MacAdmin");
    Init_authorization();
}