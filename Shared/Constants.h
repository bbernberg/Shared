//
//  Constants.h
//  Shared
//
//  Created by Brian Bernberg on 10/8/11.
//  Copyright (c) 2011 Bern Software. All rights reserved.
//


#ifndef Constants_h
#define Constants_h
#include "SharedAppDelegate.h"
#include "SHTableViewController.h"
#include "User.h"
#import "UIView+Helpers.h"
#import "NSString+SHString.h"
#import "SHViewController.h"
#import "SHNavigationController.h"
#import "PF+SHExtend.h"

static NSString *const kGoogleDriveKeychainItemName = @"Shared Google Drive";
static NSString *const kGoogleCalendarKeychainItemName = @"Shared Google Calendar";
static NSString *const kGoogleClientID = @"436686776282.apps.googleusercontent.com";
static NSString *const kGoogleClientSecret = @"LF0mRvULV_nzEjgaBTBtJAOj";
static NSString *const kGoogleAPIKey = @"AIzaSyD4YIkl7fFxBND8MlaGqHeW0gZZZxlC9qU";

#define kReadFBPermissions @[@"read_stream", @"user_photos", @"user_status", @"user_relationships",@"user_relationship_details", @"user_videos", @"email"]

#define kSharedAppGroup @"group.SharedSoftware.Shared"
#define kAppGroupLoggedInKey @"loggedIn"
#define kAppGroupHasPartnerKey @"hasPartner"
#define kAppGroupPartnerNameKey @"partnerName"
#define kAppGroupPartnerPictureKey @"partnerPicture"
#define kAppGroupPartnerCallNumberKey @"partnerPhoneNumber"
#define kAppGroupPartnerFaceTimeNumberKey @"partnerFaceTime"

#define kCurrentSharedControllerType @"currentSharedController"
typedef NS_ENUM(NSUInteger, SharedControllerType) {
  SharedControllerTypeText = 1,
  SharedControllerTypeCalendar,
  SharedControllerTypeList,
  SharedControllerTypeDrive,
  SharedControllerTypeSettings,
  SharedControllerTypeNotifications
};

// ***************
// *
// * Feature ifdef's
// *
// ***************
//#define kUseVoiceChat

// ***************
// *
// * Configuration
// *
// ***************
//#define INCLUDE_MIGRATION
//#define kIncludeCheckUserEmail
#if DEBUG
//#define kUsePFStaging
//#define kUsePFEmpty
//#define kUseDummyData
#endif

#define kYesString @"Yes"
#define kNoString @"No"

#define kPhotoAlbumTitle @"Shared Photos"
#define kVideoAlbumTitle @"Shared Videos"

#define kPushTypeKey @"PushType"
#define kFBUploadNotification @"fbUploadNotification"
#define kListNotification @"List Notification"
#define kGoogleCalendarNotification @"googleCalendarNotification"
#define kGoogleCalendarEventDateKey @"googleCalendarEventDate"
#define kTextNotification @"textNotification"
#define kDriveUploadNotification @"driveUploadNotification"
#define kPushNotificationIDKey @"notificationID"
#define kTimeToWaitBeforeParseDelete 20// 86400  /* 1 day (in seconds) */
#define kMyMaxResolution 1024

// In app purchase keys
#define kPremiumSharedPurchase @"premiumSharedPurchase"

//**************************************************
#pragma mark Notification class
//**************************************************
// Parse Class
#define kNotificationClass @"NotificationClass"
// Parse field keys
#define kNotificationMessageKey @"notificationMessage"
#define kNotificationSenderKey @"notificationSender"
// Notifications
#define kUpdateNotificationButtonNotification @"updateNotificationButton"

//**************************************************
#pragma mark - User Defaults
//**************************************************
#define kPartnerStatusKey @"partnerStatus"
#define kPartnerStatusDateKey @"partnerStatusDate"
#define kLocalUserInfoKey @"localUserInfoKey"
#define kMessagingSystemKey @"messagingSystemKey"
#define kIMessage @"iMessage"
#define kSharedMessage @"sharedMessage"
#define kIntroShownKey @"introShown"
#define kTextPushMessageShownKey @"textPushMessageShown_"
#define kVoiceChatIntroShownKey @"voiceChatIntroShown_"
#define kTextIntroShownKey @"textIntroShown_"
#define kDriveIntroShownKey @"driveIntroShown_"
#define kGoogleCalendarIntroShownKey @"googleCalendarIntroShown_"
#define kFacebookIntroShownKey @"facebookIntroShown_"
#define kListIntroShownKey @"listIntroShown_"
#define kGlympseIntroShownKey @"glympseIntroShown_"
#define kNoFBPrivacyCheckKey @"noFBPrivacyCheck"

