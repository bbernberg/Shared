//
//  EmailLoginController.m
//  Shared
//
//  Created by Brian Bernberg on 2/27/13.
//  Copyright (c) 2013 BB Consulting. All rights reserved.
//

#import "EmailLoginController.h"
#import "Constants.h"
#import <Parse/Parse.h>
#import "Constants.h"
#import "SVProgressHUD.h"
#import "PSPDFAlertView.h"
#import "HTAutocompleteTextField.h"
#import "HTAutocompleteManager.h"
#import "JVFloatLabeledTextField.h"
#import "LTHPasscodeViewController.h"

@interface EmailLoginController () <UITextFieldDelegate>
@property (nonatomic, weak) IBOutlet JVFloatLabeledTextField *emailField;
@property (nonatomic, weak) IBOutlet JVFloatLabeledTextField *passwordField;
@property (nonatomic, weak) IBOutlet UIButton *passwordButton;
@property (nonatomic, weak) IBOutlet UIButton *loginButton;
@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) PSPDFAlertView *alert;
@end

@implementation EmailLoginController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    // Custom initialization
    // register for notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  // Do any additional setup after loading the view from its nib.
  [self.navigationController setNavigationBarHidden:NO animated:YES];
  self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed)];
  self.navigationItem.title = @"Log In";
  self.view.backgroundColor = [SHPalette backgroundColor];
  self.scrollView.contentSize = CGSizeMake([[UIScreen mainScreen] bounds].size.width, 280);
  self.emailField.autocompleteDataSource = [HTAutocompleteManager sharedManager];
  self.emailField.autocompleteType = HTAutocompleteTypeEmail;
  
  self.emailField.floatingLabelActiveTextColor = [SHPalette navyBlue];
  self.emailField.floatingLabelTextColor = [SHPalette navyBlue];
  self.emailField.floatingLabel.font = [UIFont systemFontOfSize:12.f];
  
  self.passwordField.floatingLabelActiveTextColor = [SHPalette navyBlue];
  self.passwordField.floatingLabelTextColor = [SHPalette navyBlue];
  self.passwordField.floatingLabel.font = [UIFont systemFontOfSize:12.f];
  
}

-(void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [self.emailField becomeFirstResponder];
}

-(void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  [SVProgressHUD dismiss]; // just in case
}

-(void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Button actions
-(void)cancelButtonPressed {
  [self.navigationController popViewControllerAnimated:YES];
}

-(IBAction)passwordButtonPressed:(id)sender {
  [self.view endEditing:YES];
  
  self.alert = [[PSPDFAlertView alloc] initWithTitle:nil
                                             message:@"Please enter the e-mail address you signed up with:"];
  self.alert.alertViewStyle = UIAlertViewStylePlainTextInput;
  [self.alert setCancelButtonWithTitle:@"Cancel" block:NULL];
  __weak EmailLoginController *wSelf = self;
  [self.alert addButtonWithTitle:@"OK" block:^(NSInteger buttonIndex) {
    
    [SVProgressHUD showWithStatus:@"Sending..."];
    [PFUser requestPasswordResetForEmailInBackground:[wSelf.alert textFieldAtIndex:0].text
                                               block:^(BOOL succeeded, NSError *error) {
                                                 if (succeeded) {
                                                   [SVProgressHUD showSuccessWithStatus:@"Reset password e-mail sent"];
                                                 } else {
                                                   [SVProgressHUD dismiss];
                                                   if (error) {
                                                     NSString *message;
                                                     if (error.code == 100) {
                                                       message = @"The internet connection appears to be offline";
                                                     } else {
                                                       message = [error.userInfo[@"error"] capitalizedString];
                                                     }
                                                     UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"E-mail Not Sent"
                                                                                                                    message:message
                                                                                                             preferredStyle:UIAlertControllerStyleAlert];
                                                     [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                                                               style:UIAlertActionStyleCancel
                                                                                             handler:nil]];
                                                     [wSelf presentViewController:alert
                                                                        animated:YES
                                                                      completion:nil];
                                                   }
                                                 }
                                                 
                                               }];
  }];
  [[self.alert textFieldAtIndex:0] setDelegate:self];
  [self.alert show];
  
}

-(IBAction)loginButtonPressed:(id)sender {
  [self validateFields];
  [self.view endEditing:YES];
}

#pragma mark validation method
-(void)validateFields {
  if ( ! [self NSStringIsValidEmail:self.emailField.text] ) {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Invalid E-mail Address"
                                                                   message:@"Please re-enter your e-mail address."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [self presentViewController:alert
                       animated:YES
                     completion:nil];
    
    [self.emailField becomeFirstResponder];
    return;
  }
  if ( self.passwordField.text.length == 0) {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Invalid Password"
                                                                   message:@"Please re-enter your password."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [self presentViewController:alert
                       animated:YES
                     completion:nil];
    
    self.passwordField.text = @"";
    [self.passwordField becomeFirstResponder];
    return;
  }
  
  [self login];
}

