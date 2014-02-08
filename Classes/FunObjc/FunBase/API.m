//
//  API.m
//  Dogo-iOS
//
//  Created by Marcus Westin on 6/27/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "API.h"
#import "FunBase.h"
#import "JSON.h"

static NSString* multipartJsonName = @"json";
static NSString* multipartImageName = @"image";
static NSString* multipartVideoName = @"video";
static NSString* multipartAudioName = @"audio";

@implementation Multipart
+ (instancetype)json:(NSDictionary *)obj {
    return [Multipart json:obj name:multipartJsonName];
}
+ (instancetype)json:(NSDictionary *)obj name:(NSString *)name {
    NSString* disposition = [NSString stringWithFormat:@"form-data; name=\"%@\"", name];
    return [Multipart withContent:[JSON serialize:obj] type:@"application/json" disposition:disposition];
}

+ (instancetype)jpg:(UIImage *)image quality:(CGFloat)quality {
    return [Multipart jpg:image quality:quality name:multipartImageName];
}
+ (instancetype)jpg:(UIImage *)image quality:(CGFloat)quality name:(NSString *)name {
    NSString* disposition = [NSString stringWithFormat:@"form-data; filename=\"%@.jpg\"; name=\"%@\"", name, name];
    return [Multipart withContent:UIImageJPEGRepresentation(image, quality) type:@"image/jpg" disposition:disposition];
}

+ (instancetype)png:(UIImage *)image {
    return [Multipart png:image name:multipartImageName];
}
+ (instancetype)png:(UIImage *)image name:(NSString *)name {
    NSString* disposition = [NSString stringWithFormat:@"form-data; filename=\"%@.png\"; name=\"%@\"", name, name];
    return [Multipart withContent:UIImagePNGRepresentation(image) type:@"image/png" disposition:disposition];
}

+ (instancetype)avi:(NSString *)path {
    return [Multipart avi:path name:multipartVideoName];
}
+ (instancetype)avi:(NSString *)path name:(NSString *)name {
    NSString* disposition = [NSString stringWithFormat:@"form-data; filename=\"%@.avi\"; name=\"%@\"", name, name];
    NSData* data = [NSData dataWithContentsOfFile:path];
    return [Multipart withContent:data type:@"video/avi" disposition:disposition];
}

+ (instancetype)mov:(NSString *)path {
    return [Multipart mov:path name:multipartVideoName];
}

+ (instancetype)mov:(NSString *)path name:(NSString *)name {
    NSString* disposition = [NSString stringWithFormat:@"form-data; filename=\"%@.mov\"; name=\"%@\"", name, name];
    NSData* data = [NSData dataWithContentsOfFile:path];
    return [Multipart withContent:data type:@"video/quicktime" disposition:disposition];
}

+ (instancetype)m4a:(NSString *)path {
    return [Multipart m4a:path name:multipartAudioName];
}
+ (instancetype)m4a:(NSString *)path name:(NSString *)name {
    NSString* disposition = [NSString stringWithFormat:@"form-data; filename=\"%@.m4a\"; name=\"%@\"", name, name];
    NSData* data = [NSData dataWithContentsOfFile:path];
    return [Multipart withContent:data type:@"audio/mp4a-latm" disposition:disposition];
}

+ (instancetype)withContent:(NSData *)contentData type:(NSString *)contentType disposition:(NSString *)contentDisposition {
    Multipart* instance = [Multipart new];
    instance.contentData = contentData;
    instance.contentType = contentType;
    instance.contentDisposition = contentDisposition;
    return instance;
}
@end

@implementation API

static NSString* server;
static NSOperationQueue* queue;
static NSString* multipartBoundary;
static NSMutableDictionary* baseHeaders;
static int numRequests = 0;
static NSMutableArray* errorChecks;
static NSString* uuidHeader;

+ (void)setMultipartNamesJson:(NSString *)jsonName image:(NSString *)imageName video:(NSString *)videoName audio:(NSString *)audioName {
    multipartJsonName = jsonName;
    multipartImageName = imageName;
    multipartVideoName = videoName;
    multipartAudioName = audioName;
}

