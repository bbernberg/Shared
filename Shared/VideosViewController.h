//
//  VideosViewController.h
//  PowerOfTwo
//
//  Created by Brian Bernberg on 2/8/12.
//  Copyright (c) 2012 BB Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Partner;
@class Myself;
@class CombinedVideos;
@class Video;

@interface VideosViewController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIActionSheetDelegate, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate> {
    UIImageView *headerView;
    UILabel *headerLabel;
    UIButton *addVideoButton;
    UIButton *homeButton;
    UITableView *videoTableView;
    
    UITableViewCell *videoTableViewCell;
    
    UIView *uploadingBackground;
    UILabel *uploadingLabel;
    UIActivityIndicatorView *uploadingActivityIndicator;
    
    Partner *partner;
    Myself *myself;
    
    UILabel *loadingLabel;
    UIActivityIndicatorView *loadingActivityIndicator;
        
    NSURL *videoToUploadURL;
    NSString *captionToUpload;
    
    NSString *videoToDisplay;
    Video *currentVideo;
    
    // Pull to refresh variables
    UIView *refreshHeaderView;
    UILabel *refreshLabel;
    UIImageView *refreshArrow;
    UIActivityIndicatorView *refreshSpinner;
    BOOL isDragging;
    BOOL isRefreshing;    
    
    CombinedVideos *combinedVideos;
    UIActionSheet *videoDetailActionSheet;
    
}
@property (nonatomic) IBOutlet UIImageView *headerView;
@property (nonatomic) IBOutlet UILabel *headerLabel;
@property (nonatomic) IBOutlet UIButton *addVideoButton;
@property (nonatomic) IBOutlet UIButton *homeButton;
@property (nonatomic) IBOutlet UITableView *videoTableView;
@property (nonatomic) IBOutlet UITableViewCell *videoTableViewCell;
@property (nonatomic) IBOutlet UILabel *loadingLabel;
@property (nonatomic) IBOutlet UIActivityIndicatorView *loadingActivityIndicator;
@property (weak) IBOutlet UIView *contentView;

@property (nonatomic) UIView *uploadingBackground;
@property (nonatomic) UILabel *uploadingLabel;
@property (nonatomic) UIActivityIndicatorView *uploadingActivityIndicator;

@property (nonatomic) NSURL *videoToUploadURL;
@property (nonatomic) NSString *captionToUpload;

@property (nonatomic) NSString *videoToDisplay;

@property (nonatomic) UIView *refreshHeaderView;
@property (nonatomic) UILabel *refreshLabel;
@property (nonatomic) UIImageView *refreshArrow;
@property (nonatomic) UIActivityIndicatorView *refreshSpinner;

-(IBAction)homeButtonPressed;
-(IBAction)addVideoButtonPressed;
-(IBAction)commentsLikesButtonPressed:(id)sender;
-(IBAction)actionButtonPressed:(id)sender;

@end
