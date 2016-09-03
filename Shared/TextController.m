//
//  TextController.m
//  Shared
//
//  Created by Brian Bernberg on 4/5/12.
//  Copyright (c) 2012 BB Consulting. All rights reserved.
//

#import "TextController.h"
#import "Constants.h"
#import "TextService.h"
#import "UIButton+myButton.h"
#import "TouchDownGestureRecognizer.h"
#import <QuartzCore/QuartzCore.h>
#import "MyReach.h"
#import <Quartzcore/Quartzcore.h>
#import "PhotoDetailController.h"
#import "CLImageEditor.h"
#import "RecordController.h"
#import "DDProgressView.h"
#import "NSString+SHString.h"
#import "SHUtil.h"
#import "NotificationRetriever.h"
#import "SavedMessagesService.h"
#import "SavedMessagesController.h"
#import "SharedActivityIndicator.h"
#import "NSString+SHString.h"
#import "OHAttributedStringAdditions.h"
#import "TTTAttributedLabel.h"
#import <MessageUI/MessageUI.h>
#import "TextCell.h"
#import "TextVoiceMessageCell.h"
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import <MMDrawerController/MMDrawerBarButtonItem.h>
#import <MMDrawerController/UIViewController+MMDrawerController.h>
#import "CSGrowingTextView.h"
#import "GlympseLiteWrapper.h"
#import "GlympseTextCell.h"
#import "GenericWebViewController.h"
#import "UIView+Helpers.h"
@import CoreLocation;

#define kMaxPhotoDimension 480
#define kVoiceMessageCellHeight 86.0f

#define kSpinnerTag 1000

#define kMaxTextviewLines 6

#define kTextCellIdentifier @"textCellIdentifier"
#define kVoiceMessageCellIdentifier @"voiceMessageCellIdentifier"
#define kGlympseTextCellIdentificer @"glympseCellIdentifier"

#define kTableHeaderHeight 60

@interface TextController () <RecordDelegate, SavedMessagesDelegate, TTTAttributedLabelDelegate, MFMailComposeViewControllerDelegate, CSGrowingTextViewDelegate, CLLocationManagerDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet CSGrowingTextView *messageTextView;
@property (nonatomic, weak) IBOutlet UIView *messageBackground;
@property (nonatomic, weak) IBOutlet UIButton *sendButton;
@property (nonatomic, weak) IBOutlet UIButton *addButton;
@property (nonatomic, weak) IBOutlet UIButton *addPhotoButton;
@property (nonatomic, weak) IBOutlet UIButton *addVoiceMessageButton;
@property (nonatomic, weak) IBOutlet UIButton *addSavedMessageButton;
@property (nonatomic, weak) IBOutlet UIButton *addGlympseButton;
@property (nonatomic, weak) IBOutlet UIView *addButtonsBackground;
@property (nonatomic, weak) IBOutlet UILabel *noTextMessagesLabel;

@property (nonatomic, strong) UIBarButtonItem *refreshButton;
@property (nonatomic, strong) UIBarButtonItem *audioRouteButton;

@property (nonatomic, readonly) TextService *textService;
@property (nonatomic, strong) TouchDownGestureRecognizer *hideDeleteGR;
@property (nonatomic, weak) PFObject *textToDelete;
@property (nonatomic, weak) UITableViewCell *cellToDelete;
@property (nonatomic, strong) UITapGestureRecognizer *dismissKeyboardTap;
@property (nonatomic, strong) UISwipeGestureRecognizer *dismissKeyboardSwipe;
@property (nonatomic, strong) UIImage *photoToSend;
@property (nonatomic, strong) UIImage *sentPhoto;
@property (nonatomic, assign) BOOL scrollToBottom;
@property (nonatomic, assign) CGFloat tableViewBottomInset;

@property (nonatomic, assign) BOOL showingAddButtons;
@property (nonatomic, strong) RecordController *recordVC;
@property (nonatomic, strong) AVAudioPlayer *player;
@property (nonatomic, strong) NSIndexPath *playerIP;
@property (nonatomic, strong) NSTimer *playerTimer;
@property (nonatomic, assign) AVAudioSessionPortOverride audioRoute;
@property (nonatomic, assign) BOOL showPushMessage;
@property (nonatomic, strong) NSTimer *refreshTimer;
@property (nonatomic, strong) UIView *blockingView;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) UIView *alertContainer;
@property (nonatomic, strong) UIButton *loadMoreButton;
@property (nonatomic, readonly) SharedActivityIndicator *loadMoreSpinner;
@property (nonatomic, strong) UIView *emptyHeader;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic) BOOL sendingGlympse;
@end

@implementation TextController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    _photoToSend = nil;
    _scrollToBottom = YES;
    _showingAddButtons = NO;
    _showPushMessage = NO;
    
    [self registerForNotifications];
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.backBarButtonItem = backButton;
    
    [[SavedMessagesService instance] retrieveSavedMessages];
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  [[NSUserDefaults standardUserDefaults] setObject:@(SharedControllerTypeText) forKey:kCurrentSharedControllerType];
  [[NSUserDefaults standardUserDefaults] synchronize];

  // Do any additional setup after loading the view from its nib.
  self.navigationItem.title = @"Text";
  self.view.backgroundColor = [SHPalette backgroundColor];
  
  [self initializeButtons];

  [self initializeTableView];
  [self positionAddButtonsBackground];
  [self initializeMessageTextView];
  [self initializeNoMessagesLabel];
  [self initializeAddButtons];
  [self initializeKeyboardGestures];
  [self createAddButtons];
  [self configureAudio];
  [self checkForPushNotificationsEnabled];
 
  [self kickoff];
  
  [self initializeAlertContainer];
 
}

-(void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  [[UIDevice currentDevice] setValue:@(UIInterfaceOrientationPortrait) forKey:@"orientation"];

  [self setRefreshButton];
  self.sendingGlympse = NO;
  
  [self configureMessageTextViewWithAnimationDuration:0];
  [self updateOverlays];
  if (self.scrollToBottom) {
    self.scrollToBottom = NO;
    [self.tableView reloadData];
    [self moveTableViewToBottomWithAnimationDuration:0.0 setAlpha:NO];
  }
  
  if (self.showPushMessage) {
    self.showPushMessage = NO;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:@"Without push notifications enabled, new messages will not appear instantaneously. You can enable push notifications with the Settings app."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      [[kAppDelegate viewControllerForPresentation] presentViewController:alert animated:YES completion:nil];
    });
  }
 
}

- ( void ) viewDidDisappear: ( BOOL ) animated {
  [super viewDidDisappear:animated];
  if ( [self isMovingFromParentViewController] ) {
    [self.player stop];
    self.player = nil;
    [self.playerTimer invalidate];
    [self.refreshTimer invalidate];
    [[NotificationRetriever instance] deleteNotificationsOfType:kTextNotification];
  }
}

-(void)kickoff {
  [self setRefreshButton];
  [self.textService retrieveTextsWithRetrieveAction:RetrieveTextActionAll];
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    [[NotificationRetriever instance] deleteNotificationsOfType:kTextNotification];
  });
}

