//
//  ImageActivityIndicator.m
//  Shared
//
//  Created by Brian Bernberg on 10/3/13.
//  Copyright (c) 2013 BB Consulting. All rights reserved.
//

#import "SharedActivityIndicator.h"
#import <QuartzCore/QuartzCore.h>

@implementation SharedActivityIndicator


- (id)init {
    return [self initWithImage:[UIImage imageNamed: @"Shared_Icon_Transparent"]];
}

- (id)initWithImage: (UIImage*)image
{
    self = [super initWithImage: image];
    if (self) {
        // Initialization code
        self.frame = CGRectMake(0.f, 0.f, 24.f, 24.f);
        self.backgroundColor = [UIColor clearColor];
        self.duration = 1.0f;
        self.hidden = YES;
    }
    return self;
}

-(void)awakeFromNib {
    [super awakeFromNib];
    self.backgroundColor = [UIColor clearColor];
    self.duration = 1.0f;
    self.hidden = YES;
}

-(void)startAnimating {
    self.hidden = NO;
    CABasicAnimation *rotation;
    rotation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    rotation.fromValue = @0.f;
    rotation.toValue = @(2 * M_PI);
    rotation.duration = self.duration;
    rotation.repeatCount = HUGE_VALF;
    [self.layer addAnimation:rotation forKey:@"Spin"];
}

-(void)stopAnimating {
    [self.layer removeAnimationForKey:@"Spin"];
    self.hidden = YES;
}

@end
