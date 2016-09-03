//
//  CalendarReminderEditController.m
//  Shared
//
//  Created by Brian Bernberg on 2/8/13.
//  Copyright (c) 2013 BB Consulting. All rights reserved.
//

#import "CalendarReminderEditController.h"
#import "Constants.h"

@interface CalendarReminderEditController ()
@property (nonatomic, strong) GTLCalendarEvent *event;
@property (nonatomic, strong) GTLCalendarEvent *originalEvent;
@property (nonatomic, assign) BOOL isAllDay;
@property (nonatomic, strong) NSMutableArray *availableReminders;
@property (nonatomic, assign) NSNumber *currentReminder;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;
@end

@implementation CalendarReminderEditController

- (id)initWithEvent:(GTLCalendarEvent *)event
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        // Custom initialization
        self.event = event;
        self.originalEvent = [self.event copy];
        if (!self.event.reminders) {
            self.event.reminders = [GTLCalendarEventReminders object];
        }
        if (self.event.start.date) {
            self.isAllDay = YES;
            self.availableReminders = [NSMutableArray arrayWithObjects:@(-1), @0, @(60*24), @(2*60*24), @(3*60*24), @(7*60*24), @(14*60*24), nil];
        } else {
            self.isAllDay = NO;
            self.availableReminders = [NSMutableArray arrayWithObjects: @(-1), @0, @5, @15, @30, @60, @120, @(60*24), @(2*60*24), nil];
        }
        
        if (!self.event.reminders.overrides ||
            self.event.reminders.overrides.count == 0) {
            self.currentReminder = @(-1);
            self.selectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        } else {
            self.currentReminder = [self.event.reminders.overrides[0] minutes];
            NSUInteger index = [self.availableReminders indexOfObject:self.currentReminder];
            if (index == NSNotFound) {
                self.selectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
                [self.availableReminders insertObject:self.currentReminder atIndex:0];
            } else {
                self.selectedIndexPath = [NSIndexPath indexPathForRow:index inSection:0];
            }
        }
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.backgroundView = nil;
    self.view.backgroundColor = [SHPalette backgroundColor];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed)];
    self.navigationItem.title = @"Reminder";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark button actions
-(void)doneButtonPressed {
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)cancelButtonPressed {
    self.event.reminders = self.originalEvent.reminders;
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - Table view data source


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.availableReminders.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        cell.textLabel.font = [kAppDelegate globalFontWithSize: 20.0];
    }
    
    NSInteger minutes = [self.availableReminders[indexPath.row] integerValue];
    if (minutes < 0) {
        cell.textLabel.text = @"None";
    } else {
        cell.textLabel.text = [self reminderDescription:minutes allDay:self.isAllDay];
    }
    if ([indexPath isEqual:self.selectedIndexPath]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.availableReminders[indexPath.row] integerValue] < 0) {
        self.event.reminders.overrides = [NSMutableArray array];
        self.event.reminders.useDefault = [NSNumber numberWithBool:YES];
    } else {
        if (!self.event.reminders.overrides ||
            self.event.reminders.overrides.count == 0) {
            GTLCalendarEventReminder *reminder = [GTLCalendarEventReminder object];
            reminder.minutes = self.availableReminders[indexPath.row];
            reminder.method = @"popup";
            self.event.reminders.overrides = @[reminder];
            self.event.reminders.useDefault = [NSNumber numberWithBool:NO];
        } else {
            GTLCalendarEventReminder *reminder = self.event.reminders.overrides[0];
            reminder.minutes = self.availableReminders[indexPath.row];
            reminder.method = @"popup";
            self.event.reminders.useDefault = [NSNumber numberWithBool:NO];
        }
    }
    if (![indexPath isEqual:self.selectedIndexPath]) {
        UITableViewCell *selectedCell = [self.tableView cellForRowAtIndexPath:self.selectedIndexPath];
        selectedCell.accessoryType = UITableViewCellAccessoryNone;
    }
    self.selectedIndexPath = indexPath;
    UITableViewCell *selectedCell = [self.tableView cellForRowAtIndexPath:self.selectedIndexPath];
    selectedCell.accessoryType = UITableViewCellAccessoryCheckmark;
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}

#pragma mark utility
-(NSString *)reminderDescription:(NSInteger)minutes allDay:(BOOL)allDay {
    if (minutes == 0) {
        if (allDay) {
            return @"On day of event";
        } else {
            return @"At time of event";
        }
    } else if (minutes < 60) {
        return [NSString stringWithFormat:@"%ld minutes before", (long)minutes];
    } else if (minutes == 60) {
        return @"1 hour before";
    } else if (minutes < (60 * 24)) {
        if ((minutes % 60) == 0) {
            return [NSString stringWithFormat:@"%ld hours before", (long)(minutes / 60)];
        } else {
            CGFloat hours = (float)minutes / 60.0;
            return [NSString stringWithFormat:@"%1.1f hours before", hours];
        }
    } else {
        NSInteger days = (float)minutes / (60.0 * 24.0);
        if (days == 1) {
            if (allDay) {
                return [NSString stringWithFormat:@"%ld day before", (long)days];
            } else {
                return [NSString stringWithFormat:@"%ld day before", (long)days];
            }
        } else {
            if (allDay) {
                return [NSString stringWithFormat:@"%ld days before", (long)days];
            } else {
                return [NSString stringWithFormat:@"%ld days before", (long)days];
            }
        }
    }
}

@end
