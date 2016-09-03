//
//  CalendarEventViewController.m
//  Shared
//
//  Created by Brian Bernberg on 1/28/13.
//  Copyright (c) 2013 BB Consulting. All rights reserved.
//

#import "CalendarEventController.h"
#import "OHAttributedStringAdditions.h"
#import "User.h"
#import "Constants.h"
#import "CalendarEventEditController.h"
#import "CalendarService.h"
#import "NSString+SHString.h"

static const CGFloat kDayTimeInterval = 86000.0;

@interface CalendarEventController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) GTLCalendarEvent *event;
@property (nonatomic, strong) NSMutableArray *rowMap;
@end

@implementation CalendarEventController

- (id)initWithEvent:(GTLCalendarEvent*)event {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    // Custom initialization
    self.event = event;
    [self calculateRowMap];
    
  }
  return self;
}

-(void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view from its nib.
  self.view.backgroundColor = [SHPalette backgroundColor];
  self.tableView.backgroundColor = [SHPalette backgroundColor];
  self.tableView.backgroundView = nil;
  self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 20)];
  self.navigationItem.title = @"Event Details";
  // right button
  UIBarButtonItem * editBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                                                      target:self
                                                                                      action:@selector(editButtonPressed)];
  self.navigationItem.rightBarButtonItem = editBarButtonItem;
  
}

-(void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  [self refreshTableView];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void)refreshTableView {
  [self calculateRowMap];
  [self.tableView reloadData];
}

#pragma mark row map
enum {
  SHMainCell,
  SHLocationCell,
  SHAttendeesCell,
  SHRemindersCell
};

- (void)calculateRowMap {
  self.rowMap = [NSMutableArray array];
  [self.rowMap addObject:@(SHMainCell)];
  
  if ( self.event.location && self.event.location.length > 0 ) {
    [self.rowMap addObject:@(SHLocationCell)];
  }
  
  if (self.event.creator) {
    [self.rowMap addObject:@(SHAttendeesCell)];
  }
  if (self.event.reminders.overrides) {
    [self.rowMap addObject:@(SHRemindersCell)];
  }
}

#pragma mark button actions
-(void)editButtonPressed {
  CalendarEventEditController *vc = [[CalendarEventEditController alloc] initWithEvent:self.event
                                                                                  date:nil];
  SHNavigationController *nav = [[SHNavigationController alloc] initWithRootViewController:vc];
  [self presentViewController:nav animated:YES completion:nil];
}

