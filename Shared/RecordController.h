//
//  RecordViewController.h
//  Shared
//
//  Created by Brian Bernberg on 10/26/12.
//  Copyright (c) 2012 BB Consulting. All rights reserved.
//

#import "SHViewController.h"
#import <AVFoundation/AVFoundation.h>

@protocol RecordDelegate;

@interface RecordController : SHViewController <AVAudioRecorderDelegate, AVAudioPlayerDelegate>
@property (weak) id<RecordDelegate> delegate;
@end

@protocol RecordDelegate <NSObject>
-(void)recordingComplete:(NSDictionary *)voiceMessageDictionary;
-(void)recordingCancelled;
@end
