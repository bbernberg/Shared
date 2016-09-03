//
//  User.m
//  Shared
//
//  Created by Brian Bernberg on 9/24/12.
//  Copyright (c) 2012 BB Consulting. All rights reserved.
//

#import "User.h"
#import <Parse/Parse.h>
#import "Constants.h"
#import "PF+SHExtend.h"
#import "PSPDFAlertView.h"
#import "LTHPasscodeViewController.h"

static User *currentUser = nil;

@interface User ()
@property (nonatomic, strong) PFObject *info;
@property (nonatomic, readonly) NSMutableDictionary *partnerDict;
@property (nonatomic, readonly) NSString *partnerKey;
@property (nonatomic, strong) NSFileWrapper *fbSymLink;
@end

@implementation User

+(User *)currentUser {
  
  return currentUser;
  
}

+(void)initWithUserID:(NSString *)userID {
  if (userID) {
    currentUser = [[User alloc] initWithUserID:userID];
  }
}

-(id)initWithUserID:(NSString *)userID {
  self = [super init];
  if (self) {
    NSData *data = [NSData dataWithContentsOfFile: [User userPathForUserID:userID]];
    if ( data ) {
      NSKeyedUnarchiver *decoder= [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
      self.info = [decoder decodeObjectForKey:kUserInfoKey];
      [decoder finishDecoding];
      if (self.info.objectId) {
        self.validData = YES;
      } else {
        self.validData = NO;
      }
      
    } else {
      self.validData = NO;
      self.info = nil;
    }
    
    [self updatePFInstallationForUser];
  }
  
  return self;
}

+(void)newUserWithUserID:(NSString *)userID {
  [User initWithUserID:userID];
  currentUser.info = [PFObject versionedObjectWithClassName:kUserInfoClass];
  currentUser.validData = YES;
}

-(void)saveUser {
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    if ( currentUser.myUserID ) {
      // store locally
      // only save if info's already been stored to network
      if ( currentUser.info.objectId ) {
        NSMutableData *data = [NSMutableData data];
        NSKeyedArchiver *aCoder = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
        [aCoder encodeObject:currentUser.info forKey:kUserInfoKey];
        
        [aCoder finishEncoding];
        [data writeToFile:[currentUser userPath] atomically:YES];
        
        if ( currentUser.myFBID && ! [currentUser.myFBID isEqualToString:currentUser.myUserID] ) {
          // Create symbolic link using FBID
          NSURL *url = [NSURL fileURLWithPath:[currentUser userPath] isDirectory:NO];
          NSFileWrapper *symLink = [[NSFileWrapper alloc] initSymbolicLinkWithDestinationURL:url];
          [symLink writeToURL:[NSURL fileURLWithPath:[User userPathForUserID:currentUser.myFBID] isDirectory:NO]
                      options:0
          originalContentsURL:nil
                        error:nil];
        }
        
        if ( currentUser.myUserEmail && ! [currentUser.myUserEmail isEqualToString:currentUser.myUserID] ) {
          // Create symbolic link using user email
          NSURL *url = [NSURL fileURLWithPath:[currentUser userPath] isDirectory:NO];
          NSFileWrapper *symLink = [[NSFileWrapper alloc] initSymbolicLinkWithDestinationURL:url];
          [symLink writeToURL:[NSURL fileURLWithPath:[User userPathForUserID:currentUser.myUserEmail] isDirectory:NO]
                      options:0
          originalContentsURL:nil
                        error:nil];
        }
        
      }
      // store to network
      [currentUser saveToNetwork];
      [[self class] storeAppGroupValues];
    }
  });
}

