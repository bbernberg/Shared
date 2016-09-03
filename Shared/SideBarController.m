//
//  SideBarController.m
//  Shared
//
//  Created by Brian Bernberg on 6/22/15.
//  Copyright (c) 2015 BB Consulting. All rights reserved.
//

#import "SideBarController.h"
#import "User.h"
#import "UIView+Helpers.h"
#import "UIViewController+MMDrawerController.h"
#import "SharedAppDelegate.h"
#import "SettingsController.h"
#import "TextController.h"
#import "GoogleCalendarContainerController.h"
#import "DriveFilesListController.h"
#import "ListsController.h"
#import "NotificationController.h"
#import "SHUtil.h"
#import "NotificationRetriever.h"
#import "PSPDFAlertView.h"

typedef NS_ENUM(NSUInteger, SideBarCellType) {
  SideBarCellTypeText,
  SideBarCellTypeCalendar,
  SideBarCellTypeList,
  SideBarCellTypeDrive,
  SideBarCellTypeSettings,
  SideBarCellTypeNotifcations,
  SideBarCellTypeCount
};

NS_ENUM(NSUInteger, SideBarCellTag) {
  SideBarCellTagImage = 1000,
  SideBarCellTagLabel
};

@interface SideBarController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic) UITableView *tableView;
@end

