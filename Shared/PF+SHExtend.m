//
//  PF+SHExtend.m
//  Shared
//
//  Created by Brian Bernberg on 3/13/13.
//  Copyright (c) 2013 BB Consulting. All rights reserved.
//

#import "PF+SHExtend.h"
#import "Constants.h"

@implementation PFObject (SHExtend)

#pragma mark - NSCoding compliance
#define kPFObjectAllKeys @"___PFObjectAllKeys"
#define kPFObjectClassName @"___PFObjectClassName"
#define kPFObjectObjectId @"___PFObjectId"
#define kPFACLPermissions @"permissionsById"
#define kPFFileName @"__PFFileName"
#define kPFFileData @"__PFFileData"

-(void) encodeWithCoder:(NSCoder *) encoder{
    
    // Encode first className, objectId and All Keys
    [encoder encodeObject:[self parseClassName] forKey:kPFObjectClassName];
    [encoder encodeObject:[self objectId] forKey:kPFObjectObjectId];
    [encoder encodeObject:[self allKeys] forKey:kPFObjectAllKeys];
    for (NSString * key in [self allKeys]) {
        // Ignore PFFiles
        if ([self[key] isKindOfClass:[PFFile class]]) {
            NSLog(@"Ignoring PFFile");
        } else {
            [encoder encodeObject:self[key] forKey:key];
        }
    }
    
}

-(id) initWithCoder:(NSCoder *) aDecoder{
    
    // Decode the className and objectId
    NSString * aClassName  = [aDecoder decodeObjectForKey:kPFObjectClassName];
    NSString * anObjectId = [aDecoder decodeObjectForKey:kPFObjectObjectId];
    
    
    // Init the object
    self = [PFObject objectWithoutDataWithClassName:aClassName objectId:anObjectId];
    
    if (self) {
        NSArray * allKeys = [aDecoder decodeObjectForKey:kPFObjectAllKeys];
        for (NSString * key in allKeys) {
            id obj = [aDecoder decodeObjectForKey:key];
            if (obj) {
                self[key] = obj;
            }
            
        }
    }
    return self;
}

+(PFObject *)versionedObjectWithClassName:(NSString *)className {
    PFObject *obj = [PFObject objectWithClassName:className];
    NSDictionary* info = [[NSBundle mainBundle] infoDictionary];
    
    obj[kAppVersionKey] = info[@"CFBundleVersion"];
    
    return obj;
}

-(BOOL)isEquivalent:(PFObject *)object {

    return ( self.objectId && object.objectId && [self.objectId isEqualToString: object.objectId]) ||
           ( !self.objectId && [self[kLocalIDKey] isEqualToString:object[kLocalIDKey]] );
    
}

- (void)saveInBackgroundElseEventually {
  [self saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
    if (!succeeded) {
      [self saveEventually];
    }
  }];
}

- (void)deleteInBackgroundElseEventually {
  [self deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
    if (!succeeded) {
      [self deleteEventually];
    }
  }];
}

+ (void)pinAllWithoutObjectIdInBackground:(NSArray *)objects {
  [objects enumerateObjectsUsingBlock:^(PFObject *object, NSUInteger idx, BOOL * _Nonnull stop) {
    if ( ! object.objectId ) {
      [object pinInBackground];
    }
  }];
}

+ (void)unpinAllWithObjectIdInBackground:(NSArray *)objects {
  [objects enumerateObjectsUsingBlock:^(PFObject *object, NSUInteger idx, BOOL * _Nonnull stop) {
    if ( object.objectId ) {
      [object unpinInBackground];
    }
  }];
}

- (void)conditionallyPinInBackground {
  if ( self.objectId ) {
    [self unpinInBackground];
  } else {
    [self pinInBackground];
  }
}

+ (void)conditionallyPinAllInBackground:(NSArray *)objects {
  [objects enumerateObjectsUsingBlock:^(PFObject *object, NSUInteger idx, BOOL * _Nonnull stop) {
    [object conditionallyPinInBackground];
  }];
}

@end

@implementation PFQuery (SHExtend)
+ (PFQuery *)queryForCurrentUsersWithClassName:(NSString *)className {
  NSMutableArray* queries = [NSMutableArray array];
  if ( [User currentUser].myUserEmail ) {
    PFQuery *query = [PFQuery queryWithClassName:className];
    NSArray *array = @[[User currentUser].myUserEmail, [User currentUser].partnerUserID];
    [query whereKey:kUsersKey containsAllObjectsInArray:array];
    [queries addObject:query];
  }
  if ( [User currentUser].myFBID ) {
    PFQuery *query = [PFQuery queryWithClassName:className];
    NSArray *array = @[[User currentUser].myFBID, [User currentUser].partnerUserID];
    [query whereKey:kUsersKey containsAllObjectsInArray:array];
    [queries addObject:query];
  }
  PFQuery *orQuery = [PFQuery orQueryWithSubqueries:queries];
  
  return orQuery;
}
@end

