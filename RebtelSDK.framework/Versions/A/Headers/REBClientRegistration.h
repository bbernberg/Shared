/*
 * Copyright (c) 2012 Rebtel Networks AB. All rights reserved.
 *
 * See LICENSE file for license terms and information.
 */

#import <Foundation/Foundation.h>


/**
 * Callback object to be used to proceed in user registration process when
 * registration credentials for the user in question have been obtained.
 */
@protocol REBClientRegistration <NSObject>

/**
 * Proceed with user registration by providing a valid signature and sequence
 * which will be used in signing the registration request.
 *
 * @param signature Signature which have been obtained for a specific
 *                  user and sequence.
 *
 * @param sequence  Sequence identifier for the correspoding signature
 *
 *
 * @see REBClient, REBClientDelegate
 *
 */
- (void)registerWithSignature:(NSString *)signature
                     sequence:(uint64_t)sequence;

/**
 * If the application fails to provide a signature and sequence, it must
 * notify the Rebtel client via this method.
 *
 * Calling this method will have the effect that the client delegate will 
 * receive a call to -[REBClientDelegate clientDidFail:error:].
 *
 * @param error Error that prevented obtaining a registration sequence and
 *              signature.
 *
 * @see REBClient, REBClientDelegate
 *
 */
- (void)registerDidFail:(NSError *)error;

@end
