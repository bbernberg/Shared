//
//  ListTableViewCell.m
//  Shared
//
//  Created by Brian Bernberg on 8/6/13.
//  Copyright (c) 2013 BB Consulting. All rights reserved.
//

#import "ListTableViewCell.h"
#import "UIView+Helpers.h"

@interface ListTableViewCell ()
@property (nonatomic, strong) UILabel *partnerMemberLabel;
@property (nonatomic, strong) UILabel *myMemberLabel;
@end
@implementation ListTableViewCell

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier {
  if (self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier]) {
    // Initialization code
    self.showsReorderControl = NO;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    UIView *drawerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
    drawerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    drawerView.backgroundColor = [UIColor whiteColor];
    self.drawerView = drawerView;
    
    self.markButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.markButton setTitle:@"Mark" forState:UIControlStateNormal];
    self.markButton.frame = CGRectMake(self.frame.size.width - 70.f, 0.f, 70.f, drawerView.frame.size.height);
    self.markButton.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin;
    self.markButton.backgroundColor = [UIColor darkGrayColor];
    [self.markButton setBackgroundImage:[UIImage imageNamed:@"GrayBackground"] forState:UIControlStateHighlighted];
    [drawerView addSubview: self.markButton];
    
    self.deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.deleteButton setTitle:@"Delete" forState:UIControlStateNormal];
    self.deleteButton.frame = CGRectMake(self.frame.size.width - 140.f, 0.f, 70.f, drawerView.frame.size.height);
    self.deleteButton.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin;
    self.deleteButton.backgroundColor = [SHPalette darkRedColor];
    [self.deleteButton setBackgroundImage:[UIImage imageNamed:@"GrayBackground"] forState:UIControlStateHighlighted];
    [drawerView addSubview: self.deleteButton];
    
    self.partnerButton=[UIButton buttonWithType:UIButtonTypeCustom];
    self.partnerButton.frame = CGRectMake(0.f, 0.f, 70.f, drawerView.frame.size.height);
    self.partnerButton.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    self.partnerButton.backgroundColor = [SHPalette navyBlue];
    [self.partnerButton setBackgroundImage:[UIImage imageNamed:@"GrayBackground"] forState:UIControlStateHighlighted];
    [drawerView addSubview: self.partnerButton];

    self.partnerLabel = [[UILabel alloc] init];
    self.partnerLabel.textAlignment = NSTextAlignmentCenter;
    if ([[User currentUser].partnerName length] > 0) {
      self.partnerLabel.text = [[[User currentUser].partnerName substringToIndex:1] uppercaseString];
    } else {
      self.partnerLabel.text = [[[User currentUser].partnerUserEmail substringToIndex:1] uppercaseString];
    }
    self.partnerLabel.font = [UIFont fontWithName:@"Copperplate" size:18.f];
    self.partnerLabel.textColor = [SHPalette navyBlue];
    self.partnerLabel.backgroundColor = [UIColor whiteColor];
    self.partnerLabel.frame = CGRectMake(20, (drawerView.frame.size.height - 30.f) / 2.f, 30.f, 30.f);
    [self makeViewCircular:self.partnerLabel];
    self.partnerLabel.userInteractionEnabled = NO;
    [self.partnerButton addSubview:self.partnerLabel];
    
    self.myButton=[UIButton buttonWithType:UIButtonTypeCustom];
    self.myButton.frame = CGRectMake(70.f, 0.f, 70.f, drawerView.frame.size.height);
    self.myButton.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    self.myButton.backgroundColor = [UIColor lightGrayColor];
    [self.myButton setBackgroundImage:[UIImage imageNamed:@"GrayBackground"] forState:UIControlStateHighlighted];
    [drawerView addSubview: self.myButton];
    
    self.myLabel = [[UILabel alloc] init];
    self.myLabel.textAlignment = NSTextAlignmentCenter;
    self.myLabel.text = @"YOU";
    self.myLabel.font = [UIFont fontWithName:@"Copperplate" size:12.f];
    self.myLabel.textColor = [UIColor lightGrayColor];
    self.myLabel.backgroundColor = [UIColor whiteColor];
    self.myLabel.frame = CGRectMake(20, (drawerView.frame.size.height - 30.f) / 2.f, 30.f, 30.f);
    [self makeViewCircular:self.myLabel];
    self.myLabel.userInteractionEnabled = NO;
    [self.myButton addSubview:self.myLabel];
    
    self.textView = [[UITextView alloc] initWithFrame:CGRectMake(kTextViewLeftMargin,
                                                                 5,
                                                                 self.frameSizeWidth - kTextViewLeftMargin - kTextViewRightMargin,
                                                                 self.contentView.frame.size.height)];
    self.textView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.textView.scrollEnabled = YES;
    self.textView.font = [kAppDelegate globalFontWithSize:kTextViewFontSize];
    self.textView.backgroundColor = [UIColor clearColor];
    self.textView.scrollEnabled = FALSE;
    self.textView.returnKeyType = UIReturnKeyDone;
    self.textView.editable = NO;
    self.textView.userInteractionEnabled = NO;
    [self.contentView addSubview:self.textView];
    
    self.separator = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, self.contentView.frame.size.width, 1.f)];
    self.separator.backgroundColor = [UIColor colorWithRed:(224.0/255.0) green:(224.0/255.0) blue:(224.0/255.0) alpha:1.0];
    self.separator.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
    [self.contentView addSubview:self.separator];
    
    self.membersView = [[UIView alloc] initWithFrame:CGRectMake(self.contentView.frame.size.width - kMembersViewWidth, 0, kMembersViewWidth, kMembersViewWidth)];
    self.membersView.backgroundColor = [UIColor clearColor];
    self.membersView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [self.contentView addSubview:self.membersView];
    
    self.partnerMemberLabel = [[UILabel alloc] init];
    self.partnerMemberLabel.textAlignment = NSTextAlignmentCenter;
    self.partnerMemberLabel.textColor = [UIColor whiteColor];
    self.partnerMemberLabel.backgroundColor = [SHPalette navyBlue];
    if ([[User currentUser].partnerName length] > 0) {
      self.partnerMemberLabel.text = [[[User currentUser].partnerName substringToIndex:1] uppercaseString];
    } else {
      self.partnerMemberLabel.text = [[[User currentUser].partnerUserEmail substringToIndex:1] uppercaseString];
    }
    self.partnerMemberLabel.font = [UIFont fontWithName:@"Copperplate" size:18.f];
    self.partnerMemberLabel.frame = CGRectMake(0, 0, kMemberPictureEdge, kMemberPictureEdge);
    [self makeViewCircular:self.partnerMemberLabel];

    self.myMemberLabel = [[UILabel alloc] init];
    self.myMemberLabel.textAlignment = NSTextAlignmentCenter;
    self.myMemberLabel.textColor = [UIColor whiteColor];
    self.myMemberLabel.backgroundColor = [UIColor lightGrayColor];
    self.myMemberLabel.text = @"YOU";
    self.myMemberLabel.font = [UIFont fontWithName:@"Copperplate" size:12.f];
    self.myMemberLabel.frame = CGRectMake(0, 0, kMemberPictureEdge, kMemberPictureEdge);
    [self makeViewCircular:self.myMemberLabel];
    
    self.separatorInset = UIEdgeInsetsZero;
  }
  return self;
}

