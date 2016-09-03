//
//  AccountDetailController.m
//  Shared
//
//  Created by Brian Bernberg on 3/10/13.
//  Copyright (c) 2013 BB Consulting. All rights reserved.
//

#import "AccountDetailController.h"
#import "Constants.h"
#import "GTLDrive.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "ChoosePartnerController.h"
#import "PSPDFAlertView.h"
#import "PartnerStatusController.h"
#import "SharedController.h"
#import "GoogleEmailViewController.h"

@interface AccountDetailController () <ControllerExiting, GoogleEmailViewControllerDelegate>
@property (nonatomic, assign) AccountType accountType;
@end

@implementation AccountDetailController

- (id)initWithAccountType:(AccountType)accountType
{
  self = [super initWithStyle:UITableViewStyleGrouped];
  if (self) {
    // Custom initialization
    self.accountType = accountType;
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.tableView.backgroundView = nil;
  self.tableView.backgroundColor = [SHPalette backgroundColor];
  self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
  self.tableView.allowsSelectionDuringEditing = TRUE;
  
  switch (self.accountType) {
    case kMyFacebookAccount:
      self.navigationItem.title = @"Facebook";
      break;
    case kPartnerAccount:
      self.navigationItem.title = @"Partner";
      
      [self getPartnerAccountStatus];
      break;
    case kMyGoogleDriveAccount:
    case kPartnerGoogleDriveAccount:
      self.navigationItem.title = @"Google Drive";
      break;
    case kMyGoogleCalendarAccount:
    case kPartnerGoogleCalendarAccount:
      self.navigationItem.title = @"Google Calendar";
      break;
    default:
      break;
  }
  
}

-(void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self.tableView reloadData];
  if ( self.accountType == kPartnerAccount ) {
    // Show header view with profile picture if it exists
    if ([User currentUser].partnerPictureExists) {
      UIView* header = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, self.view.frame.size.width, 120.f)];
      header.backgroundColor = [UIColor clearColor];
      UIImageView* partnerPicture = [[UIImageView alloc] initWithImage:[User currentUser].partnerPicture];
      partnerPicture.frame = CGRectMake((self.view.frame.size.width - 100.f) / 2.f,
                                        20.f,
                                        100.f,
                                        100.f);
      partnerPicture.contentMode = UIViewContentModeScaleAspectFill;
      partnerPicture.clipsToBounds = YES;
      [header addSubview: partnerPicture];
      self.tableView.tableHeaderView = header;
    } else {
      self.tableView.tableHeaderView = nil;
    }
    
  }
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  switch (self.accountType) {
    case kMyFacebookAccount:
    case kMyGoogleDriveAccount:
    case kPartnerGoogleDriveAccount:
    case kMyGoogleCalendarAccount:
    case kPartnerGoogleCalendarAccount:
      return 1;
      break;
      
    case kPartnerAccount:
      return 2;
      break;
    default:
      return 1;
      break;
  }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *CellIdentifier = @"Cell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if ( !cell ) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    cell.textLabel.font = [kAppDelegate globalBoldFontWithSize:18.0];
    cell.textLabel.textColor = [UIColor blackColor];
    cell.detailTextLabel.font = [kAppDelegate globalFontWithSize:18.0];
    cell.detailTextLabel.textColor = [UIColor blackColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
    cell.detailTextLabel.minimumScaleFactor = 0.7;
  }
  
  cell.accessoryView = nil;
  cell.accessoryType = UITableViewCellAccessoryNone;
  
  switch (self.accountType) {
    case kMyFacebookAccount:
      cell.textLabel.text = @"Account";
      cell.detailTextLabel.text = [User currentUser].myFBName;
      break;
    case kPartnerAccount:
      if (indexPath.row == 0) {
        cell.textLabel.text = @"Partner";
        if ([User currentUser].partnerUserEmail) {
          cell.detailTextLabel.text = [User currentUser].partnerUserEmail;
        } else {
          cell.detailTextLabel.text = [User currentUser].partnerName;
        }
      } else {
        cell.textLabel.text = @"Account Status";
        if ([[NSUserDefaults standardUserDefaults] stringForKey:kPartnerStatusKey]) {
          cell.detailTextLabel.text = [[NSUserDefaults standardUserDefaults] stringForKey:kPartnerStatusKey];
        } else {
          cell.detailTextLabel.text = @"Loading...";
        }
      }
      break;
    case kMyGoogleDriveAccount:
      cell.textLabel.text = @"Account";
      cell.detailTextLabel.text = [User currentUser].myGoogleDriveUserEmail;
      break;
    case kPartnerGoogleDriveAccount:
      cell.textLabel.text = @"Partner";
      cell.detailTextLabel.text = [User currentUser].partnerGoogleDriveUserEmail;
      break;
    case kMyGoogleCalendarAccount:
      cell.textLabel.text = @"Account";
      cell.detailTextLabel.text = [User currentUser].myGoogleCalendarUserEmail;
      break;
    case kPartnerGoogleCalendarAccount:
      cell.textLabel.text = @"Partner:";
      cell.detailTextLabel.text = [User currentUser].partnerGoogleCalendarUserEmail;
      break;
    default:
      break;
  }
  return cell;
}

