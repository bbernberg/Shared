//
//  GlympseLiteWrapper.mm
//  Shared
//
//  Created by Brian Bernberg on 6/4/13.
//  Copyright (c) 2013 BB Consulting. All rights reserved.
//
#import "Constants.h"
#import "GlympseLiteWrapper.h"
#import "User.h"
#import <Parse/Parse.h>
#import "PF+SHExtend.h"
#import "SHUtil.h"
#import "TextService.h"

#define kGlympseUseProduction
#ifdef kGlympseUseProduction
#define kGlympseApiKey "PlB71lu89D1ddUtC"
#define kGlympseBaseURL "api.glympse.com"
#else
#define kGlympseApiKey "JMxouPf4vCDHppDY"
#define kGlympseBaseURL "sandbox.glympse.com"
#endif

@interface GlympseLiteWrapper () <GLYListenerLite>
@property (nonatomic, assign) Glympse::GGlympseLite glympse;
@property (nonatomic, assign) Glympse::GString serverAddress;
@property (nonatomic, assign) Glympse::GString apiKey;
@property (nonatomic, strong) NSMutableDictionary *lastGlympseInfo;
@end

@implementation GlympseLiteWrapper

- (void)start {
  if ( _glympse == NULL ) {
    _glympse = Glympse::LiteFactory::createGlympse(_serverAddress, _apiKey);
    [GLYGlympseLite subscribe:self onPlatform:_glympse];
    
    _glympse-> start();
    
    
  }
}

- (void) stop
{
  if (_glympse != NULL) {
    [GLYGlympseLite unsubscribe:self onPlatform:_glympse];
    
    // Shutdown the Glympse platform.
    _glympse->stop();
    _glympse = NULL;
  }
}

- (void) setActive:(BOOL)isActive {
  if (_glympse != NULL) {
    _glympse->setActive(isActive);
  }
}

- (Glympse::GGlympseLite) glympse {
  return (Glympse::GGlympseLite) _glympse;
}

- (void)sendGlympse
{
  static const NSInteger MS_PER_HOUR   = 3600000;
  
  Glympse::GTicketLite ticketLite = Glympse::LiteFactory::createTicket(MS_PER_HOUR,
                                                                       NULL,
                                                                       NULL);
  
  NSString *userName = [User currentUser].myName;
  
  _glympse->setNickname(Glympse::LiteFactory::createString([userName UTF8String]));
  
  if ([[User currentUser] myPictureExists])
  {
    //Largest avatar size is 320x320 @ 72 PPI -- anything larger is resized prior to upload.
    UIImage* image = [[User currentUser] myPicture];
    Glympse::GDrawable avatar = Glympse::LiteFactory::createDrawable(image);
    _glympse->setAvatar(avatar);
  }
  
  ticketLite->addInvite(Glympse::LC::INVITE_TYPE_LINK,
                        Glympse::LiteFactory::createString([[User currentUser].partnerName UTF8String]),
                        NULL);
  
  
  _glympse->sendTicket(ticketLite, Glympse::LC::SEND_WIZARD_INVITES_READONLY);
  
}

-(void)logout {
  [self stop];
}

- (Glympse::GTicketLite)activeTicket
{
  
  if (_glympse != NULL) {
    
    Glympse::GArray<Glympse::GTicketLite>::ptr tickets = [GlympseLiteWrapper instance].glympse->getTickets();
    
    // Just grab first ticket in array since creating
    //  more than one ticket at a time is avoided
    if (tickets->length() > 0)
    {
      return tickets->at(0);
    }
  }
  
  return nil;
}

- (BOOL)hasActiveTicket {
  // Check for valid ticket object AND whether it has expired AND that invite is to partner
  Glympse::GTicketLite ticket = [self activeTicket];
  if (ticket == NULL) {
    return NO;
  }
  
  Glympse::GInviteLite invite = [self inviteForActiveTicket];
  NSString *inviteName = invite->getName() != nil ? [NSString stringWithUTF8String:invite->getName()->toCharArray()] : @"";
  
  return (ticket->getExpireTime() > _glympse->getTime() &&
          [inviteName isEqualToString:[User currentUser].partnerName]);
  
}

