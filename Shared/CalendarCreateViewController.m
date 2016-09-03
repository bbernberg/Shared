//
//  CalendarCreateViewController.m
//  Shared
//
//  Created by Brian Bernberg on 9/26/15.
//  Copyright © 2015 BB Consulting. All rights reserved.
//

#import "CalendarCreateViewController.h"
#import "Constants.h"
#import "PSPDFAlertView.h"
#import "CalendarService.h"

@interface CalendarCreateViewController () <UITextFieldDelegate>
@property (nonatomic, weak) id<CalendarCreateDelegate> delegate;
@property (nonatomic, weak) IBOutlet UITextField *textField;
@property (nonatomic, weak) IBOutlet UIView *textBackground;
@property (nonatomic, weak) IBOutlet UILabel *messageLabel;
@property (nonatomic, weak) IBOutlet UIButton *submitButton;
@property (nonatomic, weak) IBOutlet UILabel *statusLabel;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *spinner;
@end

@implementation CalendarCreateViewController

- (instancetype)initWithDelegate:(id<CalendarCreateDelegate>)delegate {
  self = [super initWithNibName:nil bundle:nil];
  if ( self ) {
    _delegate = delegate;
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.title = @"Calendar";
  self.view.backgroundColor = [SHPalette backgroundColor];
  self.statusLabel.hidden = YES;
  self.spinner.hidden = YES;
  self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                        target:self
                                                                                        action:@selector(cancelButtonPressed)];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [self.textField becomeFirstResponder];
}

- (IBAction)submitButtonPressed:(id)sender {
  [self checkCalendarName];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [textField endEditing:YES];
  [self checkCalendarName];
  return YES;
}


- (void)checkCalendarName {
  if ( self.textField.text.length == 0 ) {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:@"Invalid name. Please enter a new name." preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK"
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * _Nonnull action) {
                                                     [self.textField becomeFirstResponder];
                                                   }];
    [alert addAction:action];
    
    [self presentViewController:alert animated:YES completion:nil];
  } else {
    [self createCalendar];
  }
}

- (void)createCalendar {
  [self.view endEditing:YES];
  self.textField.hidden = YES;
  self.textBackground.hidden = YES;
  self.messageLabel.hidden = YES;
  self.submitButton.hidden = YES;
  self.statusLabel.hidden = NO;
  self.spinner.hidden = NO;
  [self.spinner startAnimating];
  
  [[CalendarService sharedInstance] createCalendarWithName:self.textField.text
                                           completionBlock:^(BOOL success, BOOL choosePartner, NSError *error) {
                                             if ( error ) {
                                               [self.delegate calendarCreateControllerDidCancelWithError:YES];
                                             } else {
                                               self.statusLabel.text = @"Verifying Calendar...";
                                               [[CalendarService sharedInstance] verifyCalendarWithCompletionBlock:^(BOOL success, NSError *error) {
                                                 if ( success ) {
                                                   [self.delegate calendarCreatedNeedsPartnerEmail:choosePartner];
                                                 } else {
                                                   [self.delegate calendarCreateControllerDidCancelWithError:YES];
                                                 }
                                               } failureCount:0];
                                             }
                                           }];
}

- (void)cancelButtonPressed {
  [self.delegate calendarCreateControllerDidCancelWithError:NO];
}

@end
