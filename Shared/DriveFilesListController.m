//
//  DriveFilesListViewController.m
//  Shared
//
//  Created by Brian Bernberg on 1/13/13.
//  Copyright (c) 2013 BB Consulting. All rights reserved.
//


#import "DriveFilesListController.h"
#import "Constants.h"
#import "TouchDownGestureRecognizer.h"
#import "SVPullToRefresh.h"
#import "SVProgressHUD.h"
#import "UIButton+myButton.h"
#import <Quartzcore/QuartzCore.h>
#import "GTMOAuth2ViewControllerTouch.h"
#import "GTLDrive.h"
#import "PSPDFAlertView.h"
#import "UIImageView+AFNetworking.h"
#import "User.h"
#import <Parse/Parse.h>
#import "DriveService.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import "DriveFileController.h"
#import <MediaPlayer/MediaPlayer.h>
#import "GoogleLoginController.h"
#import <AVFoundation/AVFoundation.h>
#import "SHUtil.h"
#import "NotificationRetriever.h"
#import "SharedActivityIndicator.h"
#import "PhotoDetailController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <MMDrawerController/MMDrawerBarButtonItem.h>
#import <MMDrawerController/UIViewController+MMDrawerController.h>
#import "GoogleEmailViewController.h"
#import "CLImageEditor.h"

#define kUploadIVTag 1000
#define kPhotoActionSheetTag 1001
#define kVideoActionSheetTag 1002
#define kFileActionSheetTag 1003
#define kActionTakePhoto @"Take Photo"
#define kActionTakeVideo @"Take Video"
#define kActionChooseFromLibrary @"Choose From Library"

#define kActionRename @"Rename"
#define kActionDelete @"Delete"
#define kActionSavePhoto @"Save Photo"
#define kActionSaveVideo @"Save Video"

@interface DriveFilesListController () <
UITableViewDataSource,
UITableViewDelegate,
UIGestureRecognizerDelegate,
UIActionSheetDelegate,
UINavigationControllerDelegate,
UIImagePickerControllerDelegate,
CLImageEditorDelegate,
UITextFieldDelegate,
GoogleEmailViewControllerDelegate
>
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UIView *uploadButtonsBackground;
@property (nonatomic, weak) IBOutlet UIButton *folderButton;
@property (nonatomic, weak) IBOutlet UIButton *photoButton;
@property (nonatomic, weak) IBOutlet UIButton *videoButton;
@property (nonatomic, assign) BOOL isRoot;
@property (nonatomic, strong) UIButton *uploadButton;
@property (nonatomic, strong) TouchDownGestureRecognizer *touchDownGR;
@property (nonatomic, assign) BOOL showingUploadButtons;

@property (nonatomic, readonly) GTLServiceDrive *gtlDriveService;
@property (nonatomic, strong) NSArray *driveFiles;
@property (nonatomic, readonly) PFObject *jointFolder;
@property (nonatomic, strong) NSString *folderID;
@property (nonatomic, strong) NSString *folderName;
@property (nonatomic, strong) UIView *loadingView;
@property (nonatomic, strong) UIView *tryAgainView;
@property (nonatomic, strong) GTLDriveFile *selectedFile;
@property (nonatomic, strong) UIView *introBackground;
@property (nonatomic, strong) PSPDFAlertView *alert;
@property (nonatomic, assign) BOOL shouldShowAuth;
@property (nonatomic) BOOL deletedErrorShown;
@end

@implementation DriveFilesListController

- (id)initWithFolderID:(NSString *)theFolderID andFolderName:(NSString *)theFolderName
{
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    // Custom initialization
    self.folderID = theFolderID;
    self.isRoot = ( theFolderID == nil );
    self.folderName = theFolderName;
    self.shouldShowAuth = NO;
    [self registerForNotifications];
    self.deletedErrorShown = NO;
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  [[NSUserDefaults standardUserDefaults] setObject:@(SharedControllerTypeDrive) forKey:kCurrentSharedControllerType];
  [[NSUserDefaults standardUserDefaults] synchronize];
  
  self.view.backgroundColor = [SHPalette backgroundColor];
  self.tableView.backgroundColor = [SHPalette backgroundColor];
  self.automaticallyAdjustsScrollViewInsets = NO;
  self.tableView.contentInset = UIEdgeInsetsMake(64.f, 0.f, 0.f, 0.f);
  
  if (self.folderName) {
    self.navigationItem.title = self.folderName;
  } else {
    self.navigationItem.title = @"Google Drive";
  }
  
  self.tableView.hidden = YES;
  __weak DriveFilesListController *wSelf = self;
  [self.tableView addPullToRefreshWithActionHandler:^{
    [wSelf refreshTableViewSource];
  }];
  self.tableView.showsPullToRefresh = NO;
  
  self.touchDownGR = [[TouchDownGestureRecognizer alloc] initWithTarget:self action:@selector(hideUploadButtons)];
  self.touchDownGR.delegate = self;
  self.showingUploadButtons = FALSE;
  
  
  if (self.isRoot) {
    self.navigationItem.leftBarButtonItem = [[MMDrawerBarButtonItem alloc] initWithTarget:self action:@selector(drawerButtonPressed)];
    
    NSString *key = [NSString stringWithFormat:@"%@%@", kDriveIntroShownKey, [User currentUser].myUserID];
    if ( ! [[NSUserDefaults standardUserDefaults] stringForKey:key] ) {
      [[NSUserDefaults standardUserDefaults] setBool:YES forKey:key];
      [[NSUserDefaults standardUserDefaults] synchronize];
      [self.navigationController setNavigationBarHidden:YES];
      [self showIntro];
    } else {
      [self hideIntroWithDuration:0.0];
      [self kickoffFromViewDidLoad:YES];
    }
  } else {
    [self kickoffFromViewDidLoad:YES];
  }
  
}

- (void)registerForNotifications {
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(handleDriveRefreshFilesNotification)
                                               name:kDriveRefreshFilesNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(handleDriveFolderFetched)
                                               name:kDriveFolderFetchedNotification
                                             object:nil];
}

-(void)kickoffFromViewDidLoad:(BOOL)fromViewDidLoad {
  [self.navigationController setNavigationBarHidden:NO];
  [self initializeUploadButtons];
  // Check for authorization.
  GTMOAuth2Authentication *auth =
  [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:kGoogleDriveKeychainItemName
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
  
  [self showLoadingViews];
  
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    [[NotificationRetriever instance] deleteNotificationsOfType:kDriveUploadNotification];
  });
  
}

