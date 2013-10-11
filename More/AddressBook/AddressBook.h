//
//  AddressBook.h
//  Dogo iOS
//
//  Created by Marcus Westin on 10/9/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FunObjc.h"
#import <AddressBook/AddressBook.h>
#import "AddressBookContact.h"

typedef void(^ContactsCallback)(NSArray* contacts);

@interface AddressBook : NSObject

+ (void)preloadAllContacts;
+ (void)loadAllContacts:(ContactsCallback)callback;
+ (void)authorize:(AuthorizeCallback)callback;
+ (NSString*)authorizationStatus;

+ (void)findContactsMatchingPredicate:(NSPredicate*)predicate callback:(ContactsCallback)callback;
+ (void)findContactsWithPhoneNumber:(NSString*)phoneNumber callback:(ContactsCallback)callback;
+ (void)findContactsWithEmailAddress:(NSString*)emailAddress callback:(ContactsCallback)callback;

@end
