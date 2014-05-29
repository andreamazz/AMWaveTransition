//
//  ViewController.m
//  Demo
//
//  Created by Andrea on 16/04/14.
//  Copyright (c) 2014 Fancy Pixel. All rights reserved.
//

#import "ViewController.h"
#import "AMWaveTransition.h"

@interface ViewController () <UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray *data;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.navigationController.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"background"]]];
	[self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"navbar"] forBarMetrics:UIBarMetricsDefault];
    [self.view setBackgroundColor:[UIColor clearColor]];
    [self.tableView setBackgroundColor:[UIColor clearColor]];
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];

    [self setTitle:@"Demo"];
    self.data =
    @[
      @{@"text": @"Stylized organs", @"icon": @"heart"},
      @{@"text": @"Food pictures", @"icon": @"camera"},
      @{@"text": @"Straight line maker", @"icon": @"pencil"},
      @{@"text": @"Let's cook!", @"icon": @"beaker"},
      @{@"text": @"That's the puzzle!", @"icon": @"puzzle"},
      @{@"text": @"Cheers", @"icon": @"glass"}
      ];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.navigationController setDelegate:self];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.data count];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    NSDictionary* dict = self.data[indexPath.row];
    
    cell.textLabel.text = dict[@"text"];
    [cell setBackgroundColor:[UIColor clearColor]];
	[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    [cell.imageView setImage:[UIImage imageNamed:dict[@"icon"]]];
    return cell;
}

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                  animationControllerForOperation:(UINavigationControllerOperation)operation
                                               fromViewController:(UIViewController*)fromVC
                                                 toViewController:(UIViewController*)toVC
{
    if (operation != UINavigationControllerOperationNone) {
        return [AMWaveTransition transitionWithOperation:operation andTransitionType:AMWaveTransitionTypeBounce];
    }
    return nil;
}

- (NSArray*)visibleCells
{
    return [self.tableView visibleCells];
}

- (void)dealloc
{
    [self.navigationController setDelegate:nil];
}

@end
