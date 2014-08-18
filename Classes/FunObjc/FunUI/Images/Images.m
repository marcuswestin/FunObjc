//
//  Images.m
//  Dogo-iOS
//
//  Created by Marcus Westin on 6/26/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "Images.h"

static NSMutableSet* imageLoadObservers;

@interface ImagesLoadObserver ()
@property (copy) Block callback;
@property NSMutableSet* urls;
@end
@implementation ImagesLoadObserver
- (void)onLoaded:(Block)callback {
    if ([_urls count] == 0) {
        [imageLoadObservers removeObject:self];
        asyncMain(callback);
    } else {
        _callback = callback;
    }
}
@end

@implementation Images

static NSOperationQueue* queue;
static NSMutableDictionary* loading;
static NSMutableDictionary* processing;
static CGSize noResize;
static NSUInteger noRadius;
static NSString* cacheKeyBase;

+ (void)load {
    loading = [NSMutableDictionary dictionary];
    processing = [NSMutableDictionary dictionary];
    queue = [[NSOperationQueue alloc] init];
    imageLoadObservers = [NSMutableSet set];
    queue.maxConcurrentOperationCount = 10;
    noResize = CGSizeMake(0,0);
    noRadius = 0;
    
    cacheKeyBase = @"FunImgs";
}

+ (ImagesLoadObserver *)observeLoadRequests {
    ImagesLoadObserver* observer = [ImagesLoadObserver new];
    observer.urls = [NSMutableSet set];
    [imageLoadObservers addObject:observer];
    return observer;
}

+ (UIImage *)getLocal:(NSString *)url resize:(CGSize)resize radius:(CGFloat)radius {
    NSData* data = [Files readCache:[self _cacheKeyFor:url resize:resize radius:radius]];
    return (data ? [UIImage imageWithData:data] : nil);
}

+ (UIImage *)getLocal:(NSString *)url {
    return [self getLocal:url resize:noResize radius:noRadius];
}

+ (void)load:(NSString *)url resize:(CGSize)size callback:(ImageCallback)callback {
    [Images load:url resize:size radius:0 callback:callback];
}

+ (void)load:(NSString *)url resize:(CGSize)resize radius:(CGFloat)radius callback:(ImageCallback)_callback {
    // Processed cached
    ImageCallback callback = ^(NSError *err, UIImage *image) {
        asyncMain(^{
            _callback(err, image);
            NSMutableArray* clean = [NSMutableArray array];
            for (ImagesLoadObserver* observer in imageLoadObservers) {
                if ([observer.urls containsObject:url]) {
                    [observer.urls removeObject:url];
                    if ([observer.urls count] == 0) {
                        observer.callback();
                        [clean addObject:observer];
                    }
                }
            }
            for (ImagesLoadObserver* observer in clean) {
                [imageLoadObservers removeObject:observer];
            }
        });
    };
    
    for (ImagesLoadObserver* observer in imageLoadObservers) {
        [observer.urls addObject:url];
    }
    
    asyncHigh(^{
        NSData* processedData = [Files readCache:[self _cacheKeyFor:url resize:resize radius:radius]];
        if (processedData) {
            callback(nil, [UIImage imageWithData:processedData]);
            return;
        }

        // Original cached
        NSString* originalKey = [self _cacheKeyFor:url resize:noResize radius:noRadius];
        NSData* originalData = [Files readCache:originalKey];
        if (originalData) {
            [self _processAndCache:url data:originalData resize:resize radius:radius callback:callback];
            return;
        }
    
        // Fetch from network
        [API showSpinner];
        [self _fetch:url cacheKey:originalKey callback:^(id err, NSData* data) {
            [API hideSpinner];
            if (err) { return callback(err,nil); }
            
            // Multiple load calls could have been made for the same un-fetched image with the same processing parameters
            NSData* processedData = [Files readCache:[self _cacheKeyFor:url resize:resize radius:radius]];
            if (processedData) {
                callback(nil, [UIImage imageWithData:processedData]);
                return;
            }
            
            return [self _processAndCache:url data:data resize:resize radius:radius callback:callback];
        }];
    });
}

+ (void)_fetch:(NSString*)url cacheKey:(NSString*)key callback:(DataCallback)callback {
    if (url.isNull) { return callback(makeError(@"Bad URL"), nil); }
    @synchronized(loading) {
        if (loading[url]) {
            [loading[url] addObject:callback];
            return;
        }
        loading[url] = [NSMutableArray arrayWithObject:callback];
    }
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    [Net request:request uploadProgress:nil downloadProgress:nil completion:^(NSURLResponse *response, NSData *data, NSError *networkError) {
        if (networkError) {
            return [self _onFetched:url error:networkError data:nil];
        }
        if (!data || !data.length) {
            return [self _onFetched:url error:makeError(@"Error getting image") data:nil];
        }
        
        if (![response.MIMEType startsWith:@"image/"]) {
            return [self _onFetched:url error:makeError(@"Non-image response") data:nil];
        }
        
        [Files writeCache:key data:data];
        
        [self _onFetched:url error:nil data:data];
    }];
}

+ (void) _onFetched:(NSString*)url error:(NSError*)error data:(NSData*)data {
//    DLog(@"Fetched %@ %@ %d", url, error, (data ? data.length : -1));
    NSArray* callbacks;
    @synchronized(loading) {
        callbacks = loading[url];
        [loading removeObjectForKey:url];
    }
    for (DataCallback callback in callbacks) {
        callback(error, data);
    }
}

+ (void) _processAndCache:(NSString*)url data:(NSData*)data resize:(CGSize)resize radius:(CGFloat)radius callback:(ImageCallback)callback {
    if (data == nil || data.length == 0 || [data isNull]) {
        callback(makeError(@"No image found"), nil);
        return;
    }
    UIImage* image = [UIImage imageWithData:data];
    if (!image) {
        return;
    }
    if (resize.width || resize.height || radius) {
        image = [image thumbnailSize:CGSizeMake(resize.width*2, resize.height*2) transparentBorder:0 cornerRadius:radius interpolationQuality:kCGInterpolationDefault];

        NSData* processedData = (radius
                                ? UIImagePNGRepresentation(image) // Radius requires PNG transparency
                                 : UIImageJPEGRepresentation(image, 1.0));

        [Files writeCache:[self _cacheKeyFor:url resize:resize radius:radius] data:processedData];
    }
    
    callback(nil, image);
}

+ (NSString*)_cacheKeyFor:(NSString*)url resize:(CGSize)resize radius:(CGFloat)radius {
    NSString* ext = (radius ? @"png" : @"jpg");
    NSString* name = [NSString stringWithFormat:@"%@url%@resize%@radius%f.%@", cacheKeyBase, url, NSStringFromCGSize(resize), radius, ext];
    return [Files sanitizeName:name];
}

@end
