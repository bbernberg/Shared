//
//  MyFacebook.m
//  PowerOfTwo
//
//  Created by Brian Bernberg on 12/3/11.
//  Copyright (c) 2011 BB Consulting. All rights reserved.
//

#import "MyFacebook.h"
#import "Constants.h"

static Facebook *sharedInstance = nil;

@implementation MyFacebook
+(Facebook *)sharedInstance {
    if (!sharedInstance) {
        sharedInstance = [[Facebook alloc] initWithAppId:kFBAppIdString
                                       andDelegate:nil];
    }
    return sharedInstance;
}


@end
