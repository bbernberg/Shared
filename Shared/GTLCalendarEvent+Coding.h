//
//  GTLCalendarEvent+Coding.h
//  Shared
//
//  Created by Brian Bernberg on 7/17/13.
//  Copyright (c) 2013 BB Consulting. All rights reserved.
//

#import "GTLCalendar.h"

@interface GTLCalendarEvent (Coding)
-(void) encodeWithCoder:(NSCoder *) encoder;
-(id) initWithCoder:(NSCoder *) aDecoder;

@end
