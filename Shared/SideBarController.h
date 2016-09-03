//
//  SideBarController.h
//  Shared
//
//  Created by Brian Bernberg on 6/22/15.
//  Copyright (c) 2015 BB Consulting. All rights reserved.
//

#import "SHViewController.h"
#import "NotificationController.h"

@interface SideBarController : SHViewController <NotificationControllerDelegate>

- (void)reloadData;
- (void)showViewControllerInMainDrawer:(UIViewController *)viewController;
- (void)showViewControllerInMainDrawer:(UIViewController *)viewController animated:(BOOL)animated;
@end
