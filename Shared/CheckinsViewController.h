//
//  CheckinsViewController.h
//  PowerOfTwo
//
//  Created by Brian Bernberg on 3/11/12.
//  Copyright (c) 2012 BB Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PlacesListDelegate.h"
#define kCheckinCommentsDoneButtonPressed @"checkinCommentsDoneButtonPressed"

@interface CheckinsViewController : UIViewController <UIActionSheetDelegate, PlacesListDelegate, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate>

@end
