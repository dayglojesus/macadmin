/*
 *  corefoundation.h
 *  MacAdmin
 *  - Ruby C extension housing a collection of CoreFoundation wrappers and converion functions
 *  
 *  Created by Brian Warsing on 2013-12-22.
 *  Copyright (c) 2013 Brian Warsing. All rights reserved.
 */

#ifndef RUBY_CF
#define RUBY_CF

#include <CoreFoundation/CoreFoundation.h>
#include <Ruby/ruby.h>
#include "cfconv.h"
#include "authorization.h"

extern VALUE cMacAdmin;

// Prototypes
void Init_corefoundation();

#endif