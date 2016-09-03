//
//  SplashViewController.m
//  Shared
//
//  Created by Brian Bernberg on 7/7/15.
//  Copyright (c) 2015 BB Consulting. All rights reserved.
//

#import "SplashViewController.h"
#import "SharedActivityIndicator.h"

@interface SplashViewController ()

@property (nonatomic, weak) IBOutlet SharedActivityIndicator *loadingSpinner;

@end

@implementation SplashViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.loadingSpinner.image = [UIImage imageNamed:@"Shared_Icon_White_Transparent"];
  [self.loadingSpinner startAnimating];
  
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  [self.loadingSpinner startAnimating];
  
}

@end
