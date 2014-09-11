//
//  AMWaveTransitioning.m
//  AMWaveTransitioning
//
//  Created by Andrea on 11/04/14.
//  Copyright (c) 2014 Fancy Pixel. All rights reserved.
//

#import "AMWaveTransition.h"

typedef NS_ENUM(NSInteger, AMWaveTransitionViewControllers) {
    AMWaveTransitionToVC,
    AMWaveTransitionFromVC,
};

@interface AMWaveTransition ()

@property (nonatomic, strong) UIGestureRecognizer *gesture;
@property (nonatomic, weak) UINavigationController *navigationController;
@property (nonatomic, assign) int selectionIndexFrom;
@property (nonatomic, assign) int selectionIndexTo;
@property (nonatomic, assign) CGPoint firstTouch;

@property (nonatomic, strong) UIDynamicAnimator *animator;
@property (nonatomic, strong) NSMutableArray *attachmentsFrom;
@property (nonatomic, strong) NSMutableArray *attachmentsTo;

@end


@implementation AMWaveTransition

#define SCREEN_WIDTH ((([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortrait) || ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortraitUpsideDown)) ? [[UIScreen mainScreen] bounds].size.width : [[UIScreen mainScreen] bounds].size.height)

const CGFloat DURATION = 0.65;
const CGFloat MAX_DELAY = 0.15;

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setup];
        _operation = UINavigationControllerOperationNone;
        _transitionType = AMWaveTransitionTypeNervous;
    }
    return self;
}

+ (instancetype)transitionWithOperation:(UINavigationControllerOperation)operation
{
    return [[self alloc] initWithOperation:operation andTransitionType:AMWaveTransitionTypeNervous];
}

- (instancetype)initWithOperation:(UINavigationControllerOperation)operation
{
    return [self initWithOperation:operation andTransitionType:AMWaveTransitionTypeNervous];
}

+ (instancetype)transitionWithOperation:(UINavigationControllerOperation)operation andTransitionType:(AMWaveTransitionType)type
{
    return [[self alloc] initWithOperation:operation andTransitionType:type];
}

- (instancetype)initWithOperation:(UINavigationControllerOperation)operation andTransitionType:(AMWaveTransitionType)type
{
    self = [super init];
    if (self) {
        [self setup];
        _operation = operation;
        _transitionType = type;
    }
    return self;
}

- (void)setup
{
    _viewControllersInset = 20;
    _interactiveTransitionType = AMWaveTransitionFullScreenPan;
    _animateAlphaWithInteractiveTransition = YES;
    _duration = DURATION;
    _maxDelay = MAX_DELAY;
}

- (void)attachInteractiveGestureToNavigationController:(UINavigationController *)navigationController
{
    self.navigationController = navigationController;
    if (self.interactiveTransitionType == AMWaveTransitionEdgePan) {
        
        UIScreenEdgePanGestureRecognizer *recognizer = [[UIScreenEdgePanGestureRecognizer alloc]
                                                        initWithTarget:self
                                                        action:@selector(handlePan:)];
        [recognizer setEdges:UIRectEdgeLeft];
        self.gesture = recognizer;
    } else {
        UIPanGestureRecognizer *recognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                                     action:@selector(handlePan:)];
        self.gesture = recognizer;
    }
    [navigationController.view addGestureRecognizer:self.gesture];
    self.animator = [[UIDynamicAnimator alloc]initWithReferenceView:navigationController.view];
    self.attachmentsFrom = [@[] mutableCopy];
    self.attachmentsTo = [@[] mutableCopy];
}

- (void)detachInteractiveGesture
{
    [self.navigationController.view removeGestureRecognizer:self.gesture];
    self.navigationController = nil;
    self.gesture = nil;
    [self.animator removeAllBehaviors];
    self.animator = nil;
}

#pragma mark - Interactive Transition

