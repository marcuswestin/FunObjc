//
//  API.m
//  Dogo-iOS
//
//  Created by Marcus Westin on 6/27/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "FunObjc.h"

#define log NSLog

@implementation Multipart
static NSString* multipartJsonName = @"json";
static NSString* multipartImageName = @"image";
static NSString* multipartVideoName = @"video";
static NSString* multipartAudioName = @"audio";

+ (void)setMultipartNamesJson:(NSString *)jsonName image:(NSString *)imageName video:(NSString *)videoName audio:(NSString *)audioName {
    multipartJsonName = jsonName;
    multipartImageName = imageName;
    multipartVideoName = videoName;
    multipartAudioName = audioName;
}

+ (instancetype)json:(NSDictionary *)obj {
    return [Multipart withContent:[JSON serialize:obj] type:@"application/json" disposition:@"form-data; name=\"json\""];
}
+ (instancetype)jpg:(UIImage *)image quality:(CGFloat)quality {
    NSString* disposition = [NSString stringWithFormat:@"form-data; filename=\"%@.jpg\"; name=\"%@\"", multipartImageName, multipartImageName];
    return [Multipart withContent:UIImageJPEGRepresentation(image, quality) type:@"image/jpg" disposition:disposition];
}
+ (instancetype)png:(UIImage *)image {
    NSString* disposition = [NSString stringWithFormat:@"form-data; filename=\"%@.png\"; name=\"%@\"", multipartImageName, multipartImageName];
    return [Multipart withContent:UIImagePNGRepresentation(image) type:@"image/png" disposition:disposition];
}
+ (instancetype)avi:(NSString *)path {
    NSString* disposition = [NSString stringWithFormat:@"form-data; filename=\"%@.mov\"; name=\"%@\"", multipartVideoName, multipartVideoName];
    NSData* data = [NSData dataWithContentsOfFile:path];
    return [Multipart withContent:data type:@"video/avi" disposition:disposition];
}
+ (instancetype)m4a:(NSString *)path {
    NSString* disposition = [NSString stringWithFormat:@"form-data; filename=\"%@.m4a\"; name=\"%@\"", multipartAudioName, multipartAudioName];
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

+ (void)load {
    baseHeaders = [NSMutableDictionary dictionary];
    errorChecks = [NSMutableArray array];
    multipartBoundary = @"_____FUNOBJ_BNDRY__";
    queue = [[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = 10;
    errorChecks = [NSMutableArray array];
}

+ (void)addErrorCheck:(APIErrorCheck)errorCheck {
    [errorChecks addObject:errorCheck];
}

+ (void)setup:(NSString *)serverUrl {
    server = serverUrl;
}

+ (void)setHeaders:(NSDictionary *)headers {
    for (NSString* name in headers) {
        baseHeaders[name] = headers[name];
    }
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
        [httpData appendData:[[NSString stringWithFormat:@"Content-Length: %u\r\n", part.contentData.length] dataUsingEncoding:NSUTF8StringEncoding]];
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
    NSString* url = [server stringByAppendingString:path];

    if ([contentType isEqualToString:@"application/json"]) {
        NSLog(@"API %@ %@ SEND:\n%@", method, url, data.toString);
    } else {
        NSLog(@"API %@ %@ SEND", method, url);
    }
    NSDictionary* devInterceptRes = [API _devIntercept:path];
    if (devInterceptRes) {
        return dispatch_async(dispatch_get_main_queue(), ^{
            callback(nil, devInterceptRes);
        });
    }
    
    if (!server) { [NSException raise:@"MissingServer" format:@"You must do [API setup:@\"https://your.server.com\""]; }
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    request.HTTPMethod = method;
    request.HTTPBody = data;
    request.allHTTPHeaderFields = [API headers:contentType data:data];

    [API _showSpinner];
    
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        
        asyncMain(^{
            [API _handleResponse:(NSHTTPURLResponse*)response forMethod:method path:path data:data error:connectionError callback:callback];
        });
    }];
}

+ (void)_handleResponse:(NSHTTPURLResponse*)httpRes forMethod:(NSString*)method path:(NSString*)path data:(NSData*)data error:(NSError*)connectionError callback:(APICallback)callback {
    
    [API _hideSpinner];
    
    if (connectionError) {
        return callback(connectionError, nil);
    }
    
    NSLog(@"API %@ %@ RECV:\n%@\n\n", method, path, [data toString]);

    NSString* contentType = httpRes.allHeaderFields[@"content-type"];
    NSDictionary* res;
    NSError* err;
    
    if (!contentType) {
        err = makeError(@"Missing Content-Type header");
    } else if ([contentType hasPrefix:@"application/json"] || [contentType hasPrefix:@"application/javascript"]) {
        
        res = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
    } else if ([contentType hasPrefix:@"text/"]) {
        res = @{ @"text":[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] };
    } else {
        err = makeError([@"Unknown Content-Type: " stringByAppendingString:contentType]);
    }
    
    if (err) {
        return callback(err, nil);
    }
    
    for (APIErrorCheck errorCheck in errorChecks) {
        err = errorCheck(httpRes, res);
        if (err) {
            return callback(err, nil);
        }
    }
    
    if (httpRes.statusCode < 200 && httpRes.statusCode >= 300) {
        err = makeError([NSString stringWithFormat:@"API received non-200 status code: %d", httpRes.statusCode]);
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

+ (void)_showSpinner {
    @synchronized(self) {
        if (numRequests == 0) {
            UIApplication.sharedApplication.networkActivityIndicatorVisible = YES;
        }
        numRequests += 1;
    }
}

+ (void)_hideSpinner {
    @synchronized(self) {
        numRequests -= 1;
        if (numRequests == 0) {
            UIApplication.sharedApplication.networkActivityIndicatorVisible = NO;
        }
    }
}

+ (NSDictionary*)_devIntercept:(NSString*)path {
    return nil;
}

@end
