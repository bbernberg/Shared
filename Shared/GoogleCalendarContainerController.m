//
//  GoogleCalendarController.m
//  Shared
//
//  Created by Brian Bernberg on 1/22/13.
//  Copyright (c) 2013 BB Consulting. All rights reserved.
//


#import "GoogleCalendarContainerController.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "GTLCalendar.h"
#import "Constants.h"
#import "CalendarService.h"
#import "PSPDFAlertView.h"
#import "CalendarEventController.h"
#import "UIButton+myButton.h"
#import <QuartzCore/QuartzCore.h>
#import "CalendarEventEditController.h"
#import "NSString+SHString.h"
#import "GoogleLoginController.h"
#import "SHUtil.h"
#import "NotificationRetriever.h"
#import "SharedActivityIndicator.h"
#import <MMDrawerController/MMDrawerBarButtonItem.h>
#import <MMDrawerController/UIViewController+MMDrawerController.h>
#import "GoogleEmailViewController.h"
#import "CalendarViewController.h"
#import "CalendarCreateViewController.h"

@interface GoogleCalendarContainerController () <UITableViewDelegate, GoogleEmailViewControllerDelegate, UITextFieldDelegate, CalendarCreateDelegate>

@property (nonatomic, weak, readonly) GTLServiceCalendar *gtlCalendarService;
@property (nonatomic, readonly) PFObject *calendarInfo;
@property (nonatomic, strong) NSMutableArray *displayedEvents;
@property (nonatomic, strong) NSDate *lastFetchTime;
@property (nonatomic, strong) NSMutableDictionary *recurringEvents;
@property (nonatomic, strong) UIView *loadingView;
@property (nonatomic, strong) UIView *tryAgainView;
@property (nonatomic, strong) UIView *introBackground;
@property (nonatomic, strong) PSPDFAlertView *alert;
@property (nonatomic, assign) BOOL shouldShowAuth;
@property (nonatomic) BOOL loadingShown;
@property (nonatomic) CalendarViewController *calendarViewController;
@property (nonatomic) SHNavigationController *modalNav;
@property (nonatomic) BOOL deletedErrorShown;
@end

@implementation GoogleCalendarContainerController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    // Custom initialization
    self.displayedEvents = [NSMutableArray array];
    self.recurringEvents = [NSMutableDictionary dictionary];
    self.shouldShowAuth = NO;
    self.deletedErrorShown = NO;
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  [[NSUserDefaults standardUserDefaults] setObject:@(SharedControllerTypeCalendar) forKey:kCurrentSharedControllerType];
  [[NSUserDefaults standardUserDefaults] synchronize];

  self.view.backgroundColor = [SHPalette backgroundColor];
  self.navigationItem.title = @"Calendar";
  
  // left button
  self.navigationItem.leftBarButtonItem = [[MMDrawerBarButtonItem alloc] initWithTarget:self action:@selector(drawerButtonPressed)];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(handleSharedCalendarDeletion)
                                               name:kSharedGoogleCalendarDeleted
                                             object:nil];
  
  
  NSString *key = [NSString stringWithFormat:@"%@%@", kGoogleCalendarIntroShownKey, [User currentUser].myUserID];
  if ( ! [[NSUserDefaults standardUserDefaults] stringForKey:key] ) {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.navigationController setNavigationBarHidden: YES];
    [self showIntro];
  } else {
    [self hideIntroWithDuration:0.0];
    [self kickoffFromViewDidLoad:YES];
  }
  
}

-(void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  if ([self.loadingView superview]) {
    CGRect frame = self.loadingView.frame;
    frame.origin.y = (self.view.frame.size.height - self.loadingView.frame.size.height) / 2.0;
    self.loadingView.frame = frame;
  }
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  if ( ! self.loadingShown && ! self.introBackground.superview ) {
    self.loadingShown = YES;
    [self showLoading];
  }
}

-(void)kickoffFromViewDidLoad:(BOOL)fromViewDidLoad {
  [self.navigationController setNavigationBarHidden: NO];
  
  // Check for authorization.
  GTMOAuth2Authentication *auth = [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:kGoogleCalendarKeychainItemName
                                                                                        clientID:kGoogleClientID
                                                                                    clientSecret:kGoogleClientSecret];
  if ([auth canAuthorize]) {
    [self isAuthorizedWithAuthentication:auth];
  } else {
    if (fromViewDidLoad) {
      self.shouldShowAuth = YES;
    } else {
      [self showAuth];
    }
  }
  
}