-(void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark getters/setters
- (TextService *)textService {
  return [TextService sharedInstance];
}

- (NSDateFormatter *)dateFormatter {
  if ( ! _dateFormatter ) {
    _dateFormatter = [[NSDateFormatter alloc] init];
    [_dateFormatter setDateFormat:@"EEE, MMM d h:mma"];
  }
  return _dateFormatter;
}

- (TouchDownGestureRecognizer *)hideDeleteGR {
  if ( ! _hideDeleteGR ) {
    _hideDeleteGR = [[TouchDownGestureRecognizer alloc] initWithTarget:self action:@selector(hideDeleteButton:)];
    _hideDeleteGR.delegate = self;
  }
  return _hideDeleteGR;
}

- (UIButton *)loadMoreButton {
  if ( ! _loadMoreButton ) {
    _loadMoreButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_loadMoreButton setTitle:@"Load Earlier Messages" forState:UIControlStateNormal];
    [_loadMoreButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    _loadMoreButton.titleLabel.font = [UIFont italicSystemFontOfSize:15.0];
    [_loadMoreButton addTarget:self
                        action:@selector(loadEarlierButtonPressed:)
              forControlEvents:UIControlEventTouchUpInside];
    
    _loadMoreButton.frame = CGRectMake(0, 0, self.tableView.frame.size.width, kTableHeaderHeight);
    
    SharedActivityIndicator *spinner = [[SharedActivityIndicator alloc] initWithImage:[UIImage imageNamed:@"Shared_Icon_Gray_Transparent"]];
    spinner.center = _loadMoreButton.center;
    spinner.userInteractionEnabled = NO;
    [spinner stopAnimating];
    spinner.tag = kSpinnerTag;
    [_loadMoreButton addSubview:spinner];
  }
  return _loadMoreButton;
}

- (SharedActivityIndicator *)loadMoreSpinner {
  return (SharedActivityIndicator *)[self.loadMoreButton viewWithTag:kSpinnerTag];
}

- (UIView *)emptyHeader {
  if ( ! _emptyHeader ) {
    _emptyHeader = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, self.tableView.frame.size.width, 10.f)];
    _emptyHeader.backgroundColor = [UIColor clearColor];
  }
  return _emptyHeader;
}

-(UIView *)blockingView {
  if (!_blockingView) {
    _blockingView = [[UIView alloc] initWithFrame:self.view.frame];
    _blockingView.backgroundColor = [UIColor blackColor];
    _blockingView.alpha = 0.6;
  }
  return _blockingView;
}

- (CLLocationManager *)locationManager {
  if ( ! _locationManager ) {
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
  }
  return _locationManager;
}

#pragma mark initial config methods
-(void)registerForNotifications {
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAllTextsReceived:) name:kAllTextsReceivedNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleReceiveTextError) name:kReceiveTextErrorNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleInitialSendText:) name:kInitialSendTextNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSendTextSuccess:) name:kSendTextSuccessNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleInitialResendText) name:kInitialResendTextNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleResendTextSuccess) name:kResendTextSuccessNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSendTextError) name:kSendTextErrorNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSendNetworkError) name:kSendNetworkErrorNotification object:nil];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDeleteTextSuccess:) name:kDeleteTextSuccessNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDeleteTextError) name:kDeleteTextErrorNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDismissPhotoDetail) name:kDismissPhotoDetailViewNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:UIApplicationDidBecomeActiveNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAudioSessionRouteChanged:) name:AVAudioSessionRouteChangeNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(reloadData)
                                               name:kUserDataFetchedNotification
                                             object:nil];
  
}

- (void)initializeTableView {
  self.tableView.backgroundColor = [SHPalette backgroundColor];
  self.tableViewBottomInset = self.messageBackground.frame.size.height;
  self.tableView.contentInset = UIEdgeInsetsMake(64.0,
                                                 self.tableView.contentInset.left, self.tableView.contentInset.bottom, self.tableView.contentInset.right);
  if (self.textService.texts.count > 0) {
    self.tableView.alpha = 1.0;
  } else {
    self.tableView.alpha = 0.0;
  }
  
  self.tableView.scrollsToTop = YES;
 
  self.tableView.tableHeaderView = (self.textService.texts.count >= kTextsPerPage) ? self.loadMoreButton : self.emptyHeader;
  
}

- (void)initializeMessageTextView {
  self.messageTextView.delegate = self;
  self.messageTextView.enablesNewlineCharacter = YES;
  self.messageTextView.internalTextView.font = [kAppDelegate globalFontWithSize:18.0];
  self.messageTextView.layer.masksToBounds = YES;
  self.messageTextView.placeholderLabel.text = @"Message";
  self.messageTextView.placeholderLabel.font = self.messageTextView.internalTextView.font;
  self.messageTextView.placeholderLabel.textColor = [UIColor lightGrayColor];
  
  self.messageBackground.clipsToBounds = NO;  
}

- (void)initializeKeyboardGestures {
  self.dismissKeyboardTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
  self.dismissKeyboardTap.delegate = self;
  
  self.dismissKeyboardSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
  self.dismissKeyboardSwipe.direction = UISwipeGestureRecognizerDirectionDown;
  self.dismissKeyboardSwipe.delegate = self;
}

- (void)initializeButtons {
  self.navigationItem.leftBarButtonItem = [[MMDrawerBarButtonItem alloc] initWithTarget:self action:@selector(drawerButtonPressed)];
  
  self.audioRouteButton = [SHUtil barButtonItemWithTarget:self
                                                   action:@selector(audioRouteButtonPressed:)
                                                    image:[UIImage imageNamed:@"speaker_white"]];
  
  self.audioRouteButton.customView.tintColor = [SHPalette darkRedColor];
  
  [self.sendButton customizeSimpleButton];
  
}

- (void)initializeNoMessagesLabel {
  CGRect frame = self.noTextMessagesLabel.frame;
  frame.origin.y = (self.view.frame.size.height - frame.size.height) / 2.0;
  self.noTextMessagesLabel.frame = frame;
}

- (void)configureAudio {
  // Audio routing
  self.audioRoute = kAudioSessionOverrideAudioRoute_Speaker;
  
  if ([self headsetPluggedIn]) {
    self.audioRouteButton.enabled = NO;
  }
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [[AVAudioSession sharedInstance] overrideOutputAudioPort:self.audioRoute error:nil];
  });
  
}

- (void)checkForPushNotificationsEnabled {
  
  if ( ![[UIApplication sharedApplication] isRegisteredForRemoteNotifications] ) {
    NSString *key = [NSString stringWithFormat:@"%@%@", kTextPushMessageShownKey, [User currentUser].myUserID];
    if ( ! [[NSUserDefaults standardUserDefaults] stringForKey:key] ) {
      [[NSUserDefaults standardUserDefaults] setBool:YES forKey:key];
      [[NSUserDefaults standardUserDefaults] synchronize];
      self.showPushMessage = YES;
    }
    
    self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:300
                                                         target:self
                                                       selector:@selector(timerRefresh)
                                                       userInfo:nil
                                                        repeats:YES];
  }
}

- (void)initializeAlertContainer {
  self.alertContainer = [[UIView alloc] initWithFrame: CGRectMake(0.f,
                                                                  self.tableView.contentInset.top,
                                                                  self.view.frame.size.width,
                                                                  self.view.frame.size.height - self.tableView.contentInset.top)];
  self.alertContainer.backgroundColor = [UIColor clearColor];
  self.alertContainer.userInteractionEnabled = NO;
  self.alertContainer.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
  [self.view addSubview:self.alertContainer];  
}

# pragma mark table view data source
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
 
  if ( self.textService.texts ) {
    return self.textService.texts.count;
  } else {
    return 0;
  }
  
}

- (UITableViewCell *)tableView:(UITableView *)theTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  PFObject *theText = [self textForRow:indexPath.row];
  if (theText[kTextVoiceMessageKey]) {
   return [self textVoiceMessageCellForText:theText
                                  indexPath:indexPath];
  } else if (theText[kGlympseURLKey]) {
    return [self glympseCellForText:theText];
  } else {
    return [self textCellForText:theText];
  }
}

- (void)tableView: (UITableView*)tableView
  willDisplayCell: (UITableViewCell*)cell
forRowAtIndexPath: (NSIndexPath*)indexPath
{
  cell.backgroundColor = [UIColor clearColor];
}


