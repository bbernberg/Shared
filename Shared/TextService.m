//
//  TextService.m
//  Shared
//
//  Created by Brian Bernberg on 4/5/12.
//  Copyright (c) 2012 BB Consulting. All rights reserved.
//
#import "TextService.h"
#import "Constants.h"
#import "Constants.h"
#import "MyReach.h"
#import "User.h"
#import "SHUtil.h"

#define kMaxFailedTexts 100
#define kMaxPhotos 100
#define kMaxVoiceMessages 50

static TextService *sharedInstance = nil;

@interface TextService()
@property (nonatomic) UIBackgroundTaskIdentifier sendBackgroundTaskId;
@property (nonatomic) BOOL sendingText;
@property (nonatomic) BOOL retrievingTexts;
@property (nonatomic) BOOL cacheRetrieved;
@property (nonatomic) BOOL networkRetrieved;
@property (nonatomic) BOOL networkCallSucceeded;

@end

@implementation TextService

+(TextService *)sharedInstance {
  if (!sharedInstance) {
    sharedInstance = [[TextService alloc] init];
  }
  return sharedInstance;
}

-(id)init {
  self = [super init];
  if (self) {
    
    //Load the arrays
    _texts = nil;
    _networkCallSucceeded = NO;
    [self retrieveTextsFromCache];
    
    _retrievingTexts = NO;
    _sendingText = NO;
    _cacheRetrieved = NO;
    _networkRetrieved = NO;
    
    self.sendBackgroundTaskId = UIBackgroundTaskInvalid;
    
    // register for notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLogout) name:kDidLogoutNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pinTexts) name:UIApplicationWillResignActiveNotification object:nil];
    
  }
  return self;
}

-(void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)pinTexts {
  [PFObject pinAllInBackground:self.texts];
}

- (void)unpinTexts {
  [PFObject conditionallyPinAllInBackground:self.texts];
}

#pragma mark other functions
- (void)retrieveTextsFromCache {
  PFQuery *query = [PFQuery queryForCurrentUsersWithClassName:kTextClass];
  [query fromLocalDatastore];
  [query orderByDescending:kMyCreatedAtKey];
  [query findObjectsInBackgroundWithBlock:^(NSArray *texts, NSError *error) {
    self.cacheRetrieved = YES;
    if ( !self.networkCallSucceeded ) {
      if ( ! error ) {
        [texts enumerateObjectsUsingBlock:^(PFObject *text, NSUInteger idx, BOOL *stop) {
          if ( ! text.objectId ) {
            text[kSendStatusKey] = kSendError;
            [text pinInBackground];
          } else {
            [text unpinInBackground];
          }
        }];
        self.texts = texts;
        [self sendNotificationForTexts:texts retrieveAction:RetrieveTextActionAll];
      } else {
        self.texts = @[];
      }
    }
  }];
}

-(void)retrieveTextsWithRetrieveAction:(RetrieveTextAction)retrieveAction {
  if (self.retrievingTexts == NO) {
    self.retrievingTexts = YES;
    
    // block if currently sending
    if (self.sendingText) {
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while(self.sendingText) {}
        [self doTextRetrieval:retrieveAction];
      });
    } else {
      [self doTextRetrieval:retrieveAction];
    }
  } else {
    NSLog(@"Already retrieving");
  }
}

- (PFQuery *)queryForTextsWithRetrieveAction:(RetrieveTextAction)retrieveAction local:(BOOL)local {
  NSUInteger textCount = self.texts.count;
  
  PFQuery *query = [PFQuery queryForCurrentUsersWithClassName:kTextClass];
  if ( local ) {
    [query fromLocalDatastore];
  }
  query.limit = kTextsPerPage;
  [query orderByDescending:kMyCreatedAtKey];
  
  switch (retrieveAction) {
    case RetrieveTextActionOlder:
      if (textCount > 0) {
        PFObject *theOldestText = [self oldestText];
        if (theOldestText) {
          [query whereKey:kMyCreatedAtKey lessThan:[theOldestText objectForKey:kMyCreatedAtKey]];
        }
      }
      break;
    case RetrieveTextActionNew:
      if (textCount > 0) {
        PFObject *theNewestText = [self newestText];
        if (theNewestText) {
          [query whereKey:kMyCreatedAtKey greaterThan:[theNewestText objectForKey:kMyCreatedAtKey]];
        }
      }
      break;
    default:
      break;
  }
  
  return query;
}

