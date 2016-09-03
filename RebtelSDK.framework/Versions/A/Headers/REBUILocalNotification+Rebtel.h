/*
 * Copyright (c) 2012 Rebtel Networks AB. All rights reserved.
 *
 * See LICENSE file for license terms and information.
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 * REBLocalNotificationRebtelAdditions is a set of category methods for the 
 * UILocalNotification class. 
 *
 */

@interface UILocalNotification (REBLocalNotificationRebtelAdditions)

/**
 * Indicates that the UILocalNotification was created by the RebtelSDK
 */
- (BOOL)reb_isRebtelNotification;

/**
 * The UILocalNotification represents an incoming call
 */
- (BOOL)reb_isIncomingCall;

/**
 * The UILocalNotification represents a missed call
 */
- (BOOL)reb_isMissedCall;

@end
