//
//  SharedAppDelegate.m
//  Shared
//
//  Created by Brian Bernberg on 9/11/11.
//  Copyright 2011 Shared Software, LLC. All rights reserved.
//

#import "SharedAppDelegate.h"

#import <MMDrawerController/MMDrawerController.h>
#import "SHDrawerController.h"
#import "SharedController.h"
#import "Parse/Parse.h"
#import "Constants.h"
#import "TextService.h"
#import "TextController.h"
#import "DriveFilesListController.h"
#import "MyReach.h"
#import "User.h"
#import <Crashlytics/Crashlytics.h>

#import "GoogleCalendarContainerController.h"
#import "CalendarService.h"
#import "GlympseLiteWrapper.h"
#import "PSPDFAlertView.h"
#import "NotificationRetriever.h"
#import "LTHPasscodeViewController.h"
#import "SideBarController.h"
#import "ListsController.h"
#import "SettingsController.h"
#import <GoogleMaps/GoogleMaps.h>

// BIG TICKET ITEMS TO IMPLEMENT
// Later: Joint Address Book (Google contacts?)
// Later: Joint reading list (Instapaper or Pocket?)
// Later: Joint Evernote
// Later: Joint Dropbox folder
// Later: Places to visit (Matchbook API?)
// Later: Mixtape (Spotify or RDIO?)

static const CGFloat kMinimumRefreshTime = 3600;

@interface SharedAppDelegate ()
@property (nonatomic, strong) SharedController *sharedCon;
@property (nonatomic, strong) SideBarController *sideBarController;
@property (nonatomic, strong) UINavigationController *navController;
@property (nonatomic, strong) NSArray *allButtons;
@property (nonatomic, strong) NSDate *lastRefreshDate;
@property (nonatomic, assign) BOOL firstLaunch;
@property (nonatomic, assign) BOOL notificationsRetrieved;
@end

@implementation SharedAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  // Override point for customization after application launch.
  _firstLaunch = YES;
  _lastRefreshDate = nil;
  [Parse enableLocalDatastore];
  [self setParseDatabase];
  [Crashlytics startWithAPIKey:@"xxxx"];
  [[Crashlytics sharedInstance] setUserIdentifier:@"Logged out"];
    
  [GMSServices provideAPIKey:kGoogleAPIKey];
  
  PFInstallation *currentInstallation = [PFInstallation currentInstallation];
  if (currentInstallation.badge != 0) {
    currentInstallation.badge = 0;
    [currentInstallation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
      if (!succeeded) {
        [currentInstallation saveEventually];
      }
    }];
  }
  [self setupAppearance];
  
  self.navController = [[UINavigationController alloc] init];
  
  self.sideBarController = [[SideBarController alloc] initWithNibName:nil bundle:nil];

  self.viewController = [[SHDrawerController alloc] initWithCenterViewController:self.navController leftDrawerViewController:self.sideBarController];
  self.viewController.openDrawerGestureModeMask = MMOpenDrawerGestureModeBezelPanningCenterView | MMOpenDrawerGestureModePanningNavigationBar;
  self.viewController.closeDrawerGestureModeMask = MMCloseDrawerGestureModeAll;

  self.window.rootViewController = self.viewController;
  [self.window makeKeyAndVisible];
  
  self.sharedCon = [[SharedController alloc] init];
  
  if (launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey]) {
    NSDictionary *userInfo = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
    [self application:application didReceiveRemoteNotification:userInfo];
  }
  
  return YES;
}

