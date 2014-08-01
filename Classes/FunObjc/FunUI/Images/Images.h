//
//  Images.h
//  Dogo-iOS
//
//  Created by Marcus Westin on 6/26/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIImage+Alpha.h"
#import "UIImage+Resize.h"
#import "UIImage+RoundedCorner.h"
#import "UIImage+Fun.h"
#import "UIImage+ImageEffects.h"
#import "FunBase.h"
#import "AsyncImageView.h"

@interface ImagesLoadObserver : NSObject
- (void) onLoaded:(Block)callback;
@end

@interface Images : NSObject

+ (ImagesLoadObserver*)observeLoadRequests;
+ (void)load:(NSString*)url resize:(CGSize)size radius:(CGFloat)radius callback:(ImageCallback)callback;
+ (void)load:(NSString*)url resize:(CGSize)size callback:(ImageCallback)callback;
+ (UIImage*)getLocal:(NSString*)url resize:(CGSize)size radius:(CGFloat)radius;
+ (UIImage*)getLocal:(NSString*)url;

@end
