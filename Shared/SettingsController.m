//
//  SettingsViewController.m
//  Shared
//
//  Created by Brian Bernberg on 6/13/12.
//  Copyright (c) 2012 BB Consulting. All rights reserved.
//

#import "SettingsController.h"
#import "Constants.h"
#import "LogInController.h"
#import "AboutController.h"
#import "PSPDFAlertView.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "ProfileController.h"
#import "AccountDetailController.h"
#import "GoogleLoginController.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "GTLCalendar.h"
#import "GTLDrive.h"
#import "GenericWebViewController.h"
#import "Parse/Parse.h"
#import "SHUtil.h"
#import "LTHPasscodeViewController.h"
#import <MMDrawerController/MMDrawerBarButtonItem.h>
#import <MMDrawerController/UIViewController+MMDrawerController.h>
#import "GoogleEmailViewController.h"
#import "SVProgressHud.h"
#import "CalendarService.h"
#import "DriveService.h"
#import "NSString+PhoneNumberFormatting.h"

#define kHeaderHeight 30
#define kPhoneNumberFieldTag 1000
#define kFaceTimeFieldTag 1001

enum {kMyAccountGroup = 0, kPartnerAccountGroup, kSecurityGroup, kGoogleDriveGroup, kGoogleCalendarGroup, kGeneralGroup, kNumSettingsGroups};

enum {kAccountProfileCell=0, kAccountLogOutCell, kAccountPartnerCell, kAccountPartnerFBCell};

@interface SettingsController () <GoogleEmailViewControllerDelegate, UITextFieldDelegate>

@end

@implementation SettingsController

