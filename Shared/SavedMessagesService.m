//
//  SavedMessages.m
//  Shared
//
//  Created by Brian Bernberg on 8/20/13.
//  Copyright (c) 2013 BB Consulting. All rights reserved.
//

#import "SavedMessagesService.h"
#import "Constants.h"
#import "PF+SHExtend.h"
#import "SHUtil.h"

#define kSavedMessagesType @"saved_messages"

static SavedMessagesService *instance = nil;

@interface SavedMessagesService()

@property (nonatomic) NSArray* messages;
@property (nonatomic) BOOL networkCallSucceeded;

@end

@implementation SavedMessagesService

+(SavedMessagesService *)instance {
  if (!instance) {
    instance = [[SavedMessagesService alloc] init];
    
  }
  return instance;
}

-(id)init {
  self = [super init];
  if (self) {
    self.messages = @[];
    self.networkCallSucceeded = NO;
    [self retrieveSavedMessagesFromCache];
    
    // register for notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLogout) name:kDidLogoutNotification object:nil];
    
  }
  return self;
}

-(void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark message retrieval
- (PFQuery *)queryForSavedMessagesFromLocal:(BOOL)local {
  NSMutableArray* queries = [NSMutableArray array];
  if ( [User currentUser].myUserEmail ) {
    PFQuery *query = [PFQuery queryWithClassName:kSavedMessageClass];
    if ( local ) {
      [query fromLocalDatastore];
    }
    [query whereKey:kSavedMessageUserIDKey equalTo:[User currentUser].myUserEmail];
    [queries addObject:query];
  }
  if ( [User currentUser].myFBID ) {
    PFQuery *query = [PFQuery queryWithClassName:kSavedMessageClass];
    if ( local ) {
      [query fromLocalDatastore];
    }
    [query whereKey:kSavedMessageUserIDKey equalTo:[User currentUser].myFBID];
    [queries addObject:query];
  }
  PFQuery *orQuery = [PFQuery orQueryWithSubqueries:queries];
  [orQuery orderByAscending:kSavedMessageIndexKey];
  if ( local ) {
    [orQuery fromLocalDatastore];
  }
  return orQuery;
}

- (void)retrieveSavedMessagesFromCache {
  PFQuery *query = [self queryForSavedMessagesFromLocal:YES];
  [query findObjectsInBackgroundWithBlock:^(NSArray *messages, NSError *error) {
    if ( ! self.networkCallSucceeded ) {
      if ( ! error ) {
        self.messages = messages;
      } else {
        self.messages = @[];
      }
    }
  }];
  
}

-(void)retrieveSavedMessages {
  PFQuery *query = [self queryForSavedMessagesFromLocal:NO];
  
  [query findObjectsInBackgroundWithBlock:^(NSArray *messages, NSError *error) {
    if (!error) {
      [PFObject unpinAllInBackground:self.messages];
      [PFObject pinAllInBackground:messages];
      self.messages = messages;
      [[NSNotificationCenter defaultCenter] postNotificationName:kSavedMessagesUpdatedNotification object:nil];
    }
  }];
}

-(void)addSavedMessage:(NSString *)message {
  PFObject *savedMessage = [PFObject versionedObjectWithClassName:kSavedMessageClass];
  savedMessage[kSavedMessageUserIDKey] = [User currentUser].myUserID;
  savedMessage[kSavedMessageMessageKey] = message;
  NSMutableArray *messages = [NSMutableArray arrayWithArray:self.messages];
  [messages insertObject:savedMessage atIndex:0];
  self.messages = [NSArray arrayWithArray:messages];
  [self storeIndexesAndSaveMessages];
}

-(void)deleteSavedMessage:(PFObject *)message {
  NSMutableArray *messages = [NSMutableArray arrayWithArray:self.messages];
  [messages removeObject:message];
  [message unpinInBackground];
  [message deleteInBackgroundElseEventually];
  self.messages = [NSArray arrayWithArray:messages];
  [self storeIndexesAndSaveMessages];
}

-(void)moveSavedMessage:(PFObject *)message toIndex:(NSUInteger)toIndex {
  NSMutableArray *messages = [NSMutableArray arrayWithArray:self.messages];
  [messages removeObject:message];
  [messages insertObject:message atIndex:toIndex];
  self.messages = [NSArray arrayWithArray:messages];
  [self storeIndexesAndSaveMessages];
}

#pragma mark utility methods
-(void)storeIndexesAndSaveMessages {
  [self.messages enumerateObjectsUsingBlock:^(PFObject *savedMessage, NSUInteger idx, BOOL *stop) {
    savedMessage[kSavedMessageIndexKey] = @(idx);
    [savedMessage saveInBackgroundElseEventually];
    [savedMessage pinInBackground];
  }];
  
}

#pragma mark logout handler
-(void)handleLogout {
  instance = nil;
}

@end
