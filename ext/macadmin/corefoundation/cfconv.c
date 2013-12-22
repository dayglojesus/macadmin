/*
 *  cfconv.c
 *  - Functions for converting CoreFoundation Types to Ruby objects and vice versa
 *  
 *  Graciously and respectfully plundered from Kevin Ballard's amazing plist.c
 *  https://github.com/kballard/textmate-bundles/blob/master/Tools/plist/plist.c
 *  
 *  Created by Brian Warsing on 2013-12-22.
 *  Copyright (c) 2013 Brian Warsing. All rights reserved.
 */

#include "cfconv.h"

/*
 * Internal Prototypes
 */

// Internal CoreFoundation to Ruby
VALUE str_setBlob(VALUE self, VALUE b);                                         // Sets the blob status of +str+.
VALUE convertPropertyListRef(CFPropertyListRef plist);                          // Maps the property list object to a ruby object
void dictionaryConverter(const void *key, const void *value, void *context);    // Converts the keys and values of a CFDictionaryRef
void arrayConverter(const void *value, void *context);                          // Converts the values of a CFArrayRef

// Internal Ruby to CoreFoundation
VALUE str_blob(VALUE self);                                                     // Returns whether or not +str+ is a blob
CFPropertyListRef convertObject(VALUE obj);                                     // Converts an Object to a CFTypeRef
int iterateHash(VALUE key, VALUE val, VALUE dict);                              // Converts the keys and values of a Hash to CFTypeRefs

/*
 * Core Foundation Type Conversion Functions
 */

// Converts a CFStringRef to a String
VALUE convertStringRef(CFStringRef plist) {
    CFIndex byteCount;
    CFRange range = CFRangeMake(0, CFStringGetLength(plist));
    CFStringEncoding enc = kCFStringEncodingUTF8;
    Boolean succ = CFStringGetBytes(plist, range, enc, 0, false, NULL, 0, &byteCount);
    if (!succ) {
        enc = kCFStringEncodingMacRoman;
        CFStringGetBytes(plist, range, enc, 0, false, NULL, 0, &byteCount);
    }
    UInt8 *buffer = ALLOC_N(UInt8, byteCount);
    CFStringGetBytes(plist, range, enc, 0, false, buffer, byteCount, NULL);
    VALUE retval = rb_str_new((char *)buffer, (long)byteCount);
    free(buffer);
    return retval;
}

// Converts a CFNumberRef to a Number
VALUE convertNumberRef(CFNumberRef plist) {
    if (CFNumberIsFloatType(plist)) {
        double val;
        CFNumberGetValue(plist, kCFNumberDoubleType, &val);
        return rb_float_new(val);
    } else {
#ifdef LL2NUM
        long long val;
        CFNumberGetValue(plist, kCFNumberLongLongType, &val);
        return LL2NUM(val);
#else
        long val;
        CFNumberGetValue(plist, kCFNumberLongType, &val);
        return LONG2NUM(val);
#endif
    }
}

// Converts a CFBooleanRef to a Boolean
VALUE convertBooleanRef(CFBooleanRef plist) {
    if (CFBooleanGetValue(plist)) {
        return Qtrue;
    } else {
        return Qfalse;
    }
}

// Converts a CFDateRef to a Time
VALUE convertDateRef(CFDateRef plist) {
    CFAbsoluteTime seconds = CFDateGetAbsoluteTime(plist);
    
    VALUE timeEpoch = rb_funcall(rb_cTime, rb_intern("gm"), 1, INT2FIX(2001));
    
    // trunace the time since Ruby's Time object stores it as a 32 bit signed offset from 1970 (undocumented)
    const float min_time = -3124310400.0f;
    const float max_time =  1169098047.0f;
    seconds = seconds < min_time ? min_time : (seconds > max_time ? max_time : seconds);
    
    return rb_funcall(timeEpoch, rb_intern("+"), 1, rb_float_new(seconds));
}

