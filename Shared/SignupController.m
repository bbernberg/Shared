//
//  EmailSignupController.m
//  Shared
//
//  Created by Brian Bernberg on 2/28/13.
//  Copyright (c) 2013 BB Consulting. All rights reserved.
//

#import "SignupController.h"
#import <Parse/Parse.h>
#import "Constants.h"
#import "SVProgressHUD.h"
#import "PSPDFAlertView.h"
#import "PSPDFActionSheet.h"
#import "JVFloatLabeledTextField.h"
#import "LTHPasscodeViewController.h"

@interface SignupController () <UITextFieldDelegate, UIGestureRecognizerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (nonatomic, weak) IBOutlet UIImageView *picture;
@property (nonatomic, weak) IBOutlet UIButton *pictureButton;
@property (nonatomic, weak) IBOutlet JVFloatLabeledTextField *nameField;
@property (nonatomic, weak) IBOutlet JVFloatLabeledTextField *emailField;
@property (nonatomic, weak) IBOutlet JVFloatLabeledTextField *passwordField;
@property (nonatomic, weak) IBOutlet JVFloatLabeledTextField *passwordTwoField;
@property (nonatomic, weak) IBOutlet UIButton *signupButton;
@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *keyboardHeight;
@property (nonatomic, strong) UITapGestureRecognizer *dismissKeyboardTap;

@end

@implementation SignupController

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
  self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed)];
  self.navigationItem.title = @"Sign UP";
  self.view.backgroundColor = [UIColor whiteColor];
  self.automaticallyAdjustsScrollViewInsets = NO;
  self.scrollView.contentSize = CGSizeMake(320, 568);
  self.dismissKeyboardTap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                    action:@selector(dismissKeyboard)];
  self.dismissKeyboardTap.delegate = self;
  
  self.nameField.floatingLabelActiveTextColor = [SHPalette navyBlue];
  self.nameField.floatingLabelTextColor = [SHPalette navyBlue];
  self.nameField.floatingLabel.font = [UIFont systemFontOfSize:12.f];
  
  self.emailField.floatingLabelActiveTextColor = [SHPalette navyBlue];
  self.emailField.floatingLabelTextColor = [SHPalette navyBlue];
  self.emailField.floatingLabel.font = [UIFont systemFontOfSize:12.f];
  
  self.passwordField.floatingLabelActiveTextColor = [SHPalette navyBlue];
  self.passwordField.floatingLabelTextColor = [SHPalette navyBlue];
  self.passwordField.floatingLabel.font = [UIFont systemFontOfSize:12.f];
  
  self.passwordTwoField.floatingLabelActiveTextColor = [SHPalette navyBlue];
  self.passwordTwoField.floatingLabelTextColor = [SHPalette navyBlue];
  self.passwordTwoField.floatingLabel.font = [UIFont systemFontOfSize:12.f];
  
}

-(void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self.navigationController setNavigationBarHidden:NO animated:YES];
  if (self.nameField.text.length > 0) {
    [self.nameField showFloatingLabel];
  }
  if ( self.emailField.text.length > 0) {
    [self.emailField showFloatingLabel];
  }
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