-(void)doTextRetrieval:(RetrieveTextAction)retrieveAction {
  
  PFQuery *query = [self queryForTextsWithRetrieveAction:retrieveAction local:NO];
  
  [query findObjectsInBackgroundWithBlock:^(NSArray *texts, NSError *error) {
    if (!error) {
      [PFObject pinAllInBackground:texts block:^(BOOL succeeded, NSError *error) {
        if ( succeeded ) {
          PFQuery *query = [self queryForTextsWithRetrieveAction:retrieveAction local:YES];
          [query findObjectsInBackgroundWithBlock:^(NSArray *texts, NSError *error) {
            self.networkRetrieved = YES;
            if ( !error ) {
              // The find succeeded.
              self.networkCallSucceeded = YES;
              [PFObject unpinAllWithObjectIdInBackground:self.texts];
              [PFObject pinAllWithoutObjectIdInBackground:texts];
              [self storeTexts:texts forRetrieveAction:retrieveAction];
              
              for (PFObject *text in texts) {
                if (text[kTextVoiceMessageKey]) {
                  PFFile *file = text[kTextVoiceMessageKey];
                  [file getDataInBackground];
                }
              }
              [self sendNotificationForTexts:texts retrieveAction:retrieveAction];
            } else {
              [self handleTextRetreivalError:error retrieveAction:retrieveAction];
            }
            self.retrievingTexts = NO;
          }];
        } else {
          [self handleTextRetreivalError:error retrieveAction:retrieveAction];
          self.retrievingTexts = NO;
        }
      }];
    } else {
      [self handleTextRetreivalError:error retrieveAction:retrieveAction];
      self.retrievingTexts = NO;
    }
  }];
}

- (void)handleTextRetreivalError:(NSError *)error retrieveAction:(RetrieveTextAction)retrieveAction {
  // Log details of the failure
  NSLog(@"Error: %@ %@", error, [error userInfo]);
  
  if ( error.code == kPFErrorCacheMiss ) {
    [[NSNotificationCenter defaultCenter] postNotificationName:kAllTextsReceivedNotification
                                                        object:nil
                                                      userInfo:@{kTextRetrievalActionKey : @(retrieveAction),
                                                                 kHideEarlierMessagesButtonKey : @"YES" }];
    
  } else {
    [[NSNotificationCenter defaultCenter] postNotificationName:kReceiveTextErrorNotification
                                                        object:nil
                                                      userInfo:nil];
  }
  
}
-(void)sendNotificationForTexts:(NSArray *)texts retrieveAction:(RetrieveTextAction)retrieveAction {
  
  BOOL lessThanFullPage = NO;
  if (retrieveAction == RetrieveTextActionAll) {
    lessThanFullPage = [texts count] < kTextsPerPage;
  }
  
  BOOL hideEarlierMessagesButton = ([texts count] < kTextsPerPage &&
                                    (retrieveAction == RetrieveTextActionAll || retrieveAction == RetrieveTextActionOlder)) ||
                                    lessThanFullPage;
  
  if (hideEarlierMessagesButton) {
    [[NSNotificationCenter defaultCenter] postNotificationName:kAllTextsReceivedNotification
                                                        object:self
                                                      userInfo:@{kTextRetrievalActionKey : @(retrieveAction),
                                                                 kHideEarlierMessagesButtonKey : @"YES" }];
  } else {
    [[NSNotificationCenter defaultCenter] postNotificationName:kAllTextsReceivedNotification
                                                        object:self
                                                      userInfo:@{kTextRetrievalActionKey : @(retrieveAction)}];
  }
}

- (void)storeTexts:(NSArray *)texts forRetrieveAction:(RetrieveTextAction)retrieveAction {
  switch (retrieveAction) {
    case RetrieveTextActionOlder:
      self.texts = [self.texts arrayByAddingObjectsFromArray:texts];
      break;
    case RetrieveTextActionNew:
      self.texts = [texts arrayByAddingObjectsFromArray:self.texts];
      break;
    case RetrieveTextActionAll:
    default:
      self.texts = texts;
      break;
  }
  
}

