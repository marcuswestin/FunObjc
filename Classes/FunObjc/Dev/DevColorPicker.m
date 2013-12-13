//
//  DevColorPicker.m
//  Dogo iOS
//
//  Created by Marcus Westin on 12/12/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "DevColorPicker.h"
#import "ISColorWheel.h"
#import "FunBase.h"

@interface DevColorPicker ()
@property UIView* targetView;
@property UIView* overlay;
@property ISColorWheel* colorWheel;
@property UISlider* brightnessSlider;
@property UISlider* alphaSlider;
@property UILabel* rgba;
@property UILabel* hsla;
@end

static DevColorPicker* picker;

@interface DevColorPicker (delegate) <ISColorWheelDelegate>

@end

@implementation DevColorPicker
+ (void)showForView:(UIView *)view {
    picker = [DevColorPicker new];
    picker.targetView = view;
    [picker show];
}

+ (void)hide {
    [picker.overlay removeFromSuperview];
    [picker.overlay recursivelyCleanup];
    picker = nil;
}

- (void)show {
    _overlay = [UIView.appendTo(_targetView.window).fill render];
    
    CGFloat y;
    CGFloat height;
    if (_targetView.y > [Viewport height]-_targetView.y2) {
        // Above
        y = 0;
        height = _targetView.y;
    } else {
        // Below
        y = _targetView.y2;
        height = [Viewport height]-_targetView.y2;
    }
    
    CGFloat sliderHeight = 30;
    CGFloat buttonHeight = 20;
    CGFloat size = MIN(height, [Viewport width] - sliderHeight*2+buttonHeight);
    _colorWheel = [[ISColorWheel alloc] initWithFrame:CGRectMake(0, y, size, size)];
    _colorWheel.delegate = self;
    _colorWheel.continuous = YES;
    _colorWheel.currentColor = _targetView.backgroundColor;
    [_overlay addSubview:_colorWheel];
    [_colorWheel centerHorizontally];
    
    CGRect sliderFrame = CGRectMake(_colorWheel.x, _colorWheel.y2, _colorWheel.width, sliderHeight);
    _brightnessSlider = [[UISlider alloc] initWithFrame:sliderFrame];
    _brightnessSlider.minimumValue = 0.0;
    _brightnessSlider.maximumValue = 1.0;
    _brightnessSlider.value = _colorWheel.brightness;
    _brightnessSlider.continuous = true;
    [_brightnessSlider addTarget:self action:@selector(onBrigthnessSliderDidChange) forControlEvents:UIControlEventValueChanged];
    [_overlay addSubview:_brightnessSlider];
    
    sliderFrame.origin.y += sliderFrame.size.height;
    _alphaSlider = [[UISlider alloc] initWithFrame:sliderFrame];
    _alphaSlider.minimumValue = 0.0;
    _alphaSlider.maximumValue = 1.0;
    _alphaSlider.value = 1-_targetView.backgroundColor.alpha;
    _alphaSlider.continuous = YES;
    [_alphaSlider addTarget:self action:@selector(onAlphaSliderDidChange) forControlEvents:UIControlEventValueChanged];
    [_overlay addSubview:_alphaSlider];
    
    UIButton* close = [UIButton.appendTo(_overlay).belowLast(0).bg(WHITE).text(@"Close").size.h(buttonHeight).centerHorizontally onTap:^(UIEvent *event) {
        [DevColorPicker hide];
    }];
    
    _rgba = [UILabel.appendTo(_overlay).y(close.y).h(close.height).w(100).bg(WHITE).fillLeftOf(close,0).textFont([UIFont systemFontOfSize:12]) render];
    _hsla = [UILabel.appendTo(_overlay).y(close.y).h(close.height).w(100).bg(WHITE).fillRightOf(close,0).textFont([UIFont systemFontOfSize:12]).textAlignment(NSTextAlignmentRight) render];
    
    [self colorWheelDidChangeColor:_colorWheel];
}

- (void)onBrigthnessSliderDidChange {
    _colorWheel.brightness = _brightnessSlider.value;
    [_colorWheel updateImage];
    [self colorWheelDidChangeColor:_colorWheel];
}

- (void)onAlphaSliderDidChange {
    _colorWheel.alpha = _alphaSlider.value;
    [self colorWheelDidChangeColor:_colorWheel];
}
@end

@implementation DevColorPicker (delegate)
- (void)colorWheelDidChangeColor:(ISColorWheel *)colorWheel {
    CGFloat alpha = _alphaSlider.value;
    UIColor* color = [colorWheel.currentColor withAlpha:_alphaSlider.value];
    _targetView.backgroundColor = color;
    CGFloat red, green, blue;
    [color getRed:&red green:&green blue:&blue alpha:NULL];
    _rgba.text = [NSString stringWithFormat:@"rgba(%03d,%03d,%03d,%.2f)", (int)(red*255), (int)(green*255), (int)(blue*255), alpha];
    CGFloat hue, saturation, brightness;
    [color getHue:&hue saturation:&saturation brightness:&brightness alpha:NULL];
    _hsla.text = [NSString stringWithFormat:@"hsla(%.2f,%.2f,%.2f,%.2f)", hue, saturation, brightness, alpha];
}
@end