-(void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark button actions
-(void)cancelButtonPressed {
  [self.navigationController popViewControllerAnimated:YES];
}

-(IBAction)pictureButtonPressed:(id)sender {
  PSPDFActionSheet *sheet = [[PSPDFActionSheet alloc] initWithTitle:nil];
  [sheet setCancelButtonWithTitle:@"Cancel" block:NULL];
  [sheet addButtonWithTitle:@"Take Picture" block:^(NSInteger buttonIndex) {
    [self takePicture];
  }];
  [sheet addButtonWithTitle:@"Choose From Library" block:^(NSInteger buttonIndex) {
    [self choosePicture];
  }];
  [sheet showInView:self.view];
}

-(IBAction)signupButtonPressed:(id)sender {
  [self validateFields];
  [self.view endEditing:YES];
}

#pragma mark textfield delegate
-(BOOL)textFieldShouldReturn:(UITextField *)textField {
  if (textField == self.nameField) {
    [self.emailField becomeFirstResponder];
  } else if (textField == self.emailField) {
    [self.passwordField becomeFirstResponder];
  } else if (textField == self.passwordField) {
    [self.passwordTwoField becomeFirstResponder];
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
  
  [self.scrollView addGestureRecognizer:self.dismissKeyboardTap];
  
  // get keyboard size
  NSValue *frameValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
  CGFloat keyboardHeight = [frameValue CGRectValue].size.height;
  NSTimeInterval animationDuration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
  
  self.keyboardHeight.constant += keyboardHeight;
  [self.view setNeedsUpdateConstraints];
  
  [UIView animateWithDuration:animationDuration
                   animations:^{
                     [self.view layoutIfNeeded];
                   }
                   completion:NULL];
  
}

#define kBottomViewConstraint 40

-(void)keyboardWillHide:(NSNotification *)n {
  NSDictionary *userInfo = [n userInfo];
  
  [self.scrollView removeGestureRecognizer:self.dismissKeyboardTap];
  
  // get keyboard size
  NSTimeInterval animationDuration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
  
  self.keyboardHeight.constant = kBottomViewConstraint;
  [self.view setNeedsUpdateConstraints];
  
  [UIView animateWithDuration:animationDuration
                   animations:^{
                     [self.view layoutIfNeeded];
                   } completion:NULL];
  
}

-(void)dismissKeyboard {
  [self.view endEditing:YES];
}

#pragma mark validation
-(void)validateFields {
  if (self.nameField.text.length == 0) {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Invalid Name"
                                                                   message:@"Please enter your name."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [self presentViewController:alert
                       animated:YES
                     completion:nil];
    
    [self.nameField becomeFirstResponder];
    return;
  }
  NSString *email = [self.emailField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  
  if (![self NSStringIsValidEmail:email]) {
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
  
  if (self.passwordField.text.length < 4) {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Invalid Password"
                                                                   message:@"Password must be at least 4 characters. Please re-enter password."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [self presentViewController:alert
                       animated:YES
                     completion:nil];
    
    self.passwordField.text = @"";
    self.passwordTwoField.text = @"";
    [self.passwordField becomeFirstResponder];
    return;
  }
  
  if (![self.passwordField.text isEqualToString:self.passwordTwoField.text]) {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Password Error"
                                                                   message:@"Passwords do not match. Please re-enter password."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [self presentViewController:alert
                       animated:YES
                     completion:nil];
    
    self.passwordField.text = @"";
    self.passwordTwoField.text = @"";
    [self.passwordField becomeFirstResponder];
    return;
    
  }
  
  if (!self.picture.image) {
    [self.view endEditing:YES];
    PSPDFActionSheet *sheet = [[PSPDFActionSheet alloc] initWithTitle:@"Please add a picture of yourself to your profile."];
    [sheet setCancelButtonWithTitle:@"Cancel" block:NULL];
    [sheet addButtonWithTitle:@"Take Picture" block:^(NSInteger buttonIndex) {
      [self takePicture];
    }];
    [sheet addButtonWithTitle:@"Choose Picture" block:^(NSInteger buttonIndex) {
      [self choosePicture];
    }];
    [sheet showInView:self.view];
    return;
  }
  
  [self signup];
}

-(void)signup {
  PFUser *newUser = [PFUser user];
  NSString *email = [[self.emailField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString];
  
  newUser.username = email;
  newUser.email = email;
  newUser.password = self.passwordField.text;
  NSString* name = self.nameField.text;
  
  [SVProgressHUD showWithStatus:@"Signing up..."];
  [newUser signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
    if (succeeded) {
      [SVProgressHUD showSuccessWithStatus:@"Success!"];
      [User newUserWithUserID:newUser.username];
      [User currentUser].myUserEmail = newUser.username;
      [User currentUser].myName = name;
      if (self.picture.image) {
        [User currentUser].myPicture = self.picture.image;
      }
      
      [[User currentUser] saveUser];
      [[User currentUser] updatePFInstallationForUser];
      
      [[NSUserDefaults standardUserDefaults] setObject:[User currentUser].myUserID forKey:kLoggedInUserIDKey];
      [[NSUserDefaults standardUserDefaults] synchronize];
      [LTHPasscodeViewController sharedUser].userID = [User currentUser].myUserID;
      
      dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kNewUserLoggedInNotification object:nil];
      });
      NSLog(@"New user...");
    } else {
      dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD dismiss];
        NSString *message = @"Unable to sign up at this time. Please try later.";
        if (error.code == kPFErrorUsernameTaken || error.code == kPFErrorUserEmailTaken) {
          message = @"Unable to sign up.  There is an account already affiliated with the e-mail address.";
        }
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [self presentViewController:alert
                           animated:YES
                         completion:nil];
      });
    }
  }];
}

#pragma mark take picture methods
-(void)takePicture {
  UIImagePickerController *imgPicker = [[UIImagePickerController alloc] init];
  imgPicker.delegate = self;
  if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
    imgPicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront]) {
      imgPicker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
    }
    [self presentViewController:imgPicker animated:NO completion:NULL];
  } else {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:@"Sorry, your device is unable to take photos."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [self presentViewController:alert
                       animated:YES
                     completion:nil];    
  }
  
}

-(void)choosePicture {
  UIImagePickerController *imgPicker = [[UIImagePickerController alloc] init];
  imgPicker.delegate = self;
  if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
    imgPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:imgPicker animated:YES completion:NULL];
  } else {
    UIAlertView *noPhotoAlert = [[UIAlertView alloc] initWithTitle:nil message:@"Sorry, your device does not support photos" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [noPhotoAlert show];
    
  }
}

#pragma mark Image Picker functions
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
  UIImage *newPicture = [info objectForKey:UIImagePickerControllerOriginalImage];
  newPicture = [kAppDelegate scaleAndRotateImage: newPicture maxResolution:480];
  self.picture.image = newPicture;
  
  [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
  [self dismissViewControllerAnimated:YES completion:NULL];
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