-(TextCell *)textCellForText:(PFObject *)text {
  TextCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kTextCellIdentifier];
  if ( ! cell ) {
    cell = [[TextCell alloc] initWithReuseIdentifier:kTextCellIdentifier];
  
    cell.label.delegate = self;
    [cell.resendButton addTarget:self
                          action:@selector(resendTextButtonPressed:)
                forControlEvents:UIControlEventTouchUpInside];
    [cell.deleteButton addTarget:self
                          action:@selector(deleteButtonPressed:)
                forControlEvents:UIControlEventTouchUpInside];
    
    UISwipeGestureRecognizer *swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(showDeleteButton:)];
    [cell addGestureRecognizer:swipeGesture];
  
    // add gesture recognizers for textPhoto
    UITapGestureRecognizer *pictureTap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                 action:@selector(handlePictureTap:)];
    
    [cell.picture addGestureRecognizer:pictureTap];
    
    UILongPressGestureRecognizer *pictureLongPress = [[UILongPressGestureRecognizer alloc]
                                                      initWithTarget:self action:@selector(handlePictureLongPress:)];
    pictureLongPress.minimumPressDuration = 1.0;
    [cell.picture addGestureRecognizer:pictureLongPress];
  }
  
  cell.text = text;
  cell.deleteButton.alpha = 0.0;
    
  return cell;
}

-(TextVoiceMessageCell *)textVoiceMessageCellForText:(PFObject *)text
                                           indexPath:(NSIndexPath *)indexPath {
  TextVoiceMessageCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kVoiceMessageCellIdentifier];
  if ( ! cell ) {
    cell = [[TextVoiceMessageCell alloc] initWithReuseIdentifier:kVoiceMessageCellIdentifier];
  
    [cell.playbackButton addTarget:self
                            action:@selector(playbackButtonPressed:)
                  forControlEvents:UIControlEventTouchUpInside];
    [cell.resendButton addTarget:self
                          action:@selector(resendTextButtonPressed:)
                forControlEvents:UIControlEventTouchUpInside];
    [cell.deleteButton addTarget:self
                          action:@selector(deleteButtonPressed:)
                forControlEvents:UIControlEventTouchUpInside];
  
    // swipe to delete gesture
    UISwipeGestureRecognizer *swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(showDeleteButton:)];
    [cell addGestureRecognizer:swipeGesture];
  
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]
                                             initWithTarget:self action:@selector(handleVoiceMessageLongPress:)];
    longPress.minimumPressDuration = 1.0;
    [cell addGestureRecognizer:longPress];
  }
  
  cell.text = text;
  [cell.spinner stopAnimating];
    
  if (self.playerIP && ([indexPath compare:self.playerIP] == NSOrderedSame)) {
    [cell.progressView setProgress: ( self.player.currentTime / self.player.duration )];
    
    if ([self.player isPlaying]) {
      cell.playbackButtonIV.image = [UIImage imageNamed:@"pause"];
    } else {
      cell.playbackButtonIV.image = [UIImage imageNamed:@"play"];
    }
  } else {
    [cell.progressView setProgress:0];
    cell.playbackButtonIV.image = [UIImage imageNamed:@"play"];
  }
  
  cell.deleteButton.alpha = 0.0;
  
  return cell;
}

- (GlympseTextCell *)glympseCellForText:(PFObject *)text {
  GlympseTextCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kGlympseTextCellIdentificer];
  if ( ! cell ) {
    cell = [[GlympseTextCell alloc] initWithReuseIdentifier:kGlympseTextCellIdentificer];
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                 action:@selector(glympseTapped:)];
    [cell.textView addGestureRecognizer:tapRecognizer];
    
    [cell.resendButton addTarget:self
                          action:@selector(resendTextButtonPressed:)
                forControlEvents:UIControlEventTouchUpInside];
    
  }
  
  cell.text = text;
  
  return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  PFObject *theText = [self textForRow:indexPath.row];
  
  if ( theText[kTextVoiceMessageKey] ) {
    return kVoiceMessageCellHeight;
  } else if ( theText[kGlympseURLKey] ) {
    return [GlympseTextCell textCellHeightForText:theText cellWidth:tableView.frameSizeWidth];
  } else {
    return [TextCell textCellHeightForText:theText cellWidth:tableView.frameSizeWidth];
  }
}

#pragma mark Button Actions
-(IBAction)sendButtonPressed:(id)sender {
  if ([self.messageTextView.internalTextView.text length] > 0 ||
      self.photoToSend) {
    NSString *messageToSend = self.messageTextView.internalTextView.text;
    if (messageToSend == nil) {
      messageToSend = @"";
    }
    [self.textService sendTextMessage:messageToSend withPhoto:self.photoToSend andVoiceMessage:nil];
  }
}

- (void)drawerButtonPressed {
  [self.view endEditing:YES];
  [[self mm_drawerController] toggleDrawerSide:MMDrawerSideLeft animated:YES completion:NULL];
}

-(void)refreshButtonPressed:(id)sender {
  [self refresh];
  [self stopPlayer];
}

-(void)refresh {
  [self setRefreshSpinner];
  [self.textService retrieveTextsWithRetrieveAction:RetrieveTextActionAll];
}

-(void)timerRefresh {
  [self.textService retrieveTextsWithRetrieveAction:RetrieveTextActionNew];
}

-(IBAction)resendTextButtonPressed:(UIButton *)button {
  UITableViewCell *cell = [SHUtil tableViewCellForView:button];
  
  PFObject *theText = [self textForRow:[self.tableView indexPathForCell:cell].row];
  
  [self.textService resendText:theText];
}

-(void)loadEarlierButtonPressed:(id)sender {
  [self.loadMoreButton setTitle:@"" forState:UIControlStateNormal];
  [self.loadMoreSpinner startAnimating];
  
  [self.textService retrieveTextsWithRetrieveAction:RetrieveTextActionOlder];
}

#pragma mark other functions
-(void)clearMessageTextView {
  self.messageTextView.internalTextView.text = @"";
  self.sentPhoto = self.photoToSend;
  self.photoToSend = nil;
  [self configureAddButton];
}

-(void)keyboardWillShow:(NSNotification *)n {
  NSDictionary *userInfo = [n userInfo];
  
  [self.tableView addGestureRecognizer:self.dismissKeyboardTap];
  [self.messageBackground addGestureRecognizer:self.dismissKeyboardSwipe];
  
  BOOL shouldScrollToBottom = [self atBottomOfTable];
  
  // get keyboard size
  NSValue *frameValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
  CGFloat keyboardHeight = [frameValue CGRectValue].size.height;
  NSTimeInterval animationDuration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
  
  [UIView animateWithDuration:animationDuration
                   animations:^{
                     self.messageBackground.frame = CGRectMake(0.f,
                                                                self.view.bounds.size.height - keyboardHeight - self.messageBackground.frame.size.height,
                                                                self.messageBackground.frame.size.width,
                                                                self.messageBackground.frame.size.height);
                     [self positionAddButtonsBackground];
                     self.tableViewBottomInset = keyboardHeight + self.messageBackground.frame.size.height;
                     self.tableView.contentInset = UIEdgeInsetsMake(self.tableView.contentInset.top,
                                                                     self.tableView.contentInset.left,
                                                                     self.tableViewBottomInset,
                                                                     self.tableView.contentInset.right);
                     self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
                     
                     if (shouldScrollToBottom) {
                       self.tableView.contentOffset = [self atBottomContentOffset];
                     }
                     
                   } completion:NULL];
  
}

