//
//  Fonts.m
//  Dogo iOS
//
//  Created by Marcus Westin on 10/9/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "Fonts.h"
#import "FunBase.h"
#import <CoreText/CoreText.h>

@interface Fonts ()
@property NSString* name;
@end

@implementation Fonts

+ (BOOL)loadFromResource:(NSString *)resourceName ofType:(NSString *)type {
    return [Fonts loadData:[Files readResource:resourceName ofType:type]];
}

+ (BOOL)loadData:(NSData *)fontData {
    BOOL success = YES;
    CFErrorRef error;
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)fontData);
    CGFontRef font = CGFontCreateWithDataProvider(provider);
    if (!CTFontManagerRegisterGraphicsFont(font, &error)) {
        CFStringRef errorDescription = CFErrorCopyDescription(error);
        DLog(@"Failed to load font: %@", errorDescription);
        CFRelease(errorDescription);
        success = NO;
    }
    CFRelease(font);
    CFRelease(provider);
    return success;
}

static Fonts* primary;
static Fonts* secondary;
static Fonts* brand;

+ (void)load {
    primary = [Fonts new];
    primary.name = @"HelveticaNeue";
    secondary = [Fonts new];
    secondary.name = @"GillSans";
    brand = [Fonts new];
}

+ (Fonts *)secondary {
    return secondary;
}

+ (Fonts *)brand {
    return brand;
}

+ (void)setName:(NSString *)name {
    primary.name = name;
}

+ (void)setSecondaryName:(NSString *)name {
    secondary.name = name;
}

+ (void)setBrandName:(NSString *)name {
    brand.name = name;
}

+ (UIFont *)heavy:(CGFloat)size {
    return [primary fontWithType:@"Heavy" size:size];
}

+ (UIFont *)black:(CGFloat)size {
    return [primary fontWithType:@"Black" size:size];
}

+ (UIFont *)bold:(CGFloat)size {
    return [primary fontWithType:@"Bold" size:size];
}

+ (UIFont *)medium:(CGFloat)size {
    return [primary fontWithType:@"Medium" size:size];
}

+ (UIFont*)regular:(CGFloat)size {
    return [primary fontWithType:nil size:size];
}

+ (UIFont*)light:(CGFloat)size {
    return [primary fontWithType:@"Light" size:size];
}

+ (UIFont *)lightItalic:(CGFloat)size {
    return [primary fontWithType:@"LightItalic" size:size];
}

+ (UIFont *)book:(CGFloat)size {
    return [primary fontWithType:@"Book" size:size];
}

+ (UIFont *)thin:(CGFloat)size {
    return [primary fontWithType:@"Thin" size:size];
}

+ (UIFont *)ultraLight:(CGFloat)size {
    return [primary fontWithType:@"UltraLight" size:size];
}

- (UIFont *)heavy:(CGFloat)size {
    return [self fontWithType:@"Heavy" size:size];
}

- (UIFont *)black:(CGFloat)size {
    return [self fontWithType:@"Black" size:size];
}

- (UIFont *)bold:(CGFloat)size {
    return [self fontWithType:@"Bold" size:size];
}

- (UIFont *)medium:(CGFloat)size {
    return [self fontWithType:@"Medium" size:size];
}

- (UIFont*)regular:(CGFloat)size {
    return [self fontWithType:nil size:size];
}

- (UIFont*)light:(CGFloat)size {
    return [self fontWithType:@"Light" size:size];
}

- (UIFont *)lightItalic:(CGFloat)size {
    return [self fontWithType:@"LightItalic" size:size];
}

- (UIFont *)book:(CGFloat)size {
    return [self fontWithType:@"Book" size:size];
}

- (UIFont *)thin:(CGFloat)size {
    return [self fontWithType:@"Thin" size:size];
}

- (UIFont *)ultraLight:(CGFloat)size {
    return [self fontWithType:@"UltraLight" size:size];
}

- (UIFont*)fontWithType:(NSString*)type size:(CGFloat)size {
    NSString* fontName = [NSString stringWithFormat:@"%@%@%@", _name, type ? @"-" : @"", type ? type : @""];
    UIFont* font = [UIFont fontWithName:fontName size:size];
    if (!font) {
        fatal(makeError([NSString stringWithFormat:@"Font not vailable: %@ %f", fontName, size]));
    }
    return font;
}

@end
