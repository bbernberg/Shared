//
//  CalendarViewController.m
//  Shared
//
//  Created by Brian Bernberg on 8/26/15.
//  Copyright (c) 2015 BB Consulting. All rights reserved.
//

#import "CalendarViewController.h"
#import <JTCalendar/JTCalendar.h>
#import "CalendarService.h"
#import "CalendarEventController.h"
#import "CalendarEventEditController.h"
#import "PhotoDetailController.h"
#import "SHNavigationController.h"
#import "SHUtil.h"
#import "CLLocationManager+blocks.h"

static const CGFloat kMinimumMonthFetchTime = 30;
static const CGFloat kMinimumDayFetchTime = 6000;
static const NSUInteger kEventTimeTag = 1000;
static const NSUInteger kEventDescriptionTag = 1001;
static NSString *eventCellID = @"eventCellID";

@interface CalendarViewController () <JTCalendarDelegate>
@property (weak, nonatomic) IBOutlet JTCalendarMenuView *calendarMenuView;
@property (weak, nonatomic) IBOutlet JTHorizontalCalendarView *calendarContentView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *todayButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *separatorHeight;
@property (nonatomic) NSDate *lastFetchTime;

@property (nonatomic) JTCalendarManager *calendarManager;

@property (nonatomic) NSArray *dateSelectedEvents;
@property (nonatomic) CLLocationManager *locationManager;

@end

@implementation CalendarViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  if ( ! self.dateSelected ) {
    self.dateSelected = [NSDate date];
  }

  self.calendarManager = [JTCalendarManager new];
  self.calendarManager.delegate = self;
  [self.calendarManager setMenuView:self.calendarMenuView];
  [self.calendarManager setContentView:self.calendarContentView];
  [self.calendarManager setDate:self.dateSelected];
  
  self.separatorHeight.constant = [SHUtil thinnestLineWidth];
  self.todayButton.backgroundColor = [SHPalette darkRedColor];
  self.todayButton.layer.cornerRadius = roundf(self.todayButton.frameSizeWidth / 2.f);
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(calendarEventsRetrieved)
                                               name:kGoogleCalendarRetrievedEvents
                                             object:nil];
  
  [self checkLocation];
  
  
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self.tableView reloadData];
}

#pragma mark getters / setters
- (NSArray *)dateSelectedEvents {
  NSString *key = [CalendarService keyForDate:self.dateSelected];
  return [CalendarService sharedInstance].dayDictionary[key];
}

#pragma mark JTCalendarDelegate
- (void)calendar:(JTCalendarManager *)calendar prepareDayView:(JTCalendarDayView *)dayView
{
  dayView.textLabel.font = [UIFont systemFontOfSize:18.f];
  NSDate *today = [NSDate date];
  
  // Today
  if([_calendarManager.dateHelper date:today isTheSameDayThan:dayView.date]){
    BOOL todaySelected = self.dateSelected && [_calendarManager.dateHelper date:today isTheSameDayThan:self.dateSelected];
    dayView.circleView.hidden = ! todaySelected;
    dayView.circleView.backgroundColor = [SHPalette darkRedColor];
    dayView.dotView.backgroundColor = todaySelected ? [UIColor whiteColor] : [SHPalette darkRedColor];
    dayView.textLabel.textColor = todaySelected ? [UIColor whiteColor] : [SHPalette darkRedColor];
  }
  // Selected date
  else if(self.dateSelected && [_calendarManager.dateHelper date:self.dateSelected isTheSameDayThan:dayView.date]){
    dayView.circleView.hidden = NO;
    dayView.circleView.backgroundColor = [SHPalette navyBlue];
    dayView.dotView.backgroundColor = [UIColor whiteColor];
    dayView.textLabel.textColor = [UIColor whiteColor];
  }
  // Other month
  else if(![_calendarManager.dateHelper date:_calendarContentView.date isTheSameMonthThan:dayView.date]){
    dayView.circleView.hidden = YES;
    dayView.dotView.backgroundColor = [UIColor lightGrayColor];
    dayView.textLabel.textColor = [UIColor lightGrayColor];
  }
  // Another day of the current month
  else{
    dayView.circleView.hidden = YES;
    dayView.dotView.backgroundColor = [UIColor blackColor];
    dayView.textLabel.textColor = [UIColor blackColor];
  }
  
  if([self hasEventForDate:dayView.date]){
    dayView.dotView.hidden = NO;
  }
  else{
    dayView.dotView.hidden = YES;
  }
  
  if ( [CalendarService sharedInstance].validEvents == NO ||
       self.lastFetchTime == nil ||
       [self.lastFetchTime timeIntervalSinceNow] < -kMinimumDayFetchTime ) {
    self.lastFetchTime = [NSDate date];
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *futureComponent = [[NSDateComponents alloc] init];
    futureComponent.month = 8;
    
    NSDateComponents *pastComponent = [[NSDateComponents alloc] init];
    pastComponent.month = -8;
    
    [[CalendarService sharedInstance] retrieveCalendarEventsfrom:[calendar dateByAddingComponents:pastComponent toDate:dayView.date options:0]
                                                             to:[calendar dateByAddingComponents:futureComponent toDate:dayView.date options:0]];
  }
}



