//
//  PartnerStatusController.m
//  Shared
//
//  Created by Brian Bernberg on 3/3/14.
//  Copyright (c) 2014 BB Consulting. All rights reserved.
//

#import "PartnerStatusController.h"
#import "SharedActivityIndicator.h"
#import "SHPalette.h"
#import <MessageUI/MessageUI.h>
#import "Constants.h"
#import "PSPDFAlertView.h"
#import "User.h"
#import "SharedController.h"

#define kSharedPartnerMessage @"I've installed Shared -- an app that allows two people to privately communicate.  You can get it here: https://itunes.apple.com/us/app/shared/id713345046?ls=1&mt=8"

@interface PartnerStatusController () <MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate>

@property (nonatomic, weak) id<ControllerExiting> delegate;
@property (nonatomic, weak) IBOutlet UILabel *checkingLabel;
@property (nonatomic, weak) IBOutlet SharedActivityIndicator *activityIndicator;
@property (nonatomic, weak) IBOutlet UILabel *partnerStatusLabel;
@property (nonatomic, weak) IBOutlet UIButton *emailButton;
@property (nonatomic, weak) IBOutlet UIButton *textButton;
@property (nonatomic, weak) IBOutlet UIButton *notNowButton;
@property (nonatomic, weak) IBOutlet UIButton *cancelButton;
@property (nonatomic) PFQuery *partnerQuery;
@end

@implementation PartnerStatusController

- (instancetype)initWithDelegate:(id<ControllerExiting>)delegate {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _delegate = delegate;
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.view.backgroundColor = [SHPalette darkNavyBlue];
  self.activityIndicator.image = [UIImage imageNamed:@"Shared_Icon_White_Transparent"];
  self.checkingLabel.hidden = NO;
  self.cancelButton.hidden = NO;
  self.partnerStatusLabel.hidden = YES;
  self.emailButton.hidden = YES;
  self.textButton.hidden = YES;
  self.notNowButton.hidden = YES;
  
  [self getPartnerAccountStatus];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  [[UIApplication sharedApplication] setStatusBarHidden:YES];
  
  [self.activityIndicator startAnimating];
  
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  [[UIApplication sharedApplication] setStatusBarHidden:NO];
}

- (void)dealloc {
  [self.partnerQuery cancel];
}

-(void)getPartnerAccountStatus {
  
  __weak PartnerStatusController *wSelf = self;
  
  self.partnerQuery = [PFQuery queryWithClassName:kUserInfoClass];
  if ([[User currentUser] partnerIsFBLogin]) {
    [self.partnerQuery whereKey:kMyFBIDKey equalTo:[User currentUser].partnerFBID];
  } else {
    [self.partnerQuery whereKey:kMyUserEmailKey equalTo:[User currentUser].partnerUserEmail];
  }
  [self.partnerQuery countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
    if (!error) {
      if (number > 0) {
        // Active
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
          [wSelf.delegate controllerRequestsDismissal:wSelf];
        });
      } else {
        // Not signed up
        [wSelf configureForInactivePartner];
      }
    } else {
      // Unkown
      [wSelf.delegate controllerRequestsDismissal:wSelf];
    }
  }];
}

- (void)configureForInactivePartner {
  self.checkingLabel.hidden = YES;
  self.cancelButton.hidden = YES;
  [self.activityIndicator stopAnimating];
  self.partnerStatusLabel.hidden = NO;
  self.emailButton.hidden = NO;
  self.textButton.hidden = NO;
  self.notNowButton.hidden = NO;
}

- (IBAction)emailButtonPressed:(id)sender {

  [PFAnalytics trackEvent:@"Emailed_Partner_Shared"];
  
  if ([MFMailComposeViewController canSendMail] == FALSE) {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Alert"
                                                                   message:@"Your device cannot send e-mail"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [self presentViewController:alert
                       animated:YES
                     completion:nil];
    
  } else {
    MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
    picker.mailComposeDelegate = self;
    
    // Set up recipients
    if ([User currentUser].partnerEmailAddress) {
      NSArray *toRecipients = @[[User currentUser].partnerEmailAddress];
      [picker setToRecipients:toRecipients];
    }
    
    [picker setSubject:@"Shared App"];
    [picker setMessageBody:kSharedPartnerMessage isHTML:NO];
    
    [self presentViewController:picker animated:YES completion:NULL];
  }
  
}

- (IBAction)textButtonPressed:(id)sender {
  [PFAnalytics trackEvent:@"Texted_Partner_Shared"];
  
  if ([MFMessageComposeViewController canSendText] == FALSE) {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Alert"
                                                                   message:@"Your device doesn't suppor this feature."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [self presentViewController:alert
                       animated:YES
                     completion:nil];    
  } else {
    MFMessageComposeViewController *vc = [[MFMessageComposeViewController alloc] init];
    vc.messageComposeDelegate = self;
    [vc setSubject:@"Shared App"];
    [vc setBody:kSharedPartnerMessage];
    [self presentViewController:vc animated:YES completion:NULL];
  }
}

- (IBAction)notNowButtonPressed:(id)sender {
  [PFAnalytics trackEvent:@"Declined_Sending_Shared"];

  [self.delegate controllerRequestsDismissal:self];
  
}

- (IBAction)cancelButtonPressed:(id)sender {
  [self.delegate controllerRequestsDismissal:self];
}

#pragma mark MFMailComposeViewControllerDelegate methods
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
  [controller dismissViewControllerAnimated:YES completion:nil];
  [self.delegate controllerRequestsDismissal:self];
  
}

#pragma mark MFMessageComposeViewControllerDelegate methods
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
  [controller dismissViewControllerAnimated:YES completion:nil];
  [self.delegate controllerRequestsDismissal:self];
}

@end
