//
//  UIView+Style.h
//  Dogo-iOS
//
//  Created by Marcus Westin on 6/27/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIControl+Fun.h"

typedef enum Side Side;
enum Side {
    Left = 1,
    Right = 2,
};

@class ViewStyler;

typedef ViewStyler* Styler;
typedef Styler (^StylerView)(UIView* view);
typedef Styler (^StylerView2)(UIView* view, UIView* view2);
typedef Styler (^StylerSize)(CGSize size);
typedef Styler (^StylerFloat1)(CGFloat num);
typedef Styler (^StylerFloat2)(CGFloat f1, CGFloat f2);
typedef Styler (^StylerFloat3)(CGFloat f1, CGFloat f2, CGFloat f3);
typedef Styler (^StylerFloat4)(CGFloat f1, CGFloat f2, CGFloat f3, CGFloat f4);
typedef Styler (^StylerFloatSide)(CGFloat f, Side b);
typedef Styler (^StylerViewFloatSide)(UIView* view, CGFloat f, Side b);
typedef Styler (^StylerColor1)(UIColor* color);
typedef Styler (^StylerPoint)(CGPoint point);
typedef Styler (^StylerRect)(CGRect rect);
typedef Styler (^StylerString1)(NSString* string);
typedef Styler (^StylerAttributedString)(NSAttributedString* string);
typedef Styler (^StylerMString1)(NSMutableString* string);
typedef Styler (^StylerInteger1)(NSInteger integer);
typedef Styler (^StylerTextAlignment)(NSTextAlignment textAlignment);
typedef Styler (^StylerColorFloat2)(UIColor* color, CGFloat f1, CGFloat f2);
typedef Styler (^StylerFloat3Color)(CGFloat f1, CGFloat f2, CGFloat f3, UIColor* color);
typedef Styler (^StylerColorFloat)(UIColor* color, CGFloat f);
typedef Styler (^StylerFont)(UIFont* font);
typedef Styler (^StylerViewInteger)(UIView* view, NSInteger i);
typedef Styler (^StylerViewFloat)(UIView* view, CGFloat f);
typedef Styler (^StylerFloatColor)(CGFloat f, UIColor* color);
typedef Styler (^StylerFloat4Color)(CGFloat f1, CGFloat f2, CGFloat f3, CGFloat f4, UIColor* color);
typedef Styler (^StylerImage)(UIImage* image);
typedef Styler (^StylerLayer)(CALayer* layer);
typedef Styler (^StylerDate)(NSDate* date);

@interface ViewStyler : NSObject

@property UIView* view;

/* Create & apply
 ****************/
- (void)apply;
- (id)render;
- (id)onTap:(EventHandler)handler DEPRECATED_ATTRIBUTE;
- (id)onTap:(id)target selector:(SEL)selector;

/* View hierarchy
 ****************/
- (StylerInteger1)tag;
- (StylerString1)name;

/* Position
 **********/
- (StylerFloat1)x;
- (StylerFloat1)y;
- (StylerFloat2)xy;
- (Styler)center;
- (Styler)centerVertically;
- (Styler)centerHorizontally;
- (StylerFloat1)centerX;
- (StylerFloat1)centerY;
- (StylerFloat2)centerXY;
- (StylerFloat1)fromRight;
- (StylerFloat1)fromLeft;
- (StylerFloatSide)fromSide;
- (StylerFloat1)x2;
- (StylerFloat1)fromBottom;
- (StylerFloat1)y2;
- (StylerPoint)position;
- (StylerRect)frame;
- (StylerFloat4)inset;
- (StylerFloat1)insetAll;
- (StylerFloat1)insetSides;
- (StylerFloat1)insetTop;
- (StylerFloat1)insetRight;
- (StylerFloat1)insetLeft;
- (StylerFloat1)insetBottom;
- (StylerFloat4)outset;
- (StylerFloat1)outsetAll;
- (StylerFloat1)outsetSides;
- (StylerFloat1)outsetTop;
- (StylerFloat1)outsetRight;
- (StylerFloat1)outsetLeft;
- (StylerFloat1)outsetBottom;
- (StylerFloatSide)outsetSide;
- (StylerFloat1)moveUp;
- (StylerFloat1)moveDown;
- (StylerViewFloat)below;
- (StylerViewFloat)above;
- (StylerFloat1)belowLast;
- (StylerFloat1)aboveLast;
- (StylerViewFloat)leftOf;
- (StylerFloat1)leftOfLast;
- (StylerViewFloat)rightOf;
- (StylerFloat1)rightOfLast;
- (StylerViewFloat)fillRightOf;
- (StylerFloat1)fillRightOfLast;
- (StylerViewFloat)fillLeftOf;
- (StylerFloat1)fillLeftOfLast;
- (StylerViewFloatSide)fillSideOf;
- (StylerViewFloat)fillBelow;
- (StylerFloat1)fillBelowLast;
- (StylerViewFloat)fillAbove;
- (StylerFloat1)fillAboveLast;

