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

@implementation Fonts

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

static NSString* name = @"HelveticaNeue";

+ (void)setName:(NSString *)newName {
    name = newName;
}

+ (UIFont *)bold:(CGFloat)size {
    return [self fontWithType:@"Bold" size:size];
}

+ (UIFont *)medium:(CGFloat)size {
    return [self fontWithType:@"Medium" size:size];
    return [UIFont fontWithName:@"HelveticaNeue-Medium" size:size];
}

+ (UIFont*)regular:(CGFloat)size {
    return [self fontWithType:@"" size:size];
    return [UIFont fontWithName:@"HelveticaNeue" size:size];
}

+ (UIFont*)light:(CGFloat)size {
    return [self fontWithType:@"Light" size:size];
    return [UIFont fontWithName:@"HelveticaNeue-Light" size:size];
}

+ (UIFont *)lightItalic:(CGFloat)size {
    return [self fontWithType:@"LightItalic" size:size];
    return [UIFont fontWithName:@"HelveticaNeue-LightItalic" size:size];
}

+ (UIFont *)thin:(CGFloat)size {
    return [self fontWithType:@"Thin" size:size];
    return [UIFont fontWithName:@"HelveticaNeue-Thin" size:size];
}

+ (UIFont *)ultraLight:(CGFloat)size {
    return [self fontWithType:@"UltraLight" size:size];
}

+ (UIFont*)fontWithType:(NSString*)type size:(CGFloat)size {
    return [UIFont fontWithName:[NSString stringWithFormat:@"%@-%@", name, type] size:size];
}
@end
