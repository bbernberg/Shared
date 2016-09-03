//
//  SharedController.m
//  Shared
//
//  Created by Brian Bernberg on 9/11/11.
//  Copyright 2011 Bern Software. All rights reserved.
//

// Later: upload progress on audio messages & photo uploads in general

#import "SharedController.h"
#import <MMDrawerController/MMDrawerController.h>

#import "Constants.h"
#import <QuartzCore/QuartzCore.h>
#import <Parse/Parse.h>
#import "TextController.h"
#import <AVFoundation/AVFoundation.h>
#import "ListsController.h"
#import "SettingsController.h"
#import "LogInController.h"
#import "SVProgressHUD.h"
#import "User.h"
#import "PSPDFAlertView.h"
#import "DriveFilesListController.h"
#import "GoogleCalendarContainerController.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "ChoosePartnerController.h"
#import "OnboardingController.h"
#import <Crashlytics/Crashlytics.h>
#import "TMCache.h"
#import "SHUtil.h"
#import "GlympseLiteWrapper.h"
#import "NotificationRetriever.h"
#import "NotificationController.h"
#import "FPPopoverController.h"
#import "PartnerStatusController.h"
#import "SplashViewController.h"
#import "SideBarController.h"

@interface SharedController () <ControllerExiting>

@property (nonatomic, readonly) SharedAppDelegate *appDelegate;
@property (nonatomic, readonly) MMDrawerController *drawerController;
@property (nonatomic) SHNavigationController *modalNav;
@property (nonatomic) SplashViewController *splashController;

@end

@implementation SharedController

- (id)init {
  self = [super init];
  if (self) {
    [self showSplashView];
    [self doGlobalInit];
    
    SharedControllerType controllerType = (SharedControllerType)[[NSUserDefaults standardUserDefaults] integerForKey:kCurrentSharedControllerType];
    _initialController = controllerType > 0 ? controllerType : SharedControllerTypeText;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      [self checkUserStatus];
    });
  }
  return self;
}

#pragma mark getters/setters
- (SharedAppDelegate *)appDelegate {
  return (SharedAppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (MMDrawerController *)drawerController {
  return self.appDelegate.viewController;
}

- (SHNavigationController *)modalNav {
  if ( ! _modalNav ) {
    _modalNav = [[SHNavigationController alloc] init];
  }
  return _modalNav;
}

- (SplashViewController *)splashController {
  if ( ! _splashController ) {
    _splashController = [[SplashViewController alloc] initWithNibName:nil bundle:nil];
  }
  return _splashController;
}

- (void)doGlobalInit {
  // Audio session code
  NSError *sessionError = nil;
  [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:&sessionError];
  [[AVAudioSession sharedInstance] setActive:YES error:&sessionError];
  
  [[[TMCache sharedCache] memoryCache] setAgeLimit:60*60*24]; // one day
  [[[TMCache sharedCache] diskCache] setAgeLimit:60*60*24]; // one day
  
  [self registerForNotifications];
}

- (void)registerForNotifications {
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(logout) name:kShouldLogoutNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUserLoggedIn) name:kUserLoggedInNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNewUserLoggedIn) name:kNewUserLoggedInNotification object:nil];
}

- (void)checkUserStatus {
  if ([[NSUserDefaults standardUserDefaults] boolForKey:kIntroShownKey] == YES) {
    // TODO: maintain FB login for legacy?
    
    if ( [PFUser currentUser] ) {
      [User initWithUserID:[PFUser currentUser].username];
      if ( [User currentUser].validData ) {
        [User currentUser].myUserEmail = [[PFUser currentUser] username];
        [self initializeSession];
      } else {
        [self logout];
      }
      [self.appDelegate.sideBarController reloadData];
    } else {
      LogInController *loginController = [[LogInController alloc] initWithNibName:nil bundle:nil];
      [self showInModalNav:loginController makeRoot:YES hideNavBar:YES animated:NO];
    }
  } else {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kIntroShownKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self logout];
    OnboardingController *vc = [[OnboardingController alloc] initWithDelegate:self];
    [self showInModalNav:vc makeRoot:YES hideNavBar:YES animated:NO];
  }
  
