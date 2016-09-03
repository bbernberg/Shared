//
//  ProfileController.m
//  Shared
//
//  Created by Brian Bernberg on 3/9/13.
//  Copyright (c) 2013 BB Consulting. All rights reserved.
//

#import "ProfileController.h"
#import "PSPDFAlertView.h"
#import "User.h"
#import "Constants.h"
#import "PSPDFActionSheet.h"

@interface ProfileController () <UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate>
@property (nonatomic, weak) IBOutlet UIImageView *picture;
@property (nonatomic, weak) IBOutlet UILabel *accountLabel;
@property (nonatomic, weak) IBOutlet UITextField *nameField;
@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic, weak) IBOutlet UIButton *tapPictureButton;
@property (nonatomic, weak) IBOutlet UILabel *tapPictureLabel;
@property (nonatomic, strong) UITapGestureRecognizer *dismissKeyboardTap;
@end

@implementation ProfileController

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
  self.navigationItem.title = @"Your Profile";
  if ([[User currentUser] myPictureExists]) {
    self.picture.image = [User currentUser].myPicture;
  }
  
  self.accountLabel.text = [User currentUser].myUserEmail;
  self.nameField.text = [User currentUser].myName;
  self.view.backgroundColor = [SHPalette backgroundColor];
  self.scrollView.contentSize = self.view.frame.size;
  self.dismissKeyboardTap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                    action:@selector(dismissKeyboard)];
  self.dismissKeyboardTap.delegate = self;
  self.scrollView.contentSize = CGSizeMake(320, 240);
  
}

-(void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  self.picture.center = CGPointMake(self.accountLabel.center.x, self.picture.center.y);
  self.tapPictureButton.center = CGPointMake(self.picture.center.x, self.tapPictureButton.center.y);
  self.tapPictureLabel.center = CGPointMake(self.picture.center.x, self.tapPictureLabel.center.y);
}

#pragma mark button method
-(IBAction)pictureButtonTapped:(id)sender {
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

#pragma mark textfield delegate
-(BOOL)textFieldShouldReturn:(UITextField *)textField {
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
    return NO;
  }
  if (![[User currentUser].myName isEqualToString:textField.text]) {
    [User currentUser].myName = textField.text;
    [[User currentUser] saveUser];
  }
  [textField resignFirstResponder];
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
  
  [UIView animateWithDuration:animationDuration
                   animations:^{
                     self.scrollView.contentInset = UIEdgeInsetsMake(self.scrollView.contentInset.top,
                                                                     self.scrollView.contentInset.left,
                                                                     keyboardHeight,
                                                                     self.scrollView.contentInset.right);
                     self.scrollView.scrollIndicatorInsets = self.scrollView.contentInset;
                   }
                   completion:NULL];
  
}

-(void)keyboardWillHide:(NSNotification *)n {
  NSDictionary *userInfo = [n userInfo];
  
  [self.scrollView removeGestureRecognizer:self.dismissKeyboardTap];
  
  // get keyboard size
  NSTimeInterval animationDuration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
  
  [UIView animateWithDuration:animationDuration
                   animations:^{
                     self.scrollView.contentInset = UIEdgeInsetsMake(self.scrollView.contentInset.top,
                                                                     self.scrollView.contentInset.left,
                                                                     0.0,
                                                                     self.scrollView.contentInset.right);
                     self.scrollView.scrollIndicatorInsets = self.scrollView.contentInset;
                   } completion:NULL];
  
}

-(void)dismissKeyboard {
  [self.view endEditing:YES];
}

#pragma mark Image Picker functions
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
  UIImage *newPicture = [info objectForKey:UIImagePickerControllerOriginalImage];
  newPicture = [kAppDelegate scaleAndRotateImage: newPicture maxResolution:480];
  self.picture.image = newPicture;
  [User currentUser].myPicture = newPicture;
  [[User currentUser] saveUser];
  [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
  [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
