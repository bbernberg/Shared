//
//  CalendarRecurringEndControllerController.h
//  Shared
//
//  Created by Brian Bernberg on 2/15/13.
//  Copyright (c) 2013 BB Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol RecurringEndDelegate;

@interface RecurringEndController : UITableViewController
- (id)initWithEndDate:(NSDate *)endDate
          minimumDate:(NSDate *)minimumDate
             delegate:(id<RecurringEndDelegate>)delegate;
@end

@protocol RecurringEndDelegate <NSObject>
-(void)useEndDate:(NSDate *)date;
@end
