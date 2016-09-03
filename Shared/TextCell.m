//
//  TextCell.m
//  Shared
//
//  Created by Brian Bernberg on 11/20/13.
//  Copyright (c) 2013 BB Consulting. All rights reserved.
//

#import "TextCell.h"
#import "TTTAttributedLabel.h"
#import "UIButton+myButton.h"
#import "NSString+SHString.h"
#import "UIView+Helpers.h"

#define kMyBackgroundColor [SHPalette darkNavyBlue];
#define kPartnerBackgroundColor [UIColor colorWithRed:0.98f green:0.98f blue:0.98f alpha:1.f];

#define kTextCellXPadding 4.f
#define kTextLabelFontSize 18.0
#define kTextPaddingHeight 8
#define kPortraitViewCenterX 26
#define kTextPhotoWidth 160
#define kTextPhotoDefaultHeight 200
#define kCellContentY 8
#define kDateLabelHeight 18
#define kDateLabelOffset 6
#define kCellPaddingHeight 10
#define kMinimumTextCellHeight 56.0f
#define kTextLabelXPadding 8.f

@interface TextCell ()

@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

@implementation TextCell

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
  self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
  if (self) {
    // background view
    self.textView = [[UIView alloc] init];
    self.textView.backgroundColor = [UIColor whiteColor];
    self.textView.layer.cornerRadius = 2.0;
    self.textView.layer.shadowOffset = CGSizeMake(0, 1.0);
    self.textView.layer.shadowRadius = 1.0;
    self.textView.layer.shadowOpacity = 0.6;
    [self.contentView addSubview:self.textView];
    
    // owner image view
    self.ownerImageView = [[UIImageView alloc] initWithFrame:CGRectMake(kTextCellXPadding, 0, 40, 40)];
    self.ownerImageView.contentMode = UIViewContentModeScaleToFill;
    self.ownerImageView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    [[self class] configureViewBorder:self.ownerImageView
                      withBorderWidth:2.0f
                      andShadowOffset:3.0
                      andShadowRadius:3.0
                             andColor:[UIColor whiteColor]];
    [self.contentView addSubview:self.ownerImageView];
    
    // Text label
    self.label = [[TTTAttributedLabel alloc] initWithFrame:CGRectMake(kTextLabelXPadding, 8.f, 200.f, 22.f)];
    self.label.font = [kAppDelegate globalFontWithSize:kTextLabelFontSize];
    self.label.textColor = [UIColor blackColor];
    self.label.backgroundColor = [UIColor clearColor];
    self.label.textAlignment = NSTextAlignmentLeft;
    self.label.numberOfLines = 0;
    self.label.lineBreakMode = NSLineBreakByWordWrapping;
    self.label.linkAttributes = @{ (id)kCTForegroundColorAttributeName: [UIColor colorWithRed:70.f/255.f green:130.f/255.f blue:180.f/255.f alpha:1.f],
                                   NSUnderlineStyleAttributeName: [NSNumber numberWithInt:NSUnderlineStyleNone] };
    self.label.enabledTextCheckingTypes = NSTextCheckingTypePhoneNumber | NSTextCheckingTypeLink | NSTextCheckingTypeAddress;
    [self.textView addSubview:self.label];
    
    // Date label
    self.dateLabel = [[UILabel alloc] init];
    self.dateLabel.font = [kAppDelegate globalFontWithSize:14.0];
    self.dateLabel.textColor = [UIColor darkGrayColor];
    self.dateLabel.backgroundColor = [UIColor clearColor];
    self.dateLabel.textAlignment = NSTextAlignmentCenter;
    self.dateLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    [self.contentView addSubview:self.dateLabel];
    
    // Resend button
    self.resendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.resendButton.frame = CGRectMake(0, 0, 30, 18);
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
    self.deleteButton.frame = CGRectMake(0, 0, 20, 20);
    [self.deleteButton setBackgroundImage:[[UIImage imageNamed:@"Badge"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                                 forState:UIControlStateNormal];
    self.deleteButton.tintColor = [SHPalette darkRedColor];
    [self.contentView addSubview:self.deleteButton];
    
    // picture image view
    self.picture = [[PFImageView alloc] initWithFrame:CGRectMake(60, 53, 240, 80)];
    self.picture.contentMode = UIViewContentModeScaleAspectFit;
    self.picture.userInteractionEnabled = YES;
    [self.contentView addSubview:self.picture];
    
    // date formatter
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setDateFormat:@"EEE, MMM d h:mma"];
    
  }
  return self;
}

