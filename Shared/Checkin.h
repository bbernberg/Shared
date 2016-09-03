//
//  Checkin.h
//  PowerOfTwo
//
//  Created by Brian Bernberg on 3/11/12.
//  Copyright (c) 2012 Bern Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Checkin : NSObject 
@property NSString *FBID;
@property NSInteger owner;
@property NSDictionary *place;
@property UIImage *photo;
@property NSString *type;
@property UIImage *placePicture;
@property NSDate *createdTime;
@property NSDate *PFcreatedAt;
@property NSString *message;
@property NSMutableArray *comments;
@property NSMutableArray *likes;

@end
