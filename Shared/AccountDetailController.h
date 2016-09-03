//
//  AccountDetailController.h
//  Shared
//
//  Created by Brian Bernberg on 3/10/13.
//  Copyright (c) 2013 BB Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SHTableViewController.h"

typedef enum {kMyFacebookAccount = 0, kPartnerAccount, kMyGoogleDriveAccount, kPartnerGoogleDriveAccount, kMyGoogleCalendarAccount, kPartnerGoogleCalendarAccount} AccountType;

@interface AccountDetailController : SHTableViewController
-(id)initWithAccountType:(AccountType)accountType;
@end