- (NSString *)pathForActiveTicket {
  Glympse::GTicketLite ticket = [self activeTicket];
  
  if (ticket == NULL) {
    return nil;
  }
  
  Glympse::GArray<Glympse::GInviteLite>::ptr invites = ticket-> getInvites();
  
  if (invites->length() == 0 || invites->at(0)->getUrl() == NULL) {
    return nil;
  }
  
  return [NSString stringWithUTF8String:invites->at(0)->getUrl()->toCharArray()];
}

-(Glympse::GInviteLite)inviteForActiveTicket {
  
  Glympse::GTicketLite ticket = [self activeTicket];
  
  if (ticket == NULL) {
    return NULL;
  }
  
  Glympse::GArray<Glympse::GInviteLite>::ptr invites = ticket-> getInvites();
  
  if (invites->length() == 0) {
    return NULL;
  }
  
  return invites->at(0);
  
}

-(void)modifyActiveTicket {
  
  Glympse::GTicketLite ticket = [self activeTicket];
  
  if (ticket != NULL) {
    ticket->modify(Glympse::LC::SEND_WIZARD_INVITES_READONLY);
  }
}

-(void)expireActiveTicket {
  Glympse::GTicketLite ticket = [self activeTicket];
  
  if (ticket != NULL) {
    ticket->expire();
  }
  
}

#pragma mark utilities
- (void)populateLastGlympseInfoFromGlympseText:(PFObject *)text {
  self.lastGlympseInfo = [NSMutableDictionary dictionary];
  NSArray *fields = @[kGlympseStartDateKey,
                      kGlympseExpireDateKey,
                      kGlympseURLKey,
                      kGlympseMessageKey,
                      kGlympseDestinationKey];
  [fields enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop) {
    if ( text[key] ) {
      self.lastGlympseInfo[key] = text[key];
    }
  }];
}

- (BOOL)glympseIsEqualToLastSentGlympse:(PFObject *)glympse {
  
  if ( !self.lastGlympseInfo ) {
    return NO;
  }

  if ( ! [glympse[kGlympseStartDateKey] isEqual:self.lastGlympseInfo[kGlympseStartDateKey]] ) {
    return NO;
  }

  if ( ! [glympse[kGlympseExpireDateKey] isEqual:self.lastGlympseInfo[kGlympseExpireDateKey]] ) {
    return NO;
  }
  
  if ( ! [glympse[kGlympseURLKey] isEqualToString:self.lastGlympseInfo[kGlympseURLKey]] ) {
    return NO;
  }
  
  if ([glympse[kGlympseMessageKey] length] > 0 && ! [glympse[kGlympseMessageKey] isEqualToString:self.lastGlympseInfo[kGlympseMessageKey]]) {
    return NO;
  }
  
  if ([glympse[kGlympseDestinationKey] length] > 0 && ! [glympse[kGlympseDestinationKey] isEqualToString:self.lastGlympseInfo[kGlympseDestinationKey]]) {
    return NO;
  }
  
  return YES;;
  
}

#pragma mark - Initialization

- (void)singletonInit
{
  _apiKey = Glympse::LiteFactory::createString(kGlympseApiKey);
  _serverAddress = Glympse::LiteFactory::createString(kGlympseBaseURL);
  _lastGlympseInfo = nil;
  
}

#pragma mark - Singleton methods -- unrelated to Glympse platform

static GlympseLiteWrapper* s_globalWrapperInstance = nil;

+ (id)instance
{
  static dispatch_once_t dispatchOncePredicate = 0;
  dispatch_once(&dispatchOncePredicate, ^{
    s_globalWrapperInstance = [[super allocWithZone:NULL] init];
    [s_globalWrapperInstance singletonInit];
  });
  return s_globalWrapperInstance;
}

/**
 * Respond to GlympseLite platform events
 */
