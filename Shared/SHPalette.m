//
//  SHPalette.m
//  Shared
//
//  Created by Brian Bernberg on 8/5/13.
//  Copyright (c) 2013 BB Consulting. All rights reserved.
//

#import "SHPalette.h"

// 130b4b for Pixelmator blue

@implementation SHPalette

+(UIColor *)navyBlue {
    return [UIColor colorWithRed:0.f green:51.f/255.f blue:90.f/255.f alpha:1.0];
}

+(UIColor *)darkNavyBlue {
    return [UIColor colorWithRed:(33.f/255.f) green:(48.f/255.f) blue:(75.f/255.f) alpha:1.0];
}

+(UIColor *)navBarColor {
    return [UIColor colorWithRed:(219.f/255.f) green:(218.f/255.f) blue:(216.f/255.f) alpha:1.0];
}

+(UIColor *)backgroundColor {
    return [UIColor colorWithRed:(239.0/255.0) green:(238.0/255.0) blue:(236.0/255.0) alpha:1.0];
}

+(UIColor *)darkRedColor {
    return [UIColor colorWithRed:183.0/255.0 green:62.0/255.0 blue:62.0/255.0 alpha:1.0];
}

+(UIColor *)kellyGreen {
  return [UIColor colorWithRed:76.f/255.f green:187.f/255.f blue:23.f/255.f alpha:1.0];
}

@end