- (void)calendarDidLoadNextPage:(JTCalendarManager *)calendar {
  [self maybeLoadEventsForNewMonth];
}

- (void)calendarDidLoadPreviousPage:(JTCalendarManager *)calendar {
  [self maybeLoadEventsForNewMonth];
}

- (void)maybeLoadEventsForNewMonth {
  if ( [CalendarService sharedInstance].validEvents == NO ||
      self.lastFetchTime == nil ||
      [self.lastFetchTime timeIntervalSinceNow] < -kMinimumMonthFetchTime ) {
    self.lastFetchTime = [NSDate date];
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *futureComponent = [[NSDateComponents alloc] init];
    futureComponent.month = 8;
    
    NSDateComponents *pastComponent = [[NSDateComponents alloc] init];
    pastComponent.month = -8;
    
    [[CalendarService sharedInstance] retrieveCalendarEventsfrom:[calendar dateByAddingComponents:pastComponent toDate:self.calendarManager.date options:0]
                                                             to:[calendar dateByAddingComponents:futureComponent toDate:self.calendarManager.date options:0]];
  }
  
}

- (void)calendar:(JTCalendarManager *)calendar didTouchDayView:(JTCalendarDayView *)dayView {
  self.dateSelected = dayView.date;
  
  [self.tableView reloadData];
  
  // Animation for the circleView
  dayView.circleView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.1, 0.1);
  [UIView transitionWithView:dayView
                    duration:.3
                     options:0
                  animations:^{
                    dayView.circleView.transform = CGAffineTransformIdentity;
                    [self.calendarManager reload];
                  } completion:nil];
  
  // Load the previous or next page if touch a day from another month
  if( ![self.calendarManager.dateHelper date:self.calendarContentView.date isTheSameMonthThan:dayView.date] ) {
    if( [self.calendarContentView.date compare:dayView.date] == NSOrderedAscending ){
      [self.calendarContentView loadNextPageWithAnimation];
    } else{
      [self.calendarContentView loadPreviousPageWithAnimation];
    }
  }
}

- (void)calendarEventsRetrieved {
  [self refreshData];
}

- (void)refreshData {
  [self.calendarManager reload];
  [self.tableView reloadData];
}