- (void)glympseEvent:(const Glympse::GGlympseLite &)glympse
                code:(int)code
              param1:(const Glympse::GCommon &)param1
              param2:(const Glympse::GCommon &)param2
{
  
  if ( (param1 != NULL &&
        param2 != NULL &&
        code & Glympse::LC::EVENT_INVITE_URL_CREATED) ||
      (param1 != NULL &&
       code & Glympse::LC::EVENT_TICKET_CHANGED) )
  {
    Glympse::GTicketLite ticket = (Glympse::GTicketLite)param1;
    Glympse::GInviteLite invite;
    if (code & Glympse::LC::EVENT_INVITE_URL_CREATED) {
      invite = (Glympse::GInviteLite)param2;
    } else {
      invite = ticket->getInvites()->at(0);
    }
    if (invite->getUrl() == NULL) {
      return;
    }
    
    BOOL newGlympse = NO;
    NSString *glympseURL = [NSString stringWithUTF8String:invite->getUrl()->toCharArray()];
    PFObject *glympseText = [[TextService sharedInstance] textWithGlympseURL:glympseURL];
    if ( ! glympseText ) {
      newGlympse = YES;
      glympseText = [PFObject versionedObjectWithClassName:kTextClass];
      glympseText[kUsersKey] = [[User currentUser] userIDs];
      glympseText[kSenderKey] = [User currentUser].myUserID;
      glympseText[kReceiverKey] = [User currentUser].partnerUserID;
      glympseText[kSendStatusKey] = kSendSuccess;
      glympseText[kMyCreatedAtKey] = [NSDate date];
      glympseText[kGlympseURLKey] = glympseURL;
    }
    CGFloat startTime = (CGFloat) ticket->getStartTime() / 1000.0; // convert to seconds
    glympseText[kGlympseStartDateKey] = [NSDate dateWithTimeIntervalSince1970:startTime];
    CGFloat expireTime = (CGFloat) ticket->getExpireTime() / 1000.0; // convert to seconds
    glympseText[kGlympseExpireDateKey] = [NSDate dateWithTimeIntervalSince1970:expireTime];
    
    if (ticket->getDestination() != NULL) {
      NSMutableString *dest = [NSMutableString string];
      if (ticket->getDestination()->getName() != NULL) {
        NSString *name = [NSString stringWithUTF8String:ticket->getDestination()->getName()->toCharArray()];
        [dest appendString:name];
        [dest appendString:@"\n"];
      }
      if (ticket->getDestination()->getAddress() != NULL) {
        NSString *addr = [NSString stringWithUTF8String:ticket->getDestination()->getAddress()->toCharArray()];
        [dest appendString:addr];
        [dest appendString:@"\n"];
      }
      if (dest.length > 0) {
        glympseText[kGlympseDestinationKey] = dest;
      }
    }
    if (ticket->getMessage() != NULL) {
      glympseText[kGlympseMessageKey] = [NSString stringWithUTF8String:ticket->getMessage()->toCharArray()];
      glympseText[kMessageKey] = glympseText[kGlympseMessageKey];
    }
    
    // check if any relevant fields have changed if it's an update
    if (code & Glympse::LC::EVENT_TICKET_CHANGED &&
        [self glympseIsEqualToLastSentGlympse:glympseText]) {
      // nothing's changed so don't do anything
      return;
    }

    [self populateLastGlympseInfoFromGlympseText:glympseText];
    
    if ( newGlympse ) {
      [[TextService sharedInstance] sendText:glympseText isResend:NO];
    } else {
      [glympseText saveEventually];
      [glympseText pinInBackground];
      [[NSNotificationCenter defaultCenter] postNotificationName:kSendTextSuccessNotification object:nil];
    }
    
  } else if (param1 != NULL &&
             (code & Glympse::LC::EVENT_TICKET_EXPIRED)) {
    NSLog(@"Expired ticket.  Ticket count = %d", [self hasActiveTicket]);
    double delayInSeconds = 0.6;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
      [[NSNotificationCenter defaultCenter] postNotificationName:kSendTextSuccessNotification object:nil];
    });
  }
  
}

- (BOOL)isURLForActiveTicket:(NSString *)url {
  return [url isEqualToString:[self pathForActiveTicket]];
}

+ (id)allocWithZone:(NSZone*)zone
{
  return [[self instance] retain];
}

- (id)copyWithZone:(NSZone *)zone
{
  return self;
}

- (id)retain
{
  return self;
}

- (NSUInteger)retainCount
{
  return UINT_MAX;  //denotes an object that cannot be released
}

- (oneway void)release
{
  //do nothing
}

- (id)autorelease
{
  return self;
}

- (void)dealloc
{
  [super dealloc];
}


@end