-(void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  
  if (self.shouldShowAuth) {
    self.shouldShowAuth = NO;
    [self showAuth];
  }
  
}

-(void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)drawerButtonPressed {
  [self.view endEditing:YES];
  [[self mm_drawerController] toggleDrawerSide:MMDrawerSideLeft animated:YES completion:NULL];
}

#pragma mark getters/setters
- (PFObject *)calendarInfo {
  return [CalendarService sharedInstance].info;
}

#pragma mark authorization
-(void)showAuth {
  SEL finishedSelector = @selector(viewController:finishedWithAuth:error:);
  GoogleLoginController *vc =[[GoogleLoginController alloc] initWithScope:kGTLAuthScopeCalendar
                                                                 clientID:kGoogleClientID
                                                             clientSecret:kGoogleClientSecret
                                                         keychainItemName:kGoogleCalendarKeychainItemName
                                                                 delegate:self
                                                         finishedSelector:finishedSelector];
  vc.cancelBlock = ^{
    [self removeLoading];
    [self showTryAgainView];
  };
  
  SHNavigationController *nav = [[SHNavigationController alloc] initWithRootViewController:vc];
  [self presentViewController:nav animated: YES completion:NULL];
  
}

#pragma mark auth methods
- (void)isAuthorizedWithAuthentication:(GTMOAuth2Authentication *)auth {
  [self.gtlCalendarService setAuthorizer:auth];
  
  if ( ! [[User currentUser].myGoogleCalendarUserEmail isEqualToInsensitive:auth.userEmail] ) {
    [User currentUser].myGoogleCalendarUserEmail = [auth.userEmail lowercaseString];
    [[User currentUser] saveToNetwork];
  }
  
  if ([[CalendarService sharedInstance] isAvailable]) {
    [[CalendarService sharedInstance] fetchCalendarInfo];
    
    if ([CalendarService sharedInstance].calendarIsShared == NO) {
      if ( [CalendarService sharedInstance].isCalendarOwner ) {
        [self addPermission];
        [self presentCalendarView];
      } else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                       message:@"Your partner has not successfully shared the calendar yet. Please ask them to log in to Google Calendar through Shared."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [self presentViewController:alert
                           animated:YES
                         completion:nil];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
          [kAppDelegate showTextController];
        });
      }
      
    } else {
      [self presentCalendarView];
    }
  } else {
    [self getCalendarInfo];
  }
}

- (void)viewController:(GoogleLoginController *)viewController
      finishedWithAuth:(GTMOAuth2Authentication *)auth
                 error:(NSError *)error {
  if (error == nil) {
    [self isAuthorizedWithAuthentication:auth];
  } else {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                   message:@"There was a problem logging in to Google. Please try later."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [self presentViewController:alert
                       animated:YES
                     completion:nil];
    
    [self removeLoading];
    [self showTryAgainView];
  }
}

- (GTLServiceCalendar *)gtlCalendarService {
  return [CalendarService sharedInstance].gtlCalendarService;
}

#pragma mark calendar creation
-(void)createCalendar {
  UIViewController *vc = [[CalendarCreateViewController alloc] initWithDelegate:self];
  self.modalNav = [[SHNavigationController alloc] initWithRootViewController:vc];
  [self presentViewController:self.modalNav animated:YES completion:nil];
}

#pragma mark CalendarCreateDelegate
- (void)calendarCreateControllerDidCancelWithError:(BOOL)withError {
  if ( withError ) {
    [self dismissViewControllerAnimated:YES completion:^{
      UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                     message:@"There was a problem creating your Google Calendar.  Please try later."
                                                              preferredStyle:UIAlertControllerStyleAlert];
      [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                style:UIAlertActionStyleDefault
                                              handler:^(UIAlertAction * _Nonnull action) {
                                                [kAppDelegate showTextControllerAnimated:YES];
                                              }]];
      [self presentViewController:alert
                         animated:YES
                       completion:nil];
    }];
  } else {
    [self dismissViewControllerAnimated:YES completion:nil];
    [kAppDelegate showTextControllerAnimated:NO];
  }
}

