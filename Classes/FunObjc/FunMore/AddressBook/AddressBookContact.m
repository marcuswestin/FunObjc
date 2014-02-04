//
//  AddressBookContact.m
//  Dogo iOS
//
//  Created by Marcus Westin on 10/9/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "AddressBookContact.h"
#import "PhoneNumbers.h"

@implementation AddressBookContact {
    UIImage* _image;
}
- (UIImage *)image {
    if (!_image) {
        ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
        if (!addressBook) {
            NSLog(@"Could not open address book. Use [AddressBook authorize:] and [AddressBook authorizationStatus].");
            return nil;
        }
        _image = [self imageWithAddressBook:addressBook];
        CFRelease(addressBook);
    }
    return _image;
}
- (UIImage *)imageWithAddressBook:(ABAddressBookRef)addressBook {
    ABRecordRef person = ABAddressBookGetPersonWithRecordID(addressBook, _recordId);
    NSData* data = (__bridge NSData *)(ABPersonCopyImageData(person));
    return [UIImage imageWithData:data];
}
- (NSString *)displayName {
    if (_firstName.hasContent && _lastName.hasContent) {
        return [NSString stringWithFormat:@"%@ %@", _firstName, _lastName];
    }
    if (_firstName.hasContent) {
        return _firstName;
    }
    if (_lastName.hasContent) {
        return _lastName;
    }
    if (_phoneNumbers.count) {
        return _phoneNumbers.firstObject;
    }
    if (_emailAddresses.count) {
        return _emailAddresses.firstObject;
    }
    return @"(no name)";
}
- (NSString *)displayAddress {
    NSLog(@"TODO Figure out AddressBookContact displayAddress");
    if (_phoneNumbers.count) {
        return [PhoneNumbers format:_phoneNumbers.firstObject];
    } else {
        return _emailAddresses.firstObject;
    }
}

- (NSString *)initials {
    if (!_firstName.hasContent || !_lastName.hasContent) {
        return @"?";
    } else {
        return [NSString stringWithFormat:@"%@%@", [_firstName substringToIndex:1], [_lastName substringToIndex:1]];
    }
}
@end
