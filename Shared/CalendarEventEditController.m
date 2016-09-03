//
//  CalendarEventEditViewController.m
//  Shared
//
//  Created by Brian Bernberg on 2/4/13.
//  Copyright (c) 2013 BB Consulting. All rights reserved.
//

#import "CalendarEventEditController.h"
#import "CalendarReminderEditController.h"
#import "CalendarAvailabilityController.h"
#import "SSTextView.h"
#import "User.h"
#import "CalendarService.h"
#import "GoogleCalendarContainerController.h"
#import "NSString+SHString.h"
#import "CalendarRecuringController.h"
#import "Constants.h"
#import "RecurringEndController.h"
#import "SHUtil.h"
#import "GTLCalendar.h"
#import <MMDrawerController/UIViewController+MMDrawerController.h>
#import "PlacesController.h"
#import <GoogleMaps/GoogleMaps.h>

enum {
  kSectionSummaryLocation = 0,
  kSectionTimes,
  kSectionInvitePartner,
  kSectionNotifyPartner,
  kSectionReminders,
  kSectionAvailability,
  kSectionRecurring,
  kSectionDescription,
  kSectionMaxCount // KEEP
};

typedef enum {
  StateTimesNotEditing = 0,
  StateEditingStart,
  StateEditingEnd
} TimesEditState;

enum {
  kTimesCellAllDay = 0,
  kTimesCellStart,
  kTimesCellStartPicker,
  kTimesCellEnd,
  kTimesCellEndPicker,
  kTimesCellTimezone
};

@interface CalendarEventEditController () <UITableViewDataSource,
  UITableViewDelegate,
  UITextFieldDelegate,
  UITextViewDelegate,
  UIActionSheetDelegate,
  RecurringEndDelegate,
  UIGestureRecognizerDelegate,
  PlacesControllerDelegate> {
  NSInteger sectionMap[kSectionMaxCount];
}
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) GTLCalendarEvent *event;
@property (nonatomic, assign) BOOL isNewEvent;
@property (nonatomic, strong) GTLCalendarEvent *originalEvent;
@property (nonatomic, assign) NSInteger sectionCount;
@property (nonatomic, strong) NSDate *endRepeat;
@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, assign) BOOL notifyPartner;
@property (nonatomic, strong) UITapGestureRecognizer *dismissKeyboardTap;
@property (nonatomic, assign) TimesEditState timesEditState;
@property (nonatomic, assign) NSUInteger timesSection;
@property (nonatomic, assign) NSTimeInterval eventDuration;

@end

@implementation CalendarEventEditController

- (id)initWithEvent:(GTLCalendarEvent *)event
               date:(NSDate *)date {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    // Custom initialization
    self.event = event;
    self.sectionCount = 0;
    self.endRepeat = nil;
    self.timesEditState = StateTimesNotEditing;
    if (date) {
      self.startDate = date;
    } else {
      self.startDate = [NSDate date];
    }
    
    // register for notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    if ( event ) {
      self.isNewEvent = NO;
      self.notifyPartner = NO; // default
      self.originalEvent = [self.event copy];
      sectionMap[_sectionCount++] = kSectionSummaryLocation;
      
      self.timesSection = _sectionCount;
      sectionMap[_sectionCount++] = kSectionTimes;
      
#ifdef kUseInvitePartner
      if ([self.event.creator.email isEqualToInsensitive:[User currentUser].myGoogleCalendarUserEmail]) {
        sectionMap[_sectionCount++] = kSectionInvitePartner;
      }
#endif
      sectionMap[_sectionCount++] = kSectionNotifyPartner;
      sectionMap[_sectionCount++] = kSectionReminders;
      sectionMap[_sectionCount++] = kSectionAvailability;
      sectionMap[_sectionCount++] = kSectionDescription;
      self.title = @"Edit";
    } else {
      // configure new event
      self.isNewEvent = YES;
      self.notifyPartner = YES; // default
      self.event = [GTLCalendarEvent object];
      self.event.transparency = @"opaque";
      self.event.reminders = [GTLCalendarEventReminders object];
      self.event.creator.email = [User currentUser].myGoogleCalendarUserEmail;
      GTLDateTime *startDateTime = [GTLDateTime dateTimeWithDate:[self currentStartTime]
                                                        timeZone:[NSTimeZone systemTimeZone]];
      GTLDateTime *endDateTime = [GTLDateTime dateTimeWithDate:[self currentEndTime]
                                                      timeZone:[NSTimeZone systemTimeZone]];
      
      self.event.start = [GTLCalendarEventDateTime object];
      self.event.start.dateTime = startDateTime;
      self.event.start.timeZone = [[NSTimeZone systemTimeZone] name];
      
      self.event.end = [GTLCalendarEventDateTime object];
      self.event.end.dateTime = endDateTime;
      self.event.end.timeZone = [[NSTimeZone systemTimeZone] name];
      self.event.descriptionProperty = @"";
      
      sectionMap[_sectionCount++] = kSectionSummaryLocation;
      
      self.timesSection = _sectionCount;
      sectionMap[_sectionCount++] = kSectionTimes;
      
#ifdef kUseInvitePartner
      sectionMap[_sectionCount++] = kSectionInvitePartner;
#endif
      sectionMap[_sectionCount++] = kSectionNotifyPartner;
      sectionMap[_sectionCount++] = kSectionReminders;
      sectionMap[_sectionCount++] = kSectionAvailability;
      sectionMap[_sectionCount++] = kSectionRecurring;
      sectionMap[_sectionCount++] = kSectionDescription;
      self.title = @"Add Event";
    }
    
    if ([self isAllDayEvent]) {
      self.eventDuration = [self.event.end.date.date timeIntervalSinceDate:self.event.start.date.date];
    } else {
      self.eventDuration = [self.event.end.dateTime.date timeIntervalSinceDate:self.event.start.dateTime.date];
    }
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.tableView = [[UITableView alloc] initWithFrame:self.view.frame
                                                style:UITableViewStyleGrouped];
  self.tableView.dataSource = self;
  self.tableView.delegate = self;
  self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  [self.view addSubview:self.tableView];
  
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                         target:self
                                                                                         action:@selector(doneButtonPressed)];
  self.navigationItem.rightBarButtonItem.enabled = [self.event.summary length] > 0;
  
  self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                        target:self
                                                                                        action:@selector(cancelButtonPressed)];
  
  UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
  self.navigationItem.backBarButtonItem = backButton;
  
  self.tableView.backgroundView = nil;
  self.view.backgroundColor = [SHPalette backgroundColor];
  self.dismissKeyboardTap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                    action:@selector(dismissKeyboard)];
  self.dismissKeyboardTap.delegate = self;
  
}

