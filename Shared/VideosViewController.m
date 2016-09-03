//
//  VideosViewController.m
//  PowerOfTwo
//
//  Created by Brian Bernberg on 10/9/11.
//  Copyright (c) 2011 Bern Software. All rights reserved.
//

#import "VideosViewController.h"
#import "Partner.h"
#import "Myself.h"
#import "Video.h"
#import "Constants.h"
#import <Quartzcore/QuartzCore.h>
#import "CombinedVideos.h"
#import "UploadVideoViewController.h"
#import "CommentsViewController.h"
#import "PushNotificationController.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import <MediaPlayer/MediaPlayer.h>
#import "UIButton+myButton.h"
#import "MyAdBannerView.h"

#define kInterPhotoHeight 3.0f
#define kMaxPhotoDimension 480
#define REFRESH_HEADER_HEIGHT 52.0f
#define kLoadingCellHeight 50.0f

@interface VideosViewController()
-(void)handleUploadVideoRequestResponse:(NSNotification *)notification;
-(void)handleUploadVideoError;
-(void)handleLikeRequestResponse;
-(void)handleLikeRequestError;
-(void)handleUnlikeRequestResponse;
-(void)handleUnlikeRequestError;

-(void)takeVideoButtonPressed;
-(void)chooseFromLibraryButtonPressed;
-(void)createUploadingViews;
-(void)removeUploadingViews;
-(void)allVideosReceived;
-(void)receivedCommentsAndLikes;
-(void)videoCommentsDoneButtonPressed;
-(void)setupCommentsLikesButton:(UIButton *)commentsLikesButton;
-(void)likeButtonPressed;
-(CGRect)aspectFittedRect:(CGRect)inRect max:(CGRect)maxRect;
-(CGRect)cellRectForVideo:(Video *)theVideo;
-(void)handleVideoTap:(UIGestureRecognizer *)gesture;
-(void)uploadVideoCancelButtonPressed;
-(void)uploadVideoUploadButtonPressed:(NSNotification *)notification;
-(void)configureImageViewBorder:(UIImageView *)theImageView withBorderWidth:(CGFloat)borderWidth;

-(void)enableVideoControls:(MPMoviePlayerController *)player;
-(void)handleMoviePlayerNotification:(NSNotification *)notification;

// pull to refresh functions
- (void)addPullToRefreshHeader;
- (void)pullToRefreshStartLoading;
- (void)pullToRefreshStopLoading;
- (void)refreshTable;


@end

@implementation VideosViewController

@synthesize headerView, headerLabel, homeButton, addVideoButton, videoTableView, videoTableViewCell, loadingLabel, loadingActivityIndicator, uploadingLabel, uploadingBackground, uploadingActivityIndicator, videoToUploadURL, captionToUpload, videoToDisplay, refreshHeaderView, refreshLabel, refreshArrow, refreshSpinner, contentView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        partner = [Partner sharedInstance];
        myself = [Myself sharedInstance];
        combinedVideos = [CombinedVideos sharedInstance];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(allVideosReceived) name:@"allVideosReceived" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoCommentsDoneButtonPressed) name:@"videoCommentsDoneButtonPressed" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedCommentsAndLikes) name:kVideosReceivedCommentsAndLikes object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLikeRequestResponse) name:kVideoLikeRequestSuccess object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLikeRequestError) name:kVideoLikeRequestError object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUnlikeRequestResponse) name:kVideoUnlikeRequestSuccess object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUnlikeRequestError) name:kVideoUnlikeRequestError object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUploadVideoRequestResponse:) name:kUploadVideoRequestSuccess object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUploadVideoRequestError) name:kUploadVideoRequestError object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadVideoCancelButtonPressed) name:kUploadVideoCancelButtonPressed object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadVideoUploadButtonPressed:) name:kUploadVideoUploadButonPressed object:nil];
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
    
    [self.addVideoButton customizeButton];
    
    [self.loadingActivityIndicator startAnimating];
    
    [combinedVideos retrieveVideos:FALSE];
    self.videoTableView.hidden = TRUE;
    
    [self addPullToRefreshHeader];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[MyAdBannerView sharedInstance] setViewController:self withContentView:self.contentView];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.headerView = nil;
    self.headerLabel = nil;
    self.homeButton = nil;
    self.videoTableView = nil;
    self.videoTableViewCell = nil;
    self.addVideoButton = nil;
    self.loadingLabel = nil;
    self.loadingActivityIndicator = nil;
    self.refreshHeaderView = nil;
    self.refreshLabel = nil;
    self.refreshArrow = nil;
    self.refreshSpinner = nil;
    
}


