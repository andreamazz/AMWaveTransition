//
//  FourthViewController.m
//  Demo
//
//  Created by Andrea Mazzini on 01/05/14.
//  Copyright (c) 2014 Fancy Pixel. All rights reserved.
//

#import "FourthViewController.h"
#import "AMWaveTransition.h"

@interface FourthViewController ()
@property (strong, nonatomic) IBOutlet AMWaveTransition *interactive;
@end

@implementation FourthViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view setBackgroundColor:[UIColor clearColor]];
    
    _interactive = [[AMWaveTransition alloc] init];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.interactive attachInteractiveGestureToNavigationController:self.navigationController];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.interactive detachInteractiveGesture];
}

@end
