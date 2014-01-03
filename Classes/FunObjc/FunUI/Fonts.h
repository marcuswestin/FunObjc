//
//  Fonts.h
//  Dogo iOS
//
//  Created by Marcus Westin on 10/9/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Fonts : NSObject
+(BOOL)loadData:(NSData*)fontData;
+(UIFont*)bold:(CGFloat)size;
+(UIFont*)medium:(CGFloat)size;
+(UIFont*)regular:(CGFloat)size;
+(UIFont*)light:(CGFloat)size;
+(UIFont*)thin:(CGFloat)size;
+(UIFont*)ultraLight:(CGFloat)size;
@end
