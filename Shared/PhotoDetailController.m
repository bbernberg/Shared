//
//  PhotoDetailViewController.m
//  Shared
//
//  Created by Brian Bernberg on 10/25/11.
//  Copyright (c) 2011 BB Consulting. All rights reserved.
//

#import "PhotoDetailController.h"
#import "Constants.h"

@interface PhotoDetailController ()
-(CGRect)aspectFittedRect:(CGRect)inRect max:(CGRect)maxRect;
-(void)handleSingleSVTap:(UIGestureRecognizer *)gestureRecognizer;
-(void)handleDoubleSVTap:(UIGestureRecognizer *)gestureRecognizer;
-(void)addSVGestureRecognizers:(UIScrollView *)theScrollView;
- (CGRect)zoomRectForScale:(float)scale withCenter:(CGPoint)center;
@property (nonatomic) BOOL isDismissing;
@end

@implementation PhotoDetailController

-(id)initWithImage:(UIImage *)thePhotoImage andFrame:(CGRect)imageFrame;
{
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    // Custom initialization
    self.automaticallyAdjustsScrollViewInsets = NO;
    photoImageFrame = imageFrame;
    photoImage = thePhotoImage;
    
  }
  return self;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
  return UIInterfaceOrientationMaskAll;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
  [super viewDidLoad];
  // Do any additional setup after loading the view from its nib.
  UIImageView *thePhotoImageView = [[UIImageView alloc] initWithImage:photoImage];
  self.photoImageView = thePhotoImageView;
  
  self.photoImageView.contentMode = UIViewContentModeScaleAspectFit;
  
  self.photoImageView.frame = CGRectMake(photoImageFrame.origin.x, photoImageFrame.origin.y, photoImageFrame.size.width, photoImageFrame.size.height);
  [self.view addSubview:self.photoImageView];
  
}

-(void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  
  [UIApplication sharedApplication].statusBarHidden = YES;
  
  CGFloat animationTime = [[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationPortrait ? 0.2 : 0.0;
  
  [UIView animateWithDuration:animationTime animations:^{
    self.photoImageView.frame = [self aspectFittedRect:self.photoImageView.frame max:self.photoScrollView.frame];
  } completion:^(BOOL finished) {
    self.photoImageView.userInteractionEnabled = YES;
    [self.photoImageView removeFromSuperview];
    [self.photoScrollView addSubview:self.photoImageView];
    self.photoScrollView.contentSize = self.photoImageView.frame.size;
    [self addSVGestureRecognizers:self.photoScrollView];
  }];
  
}

-(void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  [UIApplication sharedApplication].statusBarHidden = NO;
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  
  if ( (self.photoImageView.superview == self.photoScrollView ||
       [[UIApplication sharedApplication] statusBarOrientation] != UIInterfaceOrientationPortrait) &&
       ! self.isDismissing ) {
    self.photoImageView.frame = [self aspectFittedRect:CGRectMake(0.f, 0.f, self.photoImageView.image.size.width, self.photoImageView.image.size.height) max:self.photoScrollView.frame];
    self.photoScrollView.zoomScale = 1.f;
    self.photoScrollView.contentSize = self.photoImageView.frame.size;
  }
  
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark other functions
-(void)addSVGestureRecognizers:(UIScrollView *)theScrollView {
  UITapGestureRecognizer *doubleFingerSVTap = [[UITapGestureRecognizer alloc]
                                               initWithTarget:self action:@selector(handleDoubleSVTap:)];
  doubleFingerSVTap.numberOfTapsRequired = 2;
  [theScrollView addGestureRecognizer:doubleFingerSVTap];
  
  UITapGestureRecognizer *singleFingerSVTap = [[UITapGestureRecognizer alloc]
                                               initWithTarget:self action:@selector(handleSingleSVTap:)];
  
  [singleFingerSVTap requireGestureRecognizerToFail:doubleFingerSVTap];
  
  [theScrollView addGestureRecognizer:singleFingerSVTap];
  
  
}


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


-(void)handleSingleSVTap:(UIGestureRecognizer *)gestureRecognizer {
  
  if (self.photoScrollView.zoomScale != 1.0) {
    [self exit];
  } else {
    if ( [[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationPortrait ) {
      [UIView animateWithDuration:0.5 animations:^{
        self.photoImageView.frame = CGRectMake(photoImageFrame.origin.x, photoImageFrame.origin.y, photoImageFrame.size.width, photoImageFrame.size.height);
      } completion:^(BOOL finished) {
        [self exit];
      }];
    } else {
      [self exit];
    }
  }
}

- (void)exit {
  self.isDismissing = YES;
  [UIApplication sharedApplication].statusBarHidden = NO;
  [[NSNotificationCenter defaultCenter] postNotificationName:kDismissPhotoDetailViewNotification
                                                      object:nil];
}

#define kDoubleTapZoomScale 2.0

-(void)handleDoubleSVTap:(UIGestureRecognizer *)gestureRecognizer {
  
  if (self.photoScrollView.zoomScale != self.photoScrollView.minimumZoomScale) {
    float newScale = self.photoScrollView.minimumZoomScale;
    CGRect zoomRect = [self zoomRectForScale:newScale withCenter:[gestureRecognizer locationInView:gestureRecognizer.view]];
    [self.photoScrollView zoomToRect:zoomRect animated:YES];
    
  } else {
    float newScale = self.photoScrollView.zoomScale * kDoubleTapZoomScale;
    CGRect zoomRect = [self zoomRectForScale:newScale withCenter:[gestureRecognizer locationInView:gestureRecognizer.view]];
    [self.photoScrollView zoomToRect:zoomRect animated:YES];
  }
  
}


#pragma mark Scroll View delegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)theScrollView
{
  return self.photoImageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)aScrollView {
  CGFloat offsetX = (aScrollView.bounds.size.width > aScrollView.contentSize.width) ?
  (aScrollView.bounds.size.width - aScrollView.contentSize.width) * 0.5 : 0.0;
  CGFloat offsetY = (aScrollView.bounds.size.height > aScrollView.contentSize.height) ?
  (aScrollView.bounds.size.height - aScrollView.contentSize.height) * 0.5 : 0.0;
  
  
  self.photoImageView.center = CGPointMake(aScrollView.contentSize.width * 0.5 + offsetX,
                                           aScrollView.contentSize.height * 0.5 + offsetY);
}

#pragma mark Utility methods

- (CGRect)zoomRectForScale:(float)scale withCenter:(CGPoint)center {
  
  CGRect zoomRect;
  
  // the zoom rect is in the content view's coordinates.
  //    At a zoom scale of 1.0, it would be the size of the imageScrollView's bounds.
  //    As the zoom scale decreases, so more content is visible, the size of the rect grows.
  zoomRect.size.height = self.photoScrollView.frame.size.height / scale;
  zoomRect.size.width  = self.photoScrollView.frame.size.width  / scale;
  
  // choose an origin so as to get the right center.
  zoomRect.origin.x    = center.x - (zoomRect.size.width  / 2.0);
  zoomRect.origin.y    = center.y - (zoomRect.size.height / 2.0);
  
  return zoomRect;
}

@end
