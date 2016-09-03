/*
 * Copyright (c) 2012 Rebtel Networks AB. All rights reserved.
 *
 * See LICENSE file for license terms and information.
 */

#import <Foundation/Foundation.h>

@protocol REBAudioControllerDelegate;

/**
 * The REBSoundIntent constants should be used to indicate an intent when 
 * playing a sound using the method
 * -[REBAudioController startPlayingSoundFile:intent:loop:].
 * 
 */
typedef enum REBSoundIntent {
    /**
     * The sound is intended to be played as a ringtone when an incoming
     * call is received.
     */
    REBSoundIntentRingtone = 0,
    
    /**
     * The sound is intended to be played as a progress tone on the caller
     * side while waiting for the remote user to answer.
     */
    REBSoundIntentRinging,
    
    /**
     * The sound is intended to be played as a busy tone after the call
     * has ended with a REBCallEndCauseDenied end cause.
     */
    REBSoundIntentBusy,
    
    /**
     * The sound is intended to be played as a failure tone after the call
     * has ended with a REBCallEndCauseError or REBCallEndCauseTimeout
     * end cause.
     */
    REBSoundIntentFailed
} REBSoundIntent;

#pragma mark - REBAudioController

/**
 * The REBAudioController provides methods for controlling audio related
 * functionality, e.g. enabling the speaker, muting the microphone, and
 * playing sound files.
 *
 * ### Playing Sound Files
 *
 * The audio controller provides a convenience method
 * (startPlayingSoundFile:intent:loop:) for playing sounds
 * that are related to a call, such as ringtones and busy tones.
 *
 * ### Example
 *
 * 	id<REBAudioController> audio = [client audioController];
 * 	NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"ringtone" 
 * 	                                                      ofType:@"wav"];
 *
 * 	[audio startPlayingSoundFile:soundPath intent:REBSoundIntentRingtone 
 * 	                                         loop:YES];
 * 
 *
 * Applications that prefer to use their own code for playing sounds are free
 * to do so, but they should follow a few guidelines related to audio
 * session categories and audio session activation/deactivation (see
 * Rebtel SDK User Guide for details).
 *
 * #### Sound File Format
 *
 *  The sound file must be a mono (1 channel), 16-bit, uncompressed (PCM)
 * .wav file with a sample rate of 8kHz, 16kHz, or 32kHz.
 *
 * #### Intent
 *
 * When the convenience method for playing sound is called, an intent
 * parameter must be specified. Depending on the intent, different behaviors
 * will be used in order to handle audio session categories and activation
 * correctly.
 *
 * The following intent definitions are available:
 *
 * - **`REBSoundIntentRingtone`** 
 * 
 * The sound is intended to be played as a ringtone when an incoming call
 * is received.
 *
 * This intent should be used when playing a ringtone sound from within the
 * [REBClientDelegate client:didReceiveIncomingCall:] method. The audio
 * session *will not* be deactivated when playback of the sound is stopped.
 * 
 * The `AVAudioSessionCategorySoloAmbient` category is set, as it respects
 * the state of the hardware silent switch.
 *
 * - **`REBSoundIntentRinging`**
 * 
 * The sound is intended to be played as a progress tone on the caller side
 * while waiting for the remote user to answer.
 *
 * This intent should be used when playing a progress tone sound from within
 * the [REBCallDelegate callReceivedOnRemoteEnd:] method. The audio session
 * *will not* be deactivated when playback of the sound is stopped.
 *
 * The `AVAudioSessionCategoryPlayAndRecord` category is set, partly because
 * it defaults to playing audio in the handset earpiece, but also because
 * this is the category that will be used in call.
 *
 * - **`REBSoundIntentBusy`**
 *
 * The sound is intended to be played as a busy tone after the call has ended
 * with a `REBCallEndCauseDenied` end cause.
 *
 * This intent should be used when playing a busy tone sound from within
 * the [REBCallDelegate callEnded:] method. The audio session *will* be
 * deactivated when playback of the sound is stopped.
 *
 * The `AVAudioSessionCategoryPlayAndRecord` category is set, partly because
 * it defaults to playing audio in the handset earpiece.
 *
 * - **`REBSoundIntentFailed`**
 *
 * The sound is intended to be played as a failure tone after the call has
 * ended with a `REBCallCauseError` or `REBCallEndCauseTimeout` end cause.
 *
 * This intent should be used when playing a failure tone sound from within
 * the [REBCallDelegate callEnded:] method. The audio session *will* be
 * deactivated when playback of the sound is stopped.
 *
 * The `AVAudioSessionCategoryPlayAndRecord` category is set, partly because
 * it defaults to playing audio in the handset earpiece, but also because
 * this is the category that was used in the call.
 */
