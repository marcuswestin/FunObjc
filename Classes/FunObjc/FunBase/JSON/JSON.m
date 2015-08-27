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
        DLog(@"Threw in [JSON serialize:] %@", exception);
        [exception raise];
        return nil;
    }
    
    NSData* data;
    if ([obj isNull]) {
        data = [NSData data];
    } else {
        data = [NSJSONSerialization dataWithJSONObject:obj options:0 error:&err];
    }

    if (err) {
        DLog(@"Error: %@", err);
        return nil;
    }
    return data;
}

+ (NSString *)stringify:(id)obj {
    return [[NSString alloc] initWithData:[JSON serialize:obj] encoding:NSUTF8StringEncoding];
}

+ (id)parseData:(NSData *)data {
    if (!data) { return nil; }
    NSError* err;
    NSLog(@"PARSE DATA %@", data.toString);
    id result = [JSON parseData:data error:&err];
    NSLog(@"DID PARSE DATA %@ %@ %@", data.toString, err, result);
    if (err) {
        NSLog(@"JSON parseData: %@", err);
        NSLog(@"JSON string: %@", [data toString]);
    }
    return result;
}

+ (id)parseData:(NSData *)data error:(NSError *__autoreleasing *)error {
    return [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:error];
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
