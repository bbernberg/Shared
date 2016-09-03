//
//  CalendarService.m
//  Shared
//
//  Created by Brian Bernberg on 1/24/13.
//  Copyright (c) 2013 BB Consulting. All rights reserved.
//

#import "CalendarService.h"
#import "Constants.h"
#import "GTLCalendar.h"
#import "PSPDFAlertView.h"
#import "GTLCalendarEvent+Coding.h"

// archive keys
#define kCalendarInfoKey @"calendarInfoKey"
#define kDayDictKey @"dayDictKey"

static CalendarService *sharedInstance = nil;

@interface CalendarService()

@property (nonatomic, strong) GTLServiceCalendar *gtlCalendarService;

@end

@implementation CalendarService

+(CalendarService *)sharedInstance {
  if (!sharedInstance) {
    sharedInstance = [[CalendarService alloc] init];
  }
  return sharedInstance;
}

-(id)init {
  if (self = [super init]) {
    NSData *data = [NSData dataWithContentsOfFile:[CalendarService calendarDataPath]];
    if ( data ) {
      NSKeyedUnarchiver *decoder = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
      self.info = [decoder decodeObjectForKey:kCalendarInfoKey];
      self.dayDictionary = [decoder decodeObjectForKey:kDayDictKey];
      // Check for correct data structure in day dictionary
      NSString *firstKey = [[self.dayDictionary allKeys] firstObject];
      BOOL resetDayDicationry = firstKey && ! [self.dayDictionary[firstKey] isKindOfClass:[NSArray class]];
      if ( resetDayDicationry ) {
        self.dayDictionary = @{};
      }
      
      if (self.info && self.dayDictionary && ! resetDayDicationry ) {
        self.validEvents = YES;
      } else {
        self.validEvents = NO;
      }
    } else {
      self.info = nil;
      self.dayDictionary = @{};
      self.validEvents = NO;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(saveCalendar)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
  }
  return self;
}

-(void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(BOOL)isAvailable {
  if (!self.info) {
    return NO;
  } else {
    return YES;
  }
}

- (GTLServiceCalendar *)gtlCalendarService {
  if ( !_gtlCalendarService ) {
    _gtlCalendarService = [[GTLServiceCalendar alloc] init];
    
    // Have the service object set tickets to fetch consecutive pages
    // of the feed so we do not need to manually fetch them.
    _gtlCalendarService.shouldFetchNextPages = YES;
    
    // Have the service object set tickets to retry temporary error conditions
    // automatically.
    _gtlCalendarService.retryEnabled = YES;
  }
  return _gtlCalendarService;
}

-(BOOL)calendarIsShared {
  NSString *partnerUserEmail = self.info[kGoogleCalendarPartnerUserEmailKey];
  
  if ( [self.info[kGoogleCalendarSharedKey] boolValue] == NO ) {
    return NO;
  } else if ( [self isCalendarOwner] &&
             ! [partnerUserEmail isEqualToInsensitive:[User currentUser].partnerGoogleCalendarUserEmail] ) {
    return NO;
  } else {
    return YES;
  }
}

-(BOOL)isCalendarOwner {
  [User currentUser].googleCalendarOwner = self.info[kGoogleCalendarOwnerIDKey];
  return [[User currentUser].myUserIDs containsObject:self.info[kGoogleCalendarOwnerIDKey]];
}

-(NSDictionary *)dayDictionaryFromEvents:(NSArray *)events {
  NSMutableDictionary *dayDictionary = [NSMutableDictionary dictionary];
  
  for (GTLCalendarEvent *event in events) {
    [self addEvent:event toDict:dayDictionary];
  }
  
  return [NSDictionary dictionaryWithDictionary:dayDictionary];
  
}

-(void)addEvent:(GTLCalendarEvent *)event toDict:(NSMutableDictionary *)dict {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  
  static NSDateComponents *dayComponent = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    dayComponent = [[NSDateComponents alloc] init];
    dayComponent.day = 1;
  });
  
  if ( event.start.dateTime ) {
    NSDate *eventStartDate = event.start.dateTime.date;
    NSDate *eventEndDate = event.end.dateTime.date;
    
    // add start date
    [self addEvent:event toDict:dict forDate:eventStartDate];
    // add end date
    [self addEvent:event toDict:dict forDate:eventEndDate];
    
    // increment dates in between
    NSDate *curDate = [calendar dateByAddingComponents:dayComponent toDate:eventStartDate options:0];
    
    while ([curDate compare:eventEndDate] == NSOrderedAscending) {
      [self addEvent:event toDict:dict forDate:curDate];
      curDate = [calendar dateByAddingComponents:dayComponent toDate:curDate options:0];
    }
  } else {
    // all day event
    NSInteger comps = (NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear);
    NSDateComponents *eventStartComps = [calendar components:comps fromDate:event.start.date.date];
    NSDateComponents *eventEndComps = [calendar components:comps fromDate:event.end.date.date];
    NSDate *eventStartDate = [calendar dateFromComponents:eventStartComps];
    NSDate *eventEndDate = [calendar dateFromComponents:eventEndComps];
    
    // add start date
    [self addEvent:event toDict:dict forDate:eventStartDate];
    
    NSDate *curDate = [calendar dateByAddingComponents:dayComponent toDate:eventStartDate options:0];
    while ([curDate compare:eventEndDate] == NSOrderedAscending) {
      [self addEvent:event toDict:dict forDate:curDate];
      curDate = [calendar dateByAddingComponents:dayComponent toDate:curDate options:0];
    }
  }
}

