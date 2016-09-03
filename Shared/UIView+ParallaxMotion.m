//
//  UIView+ParallaxMotion.m
//  Shared
//
//  Created by Brian Bernberg on 7/13/13.
//  Copyright (c) 2013 BB Consulting. All rights reserved.
//

#import "UIView+ParallaxMotion.h"

#import <objc/runtime.h>

static const NSString * kParallaxDepthKey = @"kParallaxDepthKey";
static const NSString * kParallaxMotionEffectGroupKey = @"kParallaxMotionEffectGroupKey";

@implementation UIView (ParallaxMotion)

-(void)setParallaxIntensity:(CGFloat)parallaxDepth
{
    if (self.parallaxIntensity == parallaxDepth)
        return;
    
    objc_setAssociatedObject(self, (__bridge const void *)(kParallaxDepthKey), @(parallaxDepth), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if (parallaxDepth == 0.0)
    {
        [self removeMotionEffect:[self nga_parallaxMotionEffectGroup]];
        [self nga_setParallaxMotionEffectGroup:nil];
        return;
    }
    
    UIMotionEffectGroup * parallaxGroup = [self nga_parallaxMotionEffectGroup];
    if (!parallaxGroup)
    {
        parallaxGroup = [[UIMotionEffectGroup alloc] init];
        [self nga_setParallaxMotionEffectGroup:parallaxGroup];
        [self addMotionEffect:parallaxGroup];
    }
    
    UIInterpolatingMotionEffect *xAxis = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    UIInterpolatingMotionEffect *yAxis = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    
    NSArray * motionEffects = @[xAxis, yAxis];
    
    for (UIInterpolatingMotionEffect * motionEffect in motionEffects )
    {
        motionEffect.maximumRelativeValue = @(parallaxDepth);
        motionEffect.minimumRelativeValue = @(-parallaxDepth);
    }
    parallaxGroup.motionEffects = motionEffects;
}

-(CGFloat)parallaxIntensity
{
    NSNumber * val = objc_getAssociatedObject(self, (__bridge const void *)(kParallaxDepthKey));
    if (!val)
        return 0.0;
    return val.doubleValue;
}

#pragma mark -

-(UIMotionEffectGroup*)nga_parallaxMotionEffectGroup
{
    return objc_getAssociatedObject(self, (__bridge const void *)(kParallaxMotionEffectGroupKey));
}

-(void)nga_setParallaxMotionEffectGroup:(UIMotionEffectGroup*)group
{
    objc_setAssociatedObject(self, (__bridge const void *)(kParallaxMotionEffectGroupKey), group, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    NSAssert( group == objc_getAssociatedObject(self, (__bridge const void *)(kParallaxMotionEffectGroupKey)), @"set did not work" );
}

@end
