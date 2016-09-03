//
//  PartnerStatusController.h
//  Shared
//
//  Created by Brian Bernberg on 3/3/14.
//  Copyright (c) 2014 BB Consulting. All rights reserved.
//

#import "SHViewController.h"

@protocol ControllerExiting;

@interface PartnerStatusController : SHViewController

- (instancetype)initWithDelegate:(id<ControllerExiting>)delegate;

@end