-(void)keyboardWillHide:(NSNotification *)n {
  NSDictionary *userInfo = [n userInfo];
  
  [self.tableView removeGestureRecognizer:self.dismissKeyboardTap];
  [self.messageBackground removeGestureRecognizer:self.dismissKeyboardSwipe];
  
  BOOL shouldScrollToBottom = [self atBottomOfTable];
  
  // get keyboard size
  NSTimeInterval animationDuration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
  
  [UIView animateWithDuration:animationDuration
                   animations:^{
                     self.messageBackground.frame = CGRectMake(0.f,
                                                                self.view.bounds.size.height - self.messageBackground.frame.size.height,
                                                                self.messageBackground.frame.size.width,
                                                                self.messageBackground.frame.size.height);
                     
                     [self positionAddButtonsBackground];
                     self.tableViewBottomInset = self.messageBackground.frame.size.height;
                     self.tableView.contentInset = UIEdgeInsetsMake(self.tableView.contentInset.top,
                                                                     self.tableView.contentInset.left,
                                                                     self.tableViewBottomInset,
                                                                     self.tableView.contentInset.right);
                     self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
                     
                     if (shouldScrollToBottom) {
                       self.tableView.contentOffset = [self atBottomContentOffset];
                     }
                   } completion:NULL];
  
}

-(void)dismissKeyboard {
  [self.messageTextView resignFirstResponder];
}

- (void)reloadData {
  [self.tableView reloadData];
}

# pragma mark notification handlers
-(void)handleAllTextsReceived:(NSNotification *)notification {
  [self setRefreshButton];
  
  NSDictionary *userInfo = notification.userInfo;
  
  if (userInfo[kHideEarlierMessagesButtonKey]) {
    self.tableView.tableHeaderView = self.emptyHeader;
  } else {
    self.tableView.tableHeaderView = self.loadMoreButton;
    [self.loadMoreSpinner stopAnimating];
    [self.loadMoreButton setTitle:@"Load earlier messages" forState:UIControlStateNormal];
  }
  
  if ([userInfo[kTextRetrievalActionKey] integerValue] != RetrieveTextActionOlder) {
    [self.tableView reloadData];
    [self moveTableViewToBottomWithAnimationDuration:(self.tableView.alpha > 0 ? 0.1 : 0.0) setAlpha:YES];
  } else {
    CGFloat distanceFromBottom = (self.tableView.contentSize.height + self.tableView.contentInset.top + self.tableView.contentInset.bottom) - self.tableView.contentOffset.y;
    [self.tableView reloadData];
    self.tableView.contentOffset = CGPointMake(0, (self.tableView.contentSize.height + self.tableView.contentInset.top + self.tableView.contentInset.bottom) - distanceFromBottom);
  }
  
  [self updateOverlays];
}

-(void)handleInitialSendText:(NSNotification *)not {
  self.tableView.alpha = 1.f;
  [self clearMessageTextView];
  NSIndexPath *newRowIndexPath = [NSIndexPath indexPathForRow:[not.userInfo[@"row"] intValue] inSection:0];
  [self.tableView insertRowsAtIndexPaths:@[newRowIndexPath] withRowAnimation:UITableViewRowAnimationNone];
  
  NSIndexPath *lastRowIndexPath = [NSIndexPath indexPathForRow:(self.textService.texts.count - 1) inSection:0];
  [self.tableView scrollToRowAtIndexPath:lastRowIndexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
  [self updateOverlays];
}

-(void)handleSendTextSuccess:(NSNotification *)not {
  [self.tableView reloadData];
  [self updateOverlays];
}

-(void)handleInitialResendText {
  [self.tableView reloadData];
  [self updateOverlays];
}

-(void)handleResendTextSuccess {
  [self.tableView reloadData];
  [self updateOverlays];
}

-(void)handleReceiveTextError {
  [self setRefreshButton];
  
  if ([self.tableView.tableHeaderView isKindOfClass:[UIButton class]]) {
    [self.loadMoreSpinner stopAnimating];
    [self.loadMoreButton setTitle:@"Load earlier messages" forState:UIControlStateNormal];
  }
  
  [self.view bringSubviewToFront:self.alertContainer];
  [SHUtil showWarningInView:self.alertContainer
                      title:@"Network Error"
                    message:@"Unable to retrieve messages.  Please try later."];
  
  [self updateOverlays];
  
}

-(void)handleSendTextError {
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                 message:@"Unable to send message. Please try later."
                                                          preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                            style:UIAlertActionStyleCancel
                                          handler:nil]];
  [self presentViewController:alert
                     animated:YES
                   completion:nil];
  
  [self.tableView reloadData];
  
  [self updateOverlays];
}

-(void)handleSendNetworkError {
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"No Internet Connection"
                                                                 message:@"Unable to send message. Please try later."
                                                          preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                            style:UIAlertActionStyleCancel
                                          handler:nil]];
  [self presentViewController:alert
                     animated:YES
                   completion:nil];
  
  [self.tableView reloadData];
  [self updateOverlays];
}

#pragma mark button functions

#define kPlusIVTag 1

-(void)initializeAddButtons {
  [self createAddButton];
}

-(void)createAddButton {
  UIImageView *plusIV = [[UIImageView alloc] initWithFrame:CGRectMake(4, 4, 22, 22)];
  UIImage* image = [UIImage imageNamed:@"X_icon"];
  image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
  plusIV.image = image;
  plusIV.tag = kPlusIVTag;
  plusIV.userInteractionEnabled = NO;
  [self.addButton addSubview:plusIV];
}

-(void)createAddButtons {
  [self createAddPhotoButton];
  [self createAddVoiceMessageButton];
  [self createAddSavedMessageButton];
  [self createAddGlympseButton];
}

-(void)createAddPhotoButton {
  UIImageView *cameraIV = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, 30, 30)];
  cameraIV.image = [UIImage imageNamed:@"photo"];
  cameraIV.userInteractionEnabled = NO;
  [self.addPhotoButton addSubview:cameraIV];
  
  UILabel *theLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 10, 250, 30)];
  theLabel.textAlignment = NSTextAlignmentLeft;
  theLabel.font = [UIFont fontWithName:@"CopperPlate" size:22.0];
  theLabel.textColor = [UIColor whiteColor];
  theLabel.text = @"Photo";
  theLabel.backgroundColor = [UIColor clearColor];
  [self.addPhotoButton addSubview:theLabel];
  
}

-(void)createAddVoiceMessageButton {
  UIImageView *micIV = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, 30, 30)];
  micIV.image = [UIImage imageNamed:@"mic"];
  micIV.userInteractionEnabled = NO;
  [self.addVoiceMessageButton addSubview:micIV];
  
  UILabel *theLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 10, 250, 30)];
  theLabel.textAlignment = NSTextAlignmentLeft;
  theLabel.font = [UIFont fontWithName:@"CopperPlate" size:22.0];
  theLabel.textColor = [UIColor whiteColor];
  theLabel.text = @"Voice Message";
  theLabel.backgroundColor = [UIColor clearColor];
  [self.addVoiceMessageButton addSubview:theLabel];
  
}

-(void)createAddSavedMessageButton {
  UIImageView *micIV = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, 30, 30)];
  micIV.image = [UIImage imageNamed:@"comment"];
  micIV.userInteractionEnabled = NO;
  [self.addSavedMessageButton addSubview:micIV];
  
  UILabel *theLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 10, 250, 30)];
  theLabel.textAlignment = NSTextAlignmentLeft;
  theLabel.font = [UIFont fontWithName:@"CopperPlate" size:22.0];
  theLabel.textColor = [UIColor whiteColor];
  theLabel.text = @"Saved Message";
  theLabel.backgroundColor = [UIColor clearColor];
  [self.addSavedMessageButton addSubview:theLabel];
}

- (void)createAddGlympseButton {
  UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, 30, 30)];
  iv.image = [UIImage imageNamed:@"Location"];
  iv.userInteractionEnabled = NO;
  [self.addGlympseButton addSubview:iv];
  
  UILabel *theLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 10, 250, 30)];
  theLabel.textAlignment = NSTextAlignmentLeft;
  theLabel.font = [UIFont fontWithName:@"CopperPlate" size:22.0];
  theLabel.textColor = [UIColor whiteColor];
  theLabel.text = @"Glympse";
  theLabel.backgroundColor = [UIColor clearColor];
  [self.addGlympseButton addSubview:theLabel];
}

