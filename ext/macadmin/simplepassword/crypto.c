//
//  crypto.c
//  MacAdmin::SimplePassword::Crypto
//  - Ruby C extension built for fast PBKDF2 calculation
//
//  Created by Brian Warsing on 2013-10-07.
//  Copyright (c) 2013 Simon Fraser University. All rights reserved.
//

#include <stdio.h>
#include <stdint.h>
#include <CommonCrypto/CommonCrypto.h>
#include "ruby.h"

VALUE MacAdmin       = Qnil;
VALUE SimplePassword = Qnil;

// Prototypes
void Init_crypto();
static VALUE salted_sha512_pbkdf2_from_string(VALUE self, VALUE input);
void to_hex( uint8_t *dest, const uint8_t *text, size_t text_size );

// Convert an ASCII char array to hexidecimal representation
void to_hex( uint8_t *dest, const uint8_t *text, size_t text_size )
{
    int i;
    for(i = 0; i < text_size; i++)
        sprintf((char*)dest+i*2, "%02x", text[i]);
}

// Ruby Init
void Init_crypto() {
    MacAdmin       = rb_define_module("MacAdmin");
    SimplePassword = rb_define_module_under(MacAdmin, "SimplePassword");
    rb_define_singleton_method(SimplePassword, "salted_sha512_pbkdf2_from_string", salted_sha512_pbkdf2_from_string, 1);
}

// salted_sha512_pbkdf2_from_string
// - single param: Ruby String
// - returns Ruby Hash with 3 keys
// http://blog.securemacprogramming.com/2012/07/password-checking-with-commoncrypto/
static VALUE salted_sha512_pbkdf2_from_string(VALUE self, VALUE input) {
    
    VALUE str = StringValue(input);
    char *password = RSTRING_PTR(str);   // may be null
    size_t password_size = RSTRING_LEN(str);
    int salt_len = 32;
    
    // Calc how many iterations
    const u_int32_t interval = arc4random_uniform(100) + 100;
    int iterations = CCCalibratePBKDF(kCCPBKDF2,
                                      password_size,
                                      salt_len,
                                      kCCPRFHmacAlgSHA512,
                                      kCCKeySizeMaxRC2,
                                      interval);

    // Generate a salt
    int i;
    uint8_t salt[salt_len];
    for (i = 0; i < salt_len; i++)
        salt[i] = (unsigned char)arc4random();
    
    // Generate HMAC
    uint8_t key[kCCKeySizeMaxRC2] = {0};
    int result = CCKeyDerivationPBKDF(kCCPBKDF2,
                                      password,
                                      password_size,
                                      salt,
                                      salt_len,
                                      kCCPRFHmacAlgSHA512,
                                      iterations,
                                      key,
                                      kCCKeySizeMaxRC2);
    
    uint8_t *entropy[kCCKeySizeMaxRC2];
    to_hex(entropy, key, kCCKeySizeMaxRC2);
    
    uint8_t *salt_hex[salt_len];
    to_hex(salt_hex, salt, salt_len);
    
    VALUE dict;
    dict = rb_hash_new();    
    rb_hash_aset(dict, ID2SYM(rb_intern(("entropy"))),    rb_str_new2((char *)entropy));
    rb_hash_aset(dict, ID2SYM(rb_intern(("salt"))),       rb_str_new2((char *)salt_hex));
    rb_hash_aset(dict, ID2SYM(rb_intern(("iterations"))), INT2NUM(iterations));
    
    return dict;
}
