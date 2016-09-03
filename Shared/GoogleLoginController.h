//
//  GoogleLoginController.h
//  Shared
//
//  Created by Brian Bernberg on 2/19/13.
//  Copyright (c) 2013 BB Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GTMOAuth2ViewControllerTouch.h"

@class GTMOAuth2ViewControllerTouch;

@interface GoogleLoginController : GTMOAuth2ViewControllerTouch

@property (nonatomic, copy) void (^cancelBlock)(void);

@end
