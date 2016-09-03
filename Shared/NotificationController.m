//
//  NotificationController.m
//  Shared
//
//  Created by Brian Bernberg on 7/14/13.
//  Copyright (c) 2013 BB Consulting. All rights reserved.
//

#import "NotificationController.h"
#import "NotificationRetriever.h"
#import "SharedController.h"
#import "SORelativeDateTransformer.h"
#import "OHAttributedStringAdditions.h"
#import <MMDrawerController/MMDrawerBarButtonItem.h>
#import <MMDrawerController/UIViewController+MMDrawerController.h>

@interface NotificationController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray* selectableNotificationTypes;
@property (nonatomic, strong) NSArray* notificationTypesToDelete;
@property (nonatomic, weak) id<NotificationControllerDelegate> delegate;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, readonly) CGFloat labelWidth;
@property (nonatomic) UILabel *noNotificationsLabel;
@end

@implementation NotificationController

- (instancetype)initWithDelegate:(id<NotificationControllerDelegate>)delegate {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    // Custom initialization
    _delegate = delegate;
    _selectableNotificationTypes = @[kFBUploadNotification,
                                     kListNotification,
                                     kGoogleCalendarNotification,
                                     kTextNotification,
                                     kDriveUploadNotification];
    _notificationTypesToDelete = @[];
    
    _dateFormatter = [[NSDateFormatter alloc] init];
    [_dateFormatter setDateFormat:@"h:mma MM/dd/yy"];
    
    self.title = @"Notifications";
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTableView) name:kUpdateNotificationButtonNotification object:nil];
    
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [[NSUserDefaults standardUserDefaults] setObject:@(SharedControllerTypeNotifications) forKey:kCurrentSharedControllerType];
  [[NSUserDefaults standardUserDefaults] synchronize];

  self.view.backgroundColor = [SHPalette backgroundColor];
  
  self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
  self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  self.tableView.dataSource = self;
  self.tableView.delegate = self;
  self.tableView.backgroundColor = [SHPalette backgroundColor];
  [self.view addSubview:self.tableView];
  
  self.noNotificationsLabel = [[UILabel alloc] initWithFrame:CGRectMake(20.f, 0.f, self.view.frameSizeWidth - 40.f, self.view.frameSizeHeight)];
  self.noNotificationsLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  self.noNotificationsLabel.textAlignment = NSTextAlignmentCenter;
  self.noNotificationsLabel.text = @"There are no notifications.";
  self.noNotificationsLabel.numberOfLines = 0;
  self.noNotificationsLabel.font = [UIFont fontWithName:@"Copperplate-Bold" size:20.0];
  self.noNotificationsLabel.textColor = [UIColor lightGrayColor];
  self.noNotificationsLabel.hidden = [[NotificationRetriever instance].notifications count] > 0;
  [self.view addSubview:self.noNotificationsLabel];
  
  // left button
  self.navigationItem.leftBarButtonItem = [[MMDrawerBarButtonItem alloc] initWithTarget:self action:@selector(drawerButtonPressed)];
  
}

-(void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear: animated];
  for (NSString *notificationType in self.notificationTypesToDelete) {
    [[NotificationRetriever instance] deleteNotificationsOfType:notificationType];
  }
}

-(void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark getters/setters
- (CGFloat)labelWidth {
  return [[UIScreen mainScreen] bounds].size.width - 40.f;
}

#pragma mark - Table view data source

#define kNotificationLabelTag 100

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [[NotificationRetriever instance].notifications count];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  PFObject *notification = [NotificationRetriever instance].notifications[indexPath.row];
  NSAttributedString *string = [self attributedStringForNotification:notification];
  CGSize size = [string sizeConstrainedToSize:CGSizeMake(self.labelWidth, CGFLOAT_MAX)];
  
  return size.height + 20.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  return 1.f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *CellIdentifier = @"Cell";
  UILabel *label;
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"notificationCell"];
  if ( !cell ) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    
    label = [[UILabel alloc] init];
    label.numberOfLines = 0;
    label.backgroundColor = [UIColor clearColor];
    label.tag = kNotificationLabelTag;
    [cell.contentView addSubview:label];
    
  }
  
  label = (UILabel *)[cell viewWithTag:kNotificationLabelTag];
  PFObject *notification = [NotificationRetriever instance].notifications[indexPath.row];
  
  label.attributedText = [self attributedStringForNotification: notification];
  CGSize size = [label.attributedText sizeConstrainedToSize:CGSizeMake(self.labelWidth, CGFLOAT_MAX)];
  label.frame = CGRectMake(15.f, 10.f, self.labelWidth, size.height);
  
  if ([self.selectableNotificationTypes containsObject:notification[kPushTypeKey]]) {
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
  } else {
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
  }
  return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  PFObject *notification = [NotificationRetriever instance].notifications[indexPath.row];
  [self.delegate didSelectNotificationType:notification[kPushTypeKey]];
}

-(void)reloadTableView {
  self.noNotificationsLabel.hidden = [[NotificationRetriever instance].notifications count] > 0;
  [self.tableView reloadData];
}

#pragma mark Utility methods
-(NSMutableAttributedString *)attributedStringForNotification:(PFObject *)notification {
  NSString *message = [NSString stringWithFormat:@"%@\n", notification[kNotificationMessageKey]];
  NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:message];
  [attrString setTextColor:[UIColor blackColor]];
  [attrString setFont: [kAppDelegate globalFontWithSize:16.0]];
  
  SORelativeDateTransformer *relativeDateTransformer = [[SORelativeDateTransformer alloc] init];
  NSString *date = [relativeDateTransformer transformedValue:notification.createdAt];
  NSMutableAttributedString *dateString = [[NSMutableAttributedString alloc] initWithString:date];
  [dateString setTextColor:[UIColor lightGrayColor]];
  [dateString setFont:[kAppDelegate globalFontWithSize:16.0]];
  [attrString appendAttributedString:dateString];
  
  return attrString;
}

- (void)drawerButtonPressed {
  [[self mm_drawerController] toggleDrawerSide:MMDrawerSideLeft animated:YES completion:NULL];
}

@end
