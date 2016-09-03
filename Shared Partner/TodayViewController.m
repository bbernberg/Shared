//
//  TodayViewController.m
//  Shared Partner
//
//  Created by Brian Bernberg on 9/21/15.
//  Copyright © 2015 BB Consulting. All rights reserved.
//

#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>

#define kSharedAppGroup @"group.SharedSoftware.Shared"
#define kAppGroupLoggedInKey @"loggedIn"
#define kAppGroupHasPartnerKey @"hasPartner"
#define kAppGroupPartnerNameKey @"partnerName"
#define kAppGroupPartnerPictureKey @"partnerPicture"
#define kAppGroupPartnerCallNumberKey @"partnerPhoneNumber"
#define kAppGroupPartnerFaceTimeNumberKey @"partnerFaceTime"

@interface TodayViewController () <NCWidgetProviding>
@property (nonatomic, weak) IBOutlet UIImageView *partnerImageView;
@property (nonatomic, weak) IBOutlet UILabel *partnerLabel;
@property (nonatomic, weak) IBOutlet UIButton *messageButton;
@property (nonatomic, weak) IBOutlet UIButton *callButton;
@property (nonatomic, weak) IBOutlet UIButton *ftVideoButton;
@property (nonatomic, weak) IBOutlet UIButton *ftAudioButton;
@property (nonatomic, weak) IBOutlet UIButton *statusButton;
@property (nonatomic) NSUserDefaults *defaults;
@end

@implementation TodayViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.defaults = [[NSUserDefaults alloc] initWithSuiteName:kSharedAppGroup];
  
  if ( [self.defaults boolForKey:kAppGroupLoggedInKey] && [self.defaults boolForKey:kAppGroupHasPartnerKey] ) {
    [self.messageButton setImage:[self buttonImageWithPicture:[UIImage imageNamed:@"comment"] text:@"Message"] forState:UIControlStateNormal];
    [self.callButton setImage:[self buttonImageWithPicture:[UIImage imageNamed:@"phone"] text:@"Call"] forState:UIControlStateNormal];
    [self.ftVideoButton setImage:[self buttonImageWithPicture:[UIImage imageNamed:@"facetime"] text:@"Video"] forState:UIControlStateNormal];
    [self.ftAudioButton setImage:[self buttonImageWithPicture:[UIImage imageNamed:@"facetime"] text:@"Audio"] forState:UIControlStateNormal];
    
    self.callButton.enabled = [self.defaults stringForKey:kAppGroupPartnerCallNumberKey].length > 0 ;
    self.ftVideoButton.enabled = self.ftAudioButton.enabled = [self.defaults stringForKey:kAppGroupPartnerFaceTimeNumberKey].length > 0;
    NSData *pictureData = [self.defaults objectForKey:kAppGroupPartnerPictureKey];
    if ( pictureData ) {
      self.partnerImageView.image = [UIImage imageWithData:pictureData];
    }
    self.partnerImageView.layer.borderWidth = 1.f;
    self.partnerImageView.layer.borderColor = [UIColor whiteColor].CGColor;
    self.partnerLabel.text = [self.defaults objectForKey:kAppGroupPartnerNameKey];
  } else {
    self.messageButton.hidden = YES;
    self.callButton.hidden = YES;
    self.ftVideoButton.hidden = YES;
    self.ftAudioButton.hidden = YES;
    self.partnerLabel.hidden = YES;
    self.partnerImageView.hidden = YES;
    self.statusButton.hidden = NO;
    UILabel *label = [[UILabel alloc] initWithFrame:self.statusButton.bounds];
    label.font = [UIFont boldSystemFontOfSize:14.f];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor darkGrayColor];
    label.text = [self.defaults boolForKey:kAppGroupLoggedInKey] ? @"Choose Partner" : @"Log In";
    label.layer.cornerRadius = 8.f;
    label.layer.borderColor = [UIColor darkGrayColor].CGColor;
    label.layer.borderWidth = 2.f;
    [self.statusButton setImage:[[self class] grabImageFromView:label] forState:UIControlStateNormal];
    
    
  }
}

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
  completionHandler(NCUpdateResultNoData);
}

- (UIEdgeInsets)widgetMarginInsetsForProposedMarginInsets:(UIEdgeInsets)defaultMarginInsets {
  return UIEdgeInsetsZero;
}

#pragma mark button handlers
- (IBAction)messageButtonPressed:(UIButton *)button {
  [self.extensionContext openURL:[NSURL URLWithString:@"shared-app://text"] completionHandler:nil];
}

- (IBAction)callButtonPressed:(UIButton *)button {
  NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"tel:%@", [[self.defaults stringForKey:kAppGroupPartnerCallNumberKey] stringByReplacingOccurrencesOfString:@" " withString:@""]]];
  
  [self.extensionContext openURL:url completionHandler:nil];
}

- (IBAction)ftVideoButtonPressed:(UIButton *)button {
  NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"facetime://%@", [[self.defaults stringForKey:kAppGroupPartnerFaceTimeNumberKey] stringByReplacingOccurrencesOfString:@" " withString:@""]]];
  
  [self.extensionContext openURL:url completionHandler:nil];
}

- (IBAction)ftAudioButtonPressed:(UIButton *)button {
  NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"facetime-audio://%@", [[self.defaults stringForKey:kAppGroupPartnerFaceTimeNumberKey] stringByReplacingOccurrencesOfString:@" " withString:@""]]];
  
  [self.extensionContext openURL:url completionHandler:nil];
  
}

- (IBAction)statusButtonPressed:(UIButton *)button {
  [self.extensionContext openURL:[NSURL URLWithString:@"shared-app://"] completionHandler:nil];
}

- (void)viewTapped:(UIGestureRecognizer *)recognizer {
  [self.extensionContext openURL:[NSURL URLWithString:@"shared-app://"] completionHandler:nil];
}

#pragma mark utility methods
- (UIImage *)buttonImageWithPicture:(UIImage *)image text:(NSString *)text {
  UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, 50.f, 40.f)];
  UIImageView *iv = [[UIImageView alloc] initWithImage:image];
  iv.contentMode = UIViewContentModeScaleAspectFit;
  iv.frame = CGRectMake(0.f, 0.f, container.frame.size.width, roundf(container.frame.size.height * 0.56f));
  [container addSubview:iv];
  UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.f, roundf(container.frame.size.height * 0.6f), container.frame.size.width, roundf(container.frame.size.height * 0.4f))];
  label.text = text;
  label.font = [UIFont systemFontOfSize:10.f];
  label.textAlignment = NSTextAlignmentCenter;
  label.textColor = [UIColor whiteColor];
  [container addSubview:label];
  
  return [[self class] grabImageFromView:container];
}

+ (UIImage *)grabImageFromView:(UIView *)view {
  UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, 0.0);
  
  [view.layer renderInContext:UIGraphicsGetCurrentContext()];
  UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return viewImage;
  
}


@end
