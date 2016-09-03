//
//  ListService.m
//  Shared
//
//  Created by Brian Bernberg on 5/23/12.
//  Copyright (c) 2012 BB Consulting. All rights reserved.
//

#import "ListService.h"
#import "Constants.h"
#import "MyReach.h"
#import "Constants.h"
#import "SHUtil.h"

#define kListsPathName @"Lists"
#define kLocallyAddedListsPathName @"LocallyAddedLists"
#define kLocallyDeletedListsPathName @"LocallyDeletedLists"
#define kListItemsPathName @"ListItems"
#define kLocallyAddedListItemsPathName @"LocallyAddedListItems"
#define kLocallyDeletedListItemsPathName @"LocallyDeletedListItems"

static ListService *sharedInstance = nil;

@interface ListService ()
@property (nonatomic) BOOL listNetworkCallSucceeded;
@end


@implementation ListService

+(ListService *)sharedInstance {
    if (!sharedInstance) {
        sharedInstance = [[ListService alloc] init];
    }
    return sharedInstance;
}
-(id)init {
    self = [super init];
    if (self) {
      self.lists = nil;
      self.listNetworkCallSucceeded = NO;
      [self retrieveListsFromCache];

      self.listItems = @{};
      
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLogout) name:kDidLogoutNotification object:nil];
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pinListsAndListItems) name:UIApplicationWillResignActiveNotification object:nil];
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(unpinListsAndListItems) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Combined Lists functions

- (void)retrieveListsFromCache {
  PFQuery *query = [self queryForListsFromLocal:YES];
  [query findObjectsInBackgroundWithBlock:^(NSArray *lists, NSError *error) {
    if ( ! self.listNetworkCallSucceeded ) {
      if ( !error ) {
        self.lists = lists;
        [PFObject unpinAllWithObjectIdInBackground:lists];
        
        NSMutableDictionary *newListItems = [NSMutableDictionary dictionary];
        [self.lists enumerateObjectsUsingBlock:^(PFObject *list, NSUInteger idx, BOOL * _Nonnull stop) {
          if ( list[kLocalIDKey] ) {
            PFQuery *itemsQuery = [self queryForListItemsForList:list fromLocal:YES];
            [itemsQuery findObjectsInBackgroundWithBlock:^(NSArray *items, NSError *error) {
              if ( ! error ) {
                newListItems[list[kLocalIDKey]] = items;
                [PFObject unpinAllWithObjectIdInBackground:items];
              }
              if ( list == [self.lists lastObject] && ! self.listNetworkCallSucceeded ) {
                self.listItems = newListItems;
                [[NSNotificationCenter defaultCenter] postNotificationName:kAllListsReceivedNotification object:nil];
              }
            }];
          } else if ( list == [self.lists lastObject] && ! self.listNetworkCallSucceeded ) {
            self.listItems = newListItems;
            [[NSNotificationCenter defaultCenter] postNotificationName:kAllListsReceivedNotification object:nil];
          }
        }];
        
      } else {
        self.lists = @[];
      }
    }
  }];
}

- (void)pinListsAndListItems {
  [PFObject pinAllInBackground:self.lists];
  [self.listItems enumerateKeysAndObjectsUsingBlock:^(NSString *listId, NSArray *listItems, BOOL * _Nonnull stop) {
    [PFObject pinAllInBackground:listItems];
  }];
  
}

- (void)unpinListsAndListItems {
  [PFObject conditionallyPinAllInBackground:self.lists];
  [self.listItems enumerateKeysAndObjectsUsingBlock:^(NSString *listId, NSArray *listItems, BOOL * _Nonnull stop) {
    [PFObject conditionallyPinAllInBackground:listItems];
  }];
}

