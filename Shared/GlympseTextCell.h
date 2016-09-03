//
//  GlympseTextCell.h
//  Shared
//
//  Created by Brian Bernberg on 7/19/15.
//  Copyright (c) 2015 BB Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GlympseTextCell : UITableViewCell

@property (nonatomic) PFObject *text;
@property (nonatomic) UIView *textView;
@property (nonatomic) UIButton *resendButton;

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier;
+ (CGFloat)textCellHeightForText:(PFObject *)text cellWidth:(CGFloat)cellWidth;

@end
