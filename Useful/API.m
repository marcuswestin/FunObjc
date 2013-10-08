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
+ (instancetype)json:(NSDictionary *)obj {
    return [Multipart withContent:obj.toJsonData type:@"application/json" disposition:@"form-data; name=\"jsonParams\""];
}
+ (instancetype)jpg:(UIImage *)image quality:(CGFloat)quality {
    return [Multipart withContent:UIImageJPEGRepresentation(image, quality) type:@"image/jpg" disposition:@"form-data; filename=\"image.jpg\"; name=\"image\""];
}
+ (instancetype)png:(UIImage *)image {
    return [Multipart withContent:UIImagePNGRepresentation(image) type:@"image/png" disposition:@"form-data; filename=\"image.png\"; name=\"image\""];
}
+ (instancetype)avi:(NSString *)path {
    NSData* data = [NSData dataWithContentsOfFile:path];
    return [Multipart withContent:data type:@"video/avi" disposition:@"form-data; filename=\"video.mov\"; name=\"video\""];
}
+ (instancetype)m4a:(NSString *)path {
    NSData* data = [NSData dataWithContentsOfFile:path];
    return [Multipart withContent:data type:@"audio/mp4a-latm" disposition:@"form-data; filename=\"audio.m4a\"; name=\"audio\""];
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

+ (void)post:(NSString *)path json:(NSDictionary *)json callback:(APICallback)callback {
    [self send:@"POST" path:path contentType:@"application/json" data:json.toJsonData callback:callback];
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

    if ([contentType isEqualToString:@"application/json"]) {
        NSLog(@"API %@ %@ SEND:\n%@", method, path, data.toString);
    } else {
        NSLog(@"API %@ %@ SEND", method, path);
    }
    NSDictionary* devInterceptRes = [API _devIntercept:path];
    if (devInterceptRes) {
        return dispatch_async(dispatch_get_main_queue(), ^{
            callback(nil, devInterceptRes);
        });
    }
    
    if (!server) { [NSException raise:@"MissingServer" format:@"You must do [API setup:@\"https://your.server.com\""]; }
    NSString* url = [server stringByAppendingString:path];
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
    if (contentType) {
        headers[@"content-type"] = contentType;
    }
    if (data && data.length) {
        headers[@"content-length"] = [num(data.length) stringValue];
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
