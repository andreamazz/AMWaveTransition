//
//  AMWaveTransition.h
//  AMWaveTransition
//
//  Created by Andrea on 11/04/14.
//  Copyright (c) 2014 Fancy Pixel. All rights reserved.
//

@import UIKit;

@protocol AMWaveTransitioning <NSObject>

- (NSArray*)visibleCells;

@end

typedef NS_ENUM(NSInteger, AMWaveTransitionType) {
    AMWaveTransitionTypeSubtle,
    AMWaveTransitionTypeNervous,
    AMWaveTransitionTypeBounce
};

@interface AMWaveTransition : NSObject <UIViewControllerAnimatedTransitioning>

/**-----------------------------------------------------------------------------
 * @name AMWaveTransition
 * -----------------------------------------------------------------------------
 */

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

/**-----------------------------------------------------------------------------
 * @name AMWaveTransition Properties
 * -----------------------------------------------------------------------------
 */

/** Operation type
 *
 * Sets the operation type (push or pop)
 *
 */
@property (assign, nonatomic) UINavigationControllerOperation operation;

/** Transition type
 *
 * Sets the transition style
 *
 */
@property (assign, nonatomic) AMWaveTransitionType transitionType;

/** Animation duration
 *
 * Sets the duration of the animation. The whole duration accounts for the maxDelay property.
 *
 */
@property (assign, nonatomic) CGFloat duration;

/** Maximum animation delay
 *
 * Sets the max delay that a cell will wait beofre animating.
 *
 */
@property (assign, nonatomic) CGFloat maxDelay;

@end