// FB Errors
#define kFBUnsupportedGetRequest 100
#define kFBDoesNotExistError 803
#define kFBUnauthorizedSourceIPAddress 5

//**************************************************
#pragma Main page
//**************************************************
#define kCallLongPressNotification @"callLongPressNotification"
#define kEmailLongPressNotification @"emailLongPressNotification"
#define kGlympseLongPressNotification @"glympseLongPressNotification"

// Buttons
#define kButtonOrderKey @"buttonOrder"
#define kCallButtonTitle @"Call"
#define kEmailButtonTitle @"E-mail"
#define kTextButtonTitle @"Text"
#define kFaceTimeButtonTitle @"FaceTime"
#define kFaceBookButtonTitle @"Facebook"
#define kListsButtonTitle @"Lists"
#define kGoogleDriveButtonTitle @"Google Drive"
#define kGoogleCalendarButtonTitle @"Google Calendar"
#define kVoiceChatButtonTitle @"Voice Chat"
#define kGlympseButtonTitle @"Glympse"

enum {kCallButton = 0,
    kEmailButton,
    kTextButton,
    kFaceTimeButton,
    kFaceBookButton,
    kListsButton,
    kGoogleDriveButton,
    kGoogleCalendarButton,
    kVoiceChatButton,
    kGlympseButton
};


//**************************************************
#pragma mark User data
//**************************************************
// Parse Class
#define kUserInfoClass @"userInfoClass"
// User field keys (to use in User & PFObject)
#define kMyNameKey @"myName"
#define kMyFBIDKey @"myFBID"
#define kMyFBNameKey @"myFBName"
#define kMyUserEmailKey @"myUserEmail"
#define kMyPictureFileKey @"myPictureFile"
#define kMySmallPictureFileKey @"mySmallPictureFile"
#define kMyGoogleDriveUserEmailKey @"myGoogleDriveUserEmail"
#define kMyGoogleCalendarUserEmailKey @"myGoogleCalendarUserEmail"
#define kPartnersKey @"partners"
// Keys within Partners dictionary
#define kPartnerNameKey @"partnerName"
#define kPartnerUserIDKey @"partnerUserID"
#define kPartnerFBIDKey @"partnerFBID"
#define kPartnerFBNameKey @"partnerFBName"
#define kPartnerUserEmailKey @"partnerUserEmail"
#define kPartnerPhoneNumberKey @"partnerPhoneNumber"
#define kPartnerPhoneNumbersKey @"partnerPhoneNumbers"
#define kPartnerEmailAddressesKey @"partnerEmailAddresses"
#define kPartnerEmailAddressKey @"partnerEmailAddress"
#define kPartnerTextKey @"partnerText"
#define kPartnerFacetimeKey @"partnerFacetimeNumber"
#define kPartnerGoogleDriveUserEmailKey @"partnerGoogleDriveUserEmail"
#define kPartnerGoogleCalendarUserEmailKey @"partnerGoogleCalendarUserEmail"
#define kGoogleDriveFolderOwnerKey @"googleDriveFolderOwner"
#define kGoogleCalendarOwnerKey @"googleCalendarOwner"

#define kContactEntryKey @"contactEntry"
#define kContactLabelKey @"contactlabel"
#define kContactTypeKey @"contactType"

#define kContactTypeSMS @"smsType"
#define kContactTypeEmail @"emailType"

#define kUserInfoKey @"userInfo"

#define kLoggedInUserIDKey @"loggedInUserID"

// Notifications
#define kUserDataFetchedNotification @"userDataFetched"

//**************************************************
#pragma mark - Installation Class
//**************************************************
// Parse Field keys
#define kInstallationUserKey @"user"
#define kInstallationChannelsKey @"channels"
#define kInstallationUserIDsKey @"userIDs"
#define kInstallationPartnerUserIDKey @"partnerUserID"