-(void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:nil];
  [[UIDevice currentDevice] setValue:@(UIInterfaceOrientationPortrait) forKey:@"orientation"];
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

#pragma mark drive auth functions
-(void)showAuth {
  SEL finishedSelector = @selector(viewController:finishedWithAuth:error:);
  GoogleLoginController *vc = [[GoogleLoginController alloc] initWithScope:kGTLAuthScopeDrive
                                                                  clientID:kGoogleClientID
                                                              clientSecret:kGoogleClientSecret
                                                          keychainItemName:kGoogleDriveKeychainItemName
                                                                  delegate:self
                                                          finishedSelector:finishedSelector];
  vc.cancelBlock = ^{
    [self removeLoadingViews];
    [self showTryAgainView];
  };
  SHNavigationController *nav = [[SHNavigationController alloc] initWithRootViewController:vc];
  [self presentViewController: nav animated: YES completion:NULL];
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
    
    [self removeLoadingViews];
    [self showTryAgainView];
  }
}

- (void)isAuthorizedWithAuthentication:(GTMOAuth2Authentication *)auth {
  [self.gtlDriveService setAuthorizer:auth];
  
  if (self.isRoot) {
    if ( ! [[User currentUser].myGoogleDriveUserEmail isEqualToString:auth.userEmail] ) {
      [User currentUser].myGoogleDriveUserEmail = auth.userEmail;
      [[User currentUser] saveToNetwork];
    }
    
    if ([[DriveService sharedInstance] isAvailable]) {
      self.folderID = self.jointFolder[kDriveFolderIDKey];
      [[DriveService sharedInstance] fetchDriveFolderInfo];
      self.navigationItem.title = self.jointFolder[kDriveFolderNameKey];
      [self getDriveFolderMetadata];
      // Check if folder has been successfully shared
      if ([self jointFolderIsShared] == NO) {
        if ( [self isFolderOwner] ) {
          [self addPermission];
          [self refreshTableViewSource];
        } else {
          UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                         message:@"Your partner has not successfully shared the folder yet. Please ask them to log in to Google Drive through Shared."
                                                                  preferredStyle:UIAlertControllerStyleAlert];
          [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                    style:UIAlertActionStyleCancel
                                                  handler:nil]];
          [self presentViewController:alert
                             animated:YES
                           completion:nil];
          
          [kAppDelegate showTextController];
        }
      } else {
        [self refreshTableViewSource];
      }
    } else {
      [self getJointDriveFolderInfo];
    }
  } else {
    [self refreshTableViewSource];
  }
}

#pragma mark joint folder retrieval functions
-(void)getJointDriveFolderInfo {
  __weak DriveFilesListController *wSelf = self;
  
  // Query Parse to determine if joint Drive folder is created
  PFQuery *folderQuery = [PFQuery queryForCurrentUsersWithClassName:kDriveFolderClass];
  
  [folderQuery findObjectsInBackgroundWithBlock:^(NSArray *folders, NSError *error) {
    if (!error) {
      if (folders.count == 0) {
        self.alert = [[PSPDFAlertView alloc] initWithTitle:nil
                                                   message:@"Please enter a name for your shared folder:"];
        self.alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        [self.alert setCancelButtonWithTitle:@"OK"
                                       block:^(NSInteger buttonIndex) {
                                         [wSelf checkName:[wSelf.alert textFieldAtIndex:0]
                                              forCreation:YES
                                           parentFolderID:nil];
                                       }];
        [[self.alert textFieldAtIndex:0] setDelegate:self];
        [self.alert show];
        
      } else {
        [DriveService sharedInstance].folder = [folders firstObject];
        self.folderID = self.jointFolder[kDriveFolderIDKey];
        
        if ( [self isFolderOwner] ) {
          NSString *folderUserEmail = self.jointFolder[kDriveFolderOwnerUserEmailKey];
          if ( ! [folderUserEmail isEqualToInsensitive:[self.gtlDriveService.authorizer userEmail]] ) {
            [self handleIncorrectUserEmail:folderUserEmail];
            return;
          }
        } else {
          if ( ! [[User currentUser].partnerGoogleDriveUserEmail isEqualToInsensitive:self.jointFolder[kDriveFolderOwnerUserEmailKey]] ) {
            [User currentUser].partnerGoogleDriveUserEmail = wSelf.jointFolder[kDriveFolderOwnerUserEmailKey];
            [[User currentUser] saveToNetwork];
          }
          NSString *folderUserEmail = self.jointFolder[kDriveFolderPartnerUserEmailKey];
          if ( ! [folderUserEmail isEqualToInsensitive:[self.gtlDriveService.authorizer userEmail]] ) {
            [wSelf handleIncorrectUserEmail:folderUserEmail];
            return;
          }
        }
        
        // Check if folder has been successfully shared
        if ([self jointFolderIsShared] == NO) {
          if ( [self isFolderOwner] ) {
            [self addPermission];
            [self refreshTableViewSource];
            self.navigationItem.title = wSelf.jointFolder[kDriveFolderNameKey];
            [self getDriveFolderMetadata];
          } else {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                           message:@"Your partner has not successfully shared the folder yet. Please ask them to log in to Google Drive through Shared."
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                      style:UIAlertActionStyleCancel
                                                    handler:nil]];
            [self presentViewController:alert
                               animated:YES
                             completion:nil];
            
            [kAppDelegate showTextController];
          }
        } else {
          // Everything is set up...save folder & reload table
          [self refreshTableViewSource];
          self.navigationItem.title = wSelf.jointFolder[kDriveFolderNameKey];
          [self getDriveFolderMetadata];
        }
        // Delete extra folders (which shouldn't happen)
        if (folders.count > 1) {
          NSRange extraRange;
          extraRange.location = 1;
          extraRange.length = folders.count - 1;
          NSArray *extraFolders = [folders subarrayWithRange:extraRange];
          for (PFObject *extraFolder in extraFolders) {
            [extraFolder deleteInBackground];
          }
        }
      }
    } else {
      if ([wSelf.navigationController.viewControllers containsObject:self]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                       message:@"Error retrieving Drive folder. Please try later."
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
  }];
  
}

- (void)handleDriveFolderFetched {
  if ( ! [[DriveService sharedInstance].folder[kDriveFolderIDKey] isEqualToString:self.folderID] ) {
    if (self.navigationController.presentedViewController != self) {
      [self.navigationController popToViewController:self animated:YES];
    }
    [self refreshTableViewSource];
  }
}