-(void)sendTextMessage:(NSString *)textMessage
             withPhoto:(UIImage *)theImage
       andVoiceMessage:(NSDictionary *)voiceMessageDictionary {
  PFObject *text = [PFObject versionedObjectWithClassName:kTextClass];
  [text setObject:[[User currentUser] userIDs] forKey:kUsersKey];
  [text setObject:textMessage forKey:kMessageKey];
  [text setObject:[User currentUser].myUserID forKey:kSenderKey];
  [text setObject:[User currentUser].partnerUserID forKey:kReceiverKey];
  [text setObject:kSendSuccess forKey:kSendStatusKey];
  [text setObject:[NSDate date] forKey:kMyCreatedAtKey];
  
  if (theImage) {
    NSData *imageData = UIImageJPEGRepresentation(theImage, 0.8f);
    PFFile *photoFile = [PFFile fileWithData:imageData];
    [photoFile saveInBackground];
    text[kTextPhotoKey] = photoFile;
    text[kTextPhotoWidthKey] = @(theImage.size.width);
    text[kTextPhotoHeightKey] = @(theImage.size.height);
    text[kTextLocalFilePathKey] = [self saveLocalFileData:imageData];
  }
  
  if (voiceMessageDictionary) {
    NSData *voiceMessageData = [NSData dataWithContentsOfURL:voiceMessageDictionary[kVoiceMessageURLKey]];
    PFFile *voiceMessageFile = [PFFile fileWithData:voiceMessageData];
    text[kTextVoiceMessageKey] = voiceMessageFile;
    text[kMessageKey] = voiceMessageDictionary[kVoiceMessageDurationKey];
    text[kTextLocalFilePathKey] = [self saveLocalFileData:voiceMessageData];
  }
  
  [self sendText:text isResend:NO];
}

- (void)sendText:(PFObject *)text isResend:(BOOL)isResend {
  self.sendingText = YES;
  
  [text pinInBackground];
  
  self.texts = [@[text] arrayByAddingObjectsFromArray:self.texts];
  NSInteger newRow = self.texts.count - 1;
  
  if ( isResend ) {
    [[NSNotificationCenter defaultCenter] postNotificationName:kInitialResendTextNotification object:nil];
  } else {
    [[NSNotificationCenter defaultCenter] postNotificationName:kInitialSendTextNotification
                                                        object:nil
                                                      userInfo:@{@"row": @(newRow)}];
  }
  
  // Request a background execution task
  self.sendBackgroundTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
    [[UIApplication sharedApplication] endBackgroundTask:self.sendBackgroundTaskId];
  }];
  
  [text saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
    if (!error) {
      if ( text[kTextLocalFilePathKey] ) {
        [[NSFileManager defaultManager] removeItemAtPath:pathInDocumentDirectory(text[kTextLocalFilePathKey]) error:nil];
      }
      
      // delay to allow first animation to complete
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSUInteger index = self.texts.count - [self.texts indexOfObject:text] - 1;
        [[NSNotificationCenter defaultCenter] postNotificationName:kSendTextSuccessNotification
                                                            object:nil
                                                          userInfo:@{kTextIndex: @(index) }];
      });
      
      // send push notification
      NSString *pushMessage = nil;
      if ( text[kGlympseURLKey] ) {
        pushMessage = [NSString stringWithFormat:@"%@ has sent a Glympse", [[User currentUser] myNameOrEmail]];
      } else if ([text[kMessageKey] isEqualToString:@""] && text[kTextPhotoKey] ) {
          pushMessage = [NSString stringWithFormat:@"%@ texted a picture.", [[User currentUser] myNameOrEmail]];
      } else if ( text[kTextVoiceMessageKey] ) {
        pushMessage = [NSString stringWithFormat:@"%@ sent a voice message.", [[User currentUser] myNameOrEmail]];
      } else {
        pushMessage = [NSString stringWithFormat:@"%@ - %@", [[User currentUser] myNameOrEmail], text[kMessageKey]];
      }
      NSDictionary *pushUserInfo = @{@"alert" : pushMessage,
                                     @"sound" : @"default",
                                     kPushTypeKey : kTextNotification,
                                     @"badge" : @"Increment"};
      
      [SHUtil sendPushNotification:pushUserInfo];
      
      if (text[kTextPhotoKey]) {
        [self deleteOverageForKey:kTextPhotoKey maxAllowed:kMaxPhotos];
      }
      if (text[kTextVoiceMessageKey]) {
        [self deleteOverageForKey:kTextVoiceMessageKey maxAllowed:kMaxVoiceMessages];
      }
      
    } else {
      text[kSendStatusKey] = kSendError;
      [text pinInBackground];
      
      [[NSNotificationCenter defaultCenter] postNotificationName:kSendTextErrorNotification
                                                          object:nil];
    }
    [[UIApplication sharedApplication] endBackgroundTask:self.sendBackgroundTaskId];
    self.sendingText = NO;
  }];
}