-(void)login {
  if ( self.parentViewController && ! [PFUser currentUser] ) {
    [SVProgressHUD showWithStatus:@"Logging in"];
  }
  
  [PFUser logInWithUsernameInBackground:self.emailField.text
                               password:self.passwordField.text
                                  block:^(PFUser *user, NSError *error) {
                                    [SVProgressHUD dismiss];
                                    if (!error) {
                                      [self registerForUserNotifications];
                                      [User initWithUserID:user.username];
                                      if ([User currentUser].validData) {
                                        [[User currentUser] fetchUserInBackground];
                                        [User currentUser].myUserEmail = user.username;
                                        [[User currentUser] updatePFInstallationForUser];
                                        [[NSUserDefaults standardUserDefaults] setObject:[User currentUser].myUserID forKey:kLoggedInUserIDKey];
                                        [[NSUserDefaults standardUserDefaults] synchronize];
                                        [LTHPasscodeViewController sharedUser].userID = [User currentUser].myUserID;
                                        [[NSNotificationCenter defaultCenter] postNotificationName:kUserLoggedInNotification object:nil];
                                        
                                      } else {
                                        [[User currentUser] fetchUserWithUserEmail:user.username
                                                                   completionBlock:^(NSNumber *result) {
                                          if ([result integerValue] == kFetchUserError) {
                                            // problem fetching user so logout
                                            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                                                           message:@"Unable to log in at this time. Please try later."
                                                                                                    preferredStyle:UIAlertControllerStyleAlert];
                                            [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                                                      style:UIAlertActionStyleCancel
                                                                                    handler:nil]];
                                            [self presentViewController:alert
                                                               animated:YES
                                                             completion:nil];
                                            
                                            [[NSNotificationCenter defaultCenter] postNotificationName:kShouldLogoutNotification object:nil];
                                          } else {
                                            [User currentUser].myUserEmail = user.username;
                                            [[User currentUser] getMyData];
                                            [[User currentUser] updatePFInstallationForUser];
                                            
                                            [[NSUserDefaults standardUserDefaults] setObject:[User currentUser].myUserID forKey:kLoggedInUserIDKey];
                                            [[NSUserDefaults standardUserDefaults] synchronize];
                                            [LTHPasscodeViewController sharedUser].userID = [User currentUser].myUserID;
                                            
                                            [[NSNotificationCenter defaultCenter] postNotificationName:kUserLoggedInNotification object:nil];
                                          }
                                        }];
                                      }
                                    } else {
                                      NSString *message;
                                      if (error.code == 100) {
                                        message = @"The internet connection appears to be offline";
                                      } else {
                                        message = [error.userInfo[@"error"] capitalizedString];
                                      }
                                      UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Unable to Log In"
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
                                  }];
  
}

#pragma mark textfield delegate
-(BOOL)textFieldShouldReturn:(UITextField *)textField {
  if (textField == self.emailField) {
    [self.passwordField becomeFirstResponder];
  } else {
    [self validateFields];
    [textField resignFirstResponder];
  }
  
  return YES;
}

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
  CGFloat keyboardHeight = 216;
  CGFloat availableScreen = self.scrollView.frame.size.height - keyboardHeight;
  
  if (textField.frame.origin.y < self.scrollView.contentOffset.y ||
      (textField.frame.origin.y + textField.frame.size.height) > self.scrollView.contentOffset.y + availableScreen ) {
    CGPoint offset = CGPointMake(0, textField.frame.origin.y + textField.frame.size.height + 20 - availableScreen);
    [self.scrollView setContentOffset: offset animated:YES];
  }
  
  return YES;
}

#pragma mark keyboard functions
-(void)keyboardWillShow:(NSNotification *)n {
  NSDictionary *userInfo = [n userInfo];
  
  // get keyboard size
  NSValue *frameValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
  CGFloat keyboardHeight = [frameValue CGRectValue].size.height;
  NSTimeInterval animationDuration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
  
  [UIView animateWithDuration:animationDuration
                   animations:^{
                     self.scrollView.contentInset = UIEdgeInsetsMake(self.scrollView.contentInset.top, 0, keyboardHeight, 0);
                     self.scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(self.scrollView.contentInset.top, 0, keyboardHeight, 0);
                   }
                   completion:NULL];
  
}

-(void)keyboardWillHide:(NSNotification *)n {
  NSDictionary *userInfo = [n userInfo];
  
  // get keyboard size
  NSTimeInterval animationDuration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
  
  [UIView animateWithDuration:animationDuration
                   animations:^{
                     self.scrollView.contentInset = UIEdgeInsetsMake(self.scrollView.contentInset.top, 0, 0, 0);
                     self.scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(self.scrollView.contentInset.top, 0, 0, 0);
                   } completion:NULL];
  
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

- (void)registerForUserNotifications {
  UIUserNotificationType types = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
  
  UIUserNotificationSettings *mySettings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
  
  [[UIApplication sharedApplication] registerUserNotificationSettings:mySettings];
}

@end
