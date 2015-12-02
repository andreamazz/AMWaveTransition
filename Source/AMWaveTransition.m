//
//  AMWaveTransitioning.m
//  AMWaveTransitioning
//
//  Created by Andrea on 11/04/14.
//  Copyright (c) 2015 Fancy Pixel. All rights reserved.
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


@interface UITableView (AMWaveTransition)
- (NSArray*)am_visibleViews;
@end


@implementation AMWaveTransition

#define SCREEN_WIDTH ((([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortrait) || ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortraitUpsideDown)) ? [[UIScreen mainScreen] bounds].size.width : [[UIScreen mainScreen] bounds].size.height)

const CGFloat DURATION = 0.65;
const CGFloat MAX_DELAY = 0.15;

- (void)dealloc {
    [self detachInteractiveGesture];
}

- (instancetype)init {
    if ((self = [super init])) {
        [self setup];
        _operation = UINavigationControllerOperationNone;
        _transitionType = AMWaveTransitionTypeNervous;
    }
    return self;
}

+ (instancetype)transitionWithOperation:(UINavigationControllerOperation)operation {
    return [[self alloc] initWithOperation:operation andTransitionType:AMWaveTransitionTypeNervous];
}

- (instancetype)initWithOperation:(UINavigationControllerOperation)operation {
    return [self initWithOperation:operation andTransitionType:AMWaveTransitionTypeNervous];
}

+ (instancetype)transitionWithOperation:(UINavigationControllerOperation)operation andTransitionType:(AMWaveTransitionType)type {
    return [[self alloc] initWithOperation:operation andTransitionType:type];
}

- (instancetype)initWithOperation:(UINavigationControllerOperation)operation andTransitionType:(AMWaveTransitionType)type {
    self = [super init];
    if (self) {
        [self setup];
        _operation = operation;
        _transitionType = type;
    }
    return self;
}

- (void)setup {
    _viewControllersInset = 20;
    _interactiveTransitionType = AMWaveTransitionEdgePan;
    _animateAlphaWithInteractiveTransition = NO;
    _duration = DURATION;
    _maxDelay = MAX_DELAY;
}