- (void)handlePan:(UIScreenEdgePanGestureRecognizer *)gesture
{
    // Starting controller
    UIViewController<AMWaveTransitioning> *fromVC;
    fromVC = (UIViewController<AMWaveTransitioning> *)self.navigationController.topViewController;
    
    // Controller that will be visible after the pop
    UIViewController<AMWaveTransitioning> *toVC;
    int index = (int)[self.navigationController.viewControllers indexOfObject:self.navigationController.topViewController];
    // The gesture velocity will also determine the velocity of the cells
    float velocity = [gesture velocityInView:self.navigationController.view].x;
    CGPoint touch = [gesture locationInView:self.navigationController.view];
    if (index == 0) {
        //simple attach animation instead of crash
        touch.x = 0;
        toVC = nil;
    } else {
       toVC = (UIViewController<AMWaveTransitioning> *)self.navigationController.viewControllers[index-1];
    }
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
        if (self.interactiveTransitionType == AMWaveTransitionFullScreenPan) {
            self.firstTouch = touch;
        } else {
            self.firstTouch = CGPointMake(0, 0);
        }
        if ([fromVC respondsToSelector:@selector(visibleCells)] && [fromVC visibleCells].count > 0) {
            [[fromVC visibleCells] enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
                // The 'selected' cell will be the one leading the other cells
                if (CGRectContainsPoint([view.superview convertRect:view.frame toView:nil], touch)) {
                    self.selectionIndexFrom = (int)idx;
                }
                [self createAttachmentForView:view inVC:AMWaveTransitionFromVC];
            }];
        } else {
            UIView *view = fromVC.view;
            self.selectionIndexFrom = 0;
            [self createAttachmentForView:view inVC:AMWaveTransitionFromVC];
        }
        // Kick the 'new' cells outside the view
        [self.navigationController.view insertSubview:toVC.view belowSubview:self.navigationController.navigationBar];
        if ([toVC respondsToSelector:@selector(visibleCells)] && [toVC visibleCells].count > 0) {
            [[toVC visibleCells] enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
                [self kickCellOutside:view];
            }];
        } else if (toVC) {
            UIView *view = toVC.view;
            [self kickCellOutside:view];
        }
        
        if ([toVC respondsToSelector:@selector(visibleCells)] && [toVC visibleCells].count > 0) {
            [[toVC visibleCells] enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
                CGRect futureRect = view.frame;
                futureRect.origin.x = 0;
                if (CGRectContainsPoint([view.superview convertRect:futureRect toView:nil], touch)) {
                    self.selectionIndexTo = (int)idx;
                }
                [self createAttachmentForView:view inVC:AMWaveTransitionToVC];
            }];
        } else if (toVC) {
            UIView *view = toVC.view;
            self.selectionIndexTo = 0;
            [self createAttachmentForView:view inVC:AMWaveTransitionToVC];
            
        }
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        if ([fromVC respondsToSelector:@selector(visibleCells)] && [fromVC visibleCells].count > 0) {
            [[fromVC visibleCells] enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
                [self changeAttachmentWithIndex:idx
                                         inView:view
                                         touchX:touch.x
                                       velocity:velocity
                                           inVC:AMWaveTransitionFromVC];
            }];
        } else {
            UIView *view = fromVC.view;
            [self changeAttachmentWithIndex:0
                                     inView:view
                                     touchX:touch.x
                                   velocity:velocity
                                       inVC:AMWaveTransitionFromVC];
        }
        if ([toVC respondsToSelector:@selector(visibleCells)] && [toVC visibleCells].count > 0) {
            [[toVC visibleCells] enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
                [self changeAttachmentWithIndex:idx
                                         inView:view
                                         touchX:touch.x
                                       velocity:velocity
                                           inVC:AMWaveTransitionToVC];
            }];
        } else if (toVC) {
            UIView *view = toVC.view;
            [self changeAttachmentWithIndex:0
                                     inView:view
                                     touchX:touch.x
                                   velocity:velocity
                                       inVC:AMWaveTransitionToVC];
        }
        
    } else if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled) {
        [self.attachmentsFrom enumerateObjectsUsingBlock:^(UIAttachmentBehavior *obj, NSUInteger idx, BOOL *stop) {
            [self.animator removeBehavior:obj];
        }];
        [self.attachmentsFrom removeAllObjects];
        
        [self.attachmentsTo enumerateObjectsUsingBlock:^(UIAttachmentBehavior *obj, NSUInteger idx, BOOL *stop) {
            [self.animator removeBehavior:obj];
        }];
        [self.attachmentsTo removeAllObjects];
        
        if (gesture.state == UIGestureRecognizerStateEnded && touch.x > self.navigationController.view.frame.size.width * 0.7) {
            // Complete the transition
            [UIView animateWithDuration:0.3 animations:^{
                if ([fromVC respondsToSelector:@selector(visibleCells)] && [fromVC visibleCells].count > 0) {
                    [[fromVC visibleCells] enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
                        [self completeFromVC:view];
                    }];
                } else {
                    UIView *view = fromVC.view;
                    [self completeFromVC:view];
                }
                if ([toVC respondsToSelector:@selector(visibleCells)] && [toVC visibleCells].count > 0) {
                    [[toVC visibleCells] enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
                        [self setPresentedFrameForView:view];
                    }];
                } else {
                    UIView *view = toVC.view;
                    [self setPresentedFrameForView:view];
                }
            } completion:^(BOOL finished) {
                    if ([toVC respondsToSelector:@selector(visibleCells)] && [toVC visibleCells].count > 0) {
                        
                            [[toVC visibleCells] enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
                                [self animationCompletionForInteractiveTransitionForView:view];
                            }];
                    } else {
                        UIView *view = toVC.view;
                        [self animationCompletionForInteractiveTransitionForView:view];
                    }
                
                [self.navigationController popViewControllerAnimated:NO];
            }];
        } else {
            // Abort
            [UIView animateWithDuration:0.3 animations:^{
                if ([fromVC respondsToSelector:@selector(visibleCells)] && [fromVC visibleCells].count > 0) {
                    [[fromVC visibleCells] enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
                        [self setPresentedFrameForView:view];
                    }];
                } else {
                    UIView *view = fromVC.view;
                    [self setPresentedFrameForView:view];
                }
                if ([toVC respondsToSelector:@selector(visibleCells)] && [toVC visibleCells].count > 0) {
                    [[toVC visibleCells] enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
                        [self completeToVC:view];
                    }];
                } else {
                    UIView *view = toVC.view;
                    [self completeFromVC:view];
                }
            } completion:^(BOOL finished) {
                // Bring 'silently' the cell back to their place, or the normal pop operation would fail
                if ([toVC respondsToSelector:@selector(visibleCells)] && [toVC visibleCells].count > 0) {
                    [[toVC visibleCells] enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
                        [self animationCompletionForInteractiveTransitionForView:view];
                    }];
                } else {
                    UIView *view = toVC.view;
                    [self animationCompletionForInteractiveTransitionForView:view];
                }
                [toVC.view removeFromSuperview];
            }];
        }
    }
}

