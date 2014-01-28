//
//  Layers.h
//  ivyq
//
//  Created by Marcus Westin on 10/28/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@interface Layers : NSObject

+(CAGradientLayer*) gradientFrom:(UIColor*)colorFrom to:(UIColor*)colorTo;

+(CAGradientLayer*) greyGradient;
+(CAGradientLayer*) blueGradient;

+(CAGradientLayer*) horizontalGradient:(NSArray*)colors;

@end