-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[MyAdBannerView sharedInstance] removeViewController];
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark IB Actions
-(void)homeButtonPressed {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"removeVideoView" object:self];    
}

-(IBAction)addVideoButtonPressed {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Take Video",@"Choose From Library", nil];
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    [actionSheet showInView:self.view];
    
    
}



#pragma mark UITableView delegate & data source functions
- (NSInteger)tableView:(UITableView *)theTableView numberOfRowsInSection:(NSInteger)section
{
    if (combinedVideos.retrievingVideos &&
        combinedVideos.retrievingMore) {
        return combinedVideos.combinedVideosArray.count + 1;
    } else {
        return combinedVideos.combinedVideosArray.count;
    }
        
}

#define kVideoTableViewCellDescription @"VideoTableViewCellDescription"
#define kLoadingCellIdentifier @"LoadingCellIdentifer"
#define kOwnerImageViewTag 1
#define kDateLabelTag 2 
#define kCommentsLikesButtonTag 3
#define kActionButtonTag 4
#define kVideoImageViewTag 5
#define kDescriptionLabelTag 6
#define kNumCommentsLabelTag 7
#define kNumLikesLabelTag 8
#define kCellSeparatorTag 9

#define kMinDescriptionLabelY 222
#define kVideoImageViewWidth 260
#define kVideoImageViewHeight 310
#define kVideoImageViewX 53
#define kVideoImageViewY 7
#define kDescriptionLabelHeight 33
#define kDescriptionLabelWidth 320