- (void)calendarCreatedNeedsPartnerEmail:(BOOL)needsPartnerEmail {
  if ( needsPartnerEmail ) {
    GoogleEmailViewController *vc = [[GoogleEmailViewController alloc] initWithDelegate:self mode:GoogleEmailModeCalendarPartner];
    [self.modalNav setViewControllers:@[vc] animated:YES];
  } else {
    [self dismissViewControllerAnimated:YES completion:nil];
    [self presentCalendarView];
  }
}

#pragma mark GoogleEmailViewControllerDelegate
- (void)controllerDidChooseEmail:(NSString *)email controller:(GoogleEmailViewController *)controller {
  [self dismissViewControllerAnimated:YES completion:nil];
  
  [User currentUser].partnerGoogleCalendarUserEmail = [email lowercaseString];
  [[User currentUser] saveToNetwork];
  
  self.calendarInfo[kGoogleCalendarPartnerIDKey] = [User currentUser].partnerUserID;
  self.calendarInfo[kGoogleCalendarPartnerUserEmailKey] = [email lowercaseString];
  
  [[CalendarService sharedInstance] addPermissionForEmail:[email lowercaseString]];
  
  [self presentCalendarView];
}

- (void)controllerDidCancel:(GoogleEmailViewController *)controller {
  [self dismissViewControllerAnimated:YES completion:nil];
  [kAppDelegate showTextController];
}


#pragma mark add partner permission
-(void)addPermission {
  if ( ! [User currentUser].partnerGoogleCalendarUserEmail ||
      [User currentUser].partnerGoogleCalendarUserEmail.length == 0 ) {
    GoogleEmailViewController *vc = [[GoogleEmailViewController alloc] initWithDelegate:self mode:GoogleEmailModeCalendarPartner];
    self.modalNav = [[SHNavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:self.modalNav animated:YES completion:NULL];
  } else {
    [[CalendarService sharedInstance] addPermissionForEmail:[User currentUser].partnerGoogleCalendarUserEmail];
  }
}

#pragma mark get calendar info (if available)
-(void)getCalendarInfo {
  // Query Parse to determine if calendar is created
  PFQuery *query = [PFQuery queryForCurrentUsersWithClassName:kGoogleCalendarClass];
  
  [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
    if (!error) {
      if (objects.count == 0) {
        [self createCalendar];
      } else {
        [CalendarService sharedInstance].info = [objects firstObject];
        if ( [CalendarService sharedInstance].isCalendarOwner ) {
          NSString *ownerEmail = self.calendarInfo[kGoogleCalendarOwnerUserEmailKey];
          if ( ! [ownerEmail isEqualToInsensitive:[self.gtlCalendarService.authorizer userEmail]] ) {
            [self handleIncorrectUserEmail: ownerEmail];
            return;
          }
        } else {
          if ( ! [[User currentUser].partnerGoogleCalendarUserEmail isEqualToInsensitive:self.calendarInfo[kGoogleCalendarOwnerUserEmailKey]] ) {
            [User currentUser].partnerGoogleCalendarUserEmail = self.calendarInfo[kGoogleCalendarOwnerUserEmailKey];
            [[User currentUser] saveToNetwork];
          }
          NSString *userEmail = self.calendarInfo[kGoogleCalendarPartnerUserEmailKey];
          if ( ! [userEmail isEqualToInsensitive:[self.gtlCalendarService.authorizer userEmail]] ) {
            [self handleIncorrectUserEmail:userEmail];
            return;
          }
          
        }
        
        // Check if calendar has been successfully shared
        if ([CalendarService sharedInstance].calendarIsShared == NO) {
          if ([CalendarService sharedInstance].isCalendarOwner) {
            [self addPermission];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
              [self presentCalendarView];
            });
          } else {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                           message:@"Your partner has not successfully shared the calendar yet. Please ask them to log in to Google Calendar through Shared."
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                      style:UIAlertActionStyleCancel
                                                    handler:nil]];
            [self presentViewController:alert
                               animated:YES
                             completion:nil];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kPopToMainNotification object:self];
          }
        } else {
          // Everything is set up
          dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self presentCalendarView];
          });
        }
        // Delete extra calendars (which shouldn't happen)
        if (objects.count > 1) {
          NSRange extraRange;
          extraRange.location = 1;
          extraRange.length = objects.count - 1;
          NSArray *extraCalendars = [objects subarrayWithRange:extraRange];
          [PFObject deleteAllInBackground:extraCalendars];
        }
      }
    } else {
      UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                     message:@"Error retrieving Google Calendar. Please try later."
                                                              preferredStyle:UIAlertControllerStyleAlert];
      [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                style:UIAlertActionStyleCancel
                                              handler:nil]];
      [self presentViewController:alert
                         animated:YES
                       completion:nil];
      
      [kAppDelegate showTextController];
    }
  }];
  
}