- (id)initWithStyle:(UITableViewStyle)style
{
  self = [super initWithStyle:UITableViewStyleGrouped];
  if (self) {
    self.title = @"Settings";
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  [[NSUserDefaults standardUserDefaults] setObject:@(SharedControllerTypeSettings) forKey:kCurrentSharedControllerType];
  [[NSUserDefaults standardUserDefaults] synchronize];

  // left button
  self.navigationItem.leftBarButtonItem = [[MMDrawerBarButtonItem alloc] initWithTarget:self action:@selector(drawerButtonPressed)];
  
  
  // Custom initialization
  self.tableView.backgroundView = nil;
  self.tableView.backgroundColor = [SHPalette backgroundColor];
  self.tableView.opaque = YES;
  self.tableView.backgroundView = nil;
  self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
  
}

-(void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self.tableView reloadData];
  
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)drawerButtonPressed {
  [self.view endEditing:YES];
  [[self mm_drawerController] toggleDrawerSide:MMDrawerSideLeft animated:YES completion:NULL];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  // Return the number of sections.
  return kNumSettingsGroups;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  // Return the number of rows in the section.
  switch (section) {
    case kMyAccountGroup:
      return 2;
      break;
    case kPartnerAccountGroup:
      return 3;
      break;
    case kSecurityGroup:
      if ( [[LTHPasscodeViewController sharedUser] passcodeExistsInKeychain] ) {
        return 2;
      } else {
        return 1;
      }
    case kGoogleDriveGroup:
      return [User currentUser].isGoogleDriveFolderOwner ? 3 : 2;
      break;
    case kGoogleCalendarGroup:
      return [User currentUser].isGoogleCalendarOwner ? 3 : 2;
      break;
    case kGeneralGroup:
      return 4;
      break;
    default:
      return 0;
      break;
  }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *CellIdentifier = @"SettingsCell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    cell.textLabel.textColor = [UIColor blackColor];
    cell.textLabel.font = [kAppDelegate globalBoldFontWithSize:19.0];
    cell.detailTextLabel.textColor = [UIColor blackColor];
    cell.detailTextLabel.font = [kAppDelegate globalFontWithSize:19.0];
  }
  cell.textLabel.text = @"";
  cell.detailTextLabel.text = @"";
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  
  cell.selectionStyle = UITableViewCellSelectionStyleGray;
  
  switch (indexPath.section) {
    case kMyAccountGroup: {
      switch ([self accountCellTypeForIndexPath:indexPath]) {
        case kAccountProfileCell: {
          // My Name
          cell.textLabel.text = @"Your Profile";
        } break;
        case kAccountLogOutCell: {
          // Log out
          cell.textLabel.text = @"Log Out";
        }
        default:
          break;
      }
    } break;
    case kPartnerAccountGroup: {
      if ( indexPath.row == 0 ) {
        // Partner Name
        cell.textLabel.text = @"Partner";
        if ([User currentUser].partnerUserEmail) {
          cell.detailTextLabel.text = [User currentUser].partnerUserEmail;
        } else {
          cell.detailTextLabel.text = [User currentUser].partnerName;
        }
      } else if ( indexPath.row == 1 ) {
        return [self partnerPhoneNumberCellForTableView:tableView];
      } else if ( indexPath.row == 2 ) {
        return [self partnerFaceTimeCellForTableView:tableView];
      }
    } break;
    case kSecurityGroup: {
      if ( [[LTHPasscodeViewController sharedUser] passcodeExistsInKeychain] ) {
        if (indexPath.row == 0) {
          cell.textLabel.text = @"Turn Security Code Off";
        } else {
          cell.textLabel.text = @"Change Security Code";
        }
      } else {
        cell.textLabel.text = @"Turn Security Code On";
      }
    } break;
    case kGoogleDriveGroup: {
      switch (indexPath.row) {
        case 0: {
          cell.textLabel.text = @"Account";
          if ([User currentUser].myGoogleDriveUserEmail) {
            cell.detailTextLabel.text = [User currentUser].myGoogleDriveUserEmail;
          } else {
            cell.detailTextLabel.text = @"Link Account";
          }
        } break;
        case 1: {
          cell.textLabel.text = @"Partner Account";
          if ([User currentUser].partnerGoogleDriveUserEmail) {
            cell.detailTextLabel.text = [User currentUser].partnerGoogleDriveUserEmail;
          } else {
            cell.detailTextLabel.text = @"None";
          }
        } break;
        case 2: {
          cell.textLabel.text = @"Reset Google Drive Folder";
        } break;
          
      }
    } break;
    case kGoogleCalendarGroup: {
      switch (indexPath.row) {
        case 0: {
          cell.textLabel.text = @"Account";
          if ([User currentUser].myGoogleCalendarUserEmail) {
            cell.detailTextLabel.text = [User currentUser].myGoogleCalendarUserEmail;
          } else {
            cell.detailTextLabel.text = @"Link Account";
          }
        } break;
        case 1: {
          cell.textLabel.text = @"Partner Account";
          if ([User currentUser].partnerGoogleCalendarUserEmail) {
            cell.detailTextLabel.text = [User currentUser].partnerGoogleCalendarUserEmail;
          } else {
            cell.detailTextLabel.text = @"None";
          }
        } break;
        case 2: {
          cell.textLabel.text = @"Reset Calendar";
        } break;
      }
    } break;
      
    case kGeneralGroup: {
      switch(indexPath.row) {
        case 0: {
          cell.textLabel.text = @"Tell Others About Shared";
          cell.detailTextLabel.text = @"";
        } break;
        case 1: {
          cell.textLabel.text = @"Rate Shared";
          cell.detailTextLabel.text = @"";
        } break;
        case 2: {
          cell.textLabel.text = @"About Shared";
          cell.detailTextLabel.text = @"";
        } break;
        case 3: {
          cell.textLabel.text = @"Privacy Policy & Terms";
          cell.detailTextLabel.text = @"";
        }
          
      }
    } break;
      
    default:
      break;
  }
  
  return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  return 30.0;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 30.0)];
  headerView.backgroundColor = [UIColor clearColor];
  UILabel *label = [[UILabel alloc] init];
  label.backgroundColor = [UIColor clearColor];
  label.textColor = [UIColor blackColor];
  label.font = [UIFont fontWithName:@"Copperplate-Bold" size:18.0];
  [headerView addSubview:label];
  
  switch (section) {
    case kMyAccountGroup:
      label.frame = CGRectMake(20, 3, 280, 24.0);
      label.text = @"Account";
      break;
    case kPartnerAccountGroup:
      label.frame = CGRectMake(20, 3, 280, 24.0);
      label.text = @"Partner Account";
      break;
    case kSecurityGroup:
      label.frame = CGRectMake(20, 3, 280, 24.0);
      label.text = @"Security";
      break;
    case kGoogleDriveGroup: {
      UIImageView *iv = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Drive"]];
      iv.frame = CGRectMake(20, 5, 20.0, 20.0);
      [headerView addSubview:iv];
      label.frame = CGRectMake(50, 3, 280, 24.0);
      label.text = @"Google Drive";
    } break;
    case kGoogleCalendarGroup: {
      UIImageView *iv = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"GoogleCalendar"]];
      iv.frame = CGRectMake(20, 5, 20.0, 20.0);
      [headerView addSubview:iv];
      label.frame = CGRectMake(50, 3, 280, 24.0);
      label.text = @"Google Calendar";
    } break;
    case kGeneralGroup:
      label.frame = CGRectMake(20, 3, 280, 24.0);
      label.text = @"General Settings";
      break;
    default:
      label.text = @"";
      break;
  }
  
  return headerView;
  
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  switch (indexPath.section) {
    case kMyAccountGroup:
      [tableView deselectRowAtIndexPath:indexPath animated:YES];
      switch ([self accountCellTypeForIndexPath:indexPath]) {
        case kAccountProfileCell: {
          ProfileController* vc = [[ProfileController alloc] initWithNibName:nil bundle:nil];
          [self.navigationController pushViewController:vc animated:YES];
        } break;
        case kAccountLogOutCell: {
          // Log out?
          PSPDFAlertView *alert = [[PSPDFAlertView alloc] initWithTitle:nil message:@"Would you like to log out?"];
          [alert addButtonWithTitle:@"Yes" block:^(NSInteger buttonIndex) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kShouldLogoutNotification object:self];
          }];
          [alert addButtonWithTitle:@"No" block: nil];
          [alert show];
        } break;
        default:
          break;
      } break;
    case kPartnerAccountGroup: {
      if ( indexPath.row == 0 ) {
        AccountDetailController *vc = [[AccountDetailController alloc] initWithAccountType:kPartnerAccount];
        [self.navigationController pushViewController:vc animated:YES];
      }
    } break;
    case kSecurityGroup: {
      if ([[LTHPasscodeViewController sharedUser] passcodeExistsInKeychain]) {
        if (indexPath.row == 0) {
          [[LTHPasscodeViewController sharedUser] showForTurningOffPasscodeInViewController:self];
        } else {
          [[LTHPasscodeViewController sharedUser] showForChangingPasscodeInViewController:self];
        }
      } else {
        [[LTHPasscodeViewController sharedUser] showForEnablingPasscodeInViewController:self];
      }
    } break;
    case kGoogleDriveGroup:
      if (indexPath.row == 0) {
        if ([User currentUser].myGoogleDriveUserEmail) {
          AccountDetailController *vc = [[AccountDetailController alloc] initWithAccountType:kMyGoogleDriveAccount];
          [self.navigationController pushViewController:vc animated:YES];
          
        } else {
          // Log in?
          SEL finishedSelector = @selector(driveViewController:finishedWithAuth:error:);
          GoogleLoginController *authViewController =
          [[GoogleLoginController alloc] initWithScope:kGTLAuthScopeDrive
                                                     clientID:kGoogleClientID
                                                 clientSecret:kGoogleClientSecret
                                             keychainItemName:kGoogleDriveKeychainItemName
                                                     delegate:self
                                             finishedSelector:finishedSelector];
          
          SHNavigationController *nav = [[SHNavigationController alloc] initWithRootViewController: authViewController];
          [self presentViewController:nav animated:YES completion:NULL];
          
        }
      } else if (indexPath.row == 1) {
        // Partner
        if ([User currentUser].partnerGoogleDriveUserEmail) {
          AccountDetailController *vc = [[AccountDetailController alloc] initWithAccountType:kPartnerGoogleDriveAccount];
          [self.navigationController pushViewController:vc animated:YES];
        } else {
          GoogleEmailViewController *vc = [[GoogleEmailViewController alloc] initWithDelegate:self mode:GoogleEmailModeDrivePartner];
          SHNavigationController *nav = [[SHNavigationController alloc] initWithRootViewController:vc];
          [self presentViewController:nav animated:YES completion:nil];
        }
      } else if ( indexPath.row == 2) {
        PSPDFAlertView *alert = [[PSPDFAlertView alloc] initWithTitle:nil message:@"Are you sure you want to reset your Google Drive folder? A new folder will need to be created after resetting."];
        [alert addButtonWithTitle:@"Yes, I'm sure" block:^(NSInteger buttonIndex) {
          [DriveService resetDriveFolder:[DriveService sharedInstance].folder];
          [self.tableView reloadData];
        }];
        [alert setCancelButtonWithTitle:@"Cancel" block:nil];
        [alert show];
      }
      break;
    case kGoogleCalendarGroup:
      if (indexPath.row == 0) {
        if ([User currentUser].myGoogleCalendarUserEmail) {
          AccountDetailController *vc = [[AccountDetailController alloc] initWithAccountType:kMyGoogleCalendarAccount];
          [self.navigationController pushViewController:vc animated:YES];
        } else {
          // Log in
          SEL finishedSelector = @selector(calendarViewController:finishedWithAuth:error:);
          GoogleLoginController *authViewController =
          [[GoogleLoginController alloc] initWithScope:kGTLAuthScopeCalendar
                                                     clientID:kGoogleClientID
                                                 clientSecret:kGoogleClientSecret
                                             keychainItemName:kGoogleCalendarKeychainItemName
                                                     delegate:self
                                             finishedSelector:finishedSelector];
          SHNavigationController *nav = [[SHNavigationController alloc] initWithRootViewController:authViewController];
          [self presentViewController: nav animated: YES completion:NULL];
          
        }
      } else if (indexPath.row == 1) {
        // Partner
        if ([User currentUser].partnerGoogleCalendarUserEmail) {
          AccountDetailController *vc = [[AccountDetailController alloc] initWithAccountType:kPartnerGoogleCalendarAccount];
          [self.navigationController pushViewController:vc animated:YES];
        } else {
          GoogleEmailViewController *vc = [[GoogleEmailViewController alloc] initWithDelegate:self mode:GoogleEmailModeCalendarPartner];
          SHNavigationController *nav = [[SHNavigationController alloc] initWithRootViewController:vc];
          [self presentViewController:nav animated:YES completion:nil];
        }
      } else if ( indexPath.row == 2) {
        PSPDFAlertView *alert = [[PSPDFAlertView alloc] initWithTitle:nil message:@"Are you sure you want to reset your Google Calendar? A new calendar will need to be created after resetting."];
        [alert addButtonWithTitle:@"Yes, I'm sure" block:^(NSInteger buttonIndex) {
          [CalendarService resetCalendarForCalendarInfo:[CalendarService sharedInstance].info];
          [self.tableView reloadData];
        }];
        [alert setCancelButtonWithTitle:@"Cancel" block:nil];
        [alert show];
      }
      break;
    case kGeneralGroup: {
      if (indexPath.row == 0) {
        NSString *text = @"Shared app\n\nhttp://sharedapp.us";
        NSArray *activityItems = @[text];
        
        UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
        [self presentViewController:activityController animated:YES completion:nil];
      } else if (indexPath.row == 1) {
        NSURL *url = [NSURL URLWithString:@"itms-apps://itunes.apple.com/app/id713345046"];
        [[UIApplication sharedApplication] openURL:url];
      } else if (indexPath.row == 2) {
        AboutController *aboutVC = [[AboutController alloc] initWithNibName:nil bundle:nil];
        [self.navigationController pushViewController:aboutVC animated:YES];
      } else if (indexPath.row == 3) {
        GenericWebViewController *vc = [[GenericWebViewController alloc] initWithPath:@"http://www.sharedapp.us/terms"
                                                                                title:@"Privacy Policy & Terms"];
        [self.navigationController pushViewController:vc animated:YES];
      }
    } break;
      
    default:
      break;
  }
}