/* Size
 ******/
- (StylerFloat1)w;
- (StylerFloat1)h;
- (StylerFloat2)wh;
- (StylerSize)bounds;
- (Styler)size;
- (Styler)sizeHeight;
- (Styler)sizeToFit;
- (Styler)fill;
- (Styler)fillW;
- (Styler)fillH;
- (Styler)square;

/* Styling
 *********/
- (StylerColor1)bg;
- (StylerFloat3)shadow;
- (StylerFloat1)radius;
- (Styler)round;
- (StylerFloatColor)border;
- (StylerFloat4Color)edges;
- (Styler)hide;
- (Styler)clip;
- (Styler)blur;
- (StylerLayer)bgLayer;
- (StylerFloat1)alpha;

/* Labels
 ********/
- (Styler)textCenter;
- (StylerString1)text;
- (StylerAttributedString)attributedText;
- (StylerColor1)textColor;
- (StylerTextAlignment)textAlignment;
- (StylerFloat3Color)textShadow;
- (StylerFont)textFont;
- (StylerInteger1)textLines;
- (Styler(^)(NSLineBreakMode lineBreakMode))textLineBreakMode;
- (Styler)wrapText;
- (Styler(^)(UIKeyboardType keyboardType))keyboardType;
- (Styler(^)(UIKeyboardAppearance keyboardAppearance))keyboardAppearance;
- (Styler(^)(UIReturnKeyType))keyboardReturnKeyType;

/* Text inputs
 *************/
- (StylerString1)placeholder;
- (StylerMString1)bindText;
- (StylerFloat1)inputPad;

/* Images
 ********/
- (StylerImage)image;
- (StylerImage)imageFill;
@end


/* View helpers
 **************/
@interface UIView (FunStyler)
+ (StylerView) appendTo;
+ (StylerView) prependTo;
+ (StylerView) prependBefore;
+ (StylerView) appendAfter;
+ (StylerViewInteger) insertAtIndex;
+ (Styler) styler;
+ (StylerRect) frame;
- (Styler) styler;
- (UIView*)viewByName:(NSString*)name;
- (UILabel*)labelByName:(NSString*)name;
- (void)sizeToParent;
@end
@interface UIButton (FunStyler)
+ (Styler) styler;
- (void)setImage:(UIImage *)image;
@end

// Arity 0
#define DeclareStyler(STYLER_NAME, STYLER_CODE)\
-(Styler) STYLER_NAME {\
STYLER_CODE; return self;\
}
// Arity 1
#define DeclareFloatStyler(STYLER_NAME, FLOAT_ARG_NAME, STYLER_CODE)\
-(StylerFloat1) STYLER_NAME {\
return ^(CGFloat FLOAT_ARG_NAME) {\
STYLER_CODE; return self;\
};\
}
#define DeclareViewStyler(STYLER_NAME, VIEW_ARG_NAME, STYLER_CODE)\
-(StylerView) STYLER_NAME {\
return ^(UIView* VIEW_ARG_NAME) {\
STYLER_CODE; return self;\
};\
}
#define DeclareIntegerStyler(STYLER_NAME, INT_ARG_NAME, STYLER_CODE)\
-(StylerInteger1) STYLER_NAME {\
return ^(NSInteger INT_ARG_NAME) {\
STYLER_CODE; return self;\
};\
}
#define DeclareStringStyler(STYLER_NAME, STRING_ARG_NAME, STYLER_CODE)\
-(StylerString1) STYLER_NAME {\
return ^(NSString* STRING_ARG_NAME) {\
STYLER_CODE; return self;\
};\
}
#define DeclareAttributedStringStyler(STYLER_NAME, STRING_ARG_NAME, STYLER_CODE)\
-(StylerAttributedString) STYLER_NAME {\
return ^(NSAttributedString* STRING_ARG_NAME) {\
STYLER_CODE; return self;\
};\
}
#define DeclareMStringStyler(STYLER_NAME, STRING_ARG_NAME, STYLER_CODE)\
-(StylerMString1) STYLER_NAME {\
return ^(NSMutableString* STRING_ARG_NAME) {\
STYLER_CODE; return self;\
};\
}
#define DeclarePointStyler(STYLER_NAME, POINT_ARG_NAME, STYLER_CODE)\
-(StylerPoint) STYLER_NAME {\
return ^(CGPoint POINT_ARG_NAME) {\
STYLER_CODE; return self;\
};\
}
#define DeclareRectStyler(STYLER_NAME, RECT_ARG_NAME, STYLER_CODE)\
-(StylerRect) STYLER_NAME {\
return ^(CGRect RECT_ARG_NAME) {\
STYLER_CODE; return self;\
};\
}
#define DeclareSizeStyler(STYLER_NAME, SIZE_ARG_NAME, STYLER_CODE)\
-(StylerSize) STYLER_NAME {\
return ^(CGSize SIZE_ARG_NAME) {\
STYLER_CODE; return self;\
};\
}
#define DeclareColorStyler(STYLER_NAME, COLOR_ARG_NAME, STYLER_CODE)\
-(StylerColor1) STYLER_NAME {\
return ^(UIColor* COLOR_ARG_NAME) {\
STYLER_CODE; return self;\
};\
}
#define DeclareStyler1(STYLER_NAME, ARG1_TYPE, ARG1_NAME, STYLER_CODE)\
-(Styler(^)(ARG1_TYPE)) STYLER_NAME {\
return ^(ARG1_TYPE ARG1_NAME) {\
STYLER_CODE; return self;\
};\
}
#define DeclareImageStyler(STYLER_NAME, IMAGE_ARG_NAME, STYLER_CODE)\
-(StylerImage) STYLER_NAME {\
return ^(UIImage* IMAGE_ARG_NAME) {\
STYLER_CODE; return self;\
};\
}
#define DeclareLayerStyler(STYLER_NAME, LAYER_ARG_NAME, STYLER_CODE)\
-(StylerLayer) STYLER_NAME {\
return ^(CALayer* LAYER_ARG_NAME) {\
STYLER_CODE; return self;\
};\
}
#define DeclareDateStyler(STYLER_NAME, ARG_NAME, STYLER_CODE)\
-(StylerDate) STYLER_NAME {\
return ^(NSDate* ARG_NAME) {\
STYLER_CODE; return self;\
};\
}

