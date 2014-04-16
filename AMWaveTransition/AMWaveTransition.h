//
//  AMWaveTransition.h
//  AMWaveTransition
//
//  Created by Andrea on 11/04/14.
//  Copyright (c) 2014 Fancy Pixel. All rights reserved.
//

@protocol AMWaveTransitioning <NSObject>

- (NSArray*)visibleCells;

@end

typedef NS_ENUM(NSInteger, AMWaveTransitionType) {
    AMWaveTransitionTypeSubtle,
    AMWaveTransitionTypeNervous
};

@interface AMWaveTransition : NSObject <UIViewControllerAnimatedTransitioning>

+ (instancetype)transitionWithOperation:(UINavigationControllerOperation)operation;
- (instancetype)initWithOperation:(UINavigationControllerOperation)operation;

@property (assign, nonatomic) AMWaveTransitionType transitionType UI_APPEARANCE_SELECTOR;
@property (assign, nonatomic) UINavigationControllerOperation operation;

@end
