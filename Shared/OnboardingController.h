//
//  OnboardingLoginViewController.h
//  Shared
//
//  Created by Brian Bernberg on 12/24/12.
//  Copyright (c) 2012 BB Consulting. All rights reserved.
//

#import "SHViewController.h"

@protocol ControllerExiting;

@interface OnboardingController : SHViewController

- (instancetype)initWithDelegate:(id<ControllerExiting>)delegate;

@end