#ifdef INCLUDE_MIGRATION
  [self migrateUsers];
#endif
  
}

-(void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark session initialization
-(void)initializeSession {
  if ( [User currentUser].validData && [[User currentUser] hasPartner] ) {
    [[User currentUser] fetchUserInBackground];
    [self checkPartnerStatus];
  } else {
    [[User currentUser] fetchUserWithCompletionBlock:^(NSNumber *result) {
      if ([result integerValue] == kFetchUserError) {
        // problem refreshing user so logout
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                       message:@"Unable to log in at this time. Please try later."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [[kAppDelegate viewControllerForPresentation] presentViewController:alert
                                                                   animated:YES
                                                                 completion:nil];
        
        [self logout];
      } else {
        [self checkPartnerStatus];
      }
    }];
  }
}

-(void)checkPartnerStatus {
  if ([[User currentUser] hasPartner]) {
    [self initializeUserData];
    [self showLoggedInView];
  } else {
    [self choosePartner];
  }
}

#pragma mark UI helpers
- (void)showSplashView {
  [self.drawerController addChildViewController:self.splashController];
  self.splashController.view.frame = self.drawerController.view.bounds;
  [self.drawerController.view addSubview:self.splashController.view];
  [self.splashController didMoveToParentViewController:self.drawerController];
}

- (void)removeSplashView {
  if ( self.splashController.parentViewController ) {
    [self.splashController willMoveToParentViewController:nil];
    [self.splashController.view removeFromSuperview];
    [self.splashController removeFromParentViewController];
  }
}

- (void)showInModalNav:(UIViewController *)controller
              makeRoot:(BOOL)makeRoot
            hideNavBar:(BOOL)hideNavBar
              animated:(BOOL)animated {
  [self removeSplashView];
  
  if ( ! [self.modalNav presentingViewController] ) {
    [self.drawerController presentViewController:self.modalNav animated:animated completion:nil];
  }
  
  self.modalNav.navigationBarHidden = hideNavBar;
  
  if ( makeRoot ) {
    [self.modalNav setViewControllers:@[controller] animated:animated];
  } else {
    [self.modalNav pushViewController:controller animated:animated];
  }
}

#pragma mark ControllerExiting
- (void)controllerRequestsDismissal:(UIViewController *)controller {
  if ( [controller isKindOfClass:[OnboardingController class]] ) {
    [self checkUserStatus];
  } else if ( [controller isKindOfClass:[PartnerStatusController class]] ) {
    [self showLoggedInView];
  }
}

#pragma mark partner selection functions
-(void)choosePartner {
  ChoosePartnerController *vc = [[ChoosePartnerController alloc] initWithCompletionBlock:^{
    PartnerStatusController *con = [[PartnerStatusController alloc] initWithDelegate:self];
    [self showInModalNav:con makeRoot:NO hideNavBar:YES animated:NO];
    [self initializeUserData];
  } useCancelButton:NO];
  [self showInModalNav:vc makeRoot:YES hideNavBar:NO animated:NO];
}

#pragma mark other functions

-(void)initializeUserData {
  
  // register for push notifications
  [[UIApplication sharedApplication] registerForRemoteNotifications];
  
  [[Crashlytics sharedInstance] setUserIdentifier:[User currentUser].myUserID];
  
  [[GlympseLiteWrapper instance] start];
  
  [[NotificationRetriever instance] retrieveNotifications];
  
  [[User currentUser] getPartnerData];
}

- (void)showLoggedInView {
  UIViewController *vc = nil;
  
  switch (self.initialController) {
    case SharedControllerTypeText:
    default:
      vc = [[TextController alloc] initWithNibName:nil bundle:nil];
      break;
    case SharedControllerTypeCalendar:
      vc = [[GoogleCalendarContainerController alloc] init];
      [(GoogleCalendarContainerController *)vc setInitialDate:self.initialCalendarDate];
      break;
    case SharedControllerTypeList:
      vc = [[ListsController alloc] init];
      break;
    case SharedControllerTypeDrive:
      vc = [[DriveFilesListController alloc] initWithFolderID:nil andFolderName:nil];
      break;
    case SharedControllerTypeSettings:
      vc = [[SettingsController alloc] init];
      break;
    case SharedControllerTypeNotifications:
      vc = [[NotificationController alloc] initWithDelegate:self.appDelegate.sideBarController];
  }
  
  [self.appDelegate.navController setViewControllers:@[vc] animated:NO];
  
  if ( self.modalNav.presentingViewController ) {
    [self.modalNav dismissViewControllerAnimated:NO completion:nil];
  }
  
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    [self removeSplashView];
  });
  
