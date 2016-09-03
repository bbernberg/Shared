//
//  ListTableViewCell.h
//  Shared
//
//  Created by Brian Bernberg on 8/6/13.
//  Copyright (c) 2013 BB Consulting. All rights reserved.
//

#import "HHPanningTableViewCell.h"
#import "Parse/Parse.h"

#define kTextViewLeftMargin 10.f
#define kTextViewRightMargin 62.f
#define kTextViewFontSize 19.f
#define kMembersViewWidth 70.f
#define kMemberPictureEdge 30.f

@interface ListTableViewCell : HHPanningTableViewCell
@property (nonatomic, strong) UIButton *markButton;
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, strong) UIButton *partnerButton;
@property (nonatomic, strong) UILabel *partnerLabel;
@property (nonatomic, strong) UIButton *myButton;
@property (nonatomic, strong) UILabel *myLabel;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) PFObject *listItem;
@property (nonatomic, strong) UIView *separator;
@property (nonatomic, strong) UIView *membersView;

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier;
- (void)updateMembers:(NSArray *)members ;
@end
