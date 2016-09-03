//
//  GoogleEmailViewController.m
//  Shared
//
//  Created by Brian Bernberg on 8/20/15.
//  Copyright (c) 2015 BB Consulting. All rights reserved.
//

#import "GoogleEmailViewController.h"
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

@interface GoogleEmailViewController () <ABPeoplePickerNavigationControllerDelegate, UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UITextField *textField;
@property (nonatomic, weak) IBOutlet UILabel *label;
@property (nonatomic, weak) id<GoogleEmailViewControllerDelegate> delegate;
@property (nonatomic) GoogleEmailMode mode;
@property (nonatomic) BOOL firstView;
@end

@implementation GoogleEmailViewController

- (instancetype)initWithDelegate:(id<GoogleEmailViewControllerDelegate>)delegate mode:(GoogleEmailMode)mode {
  self = [super initWithNibName:nil bundle:nil];
  if ( self ) {
    _delegate = delegate;
    _mode = mode;
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.title = @"Google E-mail";
  
  UIButton *addressBookButton = [UIButton buttonWithType: UIButtonTypeContactAdd];
  addressBookButton.frame = CGRectMake(0, 0, 30, 30);
  [addressBookButton addTarget:self
                        action:@selector(addressBookButtonTapped:)
              forControlEvents:UIControlEventTouchUpInside];
  self.textField.rightView = addressBookButton;
  self.textField.rightViewMode = UITextFieldViewModeUnlessEditing;
  
  self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                        target:self
                                                                                        action:@selector(cancelButtonPressed)];
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                                         target:self
                                                                                         action:@selector(saveButtonPressed)];
  self.navigationItem.rightBarButtonItem.enabled = NO;
  
  if ( self.mode == GoogleEmailModeCalendarMe || self.mode == GoogleEmailModeDriveMe ) {
    self.label.text = @"Please enter your\nGoogle e-mail address:";
  } else {
    self.label.text = @"Please enter your partner's\nGoogle e-mail address:";
  }
  
}

-(void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];

  if ( !self.firstView ) {
    self.firstView = YES;
    [self.textField becomeFirstResponder];
  }
}

#pragma mark button handlers

- (void)cancelButtonPressed {
  [self.delegate controllerDidCancel:self];
}

-(void)saveButtonPressed {
  NSString *email = [self.textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  [self.delegate controllerDidChooseEmail:email controller:self];
}

- (void) addressBookButtonTapped: (UIView*) control {
  
  ABPeoplePickerNavigationController* picker = [[ABPeoplePickerNavigationController alloc] init];
  picker.peoplePickerDelegate = self;
  
  picker.modalPresentationStyle = UIModalPresentationFormSheet;
  picker.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
  picker.displayedProperties = [NSArray arrayWithObject: [NSNumber numberWithInteger: kABPersonEmailProperty]];
  
  [self presentViewController:picker animated:YES completion:NULL];
  
  picker.navigationBar.topItem.title = @"Partner E-mail";
  
}

#pragma mark ABPeoplePickerNavigationControllerDelegate
- (void)peoplePickerNavigationControllerDidCancel: (ABPeoplePickerNavigationController*) peoplePicker {
  [self dismissViewControllerAnimated:YES completion:NULL];  
}

- (void)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker
                         didSelectPerson:(ABRecordRef)person
                                property:(ABPropertyID)property
                              identifier:(ABMultiValueIdentifier)identifier {
  ABMultiValueRef multiABEntries = ABRecordCopyValue(person, property);
  NSString* emailAddress = (__bridge_transfer NSString *)(ABMultiValueCopyValueAtIndex(multiABEntries, identifier));
  
  self.textField.text = emailAddress;
  self.navigationItem.rightBarButtonItem.enabled = [self NSStringIsValidEmail:emailAddress];

  CFRelease(multiABEntries);
  
  [self dismissViewControllerAnimated:YES completion:NULL];
  
  [self.view endEditing:YES];
}

#pragma mark UITextFieldDelegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
  NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
  self.navigationItem.rightBarButtonItem.enabled = [self NSStringIsValidEmail:newString];
  return YES;
}

#pragma mark utility functions
-(BOOL) NSStringIsValidEmail:(NSString *)checkString
{
  BOOL stricterFilter = YES;
  NSString *stricterFilterString = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
  NSString *laxString = @".+@.+\\.[A-Za-z]{2}[A-Za-z]*";
  NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
  NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
  return [emailTest evaluateWithObject:checkString];
}


@end
