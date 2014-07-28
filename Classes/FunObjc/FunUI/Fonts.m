//
//  Fonts.m
//  Dogo iOS
//
//  Created by Marcus Westin on 10/9/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "Fonts.h"
#import <CoreText/CoreText.h>

@implementation Fonts

+ (BOOL)loadData:(NSData *)fontData {
    BOOL success = YES;
    CFErrorRef error;
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)fontData);
    CGFontRef font = CGFontCreateWithDataProvider(provider);
    if (!CTFontManagerRegisterGraphicsFont(font, &error)) {
        CFStringRef errorDescription = CFErrorCopyDescription(error);
        NSLog(@"Failed to load font: %@", errorDescription);
        CFRelease(errorDescription);
        success = NO;
    }
    CFRelease(font);
    CFRelease(provider);
    return success;
}

+ (UIFont *)bold:(CGFloat)size {
    return [UIFont fontWithName:@"HelveticaNeue-Bold" size:size];
}

+ (UIFont *)medium:(CGFloat)size {
    return [UIFont fontWithName:@"HelveticaNeue-Medium" size:size];
}

+ (UIFont*)regular:(CGFloat)size {
    return [UIFont fontWithName:@"HelveticaNeue" size:size];
}

+ (UIFont*)light:(CGFloat)size {
    return [UIFont fontWithName:@"HelveticaNeue-Light" size:size];
}

+ (UIFont *)lightItalic:(CGFloat)size {
    return [UIFont fontWithName:@"HelveticaNeue-LightItalic" size:size];
}

+ (UIFont *)thin:(CGFloat)size {
    return [UIFont fontWithName:@"HelveticaNeue-Thin" size:size];
}

+ (UIFont *)ultraLight:(CGFloat)size {
    return [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:size];
}
@end
