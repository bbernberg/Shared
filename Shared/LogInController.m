//
//  LoginViewController.m
//  Shared
//
//  Created by Brian Bernberg on 6/20/12.
//  Copyright (c) 2012 BB Consulting. All rights reserved.
//

#import "LogInController.h"
#import "Parse/Parse.h"
#import "Constants.h"
#import "User.h"
#import "UIButton+myButton.h"
#import "EmailLoginController.h"
#import "SignupController.h"
#import "PSPDFAlertView.h"
#import "SharedActivityIndicator.h"
#import "LTHPasscodeViewController.h"

@interface LogInController ()
@property (nonatomic, weak) IBOutlet UIButton *emailLoginButton;
@property (nonatomic, weak) IBOutlet UIButton *emailSignupButton;
@property (nonatomic, weak) IBOutlet UILabel *alertLabel;
@property (nonatomic, weak) IBOutlet UILabel *loggingInLabel;
@property (nonatomic, weak) IBOutlet SharedActivityIndicator *spinner;
@property (nonatomic, weak) IBOutlet UIButton *dbButton;
@end

@implementation LogInController


#pragma mark lifecycle functions

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  // Return YES for supported orientations
  return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)viewDidLoad {
  [super viewDidLoad];
  self.navigationItem.title = @"Shared";
  self.navigationItem.hidesBackButton = YES;
  self.view.backgroundColor = [UIColor whiteColor];
  self.alertLabel.hidden = YES;
  
  self.spinner.image = [UIImage imageNamed:@"Shared_Icon_Gray_Transparent"];
}

-(void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self.navigationController setNavigationBarHidden:YES];
}

-(void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(IBAction)emailLoginButtonPressed:(id)sender {
  EmailLoginController *vc = [[EmailLoginController alloc] initWithNibName:nil bundle:nil];
  [self.navigationController pushViewController:vc animated:YES];
}

-(IBAction)emailSignupButtonPressed:(id)sender {
  SignupController *vc = [[SignupController alloc] initWithNibName:nil bundle:nil];
  [self.navigationController pushViewController:vc animated:YES];
}

@end
