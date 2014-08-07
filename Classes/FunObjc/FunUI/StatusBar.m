//
//  StatusBar.m
//  Diary-iOS
//
//  Created by Marcus Westin on 8/3/14.
//  Copyright (c) 2014 Flutterby Labs Inc. All rights reserved.
//

#import "StatusBar.h"
#import "UIView+FunStyle.h"
#import "UIView+Fun.h"
#import "UIColor+Fun.h"
#import "Keyboard.h"

@implementation StatusBar

static UIView* background;
static CGFloat height = 20.0;
static BOOL isHidden;

+ (BOOL)isHidden {
    return isHidden;
}

+ (void)onTap:(EventSubscriber)subscriber callback:(EventCallback)callback {
    [Events on:@"StatusBarTap" subscriber:subscriber callback:callback];
}

+ (void)offTap:(EventSubscriber)subscriber {
    [Events off:@"StatusBarTap" subscriber:subscriber];
}

+ (void)hideWithAnimation:(UIStatusBarAnimation)statusBarAnimationStyle {
    [self setHidden:YES animation:statusBarAnimationStyle];
}
+ (void)showWithAnimation:(UIStatusBarAnimation)statusBarAnimationStyle {
    [self setHidden:NO animation:statusBarAnimationStyle];
}
+ (void)setHidden:(BOOL)hide animation:(UIStatusBarAnimation)statusBarAnimation {
    [[UIApplication sharedApplication] setStatusBarHidden:hide withAnimation:statusBarAnimation];
//    if (hide && ![UIApplication sharedApplication].statusBarHidden) {
//        assert(!@"Add \"View controller-based status bar appearance: NO\" in app plist file.");
//    }
    isHidden = hide;
    CGFloat duration = [Keyboard animationDuration];
    if (hide) {
        [UIView animateWithDuration:duration animations:^{
            switch (statusBarAnimation) {
                case UIStatusBarAnimationNone:
                    background.hidden = YES;
                    break;
                case UIStatusBarAnimationSlide:
                    background.y2 = 0;
                    break;
                case UIStatusBarAnimationFade:
                    background.alpha = 0.0;
                    break;
            }
        }];
    } else {
        background.hidden = NO;
        background.alpha = 1.0;
        background.y = 0;
        switch (statusBarAnimation) {
            case UIStatusBarAnimationNone:
                break;
            case UIStatusBarAnimationFade:
                background.alpha = 0;
                [UIView animateWithDuration:duration animations:^{
                    background.alpha = 1;
                }];
                break;
            case UIStatusBarAnimationSlide:
                background.y2 = 0;
                [UIView animateWithDuration:duration animations:^{
                    background.y = 0;
                }];
                break;
        }
    }
}
+ (void)setContentHidden:(BOOL)hidden animation:(UIStatusBarAnimation)animationStyle {
    [[UIApplication sharedApplication] setStatusBarHidden:hidden withAnimation:animationStyle];
}

+ (UIView *)snapshotViewAfterScreenUpdates:(BOOL)afterUpdates {
    background.hidden = NO;
    background.y = 0;
    background.alpha = 1.0;
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
    UIView* snapshot = [[UIScreen mainScreen] snapshotViewAfterScreenUpdates:YES];
    if (isHidden) {
        background.hidden = YES;
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
    }
    
    UIView* clipper = [[UIView alloc] initWithFrame:[self bounds]];
    clipper.clipsToBounds = YES;
    [clipper addSubview:snapshot];
    return clipper;
}

+ (void)initialize {
    background = [[UIView new].styler.wh([Viewport width], height) render];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
}

+ (void)setupWithRootViewController:(UIViewController*)rootViewController {
    [background appendTo:rootViewController.view];
}

+ (void)setBackgroundColor:(UIColor *)backgroundColor {
    background.backgroundColor = backgroundColor;
}

+ (CGRect)bounds {
    return CGRectMake(0, 0, [Viewport width], 20);
}

+ (UIColor *)backgroundColor {
    return background.backgroundColor;
}

@end