#pragma mark UITableViewDataSource protocol conformance

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *identifier = @"MyCell";
  UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
  cell.contentView.backgroundColor = [UIColor whiteColor];
  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  cell.separatorInset = UIEdgeInsetsZero;
  
  switch ( [self.rowMap[indexPath.row] integerValue] ) {
    case SHMainCell: {
      UILabel *cellLabel = [[UILabel alloc] initWithFrame: CGRectMake(10, 10, 280, 40)];
      cellLabel.numberOfLines = 0;
      cellLabel.backgroundColor = [UIColor clearColor];
      [cell.contentView addSubview:cellLabel];
      
      NSMutableAttributedString *cellString = [self attributedStringForEventSummaryCell:self.event];
      CGRect labelFrame = cellLabel.frame;
      labelFrame.size.height = [cellString sizeConstrainedToSize: CGSizeMake(280, CGFLOAT_MAX)].height;
      cellLabel.frame = labelFrame;
      cellLabel.attributedText = cellString;
    } break;
    case SHLocationCell: {
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      cell.selectionStyle = UITableViewCellSelectionStyleDefault;
      cell.textLabel.font = [UIFont systemFontOfSize:14.f];
      cell.textLabel.text = self.event.location;
      cell.textLabel.textColor = [UIColor grayColor];
      cell.textLabel.numberOfLines = 0;
      UIImage *image = [UIImage imageNamed:@"Location"];
      image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
      cell.imageView.image = image;
      cell.imageView.tintColor = [UIColor grayColor];
    } break;
    case SHAttendeesCell: {
      // Attendees
      NSMutableAttributedString* attrStr = [[NSMutableAttributedString alloc] initWithString: @"Organizer"];
      [attrStr setFont: [kAppDelegate globalBoldFontWithSize: 15.0]];
      [attrStr setTextColor: [UIColor blackColor]];
      [attrStr setTextAlignment:NSTextAlignmentLeft];
      [attrStr setLineBreakMode:NSLineBreakByWordWrapping];
      UILabel *cellLabel = [[UILabel alloc] initWithFrame: CGRectMake(10, 10, 280, 40)];
      cellLabel.backgroundColor = [UIColor clearColor];
      [cell.contentView addSubview:cellLabel];
      cellLabel.attributedText = attrStr;
      CGRect labelFrame = cellLabel.frame;
      labelFrame.size.height = [attrStr sizeConstrainedToSize: CGSizeMake(280, CGFLOAT_MAX)].height;
      cellLabel.frame = labelFrame;
      
      CGFloat currentY = labelFrame.origin.y + labelFrame.size.height + 4.0;
      UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake(10,
                                                                      currentY,
                                                                      30,
                                                                      30)];
      if ([self.event.creator.email isEqualToInsensitive:[User currentUser].myGoogleCalendarUserEmail] &&
          [[User currentUser] myPictureExists]) {
        iv.image = [User currentUser].mySmallPicture;
        [cell.contentView addSubview:iv];
        currentY += iv.frame.size.height + 4.0;
      } else if ([self.event.creator.email isEqualToInsensitive:[User currentUser].partnerGoogleCalendarUserEmail] &&
                 [[User currentUser] partnerPictureExists]) {
        iv.image = [User currentUser].partnerSmallPicture;
        [cell.contentView addSubview:iv];
        currentY += iv.frame.size.height + 4.0;
      } else {
        UILabel *organizerLabel = [[UILabel alloc] initWithFrame:CGRectMake(10,
                                                                            currentY,
                                                                            280,
                                                                            18.0)];
        organizerLabel.font = [kAppDelegate globalFontWithSize:15.0];
        organizerLabel.textColor = [UIColor darkGrayColor];
        organizerLabel.text = self.event.creator.email;
        [cell.contentView addSubview: organizerLabel];
        currentY += 24.0;
      }
      
      // Attendees
      // Sort into buckets
      NSMutableArray *accepted = [NSMutableArray array];
      NSMutableArray *noReply = [NSMutableArray array];
      NSMutableArray *tentative = [NSMutableArray array];
      NSMutableArray *declined = [NSMutableArray array];
      
      for (GTLCalendarEventAttendee *attendee in self.event.attendees) {
        if (attendee.selfProperty) {
          continue;
        }
        if ([attendee.responseStatus isEqualToInsensitive:@"accepted"]) {
          [accepted addObject:attendee];
        } else if ([attendee.responseStatus isEqualToInsensitive:@"tentative"]) {
          [tentative addObject:attendee];
        } else if ([attendee.responseStatus isEqualToInsensitive:@"declined"]) {
          [declined addObject:attendee];
        } else {
          [noReply addObject:attendee];
        }
      }
      
      if (accepted.count > 0) {
        currentY = [self displayAttendeesList:accepted
                                         cell:cell
                                    listTitle:@"Accepted"
                                     currentY:currentY];
      }
      if (noReply.count > 0) {
        currentY = [self displayAttendeesList:noReply
                                         cell:cell
                                    listTitle:@"No Reply"
                                     currentY:currentY];
        
      }
      if (tentative.count > 0) {
        currentY = [self displayAttendeesList:tentative
                                         cell:cell
                                    listTitle:@"Tentative"
                                     currentY:currentY];
        
      }
      if (declined.count > 0) {
        currentY = [self displayAttendeesList:declined
                                         cell:cell
                                    listTitle:@"Declined"
                                     currentY:currentY];
        
      }
    } break;
    case SHRemindersCell: {
      UILabel *cellLabel = [[UILabel alloc] initWithFrame: CGRectMake(10, 10, tableView.frameSizeWidth - 40.f, 40)];
      cellLabel.numberOfLines = 0;
      cellLabel.backgroundColor = [UIColor clearColor];
      [cell.contentView addSubview:cellLabel];
      
      NSMutableAttributedString *cellString = [self attributedStringForRemindersCell:self.event];
      CGRect labelFrame = cellLabel.frame;
      labelFrame.size.height = [cellString sizeConstrainedToSize: CGSizeMake(tableView.frameSizeWidth - 40.f, CGFLOAT_MAX)].height;
      cellLabel.frame = labelFrame;
      cellLabel.attributedText = cellString;
    } break;
    default:
      break;
  }
  
  return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  switch ( [self.rowMap[indexPath.row] integerValue] ) {
    case SHMainCell: {
      NSMutableAttributedString *cellString = [self attributedStringForEventSummaryCell:self.event];
      return ([cellString sizeConstrainedToSize: CGSizeMake(280, CGFLOAT_MAX)].height + 20);
    } break;
    case SHLocationCell: {
      CGFloat height = [self.event.location heightForStringUsingWidth:(self.tableView.frame.size.width - 100.f) andFont:[UIFont systemFontOfSize:14.f]] + 20.f;
      return MAX(height, 50.f);
    } break;
    case SHAttendeesCell: {
      return [self heightForAttendeesCell];
    } break;
    case SHRemindersCell: {
      NSMutableAttributedString *cellString = [self attributedStringForRemindersCell:self.event];
      return ([cellString sizeConstrainedToSize: CGSizeMake(tableView.frameSizeWidth - 40.f, CGFLOAT_MAX)].height + 20);
    } break;
    default:
      return 44.0;
  }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  NSUInteger rowCount = 1;
  
  if ( self.event.location && self.event.location.length > 0 ) {
    rowCount++;
  }
  if (self.event.creator) {
    rowCount++;
  }
  if (self.event.reminders.overrides) {
    rowCount++;
  }
  return rowCount;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  return 1.0;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  return [UIView new];
}

