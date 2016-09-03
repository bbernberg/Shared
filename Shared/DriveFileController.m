//
//  DriveFileController.m
//  Shared
//
//  Created by Brian Bernberg on 1/17/13.
//  Copyright (c) 2013 BB Consulting. All rights reserved.
//

#import "DriveFileController.h"
#import "SVProgressHUD.h"
#import "PSPDFAlertView.h"
#import "Constants.h"
#import "DriveFilesListController.h"
#import "TMCache.h"
#import "SharedActivityIndicator.h"
#import "DriveService.h"

#define kNavBarAlpha 0.7

@interface DriveFileController () <
UIWebViewDelegate,
UIGestureRecognizerDelegate >
@property (nonatomic, weak) IBOutlet UIWebView *webView;
@property (nonatomic, weak) IBOutlet UILabel *loadingLabel;
@property (nonatomic, weak) IBOutlet SharedActivityIndicator *loadingSpinner;
@property (nonatomic, weak) IBOutlet UILabel *noPreviewLabel;
@property (nonatomic, strong) GTLDriveFile *file;
@property (nonatomic, strong) GTLServiceDrive *driveService;
@property (nonatomic, assign) BOOL overlayShowing;

-(IBAction)doneButtonPressed:(id)sender;

@end

@implementation DriveFileController

- (id)initWithFile:(GTLDriveFile *)file driveService:(GTLServiceDrive*)driveService {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    // Custom initialization
    self.file = file;
    self.driveService = driveService;
    self.overlayShowing = TRUE;
    self.automaticallyAdjustsScrollViewInsets = NO;
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  // Do any additional setup after loading the view from its nib.
  self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed:)];
  
  UILabel *fileLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 30.0)];
  fileLabel.text = self.file.title;
  fileLabel.textAlignment = NSTextAlignmentCenter;
  fileLabel.textColor = [SHPalette darkNavyBlue];
  fileLabel.backgroundColor = [UIColor clearColor];
  fileLabel.font = [UIFont boldSystemFontOfSize:14.0];
  self.navigationItem.titleView = fileLabel;
  [UIApplication sharedApplication].statusBarHidden = NO;
  self.navigationController.navigationBarHidden = NO;
  
  self.webView.hidden = TRUE;
  
  UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                               action:@selector(handleSingleTap:)];
  tapGesture.numberOfTapsRequired = 1;
  tapGesture.delegate = self;
  [self.webView addGestureRecognizer:tapGesture];
  
  self.loadingLabel.hidden = NO;
  self.loadingSpinner.image = [UIImage imageNamed:@"Shared_Icon_Gray_Transparent"];
  [self.loadingSpinner startAnimating];
  
  UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
  doubleTapGesture.numberOfTapsRequired = 2;
  doubleTapGesture.delegate = self;
  [self.webView addGestureRecognizer:doubleTapGesture];
  [tapGesture requireGestureRecognizerToFail:doubleTapGesture];
  
  NSString *filePath = nil;
  NSString *fileMIMEType = self.file.mimeType;
  if ([self.file.mimeType isEqualToString:kDriveDocumentMIMEType]) {
    filePath = [self.file.exportLinks JSONValueForKey:kPdfMIMEType];
    fileMIMEType = kPdfMIMEType;
  } else if ([self.file.mimeType isEqualToString:kDriveSpreadsheetMIMEType]) {
    filePath = [self.file.exportLinks JSONValueForKey:kPdfMIMEType];
    fileMIMEType = kPdfMIMEType;
  } else if ([self.file.mimeType isEqualToString:kDriveDrawingMIMEType]) {
    filePath = [self.file.exportLinks JSONValueForKey:kPngMIMEType];
    fileMIMEType = kPngMIMEType;
  } else if ([self.file.mimeType isEqualToString:kDrivePresentationMIMEType]) {
    filePath = [self.file.exportLinks JSONValueForKey:kPdfMIMEType];
    fileMIMEType = kPdfMIMEType;
  } else {
    filePath = self.file.downloadUrl;
  }
  
  NSData *fileData = [[TMCache sharedCache] objectForKey:[DriveService driveCacheName:self.file]];
  
  if (fileData) {
    [self.webView loadData:fileData
                  MIMEType:fileMIMEType
          textEncodingName:@"UTF-8"
                   baseURL:[NSURL URLWithString:@"http://"]];
  } else {
    
    GTMHTTPFetcher *fetcher =
    [self.driveService.fetcherService fetcherWithURLString:filePath];
    __weak DriveFileController* wSelf = self;
    [fetcher beginFetchWithCompletionHandler:^(NSData *data, NSError *error) {
      if (error == nil) {
        [[TMCache sharedCache] setObject:data
                                  forKey:[DriveService driveCacheName:wSelf.file]
                                   block:NULL];
        [wSelf.webView loadData:data
                       MIMEType:fileMIMEType
               textEncodingName:@"UTF-8"
                        baseURL:[NSURL URLWithString:@"http://"]];
      } else {
        NSLog(@"An error occurred: %@", error);
        PSPDFAlertView *alert = [[PSPDFAlertView alloc] initWithTitle:nil message:@"Unable to load file. Please try later."];
        [alert setCancelButtonWithTitle:@"OK" block:^(NSInteger buttonIndex) {
          [wSelf.navigationController popViewControllerAnimated:YES];
        }];
        [alert show];
      }
    }];
  }
  
}

-(void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  
  if (self.webView.isLoading) {
    [self.webView stopLoading];
  }
  [UIApplication sharedApplication].statusBarHidden = NO;
  self.navigationController.navigationBarHidden = NO;
}

-(void)dealloc {
  self.webView.delegate = nil;
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

#pragma mark IB Actions
-(void)doneButtonPressed:(id)sender {
  [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark UIWebView delegate functions
-(void)webViewDidFinishLoad:(UIWebView *)webView {
  self.webView.hidden = FALSE;
  self.loadingLabel.hidden = TRUE;
  [self.loadingSpinner stopAnimating];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
  self.loadingLabel.hidden = TRUE;
  [self.loadingSpinner stopAnimating];
  self.noPreviewLabel.hidden = FALSE;
  
}


#pragma mark gesture handler
-(void)handleSingleTap:(UIGestureRecognizer *)gestureRecognizer {
  if (self.overlayShowing) {
    self.overlayShowing = FALSE;
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
  } else {
    self.overlayShowing = TRUE;
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
  }
}

-(void)handleDoubleTap:(UIGestureRecognizer *)gestureRecognizer {
  // dummy function
}

#pragma mark UIGestureRecognizer delegate functions
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
  return YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
  return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
  return YES;
}



@end