#pragma mark helper functions
-(NSUInteger)accountCellTypeForIndexPath:(NSIndexPath *)ip {
  if (ip.section == kMyAccountGroup) {
    switch (ip.row) {
      case 0:
        return kAccountProfileCell;
        break;
      case 1:
      default:
        return kAccountLogOutCell;
        break;
    }
  } else {
    if ([User currentUser].partnerUserEmail) {
      if (ip.row == 0) {
        return kAccountPartnerCell;
      } else {
        return kAccountPartnerFBCell;
      }
    } else {
      return kAccountPartnerCell;
    }
  }
}

#pragma mark Drive Helpers
- (void)driveViewController:(GoogleLoginController *)viewController
           finishedWithAuth:(GTMOAuth2Authentication *)auth
                      error:(NSError *)error {
  if ( error ) {
    [SVProgressHUD showErrorWithStatus:@"Unable to log in at this time"];
  } else {
    [User currentUser].myGoogleDriveUserEmail = auth.userEmail;
    [[User currentUser] saveToNetwork];
    [self.tableView reloadData];
  }
}

#pragma mark Google Calendar Helper methods
- (void)calendarViewController:(GoogleLoginController *)viewController
              finishedWithAuth:(GTMOAuth2Authentication *)auth
                         error:(NSError *)error {
  if ( error ) {
    [SVProgressHUD showErrorWithStatus:@"Unable to log in at this time"];    
  } else {
    [User currentUser].myGoogleCalendarUserEmail = [auth.userEmail lowercaseString];
    [[User currentUser] saveToNetwork];
    [self.tableView reloadData];
  }
}