+ (void)storeAppGroupValues {
  static NSUserDefaults *defaults = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    defaults = [[NSUserDefaults alloc] initWithSuiteName:kSharedAppGroup];
  });
  
  if ( currentUser ) {
    [defaults setBool:YES forKey:kAppGroupLoggedInKey];
    [defaults setBool:currentUser.hasPartner forKey:kAppGroupHasPartnerKey];
    if ( currentUser.hasPartner ) {
      NSString *partnerName = [[[User currentUser] partnerName] length] > 0 ? [[User currentUser] partnerName] : [[User currentUser] partnerUserEmail];
      [defaults setObject:partnerName forKey:kAppGroupPartnerNameKey];
      if ( currentUser.partnerSmallPicture ) {
        NSData *imageData = UIImagePNGRepresentation(currentUser.partnerSmallPicture);
        [defaults setObject:imageData forKey:kAppGroupPartnerPictureKey];
      } else {
        [defaults removeObjectForKey:kAppGroupPartnerPictureKey];
      }
      
      if ( currentUser.partnerPhoneNumber ) {
        [defaults setObject:currentUser.partnerPhoneNumber forKey:kAppGroupPartnerCallNumberKey];
      } else {
        [defaults removeObjectForKey:kAppGroupPartnerCallNumberKey];
      }
      if ( currentUser.partnerFacetime ) {
        [defaults setObject:currentUser.partnerFacetime forKey:kAppGroupPartnerFaceTimeNumberKey];
      } else {
        [defaults removeObjectForKey:kAppGroupPartnerFaceTimeNumberKey];
      }
    } else {
      [defaults removeObjectForKey:kAppGroupPartnerNameKey];
      [defaults removeObjectForKey:kAppGroupPartnerPictureKey];
      [defaults removeObjectForKey:kAppGroupPartnerCallNumberKey];
      [defaults removeObjectForKey:kAppGroupPartnerFaceTimeNumberKey];
    }
  } else {
    [defaults setBool:NO forKey:kAppGroupLoggedInKey];
    [defaults removeObjectForKey:kAppGroupHasPartnerKey];
    [defaults removeObjectForKey:kAppGroupPartnerNameKey];
    [defaults removeObjectForKey:kAppGroupPartnerPictureKey];
    [defaults removeObjectForKey:kAppGroupPartnerCallNumberKey];
    [defaults removeObjectForKey:kAppGroupPartnerFaceTimeNumberKey];
  }
  
  [defaults synchronize];
}
  
+(NSString *)userPathForUserID:(NSString *)userID {
  return pathInDocumentDirectory([NSString stringWithFormat:@"%@_userInfo.data", userID]);
}

-(NSString *)userPath {
  @try {
    return [User userPathForUserID:self.myUserID];
  } @catch (NSException *e) {
    return nil;
  }
}

-(void)fetchUserInBackground {
  NSString *partnerUserID;
  @try {
    partnerUserID = self.info[kPartnerUserIDKey];
  }
  @catch (NSException *exception) {
    partnerUserID = nil;
  }
  
  NSMutableArray *queries = [NSMutableArray array];
  if ( self.myUserEmail ) {
    PFQuery *query = [PFQuery queryWithClassName:kUserInfoClass];
    [query whereKey:kMyUserEmailKey equalTo:self.myUserEmail];
    [queries addObject:query];
  }
  if ( self.myFBID ) {
    PFQuery *query = [PFQuery queryWithClassName:kUserInfoClass];
    [query whereKey:kMyFBIDKey equalTo:self.myFBID];
    [queries addObject:query];
  }
  PFQuery *query = [PFQuery orQueryWithSubqueries:queries];
  [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
    if (!error) {
      self.info = object;
      self.validData = YES;
      if ( partnerUserID && ![partnerUserID isEqualToString:self.partnerUserID] ) {
        PSPDFAlertView *alert=[[PSPDFAlertView alloc] initWithTitle:@"Partner Has Changed" message:@"Please log in again"];
        [alert setCancelButtonWithTitle:@"OK" block:nil];
        [alert show];
        [[NSNotificationCenter defaultCenter] postNotificationName:kShouldLogoutNotification object:nil];
      } else {
        [self getMyData];
        [[NSNotificationCenter defaultCenter] postNotificationName:kUserDataFetchedNotification object:nil];
      }
    }
  }];
}

- (void)fetchUserWithCompletionBlock:(void (^)(NSNumber *))completionBlock {
  if ( self.myUserEmail ) {
    [self fetchUserWithKey:kMyUserEmailKey value:self.myUserEmail completionBlock:completionBlock];
  } else {
    [self fetchUserWithKey:kMyFBIDKey value:self.myFBID completionBlock:completionBlock];
  }
}

