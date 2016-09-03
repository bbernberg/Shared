//
//  UploadVideoViewController.h
//  PowerOfTwo
//
//  Created by Brian Bernberg on 2/17/12.
//  Copyright (c) 2012 Bern Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#define kUploadVideoCancelButtonPressed @"uploadVideoCancelButtonPressed"
#define kUploadVideoUploadButonPressed @"uploadVideoUploadButtonPressed"

@interface UploadVideoViewController : UIViewController <UITextFieldDelegate> {
    UITextField *captionTextField;
    UIButton *cancelButton;
    UIButton *uploadButton;
    UIImageView  *footerView;
    UIImageView *videoPictureView;
    UIImage *videoPicture;    
}
@property (nonatomic) IBOutlet UITextField *captionTextField;
@property (nonatomic) IBOutlet UIButton *cancelButton;
@property (nonatomic) IBOutlet UIButton *uploadButton;
@property (nonatomic) IBOutlet UIImageView *footerview;
@property (nonatomic) IBOutlet UIImageView *videoPictureView;
@property (nonatomic) UIImage *videoPicture;

-(IBAction)cancelButtonPressed:(id)sender;
-(IBAction)uploadButtonPressed:(id)sender;

-(id)initWithVideoPicture:(UIImage *)image;

@end
