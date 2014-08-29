//
//  Fonts.h
//  Dogo iOS
//
//  Created by Marcus Westin on 10/9/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Fonts : NSObject
+(BOOL)loadFromResource:(NSString *)resourceName ofType:(NSString *)type;
+(BOOL)loadData:(NSData*)fontData;
+(void)setName:(NSString*)name;

+(Fonts*)secondary;
+(void)setSecondaryName:(NSString*)name;

+(Fonts*)brand;
+(void)setBrandName:(NSString*)name;

+(UIFont*)bold:(CGFloat)size;
+(UIFont*)medium:(CGFloat)size;
+(UIFont*)regular:(CGFloat)size;
+(UIFont*)light:(CGFloat)size;
+(UIFont*)lightItalic:(CGFloat)size;
+(UIFont*)thin:(CGFloat)size;
+(UIFont*)ultraLight:(CGFloat)size;
+(UIFont*)heavy:(CGFloat)size;
+(UIFont*)black:(CGFloat)size;
+(UIFont*)book:(CGFloat)size;

-(UIFont*)bold:(CGFloat)size;
-(UIFont*)medium:(CGFloat)size;
-(UIFont*)regular:(CGFloat)size;
-(UIFont*)light:(CGFloat)size;
-(UIFont*)lightItalic:(CGFloat)size;
-(UIFont*)thin:(CGFloat)size;
-(UIFont*)ultraLight:(CGFloat)size;
-(UIFont*)heavy:(CGFloat)size;
-(UIFont*)black:(CGFloat)size;
-(UIFont*)book:(CGFloat)size;@end