+ (void)initialize {
    baseHeaders = [NSMutableDictionary dictionary];
    errorChecks = [NSMutableArray array];
    multipartBoundary = @"_____FUNOBJ_BNDRY__";
    queue = [[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = 10;
}

+ (void)addErrorCheck:(APIErrorCheck)errorCheck {
    [errorChecks addObject:errorCheck];
}

+ (void)setup:(NSString *)serverUrl {
    server = serverUrl;
}

+ (void)setHeader:(NSString *)name value:(NSString*)value {
    baseHeaders[name] = value;
}

+ (void)setUUIDHeaderName:(NSString *)uuidHeaderName {
    uuidHeader = uuidHeaderName;
}

+ (void)post:(NSString *)path json:(NSDictionary *)obj callback:(APICallback)callback {
    [self send:@"POST" path:path contentType:@"application/json" data:[JSON serialize:obj] callback:callback];
}

+ (void)get:(NSString *)path queries:(NSDictionary *)queries callback:(APICallback)callback {
    path = [NSString stringWithFormat:@"%@?%@", path, queries.toQueryString];
    [self send:@"GET" path:path contentType:nil data:nil callback:callback];
}

+ (void)postMultipart:(NSString *)path parts:(NSArray *)parts callback:(APICallback)callback {
    NSString* boundary = multipartBoundary;
    
    NSMutableData* httpData = [NSMutableData data];
    for (Multipart* part in parts) {
        
        // BOUNDARY
        [httpData appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        // HEADERS
        [httpData appendData:[[NSString stringWithFormat:@"Content-Disposition: %@\r\n", part.contentDisposition] dataUsingEncoding:NSUTF8StringEncoding]];
        [httpData appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n", part.contentType] dataUsingEncoding:NSUTF8StringEncoding]];
        [httpData appendData:[[NSString stringWithFormat:@"Content-Length: %lu\r\n", (unsigned long)part.contentData.length] dataUsingEncoding:NSUTF8StringEncoding]];
        // EMPTY
        [httpData appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        // CONTENT + newline
        [httpData appendData:[NSData dataWithData:part.contentData]];
        [httpData appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    [httpData appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSString* contentType = [@"multipart/form-data; boundary=" stringByAppendingString:boundary];
    [self send:@"POST" path:path contentType:contentType data:httpData callback:callback];
}


+ (void) send:(NSString*)method path:(NSString*)path contentType:(NSString*)contentType data:(NSData*)data callback:(APICallback)callback {
    if (!server) { [NSException raise:@"MissingServer" format:@"You must do [API setup:@\"https://your.server.com\""]; }

    NSString* url = [server stringByAppendingString:path];

    if ([contentType isEqualToString:@"application/json"]) {
        NSLog(@"API %@ %@ SEND:\n%@", method, url, data.toString);
    } else {
        NSLog(@"API %@ %@ SEND: %d bytes", method, url, data.length);
    }
    NSDictionary* devInterceptRes = [API _devIntercept:path];
    if (devInterceptRes) {
        return dispatch_async(dispatch_get_main_queue(), ^{
            callback(nil, devInterceptRes);
        });
    }
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    request.HTTPMethod = method;
    request.HTTPBody = data;
    request.allHTTPHeaderFields = [API headers:contentType data:data];

    [API showSpinner];
    
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        [API hideSpinner];
        asyncMain(^{
            [API _handleResponse:(NSHTTPURLResponse*)response forMethod:method path:path data:data error:connectionError callback:callback];
        });
    }];
}

+ (void)_handleResponse:(NSHTTPURLResponse*)httpRes forMethod:(NSString*)method path:(NSString*)path data:(NSData*)data error:(NSError*)connectionError callback:(APICallback)callback {
    
    if (connectionError) {
        return callback(connectionError, nil);
    }
    
    NSLog(@"API %@ %@ RECV:\n%@\n\n", method, path, [data toString]);

    NSString* contentType = httpRes.allHeaderFields[@"content-type"];
    NSDictionary* res;
    NSError* err;
    
    if (!contentType) {
        err = makeError([NSString stringWithFormat:@"Missing Content-Type header (%@)", httpRes.allHeaderFields]);
    } else if ([contentType hasPrefix:@"application/json"] || [contentType hasPrefix:@"application/javascript"]) {
        res = [JSON parseData:data error:&err];
    } else if ([contentType hasPrefix:@"text/"]) {
        res = @{ @"text":[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] };
    } else {
        err = makeError([@"Unknown Content-Type: " stringByAppendingString:contentType]);
    }
    
    if (err) {
        NSLog(@"API error %@ %@: %@", method, path, err);
        return callback(err, nil);
    }
    
    for (APIErrorCheck errorCheck in errorChecks) {
        err = errorCheck(httpRes, res);
        if (err) {
            return callback(err, nil);
        }
    }
    
    if (httpRes.statusCode < 200 || httpRes.statusCode >= 300) {
        err = makeError(res[@"text"]);
        return callback(err, nil);
    }
    
    callback(nil, res);
}

+ (NSDictionary*)headers:(NSString*)contentType data:(NSData*)data {
    NSMutableDictionary* headers = [NSMutableDictionary dictionaryWithDictionary:baseHeaders];
    if (uuidHeader) {
        headers[uuidHeader] = [NSString UUID];
    }
    if (contentType) {
        headers[@"Content-Type"] = contentType;
    }
    if (data && data.length) {
        headers[@"Content-Length"] = [num(data.length) stringValue];
    }
    return headers;
}

static NSString* apiSync = @"";
+ (void)showSpinner {
    @synchronized(apiSync) {
        if (numRequests == 0) {
            UIApplication.sharedApplication.networkActivityIndicatorVisible = YES;
        }
        numRequests += 1;
    }
}

+ (void)hideSpinner {
    NSArray* callbacks;
    @synchronized(apiSync) {
        numRequests -= 1;
        if (numRequests == 0) {
            UIApplication.sharedApplication.networkActivityIndicatorVisible = NO;
            callbacks = waitingForCurrentRequests;
            waitingForCurrentRequests = nil;
        }
    }
    for (Block callback in callbacks) {
        callback();
    }
}

static NSMutableArray* waitingForCurrentRequests;
+ (void)waitForCurrentRequests:(Block)callback {
    @synchronized(apiSync) {
        if (numRequests) {
            if (!waitingForCurrentRequests) {
                waitingForCurrentRequests = [NSMutableArray array];
            }
            [waitingForCurrentRequests addObject:[callback copy]];
            return;
        }
    }
    callback();
}

+ (NSDictionary*)_devIntercept:(NSString*)path {
    return nil;
}


@end