-(void)configureAddButton {
  if (self.photoToSend) {
    self.addButton.layer.cornerRadius = 0;
    self.addButton.layer.masksToBounds = YES;
    self.addButton.layer.borderWidth = 0;
    [self.addButton setBackgroundImage:self.photoToSend forState:UIControlStateNormal];
    UIImageView *plusIV = (UIImageView *)[self.addButton viewWithTag:kPlusIVTag];
    [plusIV removeFromSuperview];
  } else {
    [self.addButton setBackgroundImage:nil forState:UIControlStateNormal];
    
    UIImageView *plusIV = (UIImageView *)[self.addButton viewWithTag:kPlusIVTag];
    if (plusIV) {
      [plusIV setTransform:CGAffineTransformIdentity];
    } else {
      UIImageView *plusIV = [[UIImageView alloc] initWithFrame:CGRectMake(4, 4, 22, 22)];
      UIImage* image = [UIImage imageNamed:@"X_icon"];
      image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
      
      plusIV.image = image;
      plusIV.tintColor = [UIColor darkGrayColor];
      
      plusIV.tag = kPlusIVTag;
      plusIV.userInteractionEnabled = NO;
      [self.addButton addSubview:plusIV];
    }
  }
}

-(IBAction)addButtonPressed:(id)sender {
  if (self.photoToSend) {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:@"Remove photo from message?"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Yes"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
                                              self.photoToSend = nil;
                                              [self configureAddButton];
                                            }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"No"
                                              style:UIAlertActionStyleDefault
                                            handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
  } else {
    if (!self.showingAddButtons) {
      self.showingAddButtons = YES;
      UIImageView *plusIV = (UIImageView *)[self.addButton viewWithTag:kPlusIVTag];
      CGRect backgroundFrame = self.addButtonsBackground.frame;
      backgroundFrame.origin.y = self.messageBackground.frame.origin.y;
      self.addButtonsBackground.frame = backgroundFrame;
      [UIView animateWithDuration:0.2 animations: ^{
        [plusIV setTransform:CGAffineTransformMakeRotation(M_PI_4)];
        [self positionAddButtonsBackground];
      }];
    } else {
      [self hideAddButtons];
    }
  }
}

-(void)hideAddButtons {
  self.showingAddButtons = NO;
  UIImageView *plusIV = (UIImageView *)[self.addButton viewWithTag:kPlusIVTag];
  [UIView animateWithDuration:0.2 animations: ^{
    [plusIV setTransform:CGAffineTransformIdentity];
    [self positionAddButtonsBackground];
  }];
}

-(IBAction)addPhotoButtonPressed:(id)sender {
  [self hideAddButtons];
  
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                 message:nil
                                                          preferredStyle:UIAlertControllerStyleActionSheet];
  [alert addAction:[UIAlertAction actionWithTitle:@"Take Photo"
                                            style:UIAlertActionStyleDefault
                                          handler:^(UIAlertAction * _Nonnull action) {
                                            [self takePhotoButtonPressed];
                                          }]];
  [alert addAction:[UIAlertAction actionWithTitle:@"Choose From Library"
                                            style:UIAlertActionStyleDefault
                                          handler:^(UIAlertAction * _Nonnull action) {
                                            [self choosePhotoButtonPressed];
                                          }]];
  [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                            style:UIAlertActionStyleCancel
                                          handler:nil]];
  [self presentViewController:alert animated:YES completion:nil];
  
}

-(IBAction)addVoiceMessageButtonPressed:(id)sender {
  [self.view endEditing:YES];
  [self hideAddButtons];
  [self clearMessageTextView];
  
  if (self.player && [self.player isPlaying]) {
    [self stopPlayer];
  }
  
  self.recordVC = [[RecordController alloc] initWithNibName:nil bundle:nil];
  self.recordVC.delegate = self;
  
  [self addChildViewController:self.recordVC];
  self.recordVC.view.frame = CGRectMake(0.0,
                                        self.view.bounds.size.height - self.recordVC.view.bounds.size.height,
                                        self.view.bounds.size.width,
                                        self.recordVC.view.bounds.size.height);
  [self.view addSubview:self.recordVC.view];
  [self.recordVC didMoveToParentViewController:self];
  
  // add blocking view
  self.blockingView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - self.recordVC.view.frame.size.height);
  [self.view addSubview:self.blockingView];
  self.navigationItem.rightBarButtonItem.enabled = NO;
  
}

-(IBAction)addSavedMessageButtonPressd:(id)sender {
  [self hideAddButtons];
  SavedMessagesController *con = [[SavedMessagesController alloc] initWithDelegate:self];
  SHNavigationController *navCon = [[SHNavigationController alloc] initWithRootViewController:con];
  navCon.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
  [self presentViewController:navCon animated:YES completion:nil];
}

- (IBAction)addGlympseButtonPressed:(id)sender {
  [self hideAddButtons];
  [self.view endEditing:YES];
  
  CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
  
  if ( status == kCLAuthorizationStatusAuthorizedAlways ) {
    [[GlympseLiteWrapper instance] expireActiveTicket];
    [[GlympseLiteWrapper instance] sendGlympse];
  } else if ( status == kCLAuthorizationStatusNotDetermined ) {
    self.sendingGlympse = YES;
    [self.locationManager requestAlwaysAuthorization];
  } else {
    NSString *title = status == kCLAuthorizationStatusDenied ? @"Location services are off" : @"Background location is not enabled";
    NSString *message = @"To use background location you must turn on 'Always' in the Location Services Settings";
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Settings"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
                                              NSURL *settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                                              [[UIApplication sharedApplication] openURL:settingsURL];
                                            }]];
    [self presentViewController:alert
                       animated:YES
                     completion:nil];
    
  }
}


-(BOOL)isPlayerCell:(UITableViewCell *)cell {
  if (!self.playerIP) {
    return NO;
  }
  
  NSIndexPath *ip = [self.tableView indexPathForCell:cell];
  
  return ([ip compare:self.playerIP] == NSOrderedSame);
  
}

-(IBAction)playbackButtonPressed:(UIButton *)button {
  [self.view endEditing:YES];
  
  TextVoiceMessageCell *cell = (TextVoiceMessageCell *)[SHUtil tableViewCellForView: button];
  
  if (!cell) {
    return;
  }
  
  PFObject *theText = [self textForRow:[self.tableView indexPathForCell:cell].row];
  PFFile *voiceMessageFile = theText[kTextVoiceMessageKey];
  if ( !voiceMessageFile.isDataAvailable ) {
    [cell.spinner startAnimating];
  }
  
  if ([self isPlayerCell:cell] && self.player) {
    if (self.player.playing) {
      [self pausePlayer];
    } else {
      [self playPlayer];
    }
  } else {
    if (self.playerIP) {
      // another cell was playing
      TextVoiceMessageCell *playerCell = (TextVoiceMessageCell *)[self.tableView cellForRowAtIndexPath:self.playerIP];
      playerCell.playbackButtonIV.image = [UIImage imageNamed:@"play"];
      [playerCell.progressView setProgress:0];
      self.playerIP = nil;
      [self.playerTimer invalidate];
    }

    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    self.playerIP = [self.tableView indexPathForCell:cell];
    
    [voiceMessageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
      if ( ! error ) {
        if ( [self.playerIP isEqual:indexPath] ) {
          self.player = [[AVAudioPlayer alloc] initWithData:data error:nil];
          self.player.delegate = self;
        
          [self playPlayer];
        }
      } else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                       message:@"Unable to download voice message. Please try later."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [self presentViewController:alert
                           animated:YES
                         completion:nil];
      }
      [cell.spinner stopAnimating];
    }];
  }
}