@protocol REBAudioController <NSObject>

/**
 * The object that acts as the delegate of the audio controller.
 *
 * The delegate object handles audio related state changes.
 *
 * @see REBAudioControllerDelegate
 */
@property (nonatomic, weak) id<REBAudioControllerDelegate> delegate;

/**
 * Mute the microphone.
 */
- (void)mute;

/**
 * Unmute the microphone.
 */
- (void)unmute;

/**
 * Route the call audio through the speaker.
 */
- (void)enableSpeaker;

/**
 * Route the call audio through the handset earpiece.
 */
- (void)disableSpeaker;

/**
 * Play a sound file, for the purpose of playing ringtones, etc.
 *
 * This is a simple convenience method for playing sounds associated with
 * a call, such as ringtones. It can only play one sound file at a time.
 *
 * For advanced audio, apps that use the SDK should implement their own
 * methods for playing sounds.
 *
 * Regardless of whether a sound is looping or not, a corresponding call
 * to the stopPlayingSoundFile method must be done at some point after each
 * invocation of this method.
 *
 * The sound file must be a mono (1 channel), 16-bit, uncompressed (PCM)
 * .wav file with a sample rate of 8kHz, 16kHz, or 32kHz.
 *
 * @param path Full path for the sound file to play.
 *
 * @param intent Specifies what the sound is intended for, to allow
 *               appropriate audio session settings to be applied.
 *
 * @param loop Specifies whether the sound should loop or not.
 *
 * @exception NSInvalidArgumentException Throws exception if no file exists
 *                                       at the given path.
 *
 */
- (void)startPlayingSoundFile:(NSString *)path
                       intent:(REBSoundIntent)intent
                         loop:(BOOL)loop;

/**
 * Stop playing the sound file.
 */
- (void)stopPlayingSoundFile;

@end


/**
 * The delegate of a REBAudioController object must adopt the
 * REBAudioControllerDelegate protocol. The methods handle audio
 * related state changes.
 */
@protocol REBAudioControllerDelegate <NSObject>
@optional

/**
 * Notifies the delegate that the microphone was muted.
 *
 * @param audioController The audio controller associated with this delegate.
 *
 * @see REBAudioController
 */
- (void)audioControllerMuted:(id<REBAudioController>)audioController;

/**
 * Notifies the delegate that the microphone was unmuted.
 *
 * @param audioController The audio controller associated with this delegate.
 *
 * @see REBAudioController
 */
- (void)audioControllerUnmuted:(id<REBAudioController>)audioController;

/**
 * Notifies the delegate that the speaker was enabled.
 *
 * @param audioController The audio controller associated with this delegate.
 *
 * @see REBAudioController
 */
- (void)audioControllerSpeakerEnabled:(id<REBAudioController>)audioController;

/**
 * Notifies the delegate that the speaker was disabled.
 *
 * @param audioController The audio controller associated with this delegate.
 *
 * @see REBAudioController
 */
- (void)audioControllerSpeakerDisabled:(id<REBAudioController>)audioController;

@end