-(void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self.tableView reloadData];
}

-(void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return self.sectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  switch (sectionMap[section]) {
    case kSectionSummaryLocation:
      return 2;
      break;
    case kSectionInvitePartner:
    case kSectionNotifyPartner:
    case kSectionReminders:
    case kSectionAvailability:
    case kSectionDescription:
      return 1;
      break;
    case kSectionTimes:
      if (self.timesEditState == StateTimesNotEditing) {
        if ([self isAllDayEvent]) {
          return 3;
        } else {
          return 4;
        }
      } else {
        if ([self isAllDayEvent]) {
          return 4;
        } else {
          return 5;
        }
      }
    case kSectionRecurring:
      if (self.event.recurrence) {
        return 2;
      } else {
        return 1;
      }
      break;
    default:
      return 0;
      break;
  }
}

#define kStartTitleTag 1001
#define kEndTitleTag 1002
#define kTimeZoneTitleTag 1003
#define kStartTimeTag 1004
#define kEndTimeTag 1005
#define kTimeZoneTag 1006

#define kSummaryTextFieldTag 1007
#define kDescriptionTextViewTag 1009
#define kInviteTitleTag 1010
#define kInviteSwitchTag 1011
#define kNotifySwitchTag 1012
#define kStartPickerTag 1013
#define kEndPickerTag 1014

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell;
  switch (sectionMap[indexPath.section]) {
    case kSectionSummaryLocation: {
      if (indexPath.row == 0) {
        static NSString *CellIdentifier = @"summaryCell";
        UITextField *textField;
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
          cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
          cell.selectionStyle = UITableViewCellSelectionStyleNone;
          textField = [[UITextField alloc] initWithFrame:CGRectMake(10, 10, cell.contentView.frameSizeWidth - 20.f, 24)];
          textField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
          textField.font = [kAppDelegate globalFontWithSize:18.0];
          textField.minimumFontSize = 12.0;
          textField.textColor = [UIColor darkGrayColor];
          textField.tag = kSummaryTextFieldTag;
          textField.placeholder = @"Title";
          textField.returnKeyType = UIReturnKeyDone;
          textField.delegate = self;
          [cell.contentView addSubview:textField];
        }
        textField = (UITextField *)[cell.contentView viewWithTag:kSummaryTextFieldTag];
        if (self.event.summary) {
          textField.text = self.event.summary;
        } else {
          textField.text = @"";
        }
      } else {
        static NSString *CellIdentifier = @"locationCell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
          cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
          cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
          cell.selectionStyle = UITableViewCellSelectionStyleGray;
        }
        cell.textLabel.font = [kAppDelegate globalBoldFontWithSize:18.0];
        cell.textLabel.textColor = [UIColor blackColor];
        cell.textLabel.text = @"Location";
        cell.detailTextLabel.font = [kAppDelegate globalFontWithSize:18.0];
        cell.detailTextLabel.textColor = [UIColor darkGrayColor];
        
        if (self.event.location) {
          cell.detailTextLabel.text = self.event.location;
        } else {
          cell.detailTextLabel.text = @"";
        }
      }
    } break;
    case kSectionTimes:
      return [self timesSectionCellForRow:indexPath.row];
      
    case kSectionInvitePartner : {
      static NSString *CellIdentifier = @"inviteCell";
      cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
      if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        cell.textLabel.font = [kAppDelegate globalBoldFontWithSize:18.0];
        
        UISwitch *inviteSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(220.0, 8.0, 79.0, 27.0)];
        inviteSwitch.tag = kInviteSwitchTag;
        inviteSwitch.onTintColor = [UIColor darkGrayColor];
        [inviteSwitch addTarget:self action:@selector(inviteSwitchToggled:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = inviteSwitch;
      }
      
      cell.textLabel.text = @"Invite Partner";
      UISwitch *inviteSwitch = (UISwitch *)cell.accessoryView;
      if ([self partnerIsInvited]) {
        [inviteSwitch setOn:YES];
      } else {
        [inviteSwitch setOn:NO];
      }
      
      return cell;
      
    } break;
    case kSectionNotifyPartner : {
      static NSString *CellIdentifier = @"notifyCell";
      cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
      if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        cell.textLabel.font = [kAppDelegate globalBoldFontWithSize:18.0];
        
        UISwitch *notifySwitch = [[UISwitch alloc] initWithFrame:CGRectMake(220.0, 8.0, 79.0, 27.0)];
        notifySwitch.tag = kNotifySwitchTag;
        notifySwitch.onTintColor = [UIColor darkGrayColor];
        [notifySwitch addTarget:self action:@selector(notifySwitchToggled:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = notifySwitch;
      }
      
      cell.textLabel.text = @"Notify Partner";
      UISwitch *notifySwitch = (UISwitch *)cell.accessoryView;
      if (self.notifyPartner) {
        [notifySwitch setOn:YES];
      } else {
        [notifySwitch setOn:NO];
      }
      
      return cell;
      
    } break;
    case kSectionReminders: {
      static NSString *CellIdentifier = @"remindersCell";
      cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
      if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
      }
      cell.textLabel.font = [kAppDelegate globalBoldFontWithSize:18.0];
      cell.textLabel.textColor = [UIColor blackColor];
      cell.textLabel.text = @"Reminder";
      cell.detailTextLabel.font = [kAppDelegate globalFontWithSize:18.0];
      cell.detailTextLabel.textColor = [UIColor darkGrayColor];
      
      if (self.event.reminders.overrides &&
          self.event.reminders.overrides.count > 0) {
        cell.detailTextLabel.text = [self reminderDescription:self.event.reminders.overrides[0]];
      } else {
        cell.detailTextLabel.text = @"None";
      }
    } break;
    case kSectionAvailability: {
      static NSString *CellIdentifier = @"availabilityCell";
      cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
      if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
      }
      cell.textLabel.font = [kAppDelegate globalBoldFontWithSize:18.0];
      cell.textLabel.textColor = [UIColor blackColor];
      cell.textLabel.text = @"Availability";
      cell.detailTextLabel.font = [kAppDelegate globalFontWithSize:18.0];
      cell.detailTextLabel.textColor = [UIColor darkGrayColor];
      
      if ([self.event.transparency isEqualToInsensitive:@"transparent"]) {
        cell.detailTextLabel.text = @"Free";
      } else {
        cell.detailTextLabel.text = @"Busy";
      }
    } break;
    case kSectionDescription: {
      static NSString *CellIdentifier = @"notesCell";
      SSTextView *textView;
      cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
      if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        textView = [[SSTextView alloc] initWithFrame:CGRectMake(5, 10, cell.contentView.frameSizeWidth - 20.f, 120)];
        textView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        textView.placeholder = @"Notes";
        textView.font = [kAppDelegate globalFontWithSize:20.0];
        textView.textColor = [UIColor darkGrayColor];
        textView.tag = kDescriptionTextViewTag;
        [cell.contentView addSubview:textView];
      }
      textView = (SSTextView *)[cell.contentView viewWithTag:kDescriptionTextViewTag];
      textView.delegate = self;
      
      if (self.event.descriptionProperty) {
        textView.text = self.event.descriptionProperty;
      } else {
        textView.text = @"";
      }
    } break;
    case kSectionRecurring: {
      if (indexPath.row == 0) {
        static NSString *CellIdentifier = @"recurranceCell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
          cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
          cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
          cell.selectionStyle = UITableViewCellSelectionStyleGray;
        }
        cell.textLabel.font = [kAppDelegate globalBoldFontWithSize:18.0];
        cell.textLabel.textColor = [UIColor blackColor];
        cell.textLabel.text = @"Repeat";
        cell.detailTextLabel.font = [kAppDelegate globalFontWithSize:18.0];
        cell.detailTextLabel.textColor = [UIColor darkGrayColor];
        
        if (self.event.recurrence && [self.event.recurrence count] > 0) {
          if ([self.event.recurrence[0] isEqualToString:kRepeatDaily]) {
            cell.detailTextLabel.text = @"Daily";
          } else if ([self.event.recurrence[0] isEqualToString:kRepeatWeekly]) {
            cell.detailTextLabel.text = @"Weekly";
          } else if ([self.event.recurrence[0] isEqualToString:kRepeatBiWeekly]) {
            cell.detailTextLabel.text = @"Every 2 Weeks";
          } else if ([self.event.recurrence[0] isEqualToString:kRepeatMonthly]) {
            cell.detailTextLabel.text = @"Monthly";
          } else if ([self.event.recurrence[0] isEqualToString:kRepeatYearly]) {
            cell.detailTextLabel.text = @"Yearly";
          }
        } else {
          cell.detailTextLabel.text = @"Never";
        }
      } else {
        static NSString *CellIdentifier = @"recurranceEndCell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
          cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
          cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
          cell.selectionStyle = UITableViewCellSelectionStyleGray;
        }
        cell.textLabel.font = [kAppDelegate globalBoldFontWithSize:18.0];
        cell.textLabel.textColor = [UIColor blackColor];
        cell.textLabel.text = @"End Repeat";
        cell.detailTextLabel.font = [kAppDelegate globalFontWithSize:18.0];
        cell.detailTextLabel.textColor = [UIColor darkGrayColor];
        
        if (self.endRepeat == nil) {
          cell.detailTextLabel.text = @"Never";
        } else {
          NSDateFormatter * df = [[NSDateFormatter alloc] init];
          [df setDateFormat:@"EEE, MMM d, y"];
          cell.detailTextLabel.text = [df stringFromDate:self.endRepeat];
        }
      }
    } break;
    default:
      break;
  }
  
  return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  if (sectionMap[indexPath.section] == kSectionDescription) {
    return 140;
  } else if (sectionMap[indexPath.section] == kSectionTimes) {
    NSUInteger cellType = [self timesSectionCellTypeForRow:indexPath.row];
    if (cellType == kTimesCellStartPicker ||
        cellType == kTimesCellEndPicker) {
      return 216.0;
    } else {
      return 44;
    }
  } else {
    return 44;
  }
}

