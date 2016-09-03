//
//  MyNetworkActivityIndicator.m
//  Shared
//
//  Created by Brian Bernberg on 9/4/12.
//  Copyright (c) 2012 BB Consulting. All rights reserved.
//

#import "MyNetworkActivityIndicator.h"

static MyNetworkActivityIndicator *sharedInstance = nil;
static NSInteger activeCount;

@interface MyNetworkActivityIndicator()
@end

@implementation MyNetworkActivityIndicator

+(MyNetworkActivityIndicator *)sharedInstance {
    if (!sharedInstance) {
        sharedInstance = [[MyNetworkActivityIndicator alloc] init];

    }
    return sharedInstance;
}

-(id)init {
    if (self = [super init]) {
        [self reset];
    }
    
    return self;
    
}

-(void)reset {
    activeCount = 0;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = FALSE;
}

-(void)incrementCount {
    activeCount++;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = TRUE;
}

-(void)decrementCount {
    if (activeCount > 0) {
        if (--activeCount == 0) {
            [UIApplication sharedApplication].networkActivityIndicatorVisible = FALSE;
        }
    } else {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = FALSE;
    }
}

@end
