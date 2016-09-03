//
//  DriveFileController.h
//  Shared
//
//  Created by Brian Bernberg on 1/17/13.
//  Copyright (c) 2013 BB Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GTLDrive.h"
#import "SHViewController.h"

@interface DriveFileController : SHViewController
- (id)initWithFile:(GTLDriveFile *)file driveService:(GTLServiceDrive*)driveService;
@end