-(UIView *)tableView:(UITableView *)theTableView viewForFooterInSection:(NSInteger)section {
  if (section == (self.sectionCount - 1) &&
      !self.isNewEvent) {
    UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, theTableView.frame.size.width, 100.0)];
    footer.backgroundColor = [UIColor clearColor];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(10, 10, theTableView.frameSizeWidth - 20.f, 44);
    button.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    button.backgroundColor = [UIColor colorWithRed:183.0/255.0
                                             green:62.0/255.0
                                              blue:62.0/255.0
                                             alpha:1.0];
    button.titleLabel.font = [UIFont fontWithName:@"CopperPlate" size:20.0];
    [button setTitle:@"Delete Event" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(deleteEventButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [button setBackgroundImage:[UIImage imageNamed:@"GrayBackground"] forState:UIControlStateHighlighted];
    [footer addSubview:button];
    return footer;
  } else {
    return [UIView new];
  }
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
  if (section == (self.sectionCount - 1) ) {
    return 100.0;
  } else {
    return 2.0;
  }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
  
  if (sectionMap[indexPath.section] != kSectionTimes) {
    [self resetTimesState];
  }
  UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
  switch (sectionMap[indexPath.section]) {
    case kSectionSummaryLocation: {
      if (indexPath.row == 0) {
        UITextField *textField = (UITextField *)[cell.contentView viewWithTag:kSummaryTextFieldTag];
        [textField becomeFirstResponder];
      } else {
        PlacesController *vc = [[PlacesController alloc] initWithLocation:self.event.location delegate:self];
        [self.navigationController pushViewController:vc animated:YES];
      }
    } break;
    case kSectionDescription: {
      SSTextView *textView = (SSTextView *)[cell.contentView viewWithTag:kDescriptionTextViewTag];
      [textView becomeFirstResponder];
    } break;
    case kSectionTimes: {
      [self.view endEditing:TRUE];
      NSUInteger selectedCellType = [self timesSectionCellTypeForRow:indexPath.row];
      if (selectedCellType == kTimesCellStart) {
        if (self.timesEditState == StateEditingStart) {
          self.timesEditState = StateTimesNotEditing;
          NSIndexPath *path = [NSIndexPath indexPathForRow:2
                                                 inSection:self.timesSection];
          [self.tableView deleteRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationFade];
          cell.detailTextLabel.textColor = [UIColor darkGrayColor];
        } else {
          [self.tableView beginUpdates];
          if (self.timesEditState == StateEditingEnd) {
            NSIndexPath *endPath = [NSIndexPath indexPathForRow:2
                                                      inSection:self.timesSection];
            UITableViewCell* endCell = [self.tableView cellForRowAtIndexPath:endPath];
            if ([self datesInvalid]) {
              endCell.detailTextLabel.textColor = [UIColor redColor];
            } else {
              endCell.detailTextLabel.textColor = [UIColor darkGrayColor];
            }
            NSIndexPath *path = [NSIndexPath indexPathForRow:3
                                                   inSection:self.timesSection];
            [self.tableView deleteRowsAtIndexPaths:@[path]
                                  withRowAnimation:UITableViewRowAnimationFade];
          }
          
          self.timesEditState = StateEditingStart;
          
          cell.detailTextLabel.textColor = [UIColor blueColor];
          
          NSIndexPath *path = [NSIndexPath indexPathForRow:2
                                                 inSection:self.timesSection];
          [self.tableView insertRowsAtIndexPaths:@[path]
                                withRowAnimation:UITableViewRowAnimationFade];
          [self.tableView endUpdates];
        }
      } else if (selectedCellType == kTimesCellEnd) {
        
        if (self.timesEditState == StateEditingEnd) {
          self.timesEditState = StateTimesNotEditing;
          NSIndexPath *path = [NSIndexPath indexPathForRow:3
                                                 inSection:self.timesSection];
          [self.tableView deleteRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationFade];
          if ([self datesInvalid]) {
            cell.detailTextLabel.textColor = [UIColor redColor];
          } else {
            cell.detailTextLabel.textColor = [UIColor darkGrayColor];
          }
        } else {
          [self.tableView beginUpdates];
          
          if (self.timesEditState == StateEditingStart) {
            NSIndexPath *startPath = [NSIndexPath indexPathForRow:1
                                                        inSection:self.timesSection];
            UITableViewCell* startCell = [self.tableView cellForRowAtIndexPath:startPath];
            startCell.detailTextLabel.textColor = [UIColor darkGrayColor];
            
            NSIndexPath *path = [NSIndexPath indexPathForRow:2
                                                   inSection:self.timesSection];
            [self.tableView deleteRowsAtIndexPaths:@[path]
                                  withRowAnimation:UITableViewRowAnimationFade];
          }
          self.timesEditState = StateEditingEnd;
          
          if ([self datesInvalid]) {
            cell.detailTextLabel.textColor = [UIColor redColor];
          } else {
            cell.detailTextLabel.textColor = [UIColor blueColor];
          }
          
          NSIndexPath *path = [NSIndexPath indexPathForRow:3
                                                 inSection:self.timesSection];
          [self.tableView insertRowsAtIndexPaths:@[path]
                                withRowAnimation:UITableViewRowAnimationFade];
          
          [self.tableView endUpdates];
          
        }
      }
      
    } break;
    case kSectionReminders: {
      [self.view endEditing:TRUE];
      CalendarReminderEditController *vc = [[CalendarReminderEditController alloc] initWithEvent:self.event];
      [self.navigationController pushViewController:vc animated:YES];
    } break;
    case kSectionAvailability: {
      [self.view endEditing:TRUE];
      CalendarAvailabilityController *vc = [[CalendarAvailabilityController alloc] initWithEvent:self.event];
      [self.navigationController pushViewController:vc animated:YES];
    } break;
    case kSectionRecurring: {
      [self.view endEditing:TRUE];
      if (indexPath.row == 0) {
        CalendarRecuringController *vc = [[CalendarRecuringController alloc] initWithEvent:self.event];
        [self.navigationController pushViewController:vc animated:YES];
      } else {
        NSDate *startDate;
        if (self.event.start.date) {
          startDate = self.event.start.date.date;
        } else {
          startDate = self.event.start.dateTime.date;
        }
        RecurringEndController *vc = [[RecurringEndController alloc] initWithEndDate:self.endRepeat minimumDate:startDate delegate:self];
        [self.navigationController pushViewController:vc animated:YES];
      }
    } break;
    default:
      break;
  }
  
}