-(void)getDriveFolderMetadata {
  [[DriveService sharedInstance] getDriveFolderMetadataWithCompletionBlock:^(GTLDriveFile *file, NSError *error) {
    if (error == nil) {
      if ( ! [self.jointFolder[kDriveFolderNameKey] isEqualToString:file.title] ) {
        self.jointFolder[kDriveFolderNameKey] = file.title;
        [self.jointFolder saveInBackground];
      }
      self.navigationItem.title = file.title;
    }
  }];
}

-(void)handleIncorrectUserEmail:(NSString *)correctUserEmail {
  __weak DriveFilesListController *wSelf = self;
  
  PSPDFAlertView *alert = [[PSPDFAlertView alloc] initWithTitle:@"Incorrect User"
                                                        message:[NSString stringWithFormat:@"You are logged in to Google as the incorrect user.  Please log in as %@", correctUserEmail]];
  
  [alert addButtonWithTitle:@"OK" block:^(NSInteger buttonIndex) {
    // perform logout
    [GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName:kGoogleDriveKeychainItemName];
    [self.gtlDriveService setAuthorizer:nil];
    [User currentUser].myGoogleDriveUserEmail = nil;
    [[User currentUser] saveToNetwork];
    // log in
    SEL finishedSelector = @selector(viewController:finishedWithAuth:error:);
    GoogleLoginController *vc = [[GoogleLoginController alloc] initWithScope:kGTLAuthScopeDrive
                                                                    clientID:kGoogleClientID
                                                                clientSecret:kGoogleClientSecret
                                                            keychainItemName:kGoogleDriveKeychainItemName
                                                                    delegate:self
                                                            finishedSelector:finishedSelector];
    vc.cancelBlock = ^{
      [self removeLoadingViews];
      [self showTryAgainView];
    };
    SHNavigationController *nav = [[SHNavigationController alloc] initWithRootViewController:vc];
    [wSelf presentViewController:nav animated:YES completion:NULL];
  }];
  
  if ([self isFolderOwner]) {
    [alert addButtonWithTitle:@"New Folder" block:^(NSInteger buttonIndex) {
      wSelf.alert = [[PSPDFAlertView alloc] initWithTitle:nil
                                                  message:@"Please enter a name for your shared Drive folder:"];
      wSelf.alert.alertViewStyle = UIAlertViewStylePlainTextInput;
      [wSelf.alert setCancelButtonWithTitle:@"OK"
                                      block:^(NSInteger buttonIndex) {
                                        [wSelf checkName:[wSelf.alert textFieldAtIndex:0]
                                             forCreation:YES
                                          parentFolderID:nil];
                                      }];
      [[wSelf.alert textFieldAtIndex:0] setDelegate:wSelf];
      [wSelf.alert show];
    }];
  }
  
  [alert show];
}

#pragma mark drive functions
- (GTLServiceDrive *)gtlDriveService {
  return [DriveService sharedInstance].gtlDriveService;
}

- (PFObject *)jointFolder {
  return [DriveService sharedInstance].folder;
}

#pragma mark table view data source functions
-(void)refreshTableViewSource {
  
  [[DriveService sharedInstance] refreshDriveFolderWithIdentifier:self.folderID completionBlock:^(GTLDriveFileList *files, NSError *error) {
    self.tableView.hidden = NO;
    [self removeLoadingViews];
    if (error == nil) {
      NSMutableArray *driveFiles = [NSMutableArray array];
      [driveFiles addObjectsFromArray:files.items];
      // Sort Drive Files by modified date (descending order).
      [driveFiles sortUsingComparator:^NSComparisonResult(GTLDriveFile *lhs,
                                                          GTLDriveFile *rhs) {
        return [rhs.modifiedDate.date compare:lhs.modifiedDate.date];
      }];
      // Now move folders first
      NSInteger insertPosition = 0;
      for (int i = 0; i < driveFiles.count; i++) {
        GTLDriveFile *file = driveFiles[i];
        if ([file.mimeType isEqualToString:kDriveFolderMIMEType]) {
          [driveFiles removeObject:file];
          [driveFiles insertObject:file atIndex:insertPosition++];
        }
      }
      self.driveFiles = [NSArray arrayWithArray:driveFiles];
      
      [self configureTableViewHeader];
      [self.tableView reloadData];
    } else {
      UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                     message:@"Unable to load files at this time. Please try later."
                                                              preferredStyle:UIAlertControllerStyleAlert];
      [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                style:UIAlertActionStyleCancel
                                              handler:nil]];
      [self presentViewController:alert
                         animated:YES
                       completion:nil];
    }
    [self.tableView.pullToRefreshView stopAnimating];
  }];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.driveFiles.count;
}

#define kMyImageViewTag 1001
#define kMyTextLabelTag 10022
#define kMyDetailTextLabelTag 1003

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *CellIdentifier = @"GoogleCell";
  UITableViewCell *cell;
  UIImageView *myImageView;
  UILabel *myTextLabel;
  UILabel *myDetailTextLabel;
  
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    myImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 12, 20, 30)];
    myImageView.contentMode = UIViewContentModeScaleAspectFit;
    myImageView.tag = kMyImageViewTag;
    [cell.contentView addSubview:myImageView];
    
    myTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(40, 10, 220, 22)];
    myTextLabel.backgroundColor = [UIColor clearColor];
    myTextLabel.textColor = [UIColor blackColor];
    myTextLabel.font = [kAppDelegate globalBoldFontWithSize:16.0];
    myTextLabel.tag = kMyTextLabelTag;
    [cell.contentView addSubview:myTextLabel];
    
    myDetailTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(40, 33, 220, 14)];
    myDetailTextLabel.backgroundColor = [UIColor clearColor];
    myDetailTextLabel.textColor = [UIColor lightGrayColor];
    myDetailTextLabel.font = [kAppDelegate globalFontWithSize:14.0];
    myDetailTextLabel.tag = kMyDetailTextLabelTag;
    [cell.contentView addSubview:myDetailTextLabel];
    
  }
  
  myImageView = (UIImageView *)[cell.contentView viewWithTag:kMyImageViewTag];
  myTextLabel = (UILabel *)[cell.contentView viewWithTag:kMyTextLabelTag];
  myDetailTextLabel = (UILabel *)[cell.contentView viewWithTag:kMyDetailTextLabelTag];
  
  GTLDriveFile *file = self.driveFiles[indexPath.row];
  myTextLabel.text = file.title;
  
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  [dateFormatter setDateFormat:@"MM/dd/yy"];
  
  NSString *modifiedDate = [dateFormatter stringFromDate:file.modifiedDate.date];
  myDetailTextLabel.text = [NSString stringWithFormat:@"Modified %@",modifiedDate];
  myDetailTextLabel.font = [kAppDelegate globalFontWithSize:14.0];
  
  if (file.thumbnailLink && ( [[self class] isImage:file] || [[self class] isVideo:file] )) {
    [myImageView setImageWithURL:[NSURL URLWithString:file.thumbnailLink]
                placeholderImage:[UIImage imageNamed:@"gray_document"]];
  } else if (file.iconLink) {
    [myImageView setImageWithURL:[NSURL URLWithString:file.iconLink]
                placeholderImage:[UIImage imageNamed:@"gray_document"]];
  } else if ([file.mimeType isEqualToString:kDriveFolderMIMEType]) {
    myImageView.image = [UIImage imageNamed:@"gray_folder"];
  } else {
    NSLog(@"No icon found");
    myImageView.image = [UIImage imageNamed:@"gray_document"];
  }
  
  return cell;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
  cell.backgroundColor = [UIColor whiteColor];
}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
  return [UIView new];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return 54.0;
}

