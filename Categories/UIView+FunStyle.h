//
//  UIView+Style.h
//  Dogo-iOS
//
//  Created by Marcus Westin on 6/27/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIControl+Fun.h"

@class ViewStyler;

typedef ViewStyler* Styler;
typedef ViewStyler* (^StylerView)(UIView* view);
typedef ViewStyler* (^StylerSize)(CGSize size);
typedef ViewStyler* (^StylerFloat1)(CGFloat num);
typedef ViewStyler* (^StylerFloat2)(CGFloat f1, CGFloat f2);
typedef ViewStyler* (^StylerFloat3)(CGFloat f1, CGFloat f2, CGFloat f3);
typedef ViewStyler* (^StylerFloat4)(CGFloat f1, CGFloat f2, CGFloat f3, CGFloat f4);
typedef ViewStyler* (^StylerColor1)(UIColor* color);
typedef ViewStyler* (^StylerPoint)(CGPoint point);
typedef ViewStyler* (^StylerRect)(CGRect rect);
typedef ViewStyler* (^StylerString1)(NSString* string);
typedef ViewStyler* (^StylerAttributedString)(NSAttributedString* string);
typedef ViewStyler* (^StylerMString1)(NSMutableString* string);
typedef ViewStyler* (^StylerInteger1)(NSInteger integer);
typedef ViewStyler* (^StylerTextAlignment)(NSTextAlignment textAlignment);
typedef ViewStyler* (^StylerColorFloat2)(UIColor* color, CGFloat f1, CGFloat f2);
typedef ViewStyler* (^StylerColorFloat)(UIColor* color, CGFloat f);
typedef ViewStyler* (^StylerFont)(UIFont* font);
typedef ViewStyler* (^StylerViewFloat)(UIView* view, CGFloat f);
typedef ViewStyler* (^StylerFloatColor)(CGFloat f, UIColor* color);
typedef ViewStyler* (^StylerFloat4Color)(CGFloat f1, CGFloat f2, CGFloat f3, CGFloat f4, UIColor* color);
typedef ViewStyler* (^StylerImage)(UIImage* image);
typedef ViewStyler* (^StylerLayer)(CALayer* layer);
typedef ViewStyler* (^StylerDate)(NSDate* date);

@interface ViewStyler : NSObject

@property UIView* view;

/* Create & apply
 ****************/
- (void)apply;
- (id)render;
- (StylerView)appendTo;
- (StylerView)prependTo;
- (id)onTap:(EventHandler)handler;

/* View hierarchy
 ****************/
- (StylerInteger1)tag;
- (StylerString1)name;

/* Position
 **********/
- (StylerFloat1)x;
- (StylerFloat1)y;
- (StylerFloat2)xy;
- (ViewStyler*)center;
- (ViewStyler*)centerVertically;
- (ViewStyler*)centerHorizontally;
- (StylerFloat1)fromRight;
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
- (StylerFloat1)moveUp;
- (StylerFloat1)moveDown;
- (StylerViewFloat)below;
- (StylerViewFloat)above;
- (StylerViewFloat)leftOf;
- (StylerViewFloat)rightOf;
- (StylerViewFloat)fillRightOf;
- (StylerViewFloat)fillLeftOf;

/* Size
 ******/
- (StylerFloat1)w;
- (StylerFloat1)h;
- (StylerFloat2)wh;
- (StylerSize)bounds;
- (ViewStyler*)size;
- (ViewStyler*)sizeToFit;
- (ViewStyler*)fill;
- (ViewStyler*)fillW;
- (ViewStyler*)fillH;
- (ViewStyler*)square;

/* Styling
 *********/
- (StylerColor1)bg;
- (StylerFloat3)shadow;
- (StylerFloat1)radius;
- (ViewStyler*)round;
- (StylerFloatColor)border;
- (StylerFloat4Color)edges;
- (ViewStyler*)hide;
- (ViewStyler*)clip;
- (StylerColor1)blur;
- (StylerLayer)bgLayer;
- (StylerFloat1)alpha;

/* Labels
 ********/
- (Styler)textCenter;
- (StylerString1)text;
- (StylerAttributedString)attributedText;
- (StylerColor1)textColor;
- (StylerTextAlignment)textAlignment;
- (StylerColorFloat2)textShadow;
- (StylerFont)textFont;
- (StylerInteger1)textLines;
- (Styler)wrapText;
- (ViewStyler*(^)(UIKeyboardType keyboardType))keyboardType;
- (ViewStyler*(^)(UIKeyboardAppearance keyboardAppearance))keyboardAppearance;

/* Text inputs
 *************/
- (StylerString1)placeholder;
- (StylerMString1)bindText;
- (StylerFloat1)inputPad;

/* Images
 ********/
- (StylerImage)image;
@end


/* View helpers
 **************/
@interface UIView (FunStyler)
+ (StylerView) appendTo;
+ (StylerView) prependTo;
+ (ViewStyler*) styler;
+ (StylerRect) frame;
- (ViewStyler*) styler;
- (void)render;
- (UIView*)viewByName:(NSString*)name;
- (UILabel*)labelByName:(NSString*)name;
@end
@interface UIButton (FunStyler)
+ (ViewStyler*) styler;
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
-(ViewStyler*(^)(ARG1_TYPE)) STYLER_NAME {\
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
// Arity 5
//////////
#define DeclareFloat4ColorStyler(STYLER_NAME, f1NAME, f2NAME, f3NAME, f4NAME, COLOR_ARG_NAME, STYLER_CODE)\
-(StylerFloat4Color)STYLER_NAME { \
return ^(CGFloat f1NAME, CGFloat f2NAME, CGFloat f3NAME, CGFloat f4NAME, UIColor* COLOR_ARG_NAME) {\
STYLER_CODE; return self;\
};\
}