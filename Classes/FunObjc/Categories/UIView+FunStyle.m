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
#import "UIImage+Fun.h"
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
#define _textView ((UITextView*)_view)
#define _imageView ((UIImageView*)_view)

@implementation ViewStyler {
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
    return self;
}

- (void)apply {
    [self _makeEdges];
    if (_bgLayer) {
        _bgLayer.frame = _view.bounds;
        [_view.layer insertSublayer:_bgLayer atIndex:0];
    }
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
DeclareFloatStyler(x, x,
                   CGRect frame = _view.frame;
                   frame.origin.x = x;
                   _view.frame = frame)
DeclareFloatStyler(y, y,
                   CGRect frame = _view.frame;
                   frame.origin.y = y;
                   _view.frame = frame)
DeclareFloat2Styler(xy, x, y,
                    CGRect frame = _view.frame;
                    frame.origin.x = x;
                    frame.origin.y = y;
                    _view.frame = frame)
DeclarePointStyler(position, pos,
                   CGRect frame = _view.frame;
                   frame.origin = pos;
                   _view.frame = frame)

DeclareStyler(center,
              [self centerHorizontally];
              [self centerVertically])
DeclareStyler(centerVertically,
              CGRect frame = _view.frame;
              frame.origin.y = CGRectGetMidY(_view.superview.bounds) - frame.size.height/2;
              _view.frame = frame)
DeclareStyler(centerHorizontally,
              CGRect frame = _view.frame;
              frame.origin.x = CGRectGetMidX(_view.superview.bounds) - frame.size.width/2;
              _view.frame = frame)
DeclareFloatStyler(centerX, centerX,
                   _view.centerX = centerX);
DeclareFloatStyler(centerY, centerY,
                   _view.centerY = centerY);
DeclareFloat2Styler(centerXY, centerX, centerY,
                    _view.center = CGPointMake(centerX, centerY));

DeclareFloatStyler(fromBottom, offset,
                   CGRect frame = _view.frame;
                   frame.origin.y = _view.superview.frame.size.height - frame.size.height - offset;
                   _view.frame = frame)

DeclareFloatStyler(y2, y2,
                   CGRect frame = _view.frame;
                   frame.origin.y = y2 - frame.size.height;
                   _view.frame = frame)
DeclareFloatStyler(fromRight, offset, self.x2(offset))
DeclareFloatStyler(x2, offset,
                   CGRect frame = _view.frame;
                   frame.origin.x = _view.superview.frame.size.width - frame.size.width - offset;
                   _view.frame = frame)

DeclareRectStyler(frame, frame, _view.frame = frame)

DeclareFloat4Styler(outset, t, r, b, l, self.inset(-t, -r, -b, -l))
DeclareFloatStyler(outsetAll, f, self.outset(f,f,f,f))
DeclareFloatStyler(outsetSides, f, self.outset(0,f,0,f))
DeclareFloatStyler(outsetTop, f, self.outset(f,0,0,0))
DeclareFloatStyler(outsetRight, f, self.outset(0,f,0,0))
DeclareFloatStyler(outsetBottom, f, self.outset(0,0,f,0))
DeclareFloatStyler(outsetLeft, f, self.outset(0,0,0,f))
DeclareFloatStyler(insetAll, i, self.inset(i,i,i,i))
DeclareFloatStyler(insetSides, f, self.inset(0,f,0,f))
DeclareFloatStyler(insetTop, f, self.inset(f,0,0,0))
DeclareFloatStyler(insetRight, f, self.inset(0,f,0,0))
DeclareFloatStyler(insetBottom, f, self.inset(0,0,f,0))
DeclareFloatStyler(insetLeft, f, self.inset(0,0,0,f))
DeclareFloat4Styler(inset, top, right, bottom, left,
                    CGRect frame = _view.frame;
                    frame.origin.y += top;
                    frame.size.height -= top;
                    frame.size.height -= bottom;
                    frame.origin.x += left;
                    frame.size.width -= left;
                    frame.size.width -= right;
                    _view.frame = frame)

DeclareFloatStyler(moveUp, amount,
                   _view.y -= amount)
DeclareFloatStyler(moveDown, amount,
                   _view.y += amount)

- (UIView*)last {
    NSArray* views = _view.superview.subviews;
    if (views.count <= 1) {
        return nil;
    }
    return views[views.count - 2];
}

DeclareViewFloatStyler(below, view, offset,
                       _view.y = (view ? view.y2 : 0) + offset)
DeclareFloatStyler(belowLast, offset,
                   self.below(self.last, offset))

DeclareViewFloatStyler(above, view, offset,
                       _view.y2 = view.y - offset)
DeclareFloatStyler(aboveLast, offset,
                   self.above(self.last, offset))

DeclareViewFloatStyler(rightOf, view, offset,
                       _view.x = (view ? view.x2 : 0) + offset)
DeclareFloatStyler(rightOfLast, offset,
                   self.rightOf(self.last, offset))

DeclareViewFloatStyler(leftOf, view, offset,
                       _view.x2 = (view ? view.x : 0) - offset)
DeclareFloatStyler(leftOfLast, offset,
                   self.leftOf(self.last, offset))

DeclareViewFloatStyler(fillRightOf, view, offset,
                       _view.x = view.x2 + offset;
                       _view.width = _view.superview.width - view.x2 - offset)
DeclareFloatStyler(fillRightOfLast, offset,
                   self.fillRightOf(self.last, offset))

DeclareViewFloatStyler(fillLeftOf, view, offset,
                       _view.x = 0;
                       _view.width = view.x - offset)
DeclareFloatStyler(fillLeftOfLast, offset,
                   self.fillLeftOf(self.last, offset))

/* Size
 ******/
DeclareFloatStyler(w, width,
                   CGRect frame = _view.frame;
                   frame.size.width = width;
                   _view.frame = frame)
DeclareFloatStyler(h, height,
                   CGRect frame = _view.frame;
                   frame.size.height = height;
                   _view.frame = frame)
DeclareFloat2Styler(wh, w, h,
                    CGRect frame = _view.frame;
                    frame.size = CGSizeMake(w, h);
                    _view.frame = frame)
DeclareStyler(fill,
              CGRect frame = _view.frame;
              frame.size = _view.superview.bounds.size;
              _view.frame = frame)
DeclareStyler(fillW,
              CGRect frame = _view.frame;
              frame.size.width = _view.superview.width;
              _view.frame = frame)
DeclareStyler(fillH,
              CGRect frame = _view.frame;
              frame.size.height = _view.superview.height;
              _view.frame = frame)
DeclareStyler(square,
              CGRect frame = _view.frame;
              frame.size.height = frame.size.width;
              _view.frame = frame)

DeclareSizeStyler(bounds, size,
                  CGRect frame = _view.frame;
                  frame.size = size;
                  _view.frame = frame)

DeclareStyler(size, [_view sizeToFit])
DeclareStyler(sizeToFit, [_view sizeToFit])


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
              CGFloat radius = MIN(_view.frame.size.width, _view.frame.size.height);
              _view.layer.cornerRadius = radius/2;
              _view.clipsToBounds = YES;
              )