- (void)setText:(PFObject *)text {
  _text = text;
  
  NSString *textMessage = _text[kMessageKey];
  
  if ( [textMessage length] > 0 ) {
    self.label.hidden = NO;
    self.textView.hidden = NO;
    self.label.backgroundColor = [UIColor clearColor];
    
    if ( [[User currentUser].myUserIDs containsObject:_text[kSenderKey]] ) {
      self.textView.backgroundColor = kMyBackgroundColor;
      self.label.textColor = [UIColor whiteColor];
    } else {
      self.textView.backgroundColor = kPartnerBackgroundColor;
      self.label.textColor = [UIColor blackColor];
    }
  } else {
    self.label.hidden = YES;
    self.textView.hidden = YES;
  }
  
  [self.label setText:textMessage];

  // Owner Image View
  if ( [[User currentUser].myUserIDs containsObject:_text[kSenderKey]] ) {
    self.ownerImageView.image = [User currentUser].mySmallPicture;
  } else {
    self.ownerImageView.image = [User currentUser].partnerSmallPicture;
  }
  
  // Text Photo
  if ( _text[kTextPhotoKey] ) {
    self.picture.hidden = NO;
    
    PFFile *pictureFile = _text[kTextPhotoKey];
    if ( pictureFile.isDirty && ! pictureFile.url ) {
      NSData *data = [NSData dataWithContentsOfFile:pathInDocumentDirectory(_text[kTextLocalFilePathKey])];
      self.picture.image = [UIImage imageWithData:data];
    } else {
      self.picture.image = [UIImage imageNamed:@"GrayBackground"];
    }
    
    self.picture.file = pictureFile;
    [self.picture loadInBackground];
  } else {
    self.picture.hidden = YES;
  }
  
  // Date label
  if ( [_text[kSendStatusKey] isEqualToString:kSendError] ) {
    self.dateLabel.text = @"Failed to Send";
    self.dateLabel.textColor = [UIColor redColor];
    self.resendButton.hidden = NO;
  } else if ( !_text.objectId ) {
    self.dateLabel.text = @"Sending...";
    self.dateLabel.textColor = [UIColor darkTextColor];
    self.resendButton.hidden = YES;
  } else  {
    self.dateLabel.text = [self.dateFormatter stringFromDate:_text[kMyCreatedAtKey]];
    self.dateLabel.textColor = [UIColor darkTextColor];
    self.resendButton.hidden = YES;
  }
  
  [self setNeedsLayout];
}