#pragma mark button targets
-(void)doneButtonPressed {
  if (self.isNewEvent) {
    if ([self.event.recurrence count] > 0 && self.endRepeat) {
      NSString *theRecurrence = self.event.recurrence[0];
      NSDateFormatter *df = [[NSDateFormatter alloc] init];
      [df setDateFormat:@"yyyyMMdd'T'HHmmss'Z'"];
      NSTimeZone *gmt = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
      [df setTimeZone:gmt];
      NSString *end = [df stringFromDate: self.endRepeat];
      
      theRecurrence = [theRecurrence stringByAppendingString:[NSString stringWithFormat:@";UNTIL=%@",end]];
      self.event.recurrence = @[theRecurrence];
    }
    
    [[CalendarService sharedInstance] addEvent:self.event completionBlock:^(BOOL success, NSError *error) {
      if ( success && self.notifyPartner ) {
        NSString *pushMessage = nil;
        if ([self.event.summary length] > 0) {
          pushMessage = [NSString stringWithFormat:@"%@ has added an event (%@) to your Google Calendar",
                         [[User currentUser] myNameOrEmail],
                         self.event.summary];
        } else {
          pushMessage = [NSString stringWithFormat:@"%@ has added an event to your Google Calendar",
                         [[User currentUser] myNameOrEmail]];
          
        }
        NSDate *startDate = self.event.start.date ? self.event.start.date.date : self.event.start.dateTime.date;
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyyMMdd"];
        
        NSDictionary *pushUserInfo = @{@"alert" : pushMessage,
                                       @"sound" : @"default",
                                       kPushTypeKey : kGoogleCalendarNotification,
                                       kGoogleCalendarEventDateKey : [formatter stringFromDate:startDate],
                                       @"badge" : @"Increment"};
        [SHUtil sendPushNotification:pushUserInfo];
      }
    }];
  } else {
    [[CalendarService sharedInstance] patchOriginalEvent:self.originalEvent
                                       withRevisedEvent:self.event
                                         completionBlock:^(BOOL success, NSError *error) {
                                           if ( success && self.notifyPartner ) {
                                             NSString *pushMessage = nil;
                                             if ([self.event.summary length] > 0) {
                                               pushMessage = [NSString stringWithFormat:@"%@ has updated an event (%@) on your Google Calendar",
                                                              [[User currentUser] myNameOrEmail],
                                                              self.event.summary];
                                             } else {
                                               pushMessage = [NSString stringWithFormat:@"%@ has updated an event on your Google Calendar",
                                                              [[User currentUser] myNameOrEmail]];
                                             }
                                             NSDate *startDate = self.event.start.date ? self.event.start.date.date : self.event.start.dateTime.date;
                                             NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                                             [formatter setDateFormat:@"yyyyMMdd"];

                                             NSDictionary *pushUserInfo = @{@"alert" : pushMessage,
                                                                            @"sound" : @"default",
                                                                            kPushTypeKey : kGoogleCalendarNotification,
                                                                            kGoogleCalendarEventDateKey : [formatter stringFromDate:startDate],
                                                                            @"badge" : @"Increment"};
                                             
                                             [SHUtil sendPushNotification:pushUserInfo];
                                           }
     }];
  }
  
  [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)cancelButtonPressed {
  if (self.originalEvent) {
    [[CalendarService sharedInstance] restoreEvent:self.event fromEvent:self.originalEvent];
  }
  [self dismissViewControllerAnimated:YES completion:nil];
  
}

-(void)deleteEventButtonPressed {
  UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete Event" otherButtonTitles:nil];
  actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
  [actionSheet showInView:self.view];
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
  if (buttonIndex != actionSheet.cancelButtonIndex) {
    [[CalendarService sharedInstance] deleteEvent:self.event];
    UINavigationController *nav = (UINavigationController *)[[kAppDelegate viewController] centerViewController];
    for (UIViewController *aViewController in nav.viewControllers) {
      if ([aViewController isKindOfClass:[GoogleCalendarContainerController class]]) {
        [nav popToViewController:aViewController animated:NO];
      }
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
  }
}

-(void)inviteSwitchToggled:(UISwitch *)inviteSwitch {
  if (inviteSwitch.on) {
    if ([self partnerIsInvited]) {
      return;
    }
    NSMutableArray *attendees;
    if (self.event.attendees) {
      attendees = [self.event.attendees mutableCopy];
    } else {
      attendees = [NSMutableArray array];
    }
    GTLCalendarEventAttendee *newAttendee = [GTLCalendarEventAttendee object];
    newAttendee.email = [User currentUser].partnerGoogleCalendarUserEmail;
    newAttendee.responseStatus = @"needsAction";
    [attendees addObject: newAttendee];
    self.event.attendees = attendees;
  } else {
    GTLCalendarEventAttendee *partnerAttendee = nil;
    for (GTLCalendarEventAttendee *attendee in self.event.attendees) {
      if ( [attendee.email isEqualToInsensitive:[User currentUser].partnerGoogleCalendarUserEmail] ) {
        partnerAttendee = attendee;
      }
    }
    
    if (partnerAttendee) {
      NSMutableArray *attendees = [self.event.attendees mutableCopy];
      [attendees removeObject:partnerAttendee];
      self.event.attendees = attendees;
    }
    
  }
  
}

-(void)notifySwitchToggled:(UISwitch *)inviteSwitch {
  self.notifyPartner = inviteSwitch.on;
  [self resetTimesState];
}

#pragma mark utility
-(BOOL)isAllDayEvent {
  if (self.event.start.date) {
    return YES;
  } else {
    return NO;
  }
}

-(void)resetTimesState {
  self.timesEditState = StateTimesNotEditing;
  [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:self.timesSection] withRowAnimation:UITableViewRowAnimationAutomatic];
}

-(NSString *)reminderDescription:(GTLCalendarEventReminder *)reminder {
  if ([reminder.minutes integerValue] == 0) {
    if (self.event.start.date.date) {
      return @"On day of event";
    } else {
      return @"At time of event";
    }
  } else if ([reminder.minutes integerValue] < 60) {
    return [NSString stringWithFormat:@"%ld minutes before",(long)[reminder.minutes integerValue]];
  } else if ([reminder.minutes integerValue] == 60) {
    return @"1 hour before the event";
  } else if ([reminder.minutes integerValue] < (60 * 24)) {
    if (([reminder.minutes integerValue] % 60) == 0) {
      return [NSString stringWithFormat:@"%ld hours before", (long)([reminder.minutes integerValue] / 60)];
    } else {
      CGFloat hours = [reminder.minutes floatValue] / 60.0;
      return [NSString stringWithFormat:@"%1.1f hours before", hours];
    }
  } else {
    NSInteger days = [reminder.minutes floatValue] / (60.0 * 24.0);
    if (days == 1) {
      return [NSString stringWithFormat:@"%ld day before", (long)days];
    } else {
      return [NSString stringWithFormat:@"%ld days before", (long)days];
    }
  }
  
}

-(NSDate *)currentStartTime {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDateComponents *hourComponent = [[NSDateComponents alloc] init];
  hourComponent.hour = 1;
  
  NSDateComponents *dateComp = [calendar components: (NSCalendarUnitHour | NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear) fromDate:self.startDate];
  dateComp.minute = 0;
  NSDateComponents *curTimeComp = [calendar components: NSCalendarUnitHour fromDate:[NSDate date]];
  dateComp.hour = curTimeComp.hour;
  
  NSDate *startDate = [calendar dateFromComponents: dateComp];
  
  startDate = [calendar dateByAddingComponents:hourComponent
                                        toDate:startDate
                                       options:0];
  return startDate;
}

-(NSDate *)currentEndTime {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDateComponents *twoHourComponent = [[NSDateComponents alloc] init];
  twoHourComponent.hour = 2;
  NSDateComponents *dateComp = [calendar components: (NSCalendarUnitHour | NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear) fromDate:self.startDate];
  dateComp.minute = 0;
  NSDateComponents *curTimeComp = [calendar components: NSCalendarUnitHour fromDate:[NSDate date]];
  dateComp.hour = curTimeComp.hour;
  
  NSDate *startDate = [calendar dateFromComponents: dateComp];
  NSDate *endDate = [calendar dateByAddingComponents:twoHourComponent
                                              toDate:startDate
                                             options:0];
  return endDate;
  
}

-(BOOL)partnerIsInvited {
  for (GTLCalendarEventAttendee *attendee in self.event.attendees) {
    if ( [attendee.email isEqualToInsensitive:[User currentUser].partnerGoogleCalendarUserEmail] ) {
      return  YES;
    }
  }
  return NO;
}

#pragma mark Text Field delegate
-(void)textFieldDidBeginEditing:(UITextField *)textField {
  [self resetTimesState];
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
  NSString *newTextFieldText = [textField.text stringByReplacingCharactersInRange:range withString:string];
  if (textField.tag == kSummaryTextFieldTag) {
    self.event.summary = newTextFieldText;
  }
  
  self.navigationItem.rightBarButtonItem.enabled = [self.event.summary length] > 0;
  
  return YES;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
  [textField resignFirstResponder];
  
  self.navigationItem.rightBarButtonItem.enabled = [self.event.summary length] > 0;
  
  return YES;
}

#pragma mark Text View delegate
-(BOOL)textViewShouldBeginEditing:(UITextView *)textView {
  UITableViewCell* cell = [SHUtil tableViewCellForView:textView];
  
  CGPoint point = [cell.contentView convertPoint:textView.frame.origin
                                          toView:self.tableView];
  [self.tableView setContentOffset:CGPointMake(0, point.y - self.tableView.contentInset.top - 30.0)
                          animated:YES];
  
  [self.tableView addGestureRecognizer:self.dismissKeyboardTap];
  return YES;
}

-(void)textViewDidBeginEditing:(UITextView *)textView {
  [self resetTimesState];
}

-(BOOL)textViewShouldEndEditing:(UITextView *)textView {
  [self.tableView removeGestureRecognizer:self.dismissKeyboardTap];
  [textView resignFirstResponder];
  return YES;
}

-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
  NSString *newTextViewText = [textView.text stringByReplacingCharactersInRange:range withString:text];
  if (newTextViewText) {
    self.event.descriptionProperty = newTextViewText;
  } else {
    textView.text = @"";
  }
  
  return YES;
}

