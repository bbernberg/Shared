//
//  User.h
//  Shared
//
//  Created by Brian Bernberg on 9/24/12.
//  Copyright (c) 2012 BB Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

enum {kFetchUserOK = 0,
    kFetchUserNewUser,
    kFetchUserError};

@interface User : NSObject
@property (nonatomic, strong, readonly) NSString *myUserID;
@property (nonatomic, strong, readonly) NSArray *myUserIDs;
@property (nonatomic, strong) NSString *myName;
@property (nonatomic, strong) NSString *myFBID;
@property (nonatomic, strong) NSString *myFBName;
@property (nonatomic, strong) NSString *myUserEmail;
@property (nonatomic, strong) NSString *myGoogleDriveUserEmail;
@property (nonatomic, strong) NSString *myGoogleCalendarUserEmail;
@property (nonatomic, strong) UIImage *myPicture;
@property (nonatomic, readonly) UIImage *mySmallPicture;

@property (nonatomic, strong) NSString *partnerUserID;
@property (nonatomic, strong) NSString *partnerName;
@property (nonatomic, strong) NSString *partnerFBID;
@property (nonatomic, strong) NSString *partnerFBName;
@property (nonatomic, strong) NSString *partnerUserEmail;
@property (nonatomic, strong) NSMutableArray *partnerPhoneNumbers;
@property (nonatomic, strong) NSString *partnerPhoneNumber;
@property (nonatomic, strong) NSMutableArray *partnerEmailAddresses;
@property (nonatomic, strong) NSDictionary *partnerEmailAddress;
@property (nonatomic, strong) NSDictionary *partnerText;
@property (nonatomic, strong) NSString *partnerFacetime;
@property (nonatomic, strong) NSString *partnerGoogleDriveUserEmail;
@property (nonatomic, strong) NSString *partnerGoogleCalendarUserEmail;
@property (nonatomic, strong) UIImage *partnerPicture;
@property (nonatomic, readonly) UIImage *partnerSmallPicture;
@property (nonatomic, strong) NSString *googleDriveFolderOwner;
@property (nonatomic, strong) NSString *googleCalendarOwner;
@property (readonly, nonatomic, strong) NSArray *userIDs;
@property (nonatomic, assign) BOOL validData;
@property (nonatomic, readonly) BOOL isFBLogin;
@property (nonatomic, readonly) BOOL isGoogleCalendarOwner;
@property (nonatomic, readonly) BOOL isGoogleDriveFolderOwner;


+(User *)currentUser;
+(void)initWithUserID:(NSString *)userID;
+(void)newUserWithUserID:(NSString *)userID;

- (void)fetchUserWithCompletionBlock:(void (^)(NSNumber *))completionBlock;
- (void)fetchUserWithUserEmail:(NSString *)userEmail completionBlock:(void (^)(NSNumber *))completionBlock;
- (void)fetchUserInBackground;

-(void)saveUser;
-(void)saveToNetwork;
+(void)logout;
-(BOOL)hasPartner;
-(void)updatePFInstallationForUser;
-(PFQuery*)partnerPushQuery;
-(BOOL)partnerIsFBLogin;
-(BOOL)myPictureExists;
- (BOOL)myPictureFileExists;
-(BOOL)partnerPictureExists;
-(NSString *)myNameOrEmail;
- (void)refreshMyPicture;
- (void)getMyData;
- (void)getPartnerData;

@end
