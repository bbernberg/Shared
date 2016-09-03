//
//  GTLCalendarEvent+Coding.m
//  Shared
//
//  Created by Brian Bernberg on 7/17/13.
//  Copyright (c) 2013 BB Consulting. All rights reserved.
//

#import "GTLCalendarEvent+Coding.h"

@implementation GTLCalendarEvent (Coding)

-(void) encodeWithCoder:(NSCoder *) encoder{
    
    [encoder encodeObject:self.JSON forKey: @"GTLCalendarEventJSON"];
    
}

-(id) initWithCoder:(NSCoder *) aDecoder {
    NSMutableDictionary* JSON = [aDecoder decodeObjectForKey: @"GTLCalendarEventJSON"];
    self = [GTLCalendarEvent objectWithJSON: JSON];
    
    return self;
}

@end
