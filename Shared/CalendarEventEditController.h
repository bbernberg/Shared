//
//  CalendarEventEditViewController.h
//  Shared
//
//  Created by Brian Bernberg on 2/4/13.
//  Copyright (c) 2013 BB Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GTLCalendar.h"
#import "SHViewController.h"

@interface CalendarEventEditController : SHViewController
-(id)initWithEvent:(GTLCalendarEvent *)event
              date:(NSDate *)date;
@end
