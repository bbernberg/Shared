//
//  ListService.h
//  Shared
//
//  Created by Brian Bernberg on 5/23/12.
//  Copyright (c) 2012 BB Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

#define kMaxNumberOfLists 100
#define kMaxNumberOfListItems 100

@interface ListService : NSObject

@property (nonatomic, strong) NSArray *lists;
@property (nonatomic, strong) NSDictionary *listItems;

+ (ListService *)sharedInstance;
- (void)createNewListWithName:(NSString *)name;
- (void)retrieveLists;
- (void)saveLists;
- (void)addList:(PFObject *)theList;
- (void)deleteList:(PFObject *)theList;
- (void)moveList:(PFObject *)theList toIndex:(NSInteger)theToIndex;

- (void)retrieveItemsForList:(PFObject *)theList usingCache:(BOOL)useCache;
- (void)retrieveItemsMaybeFromCacheForList:(PFObject *)theList;

- (void)deleteListItem:(PFObject *)listItem fromList:(PFObject *)list;
- (void)saveList:(PFObject *)theList withListItems:(NSArray *)theListItems;;
- (void)moveListItem:(PFObject *)listItem toIndex:(NSUInteger)index inList:(PFObject *)list;
- (NSArray *)listItemsForList:(PFObject *)list;
- (void)saveListItem:(PFObject *)listItem;
- (void)createNewListItem:(NSString *)listItem forList:(PFObject *)list;

@end