#pragma mark keyboard functions
#pragma mark keyboard functions
-(void)keyboardWillShow:(NSNotification *)n {
  NSDictionary *userInfo = [n userInfo];
  
  // get keyboard size
  NSValue *frameValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
  CGFloat keyboardHeight = [frameValue CGRectValue].size.height;
  NSTimeInterval animationDuration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
  
  [UIView animateWithDuration:animationDuration
                   animations:^{
                     self.tableView.contentInset = UIEdgeInsetsMake(self.tableView.contentInset.top, 0, keyboardHeight, 0);
                     self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
                   }
                   completion:NULL];
  
}

-(void)keyboardWillHide:(NSNotification *)n {
  NSDictionary *userInfo = [n userInfo];
  
  // get keyboard size
  NSTimeInterval animationDuration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
  
  [UIView animateWithDuration:animationDuration
                   animations:^{
                     self.tableView.contentInset = UIEdgeInsetsMake(self.tableView.contentInset.top, 0, 0, 0);
                     self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
                   } completion:^(BOOL finished) {
                   }];
  
}

-(void)dismissKeyboard {
  [self.view endEditing:YES];
}


#pragma mark Recurring end delegate
-(void)useEndDate:(NSDate *)date {
  self.endRepeat = date;
}

#pragma mark times section methods
-(UITableViewCell*)timesSectionCellForRow:(NSUInteger)row {
  UITableViewCell *cell;
  NSUInteger cellType = [self timesSectionCellTypeForRow:row];
  static NSString *CellIdentifier = @"timesCell";
  cell = [self.tableView dequeueReusableCellWithIdentifier: CellIdentifier];
  if (!cell) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
  }
  
  switch (cellType) {
    case(kTimesCellAllDay): {
      cell.textLabel.text = @"All-day";
      cell.detailTextLabel.text = @"";
      UISwitch *allDaySwitch = [[UISwitch alloc] init];
      allDaySwitch.onTintColor = [UIColor darkGrayColor];
      [allDaySwitch addTarget:self action:@selector(allDaySwitchToggled:) forControlEvents:UIControlEventValueChanged];
      allDaySwitch.on = [self isAllDayEvent];
      cell.accessoryView = allDaySwitch;
    } break;
    case(kTimesCellStart): {
      cell.textLabel.text = @"Starts";
      cell.accessoryView = UITableViewCellAccessoryNone;
      NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
      if ([self isAllDayEvent]) {
        [dateFormatter setDateFormat:@"EEE, MMM d, y"];
        cell.detailTextLabel.text = [dateFormatter stringFromDate:self.event.start.date.date];
      } else {
        [dateFormatter setDateFormat:@"EEE, MMM d h:mma"];
        cell.detailTextLabel.text = [dateFormatter stringFromDate:self.event.start.dateTime.date];
      }
      if (self.timesEditState == StateEditingStart) {
        cell.detailTextLabel.textColor = [UIColor blueColor];
      } else {
        cell.detailTextLabel.textColor = [UIColor darkGrayColor];
      }
    } break;
    case(kTimesCellEnd): {
      cell.textLabel.text = @"Ends";
      cell.accessoryView = UITableViewCellAccessoryNone;
      NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
      if ([self isAllDayEvent]) {
        [dateFormatter setDateFormat:@"EEE, MMM d, y"];
        NSDateComponents *minusDayComponent = [[NSDateComponents alloc] init];
        minusDayComponent.day = -1;
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDate *endDate = [calendar dateByAddingComponents:minusDayComponent
                                                    toDate:self.event.end.date.date options:0];
        cell.detailTextLabel.text = [dateFormatter stringFromDate:endDate];
      } else {
        [dateFormatter setDateFormat:@"EEE, MMM d h:mma"];
        cell.detailTextLabel.text = [dateFormatter stringFromDate:self.event.end.dateTime.date];
      }
      if ([self datesInvalid]) {
        cell.detailTextLabel.textColor = [UIColor redColor];
      } else {
        if (self.timesEditState == StateEditingEnd) {
          cell.detailTextLabel.textColor = [UIColor blueColor];
        } else {
          cell.detailTextLabel.textColor = [UIColor darkGrayColor];
        }
      }
    } break;
    case(kTimesCellTimezone): {
      cell.textLabel.text = @"Time Zone";
      cell.accessoryView = UITableViewCellAccessoryNone;
      cell.selectionStyle = UITableViewCellSelectionStyleNone;
      cell.detailTextLabel.textColor = [UIColor darkGrayColor];
      
      if (self.event.start.dateTime.timeZone) {
        NSTimeZone *tz = [NSTimeZone timeZoneWithName:self.event.start.timeZone];
        cell.detailTextLabel.text = [tz abbreviation];
      } else {
        cell.detailTextLabel.text = @"";
      }
    } break;
    case(kTimesCellStartPicker): {
      static NSString *startPickerCellIdentifier = @"startPickerCell";
      cell = [self.tableView dequeueReusableCellWithIdentifier: startPickerCellIdentifier];
      if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:startPickerCellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        UIDatePicker *picker = [[UIDatePicker alloc] init];
        picker.minuteInterval = 5;
        picker.tag = kStartPickerTag;
        CGRect frame = picker.frame;
        frame.origin = CGPointMake(0, 0);
        picker.frame = frame;
        [picker addTarget:self
                   action:@selector(datePickerChanged:)
         forControlEvents:UIControlEventValueChanged];
        [cell.contentView addSubview:picker];
        
      }
      UIDatePicker *picker = (UIDatePicker *)[cell.contentView viewWithTag:kStartPickerTag];
      NSDate *startDate;
      if ([self isAllDayEvent]) {
        picker.datePickerMode = UIDatePickerModeDate;
        startDate = self.event.start.date.date;
      } else {
        picker.datePickerMode = UIDatePickerModeDateAndTime;
        startDate = self.event.start.dateTime.date;
      }
      [picker setDate:startDate animated:NO];
    } break;
    case (kTimesCellEndPicker): {
      static NSString *endPickerCellIdentifier = @"endPickerCell";
      cell = [self.tableView dequeueReusableCellWithIdentifier: endPickerCellIdentifier];
      if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:endPickerCellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        UIDatePicker *picker = [[UIDatePicker alloc] init];
        picker.minuteInterval = 5;
        picker.tag = kEndPickerTag;
        CGRect frame = picker.frame;
        frame.origin = CGPointMake(0, 0);
        picker.frame = frame;
        [picker addTarget:self
                   action:@selector(datePickerChanged:)
         forControlEvents:UIControlEventValueChanged];
        [cell.contentView addSubview:picker];
      }
      UIDatePicker *picker = (UIDatePicker *)[cell.contentView viewWithTag:kEndPickerTag];
      NSDate *endDate;
      if ([self isAllDayEvent]) {
        picker.datePickerMode = UIDatePickerModeDate;
        NSDateComponents *minusDayComponent = [[NSDateComponents alloc] init];
        minusDayComponent.day = -1;
        NSCalendar *calendar = [NSCalendar currentCalendar];
        endDate = [calendar dateByAddingComponents:minusDayComponent
                                            toDate:self.event.end.date.date options:0];
      } else {
        picker.datePickerMode = UIDatePickerModeDateAndTime;
        endDate = self.event.end.dateTime.date;
      }
      [picker setDate:endDate animated:NO];
    } break;
  }
  
  return cell;
}

