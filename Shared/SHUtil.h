//
//  SHUtil.h
//  Shared
//
//  Created by Brian Bernberg on 6/12/13.
//  Copyright (c) 2013 BB Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SHUtil : NSObject
+(UIBarButtonItem *)barButtonItemWithTarget:(id)target
                                     action:(SEL)action
                                      image:(UIImage *)image;
+(UITableViewCell *)tableViewCellForView:(UIView *)view;
+(void)sendPushNotification:(NSDictionary *)pushUserInfo;
+ (void)showWarningInView:(UIView *)view
                    title:(NSString *)title
                  message:(NSString *)message;
+ (NSString*)localID;
+ (NSString *)pathForDataType:(NSString *)dataType;
+ (UIImage *)grabImageFromView:(UIView *)view;
+ (BOOL)isRetinaDisplay;
+ (CGFloat)thinnestLineWidth;

@end
