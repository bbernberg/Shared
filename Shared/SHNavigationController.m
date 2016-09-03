//
//  SHNavigationController.m
//  Shared
//
//  Created by Brian Bernberg on 9/2/15.
//  Copyright (c) 2015 BB Consulting. All rights reserved.
//

#import "SHNavigationController.h"

@interface SHNavigationController ()

@end

@implementation SHNavigationController

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
  return [self.topViewController supportedInterfaceOrientations];
}

@end
