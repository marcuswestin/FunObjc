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

+ (UIFont *)medium:(CGFloat)size {
    return [UIFont fontWithName:@"HelveticaNeue-Medium" size:size];
}

+ (UIFont*)light:(CGFloat)size {
    return [UIFont fontWithName:@"HelveticaNeue-Light" size:size];
}

+ (UIFont *)thin:(CGFloat)size {
    return [UIFont fontWithName:@"HelveticaNeue-Thin" size:size];
}
@end
