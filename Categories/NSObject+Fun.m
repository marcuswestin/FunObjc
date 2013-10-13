//
//  NSObject+Fun.m
//  Dogo-iOS
//
//  Created by Marcus Westin on 6/25/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "NSObject+Fun.h"
#import "NSString+Fun.h"
#import "Log.h"
#import <objc/runtime.h>

@implementation NSObject (Fun)
- (BOOL)isNull {
    return self == (id)[NSNull null];
}
- (NSString *)className {
    return NSStringFromClass(self.class);
}

NSString* getPropertyType(objc_property_t property) {
    const char *attributes = property_getAttributes(property);
    char buffer[1 + strlen(attributes)];
    strcpy(buffer, attributes);
    char *state = buffer, *attribute;
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

static NSMutableDictionary* classPropCache;

- (NSDictionary *)classProperties {
    if (!classPropCache) {
        classPropCache = [NSMutableDictionary dictionary];
    }

    if (!classPropCache[self.className]) {
        NSMutableDictionary *results = [NSMutableDictionary dictionary];
        
        unsigned int outCount, i;
        objc_property_t *properties = class_copyPropertyList(self.class, &outCount);
        for (i = 0; i < outCount; i++) {
            objc_property_t property = properties[i];
            const char *propName = property_getName(property);
            if(propName) {
                NSString* propertyType = getPropertyType(property);
                NSString *propertyName = [NSString stringWithUTF8String:propName];
                [results setObject:propertyType forKey:propertyName];
            }
        }
        free(properties);
        
        classPropCache[self.className] = [NSDictionary dictionaryWithDictionary:results];
    }
    
    return classPropCache[self.className];
}

@end