- (void)fetchUserWithUserEmail:(NSString *)userEmail completionBlock:(void (^)(NSNumber *))completionBlock {
  [self fetchUserWithKey:kMyUserEmailKey value:userEmail completionBlock:completionBlock];
}

-(void)fetchUserWithKey:(NSString *)key
                  value:(NSString *)value
        completionBlock:(void (^)(NSNumber *))completionBlock {
  NSString *partnerUserID;
  @try {
    partnerUserID = self.info[kPartnerUserIDKey];
  }
  @catch (NSException *exception) {
    partnerUserID = nil;
  }
  
  PFQuery *query = [PFQuery queryWithClassName:kUserInfoClass];
  [query whereKey:key equalTo:value];
  [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
    if (!error) {
      self.info = object;
      self.validData = YES;
      if ( partnerUserID && ![partnerUserID isEqualToString:self.partnerUserID] ) {
        PSPDFAlertView *alert=[[PSPDFAlertView alloc] initWithTitle:@"Partner Has Changed" message:@"Please log in again"];
        [alert setCancelButtonWithTitle:@"OK" block:nil];
        [alert show];
        [[NSNotificationCenter defaultCenter] postNotificationName:kShouldLogoutNotification object:nil];
      }
      completionBlock(@(kFetchUserOK));
      [[NSNotificationCenter defaultCenter] postNotificationName:kUserDataFetchedNotification object:nil];
      
    } else if (error.code == kPFErrorObjectNotFound) {
      [User newUserWithUserID:value];
      completionBlock(@(kFetchUserNewUser));
      [[NSNotificationCenter defaultCenter] postNotificationName:kUserDataFetchedNotification object:nil];
    } else {
      completionBlock(@(kFetchUserError));
    }
  }];
}

-(void)saveToNetwork {
  __block UIBackgroundTaskIdentifier saveBackgroundTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
    [[UIApplication sharedApplication] endBackgroundTask:saveBackgroundTaskId];
  }];
  
  [self.info saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
    [[UIApplication sharedApplication] endBackgroundTask:saveBackgroundTaskId];
  }];
}


+(void)logout {
  [[NSFileManager defaultManager] removeItemAtPath:[User userPathForUserID:currentUser.myUserID] error:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:currentUser];
  
  currentUser = nil;
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:kLoggedInUserIDKey];
  [[NSUserDefaults standardUserDefaults] synchronize];
  [LTHPasscodeViewController sharedUser].userID = nil;
  [[self class] storeAppGroupValues];
}

- (BOOL)hasPartner {
  return ( self.partnerUserID.length > 0 && self.myUserID);
}

- (NSArray *)userIDs {
  NSMutableArray *IDs = [NSMutableArray array];
  if (self.myFBID) {
    [IDs addObject:self.myFBID];
  }
  if (self.myUserEmail) {
    [IDs addObject:self.myUserEmail];
  }
  if (self.partnerFBID) {
    [IDs addObject:self.partnerFBID];
  }
  if (self.partnerUserEmail) {
    [IDs addObject:self.partnerUserEmail];
  }
  return IDs;
}

- (NSString *)myUserID {
  if (self.myUserEmail.length > 0) {
    return self.myUserEmail;
  } else {
    return self.myFBID;
  }
}

- (NSArray *)myUserIDs {
  NSMutableArray* ids = [NSMutableArray array];
  if (self.myFBID.length > 0) {
    [ids addObject:self.myFBID];
  }
  if (self.myUserEmail.length > 0) {
    [ids addObject:self.myUserEmail];
  }
  
  return ids;
}

-(UIImage *)myPicture {
#if DEBUG
#ifdef kUseDummyData
  return [UIImage imageNamed: @"Man_Profile"];
#endif
#endif
  
  UIImage *ret = [UIImage imageWithContentsOfFile:pathInDocumentDirectory([NSString stringWithFormat:@"%@_picture.data",self.myUserID])];
  if (ret) {
    return ret;
  } else {
    return [UIImage imageNamed:@"man"];
  }
}