#pragma mark incorrect user e-mail
-(void)handleIncorrectUserEmail:(NSString *)correctUserEmail {
  
  PSPDFAlertView *alert = [[PSPDFAlertView alloc] initWithTitle:@"Incorrect User" message:[NSString stringWithFormat:@"You are logged in to Google as the incorrect user.  Please log in as %@", correctUserEmail]];
  
  [alert addButtonWithTitle:@"OK" block:^(NSInteger buttonIndex) {
    // perform logout
    [GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName:kGoogleCalendarKeychainItemName];
    [self.gtlCalendarService setAuthorizer:nil];
    [User currentUser].myGoogleCalendarUserEmail = nil;
    [[User currentUser] saveToNetwork];
    
    // log in
    SEL finishedSelector = @selector(viewController:finishedWithAuth:error:);
    GoogleLoginController *vc = [[GoogleLoginController alloc] initWithScope:kGTLAuthScopeCalendar
                                                                    clientID:kGoogleClientID
                                                                clientSecret:kGoogleClientSecret
                                                            keychainItemName:kGoogleCalendarKeychainItemName
                                                                    delegate:self
                                                            finishedSelector:finishedSelector];
    vc.cancelBlock = ^{
      [self removeLoading];
      [self showTryAgainView];
    };

    SHNavigationController *nav = [[SHNavigationController alloc] initWithRootViewController:vc];
    [self presentViewController: nav animated: YES completion:NULL];
  }];
  
  if ([CalendarService sharedInstance].isCalendarOwner) {
    [alert addButtonWithTitle:@"New Calendar" block:^(NSInteger buttonIndex) {
      [self createCalendar];
    }];
  }
  
  [alert show];
}

#pragma mark present calendar monthly view
-(void)presentCalendarView {
  self.loadingShown = YES;
  [self removeLoading];
  [self removeTryAgainView];
  
  self.calendarViewController = [[CalendarViewController alloc] initWithNibName:nil bundle:nil];
  self.calendarViewController.dateSelected = self.initialDate;
  [self addChildViewController:self.calendarViewController];
  self.calendarViewController.view.frame = self.view.bounds;
  [self.view addSubview:self.calendarViewController.view];
  [self.calendarViewController didMoveToParentViewController:self];

  self.navigationItem.rightBarButtonItem =  [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemAdd
                                             
                                                                                          target: self
                                                                                          action: @selector(addButtonPressed)];
  
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    [[NotificationRetriever instance] deleteNotificationsOfType:kGoogleCalendarNotification];
  });
  
}

#pragma mark utility functions

-(void)handleSharedCalendarDeletion {
  if ( ! self.deletedErrorShown ) {
    self.deletedErrorShown = YES;
    NSString *alertMessage = [CalendarService sharedInstance].isCalendarOwner ?
    @"Unable to retreive your shared Google Calendar.  If the problem persists, you can reset your Google Calendar in the the Settings menu." :
    @"Unable to retreive your shared Google Calendar.  If the problem persists, your partner can reset your Google Calendar in the the Settings menu.";
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:alertMessage
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [self presentViewController:alert
                       animated:YES
                     completion:nil];
        
    [kAppDelegate showTextController];
  }
  
}


#pragma mark loading functions
-(void)showLoading {
  
  if ( ! self.loadingView ) {
    self.loadingView = [[UIView alloc] initWithFrame:CGRectMake(0.f,
                                                                self.view.frameSizeHeight/2.0-25.0,
                                                                self.view.frameSizeWidth,
                                                                50.0)];
    UILabel *label = [[UILabel alloc] init];
    label.text = @"Loading...";
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor darkGrayColor];
    label.font = [UIFont fontWithName:@"Copperplate-Bold" size:20.0];
    [label sizeToFit];
    label.center = CGPointMake(CGRectGetMidX(self.loadingView.bounds), CGRectGetMidY(self.loadingView.bounds));
    [self.loadingView addSubview:label];
    
    SharedActivityIndicator *spinner = [[SharedActivityIndicator alloc] initWithImage:[UIImage imageNamed:@"Shared_Icon_Gray_Transparent"]];
    spinner.center = CGPointMake(label.frameOriginX - spinner.frameSizeWidth, label.center.y);
    [spinner startAnimating];
    [self.loadingView addSubview: spinner];
  }
  
  [self.view addSubview:self.loadingView];
  
}

