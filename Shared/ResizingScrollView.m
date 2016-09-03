//
//  ResizingScrollView.m
//  Shared
//
//  Created by Brian Bernberg on 12/21/12.
//  Copyright (c) 2012 BB Consulting. All rights reserved.
//

#import "ResizingScrollView.h"

@implementation ResizingScrollView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}


-(void)layoutSubviews {
    [super layoutSubviews];
    
    for (UIView *sub in self.subviews) {
        [sub setNeedsLayout];
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