-(void)layoutSubviews {
  [super layoutSubviews];
  
  CGRect frame = self.partnerLabel.frame;
  frame.origin.y = (self.frame.size.height - self.partnerLabel.frame.size.height) / 2.f;
  self.partnerLabel.frame = frame;
  
  frame = self.myLabel.frame;
  frame.origin.y = (self.frame.size.height - self.myLabel.frame.size.height) / 2.f;
  self.myLabel.frame = frame;
  
  frame = self.membersView.frame;
  frame.origin.y = (self.frame.size.height - self.membersView.frame.size.height) / 2.f;
  self.membersView.frame = frame;
  
  frame = self.textView.frame;
  frame.origin.y = (self.frame.size.height - self.textView.frame.size.height) / 2.f;
  self.textView.frame = frame;
}

#pragma mark Members
- (void)updateMembers:(NSArray *)members {
  for (UIView *view in self.membersView.subviews) {
    [view removeFromSuperview];
  }
  if (!members || members.count == 0) {
    return;
  }
  BOOL showPartner = [members containsObject:[User currentUser].partnerUserID];
  BOOL showMe = ([User currentUser].myUserEmail && [members containsObject:[User currentUser].myUserEmail]) ||
  ([User currentUser].myFBID && [members containsObject:[User currentUser].myFBID]);
  
  if (showPartner && showMe) {
    [self.membersView addSubview:self.partnerMemberLabel];
    [self.membersView addSubview:self.myMemberLabel];
    
    CGFloat xPadding = (self.membersView.frame.size.width - self.partnerMemberLabel.frame.size.width - self.myMemberLabel.frame.size.width) / 3.f;
    
    self.partnerMemberLabel.frame = CGRectMake(xPadding,
                                              (self.membersView.frame.size.height - self.partnerMemberLabel.frame.size.height) / 2.f,
                                              self.partnerMemberLabel.frame.size.width,
                                              self.partnerMemberLabel.frame.size.height);
    self.myMemberLabel.frame = CGRectMake(xPadding * 2.f + self.partnerMemberLabel.frame.size.width,
                                         (self.membersView.frame.size.height - self.partnerMemberLabel.frame.size.height) / 2.f,
                                         self.myMemberLabel.frame.size.width,
                                         self.myMemberLabel.frame.size.height);
  } else if (showPartner) {
    [self.membersView addSubview:self.partnerMemberLabel];
    self.partnerMemberLabel.frame = CGRectMake((self.membersView.frame.size.width - self.partnerMemberLabel.frame.size.width) / 2.f,
                                              (self.membersView.frame.size.height - self.partnerMemberLabel.frame.size.height) / 2.f,
                                              self.partnerMemberLabel.frame.size.width,
                                              self.partnerMemberLabel.frame.size.height);
  } else if (showMe) {
    [self.membersView addSubview:self.myMemberLabel];
    self.myMemberLabel.frame = CGRectMake((self.membersView.frame.size.width - self.myMemberLabel.frame.size.width) / 2.f,
                                         (self.membersView.frame.size.height - self.myMemberLabel.frame.size.height) / 2.f,
                                         self.myMemberLabel.frame.size.width,
                                         self.myMemberLabel.frame.size.height);
  }
  
}

#pragma mark utilities
-(void)makeViewCircular:(UIView *)view {
  view.layer.masksToBounds = YES;
  view.layer.borderWidth = 0.0f;
  
  CGFloat diameter = view.frame.size.width;
  view.layer.cornerRadius = roundf( diameter / 2.0);
}

@end