#pragma mark table view delegate functions
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
  GTLDriveFile *file = self.driveFiles[indexPath.row];
  
  if ([file.mimeType isEqualToString:kDriveFolderMIMEType]) {
    DriveFilesListController *vc = [[DriveFilesListController alloc] initWithFolderID:file.identifier andFolderName:file.title];
    [self.navigationController pushViewController:vc animated:YES];
  } else {
    if ([[self class] isVideo:file] || [[self class] isAudio:file] || [[self class] isImage:file]) {
      [[DriveService sharedInstance] downloadFile:file statusMessage:@"Loading..." withCompletionBlock:^(NSData *data, NSError *error) {
        [SVProgressHUD dismiss];
        if (error == nil) {
          if ( [[self class] isImage:file] ) {
            UIImage *image = [UIImage imageWithData:data];
            [self presentPhotoDetailViewForImage:image];
          } else {
            NSURL *movieURL =[NSURL fileURLWithPath:pathInCachesDirectory(file.title)];
            [data writeToURL:movieURL atomically:YES];
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
            
            MPMoviePlayerViewController *vc = [[MPMoviePlayerViewController alloc] initWithContentURL:movieURL];
            vc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
            [self presentViewController:vc animated:YES completion:nil];
          }
        } else {
          NSLog(@"An error occurred: %@", error);
          UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                         message:@"Unable to load file at this time. Pleas try later."
                                                                  preferredStyle:UIAlertControllerStyleAlert];
          [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                    style:UIAlertActionStyleCancel
                                                  handler:nil]];
          [self presentViewController:alert
                             animated:YES
                           completion:nil];
          
        }
      }];
    } else {
      DriveFileController *vc = [[DriveFileController alloc] initWithFile:file driveService:self.gtlDriveService];
      [self.navigationController pushViewController:vc animated:YES];
    }
  }
  
}

-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
  self.selectedFile = self.driveFiles[indexPath.row];
  UIActionSheet *sheet = nil;
  if ( [[self class] isImage:self.selectedFile] ) {
    sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:kActionSavePhoto, kActionRename, kActionDelete, nil];
  } else if ( [[self class] isVideo:self.selectedFile]) {
    sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:kActionSaveVideo, kActionRename, kActionDelete, nil];
  } else {
    sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:kActionRename, kActionDelete, nil];
  }
  sheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
  sheet.tag = kFileActionSheetTag;
  [sheet showInView:self.view];
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
  if (self.tableView.pullToRefreshView.state == SVPullToRefreshStateStopped) {
    if (self.tableView.contentOffset.y < -70 && ! self.tableView.editing) {
      self.tableView.showsPullToRefresh = YES;
    } else {
      self.tableView.showsPullToRefresh = NO;
    }
  }
}

#pragma mark button functions
-(void)initializeUploadButtons {
  // Upload button
  self.uploadButton=[UIButton buttonWithType:UIButtonTypeCustom];
  [self.uploadButton addTarget:self
                        action:@selector(uploadButtonPressed:)
              forControlEvents:UIControlEventTouchUpInside];
  self.uploadButton.frame = CGRectMake(0, 0, 28, 28);
  UIImageView *uploadIV = [[UIImageView alloc] initWithFrame:CGRectMake(4, 4, 20, 20)];
  uploadIV.image = [[UIImage imageNamed:@"X_icon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
  uploadIV.userInteractionEnabled = NO;
  uploadIV.tag = kUploadIVTag;
  [self.uploadButton addSubview:uploadIV];
  UIBarButtonItem * uploadBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.uploadButton];
  self.navigationItem.rightBarButtonItem = uploadBarButtonItem;
  self.navigationItem.rightBarButtonItem.enabled = ! self.isRoot;
  self.uploadButton.tintColor = self.navigationItem.rightBarButtonItem.enabled ? [SHPalette darkNavyBlue] : [UIColor lightGrayColor];
  
  CGRect frame = self.uploadButtonsBackground.frame;
  frame.size.height = 0;
  self.uploadButtonsBackground.frame = frame;
  
  [self createFolderButton];
  [self createPhotoButton];
  [self createVideoButton];
  
}

#define kUploadbuttonsBackgroundHeight 180

-(void)showUploadButtons {
  self.showingUploadButtons = TRUE;
  [self.tableView addGestureRecognizer:self.touchDownGR];
  [UIView animateWithDuration:0.3 animations:^{
    UIImageView *uploadIV = (UIImageView *)[self.uploadButton viewWithTag:kUploadIVTag];
    uploadIV.transform = CGAffineTransformMakeRotation(M_PI_4);
    CGRect frame = self.uploadButtonsBackground.frame;
    frame.size.height = kUploadbuttonsBackgroundHeight;
    self.uploadButtonsBackground.frame = frame;
  }];
}

-(void)hideUploadButtons {
  self.showingUploadButtons = FALSE;
  [self.tableView removeGestureRecognizer:self.touchDownGR];
  [UIView animateWithDuration:0.5 animations:^{
    UIImageView *uploadIV = (UIImageView *)[self.uploadButton viewWithTag:kUploadIVTag];
    uploadIV.transform = CGAffineTransformIdentity;
    CGRect frame = self.uploadButtonsBackground.frame;
    frame.size.height = 0;
    self.uploadButtonsBackground.frame = frame;
  }];
}

-(void)uploadButtonPressed:(id)sender {
  if (self.showingUploadButtons) {
    [self hideUploadButtons];
  } else {
    [self showUploadButtons];
  }
}

-(IBAction)folderButtonPressed:(id)sender {
  [self hideUploadButtons];
  
  self.alert = [[PSPDFAlertView alloc] initWithTitle:nil
                                             message:@"Please enter a name for the folder:"];
  self.alert.alertViewStyle = UIAlertViewStylePlainTextInput;
  [self.alert setCancelButtonWithTitle:@"Cancel" block:nil];
  __block DriveFilesListController *weakSelf = self;
  [self.alert addButtonWithTitle:@"OK" block:^(NSInteger buttonIndex) {
    [weakSelf checkName:[weakSelf.alert textFieldAtIndex:0]
            forCreation:YES
         parentFolderID:weakSelf.folderID];
  }];
  [[self.alert textFieldAtIndex:0] setDelegate:self];
  [self.alert show];
}

-(IBAction)photoButtonPressed:(id)sender {
  [self hideUploadButtons];
  UIActionSheet *photoActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:kActionTakePhoto, kActionChooseFromLibrary, nil];
  photoActionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
  photoActionSheet.tag = kPhotoActionSheetTag;
  [photoActionSheet showInView:self.view];
}

