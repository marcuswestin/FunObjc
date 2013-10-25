//
//  Locations.h
//  ivyq
//
//  Created by Marcus Westin on 10/22/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

typedef void(^LocationCallback)(CLLocation* location);
@interface Locations : NSObject <CLLocationManagerDelegate>

@property CLLocationManager* manager;
@property (copy)LocationCallback locationCallback;

+ (void)getCurrentLocation:(LocationCallback)callback;

@end