DeclareFloat4ColorStyler(edges, w1,w2,w3,w4, color,
                         _edgeWidths = UIEdgeInsetsMake(w1,w2,w3,w4);
                         _edgeColor = color)
- (void)_makeEdges {
    if (_edgeWidths.top) {
        [self _addEdge:CGRectMake(0, 0, _view.frame.size.width, _edgeWidths.top)];
    }
    if (_edgeWidths.right) {
        [self _addEdge:CGRectMake(_view.frame.size.width - _edgeWidths.right, 0, _edgeWidths.right, _view.frame.size.height)];
    }
    if (_edgeWidths.bottom) {
        [self _addEdge:CGRectMake(0, _view.frame.size.height - _edgeWidths.bottom, _view.frame.size.width, _edgeWidths.bottom)];
    }
    if (_edgeWidths.left) {
        [self _addEdge:CGRectMake(0, 0, _edgeWidths.left, _view.frame.size.height)];
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
                   if ([_view respondsToSelector:@selector(setTextColor:)]) {
                       _labelView.textColor = textColor;
                   } else if ([_view respondsToSelector:@selector(setTitleColor:forState:)]) {
                       [_buttonView setTitleColor:textColor forState:UIControlStateNormal];
                   } else {
                       [NSException raise:@"Error" format:@"Can't apply textColor"];
                   })

- (StylerTextAlignment)textAlignment {
    return ^(NSTextAlignment textAlignment) {
        if ([_view respondsToSelector:@selector(setTextAlignment:)]) {
            _labelView.textAlignment = textAlignment;
        } else if ([_view respondsToSelector:@selector(titleLabel)]) {
            _buttonView.titleLabel.textAlignment = textAlignment;
        }
        return self;
    };
}
DeclareStyler(textCenter, self.textAlignment(NSTextAlignmentCenter))
DeclareFloat3ColorStyler(textShadow, xOffset, yOffset, radius, color,
                         CALayer* layer = ((CALayer*)_view.layer);
                         layer.shadowOffset = CGSizeMake(xOffset, yOffset);
                         layer.shadowRadius = radius;
                         layer.shadowColor = color.CGColor;
                         layer.shadowOpacity = 1.0;
                         layer.masksToBounds = NO;
                         )
- (StylerFont)textFont {
    return ^(UIFont* font) {
        _labelView.font = font;
        return self;
    };
}
DeclareIntegerStyler(textLines, lines,
                     _labelView.numberOfLines = lines)
DeclareStyler(wrapText,
              [_labelView wrapText];
              [self size])
DeclareStyler1(keyboardType, UIKeyboardType, type,
               _textField.keyboardType = type)
DeclareStyler1(keyboardAppearance, UIKeyboardAppearance, appearance,
               _textField.keyboardAppearance = appearance)
DeclareStyler1(keyboardReturnKeyType, UIReturnKeyType, returnKeyType,
               _textField.returnKeyType = returnKeyType)

/* Text inputs
 *************/
DeclareStringStyler(placeholder, placeholderText,
                    if ([_view respondsToSelector:@selector(setPlaceholder:)]) {
                        [_textField setPlaceholder:placeholderText];
                    } else if ([_view isKindOfClass:[UITextView class]]) {
                        UILabel* placeholderView = [UILabel.appendTo(_textView).fill.inset(8,5,8,5).textColor(rgb(150,150,150)).textFont(_textView.font).text(placeholderText).wrapText render];
                        [_textView onTextDidChange:^(UITextView *textView) {
                            if (textView.text.length) {
                                if (placeholderView.superview) {
                                    [placeholderView removeAndClean];
                                }
                            } else if (!placeholderView.superview) {
                                [placeholderView appendTo:textView];
                            }
                        }];
                        if (_textView.text.length) {
                            [placeholderView removeAndClean];
                        }
                    })
DeclareFloatStyler(inputPad, pad,
                   [_textField setLeftViewMode:UITextFieldViewModeAlways];
                   [_textField setRightViewMode:UITextFieldViewModeAlways];
                   [_textField setLeftView:[[UIView alloc] initWithFrame:CGRectMake(0, 0, pad, 0)]];
                   [_textField setRightView:[[UIView alloc] initWithFrame:CGRectMake(0, 0, pad, 0)]])



DeclareStyler(blur, [_view blur]);

DeclareLayerStyler(bgLayer, layer, _bgLayer = layer);
DeclareFloatStyler(alpha, alpha, _view.alpha = alpha)

/* Image views
 *************/
DeclareImageStyler(image, image,
                   if (![_view respondsToSelector:@selector(setImage:)]) {
                       [NSException raise:@"Error" format:@"Can't set image in image() styler"];
                   }
                   CGRect frame = _imageView.frame;
                   frame.size.width = image.size.width / 2;
                   frame.size.height = image.size.height / 2;
                   _imageView.image = image;
                   _imageView.frame = frame;)

DeclareImageStyler(imageFill, image,
                   if (![_view respondsToSelector:@selector(setImage:)]) {
                       [NSException raise:@"Error" format:@"Can't set image in image() styler"];
                   }
                   _imageView.image = [image thumbnailSize:_view.frame.size transparentBorder:0 cornerRadius:0 interpolationQuality:0])

@end


/* UIView helpers
 ****************/
@implementation UIView (FunStyler)
+ (StylerView)appendTo {
    return ^(UIView* superview) {
        ViewStyler* styler = self.styler;
        [styler.view appendTo:superview];
        styler.view.width = superview.width;
        return styler;
    };
}
+ (StylerView)prependTo {
    return ^(UIView* superview) {
        ViewStyler* styler = self.styler;
        [styler.view prependTo:superview];
        styler.view.width = superview.width;
        return styler;
    };
}
+ (StylerView2)prependBefore {
    return ^(UIView* superview, UIView* siblingView) {
        ViewStyler* styler = self.styler;
        [superview insertSubview:styler.view belowSubview:siblingView];
        styler.view.width = superview.width;
        return styler;
    };
}
- (ViewStyler *)styler {
    return [[ViewStyler alloc] initWithView:self];
}

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
    UIView* instance = [UIButton buttonWithType:UIButtonTypeCustom];
    [[[instance class] styles] applyTo:instance];
    return instance.styler;
}
- (void)setImage:(UIImage *)image {
    [self setImage:image forState:UIControlStateNormal];
}
@end