-(UIView *)tableView:(UITableView *)theTableView viewForFooterInSection:(NSInteger)section {
  switch (self.accountType) {
    case kPartnerAccount: {
      return [self footerForTitle:@"Choose New Partner"
                        andAction:@selector(chooseNewPartner)];
    } break;
    case kMyGoogleDriveAccount: {
      return [self footerForTitle:@"Unlink Account"
                        andAction:@selector(unlinkGoogleDrive)];
      
    } break;
    case kPartnerGoogleDriveAccount: {
      if ([[User currentUser].myUserIDs containsObject:[User currentUser].googleDriveFolderOwner] ||
          ![User currentUser].googleDriveFolderOwner) {
        return [self footerForTitle:@"Choose New E-mail Address"
                          andAction:@selector(chooseGoogleDrivePartnerEmail)];
      } else {
        return [UIView new];
      }
      
    } break;
    case kMyGoogleCalendarAccount: {
      return [self footerForTitle:@"Unlink Account"
                        andAction:@selector(unlinkGoogleCalendar)];
      
    } break;
    case kPartnerGoogleCalendarAccount: {
      if ([[User currentUser].myUserIDs containsObject:[User currentUser].googleCalendarOwner] ||
          ![User currentUser].googleCalendarOwner) {
        return [self footerForTitle:@"Choose New E-mail Address"
                          andAction:@selector(chooseGoogleCalendarPartnerEmail)];
      } else {
        return [UIView new];
      }
    } break;
    default:
      return [UIView new];
      break;
  }
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  return 30;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
  switch (self.accountType) {
    case kPartnerAccount:
    case kMyGoogleDriveAccount:
    case kMyGoogleCalendarAccount:
      return 100;
      break;
    case kPartnerGoogleDriveAccount:
      if ([[User currentUser].myUserIDs containsObject:[User currentUser].googleDriveFolderOwner] ||
          ![User currentUser].googleDriveFolderOwner) {
        return 100;
      } else {
        return 1;
      }
      break;
    case kPartnerGoogleCalendarAccount:
      if ([[User currentUser].myUserIDs containsObject:[User currentUser].googleCalendarOwner] ||
          ![User currentUser].googleCalendarOwner) {
        return 100;
      } else {
        return 1;
      }
      break;
    default:
      return 1.0;
      break;
  }
}


#pragma mark - Table view delegate

#pragma mark choose new partner
-(void)chooseNewPartner {
  // Choose new partner?
  PSPDFAlertView *alert = [[PSPDFAlertView alloc] initWithTitle:nil message:@"Would you like to choose a new partner?"];
  [alert addButtonWithTitle:@"Yes" block:^(NSInteger buttonIndex) {
    ChoosePartnerController *vc = [[ChoosePartnerController alloc] initWithCompletionBlock:^{
      PartnerStatusController *con = [[PartnerStatusController alloc] initWithDelegate:self];
      [self presentViewController:con animated:NO completion:NULL];
      double delayInSeconds = 0.6;
      dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
      dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self.navigationController popToViewController:self animated:YES];
      });
    } useCancelButton:YES];
    [self.navigationController pushViewController:vc animated:YES];
  }];
  [alert addButtonWithTitle:@"No" block:nil];
  [alert show];
}

#pragma mark Unlink Google Drive
-(void)unlinkGoogleDrive {
  // logout?
  PSPDFAlertView *alert = [[PSPDFAlertView alloc] initWithTitle:nil message:@"Would you like to unlink your Google Drive account?"];
  [alert addButtonWithTitle:@"Yes" block:^(NSInteger buttonIndex) {
    // perform logout
    [GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName:kGoogleDriveKeychainItemName];
    [User currentUser].myGoogleDriveUserEmail = nil;
    [[User currentUser] saveToNetwork];
    
    [self.navigationController popViewControllerAnimated: YES];
  }];
  [alert addButtonWithTitle:@"No" block:nil];
  [alert show];
  
}

#pragma mark Unlink Google Drive
-(void)unlinkGoogleCalendar {
  // logout?
  PSPDFAlertView *alert = [[PSPDFAlertView alloc] initWithTitle:nil message:@"Would you like to unlink your Google Calendar account?"];
  [alert addButtonWithTitle:@"Yes" block:^(NSInteger buttonIndex) {
    // perform logout
    [GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName:kGoogleCalendarKeychainItemName];
    [User currentUser].myGoogleCalendarUserEmail = nil;
    [[User currentUser] saveToNetwork];
    
    [self.navigationController popViewControllerAnimated: YES];
  }];
  [alert addButtonWithTitle:@"No" block:nil];
  [alert show];
  
}

