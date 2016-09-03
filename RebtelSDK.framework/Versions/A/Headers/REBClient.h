/*
 * Copyright (c) 2012 Rebtel Networks AB. All rights reserved.
 *
 * See LICENSE file for license terms and information.
 */

#import <Foundation/Foundation.h>

@protocol REBClientDelegate;
@protocol REBCall;
@protocol REBAudioController;
@protocol REBClientRegistration;
@protocol REBNotificationResult;
@class REBLocalNotification;
@class UILocalNotification;

#pragma mark - Log Severity

typedef enum REBLogSeverity {
    REBLogSeverityTrace = 0,
    REBLogSeverityInfo,
    REBLogSeverityWarn,
    REBLogSeverityCritical
} REBLogSeverity;

#pragma mark - REBClient

/**
 * The REBClient is used to initiate and receive calls.
 *
 * ### User Identification
 *
 * The user IDs that are used to identify users when making or
 * receiving calls are application specific. If the app already
 * has a scheme for user IDs (email addresses, phone numbers,
 * customer numbers, etc.), the same IDs could be used for the
 * purpose of calling, as well.
 *
 * ### Example
 *
 * 	// Instantiate a client object using the client factory.
 * 	id<REBClient> client = [RebtelSDK clientWithApplicationKey:@"<APPKEY>"
 * 	                                         applicationSecret:@"<APPSECRET>"
 * 	                                           environmentHost:@"clientapi.rebtel.com"
 * 	                                                    userId:@"<USERID>"];
 *
 * 	// Optionally specify additional client capabilities
 * 	[client setSupportActiveConnectionInBackground:YES]; // (optional)
 * 	[client setSupportPushNotifications:YES]; // (optional)
 *
 * 	// Set your delegate object
 * 	client.delegate = ... ;
 *
 * 	// Start the client when the calling functionality is needed.
 * 	[client start];
 *
 * 	// If incoming calls are expected, start listening for them.
 * 	[client startListeningOnActiveConnection];
 *
 * 	// Place outgoing call.
 * 	id<REBCall> call = [client callUserWithId:@"<REMOTE_USERID>"];
 *
 * 	// ...
 *
 * 	// Hangup call (the call object is provided to the delegate).
 * 	[call hangup];
 *
 * 	// Stop listening for incoming calls, if client is listening for them.
 * 	[client stopListeningOnActiveConnection];
 *
 * 	// Stop the client when the calling functionality is no longer needed.
 * 	[client stop];
 */
@protocol REBClient <NSObject>

/**
 * The object that acts as the delegate of the receiving client.
 *
 * The delegate object handles call state change events and must
 * adopt the REBClientDelegate protocol.
 *
 * @see REBClientDelegate
 */
@property (nonatomic, weak) id<REBClientDelegate> delegate;

/**
 * ID of the local user
 */
@property (nonatomic, readonly, copy) NSString *userId;

/**
 * Start client to enable the calling functionality.
 *
 * The client delegate should be set before calling the start method to
 * guarantee that delegate callbacks are received as expected.
 *
 */
- (void)start;

/**
 * Stop client when the calling functionality is no longer needed.
 * 
 * It is generally recommended to initiate the Rebtel client, start it, but not 
 * stop it, during the lifetime of the running application. If incoming calls 
 * are not desired for a limited period of time or similar scenarios, it is 
 * instead recommended to only stop listening for incoming calls via the method
 * (-[REBClient stopListeningOnActiveConnection]). 
 * This is simply because initializing and starting the client is relatively 
 * resource intensive both in terms of CPU, as well as there is potentially
 * network requests involved in stopping and re-starting the client.
 *
 * If desired to dispose the client, it is required to explicitly stop the 
 * client to relinquish certain resources. This method should always be called 
 * before the application code releases its last reference to the client.
 *
 */
- (void)stop;

/**
 *
 * @return A boolean value indicating whether the client has successfully
 *         started and is ready to perform calling functionality.
 */
- (BOOL)isStarted;

/** 
 * This will establish an active keep-alive connection as a signaling channel
 * for receiving incoming calls. 
 *
 * The active connection can be specified to be kept open even if the 
 * application leaves foreground, see
 * -[REBClient setSupportActiveConnectionInBackground:]).
 *
 */
- (void)startListeningOnActiveConnection;

/** 
 * This will close the connection that is kept alive and used as signaling 
 * channel for receiving incoming calls. This method should be used when the 
 * application no longer intends to utilize the long-lived connection for
 * receiving incoming calls.
 *
 * If the intention is to completely turn off incoming calls and the application
 * is also using push notifications as a method of receiving
 * incoming calls, then the application should also unregister previously 
 * registered push notification data via the method 
 * -[REBClient unregisterPushNotificationData].
 *
 */