-(void)retrieveLists {
  // Query for lists
  PFQuery *query = [self queryForListsFromLocal:NO];

  [query findObjectsInBackgroundWithBlock:^(NSArray *lists, NSError *error) {
    if (!error) {
      [PFObject pinAllInBackground:lists block:^(BOOL succeeded, NSError *error) {
        if ( succeeded ) {
          PFQuery *query = [self queryForListsFromLocal:YES];
          [query findObjectsInBackgroundWithBlock:^(NSArray *lists, NSError *error) {
            if ( !error ) {
              self.listNetworkCallSucceeded = YES;
              [lists enumerateObjectsUsingBlock:^(PFObject *list, NSUInteger idx, BOOL *stop) {
                if (!list[kLocalIDKey]) {
                  list[kLocalIDKey] = [SHUtil localID];
                }
              }];
              [PFObject conditionallyPinAllInBackground:self.lists];
              [PFObject conditionallyPinAllInBackground:lists];
              self.lists = lists;
              [[NSNotificationCenter defaultCenter] postNotificationName:kAllListsReceivedNotification
                                                                  object:nil];
            } else {
              [[NSNotificationCenter defaultCenter] postNotificationName:kListsReceiveErrorNotification
                                                                  object:nil];
            }
          }];
        } else {
          [[NSNotificationCenter defaultCenter] postNotificationName:kListsReceiveErrorNotification
                                                              object:nil];
        }
      }];
    } else {
      [[NSNotificationCenter defaultCenter] postNotificationName:kListsReceiveErrorNotification
                                                          object:nil];
    }
  }];

}

   
- (PFQuery *)queryForListsFromLocal:(BOOL)local {
  PFQuery *query = nil;
  if ( local ) {
    query = [PFQuery queryForCurrentUsersWithClassName:kListClass];
    [query fromLocalDatastore];
    [query orderByAscending:kListIndexKey];
  } else {
    query = [PFQuery queryForCurrentUsersWithClassName:kListClass];
    query.limit = kMaxNumberOfLists;
    [query orderByAscending:kListIndexKey];
  }
  
  return query;
}

- (void)createNewListWithName:(NSString *)name {
  PFObject *newList = [PFObject versionedObjectWithClassName:kListClass];
  [newList setObject:[User currentUser].userIDs forKey:kUsersKey];
  [newList setObject:name forKey:kListNameKey];
  [newList setObject:@(self.lists.count) forKey:kListIndexKey];
  [newList setObject:[NSDate date] forKey:kModifiedDateKey];
  [newList setObject:[NSDate date] forKey:kListModifiedDateKey];
  [newList setObject:[SHUtil localID] forKey:kLocalIDKey];
  [self addList:newList];
  [newList pinInBackground];
}

-(void)addList:(PFObject *)theList {
  self.lists = [self.lists arrayByAddingObject:theList];
}

-(void)deleteList:(PFObject *)theList {
  theList[kModifiedDateKey] = [NSDate date];
  NSMutableArray *lists = [NSMutableArray arrayWithArray:self.lists];
  [lists removeObject:theList];
  self.lists = [NSArray arrayWithArray:lists];
  
  // Retrieve list items
  PFQuery *query = [PFQuery queryForCurrentUsersWithClassName:kListItemClass];
  [query whereKey:kListNameKey equalTo:theList[kListNameKey]];
  query.limit = kMaxNumberOfListItems;
    
  [query findObjectsInBackgroundWithBlock:^(NSArray *listItems, NSError *error) {
    if (!error) {
      // Delete all the things
      [theList deleteInBackground];
      [theList unpinInBackground];
      [PFObject deleteAllInBackground:listItems];
      [PFObject unpinAllInBackground:listItems];
    } else {
      [[NSNotificationCenter defaultCenter] postNotificationName:kListDeleteErrorNotification object:nil];
    }
  }];
}

-(void)saveLists {
  [self.lists enumerateObjectsUsingBlock:^(PFObject *list, NSUInteger idx, BOOL *stop) {
    list[kListIndexKey] = @(idx);
    [list saveEventually];
  }];
  [PFObject conditionallyPinAllInBackground:self.lists];
  
}

-(void)moveList:(PFObject *)theList toIndex:(NSInteger)theToIndex {
  NSMutableArray *lists = [NSMutableArray arrayWithArray:self.lists];
  [lists removeObject:theList];
  [lists insertObject:theList atIndex:theToIndex];
  self.lists = lists;
  [self saveLists];
}

