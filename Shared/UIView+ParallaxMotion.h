//
//  UIView+ParallaxMotion.h
//  Shared
//
//  Created by Brian Bernberg on 7/13/13.
//  Copyright (c) 2013 BB Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (ParallaxMotion)
// Positive values make the view appear to be above the surface
// Negative values are below.
// The unit is in points
@property (nonatomic) CGFloat parallaxIntensity;

@end
