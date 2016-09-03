//
//  NotificationRetriever.h
//  Shared
//
//  Created by Brian Bernberg on 7/14/13.
//  Copyright (c) 2013 BB Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NotificationRetriever : NSObject

@property (nonatomic, readonly) NSArray *notifications;

+(NotificationRetriever *)instance;
-(void)retrieveNotifications;
-(void)deleteNotificationsOfType:(NSString *)notificationType;
-(void)deleteNotificationsOfType:(NSString *)notificationType queryServer:(BOOL)queryServer;

@end
