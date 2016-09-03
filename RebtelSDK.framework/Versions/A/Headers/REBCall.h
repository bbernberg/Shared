/*
 * Copyright (c) 2012 Rebtel Networks AB. All rights reserved.
 *
 * See LICENSE file for license terms and information.
 */

#import <Foundation/Foundation.h>

@protocol REBCallDelegate;
@protocol REBCallDetails;

#pragma mark - Call State

typedef enum REBCallState {
    REBCallStateSettingUp = 0,
    REBCallStateAnswering,
    REBCallStateRinging,
    REBCallStateEstablished,
    REBCallStateEnded
} REBCallState;

#pragma mark - Call Direction

typedef enum REBCallDirection
{
    REBCallDirectionIncoming = 0,
    REBCallDirectionOutgoing
} REBCallDirection;


#pragma mark - REBCall

/**
 * The REBCall represents a call.
 */
@protocol REBCall <NSObject>

/**
 * The object that acts as the delegate of the call.
 *
 * The delegate object handles call state change events and must
 * adopt the REBCallDelegate protocol.
 *
 * @see REBCallDelegate
 */
@property (nonatomic, weak) id<REBCallDelegate> delegate;

/** String that is used as an identifier for this particular call. */
@property (nonatomic, readonly, copy) NSString *callId;

/** The id of the remote participant in the call. */
@property (nonatomic, readonly, copy) NSString *remoteUserId;

/**
 * Metadata about a call, such as start time.
 *
 * When a call has ended, the details object contains information
 * about the reason the call ended and error information if the
 * call ended unexpectedly.
 *
 * @see REBCallDetails
 */
@property (nonatomic, readonly, strong) id<REBCallDetails> details;

/**
 * The state the call is currently in. It may be one of the following:
 *
 *  - `REBCallStateSettingUp`
 *  - `REBCallStateAnswering`
 *  - `REBCallStateRinging`
 *  - `REBCallStateEstablished`
 *  - `REBCallStateEnded`
 *
 * Initially, the call will be in the `REBCallStateSettingUp` state.
 */
@property (nonatomic, readonly, assign) REBCallState state;

/**
 * The direction of the call. It may be one of the following:
 *
 *  - `REBCallDirectionIncoming`
 *  - `REBCallDirectionOutgoing`
 *
 */
@property (nonatomic, readonly, assign) REBCallDirection direction;

/**
 * The user data property may be used to associate an arbitrary
 * contextual object with a particular instance of a call.
 */
@property (nonatomic, strong) id userInfo;

/** Answer an incoming call. */
- (void)answer;

/**
 * Ends the call, regardless of what state it is in. If the call is
 * an incoming call that has not yet been answered, the call will
 * be reported as denied to the caller.
 */
- (void)hangup;

@end


#pragma mark - REBCallDelegate

/**
 * The delegate of a REBCall object must adopt the REBCallDelegate
 * protocol. The required methods handle call state changes.
 *
 * ### Call State Progression
 *
 * For a complete outgoing call, the delegate methods will be called
 * in the following order:
 *
 *  - `callReceivedOnRemoteEnd:`
 *  - `callEstablished:`
 *  - `callEnded:`
 *
 * For a complete incoming call, the delegate methods will be called
 * in the following order, after the client delegate method
 * `[REBClientDelegate client:didReceiveIncomingCall:]` has been called:
 *
 *  - `callAnswered:`
 *  - `callEstablished:`
 *  - `callEnded:`
 */
@protocol REBCallDelegate <NSObject>

@required

/**
 * Tells the delegate that the call ended.
 *
 * The call has entered the `REBCallStateEnded` state.
 *
 * @param call The call that ended.
 *
 * @see REBCall
 */
- (void)callEnded:(id<REBCall>)call;

@optional

/**
 * Tells the delegate that the client on the other end is ringing.
 *
 * The call has entered the `REBCallStateRinging` state.
 *
 * @param call The outgoing call to the client on the other end.
 *
 * @see REBCall
 */
- (void)callReceivedOnRemoteEnd:(id<REBCall>)call;

/**
 * Tells the delegate that the incoming call was answered.
 *
 * The call has entered the `REBCallAnswering` state.
 *
 * @param call The incoming call that was answered.
 *
 * @see REBCall
 */
- (void)callAnswered:(id<REBCall>)call;

/**
 * Tells the delegate that the call was established.
 *
 * The call has entered the `REBCallStateEstablished` state.
 *
 * @param call The call that was established.
 *
 * @see REBCall
 */
- (void)callEstablished:(id<REBCall>)call;

/**
 * Tells the delegate that the callee device can't be reached directly,
 * and it is required to wake up the callee's application with an
 * Apple Push Notification (APN).
 *
 * @param call The call that requires the delegate to send an
 *             Apple Push Notification (APN) to the callee device.
 *
 * @param payload Opaque Rebtel-specific payload that should be sent
 *                with the APN.
 *
 * @param devicePushNotificationData Each entry identififies a certain device
 *                                   that should be requested to be woken up
 *                                   via Apple Push Notification.
 *
 *                                   The actual entries is the data that the
 *                                   callee's application has set with
 *                                   -[REBClient registerPushNotificationData:].
 *
 * @see REBCall
 * @see REBClient
 */
- (void)call:(id<REBCall>)call shouldSendPushNotificationPayload:(NSString *)payload
                                                              to:(NSArray *)devicePushNotificationData;


@end
