//
//  CalendarCreateViewController.h
//  Shared
//
//  Created by Brian Bernberg on 9/26/15.
//  Copyright © 2015 BB Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CalendarCreateDelegate <NSObject>

- (void)calendarCreateControllerDidCancelWithError:(BOOL)withError;
- (void)calendarCreatedNeedsPartnerEmail:(BOOL)needsPartnerEmail;

@end

@interface CalendarCreateViewController : SHViewController

- (instancetype)initWithDelegate:(id<CalendarCreateDelegate>)delegate;

- (id) init __attribute__((unavailable("init not available")));
- (id)initWithCoder:(NSCoder *)aDecoder __attribute__((unavailable("init not available")));
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil __attribute__((unavailable("init not available")));

@end
