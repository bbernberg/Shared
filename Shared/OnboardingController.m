//
//  OnboardingLoginViewController.m
//  Shared
//
//  Created by Brian Bernberg on 12/24/12.
//  Copyright (c) 2012 BB Consulting. All rights reserved.
//

#import "OnboardingController.h"
#import "Constants.h"
#import <QuartzCore/QuartzCore.h>
#import "SHPalette.h"
#import "SharedController.h"

@interface OnboardingController () <UIScrollViewDelegate>
@property (nonatomic, weak) id<ControllerExiting> delegate;
@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic, weak) IBOutlet UIButton *skipButton;
@property (nonatomic, weak) IBOutlet UIButton *getStartedButton;
@property (nonatomic, weak) IBOutlet UIPageControl *pageControl;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UIImageView *appIcon;
@property (nonatomic, weak) IBOutlet UIImageView *fbIcon;
@property (nonatomic, weak) IBOutlet UIImageView *calIcon;
@property (nonatomic, weak) IBOutlet UIImageView *driveIcon;
@property (nonatomic, weak) IBOutlet UILabel *pageOneLabel;
@property (nonatomic, weak) IBOutlet UILabel *pageTwoLabel;
@property (nonatomic, weak) IBOutlet UILabel *pageThreeLabel;
@property (nonatomic) UIView *onboardingContentView;
@property (nonatomic) BOOL viewsArranged;
@end

@implementation OnboardingController

- (instancetype)initWithDelegate:(id<ControllerExiting>)delegate {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _delegate = delegate;
    _viewsArranged = NO;
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  self.view.backgroundColor = [SHPalette backgroundColor];
  
  self.onboardingContentView = (UIView *)([[NSBundle mainBundle] loadNibNamed:@"OnboardingContentView" owner:self options:nil][0]);
  [self.scrollView addSubview:self.onboardingContentView];
  self.scrollView.layer.masksToBounds = NO;
  self.scrollView.layer.shadowOffset = CGSizeMake(0.0, 0.0);
  self.scrollView.layer.shadowRadius = 4.0;
  self.scrollView.layer.shadowOpacity = 0.8;
  
  self.titleLabel.textColor = [SHPalette navyBlue];
  
  self.pageControl.currentPageIndicatorTintColor = [SHPalette navyBlue];
  self.pageControl.pageIndicatorTintColor = [[SHPalette navyBlue] colorWithAlphaComponent:0.4];
  self.pageControl.numberOfPages = 3;
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  if ( ! self.viewsArranged ) {
    self.viewsArranged = YES;
    [self arrangeViews];
  }
}

-(IBAction)buttonPressed:(id)sender {
  [self.delegate controllerRequestsDismissal:self];
}

#pragma mark view layout
- (void)arrangeViews {
  CGSize screenSize = self.view.bounds.size;
  CGFloat pageWidth = screenSize.width;
  CGFloat labelIndent = 20.f;
  
  // center scroll view vertically
  [self.scrollView setFrameOriginY:roundf((screenSize.height - self.scrollView.frameSizeHeight) / 2.f)];
  self.onboardingContentView.frame = CGRectMake(0.f, 0.f, pageWidth * 3.f, self.scrollView.bounds.size.height);
  self.scrollView.contentSize = CGSizeMake(pageWidth * 3.f, self.scrollView.frameSizeHeight);
  self.scrollView.contentInset = UIEdgeInsetsZero;
  self.pageOneLabel.frame = CGRectMake(labelIndent, self.pageOneLabel.frameOriginY, pageWidth - 2*labelIndent, self.pageOneLabel.frameSizeHeight);
  self.pageTwoLabel.frame = CGRectMake(pageWidth + labelIndent, self.pageTwoLabel.frameOriginY, pageWidth - 2*labelIndent, self.pageTwoLabel.frameSizeHeight);
  self.pageThreeLabel.frame = CGRectMake(pageWidth * 2.f + labelIndent, self.pageThreeLabel.frameOriginY, pageWidth - 2*labelIndent, self.pageThreeLabel.frameSizeHeight);

  self.appIcon.center = CGPointMake(roundf(pageWidth / 2.f), self.appIcon.center.y);
  self.getStartedButton.center = CGPointMake(roundf(pageWidth * 2.5f), self.getStartedButton.center.y);
  self.titleLabel.center = CGPointMake(self.titleLabel.center.x, roundf(self.scrollView.frameOriginY / 2.f));
  self.titleLabel.font = [UIFont fontWithName:@"Copperplate-Bold" size:roundf(screenSize.height / 21.f)];
  self.pageControl.center = CGPointMake(roundf(pageWidth / 2.f), self.pageControl.center.y);
}

#pragma mark Scroll View delegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  CGFloat pageWidth = self.view.bounds.size.width;
  CGFloat p2CenterX = roundf(pageWidth * 1.5);
  CGFloat p2CenterY = 100.f;
  CGFloat p2MaxMove = 50.f;
  
  // Update the page when more than 50% of the previous/next page is visible
  int page = floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
  self.pageControl.currentPage = page;
  
  if (page == 2) {
    [self.skipButton setTitle:@"Done" forState:UIControlStateNormal];
  } else {
    [self.skipButton setTitle:@"Skip" forState:UIControlStateNormal];
  }
  
  
  // Animations...
  CGFloat appAlpha = (pageWidth - scrollView.contentOffset.x) / pageWidth;
  if (appAlpha < 0.f) {
    appAlpha = 0.f;
  } else if (appAlpha > 1.f) {
    appAlpha = 1.f;
  }
  self.appIcon.alpha = appAlpha;
  
  CGFloat pageTwoMultiplier = 0;
  if (scrollView.contentOffset.x <= pageWidth) {
    pageTwoMultiplier = scrollView.contentOffset.x / pageWidth;
  } else if (scrollView.contentOffset.x > pageWidth && scrollView.contentOffset.x <= pageWidth * 2.f) {
    pageTwoMultiplier = (pageWidth * 2.f - scrollView.contentOffset.x) / pageWidth;
  } else {
    pageTwoMultiplier = 0.f;
  }
  self.fbIcon.center = CGPointMake(p2CenterX + pageTwoMultiplier*p2MaxMove,
                                   p2CenterY - pageTwoMultiplier*p2MaxMove);
  self.calIcon.center = CGPointMake(p2CenterX - pageTwoMultiplier*p2MaxMove,
                                    p2CenterY - pageTwoMultiplier*p2MaxMove);
  self.driveIcon.center = CGPointMake(p2CenterX,
                                      p2CenterY + pageTwoMultiplier*p2MaxMove);
  
  CGFloat startAlpha = (scrollView.contentOffset.x - pageWidth) / pageWidth;
  if (startAlpha < 0.f) {
    startAlpha = 0.f;
  } else if (startAlpha > 1.f) {
    startAlpha = 1.f;
  }
  self.getStartedButton.alpha = startAlpha;
}


@end