-(void)setMyPicture:(UIImage *)myImage {
  NSData *pictureData = UIImagePNGRepresentation(myImage);
  [pictureData writeToFile:pathInDocumentDirectory([NSString stringWithFormat:@"%@_picture.data",self.myUserID]) atomically:YES];
  self.info[kMyPictureFileKey] = [PFFile fileWithData:pictureData];
  
  // save small copy also
  UIImage* smallPicture = [kAppDelegate scaleAndRotateImage:myImage maxResolution:100];
  NSData* smallPictureData = UIImagePNGRepresentation(smallPicture);
  [smallPictureData writeToFile:pathInDocumentDirectory([NSString stringWithFormat:@"%@_small_picture.data",self.myUserID]) atomically:YES];
  self.info[kMySmallPictureFileKey] = [PFFile fileWithData:smallPictureData];
}

-(BOOL)myPictureExists {
  return ([UIImage imageWithContentsOfFile:pathInDocumentDirectory([NSString stringWithFormat:@"%@_picture.data",self.myUserID])] != nil);
}

- (BOOL)myPictureFileExists {
  BOOL ret;
  @try {
    ret = (self.info[kMyPictureFileKey] != nil);
  }
  @catch (NSException *e) {
    ret = NO;
  }
  @finally {
    return ret;
  }
}

- (void)refreshMyPictureInBackground {
  if ([self myPictureFileExists]) {
    PFFile *pictureFile = self.info[kMyPictureFileKey];
    [pictureFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
      if ( !error ) {
        self.myPicture = [UIImage imageWithData:data];
      }
    }];
  }
}

- (void)refreshMyPicture {
  if ([self myPictureFileExists]) {
    PFFile *pictureFile = self.info[kMyPictureFileKey];
    NSData *pictureData = [pictureFile getData];
    if ( pictureData ) {
      self.myPicture = [UIImage imageWithData:pictureData];
    }
  }
}

- (UIImage *)mySmallPicture {
  
#if DEBUG
#ifdef kUseDummyData
  return [UIImage imageNamed: @"Man_Profile"];
#endif
#endif
  
  UIImage *ret = [UIImage imageWithContentsOfFile:pathInDocumentDirectory([NSString stringWithFormat:@"%@_small_picture.data",self.myUserID])];
  if (ret) {
    return ret;
  } else {
    return [UIImage imageNamed:@"man"];
  }
  
}

-(UIImage *)partnerPicture {
#if DEBUG
#ifdef kUseDummyData
  return [UIImage imageNamed: @"Woman_Profile"];
#endif
#endif
  
  UIImage *ret = [UIImage imageWithContentsOfFile:pathInDocumentDirectory([NSString stringWithFormat:@"%@_picture.data",self.partnerUserID])];
  
  if (ret) {
    return ret;
  } else {
    return [UIImage imageNamed:@"man"];
  }
}

-(BOOL)partnerPictureExists {
  return ([UIImage imageWithContentsOfFile:pathInDocumentDirectory([NSString stringWithFormat:@"%@_picture.data",self.partnerUserID])] != nil);
}

-(void)setPartnerPicture:(UIImage *)partnerImage {
  [UIImagePNGRepresentation(partnerImage) writeToFile:pathInDocumentDirectory([NSString stringWithFormat:@"%@_picture.data",self.partnerUserID]) atomically:YES];
  
  // save small copy also
  UIImage* smallPicture = [kAppDelegate scaleAndRotateImage:partnerImage maxResolution:100];
  NSData* smallPictureData = UIImagePNGRepresentation(smallPicture);
  [smallPictureData writeToFile:pathInDocumentDirectory([NSString stringWithFormat:@"%@_small_picture.data",self.partnerUserID]) atomically:YES];
}

