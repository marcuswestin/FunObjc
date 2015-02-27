//
//  PhoneNumberFormattingTextField.h
//  consumer-mobile-ios
//
//  Created by Marcus Westin on 2/27/15.
//  Copyright (c) 2015 Asapp, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^PhoneNumberHandler)(NSString* phoneNumber);

@interface PhoneNumberFormattingTextField : UITextField
- (void)forceHiddenPrefix:(NSString*)forceHiddenPrefix;
- (void)onValid:(PhoneNumberHandler)handler;
@end
