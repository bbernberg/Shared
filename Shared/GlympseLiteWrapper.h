//
//  GlympseLiteWrapper.h
//  Shared
//
//  Created by Brian Bernberg on 6/4/13.
//  Copyright (c) 2013 BB Consulting. All rights reserved.
//

#import "Constants.h"


@interface GlympseLiteWrapper : NSObject


+ (GlympseLiteWrapper *)instance;
- (void) sendGlympse;
- (void) start;
- (void) stop;
- (void) setActive:(BOOL)isActive;
- (BOOL) hasActiveTicket;
- (void) modifyActiveTicket;
- (void) expireActiveTicket;
- (void) logout;
- (NSString *)pathForActiveTicket;
- (BOOL)isURLForActiveTicket:(NSString *)url;

@end
