//
//  NSURLConnection+Fun.h
//  Dogo iOS
//
//  Created by Marcus Westin on 12/22/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^NetProgressBlock)(float progress);
typedef void (^NetCompletionBlock)(NSURLResponse* response, NSData* data, NSError* networkError);

@interface Net : NSObject <NSURLConnectionDataDelegate>

+ (void)request:(NSURLRequest *)request uploadProgress:(NetProgressBlock)uploadProgressBlock downloadProgress:(NetProgressBlock)downloadProgressBlock completion:(NetCompletionBlock)completionBlock;

@end
