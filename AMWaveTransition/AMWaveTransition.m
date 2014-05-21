//
//  AMWaveTransitioning.m
//  AMWaveTransitioning
//
//  Created by Andrea on 11/04/14.
//  Copyright (c) 2014 Fancy Pixel. All rights reserved.
//

#import "AMWaveTransition.h"
#import <DynamicXray/DynamicXray.h>

@interface AMWaveTransition ()

@property (nonatomic, strong) UIScreenEdgePanGestureRecognizer *gesture;
@property (nonatomic, strong) UINavigationController *navigationController;
@property (nonatomic, assign) int selectionIndexFrom;
@property (nonatomic, assign) int selectionIndexTo;

@property (nonatomic, strong) UIDynamicAnimator *animator;
@property (nonatomic, strong) NSMutableArray *attachmentsFrom;
@property (nonatomic, strong) NSMutableArray *attachmentsTo;

@end

@implementation AMWaveTransition

#define SCREEN_WIDTH ((([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortrait) || ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortraitUpsideDown)) ? [[UIScreen mainScreen] bounds].size.width : [[UIScreen mainScreen] bounds].size.height)

#define DURATION    0.65
#define MAX_DELAY   0.15

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setup];
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
        [self setup];
    }
    return self;
}

- (void)setup
{
    _duration = DURATION;
    _maxDelay = MAX_DELAY;
    _transitionType = AMWaveTransitionTypeNervous;
}

- (void)attachInteractiveGestureToNavigationController:(UINavigationController *)navigationController
{
    self.navigationController = navigationController;
    self.gesture = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [self.gesture setEdges:UIRectEdgeLeft];
    [navigationController.view addGestureRecognizer:self.gesture];
    
    self.animator = [[UIDynamicAnimator alloc]initWithReferenceView:navigationController.topViewController.view];
    self.attachmentsFrom = [@[] mutableCopy];
    DynamicXray *xray = [[DynamicXray alloc] init];
    [self.animator addBehavior:xray];
}

- (void)handlePan:(UIScreenEdgePanGestureRecognizer *)gesture
{
    // Starting controller
    UIViewController<AMWaveTransitioning> *fromVC;
    fromVC = (UIViewController<AMWaveTransitioning> *)self.navigationController.topViewController;

    // Controller that will be visible after the pop
    UIViewController<AMWaveTransitioning> *toVC;
    int index = [self.navigationController.viewControllers indexOfObject:self.navigationController.topViewController];
    toVC = (UIViewController<AMWaveTransitioning> *)self.navigationController.viewControllers[index-1];
    
    // The gesture velocity will also determine the velocity of the cells
    float velocity = [gesture velocityInView:self.navigationController.view].x;
    CGPoint touch = [gesture locationInView:self.navigationController.topViewController.view];

    if (gesture.state == UIGestureRecognizerStateBegan) {
        [[fromVC visibleCells] enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
            // The 'selected' cell will be the one leading the other cells
            if (CGRectContainsPoint(view.frame, touch)) {
                self.selectionIndexFrom = idx;
            }
            
            UIAttachmentBehavior *attachment = [[UIAttachmentBehavior alloc] initWithItem:view attachedToAnchor:(CGPoint){touch.x, view.frame.origin.y + view.frame.size.height / 2}];
            [attachment setDamping:0.4];
            [attachment setFrequency:1];
            [self.animator addBehavior:attachment];
            [self.attachmentsFrom addObject:attachment];
        }];
        

        [self.navigationController.view addSubview:toVC.view];
        [[toVC visibleCells] enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
//            if (CGRectContainsPoint(view.frame, touch)) {
//                self.selectionIndexFrom = idx;
//            }
            // TODO: move the setalpha below and scale it
            [view setAlpha:1];
//            UIAttachmentBehavior *attachment = [[UIAttachmentBehavior alloc] initWithItem:view attachedToAnchor:(CGPoint){touch.x, view.frame.origin.y + view.frame.size.height / 2}];
//            [attachment setDamping:0.4];
//            [attachment setFrequency:1];
//            [self.animator addBehavior:attachment];
//            [self.attachmentsFrom addObject:attachment];
        }];
        

    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        
        [[fromVC visibleCells] enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
            float delta = [gesture locationInView:self.navigationController.view].x - abs(self.selectionIndexFrom - idx) * velocity / 30;
            // Prevent the anchor point from going 'over' the cell
            if (delta > view.frame.origin.x + view.frame.size.width / 2) {
                delta = view.frame.origin.x + view.frame.size.width / 2 - 10;
            }
            [self.attachmentsFrom[idx] setAnchorPoint:(CGPoint){delta, view.frame.origin.y + view.frame.size.height / 2}];
        }];
 
    } else if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled) {
        [self.attachmentsFrom enumerateObjectsUsingBlock:^(UIAttachmentBehavior *obj, NSUInteger idx, BOOL *stop) {
            [self.animator removeBehavior:obj];
        }];
        [self.attachmentsFrom removeAllObjects];
        if (gesture.state == UIGestureRecognizerStateEnded && touch.x > self.navigationController.view.frame.size.width * 0.7) {
            // Complete the transition
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            // Abort
            [[fromVC visibleCells] enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
                [UIView animateWithDuration:0.3 animations:^{
                    CGRect rect = view.frame;
                    rect.origin.x = 0;
                    view.frame = rect;
                } completion:^(BOOL finished) {
                    [toVC.view removeFromSuperview];
                }];
            }];
        }
    }
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
