//
//  PhoneNumbers.h
//  Dogo-iOS
//
//  Created by Marcus Westin on 6/27/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PhoneNumberFormattingTextField.h"

@interface PhoneNumbers : NSObject
+ (NSString*)format:(NSString*)phoneNumber;
+ (BOOL)isValid:(NSString*)phoneNumber;
+ (NSString*)normalize:(NSString*)phoneNumber;
+ (BOOL)isUSPhoneNumber:(NSString*)normalizedPhoneNumber;
@end
