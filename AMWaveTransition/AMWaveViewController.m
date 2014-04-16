//
//  AMWaveViewController.m
//  Demo
//
//  Created by Andrea Mazzini on 16/04/14.
//  Copyright (c) 2014 Fancy Pixel. All rights reserved.
//

#import "AMWaveViewController.h"
#import "AMWaveTransition.h"

@interface AMWaveViewController () <UINavigationControllerDelegate, AMWaveTransitioning>

@end

@implementation AMWaveViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.navigationController setDelegate:self];
}

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                  animationControllerForOperation:(UINavigationControllerOperation)operation
                                               fromViewController:(UIViewController*)fromVC
                                                 toViewController:(UIViewController*)toVC
{
    if (operation != UINavigationControllerOperationNone) {
        return [AMWaveTransition transitionWithOperation:operation];
    }
    return nil;
}

- (NSArray*)visibleCells
{
    return nil;
}

- (void)dealloc
{
    [self.navigationController setDelegate:nil];
}

@end
