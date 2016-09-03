//
//  TextVoiceMessageCell.h
//  Shared
//
//  Created by Brian Bernberg on 11/20/13.
//  Copyright (c) 2013 BB Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DDProgressView;

@interface TextVoiceMessageCell : UITableViewCell

@property (nonatomic, strong) PFObject *text;

@property (nonatomic, strong) UIView *background;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UILabel *durationLabel;
@property (nonatomic, strong) UIButton *playbackButton;
@property (nonatomic, strong) UIImageView *playbackButtonIV;
@property (nonatomic, strong) DDProgressView *progressView;
@property (nonatomic, strong) UIButton *resendButton;
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic) UIActivityIndicatorView *spinner;

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier;

@end