- (UITableViewCell *)tableView:(UITableView *)theTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (combinedVideos.retrievingVideos &&
        combinedVideos.retrievingMore &&
        indexPath.row == combinedVideos.combinedVideosArray.count) {
        
        UITableViewCell *cell = [theTableView dequeueReusableCellWithIdentifier:kLoadingCellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kLoadingCellIdentifier];
        }
        
        // loading cell view    
        UIActivityIndicatorView *theActivityIndicator;
        
        theActivityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        theActivityIndicator.frame = CGRectMake(140, 5, 40, 40);
        [theActivityIndicator startAnimating];
        [cell addSubview:theActivityIndicator];
        
        UIView *separatorLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.videoTableView.frame.size.width, 1.0)];
        separatorLine.backgroundColor = [UIColor blackColor];
        [cell addSubview:separatorLine];
        
        return cell;
        
    } else {
        
        Video *theVideo = [combinedVideos.combinedVideosArray objectAtIndex:indexPath.row];
        
        UITableViewCell *cell = [theTableView dequeueReusableCellWithIdentifier:kVideoTableViewCellDescription];
        if (cell == nil) {
            [[NSBundle mainBundle] loadNibNamed:@"VideoTableViewCell" owner:self options:nil];
            cell = videoTableViewCell;
            self.videoTableViewCell = nil;
            UIButton *commentsLikesButton = (UIButton *)[cell viewWithTag:kCommentsLikesButtonTag];
            [commentsLikesButton customizeButton];
            [self setupCommentsLikesButton:commentsLikesButton];
            UIButton *actionButton = (UIButton *)[cell viewWithTag:kActionButtonTag];
            [actionButton customizeButton];
            // add gesture recognizer for photoImageView
            UITapGestureRecognizer *videoTap = [[UITapGestureRecognizer alloc]
                                                initWithTarget:self action:@selector(handleVideoTap:)];
            UIImageView *videoImageView = (UIImageView *)[cell viewWithTag:kVideoImageViewTag];
            videoImageView.userInteractionEnabled = YES;
            
            [videoImageView addGestureRecognizer:videoTap];
            
        }
        
        // configure video image view
        UIImageView *videoImageView = (UIImageView *)[cell viewWithTag:kVideoImageViewTag];
        videoImageView.image = theVideo.picture;
    /*    CGRect videoRect = [self aspectFittedRect:CGRectMake(0, 0, theVideo.picture.size.width, theVideo.picture.size.height) max:CGRectMake(kVideoImageViewX, kVideoImageViewY, kVideoImageViewWidth, kVideoImageViewHeight)];
        videoImageView.frame = videoRect;
    */    
        
        // configure owner image view
        UIImageView *ownerImageView = (UIImageView *)[cell viewWithTag:kOwnerImageViewTag];
        if (theVideo.owner == kSelf) {
            ownerImageView.image = [Myself sharedInstance].picture;
        } else {
            ownerImageView.image = [Partner sharedInstance].picture;
        }
        
        [self configureImageViewBorder:ownerImageView withBorderWidth:2.0];
        
        // configure date label
        UILabel *dateLabel = (UILabel *)[cell viewWithTag:kDateLabelTag];
        NSDateFormatter *outDF = [[NSDateFormatter alloc] init];
        [outDF setDateFormat:@"M/d/yy"];
        dateLabel.text = [outDF stringFromDate:theVideo.createdTime];
        dateLabel.adjustsFontSizeToFitWidth = TRUE;
        
        // configure view comments button
        UILabel *numCommentsLabel = (UILabel *)[cell viewWithTag:kNumCommentsLabelTag];
        UILabel *numLikesLabel = (UILabel *)[cell viewWithTag:kNumLikesLabelTag];
        if ([theVideo.comments count] > 0) {
            numCommentsLabel.hidden = NO;
            numCommentsLabel.text = [NSString stringWithFormat:@"%d", theVideo.comments.count];
        } else {
            numCommentsLabel.hidden = YES;
        }
        
        if ([theVideo.likes count] > 0) {
            numLikesLabel.hidden = NO;
            numLikesLabel.text = [NSString stringWithFormat:@"%d", theVideo.likes.count];
        } else {
            numLikesLabel.hidden = YES;
        }
        
        UILabel *descriptionLabel = (UILabel *)[cell viewWithTag:kDescriptionLabelTag];
        descriptionLabel.text = theVideo.name;
        float descriptionLabelY = ((videoImageView.frame.origin.y + videoImageView.frame.size.height + 5) >= kMinDescriptionLabelY) ? (videoImageView.frame.origin.y + videoImageView.frame.size.height + 5) : kMinDescriptionLabelY;
        
        descriptionLabel.frame = CGRectMake(descriptionLabel.frame.origin.x, descriptionLabelY, descriptionLabel.frame.size.width, descriptionLabel.frame.size.height);
        
        return cell;
    }    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (combinedVideos.retrievingVideos &&
        combinedVideos.retrievingMore &&
        indexPath.row == combinedVideos.combinedVideosArray.count) {
        return kLoadingCellHeight;
    } else {
        Video *theVideo = [combinedVideos.combinedVideosArray objectAtIndex:indexPath.row];
        
        CGRect cellRect = [self cellRectForVideo:theVideo];
            
        return cellRect.size.height;
    }
}

/*- (UIView *)tableView:(UITableView *)theTableView viewForFooterInSection:(NSInteger)section {
    return [[UIView new] autorelease];
}
*/

#pragma mark other functions

-(void)setupCommentsLikesButton:(UIButton *)commentsLikesButton {
    UIImageView *likeSymbol = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"heart.png"]];
    likeSymbol.frame = CGRectMake(5, 5, 30, 30);
    likeSymbol.backgroundColor = [UIColor clearColor];
    likeSymbol.userInteractionEnabled = FALSE;
    likeSymbol.exclusiveTouch = FALSE;
    [commentsLikesButton addSubview:likeSymbol];
    
    UIImageView *commentSymbol = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"comment_no_lines.png"]];
    commentSymbol.frame = CGRectMake(5, 45, 30, 30);
    commentSymbol.backgroundColor = [UIColor clearColor];
    commentSymbol.userInteractionEnabled = FALSE;
    commentSymbol.exclusiveTouch = FALSE;
    [commentsLikesButton addSubview:commentSymbol];
    
    UILabel *numCommentsLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 47, 20, 20)];
    numCommentsLabel.font = [UIFont systemFontOfSize:15.0];
    numCommentsLabel.textAlignment = UITextAlignmentCenter;
    numCommentsLabel.adjustsFontSizeToFitWidth = YES;
    numCommentsLabel.textColor = [UIColor blackColor];
    numCommentsLabel.backgroundColor = [UIColor clearColor];
    numCommentsLabel.userInteractionEnabled = FALSE;
    numCommentsLabel.exclusiveTouch = FALSE;
    numCommentsLabel.tag = kNumCommentsLabelTag;
    [commentsLikesButton addSubview:numCommentsLabel];
    UILabel *numLikesLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 7, 20, 20)];
    numLikesLabel.font = [UIFont systemFontOfSize:15.0];
    numLikesLabel.textAlignment = UITextAlignmentCenter;
    numLikesLabel.adjustsFontSizeToFitWidth = YES;
    numLikesLabel.textColor = [UIColor blackColor];
    numLikesLabel.backgroundColor = [UIColor clearColor];
    numLikesLabel.userInteractionEnabled = FALSE;
    numLikesLabel.exclusiveTouch = FALSE;
    numLikesLabel.tag = kNumLikesLabelTag;
    [commentsLikesButton addSubview:numLikesLabel];
    
    
}


