//
//  SavedMessages.h
//  Shared
//
//  Created by Brian Bernberg on 8/20/13.
//  Copyright (c) 2013 BB Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SavedMessagesService : NSObject

@property (nonatomic, readonly) NSArray *messages;

+(SavedMessagesService *)instance;
-(void)retrieveSavedMessages;
-(void)addSavedMessage:(NSString *)message;
-(void)deleteSavedMessage:(PFObject *)message;
-(void)moveSavedMessage:(PFObject *)message toIndex:(NSUInteger)toIndex;
@end