-(UIView *)tableView:(UITableView *)theTableView viewForFooterInSection:(NSInteger)section {
#ifdef kUsePartnerInvites
  if ([self.event.creator.email isEqualToInsensitive:[User currentUser].myGoogleCalendarUserEmail] &&
      ![self partnerIsAttending]) {
    UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, theTableView.frame.size.width, 100.0)];
    footer.backgroundColor = [UIColor clearColor];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0, 10, theTableView.frame.size.width, 44);
    button.backgroundColor = [UIColor blackColor];
    button.titleLabel.font = [UIFont fontWithName:@"CopperPlate" size:20.0];
    [button setTitle:@"Invite Partner" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(invitePartnerButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [button setBackgroundImage:[UIImage imageNamed:@"GrayBackground"] forState:UIControlStateHighlighted];
    [footer addSubview:button];
    return footer;
  } else {
    return [UIView new];
  }
#else
  return [UIView new];
#endif
  
}

#pragma mark UITableViewDelegate
-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
#ifdef kUsePartnerInvites
  if ([self.event.creator.email isEqualToInsensitive:[User currentUser].myGoogleCalendarUserEmail] &&
      ![self partnerIsAttending]) {
    return 100.0;
  } else {
    return 1.0;
  }
#endif
  return 1.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  
  if ([self.rowMap[indexPath.row] integerValue] == SHLocationCell) {
    NSString *locationQuery;
    NSURL *locationURL;
    
    if ( [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"comgooglemaps:"]] ) {
      // Try Google maps
      locationQuery = [NSString stringWithFormat:@"comgooglemaps://?q=%@",[self.event.location stringByReplacingOccurrencesOfString:@" " withString:@"+"]];
      locationURL = [NSURL URLWithString:locationQuery];
    } else {
      // else use Apple maps
      locationQuery = [NSString stringWithFormat:@"http://maps.apple.com/?q=%@", [self.event.location stringByReplacingOccurrencesOfString:@" " withString:@"+"]];
      locationURL = [NSURL URLWithString:locationQuery];
    }
    
    [[UIApplication sharedApplication] openURL:locationURL];
  }
}