-(void)removeLoading {
  [self.loadingView removeFromSuperview];
}


- (void)showTryAgainView {
  if ( ! self.tryAgainView ) {
    self.tryAgainView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.tryAgainView.backgroundColor = [UIColor clearColor];
    
    UILabel *label = [[UILabel alloc] init];
    label.text = @"Unable to log in to Google.";
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor darkGrayColor];
    label.font = [kAppDelegate globalFontWithSize:20.f];
    [label sizeToFit];
    label.center = CGPointMake(CGRectGetMidX(self.tryAgainView.bounds), CGRectGetMidY(self.tryAgainView.bounds) - label.frameSizeHeight);
    [self.tryAgainView addSubview:label];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(20, label.frameOriginY + label.frameSizeHeight + 20.f, self.tryAgainView.frameSizeWidth - 40.f, 44);
    button.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    button.backgroundColor = [UIColor darkGrayColor];
    button.titleLabel.font = [UIFont fontWithName:@"CopperPlate" size:20.0];
    [button setTitle:@"Try Again" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(tryAgainButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [button setBackgroundImage:[UIImage imageNamed:@"GrayBackground"] forState:UIControlStateHighlighted];
    [self.tryAgainView addSubview:button];
  }
  [self.view addSubview:self.tryAgainView];
}

- (void)removeTryAgainView {
  [self.tryAgainView removeFromSuperview];
}

- (void)tryAgainButtonTapped:(UIButton *)button {
  [self showAuth];
}

-(void)addButtonPressed {
  CalendarEventEditController *vc = [[CalendarEventEditController alloc] initWithEvent:nil
                                                                                  date:self.calendarViewController.dateSelected];
  SHNavigationController *nav = [[SHNavigationController alloc] initWithRootViewController:vc];
  [self presentViewController:nav
                     animated:YES
                   completion:nil];
}

#pragma mark intro functions
-(void)showIntro {
  CGRect screenSize = [[UIScreen mainScreen] bounds];
  self.introBackground = [[UIView alloc] initWithFrame:self.view.frame];
  self.introBackground.backgroundColor = [UIColor whiteColor];
  self.introBackground.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
  
  UILabel* label = [[UILabel alloc] init];
  label.frame = CGRectMake(20.f, roundf(screenSize.size.height * 0.24), screenSize.size.width - 40.f, 200.f);
  label.numberOfLines = 0;
  label.lineBreakMode = NSLineBreakByWordWrapping;
  label.textAlignment = NSTextAlignmentCenter;
  label.font = [kAppDelegate globalFontWithSize:20.0];
  label.textColor = [UIColor darkGrayColor];
  label.backgroundColor = [UIColor clearColor];
  label.text = @"Shared creates a shared Google Calendar for you and your partner to coordinate your schedules.";
  [self.introBackground addSubview:label];
  
  UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
  button.frame = CGRectMake(20, roundf(screenSize.size.height * 0.68), screenSize.size.width - 40.f, 44);
  button.backgroundColor = [UIColor colorWithRed: (51.0/255.0) green: (102.0/255.0) blue: (153.0/255.0) alpha:1.0];
  [button setTitle:@"OK" forState:UIControlStateNormal];
  button.titleLabel.font = [UIFont fontWithName:@"Copperplate-Bold" size:22.0];
  [button setBackgroundImage:[UIImage imageNamed:@"GrayBackground"] forState:UIControlStateHighlighted];
  [button addTarget:self action:@selector(introOKButtonPressed) forControlEvents:UIControlEventTouchUpInside];
  [self.introBackground addSubview:button];
  
  [self.view addSubview:self.introBackground];
}

-(void)introOKButtonPressed {
  [self hideIntroWithDuration:0.2];
  [self kickoffFromViewDidLoad:NO];
}

-(void)hideIntroWithDuration:(CGFloat)animateDuration {
  [UIView animateWithDuration:animateDuration
                   animations:^{
                     self.introBackground.alpha = 0.0;
                   }];
  
}

@end
