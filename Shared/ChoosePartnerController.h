//
//  ChoosePartnerController.h
//  Shared
//
//  Created by Brian Bernberg on 3/3/13.
//  Copyright (c) 2013 BB Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SHViewController.h"

@interface ChoosePartnerController : SHViewController
- (id)initWithCompletionBlock:(void (^)(void))completionBlock
              useCancelButton:(BOOL)useCancelButton;
@end