- (UIImage *)partnerSmallPicture {
#if DEBUG
#ifdef kUseDummyData
  return [UIImage imageNamed: @"Woman_Profile"];
#endif
#endif
  
  UIImage *ret = [UIImage imageWithContentsOfFile:pathInDocumentDirectory([NSString stringWithFormat:@"%@_small_picture.data",self.partnerUserID])];
  
  if (ret) {
    return ret;
  } else {
    return [UIImage imageNamed:@"man"];
  }
}

-(BOOL)partnerIsFBLogin {
  if (!self.partnerFBID) {
    return NO;
  }
  return [self.partnerUserID isEqualToString:self.partnerFBID];
}

-(void)updatePFInstallationForUser {
  BOOL installChanged = ! [[PFInstallation currentInstallation][kInstallationUserIDsKey] isEqualToArray:self.myUserIDs] ||
                        ! [[PFInstallation currentInstallation][kInstallationPartnerUserIDKey] isEqualToString:self.partnerUserID];
  if ( [self.myUserIDs count] > 0 && installChanged) {
    
    [PFInstallation currentInstallation][kInstallationUserIDsKey] = self.myUserIDs;
    if ( self.partnerUserID ) {
      [PFInstallation currentInstallation][kInstallationPartnerUserIDKey] = self.partnerUserID;
    }
    [[PFInstallation currentInstallation] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
      if (!succeeded) {
        [[PFInstallation currentInstallation] saveEventually];
      }
    }];
    
  }
}

-(PFQuery *)partnerPushQuery {
  if (self.partnerUserID.length > 0) {
    PFQuery *query = [PFInstallation query];
    [query whereKey:kInstallationUserIDsKey equalTo:self.partnerUserID];
    [query whereKey:kInstallationPartnerUserIDKey containedIn:self.myUserIDs];
    
    return query;
  }
  return nil;
}

#pragma mark getters & setters

-(NSString *)myName {
#if DEBUG
#ifdef kUseDummyData
  return @"Jim Lee";
#endif
#endif
  
  NSString *ret;
  @try {
    ret = self.info[kMyNameKey];
  }
  @catch (NSException *exception) {
    ret = nil;
  }
  @finally {
    return ret;
  }
}

-(void)setMyName:(NSString *)myName {
  if (myName) {
    self.info[kMyNameKey] = myName;
  } else {
    [self.info removeObjectForKey:kMyNameKey];
  }
}

-(NSString *)myFBID {
  NSString *ret;
  @try {
    ret = self.info[kMyFBIDKey];
  }
  @catch (NSException *exception) {
    ret = nil;
  }
  @finally {
    return ret;
  }
  
}

-(void)setMyFBID:(NSString *)myFBID {
  if (myFBID) {
    self.info[kMyFBIDKey] = myFBID;
  } else {
    [self.info removeObjectForKey:myFBID];
  }
  
}

-(NSString *)myFBName {
  NSString *ret;
  @try {
    ret = self.info[kMyFBNameKey];
  }
  @catch (NSException *exception) {
    ret = nil;
  }
  @finally {
    return ret;
  }
  
}

-(void)setMyFBName:(NSString *)myFBName {
  if (myFBName) {
    self.info[kMyFBNameKey] = myFBName;
  } else {
    [self.info removeObjectForKey:kMyFBNameKey];
  }
}

-(NSString *)myUserEmail {
  NSString *ret;
  @try {
    ret = self.info[kMyUserEmailKey];
  }
  @catch (NSException *exception) {
    ret = nil;
  }
  @finally {
    return ret;
  }
  
  return self.info[kMyUserEmailKey];
}

-(void)setMyUserEmail:(NSString *)myUserEmail {
  if (myUserEmail) {
    self.info[kMyUserEmailKey] = myUserEmail;
  } else {
    [self.info removeObjectForKey:kMyUserEmailKey];
  }
  
}

-(NSString *)myGoogleDriveUserEmail {
  NSString *ret;
  @try {
    ret = self.info[kMyGoogleDriveUserEmailKey];
  }
  @catch (NSException *exception) {
    ret = nil;
  }
  @finally {
    return ret;
  }
  
}

