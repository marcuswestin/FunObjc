//
//  CreditCard.m
//  ivyq
//
//  Created by Marcus Westin on 10/15/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "CreditCards.h"
#import "NSString+Fun.h"
#import "UIView+Fun.h"
#import "UIControl+Fun.h"

@implementation CreditCard {
    UITextField* _numberInput;
    UITextField* _cvvInput;
    UITextField* _zipInput;
    UITextField* _monthInput;
    UITextField* _yearInput;
}

@synthesize number=_number;
@synthesize cvv=_cvv;
@synthesize zip=_zip;
@synthesize month=_month;
@synthesize year=_year;

- (NSString*)number {
    return (self.isEdited ? [_numberInput.text stringByRemovingWhitespace] : _number);
}
- (NSString*)cvv {
    return (self.isEdited ? [_cvvInput.text stringByRemovingWhitespace] : _cvv);
}
- (NSString*)zip {
    return (self.isEdited ? [_zipInput.text stringByRemovingWhitespace] : _zip);
}
- (NSString*)month {
    return (self.isEdited ? [_monthInput.text stringByRemovingWhitespace] : _month);
}
- (NSString*)year {
    return (self.isEdited ? [_yearInput.text stringByRemovingWhitespace] : _year);
}

- (BOOL)isEdited {
    return !([_numberInput.text is:self.obscuredNumber]
             && [_cvvInput.text is:self.obscuredCvv]
             && [_zipInput.text is:self.obscuredZip]
             && [_monthInput.text is:self.obscuredMonth]
             && [_yearInput.text is:self.obscuredYear]);
}

- (BOOL)isEmpty {
    return ([_numberInput.text isEmpty]
            && [_cvvInput.text isEmpty]
            && [_zipInput.text isEmpty]
            && [_monthInput.text isEmpty]
            && [_yearInput.text isEmpty]);
}

- (NSString *)obscuredNumber {
    return [NSString stringWithFormat:@"Card ending in %@", [_number substringFromIndex:12]];
}
- (NSString *)obscuredCvv {
    return [NSString repeat:@"*" times:_cvv.length];
}
- (NSString*)obscuredZip {
    return [NSString repeat:@"*" times:_zip.length];
}
- (NSString *)obscuredMonth {
    return [NSString repeat:@"*" times:_month.length];
}
- (NSString *)obscuredYear {
    return [NSString repeat:@"*" times:_year.length];
}

- (void)bindNumber:(UITextField *)numberInput cvv:(UITextField *)cvvInput zip:(UITextField *)zipInput month:(UITextField *)monthInput year:(UITextField *)yearInput {
    _numberInput = numberInput;
    _cvvInput = cvvInput;
    _zipInput = zipInput;
    _monthInput = monthInput;
    _yearInput = yearInput;
    
    numberInput.keyboardType = UIKeyboardTypeNumberPad;
    cvvInput.keyboardType = UIKeyboardTypeNumberPad;
    zipInput.keyboardType = UIKeyboardTypeNumberPad;
    monthInput.keyboardType = UIKeyboardTypeNumberPad;
    yearInput.keyboardType = UIKeyboardTypeNumberPad;
    
    if (!numberInput.placeholder) {
        numberInput.placeholder = @"Credit card number";
    }
    if (!cvvInput.placeholder) {
        cvvInput.placeholder = @"CVV";
    }
    if (!zipInput.placeholder) {
        zipInput.placeholder = @"Zip code";
    }
    if (!monthInput.placeholder) {
        monthInput.placeholder = @"MM";
    }
    if (!yearInput.placeholder) {
        yearInput.placeholder = @"YYYY";
    }
    
    if (_number && [numberInput.text isEmpty]) {
        numberInput.text = [self obscuredNumber];
        cvvInput.text = [self obscuredCvv];
        zipInput.text = [self obscuredZip];
        monthInput.text = [self obscuredMonth];
        yearInput.text = [self obscuredYear];
    }
    
    NSString* nonDigits = @"[^\\d]";
    [cvvInput excludeInputsMatching:nonDigits];
    [cvvInput limitLengthTo:4];
    [zipInput excludeInputsMatching:nonDigits];
    [zipInput limitLengthTo:5];
    [monthInput excludeInputsMatching:nonDigits];
    [monthInput limitLengthTo:2];
    [yearInput excludeInputsMatching:nonDigits];
    [yearInput limitLengthTo:4];
    [numberInput shouldChange:^BOOL(NSString *fromString, NSString *toString, NSRange replacementRange, NSString *replacementString) {
        return [self checkInput:numberInput obscured:self.obscuredNumber toString:toString newAddition:replacementString];
    }];
    [cvvInput shouldChange:^BOOL(NSString *fromString, NSString *toString, NSRange replacementRange, NSString *replacementString) {
        return [self checkInput:cvvInput obscured:self.obscuredCvv toString:toString newAddition:replacementString];
    }];
    [zipInput shouldChange:^BOOL(NSString *fromString, NSString *toString, NSRange replacementRange, NSString *replacementString) {
        return [self checkInput:zipInput obscured:self.obscuredZip toString:toString newAddition:replacementString];
    }];
    [monthInput shouldChange:^BOOL(NSString *fromString, NSString *toString, NSRange replacementRange, NSString *replacementString) {
        return [self checkInput:monthInput obscured:self.obscuredMonth toString:toString newAddition:replacementString];
    }];
    [yearInput shouldChange:^BOOL(NSString *fromString, NSString *toString, NSRange replacementRange, NSString *replacementString) {
        return [self checkInput:yearInput obscured:self.obscuredYear toString:toString newAddition:replacementString];
    }];
}

- (BOOL)checkInput:(UITextField*)input obscured:(NSString*)obscuredString toString:(NSString*)potentialNewString newAddition:(NSString*)replacementString {
    if ([input.text is:obscuredString]) {
        _numberInput.text = @"";
        _cvvInput.text = @"";
        _zipInput.text = @"";
        _monthInput.text = @"";
        _yearInput.text = @"";
        input.text = replacementString; // The keyboard input that triggered the check should receive the new input entry
        return NO;
    } else if ([potentialNewString isEmpty]) {
        input.text = @"";
        // If all inputs are empty, refill with obscured strings
        if ([self isEmpty]) {
            _numberInput.text = self.obscuredNumber;
            _cvvInput.text = self.obscuredCvv;
            _zipInput.text = self.obscuredZip;
            _monthInput.text = self.obscuredMonth;
            _yearInput.text = self.obscuredYear;
        }
        return NO;
    } else {
        return YES;
    }
}

+ (NSString *)formatNumber:(NSString *)number {
    if (![number matchesPattern:@"^[\\d ]*$"]) {
        return @"";
    }
    NSString* digits = [number stringByRemovingPattern:@"[^\\d]"];
    if (digits.length > 16) {
        digits = [digits substringToIndex:16];
    }
    return [digits stringByInjecting:@" " every:4];
}

@end
