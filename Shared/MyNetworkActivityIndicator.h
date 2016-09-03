//
//  MyNetworkActivityIndicator.h
//  Shared
//
//  Created by Brian Bernberg on 9/4/12.
//  Copyright (c) 2012 BB Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MyNetworkActivityIndicator : NSObject
+(MyNetworkActivityIndicator *)sharedInstance;
-(void)incrementCount;
-(void)decrementCount;
-(void)reset;
@end