-(IBAction)videoButtonPressed:(id)sender {
  [self hideUploadButtons];
  UIActionSheet *videoActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:kActionTakeVideo, kActionChooseFromLibrary, nil];
  videoActionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
  videoActionSheet.tag = kVideoActionSheetTag;
  [videoActionSheet showInView:self.view];
}

-(void)createFolderButton {
  UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 15, 30, 30)];
  imageView.image = [UIImage imageNamed:@"folder"];
  imageView.userInteractionEnabled = NO;
  [self.folderButton addSubview:imageView];
  
  UILabel *theLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 15, 250, 30)];
  theLabel.textAlignment = NSTextAlignmentLeft;
  theLabel.font = [UIFont fontWithName:@"CopperPlate" size:22.0];
  theLabel.textColor = [UIColor whiteColor];
  theLabel.text = @"Folder";
  theLabel.backgroundColor = [UIColor clearColor];
  [self.folderButton addSubview:theLabel];
  
}

-(void)createPhotoButton {
  UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 15, 30, 30)];
  imageView.image = [UIImage imageNamed:@"photo"];
  imageView.userInteractionEnabled = NO;
  [self.photoButton addSubview:imageView];
  
  UILabel *theLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 15, 250, 30)];
  theLabel.textAlignment = NSTextAlignmentLeft;
  theLabel.font = [UIFont fontWithName:@"CopperPlate" size:22.0];
  theLabel.textColor = [UIColor whiteColor];
  theLabel.text = @"Photo";
  theLabel.backgroundColor = [UIColor clearColor];
  [self.photoButton addSubview:theLabel];
  
}

-(void)createVideoButton {
  UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 15, 30, 30)];
  imageView.image = [UIImage imageNamed:@"video"];
  imageView.userInteractionEnabled = NO;
  [self.videoButton addSubview:imageView];
  
  UILabel *theLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 15, 250, 30)];
  theLabel.textAlignment = NSTextAlignmentLeft;
  theLabel.font = [UIFont fontWithName:@"CopperPlate" size:22.0];
  theLabel.textColor = [UIColor whiteColor];
  theLabel.text = @"Video";
  theLabel.backgroundColor = [UIColor clearColor];
  [self.videoButton addSubview:theLabel];
  
}

