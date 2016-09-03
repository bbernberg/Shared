//
//  NotificationController.h
//  Shared
//
//  Created by Brian Bernberg on 7/14/13.
//  Copyright (c) 2013 BB Consulting. All rights reserved.
//

#import "SHTableViewController.h"

@protocol NotificationControllerDelegate;

@interface NotificationController : SHViewController

-(instancetype)initWithDelegate:(id<NotificationControllerDelegate>)delegate;

@end

@protocol NotificationControllerDelegate <NSObject>

-(void)didSelectNotificationType:(NSString*)notificationType;

@end