#pragma mark UITableViewDataSource / UITableViewDelegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [self.dateSelectedEvents count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:eventCellID];
  
  if (!cell) {
    cell = [self createEventCell];
  }
  UILabel *eventTime = (UILabel*)[cell.contentView viewWithTag:kEventTimeTag];
  UILabel *eventDescription = (UILabel*)[cell.contentView viewWithTag:kEventDescriptionTag];
  GTLCalendarEvent *event = self.dateSelectedEvents[indexPath.row];
  eventTime.textColor = [UIColor darkGrayColor];
  
  if ( event.start.dateTime ) {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"h:mma"];
    
    if ([CalendarService isSameDayWithDate1:event.start.dateTime.date date2:self.dateSelected]) {
      eventTime.text = [dateFormatter stringFromDate:event.start.dateTime.date];
    } else if ([CalendarService isSameDayWithDate1:event.end.dateTime.date date2:self.dateSelected]) {
      eventTime.text = [dateFormatter stringFromDate:event.end.dateTime.date];
      eventTime.textColor = [SHPalette darkRedColor];
    } else {
      eventTime.text = @"all-day";
    }
  } else {
    // All day event
    eventTime.text = @"all-day";
  }
  eventDescription.text = event.summary;
  
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  GTLCalendarEvent *event = self.dateSelectedEvents[indexPath.row];
  CalendarEventController *vc = [[CalendarEventController alloc] initWithEvent:event];
  [self.parentViewController.navigationController pushViewController: vc animated: YES];
}

#pragma mark button handlers
- (IBAction)todayButtonPressed:(UIButton *)button {
  self.dateSelected = [NSDate date];  
  [self.calendarManager setDate:[NSDate date]];
  [self.calendarManager reload];
  [self.tableView reloadData];
}

#pragma mark utility functions
- (UITableViewCell *)createEventCell {
  UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:eventCellID];
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  cell.selectionStyle = UITableViewCellSelectionStyleGray;
  
  UILabel *eventTime = [[UILabel alloc] initWithFrame: CGRectMake(5.0, 10.0, 60.0, 24.0)];
  eventTime.textColor = [UIColor darkGrayColor];
  eventTime.font = [kAppDelegate globalFontWithSize:14.0];
  eventTime.textAlignment = NSTextAlignmentRight;
  eventTime.backgroundColor = [UIColor clearColor];
  eventTime.tag = kEventTimeTag;
  eventTime.adjustsFontSizeToFitWidth = YES;
  eventTime.minimumScaleFactor = 0.7;
  [cell.contentView addSubview:eventTime];
  
  UILabel *eventDescription = [[UILabel alloc] initWithFrame: CGRectMake(70.0, 10.0, 230.0, 24.0)];
  eventDescription.textColor = [UIColor blackColor];
  eventDescription.font = [kAppDelegate globalBoldFontWithSize:16.0];
  eventDescription.backgroundColor = [UIColor clearColor];
  eventDescription.tag = kEventDescriptionTag;
  [cell.contentView addSubview:eventDescription];
  
  return cell;
}

- (BOOL)hasEventForDate:(NSDate *)date {
  NSString *key = [CalendarService keyForDate:date];
  return [[CalendarService sharedInstance].dayDictionary[key] count] > 0;
}

- (void)checkLocation {
  if ( ![[NSUserDefaults standardUserDefaults] boolForKey:kLastLocationUpdated] ) {
    self.locationManager = [CLLocationManager updateManagerWithAccuracy:50.0
                                                            locationAge:15.0
                                                authorizationDesciption:CLLocationUpdateAuthorizationDescriptionAlways];
    
    if ([CLLocationManager isLocationUpdatesAvailable]) {
      [self.locationManager startUpdatingLocationWithUpdateBlock:^(CLLocationManager *manager, CLLocation *location, NSError *error, BOOL *stopUpdating) {
        NSLog(@"New location: %@", location);
        
        [[NSUserDefaults standardUserDefaults] setObject:@{@"latitude":@(location.coordinate.latitude), @"longitude":@(location.coordinate.longitude)}
                                                  forKey:kLastLocationKey];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kLastLocationUpdated];
        [[NSUserDefaults standardUserDefaults] synchronize];
        *stopUpdating = YES;
      }];
    }
  }
  
}

@end