// Arity 2
//////////
#define DeclareFloat2Styler(STYLER_NAME, F1ARG_NAME, F2ARG_NAME, STYLER_CODE)\
-(StylerFloat2) STYLER_NAME {\
return ^(CGFloat F1ARG_NAME, CGFloat F2ARG_NAME) {\
STYLER_CODE; return self;\
};\
}
#define DeclareFloatSideStyler(STYLER_NAME, F1ARG_NAME, S1ARG_NAME, STYLER_CODE)\
-(StylerFloatSide) STYLER_NAME {\
return ^(CGFloat F1ARG_NAME, Side S1ARG_NAME) {\
STYLER_CODE; return self;\
};\
}
#define DeclareViewFloatStyler(STYLER_NAME, VIEW_ARG_NAME, FLOAT_ARG_NAME, STYLER_CODE)\
-(StylerViewFloat) STYLER_NAME {\
return ^(UIView* VIEW_ARG_NAME, CGFloat FLOAT_ARG_NAME) {\
STYLER_CODE; return self;\
};\
}
#define DeclareFloatColorStyler(STYLER_NAME, FLOAT_ARG_NAME, COLOR_ARG_NAME, STYLER_CODE)\
-(StylerFloatColor) STYLER_NAME {\
return ^(CGFloat FLOAT_ARG_NAME, UIColor* COLOR_ARG_NAME) {\
STYLER_CODE; return self;\
};\
}
// Arity 3
//////////
#define DeclareViewFloatSideStyler(STYLER_NAME, VIEW_ARGNAME, F_ARGNAME, S_ARGNAME, STYLER_CODE)\
-(StylerViewFloatSide) STYLER_NAME {\
return ^(UIView* VIEW_ARGNAME, CGFloat F_ARGNAME, Side S_ARGNAME) {\
STYLER_CODE; return self;\
};\
}

#define DeclareFloat3Styler(STYLER_NAME, f1NAME, f2NAME, f3NAME, STYLER_CODE)\
-(StylerFloat3)STYLER_NAME { \
return ^(CGFloat f1NAME, CGFloat f2NAME, CGFloat f3NAME) {\
STYLER_CODE; return self;\
};\
}
// Arity 4
//////////
#define DeclareFloat4Styler(STYLER_NAME, f1NAME, f2NAME, f3NAME, f4NAME, STYLER_CODE)\
-(StylerFloat4)STYLER_NAME { \
return ^(CGFloat f1NAME, CGFloat f2NAME, CGFloat f3NAME, CGFloat f4NAME) {\
STYLER_CODE; return self;\
};\
}
#define DeclareFloat3ColorStyler(STYLER_NAME, f1NAME, f2NAME, f3NAME, COLOR_NAME, STYLER_CODE)\
-(StylerFloat3Color)STYLER_NAME { \
return ^(CGFloat f1NAME, CGFloat f2NAME, CGFloat f3NAME, UIColor* COLOR_NAME) {\
STYLER_CODE; return self;\
};\
}
// Arity 5
//////////
#define DeclareFloat4ColorStyler(STYLER_NAME, f1NAME, f2NAME, f3NAME, f4NAME, COLOR_ARG_NAME, STYLER_CODE)\
-(StylerFloat4Color)STYLER_NAME { \
return ^(CGFloat f1NAME, CGFloat f2NAME, CGFloat f3NAME, CGFloat f4NAME, UIColor* COLOR_ARG_NAME) {\
STYLER_CODE; return self;\
};\
}