//
//  MyReach.m
//  Shared
//
//  Created by Brian Bernberg on 7/19/12.
//  Copyright (c) 2012 BB Consulting. All rights reserved.
//

#import "MyReach.h"
static MyReach *sharedInstance = nil;

@interface MyReach()

@property (strong) Reachability *fbReach;
@property (strong) Reachability *pfReach;

@end

@implementation MyReach
+(MyReach *)sharedInstance {
    if (!sharedInstance) {
        sharedInstance = [[MyReach alloc] init];
    }
    return sharedInstance;
}

-(id)init {
    if (self = [super init]) {
        // allocate fb reachability object
        self.fbReach = [Reachability reachabilityWithHostname:@"www.facebook.com"];

        // set the blocks
        __weak MyReach *weakSelf = self;
        self.fbReach.reachableBlock = ^(Reachability*reach)
        {
            weakSelf.fbReachable = YES;
            NSLog(@"FB REACHABLE!");
        };
        
        self.fbReach.unreachableBlock = ^(Reachability*reach)
        {
            weakSelf.fbReachable = NO;
            NSLog(@"UNREACHABLE!");
        };
        
        [self.fbReach startNotifier];

        // allocate pf reachability object
        self.pfReach = [Reachability reachabilityWithHostname:@"www.parse.com"];
        
        // set the blocks
        self.pfReach.reachableBlock = ^(Reachability*reach)
        {
            weakSelf.pfReachable = YES;
            NSLog(@"PF REACHABLE!");
        };
        
        self.pfReach.unreachableBlock = ^(Reachability*reach)
        {
            weakSelf.pfReachable = NO;
            NSLog(@"PF UNREACHABLE!");
        };
        
        [self.pfReach startNotifier];
                
    }
    return self;
}

@end
