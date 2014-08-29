//
//  UIControl+Fun.m
//  Dogo-iOS
//
//  Created by Marcus Westin on 6/27/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "UIControl+Fun.h"
#import "NSArray+Fun.h"
#import "FunGlobals.h"
#import "FunRuntimeProperties.h"
#import "UIView+Fun.h"

static NSString* KeyOnEditingChanged = @"Fun_OnEditingChanged";
static NSString* KeyOnTap = @"Fun_OnTap";
static NSString* KeyHandlers = @"Fun_Handlers";
static NSString* KeyBlock = @"Fun_Block";
static NSString* KeyTapHandler = @"Fun_TapHandler";
static NSString* KeyPanHandler = @"Fun_PanHandler";
static NSString* KeyTextDidChange = @"FunKeyTextDidChange";
static NSString* KeyTextShouldChance = @"FunKeyTextShouldChange";
static NSString* KeySelectionChange = @"FunKeySelectionChange";

/* UI View
 *********/
@implementation UIView (UIControlFun)
- (id)_addFunGesture:(Class)cls Key:(NSString*)Key selector:(SEL)selector handler:(id)handler {
    SetPropertyCopy(self, Key, handler);
    id instance = [[cls alloc] initWithTarget:self action:selector];
    [self addGestureRecognizer:instance];
    return instance;
}
// Tap Gesture
- (UITapGestureRecognizer*)onTap:(TapHandler)handler {
    return [self onTapNumber:1 withTouches:1 handler:handler];
}
- (UITapGestureRecognizer *)onTap:(id)target selector:(SEL)selector {
    UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:target action:selector];
    [self addGestureRecognizer:tap];
    return tap;
}
- (UITapGestureRecognizer*)onTapNumber:(NSUInteger)numberOfTapsRequires withTouches:(NSUInteger)numberOfTouchesRequired handler:(TapHandler)handler {
    UITapGestureRecognizer* tap = [self _addFunGesture:UITapGestureRecognizer.class Key:KeyTapHandler selector:@selector(_handleFunTap:) handler:handler];
    tap.numberOfTapsRequired = numberOfTapsRequires;
    tap.numberOfTouchesRequired = numberOfTouchesRequired;
    self.userInteractionEnabled = YES;
    return tap;
}
- (void) _handleFunTap:(UITapGestureRecognizer*)sender {
//    if (sender.state != UIGestureRecognizerStateEnded) { return; }
    ((TapHandler)GetProperty(self, KeyTapHandler))(sender);
}
// Pan Gesture
- (UIPanGestureRecognizer*)onPan:(PanHandler)handler {
    UIPanGestureRecognizer* pan = [self _addFunGesture:UIPanGestureRecognizer.class Key:KeyPanHandler selector:@selector(_handleFunPan:) handler:handler];
    return pan;
}
- (void) _handleFunPan:(UIPanGestureRecognizer*)sender {
    ((PanHandler)GetProperty(self, KeyPanHandler))(sender);
}
@end

/* UIButton
 **********/
@implementation UIButton (UIControlFun)
- (void)setTitle:(NSString *)title {
    [self setTitle:title forState:UIControlStateNormal];
}
- (void)setTitleColor:(UIColor *)color {
    [self setTitleColor:color forState:UIControlStateNormal];
}
@end

/* UIControls
 ************/
@implementation UIControlHandler
- (void)_handle:(id)target event:(UIEvent*)event {
    _handler(event);
}
@end
@implementation UIControl (UIControlFun)
- (void)onChange:(EventHandler)handler {
    [self on:UIControlEventEditingChanged handler:handler];
}
- (void)onTap:(EventHandler)handler {
    [self on:UIControlEventTouchUpInside handler:handler];
}
- (void)onTouchDown:(EventHandler)handler {
    [self on:UIControlEventTouchDown handler:handler];
}
- (void)onTouchUp:(EventHandler)handler {
    [self on:UIControlEventTouchUpInside handler:handler];
}
- (void)onTouchUpOutside:(EventHandler)handler {
    [self on:UIControlEventTouchUpOutside handler:handler];
}
- (void)onFocus:(EventHandler)handler {
    [self on:UIControlEventEditingDidBegin handler:handler];
}
- (void)onBlur:(EventHandler)handler {
    [self on:UIControlEventEditingDidEnd handler:handler];
}
- (void)on:(UIControlEvents)controlEvents handler:(EventHandler)handler {
    NSMutableArray* handlers = GetProperty(self, KeyHandlers);
    if (!handlers) {
        handlers = [NSMutableArray array];
        SetProperty(self, KeyHandlers, handlers);
    }
    
    UIControlHandler* controlHandler = [UIControlHandler new];
    controlHandler.handler = handler;
    [handlers addObject:controlHandler];
    
    [self addTarget:controlHandler action:@selector(_handle:event:) forControlEvents:controlEvents];
}
@end

/* UITextViews
 *************/
@implementation UITextView (UIControlFun)

- (void)onTextDidChange:(TextViewBlock)handler {
    [self _addHandlerForKey:KeyTextDidChange handler:handler];
}
- (void)textViewDidChange:(UITextView *)textView {
    [[self _handlersForKey:KeyTextDidChange] each:^(TextViewBlock handler, NSUInteger i) {
        handler(textView);
    }];
}
- (void)onEnter:(TextViewBlock)handler {
    [self onTextShouldChange:^BOOL(UITextView *textView, NSRange range, NSString *replacementText) {
        if ([replacementText isEqualToString:@"\n"]) {
            handler(textView);
            return NO;
        }
        return YES;
    }];
}
- (void)onTextShouldChange:(TextViewShouldChangeBlock)handler {
    [self _addHandlerForKey:KeyTextShouldChance handler:handler];
}
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    __block BOOL shouldChange = YES;
    [[self _handlersForKey:KeyTextShouldChance] each:^(TextViewShouldChangeBlock val, NSUInteger i) {
        shouldChange = val(textView, range, text) && shouldChange;
    }];
    return shouldChange;
}

- (void)onSelectionDidChange:(TextViewBlock)handler {
    [self _addHandlerForKey:KeySelectionChange handler:handler];
}
- (void)textViewDidChangeSelection:(UITextView *)textView {
    [[self _handlersForKey:KeySelectionChange] each:^(TextViewBlock handler, NSUInteger i) {
        handler(textView);
    }];
}

- (void) _addHandlerForKey:(NSString*)Key handler:(id)handler {
    if (self.delegate && self.delegate != self) {
        [NSException raise:@"BadDelegate" format:@"Delegate already set"];
    }
    self.delegate = self;
    NSMutableArray* handlers = GetProperty(self, Key);
    if (!handlers) { handlers = [NSMutableArray array]; }
    [handlers addObject:handler];
    SetProperty(self, Key, handlers);
}
- (NSArray*)_handlersForKey:(NSString*)Key {
    return GetProperty(self, Key);
}

@end