-(void)setMyGoogleDriveUserEmail:(NSString *)myGoogleDriveUserEmail {
  if (myGoogleDriveUserEmail) {
    self.info[kMyGoogleDriveUserEmailKey] = myGoogleDriveUserEmail;
  } else {
    [self.info removeObjectForKey:kMyGoogleDriveUserEmailKey];
  }
}

-(NSString *)myGoogleCalendarUserEmail {
  NSString *ret;
  @try {
    ret = self.info[kMyGoogleCalendarUserEmailKey];
  }
  @catch (NSException *exception) {
    ret = nil;
  }
  @finally {
    return ret;
  }
  
}

-(void)setMyGoogleCalendarUserEmail:(NSString *)myGoogleCalendarUserEmail {
  if (myGoogleCalendarUserEmail) {
    self.info[kMyGoogleCalendarUserEmailKey] = myGoogleCalendarUserEmail;
  } else {
    [self.info removeObjectForKey:kMyGoogleCalendarUserEmailKey];
  }
}

-(NSString *)partnerUserID {
  NSString *ret;
  @try {
    ret = self.info[kPartnerUserIDKey];
  }
  @catch (NSException *exception) {
    ret = nil;
  }
  @finally {
    return ret;
  }
  
}

-(void)setPartnerUserID:(NSString *)partnerUserID {
  if (partnerUserID) {
    self.info[kPartnerUserIDKey] = partnerUserID;
    
    // configure partners dictionary
    if (self.info[kPartnersKey] == nil) {
      self.info[kPartnersKey] = [NSMutableDictionary dictionary];
    }
    if (self.info[kPartnersKey][self.partnerKey] == nil) {
      self.info[kPartnersKey][self.partnerKey] = [NSMutableDictionary dictionary];
    }
    
  } else {
    [self.info removeObjectForKey:kPartnerUserIDKey];
  }
  
}

-(NSMutableDictionary *)partnerDict {
  @try {
    if (self.partnerUserID) {
      return self.info[kPartnersKey][self.partnerKey];
    } else {
      return nil;
    }
  }
  @catch (NSException *exception) {
    return nil;
  }
}

-(NSString *)partnerName {
#if DEBUG
#ifdef kUseDummyData
  return @"Anne Jones";
#endif
#endif
  
  return self.partnerDict[kPartnerNameKey];
}

-(void)setPartnerName:(NSString *)partnerName {
  if (partnerName) {
    self.partnerDict[kPartnerNameKey] = partnerName;
  } else {
    [self.partnerDict removeObjectForKey:kPartnerNameKey];
  }
}

-(NSString *)partnerFBID {
  return self.partnerDict[kPartnerFBIDKey];
}

-(void)setPartnerFBID:(NSString *)partnerFBID {
  if (partnerFBID) {
    self.partnerDict[kPartnerFBIDKey] = partnerFBID;
  } else {
    [self.partnerDict removeObjectForKey:kPartnerFBIDKey];
  }
}

-(NSString *)partnerFBName {
  return self.partnerDict[kPartnerFBNameKey];
}

-(void)setPartnerFBName:(NSString *)partnerFBName {
  if (partnerFBName) {
    self.partnerDict[kPartnerFBNameKey] = partnerFBName;
  } else {
    [self.partnerDict removeObjectForKey:kPartnerFBNameKey];
  }
}

-(NSString *)partnerUserEmail {
  return self.partnerDict[kPartnerUserEmailKey];
}

-(void)setPartnerUserEmail:(NSString *)partnerUserEmail {
  if (partnerUserEmail) {
    self.partnerDict[kPartnerUserEmailKey] = partnerUserEmail;
  } else {
    [self.partnerDict removeObjectForKey:kPartnerUserEmailKey];
  }
}

-(NSMutableArray *)partnerPhoneNumbers {
  if (!self.partnerDict[kPartnerPhoneNumbersKey]) {
    self.partnerDict[kPartnerPhoneNumbersKey] = [NSMutableArray array];
  }
  return self.partnerDict[kPartnerPhoneNumbersKey];
}

-(void)setPartnerPhoneNumbers:(NSMutableArray *)partnerPhoneNumbers {
  self.partnerDict[kPartnerPhoneNumbersKey] = partnerPhoneNumbers;
}

