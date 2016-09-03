//
//  SharedAppDelegate.h
//  Shared
//
//  Created by Brian Bernberg on 9/11/11.
//  Copyright 2011 Bern Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PF+SHExtend.h"
#import "SHPalette.h"
#import "SHDrawerController.h"

@class SharedController;
@class SideBarController;

#define kAppDelegate (SharedAppDelegate *)([UIApplication sharedApplication].delegate)

@interface SharedAppDelegate : NSObject <UIApplicationDelegate>

@property (nonatomic, strong) IBOutlet UIWindow *window;
@property (nonatomic, strong) NSArray *buttonOrder;
@property (nonatomic, strong) SHDrawerController *viewController;
@property (nonatomic, readonly) UINavigationController *navController;
@property (nonatomic, readonly) SharedController *sharedCon;
@property (nonatomic, readonly) SideBarController *sideBarController;

- (UIFont *)globalFontWithSize:(CGFloat)size;
- (UIFont *)globalItalicFontWithSize:(CGFloat)size;
- (UIFont *)globalBoldFontWithSize:(CGFloat)size;
- (UIFont *)globalBoldItalicFontWithSize:(CGFloat)size;

- (void)setParseDatabase;
- (UIImage *)scaleAndRotateImage:(UIImage *)image;
- (UIImage *)scaleAndRotateImage:(UIImage *)image maxResolution:(NSInteger)maxResolution;

- (void)showTextController;
- (void)showTextControllerAnimated:(BOOL)animated;
- (void)showGoogleCalendarControllerWithSelectedDate:(NSDate *)selectedDate;
- (void)showGoogleDriveController;
- (void)showListsController;
- (void)showSettingsController;
- (UIViewController *)viewControllerForPresentation;

@end
