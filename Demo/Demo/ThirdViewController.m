
//
//  ThirdViewController.m
//  Demo
//
//  Created by Andrea on 30/04/14.
//  Copyright (c) 2014 Fancy Pixel. All rights reserved.
//

#import "ThirdViewController.h"
#import "AMWaveTransition.h"

@interface ThirdViewController () <UITableViewDataSource, UITableViewDelegate, UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (assign, nonatomic) AMWaveTransitionType animationType;
@property (strong, nonatomic) IBOutlet AMWaveTransition *interactive;
@property (weak, nonatomic) IBOutlet UISwitch *animationSwitch;

@end

@implementation ThirdViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view setBackgroundColor:[UIColor clearColor]];
    [self.tableView setBackgroundColor:[UIColor clearColor]];
    _interactive = [[AMWaveTransition alloc] init];
    self.animationType = AMWaveTransitionTypeNervous;
    self.tableView.contentInset = UIEdgeInsetsMake(-68, 0, 0, 0);
    self.animationSwitch.onTintColor = [UIColor colorWithRed:0.91 green:0.6 blue:0.21 alpha:1];
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

- (IBAction)actionSwitch:(UISwitch *)sender
{
    if ([sender isOn]) {
        self.animationType = AMWaveTransitionTypeNervous;
    } else {
        self.animationType = AMWaveTransitionTypeSubtle;
    }
}

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                  animationControllerForOperation:(UINavigationControllerOperation)operation
                                               fromViewController:(UIViewController*)fromVC
                                                 toViewController:(UIViewController*)toVC
{
    if (operation != UINavigationControllerOperationNone) {
        AMWaveTransition *transition = [AMWaveTransition transitionWithOperation:operation];
        [transition setTransitionType:self.animationType];
        return transition;
    }
    return nil;
}

- (NSArray*)visibleCells
{
    NSMutableArray *cells = [@[] mutableCopy];
    [cells addObject:self.headerView];
    [cells addObjectsFromArray:[self.tableView visibleCells]];
    
    return cells;
}

- (void)dealloc
{
    [self.navigationController setDelegate:nil];
}

@end
