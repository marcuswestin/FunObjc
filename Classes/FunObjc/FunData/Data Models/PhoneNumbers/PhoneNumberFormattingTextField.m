//
//  PhoneNumberFormattingTextField.m
//  consumer-mobile-ios
//
//  Created by Marcus Westin on 2/27/15.
//  Copyright (c) 2015 Asapp, Inc. All rights reserved.
//

#import "PhoneNumberFormattingTextField.h"
#import "FunObjc.h"

@interface PhoneNumberFormattingTextField () <UITextFieldDelegate>
@property NSString* hiddenPrefix;
@property (copy) PhoneNumberHandler onValidHandler;
@end
@implementation PhoneNumberFormattingTextField

static NSCharacterSet* phoneNumberCharacterSet;
+ (void)initialize {
    phoneNumberCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"1234567890+"];
}

- (instancetype)init {
    return [self initWithFrame:CGRectZero];
}
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.delegate = self;
        self.hiddenPrefix = @"";
    }
    return self;
}

- (void)forceHiddenPrefix:(NSString *)forceHiddenPrefix {
    _hiddenPrefix = forceHiddenPrefix;
}

- (void)onValid:(PhoneNumberHandler)handler {
    assert(_onValidHandler == nil);
    _onValidHandler = handler;
}

- (NSUInteger)findAnchorCharacterInText:(NSString*)text location:(NSUInteger)location step:(NSUInteger)step {
    while (true) {
        unichar character = [text characterAtIndex:location];
        if ([phoneNumberCharacterSet characterIsMember:character]) {
            return location;
        } else if (location == 0 || location == text.length - 1) {
            return location;
        } else {
            location += step;
            continue;
        }
    }
}

- (NSUInteger)findLocationOfAnchorCharacter:(unichar)anchorChar withCount:(NSUInteger)anchorCharCount inText:(NSString*)text {
    NSUInteger location = 0;
    while (anchorCharCount > 0) {
        if ([text characterAtIndex:location] == anchorChar) {
            anchorCharCount -= 1;
        }
        location += 1;
    }
    return location;
}

- (NSString *)text {
    return [_hiddenPrefix append:[super text]];
}

- (BOOL)textField:(UITextField *)_ shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacementString {
    assert(range.length == 0 || range.length == 1);
    assert(replacementString.length == 0 || replacementString.length == 1);
    
    NSString* rawText = [super text]; // excluding hidden prefix
    NSString* dirtyText = [rawText stringByReplacingCharactersInRange:range withString:replacementString];
    if ([dirtyText stringByRemovingCharactersOutsideCharacterSet:phoneNumberCharacterSet].length == 0) {
        [self setText:@""];
        return NO;
    }
    NSUInteger anchorCharLocation;
    if (replacementString.length == 0) {
        // Single character deletion: find anchor character preceeding current location
        anchorCharLocation = range.location - 1;
        while (![phoneNumberCharacterSet characterIsMember:[dirtyText characterAtIndex:anchorCharLocation]] && anchorCharLocation > 0) {
            anchorCharLocation -= 1;
        }
    } else {
        // Single character addition: find anchor character after current location
        anchorCharLocation = range.location;
        while (![phoneNumberCharacterSet characterIsMember:[dirtyText characterAtIndex:anchorCharLocation]] && anchorCharLocation < dirtyText.length) {
            anchorCharLocation += 1;
        }
    }
    unichar anchorChar = [dirtyText characterAtIndex:anchorCharLocation];
    NSUInteger anchorCharCount = [dirtyText countOccurancesOfCharacter:anchorChar precedingIndex:anchorCharLocation] + 1;
    
    // Ready to format and find anchor character in formatted text
    NSString* fullFormattedNumber = [PhoneNumbers format:[_hiddenPrefix stringByAppendingString:dirtyText]];
    NSString* formattedText = [fullFormattedNumber substringFromIndex:_hiddenPrefix.length];
    if (_onValidHandler && [PhoneNumbers isValid:fullFormattedNumber]) {
        async(^{ _onValidHandler(fullFormattedNumber); });
    }
    
    NSUInteger newAnchorCharLocation = [self findLocationOfAnchorCharacter:anchorChar withCount:anchorCharCount inText:formattedText];
    [self setText:formattedText];
    [self setSelectedRange:NSRangeMake(newAnchorCharLocation, 0)];
    
    return NO;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(paste:) ||
        action == @selector(cut:) ||
        action == @selector(copy:) ||
        action == @selector(select:) ||
        action == @selector(selectAll:) ||
        action == @selector(delete:) ||
        action == @selector(makeTextWritingDirectionLeftToRight:) ||
        action == @selector(makeTextWritingDirectionRightToLeft:) ||
        action == @selector(toggleBoldface:) ||
        action == @selector(toggleItalics:) ||
        action == @selector(toggleUnderline:)) {
        return NO;
    }
    return [super canPerformAction:action withSender:sender];
}
@end