-(void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)newDeviceToken
{
  
  [PFPush storeDeviceToken:newDeviceToken];
  
  PFInstallation *currentInstallation = [PFInstallation currentInstallation];
  [currentInstallation setDeviceTokenFromData:newDeviceToken];
  
  if (currentInstallation.badge != 0) {
    currentInstallation.badge = 0;
  }
  
  [currentInstallation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
    if (!succeeded) {
      [currentInstallation saveEventually];
    }
  }];
  
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {

  NSString *pushType = userInfo[kPushTypeKey];
  
  if ([pushType isEqualToString:kTextNotification]) {
    if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive) {
      if ([self navControllerContainsClass:[TextController class]]) {
        [[TextService sharedInstance] retrieveTextsWithRetrieveAction:RetrieveTextActionAll];
      } else {
        [self showTextController];
      }
      [[NotificationRetriever instance] deleteNotificationsOfType:kTextNotification queryServer:YES];
    } else if ([self navControllerContainsClass:[TextController class]]) {
      [[TextService sharedInstance] retrieveTextsWithRetrieveAction:RetrieveTextActionAll];
      [[NotificationRetriever instance] deleteNotificationsOfType:kTextNotification queryServer:YES];
    } else {
      UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Text Message"
                                                                     message:userInfo[@"aps"][@"alert"]
                                                              preferredStyle:UIAlertControllerStyleAlert];
      [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                style:UIAlertActionStyleCancel
                                              handler:nil]];
      [[self viewControllerForPresentation] presentViewController:alert
                                                         animated:YES
                                                       completion:nil];
      
      [[NotificationRetriever instance] retrieveNotifications];
    }
  } else if ([pushType isEqualToString:kDriveUploadNotification]) {
    if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive) {
      [self showGoogleDriveController];
      [[NotificationRetriever instance] deleteNotificationsOfType:kDriveUploadNotification queryServer:YES];
    } else if ([self navControllerContainsClass:[DriveFilesListController class]]) {
      [[NSNotificationCenter defaultCenter] postNotificationName:kDriveRefreshFilesNotification
                                                          object:nil];
      [[NotificationRetriever instance] deleteNotificationsOfType:kDriveUploadNotification queryServer:YES];
    } else {
      UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Google Drive"
                                                                     message:userInfo[@"aps"][@"alert"]
                                                              preferredStyle:UIAlertControllerStyleAlert];
      [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                style:UIAlertActionStyleCancel
                                              handler:nil]];
      [[self viewControllerForPresentation] presentViewController:alert
                                                         animated:YES
                                                       completion:nil];
      
      [[NotificationRetriever instance] retrieveNotifications];
    }
  } else if ([pushType isEqualToString:kListNotification]) {
    if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive) {
      [self showListsController];
      [[NotificationRetriever instance] deleteNotificationsOfType:kListNotification queryServer:YES];
    } else {
      UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Lists"
                                                                     message:userInfo[@"aps"][@"alert"]
                                                              preferredStyle:UIAlertControllerStyleAlert];
      [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                style:UIAlertActionStyleCancel
                                              handler:nil]];
      [[self viewControllerForPresentation] presentViewController:alert
                                                         animated:YES
                                                       completion:nil];
      
      [[NotificationRetriever instance] retrieveNotifications];
    }
  } else if ([pushType isEqualToString:kGoogleCalendarNotification]) {
    if ([self navControllerContainsClass:[GoogleCalendarContainerController class]]) {
      [[CalendarService sharedInstance] retrieveCalendarEvents];
      [[NotificationRetriever instance] retrieveNotifications];
    } else if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive) {
      NSDate *date = nil;
      if ( userInfo[kGoogleCalendarEventDateKey] ) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyyMMdd"];
        date = [formatter dateFromString:userInfo[kGoogleCalendarEventDateKey]];
      }
     
      [self showGoogleCalendarControllerWithSelectedDate:date];
      [[NotificationRetriever instance] deleteNotificationsOfType:kGoogleCalendarNotification queryServer:YES];
    } else {
      UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Google Calendar"
                                                                     message:userInfo[@"aps"][@"alert"]
                                                              preferredStyle:UIAlertControllerStyleAlert];
      [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                style:UIAlertActionStyleCancel
                                              handler:nil]];
      [[self viewControllerForPresentation] presentViewController:alert
                                                         animated:YES
                                                       completion:nil];
      
      [[NotificationRetriever instance] retrieveNotifications];
    }
  } else {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:userInfo[@"aps"][@"alert"]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [[self viewControllerForPresentation] presentViewController:alert
                                                       animated:YES
                                                     completion:nil];    
    [[NotificationRetriever instance] retrieveNotifications];
  }
  self.notificationsRetrieved = YES;
}

-(BOOL)navControllerContainsClass:(Class)objClass {
  for(UIViewController *vc in self.navController.viewControllers) {
    if ([vc isKindOfClass:objClass]) {
      return YES;
    }
  }
  
  return NO;
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
  if ([error code] == 3010) {
    NSLog(@"Push notifications don't work in the simulator!");
  } else {
    NSLog(@"didFailToRegisterForRemoteNotificationsWithError: %@", error);
  }
}