-(CGRect)cellRectForVideo:(Video *)theVideo {
    CGRect ImageViewRect = CGRectMake(kVideoImageViewX, kVideoImageViewY, kVideoImageViewWidth, kVideoImageViewHeight);
    
//    CGRect videoRect = [self aspectFittedRect:CGRectMake(0, 0, theVideo.picture.size.width, theVideo.picture.size.height) max:ImageViewRect];
    
    float descriptionLabelY = ((ImageViewRect.origin.y + ImageViewRect.size.height + 5) >= kMinDescriptionLabelY) ? (ImageViewRect.origin.y + ImageViewRect.size.height + 5) : kMinDescriptionLabelY;
    
    float descriptionHeight;
    
    if ([theVideo.name isEqualToString:@""] || theVideo.name == nil)
        descriptionHeight = 0;
    else
        descriptionHeight = kDescriptionLabelHeight;
    
    return CGRectMake(0, 0, kDescriptionLabelWidth, descriptionLabelY + descriptionHeight + 10);
    
}

-(void)likeButtonPressed {
    
    BOOL videoIsCurrentlyNotLiked = TRUE;
    
    for (NSDictionary *likeDictionary in currentVideo.likes) {
        if ([[likeDictionary objectForKey:@"id"] isEqualToString:[Myself sharedInstance].FBID]) {
            videoIsCurrentlyNotLiked = FALSE;
            break;
        }
    }
    
    if (videoIsCurrentlyNotLiked) {
        [combinedVideos likeVideo:currentVideo.FBID];
    } else {
        [combinedVideos unlikeVideo:currentVideo.FBID];
    }
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

-(void)takeVideoButtonPressed {
    UIImagePickerController *imgPicker = [[UIImagePickerController alloc] init];
    imgPicker.delegate = self;
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] &&
        [[UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera] indexOfObjectIdenticalTo:(NSString *)kUTTypeMovie] != NSNotFound) {
        imgPicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        imgPicker.mediaTypes = [[NSArray alloc] initWithObjects:(NSString *)kUTTypeMovie, nil];        
        [[MyAdBannerView sharedInstance] removeViewController];
        [self presentViewController:imgPicker animated:YES completion:NULL];
    } else {
        UIAlertView *noVideoAlert = [[UIAlertView alloc] initWithTitle:nil message:@"Sorry, your device is unable to capture video" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [noVideoAlert show];
    }
    
    
}

-(void)chooseFromLibraryButtonPressed {
    UIImagePickerController *imgPicker = [[UIImagePickerController alloc] init];
    imgPicker.delegate = self;
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary] &&
        [[UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypePhotoLibrary] indexOfObjectIdenticalTo:(NSString *)kUTTypeMovie] != NSNotFound) {
        imgPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        imgPicker.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *)kUTTypeMovie, nil]; 
        [[MyAdBannerView sharedInstance] removeViewController];
        [self presentViewController:imgPicker animated:YES completion:NULL];
    } else {
        UIAlertView *noVideoAlert = [[UIAlertView alloc] initWithTitle:nil message:@"Sorry, your device does not support video" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [noVideoAlert show];
    }
    
    
}

