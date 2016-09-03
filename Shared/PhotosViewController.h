//
//  PhotosViewController.h
//  PowerOfTwo
//
//  Created by Brian Bernberg on 10/9/11.
//  Copyright (c) 2011 Bern Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UploadPhotoDelegate.h"


@class Partner;
@class Myself;
@class PhotoDetailViewController;
@class CombinedPhotos;
@class Photo;

@interface PhotosViewController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIActionSheetDelegate, UploadPhotoDelegate, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate> {
    UIImageView *headerView;
    UILabel *headerLabel;
    UIButton *addPhotoButton;
    UIButton *homeButton;
    UITableView *photoTableView;
    
    UITableViewCell *photoTableViewCell;
    
    UIView *uploadingBackground;
    UILabel *uploadingLabel;
    UIActivityIndicatorView *uploadingActivityIndicator;
    
    Partner *partner;
    Myself *myself;
        
    UILabel *loadingLabel;
    UIActivityIndicatorView *loadingActivityIndicator;
        
    UIImage *imageToUpload;
    NSString *captionToUpload;
        
    NSString *photoToDisplay;
    Photo *currentPhoto;
    
    // Pull to refresh variables
    UIView *refreshHeaderView;
    UILabel *refreshLabel;
    UIImageView *refreshArrow;
    UIActivityIndicatorView *refreshSpinner;
    BOOL isDragging;
    BOOL isRefreshing;    
    
    BOOL savePhotoToLibrary;
    
    CombinedPhotos *combinedPhotos;
    UIActionSheet *photoDetailActionSheet;
        
}
@property (nonatomic) IBOutlet UIImageView *headerView;
@property (nonatomic) IBOutlet UILabel *headerLabel;
@property (nonatomic) IBOutlet UIButton *addPhotoButton;
@property (nonatomic) IBOutlet UIButton *homeButton;
@property (nonatomic) IBOutlet UITableView *photoTableView;
@property (nonatomic) IBOutlet UITableViewCell *photoTableViewCell;
@property (nonatomic) IBOutlet UILabel *loadingLabel;
@property (nonatomic) IBOutlet UIActivityIndicatorView *loadingActivityIndicator;
@property (weak) IBOutlet UIView *contentView;

@property (nonatomic) UIView *uploadingBackground;
@property (nonatomic) UILabel *uploadingLabel;
@property (nonatomic) UIActivityIndicatorView *uploadingActivityIndicator;

@property (nonatomic) UIImage *imageToUpload;
@property (nonatomic) NSString *captionToUpload;

@property (nonatomic) NSString *photoToDisplay;

@property (nonatomic) UIView *refreshHeaderView;
@property (nonatomic) UILabel *refreshLabel;
@property (nonatomic) UIImageView *refreshArrow;
@property (nonatomic) UIActivityIndicatorView *refreshSpinner;

-(IBAction)homeButtonPressed;
-(IBAction)addPhotoButtonPressed;
-(IBAction)commentsLikesButtonPressed:(id)sender;
-(IBAction)actionButtonPressed:(id)sender;

@end
