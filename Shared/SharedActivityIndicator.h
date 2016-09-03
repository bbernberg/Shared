//
//  ImageActivityIndicator.h
//  Shared
//
//  Created by Brian Bernberg on 10/3/13.
//  Copyright (c) 2013 BB Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SharedActivityIndicator : UIImageView

@property (nonatomic, assign) CGFloat duration;

- (void)startAnimating;
- (void)stopAnimating;

@end
