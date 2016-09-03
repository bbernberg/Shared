//
//  PhotoDetailViewController.h
//  Shared
//
//  Created by Brian Bernberg on 10/25/11.
//  Copyright (c) 2011 Bern Software. All rights reserved.
//

#import "SHViewController.h"


@interface PhotoDetailController : SHViewController <UIScrollViewDelegate> {
  
    UIImage *photoImage;
    CGRect photoImageFrame;
    
}

@property (nonatomic) IBOutlet UIScrollView *photoScrollView;
@property (nonatomic) UIImageView *photoImageView;

-(id)initWithImage:(UIImage *)thePhotoImage andFrame:(CGRect)imageFrame;

@end
