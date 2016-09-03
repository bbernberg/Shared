//
//  MyFacebook.h
//  PowerOfTwo
//
//  Created by Brian Bernberg on 12/3/11.
//  Copyright (c) 2011 BB Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FBConnect.h"

@interface MyFacebook : Facebook
+(Facebook *)sharedInstance;
@end
