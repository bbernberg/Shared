//
//  TextViewController.h
//  Shared
//
//  Created by Brian Bernberg on 4/5/12.
//  Copyright (c) 2012 BB Consulting. All rights reserved.
//

#import "SHViewController.h"
#import "Parse/Parse.h"
#import "CLImageEditor.h"
#import <AVFoundation/AVFoundation.h>

@interface TextController : SHViewController <UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, UIScrollViewDelegate, UIGestureRecognizerDelegate, UIActionSheetDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, CLImageEditorDelegate, AVAudioPlayerDelegate>;

@end