-(void)resendText:(PFObject *)text {
  self.sendingText = YES;

  NSMutableArray *texts = [NSMutableArray arrayWithArray:self.texts];
  [texts removeObject:text];
  [text unpinInBackground];
  self.texts = [NSArray arrayWithArray:texts];
  
  if ( text[kTextPhotoKey] ) {
    text[kTextPhotoKey] = [PFFile fileWithData:[NSData dataWithContentsOfFile:pathInDocumentDirectory(text[kTextLocalFilePathKey])]];
  }
  
  if ( text[kTextVoiceMessageKey] ) {
    text[kTextVoiceMessageKey] = [PFFile fileWithData:[NSData dataWithContentsOfFile:pathInDocumentDirectory(text[kTextLocalFilePathKey])]];
  }
  
  text[kSendStatusKey] = kSendSuccess;
  [self sendText:text isResend:YES];
}

-(void)deleteText:(PFObject *)text {
  [text unpinInBackground];
  [text deleteEventually];
  if ( text[kTextLocalFilePathKey] ) {
    [[NSFileManager defaultManager] removeItemAtPath:pathInDocumentDirectory(text[kTextLocalFilePathKey]) error:nil];
  }

  NSUInteger index = self.texts.count - [self.texts indexOfObject:text] - 1;
  NSMutableArray *texts = [NSMutableArray arrayWithArray:self.texts];
  [texts removeObject:text];
  self.texts = [NSArray arrayWithArray:texts];
  [[NSNotificationCenter defaultCenter] postNotificationName:kDeleteTextSuccessNotification
                                                      object:self
                                                    userInfo:@{kTextIndex: @(index)}];
  
}

#pragma mark Utility functions
-(PFObject *)oldestText {
  for (PFObject *text in [self.texts reverseObjectEnumerator]) {
    if ( [text[kSendStatusKey] isEqualToString:kSendSuccess] && text.objectId ) {
      return text;
    }
  }
  return nil;
}

-(PFObject *)newestText {
  for (PFObject *text in self.texts) {
    if ([text[kSendStatusKey] isEqualToString:kSendSuccess] && text.objectId) {
      return text;
    }
  }
  return nil;
}

-(BOOL)array:(NSArray *)array containsText:(PFObject *)text {
  
  NSUInteger index = [array indexOfObjectPassingTest:^BOOL(PFObject *currentText, NSUInteger idx, BOOL *stop) {
    return [currentText.objectId isEqualToString:text.objectId];
  }];
  
  return (index != NSNotFound);
}

//Gets the file data from the documents directory
- (NSData *)retrieveLocalFileDataFromPath:(NSString *)path {
  return [[NSData alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path]];
}

//Saves the file data to the documents directory
- (NSString *)saveLocalFileData:(NSData*)fileData {
  NSString *folder = pathInDocumentDirectory(@"LocalFiles");
  //if the folder doesn't exist, we have to create one
  if (![[NSFileManager defaultManager] fileExistsAtPath:folder]) {
    [[NSFileManager defaultManager] createDirectoryAtPath:folder withIntermediateDirectories:NO attributes:nil error:nil];
  }
  
  NSString *fileUrl = [NSString stringWithFormat:@"LocalFiles/%@.data", [NSString stringWithFormat:@"%f", [NSDate timeIntervalSinceReferenceDate]]];
  [fileData writeToFile:pathInDocumentDirectory(fileUrl) atomically:YES];
  return fileUrl;
}

- (PFObject *)textWithGlympseURL:(NSString *)url {
  __block PFObject *textWithURL = nil;
  
  [self.texts enumerateObjectsUsingBlock:^(PFObject *text, NSUInteger idx, BOOL *stop) {
    if ([text[kGlympseURLKey] isEqual:url]) {
      textWithURL = text;
      *stop = YES;
    }
  }];
  
  return textWithURL;
}

#pragma mark delete overage texts
-(void)deleteOverageForKey:(NSString *)key maxAllowed:(NSInteger)maxAllowed {
  PFQuery *query = [PFQuery queryWithClassName:kTextClass];
  
  [query whereKey:kSenderKey equalTo:[User currentUser].myUserID];
  [query whereKeyExists:key];
  query.skip = maxAllowed;
  [query orderByDescending:@"createdAt"];
  
  [query findObjectsInBackgroundWithBlock:^(NSArray *texts, NSError *error) {
    if (!error) {
      // The find succeeded.
      for (PFObject *text in texts) {
        [text deleteEventually];
      }
    }
  }];
}

#pragma mark logout handler
-(void)handleLogout {
  sharedInstance = nil;
}

@end