// Converts a CFDataRef to a String (with blob set to true)
VALUE convertDataRef(CFDataRef plist) {
    const UInt8 *bytes = CFDataGetBytePtr(plist);
    CFIndex len = CFDataGetLength(plist);
    VALUE str = rb_str_new((char *)bytes, (long)len);
    str_setBlob(str, Qtrue);
    return str;
}

// Sets the blob status of +str+.
VALUE str_setBlob(VALUE self, VALUE b) {
    if (TYPE(b) == T_TRUE || TYPE(b) ==  T_FALSE) {
        return rb_ivar_set(self, rb_intern("@blob"), b);
    } else {
        rb_raise(rb_eArgError, "Argument 1 must be true or false");
        return Qnil;
    }
}

// Maps the property list object to a ruby object
VALUE convertPropertyListRef(CFPropertyListRef plist) {
    CFTypeID typeID = CFGetTypeID(plist);
    if (typeID == CFStringGetTypeID()) {
        return convertStringRef((CFStringRef)plist);
    } else if (typeID == CFDictionaryGetTypeID()) {
        return convertDictionaryRef((CFDictionaryRef)plist);
    } else if (typeID == CFArrayGetTypeID()) {
        return convertArrayRef((CFArrayRef)plist);
    } else if (typeID == CFNumberGetTypeID()) {
        return convertNumberRef((CFNumberRef)plist);
    } else if (typeID == CFBooleanGetTypeID()) {
        return convertBooleanRef((CFBooleanRef)plist);
    } else if (typeID == CFDataGetTypeID()) {
        return convertDataRef((CFDataRef)plist);
    } else if (typeID == CFDateGetTypeID()) {
        return convertDateRef((CFDateRef)plist);
    } else {
        return Qnil;
    }
}

// Converts the keys and values of a CFDictionaryRef
void dictionaryConverter(const void *key, const void *value, void *context) {
    rb_hash_aset((VALUE)context, convertPropertyListRef(key), convertPropertyListRef(value));
}

// Converts a CFDictionaryRef to a Hash
VALUE convertDictionaryRef(CFDictionaryRef plist) {
    VALUE hash = rb_hash_new();
    CFDictionaryApplyFunction(plist, dictionaryConverter, (void *)hash);
    return hash;
}

// Converts the values of a CFArrayRef
void arrayConverter(const void *value, void *context) {
    rb_ary_push((VALUE)context, convertPropertyListRef(value));
}

// Converts a CFArrayRef to an Array
VALUE convertArrayRef(CFArrayRef plist) {
    VALUE array = rb_ary_new();
    CFRange range = CFRangeMake(0, CFArrayGetCount(plist));
    CFArrayApplyFunction(plist, range, arrayConverter, (void *)array);
    return array;
}

/*
 * Ruby Object Type Conversion Functions
 */

// Returns whether or not +str+ is a blob
VALUE str_blob(VALUE self) {
    VALUE blob = rb_attr_get(self, rb_intern("@blob"));
    if (NIL_P(blob)) {
        return Qfalse;
    } else {
        return blob;
    }
}

// Converts a String to a CFStringRef
CFPropertyListRef convertString(VALUE obj) {
    if (RTEST(str_blob(obj))) {
        // convert to CFDataRef
        StringValue(obj);
        CFDataRef data = CFDataCreate(kCFAllocatorDefault, (const UInt8*)RSTRING_PTR(obj), (CFIndex)RSTRING_LEN(obj));
        return data;
    } else {
        // convert to CFStringRef
        StringValue(obj);
        CFStringRef string = CFStringCreateWithBytes(kCFAllocatorDefault, (const UInt8*)RSTRING_PTR(obj), (CFIndex)RSTRING_LEN(obj), kCFStringEncodingUTF8, false);
        if (!string) {
            // try MacRoman
            string = CFStringCreateWithBytes(kCFAllocatorDefault, (const UInt8*)RSTRING_PTR(obj), (CFIndex)RSTRING_LEN(obj), kCFStringEncodingMacRoman, false);
        }
        return string;
    }
}

