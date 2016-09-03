//
//  MyReach.h
//  Shared
//
//  Created by Brian Bernberg on 7/19/12.
//  Copyright (c) 2012 BB Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Reachability.h"

@interface MyReach : NSObject
@property BOOL fbReachable;
@property BOOL pfReachable;
+(MyReach *)sharedInstance;
@end