//**************************************************
#pragma mark - Universal user keys
//**************************************************
#define kUsersKey @"users"

//**************************************************
#pragma mark - Universal PF keys
//**************************************************
#define kAppVersionKey @"appVersion"
#define kLocalIDKey @"localID"

//**************************************************
#pragma mark DriveFilesList Class
//**************************************************
// Parse Class
#define kDriveFolderClass @"DriveFolderClass"
// Parse field keys
#define kDriveFolderIDKey @"driveFolderID"
#define kDriveFolderNameKey @"driveFolderName"
#define kDriveFolderOwnerIDKey @"driveFolderOwnerID"
#define kDriveFolderOwnerUserEmailKey @"driveFolderOwnerUserEmail"
#define kDriveFolderPartnerIDKey @"driveFolderPartnerID"
#define kDriveFolderPartnerUserEmailKey @"driveFolderPartnerUserEmail"
#define kDriveFolderSharedKey @"driveFolderShared"

#define kDriveRefreshFilesNotification @"driveRefreshRilesNotification"
#define kDriveFolderFetchedNotification @"driveFolderFetchedNotifcation"

//**************************************************
#pragma mark CombinedLists
//**************************************************
// Notifications
#define kAllListsReceivedNotification @"allListsReceived"
#define kListsReceiveErrorNotification @"listsReceiveError"
#define kListDeleteErrorNotification @"listDeleteError"
#define kListsNetworkErrorNotification @"listsNetworkError"

#define kAllListItemsReceivedNotification @"allListItemsReceived"
#define kListItemsReceiveErrorNotification @"listItemsReceiveError"
#define kListItemDeleteErrorNotification @"listItemDeleteError"

// Notification userInfo Keys
#define kNotificationListKey @"notificationListKey"
#define kNotificationListItemsKey @"notificationListItemsKey"

// Parse Class Key
#define kListClass @"ListClass"
// Parse field keys
#define kListNameKey @"listName"
#define kListIndexKey @"listIndex"

#define kListKey @"list"
// Parse Class Key
#define kListItemClass @"ListItemClass"
// Parse field keys
#define kListItemKey @"listItem"
#define kListItemIndexKey @"listItemIndex"
#define kListItemCompleteKey @"listItemComplete"
#define kListItemMembersKey @"listItemMembers"

#define kModifiedDateKey @"modifiedDate" // for list & list item
#define kListModifiedDateKey @"listModifiedDate" // user facing

//**************************************************
#pragma mark TextService
//**************************************************
#define kAllTextsReceivedNotification @"allTextsReceived"
#define kReceiveTextErrorNotification @"receiveTextError"
#define kInitialSendTextNotification @"initSendText"
#define kSendTextSuccessNotification @"sendTextSuccess"
#define kInitialResendTextNotification @"initResendText"
#define kResendTextSuccessNotification @"resendTextSuccess"
#define kSendTextErrorNotification @"sendTextError"
#define kSendNetworkErrorNotification @"sendNetworkError"
#define kDeleteTextSuccessNotification @"deleteTextSuccess"
#define kDeleteTextErrorNotification @"deleteTextError"

#define kTextRetrievalActionKey @"textRetrievalAction"
#define kHideEarlierMessagesButtonKey @"showEarlierMessagesButton"
#define kTextsPerPage 20

// Parse Class key
#define kTextClass @"TextClass"

// Parse & Text field keys
#define kMyCreatedAtKey @"myCreatedAt"
#define kSenderKey @"sender"
#define kReceiverKey @"receiver"
#define kMessageKey @"message"
#define kSendStatusKey @"sendStatus"
#define kTextPhotoKey @"textPhoto"
#define kTextPhotoWidthKey @"photoWidth"
#define kTextPhotoHeightKey @"photoHeight"
#define kTextVoiceMessageKey @"textVoiceMessage"
#define kGlympseURLKey @"glympseURL"
#define kGlympseStartDateKey @"startDate"
#define kGlympseMessageKey @"message"
#define kGlympseDestinationKey @"destination"
#define kGlympseCreateTimeKey @"glympseCreateTime"
#define kGlympseExpireDateKey @"glympseExpireTime"
#define kTextLocalFilePathKey @"localFilePath"