#pragma mark individual list functions

-(void)retrieveItemsForList:(PFObject *)theList usingCache:(BOOL)useCache {
  __block BOOL networkCallSuccessful = NO;
  if ( useCache ) {
    PFQuery *query = [self queryForListItemsForList:theList fromLocal:YES];
    [query findObjectsInBackgroundWithBlock:^(NSArray *listItems, NSError *error) {
      if ( !error && !networkCallSuccessful ) {
        NSMutableDictionary *newDictionary = [NSMutableDictionary dictionaryWithDictionary:self.listItems];
        newDictionary[theList[kLocalIDKey]] = [self sortAndIndexListItems:listItems];
        self.listItems = [NSDictionary dictionaryWithDictionary:newDictionary];
        NSDictionary *userInfo = @{ kNotificationListKey : theList,
                                    kNotificationListItemsKey : listItems };
        [[NSNotificationCenter defaultCenter] postNotificationName:kAllListItemsReceivedNotification object:nil userInfo:userInfo];
      }
    }];
  }
  
  PFQuery *query = [self queryForListItemsForList:theList fromLocal:NO];

  [query findObjectsInBackgroundWithBlock:^(NSArray *listItems, NSError *error) {
    if (!error) {
      [PFObject pinAllInBackground:listItems block:^(BOOL succeeded, NSError *error) {
        if ( succeeded ) {
          networkCallSuccessful = YES;
          PFQuery *query = [self queryForListItemsForList:theList fromLocal:YES];
          [query findObjectsInBackgroundWithBlock:^(NSArray *listItems, NSError *error) {
            if ( !error ) {
              if ( self.listItems[theList[kLocalIDKey]] ) {
                [PFObject conditionallyPinAllInBackground:self.listItems[theList[kLocalIDKey]]];
              }
              NSMutableDictionary *newDictionary = [NSMutableDictionary dictionaryWithDictionary:self.listItems];
              newDictionary[theList[kLocalIDKey]] = [self sortAndIndexListItems:listItems];
              self.listItems = [NSDictionary dictionaryWithDictionary:newDictionary];
              [PFObject conditionallyPinAllInBackground:self.listItems[theList[kLocalIDKey]]];
              NSDictionary *userInfo = @{ kNotificationListKey : theList,
                                          kNotificationListItemsKey : self.listItems[theList[kLocalIDKey]] };
              [[NSNotificationCenter defaultCenter] postNotificationName:kAllListItemsReceivedNotification
                                                                  object:nil
                                                                userInfo:userInfo];
            } else {
              [[NSNotificationCenter defaultCenter] postNotificationName:kListItemsReceiveErrorNotification object:nil];
            }
          }];
        } else {
          [[NSNotificationCenter defaultCenter] postNotificationName:kListItemsReceiveErrorNotification object:nil];
        }
      }];
    } else {
      [[NSNotificationCenter defaultCenter] postNotificationName:kListItemsReceiveErrorNotification object:nil];
    }
  }];
}

- (void)retrieveItemsMaybeFromCacheForList:(PFObject *)theList {
  BOOL useCache = self.listItems[theList[kLocalIDKey]] == nil;
  [self retrieveItemsForList:theList usingCache:useCache];
}

- (PFQuery *)queryForListItemsForList:(PFObject *)list fromLocal:(BOOL)local {
  PFQuery *query = [PFQuery queryForCurrentUsersWithClassName:kListItemClass];
  if ( local ) {
    [query fromLocalDatastore];
  } else {
    query.limit = kMaxNumberOfListItems;
  }
  [query whereKey:kListKey equalTo:list];
  [query orderByAscending:kListItemIndexKey];
  return query;
}

