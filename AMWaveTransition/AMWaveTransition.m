//
//  AMWaveTransitioning.m
//  AMWaveTransitioning
//
//  Created by Andrea on 11/04/14.
//  Copyright (c) 2014 Fancy Pixel. All rights reserved.
//

#import "AMWaveTransition.h"

@implementation AMWaveTransition

#define SCREEN_WIDTH ((([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortrait) || ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortraitUpsideDown)) ? [[UIScreen mainScreen] bounds].size.width : [[UIScreen mainScreen] bounds].size.height)

#define DURATION    0.65
#define MAX_DELAY   0.15

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSAssert(NO, @"Use initWithOperation: or transitionWithOperation: instead");
    }
    return self;
}

+ (instancetype)transitionWithOperation:(UINavigationControllerOperation)operation
{
    return [[self alloc] initWithOperation:operation];
}

- (instancetype)initWithOperation:(UINavigationControllerOperation)operation
{
    self = [super init];
    if (self) {
        _operation = operation;
        _duration = DURATION;
        _maxDelay = MAX_DELAY;
        _transitionType = AMWaveTransitionTypeNervous;
    }
    return self;
}

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext
{
    return self.duration + self.maxDelay;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController<AMWaveTransitioning> *fromVC;
    if ([[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey] isKindOfClass:[UINavigationController class]]) {
        fromVC = (UIViewController<AMWaveTransitioning>*)([(UINavigationController*)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey] visibleViewController]);
    } else {
        fromVC = (UIViewController<AMWaveTransitioning>*)([transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey]);
    }
    
    UIViewController<AMWaveTransitioning> *toVC;
    if ([[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey] isKindOfClass:[UINavigationController class]]) {
        toVC = (UIViewController<AMWaveTransitioning>*)([(UINavigationController*)[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey] visibleViewController]);
    } else {
        toVC = (UIViewController<AMWaveTransitioning>*)([transitionContext viewControllerForKey:UITransitionContextToViewControllerKey]);
    }
	
    CGRect source = [transitionContext initialFrameForViewController:fromVC];
    [[transitionContext containerView] addSubview:toVC.view];
    
    CGFloat delta;
    if (self.operation == UINavigationControllerOperationPush) {
        delta = SCREEN_WIDTH;
    } else {

        delta = -SCREEN_WIDTH;
    }
    
    // Move the destination in place
    toVC.view.frame = source;
    // And kick it aside
    toVC.view.transform = CGAffineTransformMakeTranslation(SCREEN_WIDTH, 0);
    
    // First step is required to trigger the load of the visible cells.
    [UIView animateWithDuration:0 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:nil completion:^(BOOL finished) {
        
        // Plain animation that moves the destination controller in place. Once it's done it will notify the transition context
        if (self.operation == UINavigationControllerOperationPush) {
            [toVC.view setTransform:CGAffineTransformMakeTranslation(1, 0)];
			[UIView animateWithDuration:self.duration + self.maxDelay delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
				[toVC.view setTransform:CGAffineTransformIdentity];
			} completion:^(BOOL finished) {
				[transitionContext completeTransition:YES];
			}];
        } else {
            [fromVC.view setTransform:CGAffineTransformMakeTranslation(1, 0)];
            [toVC.view setTransform:CGAffineTransformIdentity];
			[UIView animateWithDuration:self.duration + self.maxDelay delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
				[fromVC.view setTransform:CGAffineTransformMakeTranslation(SCREEN_WIDTH, 0)];
			} completion:^(BOOL finished) {
				[transitionContext completeTransition:YES];
				[fromVC.view removeFromSuperview];
			}];
        }
        
        // Animates the cells of the starting view controller
        if ([fromVC respondsToSelector:@selector(visibleCells)]) {
            [[fromVC visibleCells] enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(UITableViewCell *obj, NSUInteger idx, BOOL *stop) {
                NSTimeInterval delay = ((float)idx / (float)[[fromVC visibleCells] count]) * self.maxDelay;
                [self hideView:obj withDelay:delay andDelta:-delta];
            }];
        } else {
            // The controller has no table view, let's animate it gracefully
            [self hideView:fromVC.view withDelay:0 andDelta:-delta];
        }

        if ([toVC respondsToSelector:@selector(visibleCells)]) {
            [[toVC visibleCells] enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(UITableViewCell *obj, NSUInteger idx, BOOL *stop) {
                NSTimeInterval delay = ((float)idx / (float)[[toVC visibleCells] count]) * self.maxDelay;
                [self presentView:obj withDelay:delay andDelta:delta];
            }];
        } else {
            [self presentView:toVC.view withDelay:0 andDelta:delta];
        }
    }];
}

- (void)hideView:(UIView *)view withDelay:(NSTimeInterval)delay andDelta:(float)delta
{
    void (^animation)() = ^{
        [view setTransform:CGAffineTransformMakeTranslation(delta, 0)];
        [view setAlpha:0];
    };
    void (^completion)(BOOL) = ^(BOOL finished){
        [view setTransform:CGAffineTransformIdentity];
    };
    if (self.transitionType == AMWaveTransitionTypeSubtle) {
        [UIView animateWithDuration:self.duration delay:delay options:UIViewAnimationOptionCurveEaseIn animations:animation completion:completion];
    } else {
        [UIView animateWithDuration:self.duration delay:delay usingSpringWithDamping:0.75 initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseIn animations:animation completion:completion];
    }
}

- (void)presentView:(UIView *)view withDelay:(NSTimeInterval)delay andDelta:(float)delta
{
    [view setTransform:CGAffineTransformMakeTranslation(delta, 0)];
    void (^animation)() = ^{
        [view setTransform:CGAffineTransformIdentity];
        [view setAlpha:1];
    };
    if (self.transitionType == AMWaveTransitionTypeSubtle) {
        [UIView animateWithDuration:self.duration delay:delay options:UIViewAnimationOptionCurveEaseIn animations:animation completion:nil];
    } else {
        [UIView animateWithDuration:self.duration delay:delay usingSpringWithDamping:0.75 initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseIn animations:animation completion:nil];
    }
}

@end
