//
//  Video.h
//  PowerOfTwo
//
//  Created by Brian Bernberg on 2/9/12.
//  Copyright (c) 2012 BB Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Video : NSObject {
    NSString *FBID;
    NSInteger owner;
    UIImage *thumbnail;
    UIImage *picture;
    NSURL *videoURL;
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
@property (nonatomic) NSURL *videoURL;
@property (nonatomic) NSDate *createdTime;
@property (nonatomic) NSDate *PFcreatedAt;
@property (nonatomic) NSString *name;
@property (nonatomic) NSMutableArray *comments;
@property (nonatomic) NSMutableArray *likes;
@end