-(NSArray *)sortAndIndexListItems:(NSArray *)listItems {
    NSMutableArray *incompleteItems = [NSMutableArray array];
    NSMutableArray *completeItems = [NSMutableArray array];
    for (PFObject *anItem in listItems) {
        if ([[anItem objectForKey:kListItemCompleteKey] boolValue]) {
            [completeItems addObject:anItem];
        } else {
            [incompleteItems addObject:anItem];
        }
    }
    
    [incompleteItems addObjectsFromArray:completeItems];
  
    [incompleteItems enumerateObjectsUsingBlock:^(PFObject *listItem, NSUInteger idx, BOOL *stop) {
      listItem[kListIndexKey] = @(idx);
      if (!listItem[kListItemMembersKey]) {
        listItem[kListItemMembersKey] = @[];
      }
    }];
  
    return [NSArray arrayWithArray:incompleteItems];
    
}



-(void)deleteListItem:(PFObject *)listItem fromList:(PFObject *)list {
  NSMutableArray *listItems = [NSMutableArray arrayWithArray:self.listItems[list[kLocalIDKey]]];
  [listItems removeObject:listItem];
  
  NSMutableDictionary *newDictionary = [NSMutableDictionary dictionaryWithDictionary:self.listItems];
  newDictionary[list[kLocalIDKey]] = [NSArray arrayWithArray:listItems];
  self.listItems = [NSDictionary dictionaryWithDictionary:newDictionary];
  
  [listItem deleteInBackground];
  [listItem unpinInBackground];
}

-(void)saveList:(PFObject *)list withListItems:(NSArray *)listItems {
  NSMutableDictionary *newDictionary = [NSMutableDictionary dictionaryWithDictionary:self.listItems];
  newDictionary[list[kLocalIDKey]] = listItems;
  self.listItems = [NSDictionary dictionaryWithDictionary:newDictionary];

  NSDate *date = [NSDate date];
  [listItems enumerateObjectsUsingBlock:^(PFObject *listItem, NSUInteger idx, BOOL *stop) {
    listItem[kListItemIndexKey] = @(idx);
    listItem[kModifiedDateKey] = date;
    [listItem saveEventually];
    [listItem conditionallyPinInBackground];
  }];
  
  list[kListModifiedDateKey] = date;
  [list saveEventually];
  [list conditionallyPinInBackground];
}

-(NSArray *)listItemsForList:(PFObject *)list {
  if (!self.listItems[list[kLocalIDKey]]) {
    NSMutableDictionary *newDictionary = [self.listItems mutableCopy];
    newDictionary[list[kLocalIDKey]] = @[];
    self.listItems = [NSDictionary dictionaryWithDictionary:newDictionary];
  }
    
  return self.listItems[list[kLocalIDKey]];
}

- (void)moveListItem:(PFObject *)listItem toIndex:(NSUInteger)index inList:(PFObject *)list {
  
  NSMutableArray *listItems = [NSMutableArray arrayWithArray:self.listItems[list[kLocalIDKey]]];
  [listItems removeObject:listItem];
  [listItems insertObject:listItem atIndex:index];
  
  
  NSMutableDictionary *newDictionary = [NSMutableDictionary dictionaryWithDictionary:self.listItems];
  newDictionary[list[kLocalIDKey]] = [NSArray arrayWithArray:listItems];
  self.listItems = [NSDictionary dictionaryWithDictionary:newDictionary];
  
}

- (void)saveListItem:(PFObject *)listItem {
  [listItem saveEventually];
  [listItem conditionallyPinInBackground];
}

- (void)createNewListItem:(NSString *)listItem forList:(PFObject *)list {
  PFObject *newListItem = [PFObject versionedObjectWithClassName:kListItemClass];
  newListItem[kListKey] = list;
  newListItem[kUsersKey] = [User currentUser].userIDs;
  newListItem[kListItemMembersKey] = @[];
  newListItem[kListItemKey] = listItem;
  newListItem[kListItemIndexKey] = @(0);
  newListItem[kListItemCompleteKey] = @(NO);
  newListItem[kModifiedDateKey] = [NSDate date];
  newListItem[kLocalIDKey] = [SHUtil localID];
  NSMutableArray *listItems = [NSMutableArray arrayWithArray:self.listItems[list[kLocalIDKey]]];
  [listItems insertObject:newListItem atIndex:0];
  [self saveList:list withListItems:listItems];
}

#pragma mark logout handler
-(void)handleLogout {
    sharedInstance = nil;
}

@end