@implementation SideBarController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
  self.tableView.dataSource = self;
  self.tableView.delegate = self;
  self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
  self.tableView.separatorColor = [UIColor whiteColor];
  [self.view addSubview:self.tableView];
  
  if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
    [self.tableView setSeparatorInset:UIEdgeInsetsMake(0.f, 10.f, 0.f, 0.f)];
  }
  
  if ([self.tableView respondsToSelector:@selector(setLayoutMargins:)]) {
    [self.tableView setLayoutMargins:UIEdgeInsetsMake(0.f, 10.f, 0.f, 0.f)];
  }
  
  [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"sideBarCell"];
  
  self.tableView.backgroundColor = [UIColor darkGrayColor];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(reloadData)
                                               name:kUserDataFetchedNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(reloadData)
                                               name:kUpdateNotificationButtonNotification
                                             object:nil];

}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  return 90.f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, tableView.frame.size.width, 90.f)];
  headerView.backgroundColor = [UIColor darkGrayColor];
  
  UIImageView *logo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Shared_Name_Logo_White"]];
  logo.contentMode = UIViewContentModeScaleAspectFit;
  logo.frame = CGRectMake(20.f, 30.f, headerView.frameSizeWidth - 40.f, 40.f);
  [headerView addSubview:logo];
  
  return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return 60.f;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return SideBarCellTypeCount;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"sideBarCell" forIndexPath:indexPath];
  UIImageView *imageView = (UIImageView *)[cell.contentView viewWithTag:SideBarCellTagImage];
  if ( ! imageView ) {
    imageView = [[UIImageView alloc] init];
    imageView.tag = SideBarCellTagImage;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.frame = CGRectMake(10.f, 20.f, 20.f, 20.f);
    [cell.contentView addSubview:imageView];
  }
  UILabel *label = (UILabel *)[cell.contentView viewWithTag:SideBarCellTagLabel];
  if ( ! label ) {
    label = [[UILabel alloc] init];
    label.tag = SideBarCellTagLabel;
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont fontWithName:@"Copperplate" size:20.0];
    label.textColor = [UIColor whiteColor];
    label.frame = CGRectMake(40.f, 0.f, 200.f, 60.f);
    [cell.contentView addSubview:label];
  }
  
  switch (indexPath.row) {
    case SideBarCellTypeText:
      label.text = @"Text";
      imageView.image = [UIImage imageNamed:@"comment"];
      break;
    case SideBarCellTypeCalendar:
      label.text = @"Google Calendar";
      imageView.image = [UIImage imageNamed:@"GoogleCalendar"];
      break;
    case SideBarCellTypeList:
      label.text = @"Lists";
      imageView.image = [UIImage imageNamed:@"document"];
      break;
    case SideBarCellTypeDrive:
      label.text = @"Google Drive";
      imageView.image = [UIImage imageNamed:@"Drive"];
      break;
    case SideBarCellTypeSettings:
      label.text = @"Settings";
      imageView.image = [UIImage imageNamed:@"settings"];
      break;
    case SideBarCellTypeNotifcations: {
      NSUInteger notificationCount = [[NotificationRetriever instance].notifications count];
      UILabel *numberLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.f, 0.f, 20.f, 20.f)];
      numberLabel.backgroundColor = notificationCount > 0 ? [SHPalette darkRedColor] : [UIColor whiteColor];
      numberLabel.textColor = notificationCount > 0 ? [UIColor whiteColor] : [UIColor blackColor];
      numberLabel.text = [NSString stringWithFormat:@"%ld", notificationCount];
      numberLabel.textAlignment = NSTextAlignmentCenter;
      numberLabel.font = [UIFont systemFontOfSize:14.f];
      numberLabel.adjustsFontSizeToFitWidth = YES;
      numberLabel.layer.cornerRadius = 10.f;
      numberLabel.layer.masksToBounds = YES;
      imageView.image = [SHUtil grabImageFromView:numberLabel];
      label.text = @"Notifications";
    } break;
    default:
      break;
  }
  
  return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
  cell.backgroundColor = [UIColor blackColor];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  
  [self.mm_drawerController closeDrawerAnimated:YES completion:nil];
  
  switch (indexPath.row) {
    case SideBarCellTypeText:
      [self showViewControllerInMainDrawer:[[TextController alloc] init]];
      break;
    case SideBarCellTypeCalendar:
      [self showViewControllerInMainDrawer:[[GoogleCalendarContainerController alloc] init]];
      break;
    case SideBarCellTypeList:
      [self showViewControllerInMainDrawer:[[ListsController alloc] init]];
      break;
    case SideBarCellTypeDrive:
      [self showViewControllerInMainDrawer:[[DriveFilesListController alloc] initWithFolderID:nil andFolderName:nil]];
      break;
    case SideBarCellTypeSettings:
      [self showViewControllerInMainDrawer:[[SettingsController alloc] init]];
      break;
    case SideBarCellTypeNotifcations:
      [self showViewControllerInMainDrawer:[[NotificationController alloc] initWithDelegate:self]];
    default:
      break;
  }
  
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
  return 100.f;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
  UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, tableView.frameSizeWidth, 100.f)];
  footer.backgroundColor = [UIColor blackColor];
  
  if ( [[User currentUser] hasPartner] ) {
    UIView *hLine = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, tableView.frameSizeWidth, [SHUtil thinnestLineWidth])];
    hLine.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    hLine.backgroundColor = [UIColor whiteColor];
    [footer addSubview:hLine];
    
    UIImageView *partnerPicture = [[UIImageView alloc] initWithImage:[User currentUser].partnerSmallPicture];
    partnerPicture.contentMode = UIViewContentModeScaleAspectFill;
    partnerPicture.clipsToBounds = YES;
    partnerPicture.frame = CGRectMake(20.f, 30.f, 40.f, 40.f);
    partnerPicture.layer.borderWidth = 1.f;
    partnerPicture.layer.borderColor = [UIColor whiteColor].CGColor;
    [footer addSubview:partnerPicture];
    
    UILabel *partnerName = [[UILabel alloc] init];
    [partnerName setFrameSize:CGSizeMake(roundf(tableView.frameSizeWidth / 2.f) - 12.f, 30.f)];
    partnerName.center = CGPointMake(partnerPicture.center.x, partnerPicture.center.y + 30.f);
    partnerName.font = [UIFont systemFontOfSize:12.f];
    partnerName.textColor = [UIColor whiteColor];
    partnerName.text = [[[User currentUser] partnerName] length] > 0 ? [[User currentUser] partnerName] : [[User currentUser] partnerUserEmail];
    partnerName.textAlignment = NSTextAlignmentCenter;
    [footer addSubview:partnerName];

    UIView *vLine = [[UIView alloc] initWithFrame:CGRectMake(80.f, partnerPicture.frameOriginY, [SHUtil thinnestLineWidth], partnerPicture.frameSizeHeight)];
    vLine.backgroundColor = [UIColor whiteColor];
    [footer addSubview:vLine];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[self buttonImageWithPicture:[UIImage imageNamed:@"phone"] text:@"Call"] forState:UIControlStateNormal];
    [button setFrameSize:CGSizeMake(40.f, 40.f)];
    button.center = CGPointMake(110.f, vLine.center.y+4.f);
    [footer addSubview:button];
    [button addTarget:self action:@selector(callButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[self buttonImageWithPicture:[UIImage imageNamed:@"facetime"] text:@"Video"] forState:UIControlStateNormal];
    [button setFrameSize:CGSizeMake(40.f, 40.f)];
    button.center = CGPointMake(170.f, vLine.center.y+4.f);
    [footer addSubview:button];
    [button addTarget:self action:@selector(ftVideoButtonPressed:) forControlEvents:UIControlEventTouchUpInside];

    button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[self buttonImageWithPicture:[UIImage imageNamed:@"facetime"] text:@"Audio"] forState:UIControlStateNormal];
    [button setFrameSize:CGSizeMake(40.f, 40.f)];
    button.center = CGPointMake(230.f, vLine.center.y+4.f);
    [footer addSubview:button];
    [button addTarget:self action:@selector(ftAudioButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
  }
  
  return footer;
}