- (void)attachInteractiveGestureToNavigationController:(UINavigationController *)navigationController {
    self.navigationController = navigationController;
    if (self.interactiveTransitionType == AMWaveTransitionEdgePan) {
        UIScreenEdgePanGestureRecognizer *recognizer = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self
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

- (void)detachInteractiveGesture {
    UINavigationController *navigationController = self.navigationController;
    [navigationController.view removeGestureRecognizer:self.gesture];
    self.navigationController = nil;
    self.gesture = nil;
    [self.animator removeAllBehaviors];
    self.animator = nil;
}

- (void)handlePan:(UIScreenEdgePanGestureRecognizer *)gesture {
    UINavigationController *navigationController = self.navigationController; // support CLANG_WARN_OBJC_RECEIVER_WEAK
    
    // Starting controller
    UIViewController *fromVC = navigationController.topViewController;
    
    // Controller that will be visible after the pop
    UIViewController<AMWaveTransitioning> *toVC;
    NSInteger index = [navigationController.viewControllers indexOfObject:navigationController.topViewController];
    // The gesture velocity will also determine the velocity of the cells
    float velocity = [gesture velocityInView:navigationController.view].x;
    CGPoint touch = [gesture locationInView:navigationController.view];
    if (index == 0) {
        // Simple attach animation
        touch.x = 0;
        toVC = nil;
    } else if (index != NSNotFound) {
        toVC = (UIViewController<AMWaveTransitioning> *)navigationController.viewControllers[index-1];
    }
    
    NSArray *fromViews = [self visibleCellsForViewController:fromVC];
    NSArray *toViews = [self visibleCellsForViewController:toVC];
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
        if (self.interactiveTransitionType == AMWaveTransitionFullScreenPan) {
            self.firstTouch = touch;
        } else {
            self.firstTouch = CGPointZero;
        }
        [fromViews enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
            // The 'selected' cell will be the one leading the other cells
            if (CGRectContainsPoint([view.superview convertRect:view.frame toView:nil], touch)) {
                self.selectionIndexFrom = (int)idx;
            }
            [self createAttachmentForView:view inVC:AMWaveTransitionFromVC];
        }];
        
        
        // Kick the 'new' cells outside the view
        [navigationController.view insertSubview:toVC.view belowSubview:navigationController.navigationBar];
        toViews = [self visibleCellsForViewController:toVC]; // re-read, because toVC might have been not ready before
        [toViews enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
            [self kickCellOutside:view];
        }];
        
        [toViews enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
            CGRect futureRect = view.frame;
            futureRect.origin.x = 0;
            if (CGRectContainsPoint([view.superview convertRect:futureRect toView:nil], touch)) {
                self.selectionIndexTo = (int)idx;
            }
            [self createAttachmentForView:view inVC:AMWaveTransitionToVC];
        }];
        
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        
        [fromViews enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
            [self changeAttachmentWithIndex:idx
                                     inView:view
                                     touchX:touch.x
                                   velocity:velocity
                                       inVC:AMWaveTransitionFromVC];
        }];
        
        [toViews enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
            [self changeAttachmentWithIndex:idx
                                     inView:view
                                     touchX:touch.x
                                   velocity:velocity
                                       inVC:AMWaveTransitionToVC];
        }];
        
    } else if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled) {
        [self.attachmentsFrom enumerateObjectsUsingBlock:^(UIAttachmentBehavior *obj, NSUInteger idx, BOOL *stop) {
            [self.animator removeBehavior:obj];
        }];
        [self.attachmentsFrom removeAllObjects];
        
        [self.attachmentsTo enumerateObjectsUsingBlock:^(UIAttachmentBehavior *obj, NSUInteger idx, BOOL *stop) {
            [self.animator removeBehavior:obj];
        }];
        [self.attachmentsTo removeAllObjects];
        
        if (gesture.state == UIGestureRecognizerStateEnded && velocity > 0) {
            // Complete the transition
            [UIView animateWithDuration:0.3 animations:^{
                [fromViews enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
                    [self completeFromVC:view];
                }];
                [toViews enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
                    [self setPresentedFrameForView:view];
                }];
            } completion:^(BOOL finished) {
                toVC.view.backgroundColor = fromVC.view.backgroundColor;
                [toViews enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
                    [self animationCompletionForInteractiveTransitionForView:view];
                }];
                
                [navigationController popViewControllerAnimated:NO];
            }];
        } else {
            // Abort
            [UIView animateWithDuration:0.3 animations:^{
                [fromViews enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
                    [self setPresentedFrameForView:view];
                }];
                [toViews enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
                    [self completeToVC:view];
                }];
            } completion:^(BOOL finished) {
                // Bring 'silently' the cell back to their place, or the normal pop operation would fail
                [toViews enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
                    [self animationCompletionForInteractiveTransitionForView:view];
                }];
                [toVC.view removeFromSuperview];
            }];
            
        }
    }
}

