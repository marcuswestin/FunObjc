//
//  UITextField+Fun.m
//  Dogo iOS
//
//  Created by Marcus Westin on 12/10/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "UITextField+Fun.h"
#import "FunBase.h"

@interface UITextFieldFunDelegate : NSObject<UITextFieldDelegate>
@property NSPredicate* excludePredicate;
@property NSUInteger maxLength;
@property (copy)ShouldChangeStringCallback shouldChangeStringCallback;
@end
@implementation UITextFieldFunDelegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if ([_excludePredicate evaluateWithObject:string]) {
        return NO;
    }
    if (_maxLength && textField.text.length - range.length + string.length > _maxLength) {
        return NO;
    }
    NSString* toString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    if (_shouldChangeStringCallback) {
        return _shouldChangeStringCallback(textField.text, toString, range, string);
    }
    return YES;
}
@end

@implementation UITextField (Fun)
- (void)bindTextTo:(NSMutableString *)str {
    if (!str || str.isNull) {
        DLog(@"WARNING UITextField -bindTextTo: got nil string");
        return;
    }
    self.text = str;
    [self onChange:^(UIEvent *event) {
        [str setString:self.text];
    }];
}
- (UITextFieldFunDelegate*) funDelegate {
    UITextFieldFunDelegate* delegate = GetProperty(self, @"FunDelegate");
    if (delegate) {
        if (![delegate isKindOfClass:[UITextFieldFunDelegate class]]) {
            [NSException raise:@"" format:@"UITextField (Fun) has already been assigned a delegate"];
        }
    } else {
        delegate = [UITextFieldFunDelegate new];
        SetProperty(self, @"FunDelegate", delegate);
        self.delegate = delegate;
    }
    return delegate;
}
- (void)excludeInputsMatching:(NSString *)pattern {
    UITextFieldFunDelegate* delegate = [self funDelegate];
    if (delegate.excludePredicate) {
        [NSException raise:@"" format:@"excludeInputsMatching: called multiple times on the same input"];
    }
    delegate.excludePredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", pattern];
}
- (void)limitLengthTo:(NSUInteger)maxLength {
    [self funDelegate].maxLength = maxLength;
}
- (void)shouldChange:(ShouldChangeStringCallback)shouldChangeStringCallback {
    [self funDelegate].shouldChangeStringCallback = shouldChangeStringCallback;
}
@end
