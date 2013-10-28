//
//  UIImage+Fun.m
//  PonyDebugger
//
//  Created by Marcus Westin on 9/2/13.
//
//

#import "UIImage+Fun.h"

@implementation UIImage (Fun)

+ (UIImage *)radialGradientWithSize:(CGSize)size fromColor:(UIColor*)fromColor toColor:(UIColor*)toColor  x:(CGFloat)x y:(CGFloat)y radius:(CGFloat)radius {
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    size_t gradLocationsNum = 2;
    CGFloat gradLocations[2] = {0.0f, 1.0f};
    const CGFloat *from = CGColorGetComponents(fromColor.CGColor);
    const CGFloat *to = CGColorGetComponents(toColor.CGColor);
    CGFloat gradColors[8] = {from[0],from[1],from[2],from[3],to[0],to[1],to[2],to[3]};
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, gradColors, gradLocations, gradLocationsNum);
    CGColorSpaceRelease(colorSpace);
    
    CGPoint gradCenter = CGPointMake(x,y);
    CGContextDrawRadialGradient (context, gradient, gradCenter, 0, gradCenter, radius, kCGGradientDrawsAfterEndLocation);
    
    UIImage* result = UIGraphicsGetImageFromCurrentImageContext();
    
    CGGradientRelease(gradient);
    
    UIGraphicsEndImageContext();
    return result;
}

- (UIImage *)maskWithColor:(UIColor *)tintColor {
    CGRect aRect = CGRectMake(0.f, 0.f, self.size.width, self.size.height);
    CGImageRef alphaMask;
    UIImage *img;
    
    // Compute mask
    {
        UIGraphicsBeginImageContextWithOptions(aRect.size, NO, 2.0);
        CGContextRef c = UIGraphicsGetCurrentContext();
        // draw image
        CGContextTranslateCTM(c, 0, aRect.size.height);
        CGContextScaleCTM(c, 1.0, -1.0);
        [self drawInRect: aRect];
        img = UIGraphicsGetImageFromCurrentImageContext();
        alphaMask = CGBitmapContextCreateImage(c);
        
        UIGraphicsEndImageContext();
    }
    
    // Tint mask
    {
        UIGraphicsBeginImageContextWithOptions(self.size, NO, 2.0);
        CGContextRef c = UIGraphicsGetCurrentContext();
        // Mask it
        CGContextClipToMask(c, aRect, alphaMask);
        // Set the fill color
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextSetFillColorSpace(c, colorSpace);
        CGContextSetFillColorWithColor(c, tintColor.CGColor);
        // Fill it
        UIRectFillUsingBlendMode(aRect, kCGBlendModeNormal);
        // Done
        img = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        // Release memory
        CGColorSpaceRelease(colorSpace);
        CGImageRelease(alphaMask);
    }
    
    return img;
}

@end