-(void)allVideosReceived {
    NSLog(@"All Videos Received");
    
    if (!loadingLabel.hidden) {
        [self.loadingActivityIndicator stopAnimating];
        self.loadingLabel.hidden = TRUE;
    }
    
    if (isRefreshing) {
        [self pullToRefreshStopLoading];
    }
        
    self.videoTableView.hidden = FALSE;
    
    [self.videoTableView reloadData];
    
}

-(IBAction)commentsLikesButtonPressed:(id)sender {
    /*
    UIButton *button = (UIButton *)sender;
    UITableViewCell *cell = (UITableViewCell *)[[button superview] superview];
    int row = [self.videoTableView indexPathForCell:cell].row;    
        
    Video *theVideo = [combinedVideos.combinedVideosArray objectAtIndex:row];

    CommentsViewController *commentsVC = [[CommentsViewController alloc] initWithFBObject:theVideo];
    [[MyAdBannerView sharedInstance] removeViewController];    
    [self presentViewController:commentsVC animated:YES completion:NULL];
    */

}

-(IBAction)actionButtonPressed:(id)sender {
    UIButton *button = (UIButton *)sender;
    UITableViewCell *cell = (UITableViewCell *)[[button superview] superview];
    int row = [self.videoTableView indexPathForCell:cell].row;    
    
    currentVideo = [combinedVideos.combinedVideosArray objectAtIndex:row];
    
    NSString *likeTitle;
    
    // configure like title
    likeTitle = @"Like";
    
    for (NSDictionary *likeDictionary in currentVideo.likes) {
        if ([[likeDictionary objectForKey:@"id"] isEqualToString:[Myself sharedInstance].FBID]) {
            likeTitle = @"Unlike";
        }
    }
    
    
    videoDetailActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles: likeTitle, @"Save Video", nil];        
    
    videoDetailActionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    [videoDetailActionSheet showInView:self.view];
    
}

-(void)videoCommentsDoneButtonPressed {
    [self dismissViewControllerAnimated:YES completion:^{
        [[MyAdBannerView sharedInstance] setViewController:self withContentView:self.contentView];
    }];
    
    [self.videoTableView reloadData];
}

-(void)handleVideoTap:(UIGestureRecognizer *)gesture {
    UIImageView *videoImageView = (UIImageView *)[gesture view];
    UITableViewCell *cell = (UITableViewCell *)[[videoImageView superview] superview];
    int row = [self.videoTableView indexPathForCell:cell].row;
    
    currentVideo = [combinedVideos.combinedVideosArray objectAtIndex:row];
        
    MPMoviePlayerViewController *playerVC = [[MPMoviePlayerViewController alloc] initWithContentURL:currentVideo.videoURL];
    playerVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    playerVC.wantsFullScreenLayout = TRUE;
    playerVC.moviePlayer.controlStyle = MPMovieControlStyleNone;
    
    [self performSelector:@selector(enableVideoControls:) withObject:playerVC.moviePlayer afterDelay:2.0];
    
    // remove from notification
    [[NSNotificationCenter defaultCenter] removeObserver:playerVC
                                                    name:MPMoviePlayerPlaybackDidFinishNotification
                                                   object:playerVC.moviePlayer];
    // register for notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleMoviePlayerNotification:) name:MPMoviePlayerPlaybackDidFinishNotification object:playerVC.moviePlayer];    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleMoviePlayerNotification:) name:MPMoviePlayerLoadStateDidChangeNotification object:playerVC.moviePlayer];    
        
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    
    [[MyAdBannerView sharedInstance] removeViewController];

    [self presentViewController:playerVC animated:YES completion:NULL];
    
}

-(void)enableVideoControls:(MPMoviePlayerController *)player {
    if (player) {
        player.controlStyle = MPMovieControlStyleFullscreen;
    }
}