- (void)animationCompletionForInteractiveTransitionForView:(UIView *)view {
    CGRect rect = view.frame;
    rect.origin.x = 0;
    if (self.navigationController.navigationBar.translucent && !self.navigationController.navigationBar.hidden) {
        rect.origin.y -= self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height;
    }
    view.frame = rect;
    view.alpha = [self alphaForView:view];
}


- (void)setPresentedFrameForView:(UIView *)view {
    CGRect rect = view.frame;
    rect.origin.x = 0;
    view.frame = rect;
    view.alpha = [self alphaForView:view];
}

- (void)kickCellOutside:(UIView *)view {
    CGRect rect = view.frame;
    rect.origin.x = -SCREEN_WIDTH - self.viewControllersInset;
    if (self.navigationController.navigationBar.translucent) {
        rect.origin.y += self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height;
    }
    view.alpha = [self alphaForView:view];
    view.frame = rect;
}

- (void)completeToVC:(UIView *)view {
    [self completeTransitionWithView:view inVC:AMWaveTransitionToVC];
}

- (void)completeFromVC:(UIView *)view {
    [self completeTransitionWithView:view inVC:AMWaveTransitionFromVC];
}

- (void)completeTransitionWithView:(UIView *)view inVC:(AMWaveTransitionViewControllers)viewController {
    CGRect rect = view.frame;
    if (viewController == AMWaveTransitionFromVC) {
        rect.origin.x = SCREEN_WIDTH - self.viewControllersInset;
    } else {
        rect.origin.x = -SCREEN_WIDTH - self.viewControllersInset;
    }
    view.frame = rect;
    view.alpha = [self alphaForView:view];
}

- (void)changeAttachmentWithIndex:(NSUInteger)index
                           inView:(UIView *)view
                           touchX:(CGFloat)touchX
                         velocity:(CGFloat)velocity
                             inVC:(AMWaveTransitionViewControllers)viewController {
    int selectionIndex;
    NSInteger correction = 2;
    NSMutableArray *arrayWithAttachments;
    if (viewController == AMWaveTransitionToVC) {
        arrayWithAttachments = self.attachmentsTo;
        selectionIndex = self.selectionIndexTo;
    } else {
        arrayWithAttachments = self.attachmentsFrom;
        selectionIndex = self.selectionIndexFrom;
        correction = -correction;
    }
    
    float delta = touchX - self.firstTouch.x - abs(selectionIndex - (int)index) * velocity / 50;
    // Prevent the anchor point from going 'over' the cell
    if (delta > view.frame.origin.x + view.frame.size.width / 2 && viewController == AMWaveTransitionFromVC) {
        delta = view.frame.origin.x + view.frame.size.width / 2 + correction;
    } else if (delta < view.frame.origin.x + view.frame.size.width / 2 && viewController == AMWaveTransitionToVC) {
        delta = view.frame.origin.x + view.frame.size.width / 2 + correction;
    }
    view.alpha = [self alphaForView:view];
    [arrayWithAttachments[index] setAnchorPoint:(CGPoint){delta, [view.superview convertPoint:view.frame.origin toView:nil].y + view.frame.size.height / 2}];
}

