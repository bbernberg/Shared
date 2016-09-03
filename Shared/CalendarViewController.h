//
//  CalendarViewController.h
//  Shared
//
//  Created by Brian Bernberg on 8/26/15.
//  Copyright (c) 2015 BB Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SHViewController.h"

@interface CalendarViewController : SHViewController

@property (nonatomic) NSDate *dateSelected;

- (void)refreshData;

@end