#ifdef kIncludeCheckUserEmail
  if ( ! [User currentUser].myUserEmail ) {
    [self getUserEmail];
  }
#endif

}

- (void)handleUserLoggedIn {
  [self initializeSession];
}

- (void)handleNewUserLoggedIn {
  [self checkPartnerStatus];
}

-(void)logout {
  // Unsubscribe from push notifications
  [[PFInstallation currentInstallation] removeObjectForKey:kInstallationUserIDsKey];
  [[PFInstallation currentInstallation] saveInBackground];
  
  [GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName:kGoogleDriveKeychainItemName];
  [GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName:kGoogleCalendarKeychainItemName];
  [PFUser logOut];
  
  [[GlympseLiteWrapper instance] logout];
  
  [[Crashlytics sharedInstance] setUserIdentifier:@"Logged out"];
  
  // Log out
  [User logout];
  
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:kPartnerStatusKey];
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:kPartnerStatusDateKey];
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCurrentSharedControllerType];
  [[NSUserDefaults standardUserDefaults] synchronize];

  if ( self.appDelegate.navController.topViewController.presentedViewController ) {
    [self.appDelegate.navController.topViewController dismissViewControllerAnimated:NO completion:nil];
  }
  
  if ( [[self.drawerController presentedViewController] presentedViewController] ) {
    [self.drawerController dismissViewControllerAnimated:NO completion:nil];
  }
  
  [[NSNotificationCenter defaultCenter] postNotificationName:kDidLogoutNotification object:nil];
  
  LogInController *loginController = [[LogInController alloc] initWithNibName:nil bundle:nil];
  [self showInModalNav:loginController makeRoot:YES hideNavBar:YES animated:NO];
  
}

-(void)clearCache {
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
    NSFileManager* fm = [NSFileManager defaultManager];
    for (NSURL* dirUrl in [fm URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask])
    {
      NSDirectoryEnumerator* dirEnum = [fm enumeratorAtURL: dirUrl
                                includingPropertiesForKeys: [NSArray arrayWithObject: NSFileModificationDate]
                                                   options: 0
                                              errorHandler: ^(NSURL* a, NSError* b){ return (BOOL)YES; }];
      NSURL* url = nil;
      while ((url = [dirEnum nextObject]))
      {
        [fm removeItemAtURL:url error: NULL];
      }
    }
    
  });
}

#pragma mark notification handling

-(void)notificationButtonPressed:(UIButton *)button {
//  NotificationController *con = [[NotificationController alloc] initWithDelegate:self];
}

/*
-(void)updateNotificationButton {
  
  if ([NotificationRetriever instance].notifications.count > 0) {
    NSString *title = [NSString stringWithFormat:@"%lu", (unsigned long)[NotificationRetriever instance].notifications.count];
    [button setTitle:title forState:UIControlStateNormal];
    button.hidden = NO;
    [UIView animateWithDuration:0.4
                     animations:^{
                       button.alpha = 1.0;
                     }];
  } else {
    [button setTitle:@"0" forState:UIControlStateNormal];
    [UIView animateWithDuration:0.4
                     animations:^{
                       button.alpha = 0.0;
                     } completion:^(BOOL finished) {
                       button.hidden = YES;
                     }];
  }
}
*/