-(void)invitePartnerButtonPressed {
  [[CalendarService sharedInstance] invitePartnerToEvent:self.event];
  [self refreshTableView];
}

#pragma mark utility functions
-(NSMutableAttributedString *)attributedStringForEventSummaryCell:(GTLCalendarEvent*)event {
  NSMutableAttributedString *attrField;
  NSMutableAttributedString* newLine = [[NSMutableAttributedString alloc] initWithString:@"\n"];
  [newLine setFont: [UIFont systemFontOfSize: 14.0]];
  NSMutableAttributedString* smallNewLine = [[NSMutableAttributedString alloc] initWithString:@"\n"];
  [smallNewLine setFont: [UIFont systemFontOfSize: 6.0]];
  
  // Summary
  NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] init];
  if (event.summary) {
    NSString *summary = event.summary;
    attrField = [[NSMutableAttributedString alloc] initWithString: summary];
    [attrField setFont: [kAppDelegate globalBoldFontWithSize: 22.0]];
    [attrField setTextColor: [UIColor blackColor]];
    [attrField setTextAlignment:NSTextAlignmentLeft];
    [attrField setLineBreakMode: NSLineBreakByWordWrapping];
    [attrStr appendAttributedString:attrField];
    [attrStr appendAttributedString:newLine];
  }
  
  [attrStr appendAttributedString:smallNewLine];
  
  if (event.start.dateTime) {
    if ([self eventStartAndEndOnSameDay:event]) {
      NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
      [dateFormatter setDateFormat:@"EEEE, MMM d, y"];
      attrField = [[NSMutableAttributedString alloc] initWithString:[dateFormatter stringFromDate:event.start.dateTime.date]];
      [attrField setFont: [kAppDelegate globalFontWithSize: 15.0]];
      [attrField setTextColor:[UIColor darkGrayColor]];
      [attrField setTextAlignment:NSTextAlignmentLeft];
      [attrField setLineBreakMode: NSLineBreakByWordWrapping];
      
      [attrStr appendAttributedString:attrField];
      [attrStr appendAttributedString:newLine];
      
      // start time
      if (event.start.dateTime.dateComponents.minute == 0) {
        [dateFormatter setDateFormat:@"ha"];
      } else {
        [dateFormatter setDateFormat:@"h:mma"];
      }
      NSString *startTime = [dateFormatter stringFromDate:event.start.dateTime.date];
      // end time
      if (event.end.dateTime.dateComponents.minute == 0) {
        [dateFormatter setDateFormat:@"ha"];
      } else {
        [dateFormatter setDateFormat:@"h:mma"];
      }
      NSString *endTime = [dateFormatter stringFromDate:event.end.dateTime.date];
      
      attrField = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"from %@ to %@", startTime, endTime]];
      [attrField setFont: [kAppDelegate globalFontWithSize: 15.0]];
      [attrField setTextColor:[UIColor darkGrayColor]];
      [attrField setTextAlignment:NSTextAlignmentLeft];
      [attrField setLineBreakMode: NSLineBreakByWordWrapping];
      [attrStr appendAttributedString:attrField];
      [attrStr appendAttributedString:newLine];
    } else {
      NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
      
      // start time
      if (event.start.dateTime.dateComponents.minute == 0) {
        [dateFormatter setDateFormat:@"ha EEE, MMM d, y"];
      } else {
        [dateFormatter setDateFormat:@"h:mma EEE, MMM d, y"];
      }
      NSString *startTime = [dateFormatter stringFromDate:event.start.dateTime.date];
      attrField = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"from %@\n", startTime]];
      [attrField setFont: [kAppDelegate globalFontWithSize: 15.0]];
      [attrField setTextColor:[UIColor darkGrayColor]];
      [attrField setTextAlignment:NSTextAlignmentLeft];
      [attrField setLineBreakMode: NSLineBreakByWordWrapping];
      [attrStr appendAttributedString:attrField];
      
      // end time
      if (event.end.dateTime.dateComponents.minute == 0) {
        [dateFormatter setDateFormat:@"ha EEE, MMM d, y"];
      } else {
        [dateFormatter setDateFormat:@"h:mma EEE, MMM d, y"];
      }
      NSString *endTime = [dateFormatter stringFromDate:event.end.dateTime.date];
      attrField = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"to %@\n", endTime]];
      [attrField setFont: [kAppDelegate globalFontWithSize: 15.0]];
      [attrField setTextColor:[UIColor darkGrayColor]];
      [attrField setTextAlignment:NSTextAlignmentLeft];
      [attrField setLineBreakMode: NSLineBreakByWordWrapping];
      [attrStr appendAttributedString:attrField];
      
    }
  } else {
    // all day event
    if ([self eventStartAndEndOnSameDay:event]) {
      NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
      [dateFormatter setDateFormat:@"EEEE, MMM d, y"];
      NSString *dateString = [dateFormatter stringFromDate:event.start.date.date];
      attrField = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n", dateString]];
      [attrField setFont: [kAppDelegate globalFontWithSize: 15.0]];
      [attrField setTextColor:[UIColor darkGrayColor]];
      [attrField setTextAlignment:NSTextAlignmentLeft];
      [attrField setLineBreakMode: NSLineBreakByWordWrapping];
      [attrStr appendAttributedString:attrField];
      
      attrField = [[NSMutableAttributedString alloc] initWithString:@"All day\n"];
      [attrField setFont: [kAppDelegate globalFontWithSize: 15.0]];
      [attrField setTextColor:[UIColor darkGrayColor]];
      [attrField setTextAlignment:NSTextAlignmentLeft];
      [attrField setLineBreakMode: NSLineBreakByWordWrapping];
      [attrStr appendAttributedString:attrField];
      
    } else {
      NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
      [dateFormatter setDateFormat:@"EEEE, MMM d, y"];
      NSString *fromString = [dateFormatter stringFromDate:event.start.date.date];
      attrField = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"All day from %@\n", fromString]];
      [attrField setFont: [kAppDelegate globalFontWithSize: 15.0]];
      [attrField setTextColor:[UIColor darkGrayColor]];
      [attrField setTextAlignment:NSTextAlignmentLeft];
      [attrField setLineBreakMode: NSLineBreakByWordWrapping];
      [attrStr appendAttributedString:attrField];
      
      NSDateComponents *minusDayComponent = [[NSDateComponents alloc] init];
      minusDayComponent.day = -1;
      NSCalendar *calendar = [NSCalendar currentCalendar];
      NSDate *endDate = [calendar dateByAddingComponents:minusDayComponent
                                                  toDate:event.end.date.date options:0];
      
      NSString *toString = [dateFormatter stringFromDate:endDate];
      attrField = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"to %@\n", toString]];
      [attrField setFont: [kAppDelegate globalFontWithSize: 15.0]];
      [attrField setTextColor:[UIColor darkGrayColor]];
      [attrField setTextAlignment:NSTextAlignmentLeft];
      [attrField setLineBreakMode: NSLineBreakByWordWrapping];
      [attrStr appendAttributedString:attrField];
      
    }
  }
  
  // Transparency
  [attrStr appendAttributedString: newLine];
  attrField = [[NSMutableAttributedString alloc] initWithString: @"Availability\n"];
  [attrField setFont: [kAppDelegate globalBoldFontWithSize: 18.0]];
  [attrField setTextColor: [UIColor blackColor]];
  [attrField setTextAlignment:NSTextAlignmentLeft];
  [attrField setLineBreakMode: NSLineBreakByWordWrapping];
  [attrStr appendAttributedString:attrField];
  
  if ([event.transparency isEqualToInsensitive:@"transparent"]) {
    attrField = [[NSMutableAttributedString alloc] initWithString: @"Free\n"];
  } else {
    attrField = [[NSMutableAttributedString alloc] initWithString: @"Busy\n"];
  }
  [attrField setFont: [kAppDelegate globalFontWithSize: 15.0]];
  [attrField setTextColor:[UIColor darkGrayColor]];
  [attrField setTextAlignment:NSTextAlignmentLeft];
  [attrField setLineBreakMode: NSLineBreakByWordWrapping];
  [attrStr appendAttributedString:attrField];
  
  // Desciprtion
  if (event.descriptionProperty) {
    [attrStr appendAttributedString: newLine];
    attrField = [[NSMutableAttributedString alloc] initWithString: @"Notes\n"];
    [attrField setFont: [kAppDelegate globalBoldFontWithSize: 18.0]];
    [attrField setTextColor: [UIColor blackColor]];
    [attrField setTextAlignment:NSTextAlignmentLeft];
    [attrField setLineBreakMode: NSLineBreakByWordWrapping];
    [attrStr appendAttributedString:attrField];
    
    attrField = [[NSMutableAttributedString alloc] initWithString: event.descriptionProperty];
    [attrField setFont: [kAppDelegate globalFontWithSize: 15.0]];
    [attrField setTextColor:[UIColor darkGrayColor]];
    [attrField setTextAlignment:NSTextAlignmentLeft];
    [attrField setLineBreakMode: NSLineBreakByWordWrapping];
    [attrStr appendAttributedString:attrField];
  }
  
  return attrStr;
}

