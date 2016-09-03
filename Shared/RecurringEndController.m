//
//  CalendarRecurringEndControllerController.m
//  Shared
//
//  Created by Brian Bernberg on 2/15/13.
//  Copyright (c) 2013 BB Consulting. All rights reserved.
//

#import "RecurringEndController.h"
#import "Constants.h"

@interface RecurringEndController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) NSDate *endDate;
@property (nonatomic, strong) NSDate *originalEndDate;
@property (nonatomic, strong) NSDate *minimumDate;
@property (nonatomic, strong) NSDate *pDate;
@property (nonatomic, weak) id<RecurringEndDelegate> delegate;
@end


@implementation RecurringEndController

- (id)initWithEndDate:(NSDate *)endDate
          minimumDate:(NSDate *)minimumDate
             delegate:(id<RecurringEndDelegate>)delegate
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        // Custom initialization
        self.originalEndDate = [self.endDate copy];
        self.minimumDate = minimumDate;
        self.delegate = delegate;
        self.endDate = endDate;
        if (endDate) {
            self.pDate = endDate;
        } else {
            self.pDate = [NSDate dateWithTimeInterval:60*60*24*30 sinceDate:[NSDate date]];
        }
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.view.backgroundColor = [SHPalette backgroundColor];
//    self.tableView.dataSource = self;
//    self.tableView.delegate = self;
    self.tableView.backgroundView = nil;
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed)];
    self.navigationItem.title = @"End Repeat";
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark button methods
-(void)repeatForeverButtonPressed {
    [self.delegate useEndDate:nil];
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)doneButtonPressed {
    [self.delegate useEndDate:self.endDate];
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)cancelButtonPressed {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark Picker changed
-(void)datePickerChanged:(UIDatePicker *)datePicker {
    
    self.endDate = datePicker.date;
    self.pDate = datePicker.date;
}

#pragma mark UITableViewDataSource protocol conformance
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.endDate) {
        return 3;
    } else {
        return 2;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 2) {
        static NSString *startPickerCellIdentifier = @"startPickerCell";
        UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier: startPickerCellIdentifier];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:startPickerCellIdentifier];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            UIDatePicker *picker = [[UIDatePicker alloc] init];
            picker.datePickerMode = UIDatePickerModeDate;
            picker.tag = 1000;
            CGRect frame = picker.frame;
            frame.origin = CGPointMake(0, 0);
            picker.frame = frame;
            [picker addTarget:self
                       action:@selector(datePickerChanged:)
             forControlEvents:UIControlEventValueChanged];
            [cell.contentView addSubview:picker];
        }
        UIDatePicker *picker = (UIDatePicker *)[cell.contentView viewWithTag:10000];
        [picker setDate:self.pDate animated:NO];
        
        return cell;
        
    } else {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"CellID"];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        cell.textLabel.font = [kAppDelegate globalBoldFontWithSize:20.0];
        cell.textLabel.textColor = [UIColor blackColor];
        
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Never";
            cell.tintColor = [UIColor darkGrayColor];
            if (self.endDate) {
                cell.accessoryType = UITableViewCellAccessoryNone;
            } else {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
        } else {
            cell.textLabel.text = @"On Date";
            cell.tintColor = [UIColor redColor];
            if (self.endDate) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;;
                cell.textLabel.textColor = [UIColor redColor];
            } else {
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.textLabel.textColor = [UIColor darkGrayColor];
            }
        }
        
        return cell;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 2) {
        return 216.f;
    } else {
        return 44.f;
    }
    
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row == 0) {
        if (self.endDate) {
            self.endDate = nil;
            
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.textLabel.textColor = [UIColor darkGrayColor];
            
            [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    } else {
        if (!self.endDate) {
            self.endDate = self.pDate;
            
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            cell.textLabel.textColor = [UIColor redColor];

            [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
    
}

@end