- (void)createAttachmentForView:(UIView *)view inVC:(AMWaveTransitionViewControllers)viewController {
    UIAttachmentBehavior *attachment = [[UIAttachmentBehavior alloc] initWithItem:view attachedToAnchor:(CGPoint){0, [view.superview convertPoint:view.frame.origin toView:nil].y + view.frame.size.height / 2}];
    [attachment setDamping:0.4];
    [attachment setFrequency:1];
    [self.animator addBehavior:attachment];
    view.alpha = [self alphaForView:view];
    
    NSMutableArray *arrayWithAttachments;
    if (viewController == AMWaveTransitionToVC) {
        arrayWithAttachments = self.attachmentsTo;
    } else {
        arrayWithAttachments = self.attachmentsFrom;
    }
    
    [arrayWithAttachments addObject:attachment];
}

- (CGFloat)alphaForView:(UIView *)view {
    if (self.animateAlphaWithInteractiveTransition) {
        CGFloat width = SCREEN_WIDTH - self.viewControllersInset;
        CGFloat alpha =(width - fabs(view.frame.origin.x)) * (1 / width);
        return alpha;
    } else {
        return 1.0;
    }
}

#pragma mark - Non interactive transition

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
	
    [[transitionContext containerView] addSubview:toVC.view];
    
    CGFloat delta;
    if (self.operation == UINavigationControllerOperationPush) {
        delta = SCREEN_WIDTH + self.viewControllersInset;
    } else {
        delta = -SCREEN_WIDTH - self.viewControllersInset;
    }
    
    // Move the destination in place
    toVC.view.frame = [transitionContext finalFrameForViewController:toVC];
    // And kick it aside
    toVC.view.transform = CGAffineTransformMakeTranslation(delta, 0);
    
    // First step is required to trigger the load of the visible cells.
    [UIView animateWithDuration:0 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:nil completion:^(BOOL done) {
        
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
				[fromVC.view setTransform:CGAffineTransformMakeTranslation(delta, 0)];
			} completion:^(BOOL finished) {
                [fromVC.view removeFromSuperview];
				[transitionContext completeTransition:YES];
			}];
        }
        
        // Animates the cells of the starting view controller
        if ([fromVC respondsToSelector:@selector(visibleCells)] && [fromVC visibleCells].count > 0) {
            [[fromVC visibleCells] enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(UITableViewCell *obj, NSUInteger idx, BOOL *stop) {
                NSTimeInterval delay = ((float)idx / (float)[[fromVC visibleCells] count]) * self.maxDelay;
                [self hideView:obj withDelay:delay andDelta:-delta];
            }];
        } else {
            // The controller has no table view, let's animate it gracefully
            [self hideView:fromVC.view withDelay:0 andDelta:-delta];
        }
        
        if ([toVC respondsToSelector:@selector(visibleCells)] && [toVC visibleCells].count > 0) {
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
    } else if (self.transitionType == AMWaveTransitionTypeNervous) {
        [UIView animateWithDuration:self.duration delay:delay usingSpringWithDamping:0.75 initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseIn animations:animation completion:completion];
    } else if (self.transitionType == AMWaveTransitionTypeBounce){
        [UIView animateWithDuration:self.duration delay:delay options:UIViewAnimationOptionCurveEaseInOut animations:animation completion:completion];
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
    } else if (self.transitionType == AMWaveTransitionTypeNervous) {
        [UIView animateWithDuration:self.duration delay:delay usingSpringWithDamping:0.75 initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseIn animations:animation completion:nil];
    } else if (self.transitionType == AMWaveTransitionTypeBounce){
        [UIView animateWithDuration:self.duration delay:delay options:UIViewAnimationOptionCurveEaseInOut animations:animation completion:nil];
    }
}

@end
