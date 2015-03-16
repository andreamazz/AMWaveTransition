//
//  AMWaveViewController.h
//  Demo
//
//  Created by Andrea Mazzini on 16/04/14.
//  Copyright (c) 2014 Fancy Pixel. All rights reserved.
//

#import "AMWaveTransition.h"

@import UIKit;

@interface AMWaveViewController : UIViewController <UINavigationControllerDelegate, AMWaveTransitioning>

@property (strong, nonatomic) IBOutlet AMWaveTransition *interactive;

@end