-(UIView *)footerForTitle:(NSString *)title andAction:(SEL)action {
  UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 100.0)];
  footer.backgroundColor = [UIColor clearColor];
  
  UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
  button.frame = CGRectMake(10, 20, footer.frameSizeWidth - 20.f, 44);
  button.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  button.backgroundColor = [UIColor colorWithRed:183.0/255.0
                                           green:62.0/255.0
                                            blue:62.0/255.0
                                           alpha:1.0];
  button.titleLabel.font = [UIFont fontWithName:@"CopperPlate" size:20.0];
  [button setTitle:title forState:UIControlStateNormal];
  [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
  [button setBackgroundImage:[UIImage imageNamed:@"GrayBackground"] forState:UIControlStateHighlighted];
  
  [footer addSubview:button];
  
  return footer;
}

#pragma mark Google Drive partner contact
-(void)chooseGoogleDrivePartnerEmail {
  GoogleEmailViewController *vc = [[GoogleEmailViewController alloc] initWithDelegate:self mode:GoogleEmailModeDrivePartner];
  SHNavigationController* nav = [[SHNavigationController alloc] initWithRootViewController:vc];
  [self presentViewController:nav animated:YES completion:NULL];
}

#pragma mark Google Calendar partner contact
-(void)chooseGoogleCalendarPartnerEmail {
  GoogleEmailViewController *vc = [[GoogleEmailViewController alloc] initWithDelegate:self mode:GoogleEmailModeCalendarPartner];
  SHNavigationController* nav = [[SHNavigationController alloc] initWithRootViewController:vc];
  [self presentViewController:nav animated:YES completion:NULL];
}

#pragma mark GoogleEmailViewControllerDelegate methods
- (void)controllerDidChooseEmail:(NSString *)email controller:(GoogleEmailViewController *)controller {
  if ( controller.mode == GoogleEmailModeCalendarPartner ) {
    [User currentUser].partnerGoogleCalendarUserEmail = [email lowercaseString];
  } else if ( controller.mode == GoogleEmailModeDrivePartner ) {
    [User currentUser].partnerGoogleDriveUserEmail = [email lowercaseString];
  }
  
  [[User currentUser] saveToNetwork];
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)controllerDidCancel:(GoogleEmailViewController *)controller {
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark Contacts List delegate methods
- (void)didChooseContact:(NSDictionary *)theContact {
  [self dismissViewControllerAnimated:YES completion:NULL];
  if (self.accountType == kPartnerGoogleDriveAccount) {
    if ( ! [[User currentUser].partnerGoogleDriveUserEmail isEqualToInsensitive:theContact[kContactEntryKey]] ) {
      [User currentUser].partnerGoogleDriveUserEmail = [theContact[kContactEntryKey] lowercaseString];
      [[User currentUser] saveToNetwork];
    }
  } else if (self.accountType == kPartnerGoogleCalendarAccount) {
    if ( ! [[User currentUser].partnerGoogleCalendarUserEmail isEqualToInsensitive:theContact[kContactEntryKey]] ) {
      [User currentUser].partnerGoogleCalendarUserEmail = [theContact[kContactEntryKey] lowercaseString];
      [[User currentUser] saveToNetwork];
    }
  }
}

- (void)didCancel {
  [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark partner account status
-(void)getPartnerAccountStatus {
  NSDate *statusDate = [[NSUserDefaults standardUserDefaults] objectForKey:kPartnerStatusDateKey];
  
  if ( ! [[NSUserDefaults standardUserDefaults] stringForKey:kPartnerStatusKey] ||
      ! statusDate ||
      ( [[NSDate date] timeIntervalSinceDate:statusDate] > (60.0 * 15.0) ) ) {
    
    PFQuery *query = [PFQuery queryWithClassName:kUserInfoClass];
    if ([[User currentUser] partnerIsFBLogin]) {
      [query whereKey:kMyFBIDKey equalTo:[User currentUser].partnerFBID];
    } else {
      [query whereKey:kMyUserEmailKey equalTo:[User currentUser].partnerUserEmail];
    }
    [query countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
      if (!error) {
        if (number > 0) {
          [[NSUserDefaults standardUserDefaults] setObject:@"Active" forKey:kPartnerStatusKey];
        } else {
          [[NSUserDefaults standardUserDefaults] setObject:@"Not signed up" forKey:kPartnerStatusKey];
        }
      } else {
        [[NSUserDefaults standardUserDefaults] setObject:@"Unknown" forKey:kPartnerStatusKey];
      }
      [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:kPartnerStatusDateKey];
      [[NSUserDefaults standardUserDefaults] synchronize];
      [self.tableView reloadData];
    }];
  }
}

#pragma mark ControllerExiting
- (void)controllerRequestsDismissal:(UIViewController *)controller {
  if ( [controller isKindOfClass:[PartnerStatusController class]] ) {
    [controller dismissViewControllerAnimated:YES completion:nil];
  }
}

@end