-(CGFloat)displayAttendeesList:(NSMutableArray *)list
                          cell:(UITableViewCell *)cell
                     listTitle:(NSString *)listTitle
                      currentY:(CGFloat)currentY {
  NSMutableAttributedString *attendeesString = [[NSMutableAttributedString alloc] init];
  NSMutableAttributedString *stringAppend;
  
  UILabel *title = [[UILabel alloc] initWithFrame: CGRectMake(10,
                                                              currentY,
                                                              280.0,
                                                              20.0)];
  title.text = listTitle;
  title.font =[kAppDelegate globalBoldFontWithSize: 15.0];
  title.textColor = [UIColor blackColor];
  [cell.contentView addSubview: title];
  currentY += 20.0;
  
  for (GTLCalendarEventAttendee *attendee in list) {
    if ([attendee.email isEqualToInsensitive:[User currentUser].myGoogleCalendarUserEmail] &&
        [[User currentUser] myPictureExists]) {
      UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake(10,
                                                                      currentY,
                                                                      30,
                                                                      30)];
      iv.image = [User currentUser].mySmallPicture;
      [cell.contentView addSubview:iv];
      currentY += iv.frame.size.height + 4.0;
    } else if ([attendee.email isEqualToInsensitive:[User currentUser].partnerGoogleCalendarUserEmail] &&
               [[User currentUser] partnerPictureExists]) {
      UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake(10,
                                                                      currentY,
                                                                      30,
                                                                      30)];
      iv.image = [User currentUser].partnerSmallPicture;
      [cell.contentView addSubview:iv];
      currentY += iv.frame.size.height + 4.0;
    } else {
      if (attendee.displayName) {
        stringAppend = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n", attendee.displayName]];
      } else if (attendee.email) {
        stringAppend = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n", attendee.email]];
      } else {
        continue;
      }
      [stringAppend setFont: [kAppDelegate globalFontWithSize: 15.0]];
      [stringAppend setTextColor:[UIColor darkGrayColor]];
      [stringAppend setTextAlignment:NSTextAlignmentLeft];
      [stringAppend setLineBreakMode:NSLineBreakByWordWrapping];
      
      [attendeesString appendAttributedString:stringAppend];
    }
  }
  
  UILabel *attrLabel = [[UILabel alloc] initWithFrame: CGRectMake(10, currentY, 280, 40)];
  attrLabel.backgroundColor = [UIColor clearColor];
  CGRect labelFrame = attrLabel.frame;
  labelFrame.size.height = [attendeesString sizeConstrainedToSize: CGSizeMake(280, CGFLOAT_MAX)].height;
  attrLabel.frame = labelFrame;
  attrLabel.attributedText = attendeesString;
  [cell.contentView addSubview:attrLabel];
  
  return (currentY + labelFrame.size.height + 4.0);
  
}

