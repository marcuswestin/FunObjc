//
//  DefaultStyles.m
//  ivyq
//
//  Created by Marcus Westin on 9/25/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "DefaultStyles.h"
#import <QuartzCore/QuartzCore.h>

// Base Default style class
///////////////////////////
@implementation DefaultStyles
- (void)applyTo:(UIView *)view {}
@end

// UIView
/////////
DeclareClassDefaultStyles(UIView, UIViewStyles, uiViewStyles)
@implementation UIViewStyles
- (void)applyTo:(UIView *)view {
    [super applyTo:view];
    CGRect frame = view.frame;
    frame.size.width = _width;
    frame.size.height = _height;
    view.frame = frame;
    
    if (_backgroundColor) {
        view.backgroundColor = _backgroundColor;
    }
    if (_borderColor && _borderWidth) {
        view.layer.borderColor = [_borderColor CGColor];
        view.layer.borderWidth = _borderWidth;
    }
    if (_cornerRadius) {
        view.layer.cornerRadius = _cornerRadius;
    }
}
@end

// UIButton
///////////
DeclareClassDefaultStyles(UIButton, UIButtonStyles, uiButtonStyles)
@implementation UIButtonStyles
- (void)applyTo:(UIButton *)button {
    [super applyTo:button];
    if (_textColor) {
        [button setTitleColor:_textColor forState:UIControlStateNormal];
    }
    if (_font) {
        [button.titleLabel setFont:_font];
    }
}
@end

// UITextField
//////////////
DeclareClassDefaultStyles(UITextField, UITextFieldStyles, uiTextFieldStyles)
@implementation UITextFieldStyles
- (void)applyTo:(UITextField *)textField {
    [super applyTo:textField];
    if (_textColor) {
        [textField setTextColor:_textColor];
    }
    if (_font) {
        [textField setFont:_font];
    }
    if (_pad) {
        [textField setLeftViewMode:UITextFieldViewModeAlways];
        [textField setRightViewMode:UITextFieldViewModeAlways];
        [textField setLeftView:[[UIView alloc] initWithFrame:CGRectMake(0, 0, _pad, 0)]];
        [textField setRightView:[[UIView alloc] initWithFrame:CGRectMake(0, 0, _pad, 0)]];
    }
    if (_borderStyle) {
        [textField setBorderStyle:_borderStyle];
    }
    if (_keyboardAppearance) {
        [textField setKeyboardAppearance:_keyboardAppearance];
    }
}
@end

// UITextView
/////////////
DeclareClassDefaultStyles(UITextView, UITextViewStyles, uiTextViewStyles)
@implementation UITextViewStyles
- (void)applyTo:(UITextView *)textView {
    [super applyTo:textView];
    if (_textColor) {
        textView.textColor = _textColor;
    }
    if (_font) {
        textView.font = _font;
    }
    if (_keyboardAppearance) {
        textView.keyboardAppearance = _keyboardAppearance;
    }
}
@end

// UILabel
//////////
DeclareClassDefaultStyles(UILabel, UILabelStyles, uiLabelStyles)
@implementation UILabelStyles
- (void)applyTo:(UILabel *)label {
    [super applyTo:label];
    if (_textColor) {
        [label setTextColor:_textColor];
    }
    if (_font) {
        [label setFont:_font];
    }
    if (_textShadowColor) {
        label.shadowColor = [_textShadowColor copy];
        label.shadowOffset = _textShadowOffset;
    }
}
@end