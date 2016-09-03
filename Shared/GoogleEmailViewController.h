//
//  GoogleEmailViewController.h
//  Shared
//
//  Created by Brian Bernberg on 8/20/15.
//  Copyright (c) 2015 BB Consulting. All rights reserved.
//

#import "SHViewController.h"

typedef NS_ENUM(NSUInteger, GoogleEmailMode) {
  GoogleEmailModeCalendarMe,
  GoogleEmailModeCalendarPartner,
  GoogleEmailModeDriveMe,
  GoogleEmailModeDrivePartner
};

@protocol GoogleEmailViewControllerDelegate;

@interface GoogleEmailViewController : SHViewController

@property (nonatomic, readonly) GoogleEmailMode mode;

- (instancetype)initWithDelegate:(id<GoogleEmailViewControllerDelegate>)delegate mode:(GoogleEmailMode)mode;

- (id) init __attribute__((unavailable("init not available")));
- (id)initWithCoder:(NSCoder *)aDecoder __attribute__((unavailable("init not available")));
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil __attribute__((unavailable("init not available")));

@end

@protocol GoogleEmailViewControllerDelegate <NSObject>

- (void)controllerDidChooseEmail:(NSString *)email controller:(GoogleEmailViewController *)controller;
- (void)controllerDidCancel:(GoogleEmailViewController *)controller;

@end