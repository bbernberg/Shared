/* 
 * Copyright (c) 2009 Keith Lazuka
 * License: http://www.opensource.org/licenses/mit-license.html
 */

#import <Foundation/Foundation.h>

@interface KalDate : NSObject
{
  struct {
    NSInteger month : 4;
    NSInteger day : 5;
    NSInteger year : 15;
  } a;
}

+ (KalDate *)dateForDay:(NSInteger)day month:(NSInteger)month year:(NSInteger)year;
+ (KalDate *)dateFromNSDate:(NSDate *)date;

- (id)initForDay:(NSInteger)day month:(NSInteger)month year:(NSInteger)year;
- (NSInteger)day;
- (NSInteger)month;
- (NSInteger)year;
- (NSDate *)NSDate;
- (NSComparisonResult)compare:(KalDate *)otherDate;
- (BOOL)isToday;

@end