-(void)handleMoviePlayerNotification:(NSNotification *)notification {
    if ([[notification name] isEqualToString:MPMoviePlayerPlaybackDidFinishNotification]) {
        
        NSNumber *finishReason = [[notification userInfo] objectForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey];
        // Dismiss the view controller ONLY when the reason is not "playback ended"
        if ([finishReason intValue] != MPMovieFinishReasonPlaybackEnded)
        {
            MPMoviePlayerController *moviePlayer = [notification object];
            
            // Remove this class from the observers
            [[NSNotificationCenter defaultCenter] removeObserver:self
                                                            name:MPMoviePlayerPlaybackDidFinishNotification
                                                          object:moviePlayer];
            [[NSNotificationCenter defaultCenter] removeObserver:self
                                                            name:MPMoviePlayerLoadStateDidChangeNotification
                                                          object:moviePlayer];
            
            
            [[UIApplication sharedApplication] setStatusBarHidden:NO];
            // Dismiss the view controller
            [self dismissViewControllerAnimated:YES completion:^{
                [[MyAdBannerView sharedInstance] setViewController:self withContentView:self.contentView];                
            }];
            [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackOpaque;            

            
        }
        
    } else if ([[notification name] isEqualToString:MPMoviePlayerLoadStateDidChangeNotification]) {
        MPMoviePlayerController *moviePlayer = [notification object];
        if (moviePlayer.loadState == MPMovieLoadStatePlayable ||
            moviePlayer.loadState == MPMovieLoadStatePlaythroughOK) {
            [self enableVideoControls:moviePlayer];
        }
        
    }
    
}

-(CGRect)aspectFittedRect:(CGRect)inRect max:(CGRect)maxRect {
    float scaleFactor = maxRect.size.width/inRect.size.width;
    
    CGRect newRect = CGRectMake(maxRect.origin.x, maxRect.origin.y, maxRect.size.width, inRect.size.height*scaleFactor);
    
    if (newRect.size.height < kMinDescriptionLabelY) {
        newRect.origin.y += (kMinDescriptionLabelY - newRect.size.height)/2.0;
    }
    
    return CGRectIntegral(newRect);
    
}


-(void)receivedCommentsAndLikes {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self.videoTableView reloadData];
}

-(void)configureImageViewBorder:(UIImageView *)theImageView withBorderWidth:(CGFloat)borderWidth {
    CALayer* layer = [theImageView layer];
    [layer setBorderWidth:borderWidth];
    [layer setBorderColor:[UIColor whiteColor].CGColor];
    [layer setShadowOffset:CGSizeMake(-3.0, 3.0)];
    [layer setShadowRadius:3.0];
    [layer setShadowOpacity:1.0];
}


    
#pragma mark Action Sheet delegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (actionSheet == videoDetailActionSheet) {
        if (buttonIndex == 0) {
            [self likeButtonPressed];
        }
        
        else {
            // save video
            [combinedVideos saveVideo:currentVideo.videoURL];
        }
        
    } else {
        if (buttonIndex == 0) {
            [self takeVideoButtonPressed];
        } else if (buttonIndex == 1) {
            [self chooseFromLibraryButtonPressed];
        }
    }
}

#pragma mark Image Picker functions
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    self.videoToUploadURL = [info objectForKey:UIImagePickerControllerMediaURL];
    
    MPMoviePlayerController *player = [[MPMoviePlayerController alloc] initWithContentURL:self.videoToUploadURL];
    NSTimeInterval thumbnailImageTime = (player.duration > 1.0) ? 1.0 : 0.0;
    UIImage *thumbnailImage = [player thumbnailImageAtTime:thumbnailImageTime timeOption:MPMovieTimeOptionNearestKeyFrame];
    [player stop];
    
    UploadVideoViewController *uploadVC = [[UploadVideoViewController alloc] initWithVideoPicture:thumbnailImage];
    
    [picker pushViewController:uploadVC animated:YES];
    
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:^{
        [[MyAdBannerView sharedInstance] setViewController:self withContentView:self.contentView];
    }];

}

#pragma mark Upload Video delegate
-(void)uploadVideoCancelButtonPressed {
    [self dismissViewControllerAnimated:YES completion:^{
        [[MyAdBannerView sharedInstance] setViewController:self withContentView:self.contentView];
    }];

}

-(void)uploadVideoUploadButtonPressed:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    
    self.captionToUpload = [userInfo objectForKey:@"captionToUpload"];
    
    [self createUploadingViews];
    
    [combinedVideos uploadVideo:self.videoToUploadURL withCaption:self.captionToUpload];
        
    [self dismissViewControllerAnimated:YES completion:^{
        [[MyAdBannerView sharedInstance] setViewController:self withContentView:self.contentView];
    }];
    
}