-(NSUInteger)timesSectionCellTypeForRow:(NSUInteger)row {
  if (row == 0) {
    return kTimesCellAllDay;
  } else if (row == 1) {
    return kTimesCellStart;
  } else if ((row == 2 && self.timesEditState != StateEditingStart) ||
             (row == 3 && self.timesEditState == StateEditingStart)) {
    return kTimesCellEnd;
  } else if (![self isAllDayEvent] &&
             ((self.timesEditState == StateTimesNotEditing && row == 3) ||
              row == 4))
  {
    return kTimesCellTimezone;
  } else if (row == 2 && self.timesEditState == StateEditingStart) {
    return kTimesCellStartPicker;
  } else {
    return kTimesCellEndPicker;
  }
  
}

-(BOOL)datesInvalid {
  return ((self.event.start.date && [self.event.start.date.date compare:self.event.end.date.date] == NSOrderedDescending) ||
          (self.event.start.date && [self.event.start.date.date compare:self.event.end.date.date] == NSOrderedSame) ||
          (self.event.start.dateTime && [self.event.start.dateTime.date compare:self.event.end.dateTime.date] == NSOrderedDescending));
  
}

-(void)allDaySwitchToggled:(id)sender {
  UISwitch *theSwitch = (UISwitch *)sender;
  
  if (theSwitch.isOn) {
    // all day
    self.event.start.date = [GTLDateTime dateTimeForAllDayWithDate:self.event.start.dateTime.date];
    self.event.start.dateTime = nil;
    NSDate *endDate = [NSDate dateWithTimeInterval:60*60*24 sinceDate:self.event.end.dateTime.date];
    self.event.end.date = [GTLDateTime dateTimeForAllDayWithDate:endDate];
    self.event.end.dateTime = nil;
    self.eventDuration = 60*60*24;
  } else {
    self.event.start.dateTime = [GTLDateTime dateTimeWithDate:self.event.start.date.date
                                                     timeZone:[NSTimeZone systemTimeZone]];
    self.event.start.date = nil;
    NSDate *endDate = [NSDate dateWithTimeInterval:60*60
                                         sinceDate:self.event.start.dateTime.date];
    self.event.end.dateTime = [GTLDateTime dateTimeWithDate:endDate
                                                   timeZone:[NSTimeZone systemTimeZone]];
    self.event.end.date = nil;
    self.eventDuration = 60*60;
  }
  
  [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:self.timesSection]
                withRowAnimation:UITableViewRowAnimationAutomatic];
  
}

