/*
 * Copyright (c) 2012 Rebtel Networks AB. All rights reserved.
 *
 * See LICENSE file for license terms and information.
 */

#import <Foundation/Foundation.h>

#import "REBClient.h"
#import "REBClientRegistration.h"
#import "REBCall.h"
#import "REBCallDetails.h"
#import "REBError.h"
#import "REBLocalNotification.h"
#import "REBUILocalNotification+Rebtel.h"
#import "REBNotificationResult.h"
#import "REBAudioController.h"

/**
 * The RebtelSDK is used to instantiate a REBClient.
 *
 * This is the starting point for an app that wishes to use this
 * library.
 */
@interface RebtelSDK : NSObject

/**
 * Instantiate a new client.
 *
 * If the client is initiated with an application key, but no application
 * secret, starting the client the first time will require additional
 * authorization credentials as part of registering the user.
 * It will therefore be required of the REBClientDelegate to implement
 * -[REBClientDelegate client:requiresRegistrationCredentials:].
 *
 * @return The newly instantiated client.
 *
 * @param applicationKey Application key identifying the application.
 *
 * @param environmentHost Host for base URL for the Rebtel API environment
 *                        to be used. E.g. 'sdksandbox.rebtel.com'
 *
 *
 * @param userId ID of the local user
 *
 * @see REBClient
 * @see REBClientRegistration
 */

+ (id<REBClient>)clientWithApplicationKey:(NSString *)applicationKey
                          environmentHost:(NSString *)environmentHost
                                   userId:(NSString *)userId;

/**
 * Instantiate a new client.
 *
 * @return The newly instantiated client.
 *
 * This method should be used if user-registration and authorization with Rebtel
 * is to be handled completely by the app (without additional involvement
 * of a backend-service providing additional credentials to the application.)
 *
 * @param applicationKey Application key identifying the application.
 *
 * @param applicationSecret Application secret bound to application key.
 *
 * @param environmentHost Host for base URL for the Rebtel API environment
 *                        to be used. E.g 'sdksandbox.rebtel.com'
 *
 *
 * @param userId ID of the local user
 *
 * @see REBClient
 */

+ (id<REBClient>)clientWithApplicationKey:(NSString *)applicationKey
                        applicationSecret:(NSString *)applicationSecret
                          environmentHost:(NSString *)environmentHost
                                   userId:(NSString *)userId;

/**
 * Returns the Rebtel SDK version.
 */
+ (NSString *)version;

@end
