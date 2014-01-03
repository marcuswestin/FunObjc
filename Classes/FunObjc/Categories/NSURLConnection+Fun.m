//
//  NSURLConnection+Fun.m
//  Dogo iOS
//
//  Created by Marcus Westin on 12/22/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "NSURLConnection+Fun.h"
#import <objc/runtime.h>
#import "FunBase.h"

@interface Net ()
@property (copy) NetCompletionBlock completion;
@property (copy) NetProgressBlock uploadProgress;
@property (copy) NetProgressBlock downloadProgress;
@property NSURLResponse* response;
@property NSMutableData* data;
@end

@implementation Net

+ (void)request:(NSURLRequest *)request uploadProgress:(NetProgressBlock)uploadProgressBlock downloadProgress:(NetProgressBlock)downloadProgressBlock completion:(NetCompletionBlock)completionBlock {
    asyncMain(^{
        Net* net = [Net new];
        net.uploadProgress = uploadProgressBlock;
        net.downloadProgress = downloadProgressBlock;
        net.completion = completionBlock;
        [[[NSURLConnection alloc] initWithRequest:request delegate:net] start];
    });
}

#pragma mark NSURLConnectionDelegate

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    _completion(_response, _data, nil);
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    _completion(nil, nil, error);
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response {
    _response = response;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    if (!_data) {
        _data = [NSMutableData dataWithCapacity:(NSUInteger)_response.expectedContentLength];
    }
    
    [_data appendData:data];
    if (_response.expectedContentLength != NSURLResponseUnknownLength) {
        if (_downloadProgress) {
            _downloadProgress(_data.length / _response.expectedContentLength);
        }
    }
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
    if (_uploadProgress) {
        _uploadProgress(totalBytesWritten/totalBytesExpectedToWrite);
    }
}

@end