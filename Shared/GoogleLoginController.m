//
//  GoogleLoginController.m
//  Shared
//
//  Created by Brian Bernberg on 2/19/13.
//  Copyright (c) 2013 BB Consulting. All rights reserved.
//


#import "GoogleLoginController.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "SHUtil.h"

@interface GoogleLoginController ()

@end

@implementation GoogleLoginController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  
  __weak GoogleLoginController *wSelf = self;
  self.popViewBlock = ^{
    [wSelf dismissViewControllerAnimated:YES completion:NULL];
  };
  
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
  return UIInterfaceOrientationMaskPortrait;
}

- (void)setUpNavigation {
  self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                        target:self
                                                                                        action:@selector(cancelButtonPressed:)];
  self.navigationItem.rightBarButtonItem = nil;
}

-(void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  
  self.automaticallyAdjustsScrollViewInsets = YES;
}

// button actions
-(void)cancelButtonPressed:(id)sender {
  [self cancelSigningIn];
  if ( self.cancelBlock ) {
    self.cancelBlock();
  }
}

- (void)moveWebViewFromUnderNavigationBar {
  // Do nothing
}

@end