#pragma mark GoogleEmailViewControllerDelegate
- (void)controllerDidChooseEmail:(NSString *)email controller:(GoogleEmailViewController *)controller {
  if ( controller.mode == GoogleEmailModeDrivePartner ) {
    [User currentUser].partnerGoogleDriveUserEmail = [email lowercaseString];
  } else if ( controller.mode == GoogleEmailModeCalendarPartner ) {
    [User currentUser].partnerGoogleCalendarUserEmail = [email lowercaseString];
  }
  
  [[User currentUser] saveToNetwork];
  [self.tableView reloadData];
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)controllerDidCancel:(GoogleEmailViewController *)controller {
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark partner contacts
- (UITableViewCell *)partnerPhoneNumberCellForTableView:(UITableView *)tableView {
  static NSString *CellIdentifier = @"partnerPhoneNumberCellID";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.textColor = [UIColor blackColor];
    cell.textLabel.font = [kAppDelegate globalBoldFontWithSize:19.0];
    UITextField *field = [[UITextField alloc] initWithFrame:CGRectMake(150.f,
                                                                       0.f,
                                                                       cell.contentView.frameSizeWidth - 160.f,
                                                                       cell.contentView.frameSizeHeight)];
    field.tag = kPhoneNumberFieldTag;
    field.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight;
    field.delegate = self;
    field.placeholder = @"Phone #";
    field.textAlignment = NSTextAlignmentRight;
    field.keyboardType = UIKeyboardTypePhonePad;
    
    UIToolbar* numberToolbar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, cell.frameSizeWidth, 50)];
    numberToolbar.barStyle = UIBarStyleBlackTranslucent;
    numberToolbar.items = @[[[UIBarButtonItem alloc]initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancelWithNumberPad)],
                            [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                            [[UIBarButtonItem alloc]initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(doneWithNumberPad)]];
    [numberToolbar sizeToFit];
    field.inputAccessoryView = numberToolbar;
    [cell.contentView addSubview:field];
  }
  
  UITextField *field = (UITextField *)[cell viewWithTag:kPhoneNumberFieldTag];
  [field setText:[User currentUser].partnerPhoneNumber];
  cell.textLabel.text = @"Phone Number";
  
  return cell;
}

