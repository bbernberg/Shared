//
//  GlympseTextCell.m
//  Shared
//
//  Created by Brian Bernberg on 7/19/15.
//  Copyright (c) 2015 BB Consulting. All rights reserved.
//

#import "GlympseTextCell.h"
#import "SharedAppDelegate.h"
#import "UIButton+myButton.h"
#import "UIView+Helpers.h"
#import "NSString+SHString.h"

#define kMyBackgroundColor [SHPalette darkNavyBlue];
#define kPartnerBackgroundColor [UIColor colorWithRed:0.98f green:0.98f blue:0.98f alpha:1.f];
#define kTextCellXPadding 4.f
#define kTextLabelFontSize 18.0
#define kTextPaddingHeight 8
#define kPortraitCenterX 26
#define kTextPhotoWidth 160
#define kCellContentY 8
#define kDateLabelHeight 18
#define kDateLabelOffset 6
#define kCellPaddingHeight 10
#define kMinimumTextCellHeight 56.0f
#define kLocationIconSide 20.f
#define kLabelInset 86

@interface GlympseTextCell ()
@property (nonatomic) UIImageView *locationIcon;
@property (nonatomic) NSDateFormatter *dateFormatter;
@property (nonatomic) UIImageView *ownerImageView;
@property (nonatomic) UILabel *label;
@property (nonatomic) UILabel *dateLabel;
@property (nonatomic) UIImageView *chevron;

@end

