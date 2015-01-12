//
//  ViewController.m
//  Dogo-iOS
//
//  Created by Marcus Westin on 6/26/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "FunViewController.h"
#import "FunObjc.h"

static UIColor* defaultBackgroundColor;
static NSUInteger deallocCount;

@implementation FunViewController {
    BOOL _didRender;
    BOOL _didCleanup;
}

- (void)dealloc {
    deallocCount += 1;
}

- (void)_funViewControllerCleanup {
    [self cleanup];
}
- (void)cleanup {
    // Override in subclass
}

- (void)didMoveToParentViewController:(UIViewController *)parent {
    if (parent) {
        if (_didCleanup) {
            [NSException raise:@"Error" format:@"Don't reuse FunViewControllers. Once it has been removed from a view controller stack, it helps all contained views free up its resources."];
        }
        return;
    }
    _didCleanup = YES;
    [FunViewController _prepCheckDeallocCount:[self className]];
    [self.view recursivelyCleanup];
    [self _funViewControllerCleanup];
}

+ (void)_prepCheckDeallocCount:(NSString*)className {
    NSUInteger before = deallocCount;
    async(^{
        [API waitForCurrentRequests:^{
            after(1, ^{
                if (deallocCount > before) { return; }
                DLog(@"WARNING: dealloc was never called for %@ despite call to didMoveToParentViewController. It looks like you might have a memory leak in %@!", className, className);
//                [NSException raise:@"Error" format:@"dealloc was never called for %@ despite call to didMoveToParentViewController. It looks like you might have a memory leak in %@!", className, className];
            });
        }];
    });
}

+ (void)load {
    defaultBackgroundColor = [UIColor clearColor];
}

+ (instancetype)new {
    return [self withoutState];
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
    if (!_didRender) {
        _didRender = YES;
        self.view.backgroundColor = defaultBackgroundColor;
        self.view.opaque = (defaultBackgroundColor.alpha == 1.0);
        [self _funViewControllerRender:animated];
    }
}

- (void)_funViewControllerRender:(BOOL)animated {
    self.automaticallyAdjustsScrollViewInsets = NO;
//    self.view.backgroundColor = RANDOM_COLOR;
    [self render:animated];
}

- (void)render:(BOOL)animated {
    [UILabel.appendTo(self.view).text(@"You should implement -render in your ViewController").textColor(RED).wrapText.center render];
}

- (void)pushViewController:(UIViewController *)viewController {
    [self pushViewController:viewController animated:YES];
}
- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [self.navigationController pushViewController:viewController animated:animated];
}

- (void)popViewController {
    [self popViewControllerAnimated:YES];
}
- (void)popViewControllerAnimated:(BOOL)animated {
    [self.navigationController popViewControllerAnimated:animated];
}

- (FunNavigationController *)nav {
    if ([self.navigationController isKindOfClass:[FunNavigationController class]]) {
        return (FunNavigationController*)self.navigationController;
    } else {
        return nil;
    }
}

+ (void)show {
    [self showWithState:nil];
}

+ (void)showWithState:(id)state {
    FunNavigationController* rootVc = (FunNavigationController*)[[UIApplication sharedApplication].delegate window].rootViewController;
    FunViewController* vc = [self withState:state];
    [StatusBar hideWithAnimation:UIStatusBarAnimationNone];
    UIView* backdrop = [[UIView alloc] initWithFrame:[Viewport bounds]];
    [StatusBar showWithAnimation:UIStatusBarAnimationNone];
    SetProperty(vc, @"FunVCBackdrop", backdrop);
    [[rootVc.view snapshotViewAfterScreenUpdates:YES] appendTo:backdrop];
    [backdrop prependTo:vc.view];
    [rootVc pushViewController:vc animated:NO];
}

- (UIView *)backdrop {
    return GetProperty(self, @"FunVCBackdrop");
}

@end
