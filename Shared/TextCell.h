//
//  TextCell.h
//  Shared
//
//  Created by Brian Bernberg on 11/20/13.
//  Copyright (c) 2013 BB Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PFImageView.h"

@class TTTAttributedLabel;

@interface TextCell : UITableViewCell
@property (nonatomic, strong) UIView *textView;
@property (nonatomic, strong) UIImageView *ownerImageView;
@property (nonatomic, strong) TTTAttributedLabel *label;
@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) UIButton *resendButton;
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, strong) PFImageView *picture;

@property (nonatomic, strong) PFObject *text;

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier;
+ (CGFloat)textCellHeightForText:(PFObject *)text cellWidth:(CGFloat)cellWidth;

@end
