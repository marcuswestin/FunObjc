//
//  FunTypes.m
//  Dogo-iOS
//
//  Created by Marcus Westin on 7/13/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import "Viewport.h"
#import "UIView+FunStyle.h"
#import "UIControl+Fun.h"
#import "FunBase.h"
#import "UIColor+Fun.h"
#import "Overlay.h"
#import "FunAppDelegate.h"

#include <stdio.h>

void fatal(NSError* err) {
    if (!err) { return; }
    NSString* message = err.localizedDescription;
    DLog(@"Fatal error %@ %@", message, err);
    abort();
}

static UIView* errorView;

void error(NSError* err) {
    if (!err) { return; }
    DLog(@"ERROR %@ %@", err.localizedDescription, err);
    asyncMain(^{
        Class cameraClass = NSClassFromString(@"Camera");
        if (cameraClass) {
            [cameraClass hide];
        }
        UIView* navView = [FunAppDelegate instance].window.rootViewController.view;
        UIView* __block view;
        if (errorView) {
            view = errorView;
        } else {
            view = errorView = [UIView.appendTo(navView).bg(RED) render];
        }
        [view empty];
        
        NSString* message = err.localizedDescription;
        UILabel* label = [UILabel.appendTo(view).text(message).textColor(WHITE).insetSides(8).wrapText render];
        
        Block hide = ^{
            if (!view) { return; }
            [UIView animateWithDuration:.5 animations:^{
                view.y2 = 0;
            }];
            view = nil;
        };
        
        [view containSubviewsVertically];
        view.height += 32;
        [label.styler.fromBottom(8) apply];
        view.y2 = 0;
        [UIView animateWithDuration:.5 animations:^{
            view.y = 0;
            after(30, ^{
                hide();
            });
        }];
        [view onTap:hide];
    });
}

void after(NSTimeInterval delayInSeconds, Block block) {
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), block);
}

void every(NSTimeInterval intervalInSeconds, StopBlock block) {
    after(intervalInSeconds, ^{
        BOOL stop = NO;
        block(&stop);
        if (!stop) {
            every(intervalInSeconds, block);
        }
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
    return [NSString stringWithFormat:@"{ .location=%lu, .length%lu }", (unsigned long)range.location, (unsigned long) range.length];
}
