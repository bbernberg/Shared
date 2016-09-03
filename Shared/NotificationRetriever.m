//
//  NotificationRetriever.m
//  Shared
//
//  Created by Brian Bernberg on 7/14/13.
//  Copyright (c) 2013 BB Consulting. All rights reserved.
//

#import "NotificationRetriever.h"
#import "Constants.h"

static NotificationRetriever *instance = nil;

@interface NotificationRetriever()
@property (nonatomic, assign) BOOL isRetrieving;
@property (nonatomic) NSArray *notifications;
@end

@implementation NotificationRetriever
+(NotificationRetriever *)instance {
  if (!instance) {
    instance = [[NotificationRetriever alloc] init];
    
  }
  return instance;
}

-(id)init {
  self = [super init];
  if (self) {
    _notifications = @[];
    _isRetrieving = NO;
  }
  return self;
}

-(void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark notification retrieval
-(void)retrieveNotifications {
  if (!self.isRetrieving && [User currentUser].myUserID && [User currentUser].partnerUserID) {
    PFQuery *query = [PFQuery queryForCurrentUsersWithClassName:kNotificationClass];
    [query whereKey:kNotificationSenderKey notContainedIn:[User currentUser].myUserIDs];
    [query orderByDescending:@"createdAt"];
    
    self.isRetrieving = YES;
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
      if (!error) {
        self.notifications = [NSArray arrayWithArray:objects];
        [[NSNotificationCenter defaultCenter] postNotificationName:kUpdateNotificationButtonNotification object:nil];
      }
      self.isRetrieving = NO;
    }];
  }
}

-(void)deleteNotificationsOfType:(NSString *)notificationType {
  [self deleteNotificationsOfType:notificationType queryServer:NO];
}

-(void)deleteNotificationsOfType:(NSString *)notificationType queryServer:(BOOL)queryServer {
  if (queryServer) {
    PFQuery *query = [PFQuery queryForCurrentUsersWithClassName:kNotificationClass];
    [query whereKey:kNotificationSenderKey notContainedIn:[User currentUser].myUserIDs];
    [query orderByDescending:@"createdAt"];
    [query whereKey:kPushTypeKey equalTo:notificationType];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
      if (!error) {
        self.notifications = [NSArray arrayWithArray:objects];
        [self doDeleteOfNotificationType:notificationType];
      }
    }];
  } else {
    [self doDeleteOfNotificationType:notificationType];
  }
  
}

-(void) doDeleteOfNotificationType:(NSString *)notificationType {
  NSMutableArray *newNotifications = [NSMutableArray array];
  BOOL sendNotification = NO;
  
  for (PFObject *notification in self.notifications) {
    if ([notification[kPushTypeKey] isEqualToString:notificationType]) {
      [notification deleteInBackground];
      sendNotification = YES;
    } else {
      [newNotifications addObject:notification];
    }
  }
  
  self.notifications = [NSArray arrayWithArray:newNotifications];
  if ( sendNotification ) {
    [[NSNotificationCenter defaultCenter] postNotificationName:kUpdateNotificationButtonNotification object:nil];
  }
}

@end