-(void)addEvent:(GTLCalendarEvent *)event toDict:(NSMutableDictionary *)dict forDate:(NSDate *)date {
  NSString *dateKey = [CalendarService keyForDate:date];
  NSArray *dayEvents = dict[dateKey];
  NSMutableArray *newDayEvents = dayEvents ? [NSMutableArray arrayWithArray:dayEvents] : [NSMutableArray array];
  if ( [newDayEvents indexOfObject:event] != NSNotFound ) {
    return;
  }
  
  [newDayEvents addObject:event];
  [newDayEvents sortUsingComparator:^NSComparisonResult(GTLCalendarEvent *event1, GTLCalendarEvent *event2) {
    if (event1.start.date) {
      return NSOrderedAscending;
    } else if (event2.start.date) {
      return NSOrderedDescending;
    } else {
      return [event1.start.dateTime.date compare:event2.start.dateTime.date];
    }
  }];
  
  dict[dateKey] = [NSArray arrayWithArray:newDayEvents];
}

+(NSString *)keyForDate:(NSDate *)date {
  static NSDateFormatter *keyFormatter = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    keyFormatter = [[NSDateFormatter alloc] init];
    [keyFormatter setDateFormat:@"MM_d_y"];
  });
  
  return [keyFormatter stringFromDate:date];
}

#pragma mark API calls
- (void)createCalendarWithName:(NSString *)name
               completionBlock:(void (^)(BOOL success, BOOL choosePartner, NSError *error))completionBlock {
  GTLCalendarCalendar *newCalendar = [GTLCalendarCalendar object];
  
  newCalendar.summary = name;
  newCalendar.timeZone = [[NSTimeZone localTimeZone] name];
  
  GTLQueryCalendar *query = [GTLQueryCalendar queryForCalendarsInsertWithObject: newCalendar];
  [self.gtlCalendarService executeQuery: query
                      completionHandler:^(GTLServiceTicket *ticket, GTLCalendarCalendar *createdCalendar, NSError *error) {
                        if (!error) {
                          self.info = [PFObject versionedObjectWithClassName:kGoogleCalendarClass];
                          self.info[kGoogleCalendarIDKey] = createdCalendar.identifier;
                          self.info[kUsersKey] = [User currentUser].userIDs;
                          self.info[kGoogleCalendarOwnerIDKey] = [User currentUser].myUserID;
                          self.info[kGoogleCalendarOwnerUserEmailKey] = [User currentUser].myGoogleCalendarUserEmail;
                          [User currentUser].googleCalendarOwner = [User currentUser].myUserID;
                          self.info[kGoogleCalendarSharedKey] = @(NO);
                          if ([User currentUser].partnerGoogleCalendarUserEmail.length > 0) {
                            
                            self.info[kGoogleCalendarPartnerIDKey] = [User currentUser].partnerUserID;
                            self.info[kGoogleCalendarPartnerUserEmailKey] = [User currentUser].partnerGoogleCalendarUserEmail;
                            
                            [self addPermissionForEmail:[User currentUser].partnerGoogleCalendarUserEmail];
                            completionBlock(YES, NO, nil);
                          } else {
                            completionBlock(YES, YES, nil);
                          }
                          
                        } else {
                          NSLog(@"An error occurred: %@", error);
                          completionBlock(NO, NO, error);
                        }
                      }];
}

