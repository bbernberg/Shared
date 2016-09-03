//
//  UIButton+myButton.m
//  Shared
//
//  Created by Brian Bernberg on 3/28/12.
//  Copyright (c) 2012 BB Consulting. All rights reserved.
//

#import "UIButton+myButton.h"

@implementation UIButton (myButton)
-(void)customizeButton {
    self.layer.cornerRadius = 8.0f;
    self.layer.masksToBounds = YES;
    self.layer.borderWidth = 1.0f;
}

-(void)customizeSimpleButton {
    self.layer.cornerRadius = 4.0f;
    self.layer.masksToBounds = YES;    
}

-(void)circularButton {
    self.layer.masksToBounds = YES;
    self.layer.borderWidth = 1.0f;
    
    CGFloat newDiameter = self.frame.size.width < self.frame.size.height ? self.frame.size.width : self.frame.size.height;
    CGPoint saveCenter = self.center;
    CGRect newFrame = CGRectMake(self.frame.origin.x, self.frame.origin.y, newDiameter, newDiameter);
    self.frame = newFrame;
    self.layer.cornerRadius = newDiameter / 2.0;
    self.center = saveCenter;    
    
}

-(void)setBorderColor:(UIColor *)theBorderColor {
    self.layer.borderColor = [theBorderColor CGColor];
}
@end
