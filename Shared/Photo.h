//
//  Photo.h
//  PowerOfTwo
//
//  Created by Brian Bernberg on 10/22/11.
//  Copyright (c) 2011 Bern Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Photo : NSObject {
    NSString *FBID;
    NSInteger owner;
    UIImage *thumbnail;
    UIImage *picture;
    NSDate *createdTime;
    NSDate *PFcreatedAt;
    NSString *name;
    NSMutableArray *comments;
    NSMutableArray *likes;
}

@property (nonatomic) NSString *FBID;
@property (nonatomic, assign) NSInteger owner;
@property (nonatomic) UIImage *thumbnail;
@property (nonatomic) UIImage *picture;
@property (nonatomic) NSDate *createdTime;
@property (nonatomic) NSDate *PFcreatedAt;
@property (nonatomic) NSString *name;
@property (nonatomic) NSMutableArray *comments;
@property (nonatomic) NSMutableArray *likes;
@end
