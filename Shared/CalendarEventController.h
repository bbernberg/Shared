//
//  CalendarEventViewController.h
//  Shared
//
//  Created by Brian Bernberg on 1/28/13.
//  Copyright (c) 2013 BB Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GTLCalendar.h"
#import "SHViewController.h"

@interface CalendarEventController : SHViewController
- (id)initWithEvent:(GTLCalendarEvent *)event;

@end
