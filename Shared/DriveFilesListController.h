//
//  DriveFilesListViewController.h
//  Shared
//
//  Created by Brian Bernberg on 1/13/13.
//  Copyright (c) 2013 BB Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GTLDriveFile.h"
#import "SHViewController.h"

@interface DriveFilesListController : SHViewController
- (id)initWithFolderID:(NSString *)theFolderID andFolderName:(NSString *)theFolderName;
@end
