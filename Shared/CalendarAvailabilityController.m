//
//  CalendarAvailabilityController.m
//  Shared
//
//  Created by Brian Bernberg on 2/9/13.
//  Copyright (c) 2013 BB Consulting. All rights reserved.
//

#import "CalendarAvailabilityController.h"
#import "Constants.h"
#import "NSString+SHString.h"

@interface CalendarAvailabilityController ()
@property (nonatomic, strong) GTLCalendarEvent *event;
@property (nonatomic, strong) GTLCalendarEvent *originalEvent;

@end

@implementation CalendarAvailabilityController

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
    self.navigationItem.title = @"Availability";
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
    self.event.transparency = self.originalEvent.transparency;
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
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
    
    if (indexPath.row == 0) {
        cell.textLabel.text = @"Busy";
        if ([self.event.transparency isEqualToInsensitive:@"transparent"]) {
            cell.accessoryType = UITableViewCellAccessoryNone;
        } else {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    } else {
        cell.textLabel.text = @"Free";
        if ([self.event.transparency isEqualToInsensitive:@"transparent"]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UITableViewCell *busyCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    UITableViewCell *freeCell= [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    
    if (indexPath.row == 0) {
        self.event.transparency = @"opaque";
        busyCell.accessoryType = UITableViewCellAccessoryCheckmark;
        freeCell.accessoryType = UITableViewCellAccessoryNone;
    } else {
        self.event.transparency = @"transparent";
        freeCell.accessoryType = UITableViewCellAccessoryCheckmark;
        busyCell.accessoryType = UITableViewCellAccessoryNone;
    }
}

@end
