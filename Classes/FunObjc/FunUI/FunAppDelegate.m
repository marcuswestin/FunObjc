//
//  FunAppDelegate.m
//  Dogo-iOS
//
//  Created by Marcus Westin on 7/13/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "FunAppDelegate.h"
#import "Events.h"
#import "Keyboard.h"
#import "Overlay.h"

static FunAppDelegate* instance;

@implementation FunAppDelegate

+ (FunAppDelegate *)instance {
    return instance;
}

// Application launch & state restoration
/////////////////////////////////////////
- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [Files setup];
    _funApp = (id<FunApp>) self;
    [_funApp funAppStyleLabels:[UILabel styles] buttons:[UIButton styles] textFields:[UITextField styles] textViews:[UITextView styles]];
    [_funApp funAppInterfaceWillLoad];
    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    if (!self.window) {
        UIViewController* rootVC = [_funApp funAppRootViewControllerForFreshLoad];
        if (!rootVC.restorationIdentifier) {
            rootVC.restorationIdentifier = rootVC.className;
        }
        [self _loadInterfaceWithRootViewController:rootVC];
    }
    instance = self;
    [self handleLaunchNotification:launchOptions];
    if ([_funApp respondsToSelector:@selector(funAppInterfaceDidLoad:)]) {
        [_funApp funAppInterfaceDidLoad:self.window];
    }
    async(^{
        NSNumber* current = [NSNumber numberWithLong:[[NSDate date] timeIntervalSince1970]];
        [Files writeNumber:current name:@"LastLaunchTime"];
    });
    
#if DEBUG
    [self _setupDevMenu];
#endif
    
    return YES;
}

- (void)_setupDevMenu {
    UIView* devButton = [UILabel.appendTo(self.window).text(@"{D}").radius(8).bg(rgba(123,123,123,.5)).size.outsetAll(4).x(4).fromBottom(50).textCenter render];
    DragAndDrop* drag = [DragAndDrop forView:devButton];
    [drag onTap:^(UITapGestureRecognizer *tap) {
        [self _showDevMenu];
    }];
}

void _forceCrash() {
    int *x = NULL;
    *x = 42;
}

- (void)_showDevMenu {
    UIView* overlay = [Overlay show];
    [UIButton.appendTo(overlay).text(@"Reset State").size.center onTap:self selector:@selector(resetState)];
    [UIButton.appendTo(overlay).text(@"Crash").size.center.belowLast(10) onTap:self selector:@selector(crash)];
}

- (void)resetState {
    [Files resetFileRoot];
    [Overlay showMessage:@"State has been reset.\nApp will close in 1 second."];
    after(1, ^{
        _forceCrash();
    });
}

- (void)crash {
    async(^{
        _forceCrash();
    });
}

// View state saving
- (BOOL)application:(UIApplication *)application shouldSaveApplicationState:(NSCoder *)coder {
    return YES;
}
- (void)application:(UIApplication *)application willEncodeRestorableStateWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.window.rootViewController forKey:@"FunRootViewController"]; // TODO Versioning
}
// View state restoration
- (BOOL)application:(UIApplication *)application shouldRestoreApplicationState:(NSCoder *)coder {
    return ![Files didReset];
}
- (void)application:(UIApplication*)application didDecodeRestorableStateWithCoder:(NSCoder *)coder {
    id root = [coder decodeObjectForKey:@"FunRootViewController"]; // TODO Versioning
    if (root) {
        [self _loadInterfaceWithRootViewController:root];
    }
}
// View state utils
- (void)_loadInterfaceWithRootViewController:(UIViewController*)rootViewController {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.restorationIdentifier = NSStringFromClass([self class]);
    self.window.rootViewController = rootViewController;
    [self.window makeKeyAndVisible];
}
- (UIViewController*)application:(UIApplication *)application viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder {
    Class ViewControllerClass = NSClassFromString(identifierComponents.lastObject);
    // TODO Versioning
    if (!ViewControllerClass) {
        return nil;
    }
    UIViewController* viewController = [[ViewControllerClass alloc] initWithCoder:coder];
    if (!viewController.restorationIdentifier) {
        viewController.restorationIdentifier = viewController.className;
    }
    return viewController;
}

// Push notifications
/////////////////////
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [Events fire:@"Application.didRegisterForRemoteNotificationsWithDeviceToken" info:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)err {
    [Events fire:@"Application.didFailToRegisterForRemoteNotificationsWithError" info:err];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)notification {
    [Events fire:@"Application.didReceiveRemoteNotification" info:notification];
}

- (void)handleLaunchNotification:(NSDictionary*)launchOptions {
    NSDictionary* launchNotification = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
    if (launchNotification) {
        [Events fire:@"Application.didLaunchWithNotification" info:launchNotification];
    }
}

// Lifecycle events
///////////////////
- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    [Events syncFire:@"Application.willResignActive"];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [Events syncFire:@"Application.didEnterBackground"];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [Events syncFire:@"Application.willEnterForeground"];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [Events syncFire:@"Application.didBecomeActive"];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [Events syncFire:@"Application.willTerminate"];
}


@end
