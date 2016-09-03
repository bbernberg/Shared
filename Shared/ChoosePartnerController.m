//
//  ChoosePartnerController.m
//  Shared
//
//  Created by Brian Bernberg on 3/3/13.
//  Copyright (c) 2013 BB Consulting. All rights reserved.
//

#import "ChoosePartnerController.h"
#import "Constants.h"
#import "HTAutocompleteTextField.h"
#import "HTAutocompleteManager.h"
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import "PSPDFAlertView.h"
#import "NSString+SHString.h"

@interface ChoosePartnerController () <UITextFieldDelegate,
  UIGestureRecognizerDelegate,
  ABPeoplePickerNavigationControllerDelegate,
  ABPersonViewControllerDelegate>
@property (nonatomic, weak) IBOutlet UITextField *emailField;
@property (nonatomic, weak) IBOutlet UIView *emailBackground;
@property (nonatomic, copy) void (^completionBlock)(void);
@property (nonatomic, assign) BOOL useCancelButton;
@end

@implementation ChoosePartnerController

- (id)initWithCompletionBlock:(void (^)(void))completionBlock
              useCancelButton:(BOOL)useCancelButton
{
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    // Custom initialization
    self.completionBlock = completionBlock;
    self.useCancelButton = useCancelButton;
    
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  // Do any additional setup after loading the view from its nib.
  self.navigationItem.title = @"Choose Partner";
  self.view.backgroundColor = [SHPalette backgroundColor];
  
  UIButton *addressBookButton = [UIButton buttonWithType: UIButtonTypeContactAdd];
  addressBookButton.frame = CGRectMake(0, 0, 30, 30);
  [addressBookButton addTarget: self action: @selector(addressBookButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
  self.emailField.rightView = addressBookButton;
  self.emailField.rightViewMode = UITextFieldViewModeUnlessEditing;
  
  if (self.useCancelButton) {
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                           target:self
                                                                                           action:@selector(cancelButtonPressed)];
  } else {
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Log Out" style:UIBarButtonItemStylePlain target:self action:@selector(logoutButtonPressed)];
  }

  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                                        target:self
                                                                                        action:@selector(saveButtonPressed:)];
}

-(void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  
  [self.emailField becomeFirstResponder];
}

-(void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Button actions
-(void)logoutButtonPressed {
  [[NSNotificationCenter defaultCenter] postNotificationName:kShouldLogoutNotification object:self];
}

-(void)cancelButtonPressed {
  [self.navigationController popViewControllerAnimated:YES];
}

-(void)saveButtonPressed:(id)sender {
  NSString *email = [[self.emailField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString];
  
  if ([self NSStringIsValidEmail:email] && ! [email isEqualToString:[User currentUser].myUserEmail] ) {
    [User currentUser].partnerUserID = email;
    [User currentUser].partnerUserEmail = email;
    [[User currentUser] saveToNetwork];
    [[User currentUser] updatePFInstallationForUser];
    [[User currentUser] getPartnerData];
    
    self.completionBlock();
  } else {
    NSString *message = [email isEqualToString:[User currentUser].myUserEmail] ? @"Please enter an e-mail different than your own" :
      @"Please re-enter your partner's e-mail address";
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Invalid E-mail Address"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [self presentViewController:alert
                       animated:YES
                     completion:nil];
    
    [self.emailField becomeFirstResponder];
  }
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


#pragma mark textfield delegate
-(BOOL)textFieldShouldReturn:(UITextField *)textField {
  NSString *email = [[self.emailField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString];
  
  if ([self NSStringIsValidEmail:email]) {
    [User currentUser].partnerUserID = email;
    [User currentUser].partnerUserEmail = email;
    [[User currentUser] saveToNetwork];
    [[User currentUser] updatePFInstallationForUser];    
    self.completionBlock();
    return YES;
  } else {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Invalid E-mail Address"
                                                                   message:@"Please re-enter your partner's e-mail address"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [self presentViewController:alert
                       animated:YES
                     completion:nil];
    
    return NO;
  }
  
}

#pragma mark People Picker Delegate Functions
- (BOOL)peoplePickerNavigationController: (ABPeoplePickerNavigationController*) peoplePicker shouldContinueAfterSelectingPerson: (ABRecordRef) person {
  
  ABPersonViewController* picker = [[ABPersonViewController alloc] init];
  picker.personViewDelegate = self;
  picker.displayedPerson = person;
  picker.displayedProperties = [NSArray arrayWithObject: [NSNumber numberWithInteger: kABPersonEmailProperty]];
  // Don't allow users to edit the person’s information
  picker.allowsEditing = NO;
  
  [peoplePicker pushViewController: picker animated: YES];
  
  peoplePicker.navigationBar.topItem.title = @"Partner E-mail";
  
  return NO;
}

- (BOOL)peoplePickerNavigationController: (ABPeoplePickerNavigationController*) peoplePicker
      shouldContinueAfterSelectingPerson: (ABRecordRef) person
                                property: (ABPropertyID) property
                              identifier:(ABMultiValueIdentifier) identifier {
  
  return NO;
  
}

- (void)peoplePickerNavigationControllerDidCancel: (ABPeoplePickerNavigationController*) peoplePicker {
  [self dismissViewControllerAnimated:YES completion:NULL];
  
}

- (void)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker
                         didSelectPerson:(ABRecordRef)person
                                property:(ABPropertyID)property
                              identifier:(ABMultiValueIdentifier)identifier {
  ABMultiValueRef multiABEntries = ABRecordCopyValue(person, property);
  NSString* emailAddress = (__bridge_transfer NSString *)(ABMultiValueCopyValueAtIndex(multiABEntries, identifier));
  
  self.emailField.text = emailAddress;
  
  CFRelease(multiABEntries);
  
  [self.view endEditing:YES];
  
  [self dismissViewControllerAnimated:YES completion:NULL];
  
}

#pragma mark ABPersonViewControllerDelegate methods
// Does not allow users to perform default actions such as dialing a phone number, when they select a contact property.
- (BOOL)personViewController: (ABPersonViewController*) personViewController
shouldPerformDefaultActionForPerson: (ABRecordRef) person
                    property: (ABPropertyID) property
                  identifier: (ABMultiValueIdentifier) identifierForValue
{
  ABMultiValueRef multiABEntries = ABRecordCopyValue(person, property);
  NSString* emailAddress = (__bridge_transfer NSString *)(ABMultiValueCopyValueAtIndex(multiABEntries, identifierForValue));
  
  self.emailField.text = emailAddress;
  
  CFRelease(multiABEntries);
  
  [self.view endEditing:YES];
  
  [self dismissViewControllerAnimated:YES completion:NULL];
  
	return NO;
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
