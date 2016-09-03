//
//  TextVoiceMessageCell.m
//  Shared
//
//  Created by Brian Bernberg on 11/20/13.
//  Copyright (c) 2013 BB Consulting. All rights reserved.
//

#import "TextVoiceMessageCell.h"
#import "DDProgressView.h"
#import "UIButton+myButton.h"
#import "User.h"
#import "UIView+Helpers.h"

#define kTextCellXPadding 4.f
#define kPortraitCenterX 26
#define kMyVoicePlaybackContainerX 180
#define kPartnerVoicePlaybackContainerX 134
#define kMyBackgroundColor [SHPalette darkNavyBlue];
#define kPartnerBackgroundColor [UIColor colorWithRed:0.98f green:0.98f blue:0.98f alpha:1.f];

@interface TextVoiceMessageCell ()

@property (nonatomic, strong) UIImageView *ownerImageView;
@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

@implementation TextVoiceMessageCell

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
  self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
  if (self) {
    // background view
    self.background = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width - 54.f - kTextCellXPadding, 56)];
    self.background.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.background.layer.shadowOffset = CGSizeMake(0, 1.0);
    self.background.layer.shadowRadius = 1.0;
    self.background.layer.shadowOpacity = 0.6;
    [self.contentView addSubview:self.background];
    
    // playback container view
    self.containerView = [[UIView alloc] initWithFrame:self.background.bounds];
    self.containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.containerView.backgroundColor = [UIColor clearColor];
    [self.background addSubview:self.containerView];
    
    // playback button
    self.playbackButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.playbackButton.backgroundColor = [UIColor blackColor];
    self.playbackButton.frame = CGRectMake(10, 12, 40, 32);
    self.playbackButton.autoresizingMask =  UIViewAutoresizingFlexibleRightMargin |UIViewAutoresizingFlexibleBottomMargin;
    self.playbackButtonIV = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"play"]];
    self.playbackButtonIV.userInteractionEnabled = NO;
    self.playbackButtonIV.frame = CGRectMake(12.0, 8.0, 16.0, 16.0);
    [self.playbackButton addSubview:self.playbackButtonIV];
    [self.containerView addSubview:self.playbackButton];

    // Duration label
    self.durationLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.containerView.frameSizeWidth - 40.f, 17, 39, 22)];
    self.durationLabel.font = [kAppDelegate globalFontWithSize:17.0];
    self.durationLabel.textColor = [UIColor blackColor];
    self.durationLabel.backgroundColor = [UIColor clearColor];
    self.durationLabel.textAlignment = NSTextAlignmentLeft;
    self.durationLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.durationLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [self.containerView addSubview:self.durationLabel];
    
    // progress view
    CGFloat pvWidth = self.durationLabel.frameOriginX - 66.f;
    self.progressView = [[DDProgressView alloc] initWithFrame: CGRectMake(56, 17.0f, pvWidth, 0.0f)] ;
    self.progressView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.progressView setOuterColor: [UIColor clearColor]];
    [self.progressView setEmptyColor: [UIColor blackColor]];
    [self.progressView setInnerColor: [UIColor lightGrayColor]];
    self.progressView.progress = 0.0;
    [self.containerView addSubview:self.progressView];
    
    // owner image view
    self.ownerImageView = [[UIImageView alloc] initWithFrame:CGRectMake(8, 0, 40, 40)];
    self.ownerImageView.contentMode = UIViewContentModeScaleToFill;
    self.ownerImageView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    [[self class] configureViewBorder:self.ownerImageView
                      withBorderWidth:2.0f
                      andShadowOffset:3.0
                      andShadowRadius:3.0
                             andColor:[UIColor whiteColor]];
    [self.contentView addSubview:self.ownerImageView];
   
    // Date label
    self.dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(75, 60, 160, 18)];
    self.dateLabel.font = [kAppDelegate globalFontWithSize:14.0];
    self.dateLabel.textColor = [UIColor darkGrayColor];
    self.dateLabel.backgroundColor = [UIColor clearColor];
    self.dateLabel.textAlignment = NSTextAlignmentCenter;
    self.dateLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    [self.contentView addSubview:self.dateLabel];
    
    // Resend button
    self.resendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.resendButton.frame = CGRectMake(218, 58, 30, 18);
    [self.resendButton setBackgroundImage:[UIImage imageNamed:@"BlackBackground"]
                            forState:UIControlStateNormal];
    [self.resendButton customizeButton];
    UIImageView *resendIV = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"resend"]];
    resendIV.frame = CGRectMake(10, 4, 10, 10);
    resendIV.backgroundColor = [UIColor clearColor];
    resendIV.userInteractionEnabled = FALSE;
    resendIV.exclusiveTouch = FALSE;
    [self.resendButton addSubview:resendIV];
    [self.contentView addSubview:self.resendButton];
    
    // Delete button
    self.deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.deleteButton.frame = CGRectMake(63, 58, 20, 20);
    [self.deleteButton setBackgroundImage:[[UIImage imageNamed:@"Badge"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                                 forState:UIControlStateNormal];
    self.deleteButton.tintColor = [SHPalette darkRedColor];
    [self.contentView addSubview:self.deleteButton];
    
    // date formatter
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setDateFormat:@"EEE, MMM d h:mma"];
    
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.spinner.center = self.progressView.center;
    [self.containerView addSubview:self.spinner];
    
  }
  return self;
}