- (void)layoutSubviews {
  [super layoutSubviews];
  
  BOOL isMyText = [[User currentUser].myUserIDs containsObject:self.text[kSenderKey]];
  
  self.textView.frame = CGRectMake(isMyText ? 54.f : kTextCellXPadding,
                                   0.f,
                                   self.frame.size.width - 54.f - kTextCellXPadding,
                                   30.f);
  [self.textView setFrameSizeHeight:[[self class] textCellBackgroundHeightForText:self.text cellWidth:self.frameSizeWidth]];
  
  float YOffset = self.label.frame.origin.y;
  
  NSString *textMessage = self.text[kMessageKey];
  
  if ( [textMessage length] > 0 ) {
    CGFloat labelWidth = self.textView.frameSizeWidth - 2 * self.label.frameOriginX;
    CGSize constraintSize = CGSizeMake(labelWidth, CGFLOAT_MAX);
    CGFloat textLabelHeight = [TTTAttributedLabel sizeThatFitsAttributedString:self.label.attributedText withConstraints:constraintSize limitedToNumberOfLines:0].height;
    self.label.frame = CGRectMake(self.label.frameOriginX, self.label.frameOriginY, labelWidth, textLabelHeight);
    
    YOffset = self.label.frame.origin.y + self.label.frame.size.height + kTextPaddingHeight;
    
  }
  
  // Owner Image View
  self.ownerImageView.center = CGPointMake(isMyText ? kPortraitViewCenterX : self.contentView.frameSizeWidth - kPortraitViewCenterX,
                                           self.ownerImageView.center.y);
  
  // Text Photo
  if ( self.text[kTextPhotoKey] ) {
    float originY;
    
    if (YOffset == self.label.frame.origin.y) {
      originY = YOffset;
    } else {
      originY = YOffset + kTextPaddingHeight;
    }
    CGSize photoSize = [[self class] photoSizeForText:self.text];
    self.picture.frame = CGRectMake(0,
                                    originY,
                                    photoSize.width,
                                    photoSize.height);
    self.picture.frame = [[self class] scaledRect:self.picture.frame maxWidth:kTextPhotoWidth];
    
    // center photo
    self.picture.frame = CGRectMake((self.frame.size.width - self.picture.frame.size.width) / 2.f,
                                    self.picture.frame.origin.y,
                                    self.picture.frame.size.width,
                                    self.picture.frame.size.height);
    YOffset = self.picture.frame.origin.y + self.picture.frame.size.height + 4.0;
    
  }
  
  if ( ! self.textView.hidden && ! self.text[kTextPhotoKey]) {
    YOffset += 4.0;
  }
  
  // Date Label
  [self.dateLabel sizeToFit];
  self.dateLabel.center = CGPointMake(roundf(self.contentView.frameSizeWidth / 2.f), YOffset + 8.f);
  
  self.resendButton.center = CGPointMake(roundf(self.dateLabel.center.x + self.dateLabel.frameSizeWidth / 2.f + self.resendButton.frameSizeWidth / 2.f + 10.f), self.dateLabel.center.y);
  self.deleteButton.center = CGPointMake(roundf(self.dateLabel.center.x - self.dateLabel.frameSizeWidth / 2.f - self.deleteButton.frameSizeWidth / 2.f - 10.f), self.dateLabel.center.y);
  
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

+(CGRect)scaledRect:(CGRect)inRect maxWidth:(CGFloat)theMaxWidth {
  float scaleFactor = theMaxWidth/inRect.size.width;
  
  CGRect newRect = CGRectMake(inRect.origin.x, inRect.origin.y, theMaxWidth, inRect.size.height*scaleFactor);
  
  return CGRectIntegral(newRect);
  
}

+(CGFloat)textCellBackgroundHeightForText:(PFObject *)text cellWidth:(CGFloat)cellWidth {
  float YOffset = kCellContentY;
  static TTTAttributedLabel *attrLabel;
  static dispatch_once_t onceToken;
  CGFloat labelWidth = cellWidth - 54.f - kTextCellXPadding - kTextLabelXPadding * 2.f;
  
  dispatch_once(&onceToken, ^{
    attrLabel = [[TTTAttributedLabel alloc] initWithFrame:CGRectMake(kTextLabelXPadding, 8.f, labelWidth, 22.f)];
    attrLabel.font = [kAppDelegate globalFontWithSize:kTextLabelFontSize];
    attrLabel.textAlignment = NSTextAlignmentLeft;
    attrLabel.numberOfLines = 0;
    attrLabel.lineBreakMode = NSLineBreakByWordWrapping;
    attrLabel.linkAttributes = @{ (id)kCTForegroundColorAttributeName: [UIColor colorWithRed:70.f/255.f green:130.f/255.f blue:180.f/255.f alpha:1.f],
                                   NSUnderlineStyleAttributeName: [NSNumber numberWithInt:NSUnderlineStyleNone] };
    attrLabel.enabledTextCheckingTypes = NSTextCheckingTypePhoneNumber | NSTextCheckingTypeLink | NSTextCheckingTypeAddress;
  });
  
  if ( [text[kMessageKey] length] > 0 ) {
    NSString *textMessage = text[kMessageKey];
    [attrLabel setText:textMessage];
    
    CGSize constraintSize = CGSizeMake(labelWidth, CGFLOAT_MAX);
    CGFloat textLabelHeight = [TTTAttributedLabel sizeThatFitsAttributedString:attrLabel.attributedText withConstraints:constraintSize limitedToNumberOfLines:0].height;
    
    YOffset += textLabelHeight + kTextPaddingHeight;
  }
  
  return YOffset;
  
}

+(CGFloat)textCellHeightForText:(PFObject *)text cellWidth:(CGFloat)cellWidth {
  CGFloat cellHeight = [self textCellBackgroundHeightForText:text cellWidth:cellWidth];
  if (text[kTextPhotoKey]) {
    
    CGSize photoSize = [[self class] photoSizeForText:text];
    CGRect textPhotoFrame = CGRectMake(0, 0, photoSize.width, photoSize.height);
    textPhotoFrame = [self scaledRect:textPhotoFrame maxWidth:kTextPhotoWidth];
    
    if (cellHeight == kCellContentY) {
      cellHeight += textPhotoFrame.size.height + kTextPaddingHeight;
    } else {
      cellHeight += textPhotoFrame.size.height + kTextPaddingHeight * 2.f;
    }
  }
  
  return MAX(cellHeight + kDateLabelOffset + kDateLabelHeight + kCellPaddingHeight, kMinimumTextCellHeight);
  
}

+(CGSize)photoSizeForText:(PFObject *)text {
  CGFloat pictureHeight = text[kTextPhotoHeightKey] ? [text[kTextPhotoHeightKey] floatValue] : kTextPhotoDefaultHeight;
  CGFloat pictureWidth = text[kTextPhotoWidthKey] ? [text[kTextPhotoWidthKey] floatValue] : kTextPhotoWidth;
  return CGSizeMake(pictureWidth, pictureHeight);
}

@end
