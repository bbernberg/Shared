//
//  PF+SHExtend.h
//  Shared
//
//  Created by Brian Bernberg on 3/13/13.
//  Copyright (c) 2013 BB Consulting. All rights reserved.
//

#import <Parse/Parse.h>

@interface PFObject (SHExtend)
-(void) encodeWithCoder:(NSCoder *) encoder;
-(id) initWithCoder:(NSCoder *) aDecoder;
+(PFObject *)versionedObjectWithClassName:(NSString *)className;
-(BOOL)isEquivalent:(PFObject *)object;
- (void)saveInBackgroundElseEventually;
- (void)deleteInBackgroundElseEventually;
+ (void)pinAllWithoutObjectIdInBackground:(NSArray *)objects;
+ (void)unpinAllWithObjectIdInBackground:(NSArray *)objects;
- (void)conditionallyPinInBackground;
+ (void)conditionallyPinAllInBackground:(NSArray *)objects;
@end

@interface PFQuery (SHExtend)
+ (PFQuery *)queryForCurrentUsersWithClassName:(NSString *)className;
@end

@interface PFACL (SHExtend)
-(void) encodeWithCoder:(NSCoder *)encoder;
-(id)initWithCoder:(NSCoder *) aDecoder;
@end

