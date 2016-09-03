/*
 * Copyright (c) 2012, Pierre Bernard & Houdah Software s.à r.l.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the <organization> nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

#import "HHPanningTableViewCell.h"

#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>


#define HH_PANNING_ANIMATION_DURATION		0.1f
#define HH_PANNING_BOUNCE_DISTANCE			10.0f
#define HH_PANNING_MINIMUM_PAN				50.0f
#define HH_PANNING_MAXIMUM_PAN              0.0f //Set to 0.0f for full view width
#define HH_PANNING_TRIGGER_OFFSET			100.0f
#define HH_PANNING_USE_VELOCITY             YES


@interface HHPanningTableViewCell () <UIGestureRecognizerDelegate>

@property (nonatomic, assign, getter = isDrawerRevealed) BOOL drawerRevealed;
@property (nonatomic, assign, getter = isAnimationInProgress) BOOL animationInProgress;

@property (nonatomic, strong) UIView* containerView;
@property (nonatomic, strong) UIPanGestureRecognizer* panGestureRecognizer;
@property (nonatomic, assign) CGFloat panOriginX;
@property (nonatomic, readonly) HHPanningTableViewCellDirection swipedDirection;

@end


static NSString * const kDrawerRevealedContext = @"drawerRevealed";
static NSString * const kContainerFrameContext = @"containerFrame";

@implementation HHPanningTableViewCell

#pragma mark -
#pragma mark Initialization

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString*)reuseIdentifier
{
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  
	if (self != nil) {
		[self panningTableViewCellInit];
	}
  
  return self;
}

- (id)initWithCoder:(NSCoder*)coder
{
	self = [super initWithCoder:coder];
  
	if (self != nil) {
		[self panningTableViewCellInit];
	}
  
  return self;
}

- (void)panningTableViewCellInit
{
	self.containerView = [self createContainerView];
  
  UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] init];
  swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
  [swipeLeft addTarget:self action:@selector(handleSwipeLeft:)];
  [self addGestureRecognizer:swipeLeft];
  
  UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] init];
  swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
  [swipeRight addTarget:self action:@selector(handleSwipeRight:)];
  [self addGestureRecognizer:swipeRight];
  
	self.directionMask = 0;
	self.shouldBounce = YES;
  
  self.minimumPan = HH_PANNING_MINIMUM_PAN;
  self.maximumPan = HH_PANNING_MAXIMUM_PAN;
  
	[self addObserver:self forKeyPath:@"drawerRevealed" options:0 context:(__bridge void *)kDrawerRevealedContext];
	[self addObserver:self forKeyPath:@"containerView.frame" options:0 context:(__bridge void *)kContainerFrameContext];
}

- (void)awakeFromNib
{
	if ([super respondsToSelector:@selector(awakeFromNib)]) {
		[super awakeFromNib];
	}
}

- (void)prepareForReuse
{
	[super prepareForReuse];
  
  self.delegate = nil;
  
	[self setDrawerRevealed:NO animated:NO];
  
  self.directionMask = 0;
	self.shouldBounce = YES;
  
  self.drawerRevealed = NO;
  self.animationInProgress = NO;
  
  self.panOriginX = 0.0f;
}

- (UIView*)createContainerView
{
	UIView* containerView = [[UIView alloc] initWithFrame:self.bounds];
  
	[containerView setOpaque:YES];
	[containerView setAutoresizesSubviews:YES];
	[containerView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
  
	[containerView setBackgroundColor:[UIColor whiteColor]];
  
	return containerView;
}

#pragma mark -
#pragma mark Finalization

- (void)dealloc
{
	[self removeObserver:self forKeyPath:@"drawerRevealed" context:(__bridge void *)kDrawerRevealedContext];
	[self removeObserver:self forKeyPath:@"containerView.frame" context:(__bridge void *)kContainerFrameContext];
}


#pragma mark -

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
  if (context == (__bridge void *)kDrawerRevealedContext) {
		if (self.drawerRevealed) {
			UIView* tableView = [self superview];
      
			if ([tableView isKindOfClass:[UITableView class]]) {
				for (UITableViewCell *cell in [(UITableView*)tableView visibleCells]) {
					if ((cell != self) && [cell isKindOfClass:[HHPanningTableViewCell class]]) {
						[(HHPanningTableViewCell*)cell setDrawerRevealed:NO animated:YES];
					}
				}
			}
		}
	}
  else if (context == (__bridge void *)kContainerFrameContext) {
	}
	else {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  }
}


#pragma mark -
#pragma mark API

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
	[super setSelected:selected animated:animated];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
	if (highlighted && [self isDrawerRevealed]) {
		return;
	}
  
	[super setHighlighted:highlighted animated:animated];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated;
{
	if (editing && [self isDrawerRevealed]) {
		[self setDrawerRevealed:NO animated:NO];
	}
  
	[super setEditing:editing animated:animated];
}

- (void)setDrawerRevealed:(BOOL)revealed animated:(BOOL)animated
{
	NSInteger directionMask = self.directionMask;
  
	if (HHPanningTableViewCellDirectionRight & directionMask) {
		[self setDrawerRevealed:revealed direction:HHPanningTableViewCellDirectionRight animated:animated];
	}
  else if (HHPanningTableViewCellDirectionLeft & directionMask) {
		[self setDrawerRevealed:revealed direction:HHPanningTableViewCellDirectionLeft animated:animated];
	}
}

- (void)setDrawerRevealed:(BOOL)revealed direction:(HHPanningTableViewCellDirection)direction animated:(BOOL)animated
{
	if (self.drawerView == nil) {
		return;
	}
  
	self.drawerRevealed = revealed;
  
	UIView *drawerView = self.drawerView;
	UIView *containerView = self.containerView;
	CGRect frame = [containerView frame];
  
	UIView *cellView = self;
	CGRect bounds = [cellView bounds];
	CGFloat duration = animated ? HH_PANNING_ANIMATION_DURATION : 0.0f;
  
	[cellView addSubview:drawerView];
	[cellView addSubview:containerView];
  
	if (revealed) {
		if (direction == HHPanningTableViewCellDirectionRight) {
      if(self.maximumPan) {
        frame.origin.x = bounds.origin.x + self.maximumPan;
      } else {
        frame.origin.x = bounds.origin.x + bounds.size.width;
      }
    } else {
      if(self.maximumPan) {
        frame.origin.x  = bounds.origin.x - self.maximumPan;
      } else {
        frame.origin.x = bounds.origin.x - bounds.size.width;
      }
    }
    
		self.animationInProgress = YES;
    
    void (^animations)(void) = ^ {
      [containerView setFrame:frame];
    };
    
    void (^completion)(BOOL finished) = ^(BOOL finished) {
      
      self.animationInProgress = NO;
    };
    
    if (animated) {
      [UIView animateWithDuration:HH_PANNING_ANIMATION_DURATION
                            delay:0.0f
                          options:UIViewAnimationOptionCurveEaseOut
                       animations:animations
                       completion:completion];
    }
    else {
      animations();
      completion(YES);
    }
	}
	else {
		frame.origin.x = 0.0;
    
    void (^animations)(void) = ^ {
      [containerView setFrame:frame];
    };
    
    self.animationInProgress = YES;
    
    void (^completion)(BOOL finished) = ^(BOOL finished) {
      [drawerView removeFromSuperview];
      
      self.animationInProgress = NO;
    };
    
    if (animated) {
      BOOL shouldBounce = self.shouldBounce;
      
      if (shouldBounce) {
        CGFloat bounceDuration = duration;
        CGFloat offsetX = containerView.frame.origin.x;
        CGFloat bounceMultiplier = fmin(fabs(offsetX / HH_PANNING_TRIGGER_OFFSET), 1.0f);
        CGFloat bounceDistance = bounceMultiplier * HH_PANNING_BOUNCE_DISTANCE;
        
        if (offsetX < 0.0f) {
          bounceDistance *= -1.0;
        }
        
        [UIView animateWithDuration:duration
                              delay:0.0f
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:animations
                         completion:^(BOOL finished) {
                           [UIView animateWithDuration:bounceDuration
                                                 delay:0.0f
                                               options:UIViewAnimationOptionCurveLinear
                                            animations:^{
                                              [containerView setFrame:CGRectOffset(frame, bounceDistance, 0.0f)];
                                            } completion:^(BOOL finished) {
                                              [UIView animateWithDuration:bounceDuration
                                                                    delay:0.0f
                                                                  options:UIViewAnimationOptionCurveLinear
                                                               animations:animations
                                                               completion:completion];
                                            }];
                         }];
      }
      else {
        [UIView animateWithDuration:duration
                              delay:0.0f
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:animations
                         completion:completion];
      }
    }
    else {
      animations();
      completion(YES);
    }
	}
}


#pragma mark -
- (void)layoutSubviews
{
	[super layoutSubviews];
  
	UIView* cellView = self;
	UIView* containerView = self.containerView;
	UIView* drawerView = self.drawerView;
	UIView* backgroundView = self.backgroundView;
	UIView* accessoryView = self.accessoryView;
	UIView* contentView = self.contentView;
  
	if (!self.animationInProgress) {
		CGRect cellBounds = [cellView bounds];
    CGRect containerFrame = [containerView frame];
    
    containerFrame.size.height = cellBounds.size.height;
    containerFrame.size.width = cellBounds.size.width;
    
		if (self.drawerRevealed) {
			if (containerFrame.origin.x > cellBounds.origin.x) {
				containerFrame.origin.x = cellBounds.origin.x + cellBounds.size.width;
			}
			else {
				containerFrame.origin.x = cellBounds.origin.x - cellBounds.size.width;
			}
      
			[containerView setFrame:containerFrame];
      
			[containerView addSubview:backgroundView];
			[containerView addSubview:accessoryView];
			[containerView addSubview:contentView];
      
			[self insertSubview:drawerView belowSubview:containerView];
		}
		else {
			[containerView setFrame:containerFrame];
			[containerView addSubview:backgroundView];
			[containerView addSubview:accessoryView];
			[containerView addSubview:contentView];
      
			[self addSubview:containerView];
		}
	}
  
	// Move other subviews. E.g. drag reorder control
	for (UIView *subview in [self.subviews reverseObjectEnumerator]) {
		if (subview == containerView) {
			continue;
		}
    
		if (subview == drawerView) {
			continue;
		}
    
		if (subview == backgroundView) {
			continue;
		}
    
		if (subview == accessoryView) {
			continue;
		}
    
		if (subview == contentView) {
			continue;
		}
    
    [containerView sendSubviewToBack:subview];
	}
  
	[drawerView setFrame:[cellView bounds]];
  
}

#pragma mark swipe handler
- (void)handleSwipeLeft:(UISwipeGestureRecognizer *)gesture {
  if ( [self.delegate panningTableViewCellShouldSlide:self] == NO ) {
    return;
  }
  
  if ( self.drawerRevealed ) {
    if ( self.swipedDirection == HHPanningTableViewCellDirectionRight ) {
      [self setDrawerRevealed:NO animated:YES];
    }
  } else {
    [self setDrawerRevealed:!self.drawerRevealed direction:HHPanningTableViewCellDirectionLeft animated:YES];
  }
}

- (void)handleSwipeRight:(UISwipeGestureRecognizer *)gesture {
  if ( [self.delegate panningTableViewCellShouldSlide:self] == NO ) {
    return;
  }
  
  if ( self.drawerRevealed ) {
    if ( self.swipedDirection == HHPanningTableViewCellDirectionLeft ) {
      [self setDrawerRevealed:NO animated:YES];
    }
  } else {
    [self setDrawerRevealed:!self.drawerRevealed direction:HHPanningTableViewCellDirectionRight animated:YES];
  }
}

#pragma mark helper methods
- (HHPanningTableViewCellDirection)swipedDirection {
  if (self.containerView.frame.origin.x > 0) {
    return HHPanningTableViewCellDirectionRight;
  } else {
    return HHPanningTableViewCellDirectionLeft;
  }
}

@end
