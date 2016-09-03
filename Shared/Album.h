//
//  Album.h
//  PowerOfTwo
//
//  Created by Brian Bernberg on 11/4/11.
//  Copyright (c) 2011 Bern Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Album : NSObject {
    NSString *FBID;
    NSInteger owner;
    UIImage *coverImage;
    NSString *coverImageFBID;
    NSString *updatedTime;
    NSString *name;
    NSInteger count;
}
@property (nonatomic) NSString *FBID;
@property (nonatomic, assign) NSInteger owner;
@property (nonatomic) UIImage *coverImage;
@property (nonatomic) NSString *coverImageFBID;
@property (nonatomic) NSString *updatedTime;
@property (nonatomic) NSString *name;
@property (nonatomic, assign) NSInteger count;
@end
