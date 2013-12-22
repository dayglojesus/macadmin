/*
 *  crypto.h
 *  MacAdmin::Password
 *  - Ruby C extension built for fast PBKDF2 calculation
 *
 *  Created by Brian Warsing on 2013-10-07.
 *  Copyright (c) 2013 Brian Warsing. All rights reserved.
 */

#include <stdio.h>
#include <stdint.h>
#include <CommonCrypto/CommonCrypto.h>
#include <Ruby/ruby.h>

VALUE MacAdmin;
VALUE Password;

// Prototypes
void Init_crypto();
void to_hex( uint8_t *dest, const uint8_t *text, size_t text_size );
static VALUE salted_sha512_pbkdf2_from_string(VALUE self, VALUE input);
