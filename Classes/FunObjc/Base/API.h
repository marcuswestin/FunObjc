//
//  API.h
//  Dogo-iOS
//
//  Created by Marcus Westin on 6/27/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FunGlobals.h"

@interface Multipart : NSObject
+ (instancetype)json:(NSDictionary*)obj;
+ (instancetype)jpg:(UIImage*)image quality:(CGFloat)quality;
+ (instancetype)png:(UIImage*)image;
+ (instancetype)avi:(NSString*)path;
+ (instancetype)m4a:(NSString*)path;
+ (instancetype)json:(NSDictionary*)obj name:(NSString*)name;
+ (instancetype)jpg:(UIImage*)image quality:(CGFloat)quality name:(NSString*)name;
+ (instancetype)png:(UIImage*)image name:(NSString*)name;
+ (instancetype)avi:(NSString*)path name:(NSString*)name;
+ (instancetype)m4a:(NSString*)path name:(NSString*)name;
+ (instancetype)withContent:(NSData*)contentData type:(NSString*)contentType disposition:(NSString*)contentDisposition;
@property NSData* contentData;
@property NSString* contentType;
@property NSString* contentDisposition;
@end

typedef void (^APICallback)(NSError* err, NSDictionary* res);
typedef NSError* (^APIErrorCheck)(NSHTTPURLResponse* httpRes, NSDictionary* res);

@interface API : NSObject

+ (void)setMultipartNamesJson:(NSString*)jsonName image:(NSString*)imageName video:(NSString*)videoName audio:(NSString*)audioName;
+ (void)setup:(NSString*)serverUrl;
+ (void)setHeaders:(NSDictionary*)headers;
+ (void)setUUIDHeaderName:(NSString*)uuidHeaderName;
+ (void)post:(NSString*)path json:(NSDictionary*)json callback:(APICallback)callback;
+ (void)get:(NSString*)path queries:(NSDictionary*)queries callback:(APICallback)callback;
+ (void)postMultipart:(NSString *)path parts:(NSArray *)parts callback:(APICallback)callback;
+ (void)addErrorCheck:(APIErrorCheck)errorCheck;
+ (void)waitForCurrentRequests:(Block)callback;
+ (void)showSpinner;
+ (void)hideSpinner;
@end
