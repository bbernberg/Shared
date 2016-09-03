//
//  AboutViewController.m
//  Shared
//
//  Created by Brian Bernberg on 11/27/12.
//  Copyright (c) 2012 BB Consulting. All rights reserved.
//

#import "AboutController.h"
#import "UIButton+myButton.h"
#import "Constants.h"
#import "PSPDFAlertView.h"

@interface AboutController ()
@property (nonatomic, weak) IBOutlet UIButton *contactButton;
@property (nonatomic, weak) IBOutlet UILabel *llcLabel;
@property (nonatomic, weak) IBOutlet UILabel *thankYouLabel;
@property (nonatomic, weak) IBOutlet UITextView *creditTextView;
@property (nonatomic, weak) IBOutlet UILabel *srpLabel;
@property (nonatomic, weak) IBOutlet UILabel *versionLabel;
@property (nonatomic, strong) UIScrollView *scrollView;

-(IBAction)contactButtonPressed:(id)sender;

@end

@implementation AboutController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    // Custom initialization
    self.title = @"About";
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  // Do any additional setup after loading the view from its nib.
  self.view.backgroundColor = [UIColor whiteColor];
  
  self.scrollView = [[UIScrollView alloc] initWithFrame: CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
  self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  self.scrollView.alwaysBounceHorizontal = NO;
  self.scrollView.showsHorizontalScrollIndicator = NO;
  self.scrollView.showsVerticalScrollIndicator = YES;
  
  UIView *aboutView = (UIView *)([[NSBundle mainBundle] loadNibNamed:@"AboutViewContent" owner:self options:nil][0]);
  aboutView.frame = CGRectMake(0.f, 0.f, self.scrollView.frameSizeWidth, aboutView.frameSizeHeight);
  [self.scrollView addSubview:aboutView];
  self.scrollView.contentSize = aboutView.frame.size;
  
  [self.view addSubview:self.scrollView];
  
  [self.contactButton customizeSimpleButton];
  self.llcLabel.font = [kAppDelegate globalFontWithSize:18.0];
  self.thankYouLabel.font = [kAppDelegate globalFontWithSize:18.0];
  self.creditTextView.font = [kAppDelegate globalFontWithSize:15.0];
  self.srpLabel.font = [kAppDelegate globalItalicFontWithSize:18.0];
  
  NSDictionary* info = [[NSBundle mainBundle] infoDictionary];
  self.versionLabel.text = [NSString stringWithFormat:@"Version %@", info[@"CFBundleVersion"]];
  
}

-(void)contactButtonPressed:(id)sender {
  if ([MFMailComposeViewController canSendMail] == FALSE) {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:@"Sorry, your device is unable to send e-mail"
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
    NSArray *toRecipients = [NSArray arrayWithObject:@"support@SharedApp.us"];
    
    [picker setToRecipients:toRecipients];
    
    [self presentViewController:picker animated:YES completion:NULL];
  }
}

#pragma mark MFMailComposeViewControllerDelegate
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
  
  [self dismissViewControllerAnimated:NO completion: ^{
    [[NSNotificationCenter defaultCenter] postNotificationName:kPopToMainNotification object:self];
  }];
}

@end
