//
//  CalendarService.h
//  Shared
//
//  Created by Brian Bernberg on 1/24/13.
//  Copyright (c) 2013 BB Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>
#import "GTLCalendar.h"

@interface CalendarService : NSObject
@property (strong, nonatomic) PFObject *info;
@property (strong, nonatomic) NSDictionary *dayDictionary;
@property (nonatomic, assign) BOOL validEvents;
@property (nonatomic, readonly) GTLServiceCalendar *gtlCalendarService;
@property (nonatomic, strong) NSDictionary *recurringEvents;
@property (nonatomic, readonly) BOOL calendarIsShared;
@property (nonatomic, readonly) BOOL isCalendarOwner;

+(CalendarService *)sharedInstance;
-(BOOL)isAvailable;

// API actions
- (void)createCalendarWithName:(NSString *)name completionBlock:(void (^)(BOOL success, BOOL choosePartner, NSError * error))completionBlock;
- (void)retrieveCalendarEvents;
- (void)retrieveCalendarEventsfrom:(NSDate *)start
                               to:(NSDate *)end;
-(void)patchOriginalEvent:(GTLCalendarEvent *)originalEvent
         withRevisedEvent:(GTLCalendarEvent *)revisedEvent
          completionBlock:(void (^)(BOOL success, NSError *error))completionBlock;
- (void)addEvent:(GTLCalendarEvent *)newEvent completionBlock:(void (^)(BOOL success, NSError *error))completionBlock;
- (void)deleteEvent:(GTLCalendarEvent *)event;
- (void)invitePartnerToEvent:(GTLCalendarEvent *)event;
- (void)addPermissionForEmail:(NSString *)email;
- (void)restoreEvent:(GTLCalendarEvent *)event fromEvent:(GTLCalendarEvent *)originalEvent;
- (void)fetchCalendarInfo;
- (void)verifyCalendarWithCompletionBlock:(void (^)(BOOL success, NSError *error))completionBlock failureCount:(NSUInteger)failureCount;

+ (NSString *)keyForDate:(NSDate *)date;
+(void)resetCalendarForCalendarInfo:(PFObject *)calendarInfo;
+ (NSString *)calendarDataPath;
+ (BOOL)isSameDayWithDate1:(NSDate *)date1 date2:(NSDate *)date2;
@end