-(void)retrieveCalendarEvents {
  if (self.info[kGoogleCalendarIDKey]) {
    GTLQueryCalendar *eventsQuery = [GTLQueryCalendar queryForEventsListWithCalendarId:self.info[kGoogleCalendarIDKey]];
    eventsQuery.singleEvents = YES;
    eventsQuery.maxResults = 1000;
    [self.gtlCalendarService executeQuery:eventsQuery
                     completionHandler:^(GTLServiceTicket *ticket, GTLCalendarEvents *events, NSError *error) {
                       if (error == nil) {
                         [self markCalendarVerified];
                         dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
                           NSDictionary *newDayDictionary = [self dayDictionaryFromEvents:events.items];
                           dispatch_async(dispatch_get_main_queue(),^{
                             self.dayDictionary = newDayDictionary;
                             self.validEvents = YES;
                             [[NSNotificationCenter defaultCenter] postNotificationName:kGoogleCalendarRetrievedEvents object:nil];
                           });
                         });
                       } else if ([self sharedCalendarDeleted:error]) {
                         NSLog(@"Calendar deleted");
                         [[NSNotificationCenter defaultCenter] postNotificationName:kSharedGoogleCalendarDeleted object:nil];
                       }
                     }];
  }
}

-(void)retrieveCalendarEventsfrom:(NSDate *)start
                               to:(NSDate *)end {
  GTLQueryCalendar *eventsQuery = [GTLQueryCalendar queryForEventsListWithCalendarId:self.info[kGoogleCalendarIDKey]];
  if ( [eventsQuery respondsToSelector:@selector(singleEvents)] ) {
    eventsQuery.singleEvents = YES;
  }
  eventsQuery.timeMin = [GTLDateTime dateTimeWithDate:start timeZone:[NSTimeZone systemTimeZone]];
  eventsQuery.timeMax = [GTLDateTime dateTimeWithDate:end timeZone:[NSTimeZone systemTimeZone]];
  eventsQuery.maxResults = 2000;
  [self.gtlCalendarService executeQuery:eventsQuery
                   completionHandler:^(GTLServiceTicket *ticket, GTLCalendarEvents *events, NSError *error) {
                     if (error == nil) {
                       [self markCalendarVerified];
                       dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
                         NSDictionary *newDayDictionary = [self dayDictionaryFromEvents:events.items];
                         dispatch_async(dispatch_get_main_queue(),^{
                           self.dayDictionary = newDayDictionary;
                           self.validEvents = YES;
                           [[NSNotificationCenter defaultCenter] postNotificationName:kGoogleCalendarRetrievedEvents object:nil];
                         });
                       });
                     } else if ([self sharedCalendarDeleted:error]) {
                       NSLog(@"Calendar deleted");
                       [[NSNotificationCenter defaultCenter] postNotificationName:kSharedGoogleCalendarDeleted object:nil];
                     }
                   }];
}

-(void)patchOriginalEvent:(GTLCalendarEvent *)originalEvent
         withRevisedEvent:(GTLCalendarEvent *)revisedEvent
          completionBlock:(void (^)(BOOL success, NSError *error))completionBlock{
  GTLServiceCalendar *service = self.gtlCalendarService;
  GTLCalendarEvent *patchEvent = [revisedEvent patchObjectFromOriginal:originalEvent];
  if (patchEvent) {
    NSString *eventID = originalEvent.identifier;
    GTLQueryCalendar *query = [GTLQueryCalendar queryForEventsPatchWithObject:patchEvent
                                                                   calendarId:self.info[kGoogleCalendarIDKey]
                                                                      eventId:eventID];
    [service executeQuery:query
        completionHandler:^(GTLServiceTicket *ticket, GTLCalendarEvent *event, NSError *error) {
          if (error == nil) {
            [self retrieveCalendarEventsfrom:[CalendarService retrieveFromDateForEvent:event]
                                          to:[CalendarService retrieveToDateForEvent:event]];
          } else {
            [self restoreEvent:revisedEvent fromEvent:originalEvent];
            PSPDFAlertView *alert=[[PSPDFAlertView alloc] initWithTitle:@"Alert" message:[NSString stringWithFormat:@"Unable to update event. Please try later."]];
            [alert setCancelButtonWithTitle:@"OK" block:nil];
            [alert show];
            NSLog(@"Error = %@", [error description]);
          }
          completionBlock(error == nil, error);
        }];
  }
}

