//
//  UIView+Style.m
//  Dogo-iOS
//
//  Created by Marcus Westin on 6/27/13.
//  Copyright (c) 2013 ;; Labs Inc. All rights reserved.
//

#import "UIView+FunStyle.h"
#import "FunObjc.h"
#import <QuartzCore/QuartzCore.h>
#import "UIView+Fun.h"
#import "DefaultStyles.h"

static NSMutableArray* tagIntegerToTagName;
static NSMutableDictionary* tagNameToTagNumber;

@interface ViewStyler ()
- (instancetype)initWithView:(UIView*)view;
@end

// Type helpers
///////////////
#define _labelView ((UILabel*)_view)
#define _buttonView ((UIButton*)_view)
#define _textField ((UITextField*)_view)
#define _imageView ((UIImageView*)_view)

@implementation ViewStyler {
    CGRect _frame;
    UIEdgeInsets _edgeWidths;
    UIColor* _edgeColor;
    CALayer* _bgLayer;
}

+ (void)load {
    tagIntegerToTagName = [NSMutableArray arrayWithObject:@0];
    tagNameToTagNumber = [NSMutableDictionary dictionary];
}

/* Create & apply
 ****************/
- (ViewStyler*)initWithView:(UIView*)view {
    _view = view;
    _frame = view.frame;
    return self;
}

- (void)apply {
    _view.frame = _frame;
    [self _makeEdges];
    _bgLayer.frame = _view.bounds;
    [_view.layer insertSublayer:_bgLayer atIndex:0];
}

- (id)render {
    [self apply];
    [_view render];
    return _view;
}

- (id)onTap:(EventHandler)handler {
    id view = [self render];
    [_buttonView onTap:handler];
    return view;
}

/* View Hierarchy
 ****************/
DeclareViewStyler(appendTo, view, [_view appendTo:view])
DeclareViewStyler(prependTo, view, [_view prependTo:view])

DeclareIntegerStyler(tag, tagI, _view.tag = tagI)

DeclareStringStyler(name, tagName,
                    NSNumber* tagNumber = tagNameToTagNumber[tagName];
                    if (!tagNumber) {
                        NSInteger tag = tagIntegerToTagName.count;
                        [tagIntegerToTagName addObject:tagName];
                        tagNameToTagNumber[tagName] = [NSNumber numberWithInteger:tag];
                    }
                    _view.tag = [tagNameToTagNumber[tagName] integerValue];
                    )
/* Position
 **********/
DeclareFloatStyler(x, x, _frame.origin.x = x)
DeclareFloatStyler(y, y, _frame.origin.y = y)
DeclareFloat2Styler(xy, x, y,
                    _frame.origin.x = x;
                    _frame.origin.y = y;
                    )
DeclarePointStyler(position, pos, _frame.origin = pos)

DeclareStyler(center, [self centerHorizontally]; [self centerVertically])
DeclareStyler(centerVertically, _frame.origin.y = CGRectGetMidY(_view.superview.bounds) - _frame.size.height/2)
DeclareStyler(centerHorizontally, _frame.origin.x = CGRectGetMidX(_view.superview.bounds) - _frame.size.width/2)


DeclareFloatStyler(fromBottom, offset, _frame.origin.y = _view.superview.frame.size.height - _frame.size.height - offset)
DeclareFloatStyler(y2, y2, _frame.origin.y = y2 - _frame.size.height)
DeclareFloatStyler(fromRight, offset, self.x2(offset))
DeclareFloatStyler(x2, offset, _frame.origin.x = _view.superview.frame.size.width - _frame.size.width - offset)

DeclareRectStyler(frame, frame, _frame = frame)

DeclareFloat4Styler(inset, top, right, bottom, left,
                    _frame.origin.y += top;
                    _frame.size.height -= top;
                    _frame.size.height -= bottom;

                    _frame.origin.x += left;
                    _frame.size.width -= left;
                    _frame.size.width -= right;
                    )
DeclareFloatStyler(insetAll, i, self.inset(i,i,i,i))
DeclareFloatStyler(insetSides, f, self.inset(0,f,0,f))
DeclareFloatStyler(insetTop, f, self.inset(f,0,0,0))
DeclareFloatStyler(insetRight, f, self.inset(0,f,0,0))
DeclareFloatStyler(insetBottom, f, self.inset(0,0,f,0))
DeclareFloatStyler(insetLeft, f, self.inset(0,0,0,f))