- (void)applicationWillResignActive:(UIApplication *)application
{
  [[GlympseLiteWrapper instance] setActive:NO];
  self.notificationsRetrieved = NO;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
  [[User currentUser] saveUser];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
  PFInstallation *currentInstallation = [PFInstallation currentInstallation];
  if (currentInstallation.badge != 0) {
    currentInstallation.badge = 0;
    [currentInstallation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
      if (!succeeded) {
        [currentInstallation saveEventually];
      }
    }];
  }
  [[GlympseLiteWrapper instance] setActive: YES];
  if ( [User currentUser] && ! self.notificationsRetrieved ) {
    [[NotificationRetriever instance] retrieveNotifications];
    self.notificationsRetrieved = YES;
  }
  
  // TODOS : test that this periodic refresh works
  if (self.firstLaunch) {
    self.firstLaunch = NO;
    self.lastRefreshDate = [NSDate date];
  } else if ([User currentUser] && [self.lastRefreshDate timeIntervalSinceNow] < -kMinimumRefreshTime ) {
    self.lastRefreshDate = [NSDate date];
    if ([User currentUser].myUserID) {
      [[User currentUser] fetchUserInBackground];
    }
    if ([User currentUser].partnerUserID) {
      [[User currentUser] getPartnerData];
    }
  }
  
  NSString* userID = [[NSUserDefaults standardUserDefaults] stringForKey:kLoggedInUserIDKey];
  if (userID) {
    [LTHPasscodeViewController sharedUser].userID = userID;
  }

  if (userID && [[LTHPasscodeViewController sharedUser] passcodeExistsInKeychain]) {
    [[LTHPasscodeViewController sharedUser] showLockScreenWithAnimation:NO];
  }
  
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:kLastLocationUpdated];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)applicationWillTerminate:(UIApplication *)application {
  [[User currentUser] saveUser];
  [[GlympseLiteWrapper instance] stop];
}

#pragma mark utility functions
-(void)setupAppearance {
  [[UIApplication sharedApplication] setStatusBarHidden:NO];
  self.window.tintColor = [SHPalette navyBlue];
  [[UINavigationBar appearance] setBarTintColor:[SHPalette navBarColor]];
  
  [[UIToolbar appearance] setBarTintColor:[SHPalette navBarColor]];
  
  [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName : [SHPalette navyBlue],
                                                         NSFontAttributeName : [UIFont fontWithName:@"Copperplate" size:20.0]
                                                         }];
  
  self.window.backgroundColor = [UIColor blackColor];
  
}

-(UIFont *)globalFontWithSize:(CGFloat)size {
  return [UIFont systemFontOfSize:size];
}

-(UIFont *)globalItalicFontWithSize:(CGFloat)size {
  return [UIFont italicSystemFontOfSize:size];
}

-(UIFont *)globalBoldFontWithSize:(CGFloat)size {
  return [UIFont boldSystemFontOfSize:size];
}

-(UIFont *)globalBoldItalicFontWithSize:(CGFloat)size {
  return [UIFont italicSystemFontOfSize:size];
}


-(void)setParseDatabase {
  NSString *pfAppID = kPFProdAppID;
  NSString *pfClientKey = kPFProdKey;
  
#ifdef kUsePFStaging
  pfAppID = kPFStagingAppID;
  pfClientKey = kPFStagingKey;
#endif
#ifdef kUsePFEmpty
  pfAppID = kPFEmptyAppID;
  pfClientKey = kPFEmptyKey;
#endif
  
  [Parse setApplicationId:pfAppID
                clientKey:pfClientKey];
  
}

-(UIImage *)scaleAndRotateImage:(UIImage *)image
{
  return [self scaleAndRotateImage:image maxResolution:kMyMaxResolution];
}