- (void)setText:(PFObject *)text {
  _text = text;

  self.durationLabel.text = _text[kMessageKey];
  
  // Owner Image View & background view
  if ( [[User currentUser].myUserIDs containsObject:_text[kSenderKey]] ) {
    self.ownerImageView.image = [User currentUser].mySmallPicture;
    self.background.backgroundColor = kMyBackgroundColor;
    self.durationLabel.textColor = [UIColor whiteColor];
    self.spinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
  } else {
    self.ownerImageView.image = [User currentUser].partnerSmallPicture;
    self.background.backgroundColor = kPartnerBackgroundColor;
    self.durationLabel.textColor = [UIColor blackColor];
    self.spinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
  }
  self.ownerImageView.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.ownerImageView.layer.bounds].CGPath;
  
  // Date Label
  if ( [_text[kSendStatusKey] isEqualToString:kSendError] ) {
    self.dateLabel.text = @"Failed to Send";
    self.dateLabel.textColor = [UIColor redColor];
    self.resendButton.frame = CGRectMake(self.resendButton.frame.origin.x,
                                        self.dateLabel.frame.origin.y,
                                        self.resendButton.frame.size.width,
                                        self.resendButton.frame.size.height);
    self.resendButton.hidden = NO;
  } else if ( [_text[kSendStatusKey] isEqualToString:kSendPending] ) {
    self.dateLabel.text = @"Sending...";
    self.dateLabel.textColor = [UIColor darkTextColor];
    self.resendButton.hidden = YES;
  } else  {
    self.dateLabel.text = [self.dateFormatter stringFromDate:_text[kMyCreatedAtKey]];
    self.dateLabel.textColor = [UIColor darkTextColor];
    self.resendButton.hidden = YES;
  }
 
  // File
  PFFile *file = text[kTextVoiceMessageKey];
  if ( file.isDirty && !file.url ) {
    text[kTextVoiceMessageKey] = [PFFile fileWithData:[NSData dataWithContentsOfFile:pathInDocumentDirectory(text[kTextLocalFilePathKey])]];
  }
  [self setNeedsLayout];
}

- (void)layoutSubviews {
  [super layoutSubviews];
  
  if ( [[User currentUser].myUserIDs containsObject:_text[kSenderKey]] ) {
    self.ownerImageView.center = CGPointMake(kPortraitCenterX, self.ownerImageView.center.y);
    [self.background setFrameOriginX:54.f];
  } else {
    self.ownerImageView.center = CGPointMake(self.contentView.frameSizeWidth - kPortraitCenterX, self.ownerImageView.center.y);
    [self.background setFrameOriginX:kTextCellXPadding];
  }
  
  [self.dateLabel sizeToFit];
  self.dateLabel.center = CGPointMake(roundf(self.contentView.frameSizeWidth / 2.f), self.dateLabel.center.y);
  self.resendButton.center = CGPointMake(roundf(self.dateLabel.center.x + self.dateLabel.frameSizeWidth / 2.f + self.resendButton.frameSizeWidth / 2.f + 10.f), self.resendButton.center.y);
  self.deleteButton.center = CGPointMake(roundf(self.dateLabel.center.x - self.dateLabel.frameSizeWidth / 2.f - self.deleteButton.frameSizeWidth / 2.f - 10.f), self.deleteButton.center.y);
}

+(void)configureViewBorder:(UIView *)theView
           withBorderWidth:(CGFloat)borderWidth
           andShadowOffset:(CGFloat)theShadowOffset
           andShadowRadius:(CGFloat)theShadowRadius
                  andColor:(UIColor *)theColor {
  CALayer* layer = [theView layer];
  [layer setBorderWidth:borderWidth];
  [layer setBorderColor:theColor.CGColor];
  [layer setShadowOffset:CGSizeMake(-theShadowOffset, theShadowOffset)];
  [layer setShadowRadius:theShadowRadius];
  [layer setShadowOpacity:0.6];
}

@end
