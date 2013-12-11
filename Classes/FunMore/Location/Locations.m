//
//  Locations.m
//  ivyq
//
//  Created by Marcus Westin on 10/22/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "Locations.h"
#import <CoreLocation/CoreLocation.h>
#import "FunObjc.h"

Locations* instance;

@interface Locations ()
@property CLLocation* mockLocation;
@end

@implementation Locations

+ (void)load {
    instance = [Locations new];
    instance.manager = [CLLocationManager new];
    instance.manager.delegate = instance;
}

+ (void)getCurrentLocation:(LocationCallback)callback {
    if (instance.mockLocation) {
        async(^{
            callback(instance.mockLocation);
        });
    } else {
        instance.locationCallback = callback;
        [instance.manager startUpdatingLocation];
    }
}

#ifdef DEBUG
+ (void)debugSetMockLocation:(CLLocation *)location {
    instance.mockLocation = location;
}
#endif

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation* location = locations.lastObject;
    [instance.manager stopUpdatingLocation];
    LocationCallback callback;
    @synchronized(instance) {
        callback = instance.locationCallback;
        if (!callback) { return; }
        instance.locationCallback = nil;
    }
    asyncMain(^{
        callback(location);
    });
}

@end
