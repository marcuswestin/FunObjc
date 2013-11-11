//
//  FunTypes.m
//  Dogo-iOS
//
//  Created by Marcus Westin on 7/13/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import "Overlay.h"
#import "Viewport.h"
#import "UIView+FunStyle.h"
#import "UIControl+Fun.h"
#import "FunTypes.h"
#import "UIColor+Fun.h"
#import "Camera.h"

#include <stdio.h>

void fatal(NSError* err) {
    if (!err) { return; }
    asyncMain(^{
        NSString* message = err.localizedDescription;
        NSLog(@"FATAL %@ %@", message, err);
        UIWindow* overlay = [Overlay showWithTapHandler:^(UITapGestureRecognizer *sender) {
            // Do nothing
        }];
        [UILabel.appendTo(overlay).inset(0,8,0,8).text(message).textColor(RED).wrapText.center render];
    });
}

void error(NSError* err) {
    if (!err) { return; }
    [Camera hide];
    asyncMain(^{
        NSString* message = err.localizedDescription;
        NSLog(@"ERROR %@ %@", message, err);
        UIWindow* overlay = [Overlay show];
        [UILabel.appendTo(overlay).inset(0,8,0,8).text(message).textColor(RED).wrapText.center render];
    });
}

void after(NSTimeInterval delayInSeconds, Block block) {
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), block);
}

void every(NSTimeInterval intervalInSeconds, Block block) {
    after(intervalInSeconds, ^{
        block();
        every(intervalInSeconds, block);
    });
}

void asyncDefault(Block block) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block);
}
void asyncHigh(Block block) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), block);
}
void asyncLow(Block block) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), block);
}
void async(Block block) { asyncMain(block); }
void asyncMain(Block block) {
    dispatch_async(dispatch_get_main_queue(), block);
}
void asyncBackground(Block block) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), block);
}

void vibrateDevice() {
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

NSString* concat(NSString* firstArg, ...) {
    NSMutableString *result = [NSMutableString string];
    va_list args;
    va_start(args, firstArg);
    for (NSString *arg = firstArg; arg != nil; arg = va_arg(args, NSString*)) {
        [result appendString:arg];
    }
    va_end(args);
    return result;
}

void repeat(NSUInteger times, NSUIntegerBlock block) {
    for (NSUInteger i=0; i<times; i++) {
        block(i);
    }
}

NSError* makeError(NSString* localMessage) {
    return [NSError errorWithDomain:@"Global" code:1 userInfo:@{ NSLocalizedDescriptionKey:localMessage }];
}

NSRange NSRangeMake(NSUInteger location, NSUInteger length) {
    return (NSRange){ .location = location, .length = length };
}

NSString* NSStringFromRange(NSRange range) {
    return [NSString stringWithFormat:@"{ .location=%d, .length=%d }", range.location, range.length];
}