-(IBAction)audioRouteButtonPressed:(id)sender {
  if (self.audioRoute == kAudioSessionOverrideAudioRoute_Speaker) {
    self.audioRoute = kAudioSessionOverrideAudioRoute_None;
    self.audioRouteButton.customView.tintColor = [UIColor whiteColor];
  } else {
    self.audioRoute = kAudioSessionOverrideAudioRoute_Speaker;
    self.audioRouteButton.customView.tintColor = [SHPalette darkRedColor];
  }
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [[AVAudioSession sharedInstance] overrideOutputAudioPort:self.audioRoute error:nil];
  });
}


- (void)glympseTapped:(UIGestureRecognizer *)recognizer{
  [self.view endEditing:YES];

  GlympseTextCell *cell = (GlympseTextCell *)[SHUtil tableViewCellForView:[recognizer view]];
  
  if (!cell) {
    return;
  }
  
  PFObject *theText = [self textForRow:[self.tableView indexPathForCell:cell].row];

  if ([[GlympseLiteWrapper instance] isURLForActiveTicket:theText[kGlympseURLKey]] &&
      [theText[kGlympseExpireDateKey] compare:[NSDate date]] == NSOrderedDescending &&
      [[User currentUser].myUserIDs containsObject:theText[kSenderKey]] ) {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    [alert addAction:[UIAlertAction actionWithTitle:@"View Glympse"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
                                              [self viewGlympseForText:theText];
                                            }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Modify Glympse"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
                                              dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                                [[GlympseLiteWrapper instance] modifyActiveTicket];
                                              });
                                            }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
  } else {
    [self viewGlympseForText:theText];
  }
  
}

#pragma mark CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
  if ( status == kCLAuthorizationStatusAuthorizedAlways ) {
    if ( self.sendingGlympse ) {
      self.sendingGlympse = NO;
      [[GlympseLiteWrapper instance] expireActiveTicket];
      [[GlympseLiteWrapper instance] sendGlympse];
    }
  }
}

#pragma mark AVAudioPlayer delegate
-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
  self.tableView.scrollsToTop = YES;
  
  if (self.playerTimer) {
    [self.playerTimer invalidate];
  }
  if (self.playerIP) {
    TextVoiceMessageCell *playerCell = (TextVoiceMessageCell *)[self.tableView cellForRowAtIndexPath:self.playerIP];
    playerCell.playbackButtonIV.image = [UIImage imageNamed:@"play"];
    [playerCell.progressView setProgress:0];
  }
  
  self.playerIP = nil;
  
  [self.navigationItem setRightBarButtonItem:self.refreshButton animated:YES];
  
}

#pragma mark player functions
-(void)schedulePlayerTimer {
  self.playerTimer = [NSTimer timerWithTimeInterval:0.1
                                             target:self
                                           selector:@selector(updatePlayProgressView:)
                                           userInfo:nil
                                            repeats:YES];
  [[NSRunLoop mainRunLoop] addTimer:self.playerTimer forMode:NSRunLoopCommonModes];
}

-(void)updatePlayProgressView:(NSTimer *)timer {
  if (self.playerIP) {
    TextVoiceMessageCell *playerCell = (TextVoiceMessageCell *)[self.tableView cellForRowAtIndexPath:self.playerIP];
    [playerCell.progressView setProgress:( self.player.currentTime / self.player.duration )];
  }
}

-(void)stopPlayer {
  [UIDevice currentDevice].proximityMonitoringEnabled = NO;
  
  self.tableView.scrollsToTop = YES;
  
  [self.navigationItem setRightBarButtonItem:self.refreshButton animated:YES];
  
  [self.player stop];
  [self.playerTimer invalidate];
  if (self.playerIP) {
    TextVoiceMessageCell *playerCell = (TextVoiceMessageCell *)[self.tableView cellForRowAtIndexPath:self.playerIP];
    playerCell.playbackButtonIV.image = [UIImage imageNamed:@"play"];
  }
  
  self.playerIP = nil;
  
}

-(void)pausePlayer {
  [UIDevice currentDevice].proximityMonitoringEnabled = NO;
  
  self.tableView.scrollsToTop = YES;
  [self.navigationItem setRightBarButtonItem:self.refreshButton animated:YES];
  
  [self.playerTimer invalidate];
  [self.player pause];
  if (self.playerIP) {
    TextVoiceMessageCell *playerCell = (TextVoiceMessageCell *)[self.tableView cellForRowAtIndexPath:self.playerIP];
    playerCell.playbackButtonIV.image = [UIImage imageNamed:@"play"];
  }
  
}