// Converts a Number to a CFNumberRef
CFNumberRef convertNumber(VALUE obj) {
    void *valuePtr;
    CFNumberType type;
    switch (TYPE(obj)) {
        case T_FLOAT: {
            double num = NUM2DBL(obj);
            valuePtr = &num;
            type = kCFNumberDoubleType;
            break;
        }
        case T_FIXNUM: {
            int num = NUM2INT(obj);
            valuePtr = &num;
            type = kCFNumberIntType;
            break;
        }
        case T_BIGNUM: {
#ifdef NUM2LL
            long long num = NUM2LL(obj);
            type = kCFNumberLongLongType;
#else
            long num = NUM2LONG(obj);
            type = kCFNumberLongType;
#endif
            valuePtr = &num;
            break;
        }
        default:
            rb_raise(rb_eStandardError, "ERROR: Wrong object type passed to convertNumber");
            return NULL;
    }
    CFNumberRef number = CFNumberCreate(kCFAllocatorDefault, type, valuePtr);
    return number;
}

// Converts a Time to a CFDateRef
CFDateRef convertTime(VALUE obj) {
    VALUE timeEpoch = rb_funcall(rb_cTime, rb_intern("gm"), 1, INT2FIX(2001));
    VALUE secs = rb_funcall(obj, rb_intern("-"), 1, timeEpoch);
    CFDateRef date = CFDateCreate(kCFAllocatorDefault, NUM2DBL(secs));
    return date;
}

// Converts an Object to a CFTypeRef
CFPropertyListRef convertObject(VALUE obj) {
    switch (TYPE(obj)) {
        case T_STRING: return convertString(obj); break;
        case T_HASH: return convertHash(obj); break;
        case T_ARRAY: return convertArray(obj); break;
        case T_FLOAT:
        case T_FIXNUM:
        case T_BIGNUM: return convertNumber(obj); break;
        case T_TRUE: return kCFBooleanTrue; break;
        case T_FALSE: return kCFBooleanFalse; break;
        default: if (rb_obj_is_kind_of(obj, rb_cTime)) return convertTime(obj);
    }
    rb_raise(rb_eArgError, "An object in the argument tree could not be converted");
    return NULL;
}

// Converts a Hash to a CFDictionaryREf
CFDictionaryRef convertHash(VALUE obj) {
    // RHASH_TBL exists in ruby 1.8.7 but not ruby 1.8.6
#ifdef RHASH_TBL
    st_table *tbl = RHASH_TBL(obj);
#else
    st_table *tbl = RHASH(obj)->tbl;
#endif
    CFIndex count = (CFIndex)tbl->num_entries;
    CFMutableDictionaryRef dict = CFDictionaryCreateMutable(kCFAllocatorDefault, count, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    st_foreach(tbl, iterateHash, (VALUE)dict);
    return dict;
}

// Converts the keys and values of a Hash to CFTypeRefs
int iterateHash(VALUE key, VALUE val, VALUE dict) {
    CFPropertyListRef dKey = convertObject(key);
    CFPropertyListRef dVal = convertObject(val);
    CFDictionaryAddValue((CFMutableDictionaryRef)dict, dKey, dVal);
    CFRelease(dKey);
    CFRelease(dVal);
    return ST_CONTINUE;
}

// Converts an Array to a CFArrayRef
CFArrayRef convertArray(VALUE obj) {
    CFIndex count = (CFIndex)RARRAY_LEN(obj);
    CFMutableArrayRef array = CFArrayCreateMutable(kCFAllocatorDefault, count, &kCFTypeArrayCallBacks);
    int i;
    for (i = 0; i < count; i++) {
        CFPropertyListRef aVal = convertObject(RARRAY_PTR(obj)[i]);
        CFArrayAppendValue(array, aVal);
        CFRelease(aVal);
    }
    return array;
}




