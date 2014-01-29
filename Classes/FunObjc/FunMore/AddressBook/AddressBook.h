//
//  AddressBook.h
//  Dogo iOS
//
//  Created by Marcus Westin on 10/9/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "FunObjc.h"
#import <AddressBook/AddressBook.h>
#import "AddressBookContact.h"

typedef void(^ContactsCallback)(NSArray* contacts);
typedef void(^AddressBookContactCallback)(AddressBookContact* contact);
typedef void(^AddressBookRecordIdCallback)(ABRecordID recordId, NSError* error);

@interface AddressBook : NSObject

+ (void)preloadAllContacts;
+ (void)loadAllContacts:(ContactsCallback)callback;
+ (void)authorize:(AuthorizeCallback)callback;
+ (ABAuthorizationStatus)authorizationStatus;
+ (NSString*)authorizationStatusString;

+ (void)findContactsMatchingPredicate:(NSPredicate*)predicate callback:(ContactsCallback)callback;
+ (void)findContactsWithPhoneNumber:(NSString*)phoneNumber callback:(ContactsCallback)callback;
+ (void)findContactsWithEmailAddress:(NSString*)emailAddress callback:(ContactsCallback)callback;

+ (void)addRecordWithPhoneNumber:(NSString*)phoneNumber firstName:(NSString*)firstName lastName:(NSString*)lastName image:(UIImage*)image callback:(AddressBookRecordIdCallback)callback;
+ (void)removeRecord:(ABRecordID)recordId callback:(ErrorCallback)callback;
@end
