//
//  JSON.m
//  Dogo-iOS
//
//  Created by Marcus Westin on 6/27/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "JSON.h"
#import "NSObject+Fun.h"
#import "NSString+Fun.h"
#import "State.h"
#import "CJSONSerializer.h"
#import "CJSONDeserializer.h"

@implementation JSON

static BOOL useUnquotedKeys = NO;
+ (void)useUnquotedKeys {
    useUnquotedKeys = YES;
}

+ (NSData*)serialize:(id)obj {
    NSError* err;
    @try {
        obj = [self sanitize:obj];
    }
    @catch (NSException *exception) {
        NSLog(@"Threw in [JSON serialize:] %@", exception);
        [exception raise];
        return nil;
    }
    
    NSData* data;
    if ([obj isNull]) {
        data = [NSData data];
    } else {
        CJSONSerializer* serializer = [CJSONSerializer serializer];
        if (useUnquotedKeys) {
            serializer.options = kJSONSerializationOptions_UnquotedKeys;
        }
        data = [serializer serializeObject:obj error:&err];
    }

    if (err) {
        NSLog(@"Error: %@", err);
        return nil;
    }
    return data;
}

+ (NSString *)stringify:(id)obj {
    return [[NSString alloc] initWithData:[JSON serialize:obj] encoding:NSUTF8StringEncoding];
}

+ (id)parseData:(NSData *)data {
    NSError* err;
    id result = [JSON parseData:data error:&err];
    if (err) {
        NSLog(@"JSON parseData: %@", err);
    }
    return result;
}

+ (id)parseData:(NSData *)data error:(NSError *__autoreleasing *)error {
    CJSONDeserializer* deserializer = [CJSONDeserializer deserializer];
//    deserializer.nullObject = NULL; // "If the JSON has null values they get represented as NSNull. This line lets you avoids NSNull values.
    return [deserializer deserialize:data error:error];
}

+ (id)parseString:(NSString *)string {
    return [JSON parseData:string.toData];
}

+ (id)sanitize:(id)obj {
    if (!obj) {
        return [NSNull null];
    } if ([obj isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary* res = [NSMutableDictionary dictionaryWithDictionary:obj];
        for (id key in obj) {
            res[key] = [JSON sanitize:obj[key]];
        }
        return res;
        
    } else if ([obj isKindOfClass:[NSArray class]]) {
        NSMutableArray* res = [NSMutableArray arrayWithArray:obj];
        for (int i=0; i<res.count; i++) {
            res[i] = [JSON sanitize:res[i]];
        }
        return res;
        
    } else if ([obj isKindOfClass:[State class]]) {
        return [JSON sanitize:((State*)obj).toDictionary];
        
    } else {
        return obj;
    }
}

@end
