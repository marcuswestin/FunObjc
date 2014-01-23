//
//  State.m
//  ivyq
//
//  Created by Marcus Westin on 9/22/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "State.h"
#import "Files.h"
#import "NSObject+Fun.h"
#import "FunRuntimeProperties.h"

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
    [self _setPropertiesFromDict:dict];
    [self setDefaults];
    return self;
}

- (void)mergeDict:(NSDictionary *)dict {
    [self _setPropertiesFromDict:dict];
}

- (void)_setPropertiesFromDict:(NSDictionary*)dict {
    NSDictionary* props = [self classProperties];
    NSDictionary* deserializeMap = [self deserializeMap];
    for (NSString* key in dict) {
        if (deserializeMap) {
            NSString* deserializedKey = deserializeMap[key];
            if (!deserializeMap) {
                NSLog(@"WARNING Saw unknown deserialize key %@ for class %@", key, self.className);
                continue;
            }
            [self _setPropertyKey:deserializedKey dict:dict props:props];
        } else {
            [self _setPropertyKey:key dict:dict props:props];
        }
    }
}

- (void)_setPropertyKey:(NSString*)key dict:(NSDictionary*)dict props:(NSDictionary*)props {
    NSString* propertyClassName = props[key];
    if (!propertyClassName) {
        NSLog(@"WARNING Saw unknown property key %@ for class %@", key, self.className);
        return;
    }
    
    id val = dict[key];
    if (![val isNull]) {
        if (propertyClassName.length != 1) {
            Class class = NSClassFromString(props[key]);
            if (!class) {
                NSLog(@"WARNING Saw unknown class %@ for key %@. (Did you forget '@implementation %@'?)", props[key], key, props[key]);
            }
            if ([class isSubclassOfClass:[State class]]) {
                val = [class fromDict:val];
            }
        }
        [self setValue:val forKey:key];
    }
}


- (id)copy {
    return [[self class] fromDict:[self toDictionary]];
}

- (NSDictionary*)toDictionary {
    return [self dictionaryWithValuesForKeys:GetPropertyNames([self class])];
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

// Inflate/Deflate
//////////////////
static NSMutableSet* builtMaps;
static NSMutableDictionary* deflateMaps;
static NSMutableDictionary* inflateMaps;
+ (void)initialize {
    builtMaps = [NSMutableSet set];
    deflateMaps = [NSMutableDictionary dictionary];
    inflateMaps = [NSMutableDictionary dictionary];
}
- (NSDictionary*)serializeMap {
    if (![self conformsToProtocol:@protocol(InflateDeflateState)]) {
        return nil;
    }
    if (![builtMaps containsObject:[self class]]) {
        [self buildSerializeMaps];
    }
    return deflateMaps[[self class]];
}
- (NSDictionary*)deserializeMap {
    if (![self conformsToProtocol:@protocol(InflateDeflateState)]) {
        return nil;
    }
    if (![builtMaps containsObject:[self class]]) {
        [self buildSerializeMaps];
    }
    return inflateMaps[[self class]];
}
- (void)buildSerializeMaps {
    [builtMaps addObject:[self class]];
    NSDictionary* map = [[self class] inflateDeflateMap];
    deflateMaps[(id <NSCopying>)[self class]] = map;
    inflateMaps[(id <NSCopying>)[self class]] = [map reverse];
}

@end