- (void)animationCompletionForInteractiveTransitionForView:(UIView *)view {
    CGRect rect = view.frame;
    rect.origin.x = 0;
    UINavigationController *navigationController = self.navigationController;
    if (navigationController.navigationBar.translucent && !navigationController.navigationBar.hidden) {
        rect.origin.y -= navigationController.navigationBar.frame.origin.y + navigationController.navigationBar.frame.size.height;
    } else {
        rect.origin.y -= [[UIApplication sharedApplication] statusBarFrame].size.height;
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
    UINavigationController *navigationController = self.navigationController;
    if (navigationController.navigationBar.translucent && !navigationController.navigationBar.hidden) {
        rect.origin.y += navigationController.navigationBar.frame.origin.y + navigationController.navigationBar.frame.size.height;
    } else {
        rect.origin.y += [[UIApplication sharedApplication] statusBarFrame].size.height;
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
        CGFloat alpha = (width - fabs(view.frame.origin.x)) * (1 / width);
        return alpha;
    } else {
        return 1.0;
    }
}

#pragma mark - Non interactive transition

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    return self.duration + self.maxDelay;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    UIViewController *fromVC;
    if ([[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey] isKindOfClass:[UINavigationController class]]) {
        fromVC = (UIViewController*)([(UINavigationController*)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey] visibleViewController]);
    } else {
        fromVC = (UIViewController*)([transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey]);
    }
    
    UIViewController *toVC;
    if ([[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey] isKindOfClass:[UINavigationController class]]) {
        toVC = (UIViewController*)([(UINavigationController*)[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey] visibleViewController]);
    } else {
        toVC = (UIViewController*)([transitionContext viewControllerForKey:UITransitionContextToViewControllerKey]);
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

    [transitionContext containerView].backgroundColor = fromVC.view.backgroundColor;

    // Trigger the layout of the new cells
    [[transitionContext containerView] layoutIfNeeded];

    // Plain animation that moves the destination controller in place. Once it's done it will notify the transition context
    if (self.operation == UINavigationControllerOperationPush) {
        [toVC.view setTransform:CGAffineTransformMakeTranslation(1, 0)];
        [UIView animateWithDuration:self.duration + self.maxDelay delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            [toVC.view setTransform:CGAffineTransformIdentity];
        } completion:^(BOOL finished2) {
            [transitionContext completeTransition:YES];
        }];
    } else {
        [fromVC.view setTransform:CGAffineTransformMakeTranslation(1, 0)];
        [toVC.view setTransform:CGAffineTransformIdentity];
        [UIView animateWithDuration:self.duration + self.maxDelay delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            [fromVC.view setTransform:CGAffineTransformMakeTranslation(0, 0)];
        } completion:^(BOOL finished2) {
            [fromVC.view removeFromSuperview];
            [transitionContext completeTransition:YES];
        }];
    }

    NSArray *fromViews = [self visibleCellsForViewController:fromVC];
    NSArray *toViews = [self visibleCellsForViewController:toVC];

    __block NSArray *currentViews;
    __block NSUInteger currentVisibleViewsCount;

    void (^cellAnimation)(id, NSUInteger, BOOL*) = ^(UIView *view, NSUInteger idx, BOOL *stop){
        BOOL fromMode = currentViews == fromViews;
        NSTimeInterval delay = ((float)idx / (float)currentVisibleViewsCount) * self.maxDelay;
        if (!fromMode) {
            [view setTransform:CGAffineTransformMakeTranslation(delta, 0)];
        }
        void (^animation)() = ^{
            if (fromMode) {
                view.transform = CGAffineTransformMakeTranslation(-delta, 0);
                view.alpha = 0;
            } else {
                view.transform = CGAffineTransformIdentity;
                view.alpha = 1;
            }
        };
        void (^completion)(BOOL) = ^(BOOL finished2){
            if (fromMode) {
                [view setTransform:CGAffineTransformIdentity];
            }
        };
        if (self.transitionType == AMWaveTransitionTypeSubtle) {
            [UIView animateWithDuration:self.duration delay:delay options:UIViewAnimationOptionCurveEaseIn animations:animation completion:completion];
        } else if (self.transitionType == AMWaveTransitionTypeNervous) {
            [UIView animateWithDuration:self.duration delay:delay usingSpringWithDamping:0.75 initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseIn animations:animation completion:completion];
        } else if (self.transitionType == AMWaveTransitionTypeBounce){
            [UIView animateWithDuration:self.duration delay:delay options:UIViewAnimationOptionCurveEaseInOut animations:animation completion:completion];
        }
    };


    currentViews = fromViews;
    NSArray *viewsArrays = @[fromViews, toViews];

    for (currentViews in viewsArrays) {
        // Animates all views
        currentVisibleViewsCount = currentViews.count;
        [currentViews enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:cellAnimation];
    }
}

- (NSArray *)visibleCellsForViewController:(UIViewController*)viewController {
    NSArray *visibleCells = nil;

    if ([viewController respondsToSelector:@selector(visibleCells)]) {
        visibleCells = ((UIViewController<AMWaveTransitioning>*)viewController).visibleCells;
    } else if ([viewController respondsToSelector:@selector(tableView)]) {
        visibleCells = ((UITableViewController*)viewController).tableView.am_visibleViews;
    }
    if (visibleCells.count) {
        return visibleCells;
    } else if (viewController.view) {
        return @[viewController.view];
    }
    return nil;
}

@end

@implementation UITableView (AMWaveTransition)

- (NSArray*)am_visibleViews {
    NSMutableArray *views = [NSMutableArray array];
    
    if (self.tableHeaderView.frame.size.height) {
        [views addObject:self.tableHeaderView];
    }
    
    NSInteger section = -1;
    for (NSIndexPath *indexPath in self.indexPathsForVisibleRows) {
        if (section != indexPath.section) {
            section = indexPath.section;
            UIView *view = [self headerViewForSection:section];
            if (view.frame.size.height) {
                [views addObject:view];
            }
            
            for (NSIndexPath *sectionIndexPath in self.indexPathsForVisibleRows) {
                if (sectionIndexPath.section != indexPath.section) {
                    continue;
                }
                
                view = [self cellForRowAtIndexPath:sectionIndexPath];
                if (view.frame.size.height) {
                    [views addObject:view];
                }
            }
            
            view = [self footerViewForSection:section];
            if (view.frame.size.height) {
                [views addObject:view];
            }
        }
    }
    
    if (self.tableFooterView.frame.size.height) {
        [views addObject:self.tableFooterView];
    }
    
    return views;
}

@end
