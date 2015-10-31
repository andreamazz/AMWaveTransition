//
//  AMWaveTransition.h
//  AMWaveTransition
//
//  Created by Andrea on 11/04/14.
//  Copyright (c) 2015 Fancy Pixel. All rights reserved.
//

@import UIKit;

/**
 * @name AMWaveTransitioning
 * Delegate protocol for AMWaveTransition
 */
@protocol AMWaveTransitioning <NSObject>

/** Visible cells
 *
 * Returns the cells that need to be animated. 
 *
 * @return An array of UIViews
 */
- (NSArray*)visibleCells;

@end

/** @enum AMWaveTransitionType
 *
 * Enum that specifies the type of animation
 */
typedef NS_ENUM(NSInteger, AMWaveTransitionType) {
    /** Smooth transition */
    AMWaveTransitionTypeSubtle,
    /** Springy transition */
    AMWaveTransitionTypeNervous,
    /** Spring transition with looser springs */
    AMWaveTransitionTypeBounce
};

/** @enum AMWaveInteractiveTransitionType
 *
 * Enum that specifies the transition type
 */
typedef NS_ENUM(NSInteger, AMWaveInteractiveTransitionType) {
    /** The transition needs to start from the edge */
    AMWaveTransitionEdgePan,
    /** The transition can start from anywhere */
    AMWaveTransitionFullScreenPan
};

/**
 * @name AMWaveTransition
 * Custom transition between viewcontrollers holding tableviews. Each cell is animated to simulate a 'wave effect'.
 */
@interface AMWaveTransition : NSObject <UIViewControllerAnimatedTransitioning>

/** New transition
 *
 * Returns a AMWaveTransition instance.
 *
 * @param operation The UINavigationControllerOperation that determines the transition type (push or pop)
 */
+ (instancetype)transitionWithOperation:(UINavigationControllerOperation)operation;

/** New transition
 *
 * Returns a AMWaveTransition instance.
 *
 * @param operation The UINavigationControllerOperation that determines the transition type (push or pop)
 * @param type The transition type
 */
+ (instancetype)transitionWithOperation:(UINavigationControllerOperation)operation andTransitionType:(AMWaveTransitionType)type;

/** New transition
 *
 * Returns a AMWaveTransition instance.
 *
 * @param operation The UINavigationControllerOperation that determines the transition type (push or pop)
 */
- (instancetype)initWithOperation:(UINavigationControllerOperation)operation;

/** New transition
 *
 * Returns a AMWaveTransition instance.
 *
 * @param operation The UINavigationControllerOperation that determines the transition type (push or pop)
 * @param type The transition type
 */
- (instancetype)initWithOperation:(UINavigationControllerOperation)operation andTransitionType:(AMWaveTransitionType)type;

/** Attach the interactive gesture
 *
 * Attach the interactive gesture to the navigation controller. This will pop the current view controller when the user swipes from the left edge.
 * Make sure to detach the gesture when done.
 *
 * @param navigationController The UINavigationController that holds the current view controller
 */
- (void)attachInteractiveGestureToNavigationController:(UINavigationController *)navigationController;

/** Detach the interactive gesture
 *
 * Detaches the interactive gesture.
 */
- (void)detachInteractiveGesture;

/**
 * @name AMWaveTransition Properties
 */

/** Operation type
 *
 * Sets the operation type (push or pop)
 */
@property (assign, nonatomic) UINavigationControllerOperation operation;

/** Transition type
 *
 * Sets the transition style
 */
@property (assign, nonatomic) AMWaveTransitionType transitionType;

/** Animation duration
 *
 * Sets the duration of the animation. The whole duration accounts for the maxDelay property.
 */
@property (assign, nonatomic) CGFloat duration;

/** Maximum animation delay
 *
 * Sets the max delay that a cell will wait beofre animating.
 */
@property (assign, nonatomic) CGFloat maxDelay;

/** Inset between view controllers
 *
 * Sets the inset between view controllers. Defaults to 20 points.
 */
@property (assign, nonatomic) CGFloat viewControllersInset;

/** Alpha animation with interactive transition
 *
 * Turn on/off alpha animation with interactive transition. Defaults to NO.
 */
@property (assign, nonatomic) BOOL animateAlphaWithInteractiveTransition;

/** Interactive transition type
 *
 * Sets interactive transition type (edge or fullscreen). Defaults to edge.
 */
@property (assign, nonatomic) AMWaveInteractiveTransitionType interactiveTransitionType;

@end
