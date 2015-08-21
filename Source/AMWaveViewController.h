//
//  AMWaveViewController.h
//  Demo
//
//  Created by Andrea Mazzini on 16/04/14.
//  Copyright (c) 2015 Fancy Pixel. All rights reserved.
//

#import "AMWaveTransition.h"

@import UIKit;

@interface AMWaveViewController : UIViewController <UINavigationControllerDelegate, AMWaveTransitioning>

/**-----------------------------------------------------------------------------
 * @name AMWaveViewController
 * -----------------------------------------------------------------------------
 */

/** Wave transition
 *
 * The AMWaveTranstion used by the controller
 */
@property (strong, nonatomic) IBOutlet AMWaveTransition *interactive;

@end