-(CGFloat)heightForAttendeesList:(NSMutableArray *)list {
  CGFloat height = 30;
  NSMutableAttributedString *attendeesString = [[NSMutableAttributedString alloc] init];
  NSMutableAttributedString *stringAppend;
  
  for (GTLCalendarEventAttendee *attendee in list) {
    if ([attendee.email isEqualToInsensitive:[User currentUser].myGoogleCalendarUserEmail]) {
      height += 34.0;
    } else if ([attendee.email isEqualToInsensitive:[User currentUser].partnerGoogleCalendarUserEmail]) {
      height += 34.0;
    } else {
      if (attendee.displayName) {
        stringAppend = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n", attendee.displayName]];
      } else if (attendee.email) {
        stringAppend = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n", attendee.email]];
      } else {
        continue;
      }
      [stringAppend setFont: [kAppDelegate globalFontWithSize: 15.0]];
      [stringAppend setTextColor:[UIColor darkGrayColor]];
      [stringAppend setTextAlignment:NSTextAlignmentLeft];
      [stringAppend setLineBreakMode:NSLineBreakByWordWrapping];
      [attendeesString appendAttributedString:stringAppend];
    }
  }
  
  height += [attendeesString sizeConstrainedToSize: CGSizeMake(280, CGFLOAT_MAX)].height;
  
  return height;
  
}


