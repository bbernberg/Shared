//
//  CalendarReminderEditController.h
//  Shared
//
//  Created by Brian Bernberg on 2/8/13.
//  Copyright (c) 2013 BB Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GTLCalendar.h"

@interface CalendarReminderEditController : UITableViewController
-(id)initWithEvent:(GTLCalendarEvent *)event;

@end
