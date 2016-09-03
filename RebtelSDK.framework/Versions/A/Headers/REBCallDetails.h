/*
 * Copyright (c) 2012 Rebtel Networks AB. All rights reserved.
 *
 * See LICENSE file for license terms and information.
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#pragma mark - Call End Cause

typedef enum REBCallEndCause {
    REBCallEndCauseNone = 0,
    REBCallEndCauseTimeout = 1,
    REBCallEndCauseDenied = 2,
    REBCallEndCauseNoAnswer = 3,
    REBCallEndCauseError = 4,
    REBCallEndCauseHungUp = 5,
    REBCallEndCauseCanceled = 6,
    REBCallEndCauseOtherBranchJoined = 7
} REBCallEndCause;

#pragma mark - REBCallDetails

/**
 * The REBCallDetails holds metadata about a call (REBCall).
 */
@protocol REBCallDetails <NSObject>

/**
 * The start time of the call.
 *
 * Before the call has started, the value of the startTime property is `nil`.
 */
@property (nonatomic, readonly, strong) NSDate *startTime;

/**
 * The time at which the call was established, if it reached established state.
 *
 * Before the call has reached established state, the value of the establishedTime property is `nil`.
 */
@property (nonatomic, readonly, strong) NSDate *establishedTime;

/**
 * The end time of the call.
 *
 * Before the call has ended, the value of the endTime property is `nil`.
 */
@property (nonatomic, readonly, strong) NSDate *endTime;

/**
 * Holds the cause of why a call ended, after it has ended. It may be one
 * of the following:
 *
 *  - `REBCallEndCauseNone`
 *  - `REBCallEndCauseTimeout`
 *  - `REBCallEndCauseDenied`
 *  - `REBCallEndCauseNoAnswer`
 *  - `REBCallEndCauseError`
 *  - `REBCallEndCauseHungUp`
 *  - `REBCallEndCauseCanceled`
 *  - `REBCallEndCauseOtherBranchJoined`
 *
 * If the call has not ended yet, the value is `REBCallEndCauseNone`.
 */
@property (nonatomic, readonly) REBCallEndCause endCause;

/**
 * If the end cause is error, then this property contains an error object
 * that describes the error.
 *
 * If the call has not ended yet or if the end cause is not an error,
 * the value of this property is `nil`.
 */
@property (nonatomic, readonly, strong) NSError *error;

/**
 * The application state when the call was received.
 */
@property (nonatomic, readonly) UIApplicationState applicationStateWhenReceived;

@end
