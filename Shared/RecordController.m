//
//  RecordViewController.m
//  Shared
//
//  Created by Brian Bernberg on 10/26/12.
//  Copyright (c) 2012 BB Consulting. All rights reserved.
//

#import "RecordController.h"
#import "Constants.h"
#import "UIButton+myButton.h"
#import "DDProgressView.h"

#define kMaxRecordingTime 90.0
#define kPlayButtonIVTag 1000

typedef enum PlayStatus {
  playStatusReady,
  playStatusPaused,
  playStatusPlaying
} PlayStatus;

@interface RecordController ()
@property (weak) IBOutlet UIButton *cancelButton;
@property (weak) IBOutlet UIButton *playbackButton;
@property (weak) IBOutlet UIButton *sendButton;
@property (weak) IBOutlet UILabel *recordingLabel;
@property (weak) IBOutlet UILabel *recordingTimeLabel;
@property (weak) IBOutlet UIButton *doneButton;
@property (nonatomic, strong) DDProgressView *progressView;
@property (nonatomic, strong) AVAudioRecorder *recorder;
@property (nonatomic, strong) AVAudioPlayer *player;
@property (nonatomic, strong) NSURL *recordingURL;
@property (nonatomic, assign) BOOL isRecording;
@property (nonatomic, assign) BOOL hasRecording;
@property (nonatomic, assign) PlayStatus playStatus;
@property (strong) NSTimer *recordingTimer;
@property (strong) NSTimer *playTimer;
@end

@implementation RecordController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    // Custom initialization
    NSString *recordingPath = [NSString stringWithFormat:@"%@_%@_%@_recording.wav", [User currentUser].myUserID, [User currentUser].partnerUserID, @([[NSDate date] timeIntervalSince1970])];
    self.recordingURL = [NSURL fileURLWithPath:pathInCachesDirectory(recordingPath)];
    
    NSDictionary *recordingDict = @{AVSampleRateKey : @(12000.0),
                                    AVNumberOfChannelsKey : [NSNumber numberWithInteger:1]
                                    };
    self.recorder = [[AVAudioRecorder alloc] initWithURL:self.recordingURL
                                                settings:recordingDict
                                                   error:nil];
    self.recorder.delegate = self;
    
    self.isRecording = NO;
    self.hasRecording = NO;
    self.playStatus = playStatusReady;
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  // Do any additional setup after loading the view from its nib.
  
  [UIDevice currentDevice].proximityMonitoringEnabled = YES;
  
  self.cancelButton.hidden = YES;
  self.playbackButton.hidden = YES;
  UIImageView *playbackIV = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"play"]];
  playbackIV.userInteractionEnabled = NO;
  playbackIV.frame = CGRectMake(12.0, 8.0, 16.0, 16.0);
  playbackIV.tag = kPlayButtonIVTag;
  [self.playbackButton addSubview:playbackIV];
  
  self.sendButton.hidden = YES;
  
  [self.doneButton customizeSimpleButton];
  [self.sendButton customizeSimpleButton];
  
  
  CGFloat rightMargin = 71.f;
  CGFloat xOrigin = 103.f;
  self.progressView = [[DDProgressView alloc] initWithFrame: CGRectMake(xOrigin, 11.0, self.view.frame.size.width - rightMargin - xOrigin, 0.0f)] ;
  [self.progressView setOuterColor: [UIColor clearColor]];
  [self.progressView setEmptyColor: [UIColor blackColor]];
  [self.progressView setInnerColor: [UIColor whiteColor]];
  self.progressView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  [self.view addSubview: self.progressView];
  
  self.progressView.hidden = YES;
  
  self.view.backgroundColor = [UIColor colorWithRed: (139.0/255.0) green: 0.0 blue: 0.0 alpha:1.0];
  
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [UIApplication sharedApplication].idleTimerDisabled = YES;
  self.recordingTimeLabel.text = @"0:00";
  [self.recorder recordForDuration: kMaxRecordingTime];
  self.recordingTimer = [NSTimer scheduledTimerWithTimeInterval:0.2
                                                         target:self
                                                       selector:@selector(updateRecordingTimeLabel:)
                                                       userInfo:nil
                                                        repeats:YES];
  
}

- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
  [UIApplication sharedApplication].idleTimerDisabled = NO;
}

-(void)dealloc {
  [UIDevice currentDevice].proximityMonitoringEnabled = NO;
  [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:nil];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

#pragma mark IBActions
-(IBAction)doneButtonPressed:(id)sender {
  [self.recorder stop];
  [UIApplication sharedApplication].idleTimerDisabled = NO;
  
}

-(IBAction)cancelButtonPressed:(id)sender {
  if (self.player) {
    [self.player stop];
  }
  
  [self.delegate recordingCancelled];
}

-(IBAction)playbackButtonPressed:(id)sender {
  if (self.playStatus == playStatusReady) {
    self.playStatus = playStatusPlaying;
    [self.player play];
    UIImageView *playbackIV = (UIImageView *)[self.playbackButton viewWithTag:kPlayButtonIVTag];
    playbackIV.image = [UIImage imageNamed:@"pause"];
    [self schedulePlayTimer];
    
  } else if (self.playStatus == playStatusPaused) {
    self.playStatus = playStatusPlaying;
    [self.player play];
    UIImageView *playbackIV = (UIImageView *)[self.playbackButton viewWithTag:kPlayButtonIVTag];
    playbackIV.image = [UIImage imageNamed:@"pause"];
    [self schedulePlayTimer];
  } else {
    [self.playTimer invalidate];
    self.playStatus = playStatusPaused;
    [self.player pause];
    UIImageView *playbackIV = (UIImageView *)[self.playbackButton viewWithTag:kPlayButtonIVTag];
    playbackIV.image = [UIImage imageNamed:@"play"];
  }
  
}

-(IBAction)sendButtonPressed:(id)sender {
  if (self.player) {
    [self.player stop];
  }
  NSString *durationString = [self timeFormatted:self.player.duration];
  [self.delegate recordingComplete: @{
                                      kVoiceMessageURLKey : self.recordingURL,
                                      kVoiceMessageDurationKey : durationString
                                      }];
}

#pragma mark AVAudioRecorder delegate
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
  [self.recordingTimer invalidate];
  self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:self.recordingURL error:nil];
  self.player.delegate = self;
  self.isRecording = NO;
  self.recordingLabel.hidden = YES;
  self.recordingTimeLabel.hidden = YES;
  self.doneButton.hidden = YES;
  self.cancelButton.hidden = NO;
  self.playbackButton.hidden = NO;
  self.progressView.hidden = NO;
  self.sendButton.hidden = NO;
  self.hasRecording = YES;
  self.playStatus = playStatusReady;
  self.progressView.progress = 0.0;
  [UIView animateWithDuration:0.2 animations:^{
    self.view.backgroundColor = [UIColor darkGrayColor];
  }];
  
  NSLog(@"File size = %@", [[NSFileManager defaultManager] attributesOfItemAtPath:self.recordingURL.path error:nil][NSFileSize]);
  
}

#pragma mark AVAudioPlayer delegate
-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
  self.playStatus = playStatusReady;
  UIImageView *playbackIV = (UIImageView *)[self.playbackButton viewWithTag:kPlayButtonIVTag];
  playbackIV.image = [UIImage imageNamed:@"play"];
  self.progressView.progress = 0.0;
}

#pragma mark Timer functions
-(void)updateRecordingTimeLabel:(NSTimer *)timer {
  self.recordingTimeLabel.text = [self timeFormatted:(int)self.recorder.currentTime];
  
}

-(void)schedulePlayTimer {
  self.playTimer = [NSTimer timerWithTimeInterval:0.1
                                           target:self
                                         selector:@selector(updatePlayProgressView:)
                                         userInfo:nil
                                          repeats:YES];
  [[NSRunLoop mainRunLoop] addTimer:self.playTimer forMode:NSRunLoopCommonModes];
}

-(void)updatePlayProgressView:(NSTimer *)timer {
  self.progressView.progress = self.player.currentTime / self.player.duration;
}

#pragma mark utility functions
- (NSString *)timeFormatted:(int)totalSeconds
{
  int seconds = totalSeconds % 60;
  int minutes = (totalSeconds / 60) % 60;
  
  return [NSString stringWithFormat:@"%01d:%02d", minutes, seconds];
}

@end