-(UIImage *)scaleAndRotateImage:(UIImage *)image maxResolution:(NSInteger)maxResolution {
  
  CGImageRef imgRef = image.CGImage;
  
  CGFloat width = CGImageGetWidth(imgRef);
  CGFloat height = CGImageGetHeight(imgRef);
  
  CGAffineTransform transform = CGAffineTransformIdentity;
  CGRect bounds = CGRectMake(0, 0, width, height);
  if (width > maxResolution || height > maxResolution) {
    CGFloat ratio = width/height;
    if (ratio > 1) {
      bounds.size.width = maxResolution;
      bounds.size.height = floor(bounds.size.width / ratio);
    } else {
      bounds.size.height = maxResolution;
      bounds.size.width = ceil(bounds.size.height * ratio);
    }
  }
  
  CGFloat scaleRatio = bounds.size.width / width;
  CGSize imageSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef));
  CGFloat boundHeight;
  UIImageOrientation orient = image.imageOrientation;
  switch(orient) {
    case UIImageOrientationUp: //EXIF = 1
      transform = CGAffineTransformIdentity;
      break;
      
    case UIImageOrientationUpMirrored: //EXIF = 2
      transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);
      transform = CGAffineTransformScale(transform, -1.0, 1.0);
      break;
      
    case UIImageOrientationDown: //EXIF = 3
      transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
      transform = CGAffineTransformRotate(transform, M_PI);
      break;
      
    case UIImageOrientationDownMirrored: //EXIF = 4
      transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);
      transform = CGAffineTransformScale(transform, 1.0, -1.0);
      break;
      
    case UIImageOrientationLeftMirrored: //EXIF = 5
      boundHeight = bounds.size.height;
      bounds.size.height = bounds.size.width;
      bounds.size.width = boundHeight;
      transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
      transform = CGAffineTransformScale(transform, -1.0, 1.0);
      transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
      break;
      
    case UIImageOrientationLeft: //EXIF = 6
      boundHeight = bounds.size.height;
      bounds.size.height = bounds.size.width;
      bounds.size.width = boundHeight;
      transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
      transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
      break;
      
    case UIImageOrientationRightMirrored: //EXIF = 7
      boundHeight = bounds.size.height;
      bounds.size.height = bounds.size.width;
      bounds.size.width = boundHeight;
      transform = CGAffineTransformMakeScale(-1.0, 1.0);
      transform = CGAffineTransformRotate(transform, M_PI / 2.0);
      break;
      
    case UIImageOrientationRight: //EXIF = 8
      boundHeight = bounds.size.height;
      bounds.size.height = bounds.size.width;
      bounds.size.width = boundHeight;
      transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
      transform = CGAffineTransformRotate(transform, M_PI / 2.0);
      break;
      
    default:
      [NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];
      
  }
  
  UIGraphicsBeginImageContext(bounds.size);
  
  CGContextRef context = UIGraphicsGetCurrentContext();
  
  if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft) {
    CGContextScaleCTM(context, -scaleRatio, scaleRatio);
    CGContextTranslateCTM(context, -height, 0);
  } else {
    CGContextScaleCTM(context, scaleRatio, -scaleRatio);
    CGContextTranslateCTM(context, 0, -height);
  }
  
  CGContextConcatCTM(context, transform);
  
  CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);
  UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  
  return imageCopy;
}


- (void)showTextController {
  [self showTextControllerAnimated:YES];
}

- (void)showTextControllerAnimated:(BOOL)animated {
  if ( [[User currentUser] hasPartner] ) {
    [self.sideBarController showViewControllerInMainDrawer:[[TextController alloc] init] animated:animated];
  } else {
    self.sharedCon.initialController = SharedControllerTypeText;
  }
}

- (void)showGoogleCalendarControllerWithSelectedDate:(NSDate *)selectedDate {
  if ( [[User currentUser] hasPartner] ) {
    GoogleCalendarContainerController *vc = [[GoogleCalendarContainerController alloc] init];
    vc.initialDate = selectedDate;
    [self.sideBarController showViewControllerInMainDrawer:vc];
  } else {
    self.sharedCon.initialController = SharedControllerTypeCalendar;
    self.sharedCon.initialCalendarDate = selectedDate;
  }
}

- (void)showListsController {
  if ( [[User currentUser] hasPartner] ) {
    [self.sideBarController showViewControllerInMainDrawer:[[ListsController alloc] init]];
  } else {
    self.sharedCon.initialController = SharedControllerTypeList;
  }
}

- (void)showGoogleDriveController {
  if ( [[User currentUser] hasPartner] ) {
    [self.sideBarController showViewControllerInMainDrawer:[[DriveFilesListController alloc] initWithFolderID:nil andFolderName:nil]];
  } else {
    self.sharedCon.initialController = SharedControllerTypeDrive;
  }
}

- (void)showSettingsController {
  if ( [[User currentUser] hasPartner] ) {
    [self.sideBarController showViewControllerInMainDrawer:[[SettingsController alloc] init]];
  } else {
    self.sharedCon.initialController = SharedControllerTypeSettings;
  }
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString*, id> *)options {
  if ( [url.scheme isEqualToString:@"shared-app"] ) {
    if ( [url.resourceSpecifier isEqualToString:@"//text"] ) {
      [self showTextControllerAnimated:NO];
    }
    return YES;
  }
  return NO;
}

- (UIViewController *)viewControllerForPresentation {
  UIViewController *vc = self.navController.topViewController;
  while ( vc.presentedViewController && ![vc.presentedViewController isKindOfClass:[UIAlertController class]] ) {
    vc = vc.presentedViewController;
  }
  return vc;
}

@end
