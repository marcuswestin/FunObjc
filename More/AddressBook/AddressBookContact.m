//
//  AddressBookContact.m
//  Dogo iOS
//
//  Created by Marcus Westin on 10/9/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "AddressBookContact.h"

@implementation AddressBookContact
- (UIImage *)image {
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    if (!addressBook) {
        NSLog(@"Could not open address book. Use [AddressBook authorize:] and [AddressBook authorizationStatus].");
        return nil;
    }
    
    ABRecordRef person = ABAddressBookGetPersonWithRecordID(addressBook, _recordId);
    NSData* data = (__bridge NSData *)(ABPersonCopyImageData(person));
    return [UIImage imageWithData:data];
}
@end
