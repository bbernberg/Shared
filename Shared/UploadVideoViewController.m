//
//  UploadVideoViewController.m
//  PowerOfTwo
//
//  Created by Brian Bernberg on 11/18/11.
//  Copyright (c) 2011 Bern Software. All rights reserved.
//

#import "UploadVideoViewController.h"
#import "CombinedVideos.h"
#import <Quartzcore/Quartzcore.h>
#import "UIButton+myButton.h"

@interface UploadVideoViewController ()
-(CGRect)aspectFittedRect:(CGRect)inRect max:(CGRect)maxRect;

@end

@implementation UploadVideoViewController
@synthesize captionTextField, cancelButton, uploadButton, footerview, videoPicture, videoPictureView;

-(id)initWithVideoPicture:(UIImage *)image
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        // Custom initialization
        
        self.videoPicture = image;
        
    }
    
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [UIApplication sharedApplication].statusBarHidden = YES;
    
    [cancelButton customizeButton];
    [uploadButton customizeButton];
    videoPictureView.image = videoPicture;
    if (self.navigationController != nil) {
        self.navigationController.navigationBarHidden = TRUE;
    }

    
}


-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [UIApplication sharedApplication].statusBarHidden = YES;
    
    
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [UIApplication sharedApplication].statusBarHidden = NO;
    
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.cancelButton = nil;
    self.uploadButton = nil;
    self.footerview = nil;
    self.videoPicture = nil;
    self.videoPictureView = nil;
    self.captionTextField = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark IB Actions
-(void)cancelButtonPressed:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:kUploadVideoCancelButtonPressed object:nil];
}

-(void)uploadButtonPressed:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:kUploadVideoUploadButonPressed object:self userInfo:[NSDictionary dictionaryWithObject:self.captionTextField.text forKey:@"captionToUpload"]];
    
}

#pragma mark Text Field delegate funcitons
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];    
    return YES;
}

-(void)textFieldDidBeginEditing:(UITextField *)textField {
    textField.placeholder = @"";
}

-(void)textFieldDidEndEditing:(UITextField *)textField {
    textField.placeholder = @"Write Caption Here...";
}

#pragma mark other functions

-(CGRect)aspectFittedRect:(CGRect)inRect max:(CGRect)maxRect {
    float originalAspectRatio = inRect.size.width / inRect.size.height;
    float maxAspectRatio = maxRect.size.width / maxRect.size.height;
    
    CGRect newRect = maxRect;
    if (originalAspectRatio > maxAspectRatio) {
        // scale by width
        newRect.size.height = inRect.size.height * maxRect.size.width/inRect.size.width;
        newRect.origin.y += (maxRect.size.height - newRect.size.height)/2.0;
    } else {
        // scale by height
        newRect.size.width = inRect.size.width * maxRect.size.height /inRect.size.height;
        newRect.origin.x += (maxRect.size.width - newRect.size.width)/2.0;
    }
    
    return CGRectIntegral(newRect);
}

@end
