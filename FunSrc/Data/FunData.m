//
//  FunBase.h
//  Dogo-iOS
//
//  Created by Marcus Westin on 6/25/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import <objc/runtime.h>
#import "FunData.h"

void SetProperty(id obj, NSString* key, id val) {
    objc_setAssociatedObject(obj, (__bridge const void *)(key), val, OBJC_ASSOCIATION_RETAIN);
}

void SetPropertyCopy(id obj, NSString* key, id val) {
    objc_setAssociatedObject(obj, (__bridge const void *)(key), val, OBJC_ASSOCIATION_COPY);
}

void SetPropertyAssign(id obj, NSString* key, id val) {
    objc_setAssociatedObject(obj, (__bridge const void *)(key), val, OBJC_ASSOCIATION_ASSIGN);
}

id GetProperty(id obj, NSString* key) {
    return objc_getAssociatedObject(obj, (__bridge const void *)(key));
}

NSArray* GetPropertyNames(Class cls) {
    unsigned count;
    objc_property_t *properties = class_copyPropertyList(cls, &count);
    NSMutableArray *names = [NSMutableArray arrayWithCapacity:count];
    for (unsigned i = 0; i < count; i++) {
        objc_property_t property = properties[i];
        [names addObject:[NSString stringWithUTF8String:property_getName(property)]];
    }
    free(properties);
    return [names copy];
}

NSString* getPropertyType(objc_property_t property) {
    const char *attributes = property_getAttributes(property);
    char buffer[strlen(attributes) + 1];
    strcpy(buffer, attributes);
    
    char *state = buffer;
    char *attribute;
    while ((attribute = strsep(&state, ",")) != NULL) {

        if (attribute[0] == 'T' && attribute[1] != '@') {
            // A C primitive type. Apple docs list them: int is "i", long "l", unsigned "I", etc.
            return [[NSString alloc] initWithBytes:(attribute + 1) length:strlen(attribute) - 1 encoding:NSUTF8StringEncoding];
            
        } else if (attribute[0] == 'T' && attribute[1] == '@' && strlen(attribute) == 2) {
            // An ObjC "id" type.
            return @"id";
            
        } else if (attribute[0] == 'T' && attribute[1] == '@') {
            // An ObjC object type:
            return [[NSString alloc] initWithBytes:(attribute + 3) length:(strlen(attribute) - 4) encoding:NSUTF8StringEncoding];
        }
    }
    return nil;
}

NSDictionary* GetClassProperties(Class cls) {
    NSMutableDictionary *results = [NSMutableDictionary dictionary];
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList(cls, &outCount);
    for (i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        const char *propName = property_getName(property);
        if(propName) {
            NSString* propertyType = getPropertyType(property);
            NSString *propertyName = [NSString stringWithUTF8String:propName];
            results[propertyName] = propertyType;
        }
    }
    free(properties);
    return [results copy];
}
