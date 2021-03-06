//
//  AddressBook.m
//  Dogo iOS
//
//  Created by Marcus Westin on 10/9/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "AddressBook.h"
#import "PhoneNumbers.h"
#import "EmailAddresses.h"

@implementation AddressBook

+ (void)authorize:(AuthorizeCallback)callback {
    callback = [self _wrapAuthorize:callback];
    
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    if (!addressBook) {
        id err = makeError(@"Could not open address book");
        return callback(err, NO);
    }
    ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
        if (error) { return callback((__bridge id)(error), NO); }
        return callback(nil, granted);
    });
}

+ (ABAuthorizationStatus)authorizationStatus {
    return ABAddressBookGetAuthorizationStatus();
}

+ (NSString *)authorizationStatusString {
    ABAuthorizationStatus status = ABAddressBookGetAuthorizationStatus();
    switch (status) {
        case kABAuthorizationStatusNotDetermined: return @"Not determined";
        case kABAuthorizationStatusRestricted: return @"Restricted";
        case kABAuthorizationStatusAuthorized: return @"Authorized";
        case kABAuthorizationStatusDenied: return @"Denied";
        default: return @"Unknown";
    }
}

+ (void)findContactsMatchingPredicate:(NSPredicate *)predicate callback:(ContactsCallback)callback {
    callback = [self _wrapContacts:callback];
    [AddressBook loadAllContacts:^(NSArray *contacts) {
        asyncDefault(^{
            NSArray* filteredContacts = [contacts filteredArrayUsingPredicate:predicate];
            callback(filteredContacts);
        });
    }];
}

+ (void)findContactsWithEmailAddress:(NSString *)emailAddress callback:(ArrayCallback)callback {
    NSString* normalized = [EmailAddresses normalize:emailAddress];
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"emailAddresses contains %@", normalized];
    [AddressBook findContactsMatchingPredicate:predicate callback:callback];
}

+ (void)findContactsWithPhoneNumber:(NSString *)phoneNumber callback:(ArrayCallback)callback {
    NSString* normalized = [PhoneNumbers normalize:phoneNumber];
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"phoneNumbers contains %@", normalized];
    DLog(@"Find contacts with %@", normalized);
    [AddressBook findContactsMatchingPredicate:predicate callback:callback];
}

+ (void)preloadAllContacts {
    static BOOL preloaded;
    if (preloaded) { return; }
    preloaded = YES;
    DLog(@"AddressBook: preloading all contacts into memory");
    [self loadAllContacts:^(NSArray *contacts) {
        DLog(@"AddressBook: all contacts preloaded into memory");
    }];
}

+ (ContactsCallback)_wrapContacts:(ContactsCallback)callback {
    return ^(NSArray* contacts) {
        asyncMain(^{ callback(contacts); });
    };
}

+ (AuthorizeCallback)_wrapAuthorize:(AuthorizeCallback)callback {
    return ^(NSError* err, BOOL authorized) {
        asyncMain(^{ callback(err, authorized); });
    };
}

static NSArray* allContacts;
+ (void)loadAllContacts:(ContactsCallback)callback {
    callback = [self _wrapContacts:callback];
    
    asyncDefault(^{
        if (AddressBook.authorizationStatus != kABAuthorizationStatusAuthorized) {
            DLog(@"WARNING [AddressBook loadContacts]: non-authorized status %@", AddressBook.authorizationStatusString);
            return callback(nil);
        }
        @synchronized(self) {
            if (allContacts) {
                return callback(allContacts);
            }
            
            ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
            if (!addressBook) {
                DLog(@"Could not open address book. Use [AddressBook authorize:] and [AddressBook authorizationStatus].");
                callback(nil);
                return;
            }
            
            NSUInteger numPeople = (NSUInteger)ABAddressBookGetPersonCount(addressBook);
            CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeople(addressBook);
            NSMutableArray* entries = [NSMutableArray arrayWithCapacity:numPeople];
            NSArray* emptyArray = @[];
            for (int i=0; i<numPeople; i++ ) {
                ABRecordRef person = CFArrayGetValueAtIndex(allPeople, i);
                
                AddressBookContact* contact = [AddressBookContact new];
                contact.recordId = ABRecordGetRecordID(person);
                contact.firstName = (__bridge NSString *)ABRecordCopyValue(person, kABPersonFirstNameProperty);
                contact.lastName = (__bridge NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty);
                contact.hasImage = ABPersonHasImageData(person);
                contact.birthday = (__bridge NSDate *)ABRecordCopyValue(person, kABPersonBirthdayProperty);
                
                ABMultiValueRef emailProperty = ABRecordCopyValue(person, kABPersonEmailProperty);
                NSArray* emailAddresses = (__bridge NSArray *)ABMultiValueCopyArrayOfAllValues(emailProperty);
                if (emailAddresses.count > 0) {
                    NSMutableArray* normalizedEmailAddresses = [NSMutableArray arrayWithCapacity:emailAddresses.count];
                    [emailAddresses each:^(id val, NSUInteger i) {
                        NSString* normalized = [EmailAddresses normalize:val];
                        if (normalized) {
                            [normalizedEmailAddresses addObject:normalized];
                        }
                    }];
                    contact.emailAddresses = normalizedEmailAddresses;
                } else {
                    contact.emailAddresses = emptyArray;
                }
                
                ABMultiValueRef phoneProperty = ABRecordCopyValue(person, kABPersonPhoneProperty);
                NSArray* phoneNumbers = (__bridge NSArray *)ABMultiValueCopyArrayOfAllValues(phoneProperty);
                if (phoneNumbers.count > 0) {
                    NSMutableArray* normalizedPhoneNumbers = [NSMutableArray arrayWithCapacity:phoneNumbers.count];
                    [phoneNumbers each:^(id val, NSUInteger i) {
                        NSString* normalized = [PhoneNumbers normalize:val];
                        if (normalized) {
                            [normalizedPhoneNumbers addObject:normalized];
                        }
                    }];
                    contact.phoneNumbers = normalizedPhoneNumbers;
                } else {
                    contact.phoneNumbers = emptyArray;
                }
                
                entries[i] = contact;
            }
            CFRelease(addressBook);
            CFRelease(allPeople);
            
            allContacts = entries;
            return callback(allContacts);
        }
    });
}