-(void)playPlayer {
  [UIDevice currentDevice].proximityMonitoringEnabled = YES;
  
  self.tableView.scrollsToTop = NO;
  [self.navigationItem setRightBarButtonItem:self.audioRouteButton animated:YES];
  
  [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
  [self.player play];
  if (self.playerIP) {
    TextVoiceMessageCell *playerCell = (TextVoiceMessageCell *)[self.tableView cellForRowAtIndexPath:self.playerIP];
    playerCell.playbackButtonIV.image = [UIImage imageNamed:@"pause"];
  }
  [self schedulePlayerTimer];
  
}

#pragma mark utility functions
-(CGFloat)heightForTextView:(UITextView *)textView {
  UIEdgeInsets insets = textView.textContainerInset;
  
  NSLayoutManager *layoutManager = [textView layoutManager];
  NSUInteger numberOfLines, index, numberOfGlyphs = [layoutManager numberOfGlyphs];
  NSRange lineRange;
  for (numberOfLines = 0, index = 0; index < numberOfGlyphs && numberOfLines <= kMaxTextviewLines; numberOfLines++){
    (void) [layoutManager lineFragmentRectForGlyphAtIndex:index
                                           effectiveRange:&lineRange];
    index = NSMaxRange(lineRange);
  }
  
  if ([textView.text hasSuffix:@"\n"]) {
    numberOfLines++;
  }
  if (!numberOfLines) {
    numberOfLines = 1;
  }
  
  return numberOfLines * textView.font.lineHeight + insets.top + insets.bottom;
  
}

- (PFObject *)textForRow:(NSUInteger)row {
  return self.textService.texts[self.textService.texts.count - row - 1];
}

- (void)viewGlympseForText:(PFObject *)text {
  NSString *path = text[kGlympseURLKey];
  path = [path stringByReplacingOccurrencesOfString:@"http://" withString:@"https://"];
  
  GenericWebViewController *vc = [[GenericWebViewController alloc] initWithPath:path
                                                                          title:@"Glympse"];
  [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark CSGrowingTextViewDelegate
#define kMVPaddingHeight 6.0

- (void)growingTextView:(CSGrowingTextView *)growingTextView willChangeHeight:(CGFloat)height {
  CGFloat oldHeight = growingTextView.frame.size.height;
  CGRect frame = self.messageBackground.frame;
  CGFloat difference = height - oldHeight;
  frame.size.height += difference;
  frame.origin.y -= difference;

  
  BOOL shouldScrollToBottom = [self atBottomOfTable];
  self.tableViewBottomInset = self.view.frame.size.height - frame.origin.y;

  __weak TextController *wSelf = self;
  [UIView animateWithDuration:0.25f animations:^{
    self.messageBackground.frame = frame;    
    [wSelf positionAddButtonsBackground];
    wSelf.tableView.contentInset = UIEdgeInsetsMake(wSelf.tableView.contentInset.top,
                                                    wSelf.tableView.contentInset.left,
                                                    wSelf.tableViewBottomInset,
                                                    wSelf.tableView.contentInset.right);
    wSelf.tableView.scrollIndicatorInsets = wSelf.tableView.contentInset;
    if (shouldScrollToBottom) {
      wSelf.tableView.contentOffset = [wSelf atBottomContentOffset];
    }
  } completion:NULL];

}



#define kMVPaddingHeight 6.0
-(void)configureMessageTextViewWithAnimationDuration:(CGFloat)animationDuration {
  
  BOOL shouldScrollToBottom = [self atBottomOfTable];
  
  self.tableViewBottomInset = self.view.frame.size.height - self.messageBackground.frame.origin.y;
  
  __weak TextController *wSelf = self;
  [UIView animateWithDuration:animationDuration animations:^{
    [wSelf positionAddButtonsBackground];
    wSelf.tableView.contentInset = UIEdgeInsetsMake(wSelf.tableView.contentInset.top,
                                                    wSelf.tableView.contentInset.left,
                                                    wSelf.tableViewBottomInset,
                                                    wSelf.tableView.contentInset.right);
    wSelf.tableView.scrollIndicatorInsets = wSelf.tableView.contentInset;
    if (shouldScrollToBottom) {
      wSelf.tableView.contentOffset = [wSelf atBottomContentOffset];
    }
  } completion:NULL];
   
}


-(BOOL)atBottomOfTable {
  
  if (self.tableView.bounds.size.height > self.tableView.contentSize.height) {
    return NO;
  }
  NSIndexPath *lastIP = [NSIndexPath indexPathForRow: (self.textService.texts.count - 1)
                                           inSection: 0];
  return [self.tableView.indexPathsForVisibleRows containsObject: lastIP];
  
}

-(void)moveTableViewToBottomWithAnimationDuration:(CGFloat)animationDuration setAlpha:(BOOL)setAlpha {
  CGFloat tableViewScreenSpace = (self.tableView.frame.size.height - self.tableViewBottomInset);
  
  if (self.tableView.contentSize.height > tableViewScreenSpace) {
    [UIView animateWithDuration:animationDuration animations:^{
      self.tableView.contentOffset = [self atBottomContentOffset];
    } completion:^(BOOL finished) {
      if (setAlpha) {
        self.tableView.alpha = 1.0;
      }
    }];
  } else if (setAlpha) {
    self.tableView.alpha = 1.0;
  }
}

-(CGPoint)atBottomContentOffset {
  return CGPointMake(0, self.tableView.contentSize.height - self.tableView.bounds.size.height + self.tableViewBottomInset);
}

-(void)showDeleteButton:(UIGestureRecognizer *)gestureRecognizer {
  UITableViewCell *cell = (UITableViewCell *)gestureRecognizer.view;
  self.cellToDelete = cell;
  NSInteger row = [self.tableView indexPathForCell:cell].row;
  self.textToDelete = [self textForRow:row];
  
  if ( [[User currentUser].myUserIDs containsObject:self.textToDelete[kSenderKey]] ) {
    UIButton *deleteButton;
    if ( [cell isKindOfClass:[TextCell class]] ) {
      deleteButton = [(TextCell *)cell deleteButton];
    } else {
      deleteButton = [(TextVoiceMessageCell *)cell deleteButton];
    }
    
    [UIView animateWithDuration:0.3 animations:^{
      deleteButton.alpha = 1.0;
    }];
    [self.tableView addGestureRecognizer:self.hideDeleteGR];
  }
}

-(IBAction)deleteButtonPressed:(UIButton *)deleteButton {
  [self stopPlayer];
  [UIView animateWithDuration:0.3 animations:^{
    deleteButton.alpha = 0.0;
  }];
  self.cellToDelete.alpha = 0.5;
  [self.textService deleteText:self.textToDelete];
  [self.tableView removeGestureRecognizer:self.hideDeleteGR];
}

-(void)handleDeleteTextSuccess:(NSNotification *)not {
  self.cellToDelete.alpha = 1.0;
  [self.tableView reloadData];
  [self updateOverlays];
}

-(void)handleDeleteTextError {
  self.cellToDelete.alpha = 1.0;
  
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                 message:@"Unable to delete text. Please try later."
                                                          preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                            style:UIAlertActionStyleCancel
                                          handler:nil]];
  [self presentViewController:alert
                     animated:YES
                   completion:nil];
  
}

-(void)hideDeleteButton:(UIGestureRecognizer *)gestureRecognizer {
  [self.tableView removeGestureRecognizer:self.hideDeleteGR];
  UIButton *deleteButton;
  if ( [self.cellToDelete isKindOfClass:[TextCell class]] ) {
    deleteButton = [(TextCell *)self.cellToDelete deleteButton];
  } else {
    deleteButton = [(TextVoiceMessageCell *)self.cellToDelete deleteButton];
  }
  
  [UIView animateWithDuration:0.3 animations:^{
    deleteButton.alpha = 0.0;
  }];
}


-(void)setRefreshButton {
  self.refreshButton = [SHUtil barButtonItemWithTarget:self
                                                action:@selector(refreshButtonPressed:)
                                                 image:[UIImage imageNamed:@"resend"]];
  [self.navigationItem setRightBarButtonItem:self.refreshButton];
  
}

-(void)setRefreshSpinner {
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
  view.backgroundColor = [UIColor clearColor];
  UIActivityIndicatorView *refreshSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
  refreshSpinner.frame = CGRectMake(5, 5, 20, 20);
  [refreshSpinner startAnimating];
  [view addSubview:refreshSpinner];
  self.refreshButton = [[UIBarButtonItem alloc] initWithCustomView:view];
  [self.navigationItem setRightBarButtonItem:self.refreshButton];
  
}

-(void)positionAddButtonsBackground {
  if (self.showingAddButtons) {
    self.addButtonsBackground.frame = CGRectMake(self.addButtonsBackground.frame.origin.x,
                                                 self.messageBackground.frame.origin.y - 200.f,
                                                 self.addButtonsBackground.frame.size.width,
                                                 200.f);
  } else {
    self.addButtonsBackground.frame = CGRectMake(self.addButtonsBackground.frame.origin.x,
                                                 self.messageBackground.frame.origin.y,
                                                 self.addButtonsBackground.frame.size.width,
                                                 0);
  }
  
}

-(void)updateOverlays {
  if ( (! self.textService.cacheRetrieved && ! self.textService.networkRetrieved) ||
       (self.textService.cacheRetrieved && self.textService.texts.count == 0 && ! self.textService.networkRetrieved ) ) {
    self.noTextMessagesLabel.text = @"Loading...";
    self.noTextMessagesLabel.hidden = NO;
  } else if ( self.textService.texts.count == 0 ){
    self.noTextMessagesLabel.text = @"No text messages.\n\nPress '+' to add a photo, voice message, Glympse or saved message.";
    self.noTextMessagesLabel.hidden = NO;
  } else {
    self.noTextMessagesLabel.hidden = YES;
  }
}

#pragma mark UIGestureRecognizer delegate
- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
  if ([touch.view isKindOfClass:[UIButton class]]) return FALSE;
  return TRUE;
}

#pragma mark photo functions
-(void)handlePictureTap:(UIGestureRecognizer *)gesture {
  [self.messageTextView resignFirstResponder];
  
  UIImageView *textPhoto = (UIImageView *)[gesture view];
  
  UITableViewCell *cell = [SHUtil tableViewCellForView: textPhoto];
  
  CGRect textPhotoFrame = [cell convertRect:textPhoto.frame toView:self.view.window];
  
  PhotoDetailController *photoDetailVC = [[PhotoDetailController alloc] initWithImage:textPhoto.image andFrame:textPhotoFrame];
  photoDetailVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
  photoDetailVC.modalPresentationStyle = UIModalPresentationFullScreen;
  [self presentViewController:photoDetailVC animated:YES completion:NULL];
}

