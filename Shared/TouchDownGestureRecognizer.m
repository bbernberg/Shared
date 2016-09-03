//
//  TouchDownGestureRecognizer.m
//  Shared
//
//  Created by Brian Bernberg on 4/16/12.
//  Copyright (c) 2012 BB Consulting. All rights reserved.
//

#import "TouchDownGestureRecognizer.h"
#import <UIKit/UIGestureRecognizerSubclass.h>

@implementation TouchDownGestureRecognizer

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.state = UIGestureRecognizerStateRecognized;
}

@end
