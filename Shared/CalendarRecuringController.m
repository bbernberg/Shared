//
//  CalendarRecuringController.m
//  Shared
//
//  Created by Brian Bernberg on 2/13/13.
//  Copyright (c) 2013 BB Consulting. All rights reserved.
//

#import "CalendarRecuringController.h"
#import "NSString+SHString.h"
#import "Constants.h"

@interface CalendarRecuringController ()
@property (nonatomic, strong) GTLCalendarEvent *event;
@property (nonatomic, strong) GTLCalendarEvent *originalEvent;

@end

@implementation CalendarRecuringController

- (id)initWithEvent:(GTLCalendarEvent *)event
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        // Custom initialization
        self.event = event;
        self.originalEvent = [self.event copy];
        
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
    self.navigationItem.title = @"Repeat";
    
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
    self.event.recurrence = self.originalEvent.recurrence;
    self.event.recurringEventId = self.originalEvent.recurringEventId;
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 6;
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
    
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = @"None";
            if (self.event.recurrence == nil) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            } else {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            break;
        case 1:
            cell.textLabel.text = @"Every Day";
            if ([self.event.recurrence[0] isEqualToString:kRepeatDaily]) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            } else {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            break;
        case 2:
            cell.textLabel.text = @"Every Week";
            if ([self.event.recurrence[0] isEqualToString:kRepeatWeekly]) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            } else {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            break;
        case 3:
            cell.textLabel.text = @"Every 2 Weeks";
            if ([self.event.recurrence[0] isEqualToString:kRepeatBiWeekly]) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            } else {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            break;
        case 4:
            cell.textLabel.text = @"Every Month";
            if ([self.event.recurrence[0] isEqualToString:kRepeatMonthly]) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            } else {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            break;
        case 5:
            cell.textLabel.text = @"Every Year";
            if ([self.event.recurrence[0] isEqualToString:kRepeatYearly]) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            } else {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            break;
            
        default:
            break;
    }

    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case 0:
            self.event.recurrence = nil;
            break;
        case 1:
            self.event.recurrence = @[kRepeatDaily];
            break;
        case 2:
            self.event.recurrence = @[kRepeatWeekly];
            break;
        case 3:
            self.event.recurrence = @[kRepeatBiWeekly];
            break;
        case 4:
            self.event.recurrence = @[kRepeatMonthly];
            break;
        case 5:
            self.event.recurrence = @[kRepeatYearly];
            break;
        default:
            break;
    }
    
    for (UITableViewCell *cell in self.tableView.visibleCells) {
        NSIndexPath *ip = [self.tableView indexPathForCell:cell];
        if ([ip isEqual: indexPath]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