-(CGFloat)heightForAttendeesCell {
  CGFloat height = 60.0;
  
  // Attendees
  // Sort into buckets
  NSMutableArray *accepted = [NSMutableArray array];
  NSMutableArray *noReply = [NSMutableArray array];
  NSMutableArray *tentative = [NSMutableArray array];
  NSMutableArray *declined = [NSMutableArray array];
  
  for (GTLCalendarEventAttendee *attendee in self.event.attendees) {
    if (attendee.selfProperty) {
      continue;
    }
    if ([attendee.responseStatus isEqualToInsensitive:@"accepted"]) {
      [accepted addObject:attendee];
    } else if ([attendee.responseStatus isEqualToInsensitive:@"tentative"]) {
      [tentative addObject:attendee];
    } else if ([attendee.responseStatus isEqualToInsensitive:@"declined"]) {
      [declined addObject:attendee];
    } else {
      [noReply addObject:attendee];
    }
  }
  
  if (accepted.count > 0) {
    height += [self heightForAttendeesList:accepted];
  }
  if (noReply.count > 0) {
    height += [self heightForAttendeesList:noReply];
  }
  if (tentative.count > 0) {
    height += [self heightForAttendeesList:tentative];
  }
  if (declined.count > 0) {
    height += [self heightForAttendeesList:declined];
  }
  if (self.event.attendees.count == 0) {
    height += 10;
  }
  
  return height + 10.0;
  
}

