//
//  JSON.m
//  Dogo-iOS
//
//  Created by Marcus Westin on 6/27/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "JSON.h"
#import "Log.h"
#import "NSObject+Fun.h"
#import "NSString+Fun.h"
#import "State.h"

@implementation JSON

static NSJSONWritingOptions jsonOpts = 0;

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
    NSData* data = ([obj isNull]
                    ? [NSData data]
                    : [NSJSONSerialization dataWithJSONObject:obj options:jsonOpts error:&err]);
    if (err) { return [Log error:err]; }
    return data;
}

+ (NSString *)stringify:(id)obj {
    return [[NSString alloc] initWithData:[JSON serialize:obj] encoding:NSUTF8StringEncoding];
}

+ (id)parseData:(NSData *)data {
    if (!data) { return nil; }
    NSError* err;
    id result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&err];
    if (err) { return [Log error:err]; }
    return result;

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
