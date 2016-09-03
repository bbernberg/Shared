//
//  ListViewController.h
//  Shared
//
//  Created by Brian Bernberg on 5/25/12.
//  Copyright (c) 2012 BB Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Parse/Parse.h"
#import <MessageUI/MessageUI.h>
#import "SHViewController.h"

@interface ListController : SHViewController
- (id)initWithList:(PFObject *)theList;

@end