- (void)stopListeningOnActiveConnection;

/**
 * Specify whether to keep the active connection open if the application
 * leaves foreground.
 *
 * If specified to be supported, the active connection which is used for 
 * receiving incoming calls will be kept open even if the application leaves 
 * foreground. Enabling this also requires that 'voip' is specified for 
 * UIBackgroundModes in the application's Info.plist.
 *
 * If specified to not be supported, the application will not be running in the
 * background, and the active connection which is used for receiving incoming 
 * calls will be closed once the application leaves foreground. 
 * (Though it will be re-opened once the application returns to foreground).
 * If not supported, the application will be required to rely on push 
 * notifications to receive incoming calls if the application leaves foreground.
 *
 * If specified to be supported, the client's delegate is required to implement 
 * additional parts of the REBClientDelegate protocol. It is required to 
 * implement -[REBClientDelegate client:localNotificationForIncomingCallFromUser:]
 *
 * This method should be called before calling -[REBClient start].
 *
 * @param supported Specifies whether the active connection should be kept open
 *                  even if the application leaves foreground.
 *
 */
- (void)setSupportActiveConnectionInBackground:(BOOL)supported;

/**
 * Call the user with the given id.
 *
 * @param userId The application specific id of the user to call.
 * 
 * @exception NSInternalInconsistencyException Throws exception if attempting
 *                                             to initiate a call before the
 *                                             REBClient is started.
 *                                             @see -[REBClientDelegate clientDidStart:].
 */
- (id<REBCall>)callUserWithId:(NSString *)userId;

/**
 * Specify whether this device should receive incoming calls via push
 * notifications.
 *
 * Method should be called before calling -[REBClient start].
 *
 * @param supported Enable or disable support for push notifications.
 *
 * @see -[REBClient registerPushNotificationData:]
 * @see -[REBClient unregisterPushNotificationData];
 * @see -[REBClient relayRemotePushNotificationPayload:];
 *
 */
- (void)setSupportPushNotifications:(BOOL)supported;

/**
 * Method used to forward the Rebtel-specific payload extracted from an incoming
 * Apple Push Notification.
 *
 * @return Value indicating initial inspection of push notification payload.
 *
 * @param payload Rebtel-specific payload which was transferred with an
 *        Apple Push Notification.
 *
 * @see REBNotificationResult
 */
- (id<REBNotificationResult>)relayRemotePushNotificationPayload:(NSString *)payload;

/**
 * Method used to handle a local notification which has been scheduled and 
 * taken action upon by the application user.
 *
 * @return Value indicating outcome of the attempt to handle the notification.
 *
 * @param notification UILocalNotification
 *
 * @exception NSInternalInconsistencyException Throws exception if called before 
 *            client startup has completed.
 *            A case when the client might not be started yet is if the 
 *            application user takes action on an local notification that is not 
 *            relevant any more. E.g. the user ignored the notification when it 
 *            was first presented, then quit the app, and the notification was 
 *            left in Notification Center and was taken action upon at a later
 *            time.
 *            
 *            -[REBClient isStarted] may be used to guard against calling this
 *            method at inappropriate times.
 *
 * @see -[REBClient isStarted] 
 * @see REBNotificationResult
 *
 */
- (id<REBNotificationResult>)relayLocalNotification:(UILocalNotification *)notification;

/**
 * Register device-specific data that can be used to identify this device
 * and tie it to an Apple Push Notification device token. 
 *
 * @param pushNotificationData Device-specific data that can be used to
 *                             tie a device to a specific Apple Push
 *                             Notification device token
 *
 * The `pushNotificationData` is what will be passed back in
 * -[REBCallDelegate call:shouldSendPushNotificationPayload:to:]
 * in the caller's application, unless the application on the destination device
 * (the device on which this method is called) is not running in the background, 
 * and is required to woken up it via a Apple Push Notification.
 *
 * See [UIApplication registerForRemoteNotificationTypes:] on how to obtain
 * the current device token.
 *
 * @see REBCallDelegate
 */
- (void)registerPushNotificationData:(NSData *)pushNotificationData;

/**
 * Unregister previously registered device-specific data that is used to
 * identify this device and tie it to an Apple Push Notification device token.
 *
 * If it is unwanted that the user receives further remote push notifications
 * for Rebtel calls, this method should be used to unregister the push data.
 */
- (void)unregisterPushNotificationData;

