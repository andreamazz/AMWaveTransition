//
//  SecondViewController.m
//  Demo
//
//  Created by Andrea on 16/04/14.
//  Copyright (c) 2014 Fancy Pixel. All rights reserved.
//

#import "SecondViewController.h"
#import "AMWaveTransition.h"

@interface SecondViewController () <UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet AMWaveTransition *interactive;

@end

@implementation SecondViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view setBackgroundColor:[UIColor clearColor]];
    [self.tableView setBackgroundColor:[UIColor clearColor]];
    _interactive = [[AMWaveTransition alloc] init];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.navigationController setDelegate:self];
    [self.interactive attachInteractiveGestureToNavigationController:self.navigationController];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.interactive detachInteractiveGesture];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 10;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    cell.textLabel.text = @"John Doe";
    cell.detailTextLabel.text = @"Transitions fanatic";
    [cell setBackgroundColor:[UIColor clearColor]];
	[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    return cell;
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

- (void)dealloc
{
    [self.navigationController setDelegate:nil];
}

@end
