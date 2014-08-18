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

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        observations = [NSMutableDictionary dictionary];
        builtMaps = [NSMutableSet set];
        deflateMaps = [NSMutableDictionary dictionary];
        inflateMaps = [NSMutableDictionary dictionary];
    });
}



// Observations API
///////////////////
static NSMutableDictionary* observations;
+ (void)observeValue:(NSString *)valueName subscriber:(id)subscriber callback:(void (^)(id))callback {
    NSString* observationName = [State _observationName:valueName];
    [Events on:observationName subscriber:subscriber callback:callback];
    callback(observations[observationName]);
}
+ (void)unobserveValue:(NSString *)valueName subscriber:(id)subscriber {
    NSString* observationName = [State _observationName:valueName];
    [Events off:observationName subscriber:subscriber];
}
+ (void)updateValue:(NSString *)valueName newValue:(id)newValue {
    NSString* observationName = [State _observationName:valueName];
    if (![observations[observationName] isEqual:newValue]) {
        observations[observationName] = newValue;
        [Events fire:observationName info:newValue];
    }
}
+ (id)getValue:(NSString *)valueName {
    NSString* observationName = [State _observationName:valueName];
    return observations[observationName];
}
+ (NSString*)_observationName:(NSString*)valueName {
    return [NSString stringWithFormat:@"_Obs-%@", valueName];
}
+ (void)incrementValue:(NSString *)valueName {
    [self addToValue:valueName number:1];
}
+ (void)decrementValue:(NSString *)valueName {
    [self addToValue:valueName number:-1];
}
+ (void)addToValue:(NSString *)valueName number:(NSInteger)addNumber {
    NSNumber* val = [self getValue:valueName];
    [self updateValue:valueName newValue:num((val ? [val integerValue] : 0) + addNumber)];
}

// Construction API
///////////////////
+ (instancetype)fromDict:(NSDictionary*)dict inflate:(BOOL)inflate {
    if ([dict isKindOfClass:State.class]) {
        return (State*)dict;
    } else {
        id instance = [[[self class] alloc] initWithDict:dict inflate:inflate];
        return instance;
    }
}

+ (instancetype)fromDict:(NSDictionary*)dict {
    return [self fromDict:dict inflate:NO];
}
+ (instancetype)fromDeflatedDict:(NSDictionary *)deflatedDict {
    return [self fromDict:deflatedDict inflate:YES];
}
+ (instancetype)fromJson:(NSString *)json {
    return [self fromDict:[JSON parseString:json]];
}
+ (instancetype)fromDeflatedJson:(NSString *)json {
    return [self fromDeflatedDict:[JSON parseString:json]];
}

- (instancetype)init {
    if (self = [super init]) {
        [self setDefaults];
    }
    return self;
}

- (void)setDefaults{}

- (instancetype)initWithDict:(NSDictionary*)dict inflate:(BOOL)inflate {
    [self _setPropertiesFromDict:dict inflate:inflate];
    [self setDefaults];
    return self;
}

- (void)mergeDict:(NSDictionary *)dict {
    [self _setPropertiesFromDict:dict inflate:NO];
}

- (void)_setPropertiesFromDict:(NSDictionary*)dict inflate:(BOOL)inflate {
    NSDictionary* props = [self classProperties];
    NSDictionary* deserializeMap = (inflate ? [self deserializeMap] : nil);
    for (NSString* key in dict) {
        if (deserializeMap) {
            NSString* deserializedKey = deserializeMap[key];
            if (!deserializeMap) {
                DLog(@"WARNING Saw unknown deserialize key %@ for class %@", key, self.className);
                continue;
            }
            [self _setPropertyKey:deserializedKey value:dict[key] props:props];
        } else {
            [self _setPropertyKey:key value:dict[key] props:props];
        }
    }
}

- (void)_setPropertyKey:(NSString*)key value:(id)value props:(NSDictionary*)props {
    NSString* propertyClassName = props[key];
    if (!propertyClassName) {
        DLog(@"WARNING Saw unknown property key %@ for class %@", key, self.className);
        return;
    }
    
    if (![value isNull]) {
        if (propertyClassName.length != 1) {
            Class class = NSClassFromString(props[key]);
            if (!class) {
                DLog(@"WARNING Saw unknown class %@ for key %@. (Did you forget '@implementation %@'?)", props[key], key, props[key]);
            }
            if ([class isSubclassOfClass:[State class]]) {
                value = [class fromDict:value];
            }
        }
        [self setValue:value forKey:key];
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
    return [[class alloc] initWithDict:dict inflate:NO];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    DLog(@"WARNING State class \"%@\" attempted to set value %@ for undefined key %@", self.className, value, key);
}

- (void)setNilValueForKey:(NSString *)key {
//    DLog(@"Warning State class \"%@\" attempted to set nil value for key %@", self.className, key);
}

- (NSString*)className {
    return NSStringFromClass([self class]);
}

- (BOOL)archiveToDocument:(NSString *)archiveDocName {
    return [Files writeDocumentJson:archiveDocName object:self.toDictionary];
}

+ (instancetype)fromArchiveDocument:(NSString*)archiveDocName {
    NSDictionary* dict = [Files readDocumentJson:archiveDocName];
    if (dict) {
        return [[self class] fromDict:dict];
    } else {
        return [[self class] new];
    }
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
- (NSDictionary*)serializeMap {
    if (![self conformsToProtocol:@protocol(StateInflateDeflate)]) {
        return nil;
    }
    if (![builtMaps containsObject:[self class]]) {
        [self buildSerializeMaps];
    }
    return deflateMaps[[self class]];
}
- (NSDictionary*)deserializeMap {
    if (![self conformsToProtocol:@protocol(StateInflateDeflate)]) {
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
- (NSDictionary *)deflatedDict {
    NSDictionary* deflateMap = [self serializeMap];
    NSMutableDictionary* deflatedDict = [NSMutableDictionary dictionaryWithCapacity:deflateMap.count];
    for (NSString* key in deflateMap) {
        id value = [self valueForKey:key];
        if (value) {
            deflatedDict[deflateMap[key]] = value;
        }
    }
    return deflatedDict;
}

@end
