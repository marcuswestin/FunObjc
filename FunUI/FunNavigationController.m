//
//  NavigationController.m
//  Dogo iOS
//
//  Created by Marcus Westin on 11/11/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "FunNavigationController.h"
#import "FunObjc.h"

@interface ViewControllerTransition : NSObject <UIViewControllerAnimatedTransitioning, UIViewControllerInteractiveTransitioning>
//@property UIViewController* from;
//@property UIViewController* to;
@property UINavigationControllerOperation operation;
@property id<UIViewControllerContextTransitioning> transitionContext;
@end

@implementation ViewControllerTransition
static NSTimeInterval duration = 0.25;
- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *container = [transitionContext containerView];
    
    BOOL reverse = (_operation == UINavigationControllerOperationPop); // self.reverse
    if (reverse) {
        [container insertSubview:toViewController.view belowSubview:fromViewController.view];
    }
    else {
        toViewController.view.transform = CGAffineTransformMakeScale(0, 0);
        [container addSubview:toViewController.view];
    }
    
    [UIView animateKeyframesWithDuration:duration delay:0 options:0 animations:^{
        if (reverse) {
            fromViewController.view.transform = CGAffineTransformMakeScale(0, 0);
        }
        else {
            toViewController.view.transform = CGAffineTransformIdentity;
        }
    } completion:^(BOOL finished) {
        [transitionContext completeTransition:finished];
    }];
}
- (void)startInteractiveTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
//    _transitionContext = transitionContext;
//    if (_operation == UINavigationControllerOperationPush) {
//        _to.view.y = [Viewport height];
//        [UIView animateWithDuration:duration animations:^{
//            _to.view.y = 0;
//        } completion:^(BOOL finished) {
//            [_transitionContext completeTransition:YES];
//        }];
//    } else if (_operation == UINavigationControllerOperationPush) {
//        _to.view.y = 0;
//        [UIView animateWithDuration:duration animations:^{
//            _to.view.y = [Viewport height];
//        } completion:^(BOOL finished) {
//            [_transitionContext completeTransition:YES];
//        }];
//    } else {
//        _to.view.y = 0;
//    }
}
//- (void)animationEnded:(BOOL)transitionCompleted {
//
//}
- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return duration;
}
//- (UIViewAnimationCurve)completionCurve {
//
//}
//- (CGFloat)completionSpeed {
//
//}
@end

@interface FunNavigationController ()
@property UIView* parallax;
@end
@implementation FunNavigationController
// Custom navigation animations
///////////////////////////////

- (id)init {
    self = [super init];
    return [self _setup];
}
- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    return [self _setup];
}
- (id)initWithRootViewController:(UIViewController *)rootViewController {
    self = [super initWithRootViewController:rootViewController];
    return [self _setup];
}

static BOOL hasSetup;

- (id)_setup {
    if (hasSetup) {
        [NSException raise:@"Error" format:@"Expects only one NavigationController to be created"];
    }
    hasSetup = true;
    self.delegate = self;
    self.navigationBarHidden = YES;

    CGFloat headHeight = 50;
    self.head = [UIView.appendTo(self.view).h([Viewport height]).y2(headHeight) render];
    self.parallax = [UIImageView.prependTo(self.view).fill.image([UIImage imageNamed:@"img/bg/3"]) render];
    self.foot = [UIView.appendTo(self.view).h([Viewport height]).y([Viewport height]) render];
    
    [self setup];
    return self;
}

- (void)setup {}

//- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC {
//    return nil;
//    ViewControllerTransition* transition = [ViewControllerTransition new];
////    transition.from = fromVC;
////    transition.to = toVC;
//    transition.operation = operation;
//    return transition;
//}
//
//- (id<UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController interactionControllerForAnimationController:(id<UIViewControllerAnimatedTransitioning>)animationController {
//    return nil;
//}
//
//- (UIInterfaceOrientation)navigationControllerPreferredInterfaceOrientationForPresentation:(UINavigationController *)navigationController {
//    return UIInterfaceOrientationPortrait;
//}
//
//- (NSUInteger)navigationControllerSupportedInterfaceOrientations:(UINavigationController *)navigationController {
//    return UIInterfaceOrientationMaskPortrait;
//}
//- (void) navigationController:(UINavigationController*)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
//
//}
//
//- (void) navigationController:(UINavigationController*)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
//
//}


// Events
/////////
- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)uiViewController animated:(BOOL)animated {
    if ([uiViewController isMemberOfClass:FunViewController.class]) {
//        [(ViewController*)uiViewController willShowAnimated:animated];
    }
}

// Navigation Animation
///////////////////////
- (void)push:(UIViewController *)viewController withAnimator:(id<UIViewControllerAnimatedTransitioning>)animator {
    _currentAnimator = animator;
    [self pushViewController:viewController animated:YES];
}

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC {
    return _currentAnimator;
}

- (id<UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController interactionControllerForAnimationController:(id<UIViewControllerAnimatedTransitioning>)animationController {
    if ([_currentAnimator conformsToProtocol:@protocol(UIViewControllerInteractiveTransitioning)]) {
        return (id<UIViewControllerInteractiveTransitioning>)_currentAnimator;
    } else {
        return nil;
    }
}

@end