#pragma mark Drive folder functions
-(void)createDriveFolderWithName:(NSString *)folderName parentFolderID:(NSString *)parentFolderID {
  [[DriveService sharedInstance] createDriveFolderWithName:folderName
                                            parentFolderID:parentFolderID
                                           completionBlock:^(GTLDriveFile *newFolder, NSError *error) {
                                             if (error == nil) {
                                               if ( parentFolderID == nil ) {
                                                 // New joint folder root
                                                 [DriveService sharedInstance].folder = [PFObject versionedObjectWithClassName:kDriveFolderClass];
                                                 self.jointFolder[kDriveFolderIDKey] = newFolder.identifier;
                                                 self.jointFolder[kDriveFolderNameKey] = folderName;
                                                 self.jointFolder[kUsersKey] = [User currentUser].userIDs;
                                                 self.jointFolder[kDriveFolderOwnerIDKey] = [User currentUser].myUserID;
                                                 self.jointFolder[kDriveFolderOwnerUserEmailKey] = [User currentUser].myGoogleDriveUserEmail;
                                                 [User currentUser].googleDriveFolderOwner = [User currentUser].myUserID;
                                                 self.jointFolder[kDriveFolderSharedKey] = [NSNumber numberWithBool:NO];
                                                 self.navigationItem.title = folderName;
                                                 
                                                 // Wait for folder permission result to save to Parse
                                                 self.folderID = newFolder.identifier;
                                                 
                                                 if ([User currentUser].partnerGoogleDriveUserEmail) {
                                                   
                                                   self.jointFolder[kDriveFolderPartnerIDKey] = [User currentUser].partnerUserID;
                                                   self.jointFolder[kDriveFolderPartnerUserEmailKey] = [User currentUser].partnerGoogleDriveUserEmail;
                                                   
                                                   [self addPermission];
                                                 } else {
                                                   GoogleEmailViewController *vc = [[GoogleEmailViewController alloc] initWithDelegate:self mode:GoogleEmailModeCalendarPartner];
                                                   SHNavigationController* nav = [[SHNavigationController alloc] initWithRootViewController:vc];
                                                   [self presentViewController:nav animated:YES completion:NULL];
                                                 }
                                               }
                                               
                                             } else {
                                               NSLog(@"An error occurred: %@", error);
                                               if (parentFolderID == nil) {
                                                 // failed
                                                 self.jointFolder[kDriveFolderSharedKey] = @(NO);
                                                 // Save folder to Parse if possible
                                                 [self.jointFolder saveInBackgroundElseEventually];
                                               }
                                               
                                               if (parentFolderID && [self jointFolderDeleted:error]) {
                                                 [self handleJointFolderDeletion];
                                               } else {
                                                 UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                                                                message:@"Unable to create folder at this time. Please try later."
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
                                             [self refreshTableViewSource];
                                           }];
}

-(void)renameButtonPressed {
  self.alert = [[PSPDFAlertView alloc] initWithTitle:nil
                                             message:@"Please enter the new name:"];
  self.alert.alertViewStyle = UIAlertViewStylePlainTextInput;
  [self.alert setCancelButtonWithTitle:@"Cancel" block:nil];
  __block DriveFilesListController *weakSelf = self;
  [self.alert addButtonWithTitle:@"OK"
                           block:^(NSInteger buttonIndex) {
                             [weakSelf checkName:[weakSelf.alert textFieldAtIndex:0]
                                     forCreation:NO
                                  parentFolderID:weakSelf.folderID];
                           }];
  [[self.alert textFieldAtIndex:0] setDelegate:self];
  [self.alert show];
}

-(void)deleteButtonPressed {
  PSPDFAlertView *alert = [[PSPDFAlertView alloc] initWithTitle:@"Delete Item"
                                                        message:[NSString stringWithFormat:@"%@ will be deleted.",self.selectedFile.title]];
  
  [alert setCancelButtonWithTitle:@"Cancel" block:nil];
  [alert addButtonWithTitle:@"Delete" block:^(NSInteger buttonIndex) {
    [[DriveService sharedInstance] deleteFileWithIdentifier:self.selectedFile.identifier
                                            completionBlock:^(GTLDriveFile *deleteFile, NSError *error) {
                                              if (error) {
                                                [SVProgressHUD showErrorWithStatus:@"Unable to delete item at this time"];
                                              } else {
                                                // just delete locally (server delete could take a few seconds)
                                                NSMutableArray *driveFiles = [NSMutableArray arrayWithArray:self.driveFiles];
                                                [driveFiles removeObject:self.selectedFile];
                                                self.driveFiles = [NSArray arrayWithArray:driveFiles];
                                                [self configureTableViewHeader];
                                                [self.tableView reloadData];
                                              }
                                            }];
  }];
  [alert show];
  
}

-(void)renameDriveFile:(NSString *)fileName {
  if (self.selectedFile.fileExtension &&
      ! [self.selectedFile.fileExtension isEqualToString:@""] ) {
    // file has extension
    if (! [fileName hasSuffix:[NSString stringWithFormat:@".%@",self.selectedFile.fileExtension]] ) {
      fileName = [NSString stringWithFormat:@"%@.%@", fileName, self.selectedFile.fileExtension];
    }
  }
  
  // Send the request to the API.
  self.selectedFile.title = fileName;
  
  [[DriveService sharedInstance] updateFile:self.selectedFile
                            completionBlock:^(GTLDriveFile *updatedFile, NSError *error) {
                              [self refreshTableViewSource];
                              if (error) {
                                [SVProgressHUD showErrorWithStatus:@"Unable to rename item"];
                              }
                            }];
}

#pragma mark Drive add permission
-(void)addPermission {
  if ( ! [User currentUser].partnerGoogleDriveUserEmail ||
      [User currentUser].partnerGoogleDriveUserEmail.length == 0 ) {
    GoogleEmailViewController *vc = [[GoogleEmailViewController alloc] initWithDelegate:self mode:GoogleEmailModeCalendarPartner];
    SHNavigationController* nav = [[SHNavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:NULL];
  } else {
    [[DriveService sharedInstance] addPermissionForEmail:[User currentUser].partnerGoogleDriveUserEmail
                                         completionBlock:^(id object, NSError *error) {
                                           [self refreshTableViewSource];
                                         }];
  }
}

#pragma mark utility functions
-(void)checkName:(UITextField *)textField forCreation:(BOOL)create parentFolderID:(NSString *)parentFolderID {
  if ([textField.text isEqualToString:@""]) {
    self.alert = [[PSPDFAlertView alloc] initWithTitle:nil
                                               message:@"Invalid name. Please enter a new name:"];
    self.alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    __block DriveFilesListController *weakSelf = self;
    [self.alert setCancelButtonWithTitle:@"OK"
                                   block:^(NSInteger buttonIndex) {
                                     [weakSelf checkName:[weakSelf.alert textFieldAtIndex:0]
                                             forCreation:create
                                          parentFolderID:parentFolderID];
                                   }];
    [[self.alert textFieldAtIndex:0] setDelegate:self];
    [self.alert show];
  } else {
    if (create) {
      [self createDriveFolderWithName:textField.text parentFolderID:parentFolderID];
    } else {
      [self renameDriveFile:textField.text];
    }
  }
}

-(BOOL)jointFolderIsShared {
  NSString *partnerUserEmail = self.jointFolder[kDriveFolderPartnerUserEmailKey];
  
  if ( [self.jointFolder[kDriveFolderSharedKey] boolValue] == NO ) {
    return NO;
  } else if ( [self isFolderOwner] &&
             ! [partnerUserEmail isEqualToInsensitive:[User currentUser].partnerGoogleDriveUserEmail] ) {
    return NO;
  } else {
    return YES;
  }
  
}

-(BOOL)isFolderOwner {
  [User currentUser].googleDriveFolderOwner = self.jointFolder[kDriveFolderOwnerIDKey];
  return [[User currentUser].myUserIDs containsObject:self.jointFolder[kDriveFolderOwnerIDKey]];
}

-(BOOL)jointFolderDeleted:(NSError *)error {
  if (error.code == 404 &&
      [error.localizedDescription rangeOfString:self.jointFolder[kDriveFolderIDKey]].location != NSNotFound) {
    return YES;
  } else {
    return NO;
  }
  
}

-(void)handleJointFolderDeletion {
  if ( ! self.deletedErrorShown ) {
    self.deletedErrorShown = YES;
    NSString *alertMessage = [self isFolderOwner] ?
    @"Unable to retreive your shared Google Drive folder.  If the problem persists, you can reset your Google Drive folder in the the Settings menu." :
    @"Unable to retreive your shared Google Drive folder.  If the problem persists, your partner can reset your Google Drive folder in the the Settings menu.";
    
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


-(void)configureTableViewHeader {
  if (self.driveFiles.count == 0) {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.f, 60.f, self.tableView.frameSizeWidth, self.tableView.frameSizeHeight - 60.f)];
    label.text = @"No files yet.\nPress '+' to upload a file.";
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 0;
    label.font = [UIFont fontWithName:@"Copperplate-Bold" size:20.0];
    label.textColor = [UIColor lightGrayColor];
    label.backgroundColor = self.tableView.backgroundColor;
    
    self.tableView.tableHeaderView = label;
  } else {
    self.tableView.tableHeaderView = nil;
  }
}

#pragma mark Action Sheet delegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
  NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
  
  if (actionSheet.tag == kPhotoActionSheetTag) {
    if ([buttonTitle isEqualToString:kActionTakePhoto]) {
      [self takePhotoButtonPressed];
    } else if ([buttonTitle isEqualToString:kActionChooseFromLibrary]) {
      [self choosePhotoButtonPressed];
    }
  } else if (actionSheet.tag == kVideoActionSheetTag) {
    if ([buttonTitle isEqualToString:kActionTakeVideo]) {
      [self takeVideoButtonPressed];
    } else if ([buttonTitle isEqualToString:kActionChooseFromLibrary]) {
      [self chooseVideoButtonPressed];
    }
  } else if (actionSheet.tag == kFileActionSheetTag) {
    if ([buttonTitle isEqualToString:kActionRename]) {
      [self renameButtonPressed];
    } else if ([buttonTitle isEqualToString:kActionDelete]) {
      [self deleteButtonPressed];
    } else if ( [buttonTitle isEqualToString:kActionSavePhoto] ) {
      [[DriveService sharedInstance] downloadFile:self.selectedFile statusMessage:@"Saving..." withCompletionBlock:^(NSData *data, NSError *error) {
        if ( ! error ) {
          UIImage *image = [UIImage imageWithData:data];
          UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
        } else {
          UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                         message:@"There was a problem saving the photo. Please try later."
                                                                  preferredStyle:UIAlertControllerStyleAlert];
          [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                    style:UIAlertActionStyleCancel
                                                  handler:nil]];
          [self presentViewController:alert
                             animated:YES
                           completion:nil];
        }
      }];
    } else if ( [buttonTitle isEqualToString:kActionSaveVideo] ) {
      [[DriveService sharedInstance] downloadFile:self.selectedFile statusMessage:@"Saving..." withCompletionBlock:^(NSData *data, NSError *error) {
        if ( ! error ) {
          NSURL *movieURL =[NSURL fileURLWithPath:pathInCachesDirectory(self.selectedFile.title)];
          [data writeToURL:movieURL atomically:YES];
          
          ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
          
          if ( [library videoAtPathIsCompatibleWithSavedPhotosAlbum:movieURL] ) {
            [library writeVideoAtPathToSavedPhotosAlbum:movieURL
                                        completionBlock:^(NSURL *assetURL, NSError *error){
                                          if (error) {
                                            UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                                                           message:@"There was an error saving the video. Please try later."
                                                                                                    preferredStyle:UIAlertControllerStyleAlert];
                                            [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                                                      style:UIAlertActionStyleCancel
                                                                                    handler:nil]];
                                            [self presentViewController:alert
                                                               animated:YES
                                                             completion:nil];
                                          }
                                        }];
          } else {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                           message:@"There was an error saving the video. Please try later."
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                      style:UIAlertActionStyleCancel
                                                    handler:nil]];
            [self presentViewController:alert
                               animated:YES
                             completion:nil];
          }
        } else {
          UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                         message:@"There was an error saving the video. Please try later."
                                                                  preferredStyle:UIAlertControllerStyleAlert];
          [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                    style:UIAlertActionStyleCancel
                                                  handler:nil]];
          [self presentViewController:alert
                             animated:YES
                           completion:nil];
        }
      }];
    }
  }
}