- (UITableViewCell *)partnerFaceTimeCellForTableView:(UITableView *)tableView {
  static NSString *CellIdentifier = @"partnerFaceTimeCellID";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.textColor = [UIColor blackColor];
    cell.textLabel.font = [kAppDelegate globalBoldFontWithSize:19.0];
    UITextField *field = [[UITextField alloc] initWithFrame:CGRectMake(110.f,
                                                                       0.f,
                                                                       cell.contentView.frameSizeWidth - 120.f,
                                                                       cell.contentView.frameSizeHeight)];
    field.autocapitalizationType = UITextAutocapitalizationTypeNone;
    field.tag = kFaceTimeFieldTag;
    field.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight;
    field.delegate = self;
    field.placeholder = @"Phone #/Email Address";
    field.textAlignment = NSTextAlignmentRight;
    field.keyboardType = UIKeyboardTypeEmailAddress;
    [cell.contentView addSubview:field];
  }
  
  UITextField *field = (UITextField *)[cell viewWithTag:kFaceTimeFieldTag];
  field.text = [User currentUser].partnerFacetime;
  cell.textLabel.text = @"FaceTime";
  
  return cell;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
  if (textField.tag == kPhoneNumberFieldTag) {
    [User currentUser].partnerPhoneNumber = textField.text;
  } else if ( textField.tag == kFaceTimeFieldTag ) {
    [User currentUser].partnerFacetime = textField.text;
  }
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
  if (textField.tag == kPhoneNumberFieldTag ) {
    NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    textField.text = [newString formattedPhoneNumberForLocale:xPhoneNumberLocale_US];
    return NO;
  } else {
    return YES;
  }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [textField resignFirstResponder];
  return YES;
}

- (void)doneWithNumberPad {
  [self.view endEditing:YES];
}

- (void)cancelWithNumberPad {
  UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:kPartnerAccountGroup]];
  UITextField *field = (UITextField *)[cell viewWithTag:kPhoneNumberFieldTag];
  field.text = [User currentUser].partnerPhoneNumber;
  [self.view endEditing:YES];
}

@end