// Send Status Key values
#define kSendPending @"sendPending"
#define kSendSuccess @"sendSuccess"
#define kSendError @"sendError"

#define kTextIndex @"textIndex"

//**************************************************
#pragma mark Google Calendar Class
//**************************************************
// Parse Class key
#define kGoogleCalendarClass @"GoogleCalendarClass"
// Parse field keys
#define kGoogleCalendarIDKey @"calendarID"
#define kGoogleCalendarOwnerIDKey @"calendarOwnerID"
#define kGoogleCalendarOwnerUserEmailKey @"calendarOwnerUserEmail"
#define kGoogleCalendarPartnerIDKey @"calendarPartnerID"
#define kGoogleCalendarPartnerUserEmailKey @"calendarPartnerUserEmail"
#define kGoogleCalendarSharedKey @"calendarShared"
#define kGoogleCalendarVerifiedKey @"calendarVerified"

#define kGoogleCalendarRetrievedEvents @"retrievedEvents"
#define kSharedGoogleCalendarDeleted @"sharedGoogleCalendarDeleted"

#define kRepeatDaily @"RRULE:FREQ=DAILY"
#define kRepeatWeekly @"RRULE:FREQ=WEEKLY"
#define kRepeatBiWeekly @"RRULE:FREQ=WEEKLY;INTERVAL=2"
#define kRepeatMonthly @"RRULE:FREQ=MONTHLY"
#define kRepeatYearly @"RRULE:FREQ=YEARLY"

// features
//#define kUsePartnerInvites @"userPartnerInvites"


//**************************************************
#pragma mark LogInViewController
//**************************************************
#define kUserLoggedInNotification @"userLoggedInNotification"
#define kNewUserLoggedInNotification @"newUserLoggedInNotification"

//**************************************************
#pragma mark NearbyPlaces
//**************************************************
#define kLocationRequestErrorNotification @"locationRequestError"
#define kNearbyPlacesRequestSuccessNotification @"NearbyPlacesRequestSuccess"
#define kNearbyPlacesRequestFailureNotification @"NearbyPlacesRequestFailure"
#define kNearbyPlacesNoMoreReturnedNotification @"NearbyPlacesNoMoreReturned"


//**************************************************
#pragma mark PhotoDetailViewController
//**************************************************
#define kDismissPhotoDetailViewNotification @"dismissPhotoDetailView"

//**************************************************
#pragma mark SharedController
//**************************************************
#define kPopToMainNotification @"popToMainNotification"
#define kPopToMainNoAnimationNotification @"popToMainNoAnimationNotification"
#define kShouldLogoutNotification @"shouldLogoutNotification"
#define kDidLogoutNotification @"didLogoutNotification"

//**************************************************
#pragma mark RecordViewController
//**************************************************
#define kVoiceMessageURLKey @"voiceMessageURL"
#define kVoiceMessageDurationKey @"voiceMessageDuration"

//***************************************************
#pragma mark file MIME types
//***************************************************
#define kDriveFolderMIMEType @"application/vnd.google-apps.folder"
#define kDriveDocumentMIMEType @"application/vnd.google-apps.document"
#define kDriveSpreadsheetMIMEType @"application/vnd.google-apps.spreadsheet"
#define kDriveDrawingMIMEType @"application/vnd.google-apps.drawing"
#define kDrivePresentationMIMEType @"application/vnd.google-apps.presentation"
#define kMSWordMIMEType @"application/vnd.openxmlformats-officedocument.wordprocessingml.document"
#define kMSExcelMIMEType @"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
#define kPngMIMEType @"image/png"
#define kPdfMIMEType @"application/pdf"

//**************************************************
#pragma mark Rebtel
//**************************************************
#define kRebtelClientDidFailNotification @"rebtelClientDidFailNotification"

//**************************************************
#pragma mark Saved Messages
//**************************************************
// Parse Class key
#define kSavedMessageClass @"SavedMessageClass"
// Parse field keys
#define kSavedMessageUserIDKey @"userID"
#define kSavedMessageMessageKey @"message"
#define kSavedMessageIndexKey @"index"
// Notifications
#define kSavedMessagesUpdatedNotification @"savedMessagesReceivedNotification"

#define kLastLocationUpdated @"lastLocationUpdated"
#define kLastLocationKey @"lastLocation"

#endif