- (void)addEvent:(GTLCalendarEvent *)newEvent completionBlock:(void (^)(BOOL success, NSError *error))completionBlock {
  GTLQueryCalendar *query = [GTLQueryCalendar queryForEventsInsertWithObject:newEvent
                                                                  calendarId:self.info[kGoogleCalendarIDKey]];
  
  [self.gtlCalendarService executeQuery:query
                   completionHandler:^(GTLServiceTicket *ticket, GTLCalendarEvent *event, NSError *error) {
                     // Callback
                     if (error == nil) {
                       NSMutableDictionary *newDayDictionary = [NSMutableDictionary dictionaryWithDictionary:self.dayDictionary];
                       [self addEvent:newEvent toDict:newDayDictionary];
                       self.dayDictionary = [NSDictionary dictionaryWithDictionary:newDayDictionary];
                       // force table view reload
                       [[NSNotificationCenter defaultCenter] postNotificationName:kGoogleCalendarRetrievedEvents object:nil];
                       [self retrieveCalendarEventsfrom:[CalendarService retrieveFromDateForEvent:event]
                                                     to:[CalendarService retrieveToDateForEvent:event]];
                     } else {
                       PSPDFAlertView *alert=[[PSPDFAlertView alloc] initWithTitle:@"Alert" message:@"Unable to update event. Please try later."];
                       [alert setCancelButtonWithTitle:@"OK" block:nil];
                       [alert show];
                       NSLog(@"Error = %@", [error description]);
                     }
                     completionBlock(error == nil, error);
                   }];
}

- (void)deleteEvent:(GTLCalendarEvent *)event {
  GTLQueryCalendar *query = [GTLQueryCalendar queryForEventsDeleteWithCalendarId:self.info[kGoogleCalendarIDKey]
                                                                         eventId:event.identifier];
  
  [self.gtlCalendarService executeQuery:query
                   completionHandler:^(GTLServiceTicket *ticket, id nilObject, NSError *error) {
                     if (error == nil) {
                       [self retrieveCalendarEventsfrom:[CalendarService retrieveFromDateForEvent:event]
                                                     to:[CalendarService retrieveToDateForEvent:event]];
                     } else {
                       PSPDFAlertView *alert=[[PSPDFAlertView alloc] initWithTitle:@"Alert" message:@"Unable to update event. Please try later."];
                       [alert setCancelButtonWithTitle:@"OK" block:nil];
                       [alert show];
                       NSLog(@"Error = %@", [error description]);
                       
                     }
                   }];
}

-(void)invitePartnerToEvent:(GTLCalendarEvent *)event {
  NSMutableArray *attendees;
  if (event.attendees) {
    attendees = [event.attendees mutableCopy];
  } else {
    attendees = [NSMutableArray array];
  }
  GTLCalendarEventAttendee *newAttendee = [GTLCalendarEventAttendee object];
  newAttendee.email = [User currentUser].partnerGoogleCalendarUserEmail;
  newAttendee.responseStatus = @"needsAction";
  [attendees addObject: newAttendee];
  event.attendees = attendees;
  
  GTLQueryCalendar *query = [GTLQueryCalendar queryForEventsUpdateWithObject:event
                                                                  calendarId:self.info[kGoogleCalendarIDKey]
                                                                     eventId:event.identifier];
  [self.gtlCalendarService executeQuery:query
                   completionHandler:^(GTLServiceTicket *ticket, id object, NSError *error) {
                     if (error) {
                       PSPDFAlertView *alert=[[PSPDFAlertView alloc] initWithTitle:@"Alert" message:@"Unable to delete event. Please try later."];
                       [alert setCancelButtonWithTitle:@"OK" block:nil];
                       [alert show];
                     }
                   }];
}

- (void)addPermissionForEmail:(NSString *)email {
  // Make a new ACL rule
  GTLCalendarAclRuleScope *scope = [GTLCalendarAclRuleScope object];
  scope.type = @"user";
  scope.value = email;
  
  GTLCalendarAclRule *newRule = [GTLCalendarAclRule object];
  newRule.role = @"owner";
  newRule.scope = scope;
  
  GTLQueryCalendar *query = [GTLQueryCalendar queryForAclInsertWithObject: newRule
                                                               calendarId: self.info[kGoogleCalendarIDKey]];
  [self.gtlCalendarService executeQuery: query
                      completionHandler:^(GTLServiceTicket *ticket, id object, NSError *error) {
                        if (!error) {
                          self.info[kGoogleCalendarSharedKey] = @(YES);
                        } else {
                          self.info[kGoogleCalendarSharedKey] = @(NO);
                        }
                        self.info[kGoogleCalendarPartnerUserEmailKey] = email;
                        [self.info saveInBackgroundElseEventually];
                      }];
}

- (void)markCalendarVerified {
  if ( [self.info isDataAvailable] && !self.info[kGoogleCalendarVerifiedKey] ) {
    self.info[kGoogleCalendarVerifiedKey] = @(YES);
    [self.info saveInBackgroundElseEventually];
  }
}