/**
 * Retrieve the interface for the audio controller, which provides access
 * to various audio related functionality, such as muting the microphone,
 * enabling the speaker, and playing ring tones.
 */
- (id<REBAudioController>)audioController;

@end


/**
 * The delegate of a REBClient object must adopt the REBClientDelegate
 * protocol. The required methods handle client state changes and the
 * optional log method allows the delegate to log messages from the
 * underlying calling functionality.
 *
 * When an incoming call has been received,
 * [REBClientDelegate client:didReceiveIncomingCall:] is called.
 * The delegate of the incoming call object should be set at this time.
 */
@protocol REBClientDelegate <NSObject>

/**
 * Tells the delegate that the client started the calling functionality.
 *
 * @param client The client informing the delegate that the calling
 *               functionality started successfully.
 *
 * @see REBClient
 */
- (void)clientDidStart:(id<REBClient>)client;

/**
 * Tells the delegate that the client stopped the calling functionality.
 *
 * @param client The client informing the delegate that the calling
 *               functionality was stopped.
 *
 * @see REBClient
 */
- (void)clientDidStop:(id<REBClient>)client;

/**
 * Tells the delegate that an incoming call has been received.
 *
 * The call has entered the `REBCallStateSettingUp` state.
 *
 * @param client The client informing the delegate that an incoming call
 *               was received. The delegate of the incoming call object
 *               should be set by the implementation of this method.
 *
 * @param call The incoming call.
 *
 * @see REBClient, REBCall, REBCallDelegate
 */
- (void)client:(id<REBClient>)client didReceiveIncomingCall:(id<REBCall>)call;

/**
 * Tells the delegate that a client failure occurred.
 *
 * @param client The client informing the delegate that it
 *               failed to start or start listening.
 *
 * @param error Error object that describes the problem.
 *
 * @see REBClient
 */
- (void)clientDidFail:(id<REBClient>)client
                error:(NSError *)error;

@optional

/**
 * Tells the delegate that it is required to provide additional registration
 * credentials.
 *
 * @param client The client informing the delegate that it requires
 *               additional registration details.
 *
 * @param registrationCallback The callback object that is to be called
 *               when registration credentials have been fetched.
 *
 * @see REBClientRegistration
 * @see REBClient
 */
- (void)client:(id<REBClient>)client
requiresRegistrationCredentials:(id<REBClientRegistration>)registrationCallback;

/**
 * Method for providing presentation related data for a local notification used
 * to notify the application user of an incoming call.
 *
 * @return REBLocalNotification The delegate is responsible for composing a
 *                              REBLocalNotification which can be used to
 *                              present an incoming call.
 *
 * The return value will be used by the REBClient to schedule a
 * 'Local Push Notification', i.e. a UILocalNotification.
 * That UILocalNotification, when triggered and taken action upon by the user,
 * is supposed to be used in conjunction with 
 * -[REBClient relayLocalNotification:].
 *
 * This method is declared as optional, but it is still required to implement
 * if support for using an active connection in background is enabled, see
 * -[REBClient setSupportActiveConnectionInBackground:].
 *
 * @param client The client requesting a local notification
 *
 * @param remoteUserId user id for the remote user that is calling
 *
 * @see REBLocalNotification
 * @see REBClient
 */
- (REBLocalNotification *)client:(id<REBClient>)client
    localNotificationForIncomingCallFromUser:(NSString *)remoteUserId;

/**
 * The delegate object can choose to subscribe to log messages from
 * the underlying calling functionality by implementing this method.
 *
 * The easiest way to log the messages is to simply write them to
 * the device console using NSLog:
 *
 *     `NSLog(@"[%@] %u %@", timestamp, severity, message);`
 *
 * *Caution:* Only log messages with severity level `REBLogSeverityWarn`
 * or higher to the console in release builds, to avoid flooding the
 * device console with debugging messages.
 *
 * @param client The client that the log messages are coming from.
 *
 * @param message The message that is being logged.
 *
 * @param area The area that the log message relates to.
 *
 * @param severity The severity level of the log message. It may be one of
 *                 the following:
 *
 *                  - `REBLogSeverityTrace`
 *                  - `REBLogSeverityInfo`
 *                  - `REBLogSeverityWarn`
 *                  - `REBLogSeverityCritical`
 *
 * @param timestamp The time when the message was logged.
 *
 * @see REBClient
 */
- (void)client:(id<REBClient>)client
    logMessage:(NSString *)message
          area:(NSString *)area
      severity:(REBLogSeverity)severity
     timestamp:(NSDate *)timestamp;

@end
