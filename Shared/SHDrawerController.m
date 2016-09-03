//
//  SHDrawerController.m
//  Shared
//
//  Created by Brian Bernberg on 7/26/15.
//  Copyright (c) 2015 BB Consulting. All rights reserved.
//

#import "SHDrawerController.h"

@interface SHDrawerController ()

@end

@implementation SHDrawerController

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
  if ( [self.centerViewController isKindOfClass:[UINavigationController class]] ) {
    UIViewController *vc = [(UINavigationController *)self.centerViewController topViewController];
    if ( vc.presentedViewController && ![vc.presentedViewController isKindOfClass:[UIAlertController class]] ) {
      vc = vc.presentedViewController;
      if ( [vc isKindOfClass:[UINavigationController class]] ) {
        vc = [(UINavigationController *)vc topViewController];
      }
      return [vc supportedInterfaceOrientations];
    } else {
      return [[(UINavigationController *)self.centerViewController topViewController] supportedInterfaceOrientations];
    }
  } else {
    return [self.centerViewController supportedInterfaceOrientations];
  }
}

@end
