//
//  Locations.m
//  ivyq
//
//  Created by Marcus Westin on 10/22/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "Locations.h"
#import <CoreLocation/CoreLocation.h>

Locations* instance;

@implementation Locations

+ (void)initialize {
    instance = [Locations new];
    instance.manager = [CLLocationManager new];
    instance.manager.delegate = instance;
}

+ (void)getCurrentLocation:(LocationCallback)callback {
    instance.locationCallback = callback;
    [instance.manager startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    [instance.manager stopUpdatingLocation];
    LocationCallback callback;
    @synchronized(instance) {
        callback = instance.locationCallback;
        if (!callback) { return; }
        instance.locationCallback = nil;
    }
    callback(locations.lastObject);
}

@end