DeclareFloat4Styler(outset, t, r, b, l, self.inset(-t, -r, -b, -l))
DeclareFloatStyler(outsetAll, f, self.outset(f,f,f,f))
DeclareFloatStyler(outsetSides, f, self.outset(0,f,0,f))
DeclareFloatStyler(outsetTop, f, self.outset(f,0,0,0))
DeclareFloatStyler(outsetRight, f, self.outset(0,f,0,0))
DeclareFloatStyler(outsetBottom, f, self.outset(0,0,f,0))
DeclareFloatStyler(outsetLeft, f, self.outset(0,0,0,f))

DeclareFloatStyler(moveUp, amount, _frame.origin.y -= amount)
DeclareFloatStyler(moveDown, amount, _frame.origin.y += amount)

DeclareViewFloatStyler(below, view, offset, _frame.origin.y = (view ? view.y2 : 0) + offset)
DeclareViewFloatStyler(above, view, offset, _frame.origin.y = view.y - _frame.size.height - offset)
DeclareViewFloatStyler(rightOf, view, offset, _frame.origin.x = (view ? view.x2 : 0) + offset)
DeclareViewFloatStyler(leftOf, view, offset, _frame.origin.x = (view ? view.x : 0) - _frame.size.width - offset)
DeclareViewFloatStyler(fillRightOf, view, offset,
                  _frame.origin.x = view.x2 + offset;
                  _frame.size.width = _view.superview.width - view.x2 - offset;
                  )
DeclareViewFloatStyler(fillLeftOf, view, offset,
                       _frame.origin.x = 0;
                       _frame.size.width = view.x - offset;
                       )

/* Size
 ******/
DeclareFloatStyler(w, width, _frame.size.width = width)
DeclareFloatStyler(h, height, _frame.size.height = height)
DeclareFloat2Styler(wh, w, h, _frame.size = CGSizeMake(w, h))
DeclareStyler(fill, _frame.size = _view.superview.bounds.size)
DeclareStyler(fillW, _frame.size.width = _view.superview.width)
DeclareStyler(fillH, _frame.size.height = _view.superview.height)
DeclareStyler(square, _frame.size.height = _frame.size.width)

DeclareSizeStyler(bounds, size, _frame.size = size)
DeclareStyler(sizeToParent, _frame.size = _view.superview.bounds.size)
DeclareStyler(size, [self sizeToFit])
DeclareStyler(sizeToFit,
              _view.frame = _frame;
              [_view sizeToFit];
              _frame.size = _view.frame.size;
              )


/* Styling
 *********/
DeclareColorStyler(bg, color,
                   _view.backgroundColor = color;
                   if (color.hasTransparency) {
                       _view.opaque = NO;
                   }
                   )
DeclareFloat3Styler(shadow, xOffset, yOffset, radius,
                    _view.layer.shadowColor = [UIColor colorWithWhite:0.5 alpha:1].CGColor;
                    _view.layer.shadowOffset = CGSizeMake(xOffset, yOffset);
                    _view.layer.shadowRadius = radius;
                    _view.layer.shadowOpacity = 0.5;
                    )
DeclareFloatStyler(radius, radius,
                   _view.layer.cornerRadius = radius;
                   _view.clipsToBounds = YES)

DeclareFloatColorStyler(border, width, color,
                        _view.layer.borderWidth = width;
                        _view.layer.borderColor = [color CGColor];
                        )

DeclareStyler(round,
              CGFloat radius = MIN(_frame.size.width, _frame.size.height);
              _view.layer.cornerRadius = radius/2;
              _view.clipsToBounds = YES;
              )

DeclareFloat4ColorStyler(edges, w1,w2,w3,w4, color,
                        _edgeWidths = UIEdgeInsetsMake(w1,w2,w3,w4);
                        _edgeColor = color)
- (void)_makeEdges {
    if (_edgeWidths.top) {
        [self _addEdge:CGRectMake(0, 0, _frame.size.width, _edgeWidths.top)];
    }
    if (_edgeWidths.right) {
        [self _addEdge:CGRectMake(_frame.size.width - _edgeWidths.right, 0, _edgeWidths.right, _frame.size.height)];
    }
    if (_edgeWidths.bottom) {
        [self _addEdge:CGRectMake(0, _frame.size.height - _edgeWidths.bottom, _frame.size.width, _edgeWidths.bottom)];
    }
    if (_edgeWidths.left) {
        [self _addEdge:CGRectMake(0, 0, _edgeWidths.left, _frame.size.height)];
    }
}
- (void)_addEdge:(CGRect)rect {
    CALayer* edge = [CALayer layer];
    edge.frame = rect;
    edge.backgroundColor = _edgeColor.CGColor;
    [_view.layer addSublayer:edge];
}
- (ViewStyler *)hide {
    _view.hidden = YES;
    return self;
}
- (ViewStyler *)clip {
    _view.clipsToBounds = YES;
    return self;
}
/* Labels
 ********/
