//
//  PlacesController.h
//  Shared
//
//  Created by Brian Bernberg on 10/28/15.
//  Copyright © 2015 BB Consulting. All rights reserved.
//

#import "SHViewController.h"

@protocol PlacesControllerDelegate <NSObject>

- (void)exitingWithPlaceID:(NSString *)placeID location:(NSString *)location;

@end

@interface PlacesController : SHViewController

- (instancetype)initWithLocation:(NSString *)location delegate:(id<PlacesControllerDelegate>)delegate;

- (id) init __attribute__((unavailable("init not available")));
- (id)initWithCoder:(NSCoder *)aDecoder __attribute__((unavailable("init not available")));
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil __attribute__((unavailable("init not available")));

@end
