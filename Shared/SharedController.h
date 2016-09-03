//
//  SharedController.h
//  Shared
//
//  Created by Brian Bernberg on 9/11/11.
//  Copyright 2011 Bern Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import <iAd/iAd.h>
#import <MessageUI/MessageUI.h>

#import "Parse/Parse.h"
#import "Constants.h"

@protocol ControllerExiting <NSObject>

- (void)controllerRequestsDismissal:(UIViewController *)controller;

@end

@interface SharedController : NSObject

- (void)showSplashView;
- (void)logout;

@property (nonatomic) SharedControllerType initialController;
@property (nonatomic) NSDate *initialCalendarDate;

@end
