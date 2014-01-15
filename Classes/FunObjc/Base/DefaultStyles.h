//
//  DefaultStyles.h
//  ivyq
//
//  Created by Marcus Westin on 9/25/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#define DeclareClassDefaultStyles(VIEW_CLASS_NAME, STYLES_CLASS_NAME, INSTANCE_NAME)\
@implementation VIEW_CLASS_NAME (DefaultStyles) \
static STYLES_CLASS_NAME * INSTANCE_NAME; \
+ (void) load { INSTANCE_NAME = [STYLES_CLASS_NAME new]; } \
+ (STYLES_CLASS_NAME *)styles { return INSTANCE_NAME; }\
@end

@interface DefaultStyles : NSObject
- (void)applyTo:(UIView*)view;
@end

// UIView
@interface UIViewStyles : DefaultStyles
@property CGFloat width;
@property CGFloat height;
@property UIColor* backgroundColor;
@property CGFloat cornerRadius;
@property UIColor* borderColor;
@property CGFloat borderWidth;
@end
@interface UIView (DefaultStyles)
+ (UIViewStyles*)styles;
@end

// UIButton
@interface UIButtonStyles : UIViewStyles
@property UIColor* textColor;
@property UIFont* font;
@end
@interface UIButton (DefaultStyles)
+ (UIButtonStyles*)styles;
@end

// UITextField
@interface UITextFieldStyles : UIViewStyles
@property UIColor* textColor;
@property UIFont* font;
@property CGFloat pad;
@property UITextBorderStyle borderStyle;
@property UIKeyboardAppearance keyboardAppearance;
@end
@interface UITextField (DefaultStyles);
+ (UITextFieldStyles*)styles;
@end

// UITextView
@interface UITextViewStyles : UIViewStyles
@property UIColor* textColor;
@property UIFont* font;
@property UIKeyboardAppearance keyboardAppearance;
@end
@interface UITextView (DefaultStyles)
+ (UITextViewStyles*)styles;
@end

// UILabel
@interface UILabelStyles : UIViewStyles
@property UIColor* textColor;
@property UIFont* font;
@property UIColor* textShadowColor;
@property CGSize textShadowOffset;
@end
@interface UILabel (DefaultStyles);
+ (UILabelStyles*)styles;
@end
