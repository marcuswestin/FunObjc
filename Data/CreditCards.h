//
//  CreditCard.h
//  ivyq
//
//  Created by Marcus Westin on 10/15/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "State.h"

@interface CreditCard : State
@property (readonly) NSString* number;
@property (readonly) NSString* cvv;
@property (readonly) NSString* zip;
@property (readonly) NSString* month;
@property (readonly) NSString* year;
- (NSString*)obscuredNumber;
- (NSString*)obscuredCvv;
- (NSString*)obscuredZip;
- (NSString*)obscuredMonth;
- (NSString*)obscuredYear;

- (void)bindNumber:(UITextField*)numberInput cvv:(UITextField*)cvvInput zip:(UITextField*)zipInput month:(UITextField*)monthInput year:(UITextField*)yearInput;

+ (NSString*)formatNumber:(NSString*)number;
@end