DeclareStringStyler(text, text,
                    if (text.isNull) { text = nil; }
                    if ([_view respondsToSelector:@selector(setText:)]) {
                        [_view performSelector:@selector(setText:) withObject:text];
                    } else if ([_view isKindOfClass:UIButton.class]) {
                        [_buttonView setTitle:text forState:UIControlStateNormal];
                    } else {
                        [NSException raise:@"Error" format:@"Unknown class in text"];
                    })
DeclareAttributedStringStyler(attributedText, str,
                              [_labelView setAttributedText:str])
DeclareMStringStyler(bindText, string, [_textField bindTextTo:string]);

DeclareColorStyler(textColor, textColor,
                   if ([_view isKindOfClass:UILabel.class]) {
                       _labelView.textColor = textColor;
                   } else if ([_view isKindOfClass:UIButton.class]) {
                       [_buttonView setTitleColor:textColor forState:UIControlStateNormal];
                   } else {
                       [NSException raise:@"Error" format:@"Unknown class in textColor"];
                   })

- (StylerTextAlignment)textAlignment {
    return ^(NSTextAlignment textAlignment) {
        _labelView.textAlignment = textAlignment;
        return self;
    };
}
DeclareStyler(textCenter, self.textAlignment(NSTextAlignmentCenter))
- (StylerColorFloat2)textShadow {
    return ^(UIColor* shadowColor, CGFloat shadowOffsetX, CGFloat shadowOffsetY) {
        _labelView.shadowColor = shadowColor;
        _labelView.shadowOffset = CGSizeMake(shadowOffsetX, shadowOffsetY);
        return self;
    };
}
- (StylerFont)textFont {
    return ^(UIFont* font) {
        _labelView.font = font;
        return self;
    };
}
DeclareIntegerStyler(textLines, lines,
                     _labelView.numberOfLines = lines;
                     )
DeclareStyler(wrapText, [_labelView wrapText]; [self size])
DeclareStyler1(keyboardType, UIKeyboardType, type, _textField.keyboardType = type)
DeclareStyler1(keyboardAppearance, UIKeyboardAppearance, appearance, _textField.keyboardAppearance = appearance)

/* Text inputs
 *************/
DeclareStringStyler(placeholder, placeholder, _textField.placeholder = placeholder)
DeclareFloatStyler(inputPad, pad,
                    [_textField setLeftViewMode:UITextFieldViewModeAlways];
                    [_textField setRightViewMode:UITextFieldViewModeAlways];
                    [_textField setLeftView:[[UIView alloc] initWithFrame:CGRectMake(0, 0, pad, 0)]];
                    [_textField setRightView:[[UIView alloc] initWithFrame:CGRectMake(0, 0, pad, 0)]])



DeclareColorStyler(blur, color, [_view blur:color size:_frame.size]);

DeclareLayerStyler(bgLayer, layer, _bgLayer = layer);
DeclareFloatStyler(alpha, alpha, _view.alpha = alpha)

/* Image views
 *************/
DeclareImageStyler(image, image,
                   if ([_view respondsToSelector:@selector(setImage:)]) {
                       _imageView.image = image;
                       [_imageView sizeToFit];
                       _frame = _imageView.frame;
                       _frame.size.width /= 2;
                       _frame.size.height /= 2;
                   } else {
                       [NSException raise:@"Error" format:@"Can't set image in image() styler"];
                   })

@end


/* UIView helpers
 ****************/
@implementation UIView (FunStyler)
+ (StylerView)appendTo {
    return ^(UIView* view) {
        return self.styler.appendTo(view).fillW;
    };
}
+ (StylerView)prependTo {
    return ^(UIView* view) {
        return self.styler.prependTo(view).fillW;
    };
}
- (ViewStyler *)styler {
    return [[ViewStyler alloc] initWithView:self];
}
- (void)render {}

+ (StylerRect)frame {
    return self.styler.frame;
}
+ (ViewStyler*)styler {
    UIView* instance = [[[self class] alloc] initWithFrame:CGRectZero];
    [[[instance class] styles] applyTo:instance];
    return instance.styler;
}
- (UIView *)viewByName:(NSString *)name {
    NSNumber* tagNumber = tagNameToTagNumber[name];
    if (!tagNumber) { return nil; }
    return [self viewWithTag:[tagNumber integerValue]];
}
- (UILabel *)labelByName:(NSString *)name {
    return (UILabel*)[self viewByName:name];
}
@end
@implementation UIButton (FunStyler)
+ (ViewStyler *)styler {
    return [[UIButton buttonWithType:UIButtonTypeCustom] styler];
}
- (void)setImage:(UIImage *)image {
    [self setImage:image forState:UIControlStateNormal];
}
@end