- (void)restoreEvent:(GTLCalendarEvent *)event fromEvent:(GTLCalendarEvent *)originalEvent {
  // restore original event
  event.summary = originalEvent.summary;
  event.location = originalEvent.location;
  event.start = originalEvent.start;
  event.end = originalEvent.end;
  event.recurrence = originalEvent.recurrence;
  event.recurringEventId = originalEvent.recurringEventId;
  event.reminders = originalEvent.reminders;
  event.transparency = originalEvent.transparency;
  event.descriptionProperty = originalEvent.descriptionProperty;
}

-(void)fetchCalendarInfo {
  if (self.info.objectId) {
    [self.info fetchInBackgroundWithBlock:^(PFObject *object, NSError *error) {
      if ( !error ) {
        self.info = object;
      }
    }];
  }
}

#pragma mark utility functions
-(BOOL)sharedCalendarDeleted:(NSError *)error {
  if ([self.info isDataAvailable] &&
      self.info[kGoogleCalendarVerifiedKey] &&
      error.code == 404 &&
      [error.localizedDescription rangeOfString:@"Not Found"].location != NSNotFound) {
    return YES;
  } else {
    return NO;
  }
}

+(void)resetCalendarForCalendarInfo:(PFObject *)calendarInfo {
  [calendarInfo deleteInBackgroundElseEventually];
  [User currentUser].googleCalendarOwner = nil;
  [User currentUser].myGoogleCalendarUserEmail = nil;
  [User currentUser].partnerGoogleCalendarUserEmail = nil;
  [[User currentUser] saveToNetwork];
  [[NSFileManager defaultManager] removeItemAtPath:[CalendarService calendarDataPath] error:nil];
  sharedInstance = nil;
}

+ (NSDate *)retrieveFromDateForEvent:(GTLCalendarEvent *)event {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  
  NSDateComponents *pastComponent = [[NSDateComponents alloc] init];
  pastComponent.month = -8;
  
  if (event.start.date) {
    return [calendar dateByAddingComponents:pastComponent toDate:event.start.date.date options:0];
  } else {
    return [calendar dateByAddingComponents:pastComponent toDate:event.start.dateTime.date options:0];
  }
  
}

+ (NSDate *)retrieveToDateForEvent:(GTLCalendarEvent *)event {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDateComponents *futureComponent = [[NSDateComponents alloc] init];
  futureComponent.month = 8;
  
  if (event.start.date) {
    return [calendar dateByAddingComponents:futureComponent toDate:event.start.date.date options:0];
  } else {
    return [calendar dateByAddingComponents:futureComponent toDate:event.start.dateTime.date options:0];
  }
  
}

+ (BOOL)isSameDayWithDate1:(NSDate *)date1 date2:(NSDate *)date2 {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSUInteger unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
  NSDateComponents *comp1 = [calendar components:unitFlags fromDate:date1];
  NSDateComponents *comp2 = [calendar components:unitFlags fromDate:date2];
  
  return ([comp1 day] == [comp2 day] &&
          [comp1 month] == [comp2 month] &&
          [comp1 year] == [comp2 year]);
}

#pragma mark data persistence
+(NSString *)calendarDataPath {
  return pathInDocumentDirectory([NSString stringWithFormat:@"%@_calendarInfo.data", [User currentUser].myUserID]);
}


- (void)saveCalendar {
  if ([User currentUser].myUserID) {
    NSMutableData *data = [NSMutableData data];
    NSKeyedArchiver *aCoder = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [aCoder encodeObject:self.info forKey:kCalendarInfoKey];
    [aCoder encodeObject:self.dayDictionary forKey:kDayDictKey];
    [aCoder finishEncoding];
    [data writeToFile:[CalendarService calendarDataPath] atomically:YES];
  }
}

- (void)verifyCalendarWithCompletionBlock:(void (^)(BOOL success, NSError *error))completionBlock failureCount:(NSUInteger)failureCount {
  __block NSInteger currentFailureCount = failureCount;
  
  if (self.info[kGoogleCalendarIDKey]) {
    GTLQueryCalendar *eventsQuery = [GTLQueryCalendar queryForEventsListWithCalendarId:self.info[kGoogleCalendarIDKey]];
    eventsQuery.singleEvents = YES;
    eventsQuery.maxResults = 6;
    [self.gtlCalendarService executeQuery:eventsQuery
                        completionHandler:^(GTLServiceTicket *ticket, id object, NSError *error) {
                          if (error == nil) {
                            [self markCalendarVerified];
                            completionBlock(YES, nil);
                          } else {
                            currentFailureCount++;
                            if (currentFailureCount >= 10) {
                              completionBlock(NO, error);
                            } else {
                              dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                [self verifyCalendarWithCompletionBlock:completionBlock failureCount:currentFailureCount];
                              });
                            }
                          }
                        }];
  }
}

@end