@implementation GlympseTextCell

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
  self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
  if (self) {
    // message view
    self.textView = [[UIView alloc] init];
    self.textView.backgroundColor = [UIColor whiteColor];
    self.textView.layer.cornerRadius = 2.0;
    self.textView.layer.shadowOffset = CGSizeMake(0, 1.0);
    self.textView.layer.shadowRadius = 1.0;
    self.textView.layer.shadowOpacity = 0.6;
    [self.contentView addSubview:self.textView];
    
    UIImage *image = [[UIImage imageNamed:@"Location"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.locationIcon = [[UIImageView alloc] initWithImage:image];
    self.locationIcon.frameSize = CGSizeMake(kLocationIconSide, kLocationIconSide);
    [self.textView addSubview:self.locationIcon];
    
    image = [[UIImage imageNamed:@"Chevron"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.chevron = [[UIImageView alloc] initWithImage:image];
    [self.chevron sizeToFit];
    [self.textView addSubview:self.chevron];
    
    
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
    
    // Text label
    self.label = [[UILabel alloc] init];
    self.label.font = [kAppDelegate globalFontWithSize:18.f];
    self.label.textColor = [UIColor blackColor];
    self.label.backgroundColor = [UIColor clearColor];
    self.label.textAlignment = NSTextAlignmentLeft;
    self.label.numberOfLines = 0;
    self.label.lineBreakMode = NSLineBreakByWordWrapping;
    [self.textView addSubview:self.label];
    
    // Date label
    self.dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(87, 147, 160, 18)];
    self.dateLabel.font = [kAppDelegate globalFontWithSize:14.0];
    self.dateLabel.textColor = [UIColor darkGrayColor];
    self.dateLabel.backgroundColor = [UIColor clearColor];
    self.dateLabel.textAlignment = NSTextAlignmentCenter;
    self.dateLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    [self.contentView addSubview:self.dateLabel];
    
    // Resend button
    self.resendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.resendButton.frame = CGRectMake(227, 147, 30, 18);
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
        
    // date formatter
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setDateFormat:@"EEE, MMM d h:mma"];
    
  }
  return self;
}

- (void)setText:(PFObject *)text {
  _text = text;
  
  BOOL isActive = [text[kGlympseExpireDateKey] compare:[NSDate date]] == NSOrderedDescending;
  
  // Owner Image View
  if ( [[User currentUser].myUserIDs containsObject:self.text[kSenderKey]] ) {
    self.ownerImageView.image = [User currentUser].mySmallPicture;
    self.textView.backgroundColor = kMyBackgroundColor;
    self.label.textColor = [UIColor whiteColor];
    self.locationIcon.tintColor = isActive ? [SHPalette kellyGreen] : [UIColor whiteColor];
    self.chevron.tintColor = [UIColor whiteColor];
  } else {
    self.ownerImageView.image = [User currentUser].partnerSmallPicture;
    self.textView.backgroundColor = kPartnerBackgroundColor;
    self.label.textColor = [UIColor blackColor];
    self.locationIcon.tintColor = isActive ? [SHPalette kellyGreen] : [UIColor blackColor];
    self.chevron.tintColor = [UIColor blackColor];
  }
  
  self.label.attributedText = [[self class] attributedStringForText:self.text];
  
  // Date label
  if ( [self.text[kSendStatusKey] isEqualToString:kSendError] ) {
    self.dateLabel.text = @"Failed to Send";
    self.dateLabel.textColor = [UIColor redColor];
    self.resendButton.hidden = NO;
  } else if ( [self.text[kSendStatusKey] isEqualToString:kSendPending] ) {
    self.dateLabel.text = @"Sending...";
    self.dateLabel.textColor = [UIColor darkTextColor];
    self.resendButton.hidden = YES;
  } else  {
    self.dateLabel.text = [self.dateFormatter stringFromDate:self.text[kMyCreatedAtKey]];
    self.dateLabel.textColor = [UIColor darkTextColor];
    self.resendButton.hidden = YES;
  }
  
  [self setNeedsLayout];
}

- (void)layoutSubviews {
  [super layoutSubviews];
  
  self.textView.frame = CGRectMake(kTextCellXPadding,
                                   0.f,
                                   self.frame.size.width - 54.f - kTextCellXPadding,
                                   30.f);
  
  CGRect textViewFrame = self.textView.frame;
  textViewFrame.size.height = [[self class] textCellBackgroundHeightForText:self.text cellWidth:self.frameSizeWidth];
  BOOL isMyText = [[User currentUser].myUserIDs containsObject:self.text[kSenderKey]];
  textViewFrame.origin.x = isMyText ? 54.f : kTextCellXPadding;
  self.textView.frame = textViewFrame;
  
  self.locationIcon.center = CGPointMake(roundf(self.textView.frameSizeWidth / 2.f), 20.f);
  self.chevron.center = CGPointMake(self.textView.frameSizeWidth - self.chevron.frameSizeWidth - 1.f,
                                    roundf(self.textView.frameSizeHeight / 2.f));
  
  float YOffset = self.locationIcon.frameOriginY + self.locationIcon.frameSizeHeight + 5.f;
  
  CGFloat labelHeight = [self.label.attributedText integralHeightGivenWidth:(self.frameSizeWidth - kLabelInset)];
  self.label.frame = CGRectMake(8.f, YOffset, self.frameSizeWidth - kLabelInset, labelHeight);
  YOffset = self.label.frameOriginY + self.label.frameSizeHeight + kTextPaddingHeight;
  
  // Owner Image View
  self.ownerImageView.center = CGPointMake(isMyText ? kPortraitCenterX : self.contentView.frameSizeWidth - kPortraitCenterX,
                                           self.ownerImageView.center.y);
  
  // Date Label
  [self.dateLabel sizeToFit];
  self.dateLabel.center = CGPointMake(roundf(self.contentView.frameSizeWidth / 2.f), YOffset + 12.f);
  
  self.resendButton.center = CGPointMake(roundf(self.dateLabel.center.x + self.dateLabel.frameSizeWidth / 2.f + self.resendButton.frameSizeWidth / 2.f + 10.f), self.dateLabel.center.y);
  
}


#pragma mark helper methods
+ (NSAttributedString *)attributedStringForText:(PFObject *)text {
  static NSDateFormatter *dateFormatter = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"EEE, MMM d h:mma"];
  });
  
  CGFloat subjectFontSize = 16.f;;
  CGFloat fontSize = 18.f;
  
  NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] init];

  if ( text[kGlympseDestinationKey] ) {
    NSMutableAttributedString *subString = [[NSMutableAttributedString alloc] initWithString:@"Destination: "];
    [subString addAttributeForFont:[UIFont boldSystemFontOfSize:subjectFontSize]];
    [attrString appendAttributedString:subString];
    NSString *dest = [text[kGlympseDestinationKey] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    subString = [[NSMutableAttributedString alloc] initWithString:dest];
    [subString addAttributeForFont:[UIFont systemFontOfSize:fontSize]];
    [attrString appendAttributedString:subString];
  }
  
  if ( text[kMessageKey] ) {
    NSMutableAttributedString *subString = [[NSMutableAttributedString alloc] initWithString:[attrString.string length] > 0 ? @"\nMessage: " : @"Message: "];
    [subString addAttributeForFont:[UIFont boldSystemFontOfSize:subjectFontSize]];
    [attrString appendAttributedString:subString];
    subString = [[NSMutableAttributedString alloc] initWithString:text[kMessageKey]];
    [subString addAttributeForFont:[UIFont systemFontOfSize:fontSize]];
    [attrString appendAttributedString:subString];
  }
  
  if ( [text[kGlympseExpireDateKey] compare:[NSDate date]] == NSOrderedDescending ) {
    NSMutableAttributedString *subString = [[NSMutableAttributedString alloc] initWithString:[attrString.string length] > 0 ? @"\nExpires: " : @"Expires: "];
    [subString addAttributeForFont:[UIFont boldSystemFontOfSize:subjectFontSize]];
    [attrString appendAttributedString:subString];
    subString = [[NSMutableAttributedString alloc] initWithString:[dateFormatter stringFromDate:text[kGlympseExpireDateKey]]];
    [subString addAttributeForFont:[UIFont systemFontOfSize:fontSize]];
    [attrString appendAttributedString:subString];
  }
  
  if ( [attrString length] == 0 ) {
    NSMutableAttributedString *subString = [[NSMutableAttributedString alloc] initWithString:@"Sent a Glympse"];
    [subString addAttributeForFont:[UIFont systemFontOfSize:fontSize]];
    [attrString appendAttributedString:subString];
  }
  return attrString;
}

+(CGFloat)textCellBackgroundHeightForText:(PFObject *)text cellWidth:(CGFloat)cellWidth {
  CGFloat YOffset = kCellContentY + kLocationIconSide + 5.f;
  
  NSAttributedString *attrString = [[self class] attributedStringForText:text];
  CGFloat labelHeight = [attrString integralHeightGivenWidth:cellWidth - kLabelInset];
  YOffset += labelHeight + 10.f;
  
  return YOffset;
  
}

+ (CGFloat)textCellHeightForText:(PFObject *)text cellWidth:(CGFloat)cellWidth {
  CGFloat cellHeight = [self textCellBackgroundHeightForText:text cellWidth:cellWidth];
  return cellHeight + kDateLabelOffset + kDateLabelHeight + kCellPaddingHeight;
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
