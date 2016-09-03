//
//  SavedMessagesController.h
//  Shared
//
//  Created by Brian Bernberg on 8/20/13.
//  Copyright (c) 2013 BB Consulting. All rights reserved.
//

#import "SHViewController.h"

@protocol SavedMessagesDelegate;

@interface SavedMessagesController : SHViewController

- (id)initWithDelegate: (id<SavedMessagesDelegate>)delegate;

@end

@protocol SavedMessagesDelegate <NSObject>

-(void)savedMessageSelected: (NSString*)savedMessage;
-(void)dismiss;

@end
