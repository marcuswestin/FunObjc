//
//  FunBase.h
//  Dogo-iOS
//
//  Created by Marcus Westin on 6/25/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "CreditCards.h"
#import "EmailAddresses.h"
#import "Money.h"
#import "State.h"
#import "PhoneNumbers.h"

id GetProperty(id obj, NSString* key);
void SetProperty(id obj, NSString* key, id val);
void SetPropertyCopy(id obj, NSString* key, id val);
void SetPropertyAssign(id obj, NSString* key, id val);
NSArray* GetPropertyNames(Class cls);
NSDictionary* GetClassProperties(Class cls);