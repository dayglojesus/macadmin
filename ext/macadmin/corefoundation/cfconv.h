/*
 *  cfconv.h
 *  - Functions for converting CoreFoundation Types to Ruby objects and vice versa
 *  
 *  Graciously and respectfully plundered from Kevin Ballard's amazing plist.c
 *  https://github.com/kballard/textmate-bundles/blob/master/Tools/plist/plist.c
 *  
 *  Created by Brian Warsing on 2013-12-22.
 *  Copyright (c) 2013 Brian Warsing. All rights reserved.
 */

#include <CoreFoundation/CoreFoundation.h>
#include <Ruby/ruby.h>

/*
 * Core Foundation Type Conversion Functions
 */
VALUE convertStringRef(CFStringRef plist);          // Converts a CFStringRef to a String
VALUE convertNumberRef(CFNumberRef plist);          // Converts a CFNumberRef to a Number
VALUE convertBooleanRef(CFBooleanRef plist);        // Converts a CFBooleanRef to a Boolean
VALUE convertDateRef(CFDateRef plist);              // Converts a CFDateRef to a Time
VALUE convertDataRef(CFDataRef plist);              // Converts a CFDataRef to a String (with blob set to true)
VALUE convertDictionaryRef(CFDictionaryRef plist);  // Converts a CFDictionaryRef to a Hash
VALUE convertArrayRef(CFArrayRef plist);            // Converts a CFArrayRef to an Array

/*
 * Ruby Object Type Conversion Functions
 */
CFPropertyListRef convertString(VALUE obj);         // Converts a String to a CFStringRef
CFNumberRef convertNumber(VALUE obj);               // Converts a Number to a CFNumberRef
CFDateRef convertTime(VALUE obj);                   // Converts a Time to a CFDateRef
CFArrayRef convertArray(VALUE obj);                 // Converts an Array to a CFArrayRef
CFDictionaryRef convertHash(VALUE obj);             // Converts a Hash to a CFDictionaryREf