-(NSMutableArray *)partnerEmailAddresses {
  if (!self.partnerDict[kPartnerEmailAddressesKey]) {
    self.partnerDict[kPartnerEmailAddressesKey] = [NSMutableArray array];
  }
  return self.partnerDict[kPartnerEmailAddressesKey];
}

-(void)setPartnerEmailAddresses:(NSMutableArray *)partnerEmailAddresses {
  self.partnerDict[kPartnerEmailAddressesKey] = partnerEmailAddresses;
}

-(NSDictionary *)partnerEmailAddress {
  return self.partnerDict[kPartnerEmailAddressKey];
}

-(void)setPartnerEmailAddress:(NSDictionary *)partnerEmailAddress {
  if (partnerEmailAddress) {
    self.partnerDict[kPartnerEmailAddressKey] = partnerEmailAddress;
  } else {
    [self.partnerDict removeObjectForKey:kPartnerEmailAddressKey];
  }
}

-(NSDictionary *)partnerText {
  return self.partnerDict[kPartnerTextKey];
}

-(void)setPartnerText:(NSDictionary *)partnerText {
  if (partnerText) {
    self.partnerDict[kPartnerTextKey] = partnerText;
  } else {
    [self.partnerDict removeObjectForKey:kPartnerTextKey];
  }
}

- (NSString *)partnerPhoneNumber {
  if ( self.partnerDict[kPartnerPhoneNumberKey] ) {
    return self.partnerDict[kPartnerPhoneNumberKey];
  } else if ( [self.partnerDict[kPartnerPhoneNumbersKey] count] > 0 ) {
    self.partnerPhoneNumber = [self.partnerDict[kPartnerPhoneNumbersKey] firstObject][kContactEntryKey];
    return [self.partnerDict[kPartnerPhoneNumbersKey] firstObject][@"contactEntry"];
  } else {
    return nil;
  }
}

- (void)setPartnerPhoneNumber:(NSString *)partnerPhoneNumber {
  if ( partnerPhoneNumber ) {
    self.partnerDict[kPartnerPhoneNumberKey] = partnerPhoneNumber;
  } else {
    [self.partnerDict removeObjectForKey:kPartnerPhoneNumberKey];
  }
}

-(NSString *)partnerFacetime {
  if ( [self.partnerDict[kPartnerFacetimeKey] isKindOfClass:[NSDictionary class]] ) {
    self.partnerDict[kPartnerFacetimeKey] = self.partnerDict[kPartnerFacetimeKey][kContactEntryKey];
  }
  return self.partnerDict[kPartnerFacetimeKey];
}

-(void)setPartnerFacetime:(NSString *)partnerFacetime {
  if (partnerFacetime) {
    self.partnerDict[kPartnerFacetimeKey] = partnerFacetime;
  } else {
    [self.partnerDict removeObjectForKey:kPartnerFacetimeKey];
  }
}

-(NSString *)partnerGoogleDriveUserEmail {
  return self.partnerDict[kPartnerGoogleDriveUserEmailKey];
}

-(void)setPartnerGoogleDriveUserEmail:(NSString *)partnerGoogleDriveUserEmail {
  if (partnerGoogleDriveUserEmail) {
    self.partnerDict[kPartnerGoogleDriveUserEmailKey] = partnerGoogleDriveUserEmail;
  } else {
    [self.partnerDict removeObjectForKey:kPartnerGoogleDriveUserEmailKey];
  }
}

-(NSString *)partnerGoogleCalendarUserEmail {
  return self.partnerDict[kPartnerGoogleCalendarUserEmailKey];
}

-(void)setPartnerGoogleCalendarUserEmail:(NSString *)partnerGoogleCalendarUserEmail {
  if (partnerGoogleCalendarUserEmail) {
    self.partnerDict[kPartnerGoogleCalendarUserEmailKey] = partnerGoogleCalendarUserEmail;
  } else {
    [self.partnerDict removeObjectForKey:kPartnerGoogleCalendarUserEmailKey];
  }
}


-(NSString *)googleDriveFolderOwner {
  return self.partnerDict[kGoogleDriveFolderOwnerKey];
}

