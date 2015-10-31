//
//  AMWaveViewController.h
//  Demo
//
//  Created by Andrea Mazzini on 16/04/14.
//  Copyright (c) 2015 Fancy Pixel. All rights reserved.
//

#import "AMWaveTransition.h"

#import <UIKit/UIKit.h>

/**
 * @name AMWaveViewController
 * UIViewController subclass that implements the custom transition
 */
@interface AMWaveViewController : UIViewController <UINavigationControllerDelegate, AMWaveTransitioning>

/** Wave transition
 *
 * The AMWaveTranstion used by the controller
 */
@property (strong, nonatomic) IBOutlet AMWaveTransition *interactive;

@end