-(void)handlePictureLongPress:(UIGestureRecognizer *)gesture {
  if (gesture.state == UIGestureRecognizerStateBegan) {
    UIImageView *textPhoto = (UIImageView *)[gesture view];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    [alert addAction:[UIAlertAction actionWithTitle:@"Save Photo"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
                                              UIImageWriteToSavedPhotosAlbum(textPhoto.image, nil, nil, nil);
                                            }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
  }
}

- (void)handleVoiceMessageLongPress:(UIGestureRecognizer *)gesture {
  if ( gesture.state == UIGestureRecognizerStateBegan ) {
    UITableViewCell *cell = (UITableViewCell *)[gesture view];
    NSInteger row = [self.tableView indexPathForCell:cell].row;
    
    PFObject *theText = [self textForRow:row];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    [alert addAction:[UIAlertAction actionWithTitle:@"E-mail Voice Message"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
                                              if ([MFMailComposeViewController canSendMail] == FALSE) {
                                                UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                                                               message:@"Sorry, your device is unable to send e-mail."
                                                                                                        preferredStyle:UIAlertControllerStyleAlert];
                                                [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                                                          style:UIAlertActionStyleCancel
                                                                                        handler:nil]];
                                                [self presentViewController:alert animated:YES completion:nil];
                                              } else {
                                                [theText[kTextVoiceMessageKey] getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                                                  if ( ! error ) {
                                                    MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
                                                    picker.mailComposeDelegate = self;
                                                    
                                                    [picker setSubject:@"Shared Voice Message"];
                                                    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                                                    [dateFormatter setDateFormat:@"h_mma_MMM_d_YYYY"];
                                                    
                                                    NSString *fileName = [NSString stringWithFormat:@"VoiceMessage_%@.wav", [dateFormatter stringFromDate:theText[kMyCreatedAtKey]]];
                                                    [picker addAttachmentData:data mimeType:@"audio/x-wav" fileName:fileName];
                                                    
                                                    [self presentViewController:picker animated:YES completion:NULL];
                                                    
                                                  } else {
                                                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                                                                   message:@"Unable to download voice message. Please try later."
                                                                                                            preferredStyle:UIAlertControllerStyleAlert];
                                                    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                                                              style:UIAlertActionStyleCancel
                                                                                            handler:nil]];
                                                    [self presentViewController:alert
                                                                       animated:YES
                                                                     completion:nil];
                                                  }
                                                }];
                                              }
                                            }]];
                      
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
  }
  
}

-(void)handleDismissPhotoDetail {
  [self dismissViewControllerAnimated:YES completion:NULL];
}

-(void)takePhotoButtonPressed {
  UIImagePickerController *imgPicker = [[UIImagePickerController alloc] init];
  imgPicker.delegate = self;
  if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
    imgPicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    [self presentViewController:imgPicker animated:NO completion:NULL];
  } else {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:@"Sorry, your device is unable to take photos."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [self presentViewController:alert
                       animated:YES
                     completion:nil];
  }
  
}

-(void)choosePhotoButtonPressed {
  UIImagePickerController *imgPicker = [[UIImagePickerController alloc] init];
  imgPicker.delegate = self;
  if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
    imgPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:imgPicker animated:NO completion:NULL];
  } else {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:@"Sorry, your device does not support photos."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [self presentViewController:alert
                       animated:YES
                     completion:nil];
    
  }
  
}

#pragma mark Image Picker functions
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
  [UIApplication sharedApplication].statusBarHidden = NO;
  
  UIImage *chosenImage = [info objectForKey:UIImagePickerControllerOriginalImage];
  
  CLImageEditor *editor = [[CLImageEditor alloc] initWithImage:chosenImage];
  editor.delegate = self;
  [picker presentViewController:editor animated:YES completion:nil];
  
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
  [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma CLImageEditorDelegate
- (void)imageEditor:(CLImageEditor*)editor didFinishEdittingWithImage:(UIImage*)image {
  // Handle the result image here
  UIImage *theImage =[kAppDelegate scaleAndRotateImage:image maxResolution:512.f];
  
  self.photoToSend = theImage;
  
  [self configureAddButton];
  
  [self dismissViewControllerAnimated:YES completion:NULL];
  
}

- (void)imageEditorDidCancel:(CLImageEditor*)editor {
  [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark SavedMessagesDelegate methods
-(void)savedMessageSelected: (NSString*)savedMessage {
  self.messageTextView.internalTextView.text = savedMessage;
  [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)dismiss {
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark TTTAtributedLabelDelegate
- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
  
  if ([[UIApplication sharedApplication] canOpenURL:url]) {
    // use default behavior
    [[UIApplication sharedApplication] openURL:url];
  }
  
}

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithPhoneNumber:(NSString *)phoneNumber {
  NSString *message = [NSString stringWithFormat:@"Call %@?", phoneNumber];
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                 message:message
                                                          preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:@"Call"
                                            style:UIAlertActionStyleDefault
                                          handler:^(UIAlertAction * _Nonnull action) {
                                            NSURL *URLToDial = [NSURL URLWithString:[NSString stringWithFormat:@"tel:%@", phoneNumber]];
                                            [[UIApplication sharedApplication] openURL:URLToDial];
                                            }]];
  [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                            style:UIAlertActionStyleCancel
                                          handler:nil]];
  [self presentViewController:alert animated:YES completion:nil];
}

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithAddress:(NSDictionary *)addressComponents {
  NSString *string = ABCreateStringWithAddressDictionary(addressComponents, NO);
  NSString *locationQuery;
  NSURL *locationURL;
  
  if ( [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"comgooglemaps://"]] ) {
    // Try Google maps
    locationQuery = [NSString stringWithFormat:@"comgooglemaps://?q=%@",[string stringByReplacingOccurrencesOfString:@" " withString:@"+"]];
    locationQuery = [locationQuery stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    locationURL = [NSURL URLWithString:locationQuery];
  } else {
    // else use Apple maps
    locationQuery = [NSString stringWithFormat:@"http://maps.apple.com/?q=%@", [string stringByReplacingOccurrencesOfString:@" " withString:@"+"]];
    locationQuery = [locationQuery stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    locationURL = [NSURL URLWithString:locationQuery];
  }
  
  [[UIApplication sharedApplication] openURL:locationURL];
  
}

#pragma mark Record delegate methods
-(void)recordingComplete:(NSDictionary *)voiceMessageDictionary {
  [self.textService sendTextMessage:@"" withPhoto:nil andVoiceMessage:voiceMessageDictionary];
  
  [self.recordVC willMoveToParentViewController:nil];
  [self.recordVC.view removeFromSuperview];
  [self.recordVC removeFromParentViewController];
  
  self.recordVC = nil;
  
  [self updateOverlays];
  
  self.navigationItem.rightBarButtonItem.enabled = YES;
  [self.blockingView removeFromSuperview];
}

-(void)recordingCancelled {
  [self.recordVC willMoveToParentViewController:nil];
  [self.recordVC.view removeFromSuperview];
  [self.recordVC removeFromParentViewController];
  
  self.recordVC = nil;
  self.navigationItem.rightBarButtonItem.enabled = YES;
  [self.blockingView removeFromSuperview];
  
}

-(AVAudioSessionPortOverride)audioRoute {
  return _audioRoute;
}

#pragma mark Audio session listener

- (void)handleAudioSessionRouteChanged:(NSNotification *)notification {
  if ([self headsetPluggedIn]) {
    self.audioRouteButton.enabled = NO;
  } else {
    self.audioRouteButton.enabled = YES;
    __weak TextController *wSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      [[AVAudioSession sharedInstance] overrideOutputAudioPort: wSelf.audioRoute error:nil];
    });
  }
}

- (BOOL) headsetPluggedIn {
  
  AVAudioSessionRouteDescription* routeDescription = [[AVAudioSession sharedInstance] currentRoute];
  
  for(AVAudioSessionPortDescription* portDesc in routeDescription.outputs) {
    if ([portDesc.portName rangeOfString:@"Head"].location != NSNotFound) {
      return YES;
    }
  }
  
  return NO;
  
}

#pragma mark MFMailComposeViewControllerDelegate
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
  [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)handleApplicationWillResignActive {
  [self.view endEditing:YES];
}

@end
