//
//  TextService.h
//  Shared
//
//  Created by Brian Bernberg on 4/5/12.
//  Copyright (c) 2012 BB Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Parse/Parse.h"

typedef NS_ENUM(NSUInteger, RetrieveTextAction) {
  RetrieveTextActionAll = 0,
  RetrieveTextActionOlder,
  RetrieveTextActionNew
};

@interface TextService : NSObject
@property (strong) NSArray *texts;

@property (nonatomic, readonly) BOOL retrievingTexts;
@property (nonatomic, readonly) BOOL cacheRetrieved;
@property (nonatomic, readonly) BOOL networkRetrieved;

+(TextService *)sharedInstance;
-(void)retrieveTextsWithRetrieveAction:(RetrieveTextAction)retrieveAction;
-(void)sendTextMessage:(NSString *)textMessage
             withPhoto:(UIImage *)theImage
       andVoiceMessage:(NSDictionary *)voiceMessageDictionory;
- (void)sendText:(PFObject *)text isResend:(BOOL)isResend;
-(void)resendText:(PFObject *)textToResend;
-(void)deleteText:(PFObject *)textToDelete;
-(PFObject *)textWithGlympseURL:(NSString *)url;
@end