#pragma mark uploading view functions
-(void)createUploadingViews {
    // description view
    UIView *theUploadingBackground = [[UIView alloc] initWithFrame:CGRectMake(60, 140, 200, 150)];
    self.uploadingBackground = theUploadingBackground;
    self.uploadingBackground.backgroundColor = [UIColor blackColor];
    self.uploadingBackground.alpha = 0.7;
    [self.view addSubview:self.uploadingBackground];    
    self.uploadingBackground.layer.cornerRadius = 12.0f;
    self.uploadingBackground.layer.masksToBounds = YES;
    
    UILabel *theUploadingLabel = [[UILabel alloc] initWithFrame:CGRectMake(65, 150, 190, 80)];
    self.uploadingLabel = theUploadingLabel;
    self.uploadingLabel.text = @"Uploading Video";
    self.uploadingLabel.textColor = [UIColor whiteColor];
    self.uploadingLabel.font = [UIFont systemFontOfSize:30.0];
    self.uploadingLabel.textAlignment = UITextAlignmentCenter;
    self.uploadingLabel.adjustsFontSizeToFitWidth = YES;
    self.uploadingLabel.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.uploadingLabel];
    
    UIActivityIndicatorView *theUploadingAI = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(120, 210, 80, 80)];
    self.uploadingActivityIndicator = theUploadingAI;
    self.uploadingActivityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    [self.view addSubview:self.uploadingActivityIndicator]; 
    
    [self.uploadingActivityIndicator startAnimating];
    
}

-(void)removeUploadingViews {
    [self.uploadingBackground removeFromSuperview];
    self.uploadingBackground = nil;
    [self.uploadingLabel removeFromSuperview];
    self.uploadingLabel = nil;
    [self.uploadingActivityIndicator removeFromSuperview];
    self.uploadingActivityIndicator = nil;
    
}

#pragma mark Scroll View Delegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (isRefreshing) {
        // Update the content inset, good for section headers
        if (scrollView.contentOffset.y > 0)
            self.videoTableView.contentInset = UIEdgeInsetsZero;
        else if (scrollView.contentOffset.y >= -REFRESH_HEADER_HEIGHT)
            self.videoTableView.contentInset = UIEdgeInsetsMake(-scrollView.contentOffset.y, 0, 0, 0);
    } else if (isDragging && scrollView.contentOffset.y < 0) {
        // Update the arrow direction and label
        [UIView beginAnimations:nil context:NULL];
        if (scrollView.contentOffset.y < -REFRESH_HEADER_HEIGHT) {
            // User is scrolling above the header
            refreshLabel.text = @"Release to refresh...";
            [refreshArrow layer].transform = CATransform3DMakeRotation(M_PI, 0, 0, 1);
        } else { // User is scrolling somewhere within the header
            refreshLabel.text = @"Pull down to refresh...";
            [refreshArrow layer].transform = CATransform3DMakeRotation(M_PI * 2, 0, 0, 1);
        }
        [UIView commitAnimations];
    }

    float bottomEdge = scrollView.contentOffset.y + scrollView.frame.size.height;
    if (bottomEdge >= scrollView.contentSize.height + 20 &&
        combinedVideos.combinedVideosArray.count < combinedVideos.totalVideos &&        
        !combinedVideos.retrievingVideos) {
        // we are at the end
        NSLog(@"Reached the bottom");
                
        [combinedVideos retrieveVideos:YES];
                
        [self.videoTableView reloadData];
    }
}

#pragma mark pull to refresh functions

