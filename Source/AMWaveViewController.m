//
//  AMWaveViewController.m
//  Demo
//
//  Created by Andrea Mazzini on 16/04/14.
//  Copyright (c) 2015 Fancy Pixel. All rights reserved.
//

#import "AMWaveViewController.h"

@interface AMWaveViewController ()

@end

@implementation AMWaveViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.navigationController setDelegate:self];
    [self.interactive attachInteractiveGestureToNavigationController:self.navigationController];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.interactive detachInteractiveGesture];
}

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                  animationControllerForOperation:(UINavigationControllerOperation)operation
                                               fromViewController:(UIViewController*)fromVC
                                                 toViewController:(UIViewController*)toVC {
    if (operation != UINavigationControllerOperationNone) {
        return [AMWaveTransition transitionWithOperation:operation andTransitionType:AMWaveTransitionTypeNervous];
    }
    return nil;
}

- (NSArray *)visibleCells {
    return nil;
}

- (void)dealloc {
    [self.navigationController setDelegate:nil];
}

@end