#pragma mark migration code

#ifdef INCLUDE_MIGRATION
-(void) migrateUsers {
  PFQuery *textQuery = [PFQuery queryWithClassName:kPFTextClassKey];
  
  [textQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
    for (PFObject* text in objects) {
      NSArray *users = text[@"textUsersV2"];
      [text setObject:users[0] forKey:kTextUserOneKey];
      [text setObject:users[1] forKey:kTextUserTwoKey];
      [text saveInBackground];
    }
  }];
  
  PFQuery *fbQuery = [PFQuery queryWithClassName:kFBObjectClassKey];
  
  [fbQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
    for (PFObject* object in objects) {
      NSArray *users = object[@"FBObjectUsersV2"];
      [object setObject:users[0] forKey:kFBObjectUserOneKey];
      [object setObject:users[1] forKey:kFBObjectUserTwoKey];
      [object saveInBackground];
    }
  }];
  
  
  PFQuery *listQuery = [PFQuery queryWithClassName:kListClassKey];
  
  [listQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
    for (PFObject* object in objects) {
      NSArray *users = object[@"listUsersV2"];
      [object setObject:users[0] forKey:kListUserOneKey];
      [object setObject:users[1] forKey:kListUserTwoKey];
      [object saveInBackground];
    }
  }];
  
  PFQuery *listItemQuery = [PFQuery queryWithClassName:kListItemClassKey];
  
  [listItemQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
    for (PFObject* object in objects) {
      NSArray *users = object[@"listUsersV2"];
      [object setObject:users[0] forKey:kListUserOneKey];
      [object setObject:users[1] forKey:kListUserTwoKey];
      [object saveInBackground];
    }
  }];
  
  PFQuery *driveQuery = [PFQuery queryWithClassName:kDriveFolderClassKey];
  
  [driveQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
    for (PFObject* object in objects) {
      NSArray *users = object[@"driveFolderUsers"];
      [object setObject:users[0] forKey:kDriveFolderUserOneKey];
      [object setObject:users[1] forKey:kDriveFolderUserTwoKey];
      [object saveInBackground];
    }
  }];
  
  PFQuery *calQuery = [PFQuery queryWithClassName:kGoogleCalendarClassKey];
  
  [calQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
    for (PFObject* object in objects) {
      NSArray *users = object[@"calendarUsers"];
      [object setObject:users[0] forKey:kGoogleCalendarUserOneKey];
      [object setObject:users[1] forKey:kGoogleCalendarUserTwoKey];
      [object saveInBackground];
    }
  }];
  
}

#endif

- (void)getUserEmail {
  __block NSString *emailAddress;
  __block NSString *password;
  PSPDFAlertView *alert = [[PSPDFAlertView alloc] initWithTitle:nil
                                                        message:@"Please enter an e-mail address and password for your account:"];
  alert.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
  __weak PSPDFAlertView *weakAlert = alert;
  [alert setCancelButtonWithTitle:@"OK"
                    block:^(NSInteger buttonIndex) {
                      [SVProgressHUD showWithStatus:@"Signing up"];
                      emailAddress = [weakAlert textFieldAtIndex:0].text;
                      password = [weakAlert textFieldAtIndex:1].text;
                      PFUser *newUser = [PFUser user];
                      newUser.username = emailAddress;
                      newUser.email = emailAddress;
                      newUser.password = password;
                      [newUser signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                        if (succeeded) {
                          [User currentUser].myUserEmail = emailAddress;
                          [[User currentUser] saveUser];
                          [SVProgressHUD showSuccessWithStatus:@"Signed up"];
                        } else {
                          [SVProgressHUD showErrorWithStatus:@"Unable to sign up at this time"];
                        }
                      }];
                      
                    }];
  [alert show];
}



@end