-(void)addPullToRefreshHeader {
    refreshHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0 - REFRESH_HEADER_HEIGHT, 320, REFRESH_HEADER_HEIGHT)];
    refreshHeaderView.backgroundColor = [UIColor clearColor];
    
    refreshLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, REFRESH_HEADER_HEIGHT)];
    refreshLabel.backgroundColor = [UIColor clearColor];
    refreshLabel.font = [UIFont fontWithName:@"Copperplate-Bold" size:14.0];;
    refreshLabel.textAlignment = UITextAlignmentCenter;
    refreshLabel.textColor = [UIColor whiteColor];
    
    refreshArrow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"arrow_down.png"]];
    refreshArrow.frame = CGRectMake(floorf((REFRESH_HEADER_HEIGHT - 27) / 2),
                                    (floorf(REFRESH_HEADER_HEIGHT - 44) / 2),
                                    27, 44);
    
    refreshSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    refreshSpinner.frame = CGRectMake(floorf(floorf(REFRESH_HEADER_HEIGHT - 20) / 2), floorf((REFRESH_HEADER_HEIGHT - 20) / 2), 20, 20);
    refreshSpinner.hidesWhenStopped = YES;
    
    [refreshHeaderView addSubview:refreshLabel];
    [refreshHeaderView addSubview:refreshArrow];
    [refreshHeaderView addSubview:refreshSpinner];
    [self.videoTableView addSubview:refreshHeaderView];
}


-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (isRefreshing) return;
    isDragging = YES;
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (isRefreshing) return;
    isDragging = NO;
    if (scrollView.contentOffset.y <= -REFRESH_HEADER_HEIGHT) {
        // Released above the header
        [self pullToRefreshStartLoading];
    }
}

-(void)pullToRefreshStartLoading {
    isRefreshing = YES;
    
    // Show the header
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3];
    self.videoTableView.contentInset = UIEdgeInsetsMake(REFRESH_HEADER_HEIGHT, 0, 0, 0);
    refreshLabel.text = @"Loading...";
    refreshArrow.hidden = YES;
    [refreshSpinner startAnimating];
    [UIView commitAnimations];
    
    // Refresh action!
    [self refreshTable];
}

- (void)pullToRefreshStopLoading {
    isRefreshing = NO;
    
    // Hide the header
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDuration:0.3];
    [UIView setAnimationDidStopSelector:@selector(stopLoadingComplete:finished:context:)];
    self.videoTableView.contentInset = UIEdgeInsetsZero;
    UIEdgeInsets tableContentInset = self.videoTableView.contentInset;
    tableContentInset.top = 0.0;
    self.videoTableView.contentInset = tableContentInset;
    [refreshArrow layer].transform = CATransform3DMakeRotation(M_PI * 2, 0, 0, 1);
    [UIView commitAnimations];
}

- (void)stopLoadingComplete:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
    // Reset the header
    refreshLabel.text = @"Pull down to refresh...";
    refreshArrow.hidden = NO;
    [refreshSpinner stopAnimating];
}

- (void)refreshTable {
    // This is just a demo. Override this method with your custom reload action.
    // Don't forget to call stopLoading at the end.
    NSLog(@"This will refresh table");
    [combinedVideos retrieveVideos:FALSE];    
}

#pragma mark Handlers


-(void)handleUploadVideoRequestResponse:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    NSLog(@"Successful Upload of Video %@", [userInfo objectForKey:@"id"]);
    [self removeUploadingViews];
    [combinedVideos retrieveVideos:FALSE];
    // send push notification
    NSString *pushMessage = [NSString stringWithFormat:@"%@ just uploaded a new video.", myself.name];
    NSString *videoFBID = [userInfo objectForKey:@"id"];
    NSDictionary *pushUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:pushMessage, @"alert",
                                  kVideoNotification, kPushTypeKey,
                                  nil];
    
    [PFPush sendPushDataToChannelInBackground:[PushNotificationController sharedInstance].sendChannel withData:pushUserInfo];
    
}

-(void)handleUploadVideoError {
    [self removeUploadingViews];
    UIAlertView *uploadVideoAlert = [[UIAlertView alloc] initWithTitle:nil message:@"Upload video error.  Please try again later" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [uploadVideoAlert show];
    
}

#pragma mark like functions
-(void)handleLikeRequestResponse {
    [[CombinedVideos sharedInstance] retrieveCommentsAndLikes];
}

-(void)handleUnlikeRequestResponse {
    [[CombinedVideos sharedInstance] retrieveCommentsAndLikes];
}

-(void)handleLikeRequestError {
    
    UIAlertView *likeAlert = [[UIAlertView alloc] initWithTitle:nil message:@"Error liking video.  Please try later" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [likeAlert show];
}

-(void)handleUnlikeRequestError {
    UIAlertView *unlikeAlert = [[UIAlertView alloc] initWithTitle:nil message:@"Error unliking video.  Please try later" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [unlikeAlert show];
    
}



@end
