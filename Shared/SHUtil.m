//
//  SHUtil.m
//  Shared
//
//  Created by Brian Bernberg on 6/12/13.
//  Copyright (c) 2013 BB Consulting. All rights reserved.
//

#import "SHUtil.h"
#import "User.h"
#import "Constants.h"
#import "PF+SHExtend.h"
#import "YRDropdownView.h"

@implementation SHUtil
+(UIBarButtonItem *)barButtonItemWithTarget:(id)target
                                     action:(SEL)action
                                      image:(UIImage *)image {
  image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
  UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
  [button addTarget:target
             action:action forControlEvents:UIControlEventTouchUpInside];
  [button setImage:image forState:UIControlStateNormal];
  [button sizeToFit];
  
  return [[UIBarButtonItem alloc] initWithCustomView:button];
  
}

+(UITableViewCell *)tableViewCellForView:(UIView *)view {
  UITableViewCell *cell = nil;
  
  UIView *parentView = view.superview;
  while (parentView) {
    if ([parentView isKindOfClass:[UITableViewCell class]]) {
      cell = (UITableViewCell *)parentView;
      break;
    }
    parentView = parentView.superview;
  }
  
  return cell;
  
}

+(void)sendPushNotification:(NSDictionary *)pushUserInfo {
  NSString* message = pushUserInfo[@"alert"];
  
  const NSInteger clipLength = 107;
  if ([message length] > clipLength)
  {
    message = [NSString stringWithFormat:@"%@…", [message substringToIndex:clipLength]];
  }
  
  PFObject* pfNotification = [PFObject versionedObjectWithClassName:kNotificationClass];
  pfNotification[kUsersKey] = [User currentUser].userIDs;
  pfNotification[kPushTypeKey] = pushUserInfo[kPushTypeKey];
  pfNotification[kNotificationMessageKey] = message;
  pfNotification[kNotificationSenderKey] = [User currentUser].myUserID;
  [pfNotification saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
    if (succeeded) {
      NSMutableDictionary *pushDict = [pushUserInfo mutableCopy];
      pushDict[@"alert"] = message;
      pushDict[kPushNotificationIDKey] = pfNotification.objectId;
      [PFPush sendPushDataToQueryInBackground:[[User currentUser] partnerPushQuery]
                                     withData:pushDict];
      
    }
  }];
  
}

+ (void)showWarningInView:(UIView *)view
                    title:(NSString *)title
                  message:(NSString *)message
{
  UIView *colorView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 60.f, 60.f)];
  colorView.backgroundColor = [UIColor darkGrayColor];
  YRDropdownView *yrView = [YRDropdownView showDropdownInView:view
                                                        title:title
                                                       detail:message
                                                        image:nil
                                              backgroundImage:[[self class] grabImageFromView:colorView]
                                                     animated:YES
                                                    hideAfter:3.f];
  yrView.titleLabelColor = [UIColor whiteColor];
  yrView.detailLabelColor = [UIColor whiteColor];
}

+ (NSString*)localID {
  NSString *localID = [[NSProcessInfo processInfo] globallyUniqueString];
  return localID;;
}

+(NSString *)pathForDataType:(NSString *)dataType {
  return pathInDocumentDirectory([NSString stringWithFormat:@"%@_%@_%@",
                                  [User currentUser].myUserID,
                                  [User currentUser].partnerUserID,
                                  dataType]);
}

+ (UIImage *)grabImageFromView:(UIView *)view {
  UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, 0.0);
    
  [view.layer renderInContext:UIGraphicsGetCurrentContext()];
  UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return viewImage;
    
}

+ (BOOL)isRetinaDisplay {
  static BOOL retina = NO;
  static BOOL alreadyChecked = NO;
  if ( ! alreadyChecked ) {
    UIScreen *mainScreen = [UIScreen mainScreen];
    if ( mainScreen ) {
      retina = mainScreen.scale > 1.0;
      alreadyChecked = YES;
    }
  }
  return retina;
}

+ (CGFloat)thinnestLineWidth {
  return [[self class] isRetinaDisplay] ? 0.5f : 1.f;
}

@end