-(void)setGoogleDriveFolderOwner:(NSString *)googleDriveFolderOwner {
  if (googleDriveFolderOwner) {
    self.partnerDict[kGoogleDriveFolderOwnerKey] = googleDriveFolderOwner;
  } else {
    [self.partnerDict removeObjectForKey:kGoogleDriveFolderOwnerKey];
  }
}

-(NSString *)googleCalendarOwner {
  return self.partnerDict[kGoogleCalendarOwnerKey];
}

-(void)setGoogleCalendarOwner:(NSString *)googleCalendarOwner {
  if (googleCalendarOwner) {
    self.partnerDict[kGoogleCalendarOwnerKey] = googleCalendarOwner;
  } else {
    [self.partnerDict removeObjectForKey:kGoogleCalendarOwnerKey];
  }
}

-(NSString *)partnerKey {
  return [[self.partnerUserID componentsSeparatedByCharactersInSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]]
          componentsJoinedByString:@"_"];
}

-(NSString *)myNameOrEmail {
  NSString *ret;
  @try {
    ret = self.info[kMyNameKey];
  }
  @catch (NSException *exception) {
    ret = nil;
  }
  @finally {
    if (ret) {
      return ret;
    } else {
      @try {
        ret = self.info[kMyUserEmailKey];
      }
      @catch (NSException *exception) {
        ret = @"Your Shared partner";
      }
      @finally {
        return ret;
      }
    }
  }
}

- (BOOL)isGoogleCalendarOwner {
  if ( self.googleCalendarOwner ) {
    return [self.myUserIDs containsObject:self.googleCalendarOwner];
  } else {
    return NO;
  }
}

- (BOOL)isGoogleDriveFolderOwner {
  if ( self.googleCalendarOwner ) {
    return [self.myUserIDs containsObject:self.googleDriveFolderOwner];
  } else {
    return NO;
  }
}

#pragma mark my data
-(void)getMyData {
  
  // get picture
  if ([self myPictureFileExists]) {
    [self refreshMyPictureInBackground];
    [[NSNotificationCenter defaultCenter] postNotificationName:kUserDataFetchedNotification object:nil];
  } else if ([self myPictureExists] ) {
    // This will save to myPictureFile
    self.myPicture = self.myPicture;
    [self saveUser];
    [[NSNotificationCenter defaultCenter] postNotificationName:kUserDataFetchedNotification object:nil];
  }
}

#pragma mark partner data
-(void)getPartnerData {
  NSMutableArray *queries = [NSMutableArray array];
  if ( self.partnerUserEmail ) {
    PFQuery *emailQuery = [PFQuery queryWithClassName:kUserInfoClass];
    [emailQuery whereKey:kMyUserEmailKey equalTo:self.partnerUserEmail];
    [queries addObject:emailQuery];
  }
  if ([self partnerIsFBLogin]) {
    PFQuery *fbQuery = [PFQuery queryWithClassName:kUserInfoClass];
    [fbQuery whereKey:kMyFBIDKey equalTo:self.partnerFBID];
    [queries addObject:fbQuery];
  }
  PFQuery *query = [PFQuery orQueryWithSubqueries:queries];
  [query getFirstObjectInBackgroundWithBlock:^(PFObject *partnerInfo, NSError *error) {
    if (!error && partnerInfo) {
      if (partnerInfo[kMyNameKey]) {
        self.partnerName = partnerInfo[kMyNameKey];
      }
      if (partnerInfo[kMyPictureFileKey]) {
        PFFile* partnerPictureFile = partnerInfo[kMyPictureFileKey];
        [partnerPictureFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
          if (!error && data) {
            self.partnerPicture = [UIImage imageWithData:data];
          }
          [[NSNotificationCenter defaultCenter] postNotificationName:kUserDataFetchedNotification object:nil];
        }];
      } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:kUserDataFetchedNotification object:nil];
      }
    } else {
      [[NSNotificationCenter defaultCenter] postNotificationName:kUserDataFetchedNotification object:nil];
    }
  }];
  
}

@end
