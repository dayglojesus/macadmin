/*
 *  authorization.c
 *  MacAdmin::Authorization
 *  - Ruby C extension for managing Authorization related operations
 *  - https://developer.apple.com/library/mac/documentation/security/Reference/authorization_ref
 *  
 *  Created by Brian Warsing on 2013-12-22.
 *  Copyright (c) 2013 Brian Warsing. All rights reserved.
 */

#include "authorization.h"

// Retrieve the rightsDefinition
VALUE get_authorization_right(VALUE self, VALUE name) {
    
    VALUE definition;
    OSStatus status;
    CFDictionaryRef def;
    
    name = StringValue(name);
    
    status = AuthorizationRightGet(StringValueCStr(name), &def);
    
    if (status != noErr) {
        definition = rb_hash_new();
    } else {
        definition = convertDictionaryRef(def);
        CFRelease(def);
    }
    
    return definition;
}

// Set the rightsDefinition
VALUE set_authorization_right(VALUE self, VALUE name, VALUE definition) {
    
    OSStatus status;
    AuthorizationRef auth;
    CFDictionaryRef def;
    const char *definition_klass;
    char *c_name;
    
    c_name = StringValueCStr(name);
    
    status = AuthorizationCreate(NULL,
                                 kAuthorizationEmptyEnvironment,
                                 kAuthorizationFlagDefaults,
                                 &auth);
    
    if (status != noErr)
        rb_raise(cAuthorizationError, "could not create AuthorizationRef [%d]", (int)status);
    
    switch (TYPE(definition)) {
      case T_HASH:
          def = convertHash(definition);
          break;
      case T_STRING:
          def = convertString(definition);
          break;
      default:
          definition_klass = rb_obj_classname(definition);
          def = NULL;
          break;
    }
    
    if (def) {
        status = AuthorizationRightSet(auth, c_name, def, NULL, NULL, NULL);
        CFRelease(def);
    }
    
    AuthorizationFree(auth, kAuthorizationFlagDefaults);
    
    if (!def)
        rb_raise(rb_eTypeError, "expected String or Hash, not %s", definition_klass);
    
    return INT2FIX((int)status);
}

// Remove the rightsDefinition
VALUE rm_authorization_right(VALUE self, VALUE name) {
    
    OSStatus status;
    AuthorizationRef auth;
    const char *c_name;
    
    c_name = StringValueCStr(name);
    
    status = AuthorizationCreate(NULL,
                                 kAuthorizationEmptyEnvironment,
                                 kAuthorizationFlagDefaults,
                                 &auth);
    
    if (status != noErr)
        rb_raise(cAuthorizationError, "could not create AuthorizationRef [%d]", (int)status);
    
    status = AuthorizationRightRemove(auth, c_name);
    
    AuthorizationFree(auth, kAuthorizationFlagDefaults);
    
    return INT2FIX((int)status);
}

// Ruby Init
void Init_authorization() {
    cAuthorization      = rb_define_module_under(cMacAdmin, "Authorization");
    cAuthorizationError = rb_define_class_under(cAuthorization, "AuthorizationError", rb_eStandardError);
    rb_define_singleton_method(cAuthorization, "get_authorization_right", get_authorization_right, 1);
    rb_define_singleton_method(cAuthorization, "set_authorization_right", set_authorization_right, 2);
    rb_define_singleton_method(cAuthorization, "rm_authorization_right",  rm_authorization_right,  1);
}
