//
//  UIControl+Fun.h
//  Dogo-iOS
//
//  Created by Marcus Westin on 6/27/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^EventHandler)(UIEvent* event);

typedef void (^TapHandler)(UITapGestureRecognizer* tap);
typedef void (^PanHandler)(UIPanGestureRecognizer* pan);

@interface UIView (UIControlFun)
- (UITapGestureRecognizer*) onTap:(TapHandler)handler DEPRECATED_ATTRIBUTE;
- (UITapGestureRecognizer*) onTap:(id)target selector:(SEL)selector;
- (UIPanGestureRecognizer*) onPan:(PanHandler)handler;
@end

@interface UIButton (UIControlFun)
- (void)setTitle:(NSString *)title;
- (void)setTitleColor:(UIColor *)color;
@end

@interface UIControlHandler : NSObject
@property (strong) EventHandler handler;
@end

@interface UIControl (UIControlFun)
- (void) onChange:(EventHandler)handler;
- (void) onTap:(EventHandler)handler DEPRECATED_ATTRIBUTE;
- (void)onTap:(id)target selector:(SEL)selector;
- (void)onTouchDown:(EventHandler)handler;
- (void)onTouchUp:(EventHandler)handler;
- (void)onTouchUpOutside:(EventHandler)handler;
- (void)onFocus:(EventHandler)handler;
- (void)onBlur:(EventHandler)handler;
- (void) on:(UIControlEvents)controlEvents handler:(EventHandler)handler;
@end

typedef BOOL (^TextViewShouldChangeBlock)(UITextView* textView, NSRange range, NSString* replacementText);
typedef void (^TextViewBlock)(UITextView* textView);
@interface UITextViewDelegate : NSObject <UITextViewDelegate>
@end
@interface UITextView (UIControlFun) <UITextViewDelegate>
- (void) onTextDidChange:(TextViewBlock)handler;
- (void) onEnter:(TextViewBlock)handler;
- (void) onTextShouldChange:(TextViewShouldChangeBlock)handler;
- (void) onSelectionDidChange:(TextViewBlock)handler;
@end

// Prevent emojis:
//- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
//    
//    if (!(([text isEqualToString:@""]))) {//not a backspace
//        unichar unicodevalue = [text characterAtIndex:0];
//        if (unicodevalue == 55357) {
//            return NO;
//        }
//    }
//}
