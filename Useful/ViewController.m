//
//  ViewController.m
//  Dogo-iOS
//
//  Created by Marcus Westin on 6/26/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "ViewController.h"
#import "FunObjc.h"

static UIColor* defaultBackgroundColor;

@implementation ViewController {
    BOOL _didRender;
}

+ (void)load {
    defaultBackgroundColor = [UIColor clearColor];
}

+ (instancetype)withoutState {
    return [[[self class] alloc] initWithState:nil];
}

+ (instancetype)withState:(State *)state {
    return [[[self class] alloc] initWithState:state];
}

+ (void)setDefaultBackgroundColor:(UIColor *)color {
    defaultBackgroundColor = color;
}

- (instancetype)init {
    return [self initWithState:nil];
}
- (instancetype)initWithState:(id<NSCoding>)state {
    self = [super initWithNibName:nil bundle:nil];
    self.state = state;
    return self;
}
- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    [self decodeRestorableStateWithCoder:coder];
    return self;
}

- (NSString *)restorationIdentifier {
    return self.className;
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [super encodeRestorableStateWithCoder:coder];
    [coder encodeObject:self.title forKey:@"FunVCTitle"];
    [coder encodeObject:self.state forKey:@"FunVCState"];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    [super decodeRestorableStateWithCoder:coder];
    NSString* title = [coder decodeObjectForKey:@"FunVCTitle"];
    if (title) {
        self.title = title;
    }
    self.state = [coder decodeObjectForKey:@"FunVCState"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (_didRender) { return; }
    _didRender = YES;
    self.view.backgroundColor = defaultBackgroundColor;
    self.view.opaque = (defaultBackgroundColor.alpha == 1.0);
    [self beforeRender:animated];
    [self render:animated];
    [self afterRender:animated];
}

- (void)beforeRender:(BOOL)animated{} // Private hook - see e.g. ListViewController
- (void)render:(BOOL)animated {
    [UILabel.appendTo(self.view).text(@"You should implement -render in your ViewController").wrapText.center render];
}
- (void)afterRender:(BOOL)animated{} // Private hook - see e.g. ListViewController

- (void)pushViewController:(ViewController *)viewController {
    [self.navigationController pushViewController:viewController animated:YES];
}

- (NavigationController *)nav {
    return ([self.navigationController isMemberOfClass:[NavigationController class]]
            ? (NavigationController*)self.navigationController
            : nil);
}

@end