-(NSMutableAttributedString *)attributedStringForRemindersCell:(GTLCalendarEvent*)event {
  NSMutableAttributedString *attrField;
  NSMutableAttributedString* newLine = [[NSMutableAttributedString alloc] initWithString:@"\n"];
  [newLine setFont: [UIFont systemFontOfSize: 15.0]];
  NSMutableAttributedString* smallNewLine = [[NSMutableAttributedString alloc] initWithString:@"\n"];
  [smallNewLine setFont: [UIFont systemFontOfSize: 6.0]];
  
  NSMutableAttributedString* attrStr;
  if (event.reminders.overrides.count == 1) {
    attrStr = [[NSMutableAttributedString alloc] initWithString: @"Reminder"];
  } else {
    attrStr = [[NSMutableAttributedString alloc] initWithString: @"Reminders"];
  }
  [attrStr setFont: [kAppDelegate globalBoldFontWithSize: 18.0]];
  [attrStr setTextColor: [UIColor blackColor]];
  [attrStr setTextAlignment:NSTextAlignmentLeft];
  [attrStr setLineBreakMode: NSLineBreakByWordWrapping];

  [attrStr appendAttributedString:newLine];
  
  for (GTLCalendarEventReminder *reminder in event.reminders.overrides) {
    NSString *reminderDescription;
    if ([reminder.minutes integerValue] == 0) {
      if (self.event.start.date.date) {
        reminderDescription = @"On day of event";
      } else {
        reminderDescription = @"At time of event";
      }
    } else if ([reminder.minutes integerValue] < 60) {
      reminderDescription = [NSString stringWithFormat:@"%ld minutes before the event", (long)[reminder.minutes integerValue]];
    } else if ([reminder.minutes integerValue] == 60) {
      reminderDescription = @"1 hour before the event";
    } else if ([reminder.minutes integerValue] < (60 * 24)) {
      if (([reminder.minutes integerValue] % 60) == 0) {
        reminderDescription = [NSString stringWithFormat:@"%ld hours before the event", (long)([reminder.minutes integerValue] / 60)];
      } else {
        CGFloat hours = [reminder.minutes floatValue] / 60.0;
        reminderDescription = [NSString stringWithFormat:@"%1.1f hours before the event", hours];
      }
    } else {
      NSInteger days = [reminder.minutes floatValue] / (60.0 * 24.0);
      if (days == 1) {
        reminderDescription = [NSString stringWithFormat:@"%ld day before the event", (long)days];
      } else {
        reminderDescription = [NSString stringWithFormat:@"%ld days before the event", (long)days];
      }
    }
    
    attrField = [[NSMutableAttributedString alloc] initWithString:reminderDescription];
    [attrField setFont: [kAppDelegate globalFontWithSize: 16.0]];
    [attrField setTextColor:[UIColor darkGrayColor]];
    [attrField setTextAlignment:NSTextAlignmentLeft];
    [attrField setLineBreakMode: NSLineBreakByWordWrapping];

    [attrStr appendAttributedString:attrField];
    
  }
  
  return attrStr;
}

-(BOOL)eventStartAndEndOnSameDay:(GTLCalendarEvent *)event {
  if (event.start.dateTime) {
    return (event.start.dateTime.dateComponents.day == event.end.dateTime.dateComponents.day &&
            event.start.dateTime.dateComponents.month == event.end.dateTime.dateComponents.month &&
            event.start.dateTime.dateComponents.year == event.end.dateTime.dateComponents.year);
  } else {
    // all day event
    NSInteger numberOfDays = [event.end.date.date timeIntervalSinceDate:event.start.date.date] / kDayTimeInterval;
    if (numberOfDays == 1) {
      return YES;
    } else {
      return NO;
    }
    
  }
}

-(BOOL)partnerIsAttending {
  for (GTLCalendarEventAttendee *attendee in self.event.attendees) {
    if ( [attendee.email isEqualToInsensitive:[User currentUser].partnerGoogleCalendarUserEmail] ) {
      return  YES;
    }
  }
  return NO;
}

@end