#pragma mark photo video functions
-(void)takePhotoButtonPressed {
  UIImagePickerController *imgPicker = [[UIImagePickerController alloc] init];
  imgPicker.delegate = self;
  if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
    imgPicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    [self presentViewController:imgPicker animated:NO completion:NULL];
  } else {
    UIAlertView *noPhotoAlert = [[UIAlertView alloc] initWithTitle:nil message:@"Sorry, your device is unable to take photos" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [noPhotoAlert show];
  }
  
}

-(void)choosePhotoButtonPressed {
  UIImagePickerController *imgPicker = [[UIImagePickerController alloc] init];
  imgPicker.delegate = self;
  if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
    imgPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:imgPicker animated:NO completion:NULL];
  } else {
    UIAlertView *noPhotoAlert = [[UIAlertView alloc] initWithTitle:nil message:@"Sorry, your device does not support photos" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [noPhotoAlert show];
    
  }
  
}

-(void)takeVideoButtonPressed {
  UIImagePickerController *imgPicker = [[UIImagePickerController alloc] init];
  imgPicker.delegate = self;
  if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] &&
      [[UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera] indexOfObjectIdenticalTo:(NSString *)kUTTypeMovie] != NSNotFound) {
    imgPicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    imgPicker.mediaTypes = [[NSArray alloc] initWithObjects:(NSString *)kUTTypeMovie, nil];
    [self presentViewController:imgPicker animated:NO completion:NULL];
  } else {
    UIAlertView *noVideoAlert = [[UIAlertView alloc] initWithTitle:nil message:@"Sorry, your device is unable to capture video" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [noVideoAlert show];
  }
}

-(void)chooseVideoButtonPressed {
  UIImagePickerController *imgPicker = [[UIImagePickerController alloc] init];
  imgPicker.delegate = self;
  if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary] &&
      [[UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypePhotoLibrary] indexOfObjectIdenticalTo:(NSString *)kUTTypeMovie] != NSNotFound) {
    imgPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imgPicker.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *)kUTTypeMovie, nil];
    [self presentViewController:imgPicker animated:NO completion:NULL];
  } else {
    UIAlertView *noVideoAlert = [[UIAlertView alloc] initWithTitle:nil message:@"Sorry, your device does not support video" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [noVideoAlert show];
  }
  
}