- (UIImage *)buttonImageWithPicture:(UIImage *)image text:(NSString *)text {
  UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, 40.f, 40.f)];
  UIImageView *iv = [[UIImageView alloc] initWithImage:image];
  iv.contentMode = UIViewContentModeScaleAspectFit;
  iv.frame = CGRectMake(0.f, 0.f, container.frameSizeWidth, roundf(container.frameSizeHeight * 0.56f));
  [container addSubview:iv];
  UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.f, roundf(container.frameSizeHeight * 0.6f), container.frameSizeWidth, roundf(container.frameSizeHeight * 0.4f))];
  label.text = text;
  label.font = [UIFont systemFontOfSize:10.f];
  label.textAlignment = NSTextAlignmentCenter;
  label.textColor = [UIColor whiteColor];
  [container addSubview:label];
  
  return [SHUtil grabImageFromView:container];
}


#pragma mark button handlers
- (void)callButtonPressed:(UIButton *)button {
  if ( ![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tel:5555555555"]] ) {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:@"Your device doesn't support this feature."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [self presentViewController:alert
                       animated:YES
                     completion:nil];
    
  } else if ( ! [User currentUser].partnerPhoneNumber ) {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:@"Partner phone number is required. Please update in the Settings menu."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [self presentViewController:alert
                       animated:YES
                     completion:nil];
    
  } else {
    NSURL *URLToDial = [NSURL URLWithString:[NSString stringWithFormat:@"tel:%@", [[User currentUser].partnerPhoneNumber stringByReplacingOccurrencesOfString:@" " withString:@""]]];
    
    [[UIApplication sharedApplication] openURL:URLToDial];
  }
}

- (void)ftVideoButtonPressed:(UIButton *)button {
  if (![[UIApplication sharedApplication] canOpenURL: [NSURL URLWithString: @"facetime://5555555555"]]) {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:@"Your device doesn't support this feature."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [self presentViewController:alert
                       animated:YES
                     completion:nil];
  } else if ( ! [User currentUser].partnerFacetime ) {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:@"Partner FaceTime contact is required. Please update in the Settings menu."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [self presentViewController:alert
                       animated:YES
                     completion:nil];
  } else {
    NSURL *URLToDial = [NSURL URLWithString:[NSString stringWithFormat:@"facetime://%@", [[User currentUser].partnerFacetime stringByReplacingOccurrencesOfString:@" " withString:@""]]];
    
    [[UIApplication sharedApplication] openURL:URLToDial];
  }
}

- (void)ftAudioButtonPressed:(UIButton *)button {
  if (![[UIApplication sharedApplication] canOpenURL: [NSURL URLWithString: @"facetime-audio://5555555555"]]) {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:@"Your device doesn't support this feature."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [self presentViewController:alert
                       animated:YES
                     completion:nil];
  }  else if ( ! [User currentUser].partnerFacetime ) {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:@"Partner FaceTime contact is required. Please update in the Settings menu."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [self presentViewController:alert
                       animated:YES
                     completion:nil];    
  } else {
    NSURL *URLToDial = [NSURL URLWithString:[NSString stringWithFormat:@"facetime-audio://%@", [[User currentUser].partnerFacetime stringByReplacingOccurrencesOfString:@" " withString:@""]]];
    
    [[UIApplication sharedApplication] openURL:URLToDial];
  }
}

#pragma mark other methods
- (void)showViewControllerInMainDrawer:(UIViewController *)viewController {
  [self showViewControllerInMainDrawer:viewController animated:YES];
}

- (void)showViewControllerInMainDrawer:(UIViewController *)viewController animated:(BOOL)animated {
  UINavigationController *nav = [kAppDelegate navController];
  [nav setViewControllers:@[viewController] animated:animated];
}

- (void)reloadData {
  [self.tableView reloadData];
}

#pragma mark NotificationControllerDelegate
- (void)didSelectNotificationType:(NSString*)notificationType {
  if ([notificationType isEqualToString:kListNotification]) {
    [self showViewControllerInMainDrawer:[[ListsController alloc] init] animated:NO];
  } else if ([notificationType isEqualToString:kGoogleCalendarNotification]) {
    [self showViewControllerInMainDrawer:[[GoogleCalendarContainerController alloc] init] animated:NO];
  } else if ([notificationType isEqualToString:kTextNotification]) {
    [self showViewControllerInMainDrawer:[[TextController alloc] init] animated:NO];
  } else if ([notificationType isEqualToString:kDriveUploadNotification]) {
    [self showViewControllerInMainDrawer:[[DriveFilesListController alloc] initWithFolderID:nil andFolderName:nil] animated:NO];
  }
}

@end
