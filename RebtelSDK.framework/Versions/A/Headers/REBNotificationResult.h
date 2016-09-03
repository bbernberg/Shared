/*
 * Copyright (c) 2012 Rebtel Networks AB. All rights reserved.
 *
 * See LICENSE file for license terms and information.
 */

#import <Foundation/Foundation.h>

/**
 * REBNotificationResult is used to indicate the result of calling the methods
 * -[REBClient relayLocalNotification:] and 
 * -[REBClient relayRemotePushNotificationPayload:] .
 * 
 * It can be especially useful for scenarios which will not result in 
 * the REBClientDelegate receiving any callback for an incomnig call as a result
 * of calling the methods mentioned above. One such scenario is when a user
 * have been attempted to be reached, but not acted on the notification directly.
 * In that case, the notification result object can indicate that the 
 * notification is too old (`isTimedOut`), and also contains the `remoteUserId` which can be 
 * used for display purposes.
 *
 */

@protocol REBNotificationResult <NSObject>

/** Indicates whether the notification is valid or not. */
@property (nonatomic, readonly, assign) BOOL isValid;

/** Indicates whether the notification has timed out or not. */
@property (nonatomic, readonly, assign) BOOL isTimedOut;

/** Id of the user from which the call represented by the notification
 originated.
 */
@property (nonatomic, readonly, copy) NSString *remoteUserId;

@end