+ (void)addRecordWithPhoneNumber:(NSString *)phoneNumber firstName:(NSString *)firstName lastName:(NSString *)lastName image:(UIImage *)image callback:(AddressBookRecordIdCallback)_callback {
    void (^callback)(ABRecordID, CFErrorRef) = ^(ABRecordID recordId, CFErrorRef error) {
        return _callback(recordId,(__bridge NSError *)(error));
    };
    
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    if (!addressBook) {
        return callback(0, nil);
    }
    ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
        if (error != NULL) {
            return callback(0, error);
        }
        if (!granted) {
            return callback(0, NULL);
        }
        
        ABRecordRef newPerson = ABPersonCreate();
        
        if (firstName) {
            if (!ABRecordSetValue(newPerson, kABPersonFirstNameProperty, (__bridge CFTypeRef)(firstName), &error)) {
                return callback(0, error);
            }
        }
        
        if (lastName) {
            if (!ABRecordSetValue(newPerson, kABPersonLastNameProperty, (__bridge CFTypeRef)(lastName), &error)) {
                return callback(0, error);
            }
        }
        
        if (phoneNumber) {
            ABMutableMultiValueRef multiPhone = ABMultiValueCreateMutable(kABMultiStringPropertyType);
            ABMultiValueAddValueAndLabel(multiPhone, (__bridge CFTypeRef)(phoneNumber), kABPersonPhoneMainLabel, NULL);
            bool success = ABRecordSetValue(newPerson, kABPersonPhoneProperty, multiPhone, &error);
            CFRelease(multiPhone);
            if (!success) {
                return callback(0, error);
            }
        }

        if (image) {
            NSData *dataRef = UIImagePNGRepresentation(image);
            if (!ABPersonSetImageData(newPerson, (__bridge CFDataRef)dataRef, &error)) {
                return callback(0, error);
            }
        }
        
        if (!ABAddressBookAddRecord(addressBook, newPerson, &error)) {
            return callback(0, error);
        }
        
        if (!ABAddressBookSave(addressBook, &error)) {
            return callback(0, error);
        }
        
        ABRecordID recordId = ABRecordGetRecordID(newPerson);
        CFRelease(newPerson);
        CFRelease(addressBook);

        callback(recordId, nil);
    });
}

+ (void)removeRecord:(ABRecordID)recordId callback:(ErrorCallback)_callback {
    void (^callback)(CFErrorRef) = ^(CFErrorRef error) {
        return _callback((__bridge NSError *)(error));
    };

    CFErrorRef error;

    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, &error);
    if (!addressBook) {
        return callback(error);
    }
    
    ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
        if (error) {
            return callback(error);
        }
        if (!granted) {
            return _callback(makeError(@"Could not open address book"));
        }
        
        ABRecordRef record = ABAddressBookGetPersonWithRecordID(addressBook, recordId);
        ABAddressBookRemoveRecord(addressBook, record, &error);
        CFRelease(record);
        CFRelease(addressBook);
        
        callback(error);
    });
}

@end
