//
//  AddressBookContact.h
//  Dogo iOS
//
//  Created by Marcus Westin on 10/9/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>
#import "FunObjc.h"

@interface AddressBookContact : State
@property ABRecordID recordId;
@property NSString* firstName;
@property NSString* lastName;
@property NSArray* phoneNumbers;
@property NSArray* emailAddresses;
@property BOOL hasImage;
@property NSDate* birthday;
- (UIImage*)image;
- (UIImage*)imageWithAddressBook:(ABAddressBookRef)addressBook;
- (NSString*)displayName;
@end
