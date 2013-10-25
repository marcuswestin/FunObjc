//
//  State.m
//  ivyq
//
//  Created by Marcus Westin on 9/22/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "State.h"
#import <objc/runtime.h>
#import "Files.h"
#import "FunObjc.h"

@implementation State

+ (instancetype)fromDict:(NSDictionary*)dict {
    if ([dict isKindOfClass:State.class]) {
        return (State*)dict;
    } else {
        id instance = [[[self class] alloc] initWithDict:dict];
        return instance;
    }
}

+ (instancetype)withDict:(NSDictionary *)dict {
    return [[self class] fromDict:dict];
}

- (instancetype)init {
    if (self = [super init]) {
        [self setDefaults];
    }
    return self;
}

- (void)setDefaults{}

- (instancetype)initWithDict:(NSDictionary*)dict {
    NSDictionary* props = [self classProperties];
    
    for (NSString* key in dict) {
        NSString* className = props[key];
        if (!className) {
            NSLog(@"WARNING Saw unknown property key %@ for class %@", key, self.className);
            continue;
        }
        
        id val = dict[key];

        if (![val isNull]) {
            if (className.length != 1) {
                Class class = NSClassFromString(props[key]);
                if (!class) {
                    NSLog(@"WARNING Saw unknown class %@ for key %@. Did you forget '@implementation %@'?", props[key], key, props[key]);
                }
                if ([class isSubclassOfClass:[State class]]) {
                    val = [class fromDict:val];
                }
            }
            
            [self setValue:val forKey:key];
        }
    }
    
    [self setDefaults];
    return self;
}

- (id)copy {
    return [[self class] fromDict:[self toDictionary]];
}

- (NSDictionary*)toDictionary {
    unsigned count;
    objc_property_t *properties = class_copyPropertyList([self class], &count);
    NSMutableArray *rv = [NSMutableArray arrayWithCapacity:count];
    for (unsigned i = 0; i < count; i++) {
        objc_property_t property = properties[i];
        NSString *name = [NSString stringWithUTF8String:property_getName(property)];
        [rv addObject:name];
    }
    free(properties);
    return [self dictionaryWithValuesForKeys:rv];
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:[self toDictionary] forKey:@"FunStateDict"];
    NSString* className = self.className;
    [aCoder encodeObject:className forKey:@"FunStateClass"];
}
- (id)initWithCoder:(NSCoder *)aDecoder {
    NSString* className = [aDecoder decodeObjectForKey:@"FunStateClass"];
    Class class = NSClassFromString(className);
    NSDictionary* dict = [aDecoder decodeObjectForKey:@"FunStateDict"];
    return [[class alloc] initWithDict:dict];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    NSLog(@"WARNING State class \"%@\" attempted to set value %@ for undefined key %@", self.className, value, key);
}

- (void)setNilValueForKey:(NSString *)key {
//    NSLog(@"Warning State class \"%@\" attempted to set nil value for key %@", self.className, key);
}

- (NSString*)className {
    return NSStringFromClass([self class]);
}

- (BOOL)archiveToDocument:(NSString *)archiveDocName {
    return [NSKeyedArchiver archiveRootObject:self toFile:[Files documentPath:archiveDocName]];
}

+ (instancetype)fromArchiveDocument:(NSString*)archiveDocName {
    id instance = [NSKeyedUnarchiver unarchiveObjectWithFile:[Files documentPath:archiveDocName]];
    if (instance) {
        [instance setDefaults];
    } else {
        instance = [[self class] new];
    }
    return instance;
}

- (instancetype)copyWithDictionary:(NSDictionary *)dict {
    id copy = [self copy];
    [copy setValuesForKeysWithDictionary:dict];
    return copy;
}

@end