#pragma mark Picker changed
-(void)datePickerChanged:(UIDatePicker *)picker {
  if (picker.tag == kStartPickerTag) {
    if ([self isAllDayEvent]) {
      // all day
      GTLDateTime *startDate = [GTLDateTime dateTimeForAllDayWithDate:picker.date];
      self.event.start.date = startDate;
      NSDate *newEndDate = [NSDate dateWithTimeInterval:self.eventDuration
                                              sinceDate:self.event.start.date.date];
      GTLDateTime *endDateTime = [GTLDateTime dateTimeForAllDayWithDate:newEndDate];
      self.event.end.date = endDateTime;
    } else {
      GTLDateTime *startDate = [GTLDateTime dateTimeWithDate:picker.date
                                                    timeZone:[NSTimeZone systemTimeZone]];
      self.event.start.dateTime = startDate;
      NSDate *newEndDate = [NSDate dateWithTimeInterval:self.eventDuration sinceDate:self.event.start.dateTime.date];
      GTLDateTime *endDateTime = [GTLDateTime dateTimeWithDate:newEndDate
                                                      timeZone:[NSTimeZone systemTimeZone]];
      self.event.end.dateTime = endDateTime;
    }
    NSIndexPath* startIndexPath = [NSIndexPath indexPathForRow:1 inSection:self.timesSection];
    NSIndexPath* endIndexPath = [NSIndexPath indexPathForRow:3 inSection:self.timesSection];
    [self.tableView reloadRowsAtIndexPaths:@[startIndexPath, endIndexPath]
                          withRowAnimation:UITableViewRowAnimationAutomatic];
  } else {
    if (self.event.start.date) {
      // all day
      NSDate *oneDayAhead = [NSDate dateWithTimeInterval:60*60*24
                                               sinceDate:picker.date];
      GTLDateTime *endDate = [GTLDateTime dateTimeForAllDayWithDate:oneDayAhead];
      self.event.end.date = endDate;
      self.eventDuration = [self.event.end.date.date timeIntervalSinceDate:self.event.start.date.date];
    } else {
      GTLDateTime *endDate = [GTLDateTime dateTimeWithDate:picker.date
                                                  timeZone:[NSTimeZone systemTimeZone]];
      self.event.end.dateTime = endDate;
      self.eventDuration = [picker.date timeIntervalSinceDate:self.event.start.dateTime.date];
    }
    NSIndexPath* startIndexPath = [NSIndexPath indexPathForRow:1 inSection:self.timesSection];
    NSIndexPath* endIndexPath = [NSIndexPath indexPathForRow:2 inSection:self.timesSection];
    [self.tableView reloadRowsAtIndexPaths:@[startIndexPath, endIndexPath]
                          withRowAnimation:UITableViewRowAnimationAutomatic];
    
  }
  
}

#pragma mark PlacesControllerDelegate
- (void)exitingWithPlaceID:(NSString *)placeID location:(NSString *)location {
  if ( placeID ) {
    [[GMSPlacesClient sharedClient] lookUpPlaceID:placeID callback:^(GMSPlace * _Nullable result, NSError * _Nullable error) {
      if ([result.types containsObject:@"street_address"]) {
        self.event.location = result.formattedAddress;
      } else {
        self.event.location = [NSString stringWithFormat:@"%@, %@", result.name, result.formattedAddress];
      }
      [self.tableView reloadData];
    }];
    
  } else {
    self.event.location = location;
  }
}

@end
