//
//  NavigationController.m
//  Dogo iOS
//
//  Created by Marcus Westin on 11/11/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "NavigationController.h"
#import "FunObjc.h"

@interface NavigationController ()
@property UIView* parallax;
@end

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


@implementation NavigationController
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

- (id)_setup {
    if (Nav) {
        [NSException raise:@"Error" format:@"Expects only one NavigationController to be created"];
    }
    Nav = self;
    self.delegate = self;
    self.navigationBarHidden = YES;
    CGFloat headHeight = 50;
    self.head = [UIView.appendTo(self.view).h([Viewport height]).y2(headHeight)
//                 .blur(rgba(255,222,161,.5))
                 render];
    self.parallax = [UIImageView.prependTo(self.view).fill.image([UIImage imageNamed:@"img/bg/2"]) render];
    
    self.left = [UIView.appendTo(self.view).h([Viewport height]).w(0).insetTop(20).y(20) render];
    
    return self;
}

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


//////////////////
- (void)renderHeadHeight:(CGFloat)height block:(void (^)(UIView *))block {
    self.head.height = height;
    UIView* view = [UIView.styler.wh(self.head.width, height) render];
    block(view);
    [self.head empty];
    [self.head addSubview:view];
}

- (void)renderLeftWidth:(CGFloat)width block:(void (^)(UIView *))block {
    self.left.width = width;
    UIView* view = [UIView.appendTo(self.left).wh(width, self.view.height) render];
    block(view);
    [self.left empty];
    [self.left addSubview:view];
}

- (void)push:(ViewController *)viewController withAnimator:(NavigationAnimator *(^)())block {
    
//    [self pushViewController:viewController animated:YES];
}
@end