#pragma mark Image Picker functions
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
  NSString* mediaType = [info objectForKey:UIImagePickerControllerMediaType];
  
  if ([mediaType isEqualToString:(NSString *)kUTTypeImage]) {
    // photo
    [UIApplication sharedApplication].statusBarHidden = NO;
    
    UIImage *chosenImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    CLImageEditor *editor = [[CLImageEditor alloc] initWithImage:chosenImage];
    editor.delegate = self;
    [picker presentViewController:editor animated:YES completion:nil];
    
  } else {
    // video
    NSURL *chosenVideoURL = [info objectForKey:UIImagePickerControllerMediaURL];
    
    // Now upload video
    // Video name
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM_dd_yyyy-hh.mm.ss_a"];
    
    NSString *result_str = [dateFormatter stringFromDate:[NSDate date]];
    NSString *videoName = [NSString stringWithFormat:@"Video-%@.%@",result_str,[chosenVideoURL pathExtension]];
    
    [self dismissViewControllerAnimated:NO completion:NULL];
    
    [[DriveService sharedInstance] uploadVideoWithData:[NSData dataWithContentsOfURL:chosenVideoURL] videoName:videoName withParentFolderIdentifier:self.folderID completionBlock:^(GTLDriveFile *insertedFile, NSError *error) {
      if (error == nil) {
        [SVProgressHUD showSuccessWithStatus:@"Success"];
        [self refreshTableViewSource];
        // send push notification
        NSString *pushMessage = [NSString stringWithFormat:@"%@ uploaded a video to Google Drive.", [[User currentUser] myNameOrEmail]];
        NSDictionary *pushUserInfo = @{@"alert" : pushMessage,
                                       @"sound" : @"default",
                                       kPushTypeKey : kDriveUploadNotification,
                                       @"badge" : @"Increment"};
        [SHUtil sendPushNotification:pushUserInfo];
        
      } else {
        if ([self jointFolderDeleted:error]) {
          [self handleJointFolderDeletion];
        } else {
          [SVProgressHUD showErrorWithStatus:@"Unable to upload video"];
        }
      }
    }];
    
    [SVProgressHUD showWithStatus:@"Uploading video..."];
  }
  
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
  [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark CLImageEditorDelegate
- (void)imageEditorDidCancel:(CLImageEditor*)editor {
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imageEditor:(CLImageEditor*)editor didFinishEdittingWithImage:(UIImage*)image {
  // Photo name
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  [dateFormatter setDateFormat:@"MM_dd_yyyy-hh.mm.ss_a"];
  
  NSString *result_str = [dateFormatter stringFromDate:[NSDate date]];
  NSString *photoName = [NSString stringWithFormat:@"Photo-%@.jpg",result_str];
  
  [self dismissViewControllerAnimated:NO completion:NULL];
  
  [[DriveService sharedInstance] uploadPhotoWithData:UIImagePNGRepresentation(image)
                                           photoName:photoName
                          withParentFolderIdentifier:self.folderID
                                     completionBlock:^(GTLDriveFile *insertedFiled, NSError *error) {
                                       if (error == nil) {
                                         [SVProgressHUD showSuccessWithStatus:@"Success"];
                                         [self refreshTableViewSource];
                                         
                                         // send push notification
                                         NSString *pushMessage = [NSString stringWithFormat:@"%@ uploaded a photo to Google Drive.", [[User currentUser] myNameOrEmail]];
                                         NSDictionary *pushUserInfo = @{@"alert" : pushMessage,
                                                                        @"sound" : @"default",
                                                                        kPushTypeKey : kDriveUploadNotification,
                                                                        @"badge" : @"Increment"};
                                         [SHUtil sendPushNotification:pushUserInfo];
                                         
                                       } else {
                                         if ([self jointFolderDeleted:error]) {
                                           [self handleJointFolderDeletion];
                                         } else {
                                           [SVProgressHUD showErrorWithStatus:@"Unable to upload photo"];
                                         }
                                       }
                                     }];
  
  [SVProgressHUD showWithStatus:@"Uploading photo..."];
  
}


+(BOOL)isImage:(GTLDriveFile *)file {
  static NSArray *supported = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    supported =  @[@"tiff", @"tif", @"jpg", @"jpeg", @"gif", @"png", @"bmp", @"bmpf", @"ico", @"cur", @"xbm"];
  });
  
  return [supported containsObject:[file.fileExtension lowercaseString]];
}

+(BOOL)isAudio:(GTLDriveFile*)file {
  static NSArray *supported = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    supported = @[@"aac", @"adts", @"ac3", @"aif", @"aiff", @"aifc", @"caf", @"mp3", @"mp4", @"m4a", @"snd", @"au", @"sd2", @"wav"];
  });
  return [supported containsObject:[file.fileExtension lowercaseString]];
}

+(BOOL)isVideo:(GTLDriveFile*)file {
  static NSArray *supported = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    supported = @[@"mov", @"mp4", @"mpv", @"3gp"];
  });
  
  return [supported containsObject:[file.fileExtension lowercaseString]];
}

#pragma mark loading functions
-(void)showLoadingViews {
  
  if ( ! self.loadingView ) {
    self.loadingView = [[UIView alloc] initWithFrame:CGRectMake(0.f,
                                                                self.view.frameSizeHeight/2.0-25.0,
                                                                [UIScreen mainScreen].bounds.size.width,
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

-(void)removeLoadingViews {
  if ( self.isRoot ) {
    self.navigationItem.rightBarButtonItem.enabled = [DriveService sharedInstance].gtlDriveService.authorizer != nil;
    self.uploadButton.tintColor = self.navigationItem.rightBarButtonItem.enabled ? [SHPalette darkNavyBlue] : [UIColor lightGrayColor];
  }
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

#pragma mark notification handler
-(void)handleDriveRefreshFilesNotification {
  if ( !self.tableView.hidden ) {
    [self refreshTableViewSource];
  }
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
  label.text = @"Shared creates a shared Google Drive folder where you and your partner can store shared documents, including photos, videos and more.";
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
#pragma mark UITextFieldDelegate
// Enable the return key on the alert view.
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [self.alert dismissWithClickedButtonIndex:1 animated:YES];
  return YES;
}

#pragma photo detail methods
- (void)presentPhotoDetailViewForImage:(UIImage *)image {
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(dismissPhotoDetailView)
                                               name:kDismissPhotoDetailViewNotification
                                             object:nil];
  image = [kAppDelegate scaleAndRotateImage:image maxResolution:640];
  PhotoDetailController *photoDetailVC = [[PhotoDetailController alloc] initWithImage:image andFrame:self.view.bounds];
  photoDetailVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
  photoDetailVC.modalPresentationStyle = UIModalPresentationFullScreen;
  [self presentViewController:photoDetailVC animated:YES completion:NULL];
}

- (void)dismissPhotoDetailView {
  [self dismissViewControllerAnimated:YES completion:NULL];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:kDismissPhotoDetailViewNotification object:nil];
}

#pragma mark GoogleEmailViewControllerDelegate
- (void)controllerDidChooseEmail:(NSString *)email controller:(GoogleEmailViewController *)controller {
  [self dismissViewControllerAnimated:YES completion:nil];
  
  [User currentUser].partnerGoogleDriveUserEmail = [email lowercaseString];
  [[User currentUser] saveToNetwork];
  
  self.jointFolder[kGoogleCalendarPartnerIDKey] = [User currentUser].partnerUserID;
  self.jointFolder[kGoogleCalendarPartnerUserEmailKey] = [email lowercaseString];
  [self.jointFolder saveInBackgroundElseEventually];
  
  [self addPermission];
  
}

- (void)controllerDidCancel:(GoogleEmailViewController *)controller {
  [self dismissViewControllerAnimated:YES completion:nil];
  [kAppDelegate showTextController];
}

@end

