//
//  PhotosViewController.m
//  PowerOfTwo
//
//  Created by Brian Bernberg on 10/9/11.
//  Copyright (c) 2011 Bern Software. All rights reserved.
//


#import "PhotosViewController.h"
#import "Partner.h"
#import "Myself.h"
#import "Photo.h"
#import "Constants.h"
#import <Quartzcore/QuartzCore.h>
#import "UploadPhotoViewController.h"
#import "CombinedPhotos.h"
#import "CommentsViewController.h"
#import "PhotoDetailViewController.h"
#import "PushNotificationController.h"
#import "UIButton+myButton.h"
#import "MyAdBannerView.h"

#define kInterPhotoHeight 3.0f
#define kMaxPhotoDimension 480
#define REFRESH_HEADER_HEIGHT 52.0f
#define kLoadingCellHeight 50.0f


@interface PhotosViewController()
-(void)handleUploadPhotoRequestResponse:(NSNotification *)notification;
-(void)handleUploadPhotoError;
-(void)handleLikeRequestResponse;
-(void)handleLikeRequestError;
-(void)handleUnlikeRequestResponse;
-(void)handleUnlikeRequestError;

-(void)takePictureButtonPressed;
-(void)chooseFromLibraryButtonPressed;
-(void)createUploadingViews;
-(void)removeUploadingViews;
-(void)allPicturesReceived;
-(void)receivedCommentsAndLikes;
-(void)photoCommentsDoneButtonPressed;
-(void)setupCommentsLikesButton:(UIButton *)commentsLikesButton;
-(void)likeButtonPressed;
-(CGRect)aspectFittedRect:(CGRect)inRect max:(CGRect)maxRect;
-(CGRect)cellRectForPhoto:(Photo *)thePhoto;
-(void)handlePhotoTap:(UIGestureRecognizer *)gesture;
-(void)dismissPhotoDetailView;

// pull to refresh functions
- (void)addPullToRefreshHeader;
- (void)pullToRefreshStartLoading;
- (void)pullToRefreshStopLoading;
- (void)refreshTable;
-(void)configureImageViewBorder:(UIImageView *)theImageView withBorderWidth:(CGFloat)borderWidth;

@end

@implementation PhotosViewController

@synthesize headerView, headerLabel, homeButton, addPhotoButton, photoTableView, photoTableViewCell, loadingLabel, loadingActivityIndicator, uploadingLabel, uploadingBackground, uploadingActivityIndicator, imageToUpload, captionToUpload, photoToDisplay, refreshHeaderView, refreshLabel, refreshArrow, refreshSpinner, contentView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        partner = [Partner sharedInstance];
        myself = [Myself sharedInstance];
        combinedPhotos = [CombinedPhotos sharedInstance];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(allPicturesReceived) name:kAllPhotosReceived object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(photoCommentsDoneButtonPressed) name:@"photoCommentsDoneButtonPressed" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissPhotoDetailView) name:kDismissPhotoDetailView object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedCommentsAndLikes) name:@"receivedCommentsAndLikes" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLikeRequestResponse) name:kPhotoLikeRequestSuccess object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLikeRequestError) name:kPhotoLikeRequestError object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUnlikeRequestResponse) name:kPhotoUnlikeRequestSuccess object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUnlikeRequestError) name:kPhotoUnlikeRequestError object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUploadPhotoRequestResponse:) name:kUploadPhotoRequestSuccess object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUploadPhotoRequestError) name:kUploadPhotoRequestError object:nil];

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
    
    [self.addPhotoButton customizeButton];
    
    [self.loadingActivityIndicator startAnimating];
    
    [combinedPhotos retrievePhotos:FALSE];
    self.photoTableView.hidden = TRUE;
    
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
    self.photoTableView = nil;
    self.photoTableViewCell = nil;
    self.addPhotoButton = nil;
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
    [[NSNotificationCenter defaultCenter] postNotificationName:@"removePhotoView" object:self];    
}

-(IBAction)addPhotoButtonPressed {
    savePhotoToLibrary = FALSE;
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Take Photo",@"Choose From Library", nil];
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    [actionSheet showInView:self.view];

    
}



#pragma mark UITableView delegate & data source functions
- (NSInteger)tableView:(UITableView *)theTableView numberOfRowsInSection:(NSInteger)section
{
    if (combinedPhotos.retrievingPhotos &&
        combinedPhotos.retrievingMore ) {
        return combinedPhotos.combinedPhotosArray.count + 1;
    } else {
        return combinedPhotos.combinedPhotosArray.count;
    }
    
}

#define kPhotoTableViewCellDescription @"PhotoTableViewCellDescription"
#define kLoadingCellIdentifier @"LoadingCellIdentifier"
#define kOwnerImageViewTag 1
#define kDateLabelTag 2 
#define kCommentsLikesButtonTag 3
#define kActionButtonTag 4
#define kPhotoImageViewTag 5
#define kDescriptionLabelTag 6
#define kNumCommentsLabelTag 7
#define kNumLikesLabelTag 8
#define kCellSeparatorTag 9

#define kMinDescriptionLabelY 222
#define kPhotoImageViewWidth 260
#define kPhotoImageViewHeight 310
#define kPhotoImageViewX 53
#define kPhotoImageViewY 7
#define kDescriptionLabelHeight 33
#define kDescriptionLabelWidth 320

- (UITableViewCell *)tableView:(UITableView *)theTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (combinedPhotos.retrievingPhotos &&
        combinedPhotos.retrievingMore &&
        indexPath.row == combinedPhotos.combinedPhotosArray.count) {
        
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
        
        UIView *separatorLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.photoTableView.frame.size.width, 1.0)];
        separatorLine.backgroundColor = [UIColor blackColor];
        [cell addSubview:separatorLine];
        
        return cell;
        
    } else {
    
        Photo *thePhoto = [combinedPhotos.combinedPhotosArray objectAtIndex:indexPath.row];
        
        UITableViewCell *cell = [theTableView dequeueReusableCellWithIdentifier:kPhotoTableViewCellDescription];
        if (cell == nil) {
            [[NSBundle mainBundle] loadNibNamed:@"PhotoTableViewCell" owner:self options:nil];
            cell = photoTableViewCell;
            self.photoTableViewCell = nil;
            UIButton *commentsLikesButton = (UIButton *)[cell viewWithTag:kCommentsLikesButtonTag];
            [commentsLikesButton customizeButton];
            [self setupCommentsLikesButton:commentsLikesButton];
            UIButton *actionButton = (UIButton *)[cell viewWithTag:kActionButtonTag];
            [actionButton customizeButton];
            // add gesture recognizer for photoImageView
            UITapGestureRecognizer *photoTap = [[UITapGestureRecognizer alloc]
                                                     initWithTarget:self action:@selector(handlePhotoTap:)];
            UIImageView *photoImageView = (UIImageView *)[cell viewWithTag:kPhotoImageViewTag];
            photoImageView.userInteractionEnabled = YES;
        
            [photoImageView addGestureRecognizer:photoTap];
            
        }

        // configure photo image view
        UIImageView *photoImageView = (UIImageView *)[cell viewWithTag:kPhotoImageViewTag];
        photoImageView.image = thePhoto.picture;
        CGRect photoRect = [self aspectFittedRect:CGRectMake(0, 0, thePhoto.picture.size.width, thePhoto.picture.size.height) max:CGRectMake(kPhotoImageViewX, kPhotoImageViewY, kPhotoImageViewWidth, kPhotoImageViewHeight)];
        photoImageView.frame = photoRect;

        // configure owner image view
        UIImageView *ownerImageView = (UIImageView *)[cell viewWithTag:kOwnerImageViewTag];
        
        if (thePhoto.owner == kSelf) {
            ownerImageView.image = [Myself sharedInstance].picture;
        } else {
            ownerImageView.image = [Partner sharedInstance].picture;
        }
        [self configureImageViewBorder:ownerImageView withBorderWidth:2.0f];
        
        // configure date label
        UILabel *dateLabel = (UILabel *)[cell viewWithTag:kDateLabelTag];
        NSDateFormatter *outDF = [[NSDateFormatter alloc] init];
        [outDF setDateFormat:@"M/d/yy"];
        dateLabel.text = [outDF stringFromDate:thePhoto.createdTime];
        dateLabel.adjustsFontSizeToFitWidth = TRUE;
        
        // configure view comments button
        UILabel *numCommentsLabel = (UILabel *)[cell viewWithTag:kNumCommentsLabelTag];
        UILabel *numLikesLabel = (UILabel *)[cell viewWithTag:kNumLikesLabelTag];
        if ([thePhoto.comments count] > 0) {
            numCommentsLabel.hidden = NO;
            numCommentsLabel.text = [NSString stringWithFormat:@"%d", thePhoto.comments.count];
        } else {
            numCommentsLabel.hidden = YES;
        }

        if ([thePhoto.likes count] > 0) {
            numLikesLabel.hidden = NO;
            numLikesLabel.text = [NSString stringWithFormat:@"%d", thePhoto.likes.count];
        } else {
            numLikesLabel.hidden = YES;
        }

        UILabel *descriptionLabel = (UILabel *)[cell viewWithTag:kDescriptionLabelTag];
        descriptionLabel.text = thePhoto.name;
        float descriptionLabelY = ((photoRect.origin.y + photoRect.size.height + 5) >= kMinDescriptionLabelY) ? (photoRect.origin.y + photoRect.size.height + 5) : kMinDescriptionLabelY;
        
        descriptionLabel.frame = CGRectMake(descriptionLabel.frame.origin.x, descriptionLabelY, descriptionLabel.frame.size.width, descriptionLabel.frame.size.height);
        
        return cell;
    }    
        
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (combinedPhotos.retrievingPhotos &&
        combinedPhotos.retrievingMore &&
        indexPath.row == combinedPhotos.combinedPhotosArray.count) {
        return kLoadingCellHeight;
    } else {
        Photo *thePhoto = [combinedPhotos.combinedPhotosArray objectAtIndex:indexPath.row];

        CGRect cellRect = [self cellRectForPhoto:thePhoto];
    
        return cellRect.size.height;
    }
}


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


-(CGRect)cellRectForPhoto:(Photo *)thePhoto {
    CGRect ImageViewRect = CGRectMake(kPhotoImageViewX, kPhotoImageViewY, kPhotoImageViewWidth, kPhotoImageViewHeight);
    
    CGRect photoRect = [self aspectFittedRect:CGRectMake(0, 0, thePhoto.picture.size.width, thePhoto.picture.size.height) max:ImageViewRect];
    
    float descriptionLabelY = ((photoRect.origin.y + photoRect.size.height + 5) >= kMinDescriptionLabelY) ? (photoRect.origin.y + photoRect.size.height + 5) : kMinDescriptionLabelY;
    
    float descriptionHeight;
    
    if ([thePhoto.name isEqualToString:@""] || thePhoto.name == nil)
        descriptionHeight = 0;
    else
        descriptionHeight = kDescriptionLabelHeight;
    
    return CGRectMake(0, 0, kDescriptionLabelWidth, descriptionLabelY + descriptionHeight + 10);
    
}

-(void)likeButtonPressed {
    
    BOOL pictureIsCurrentlyNotLiked = TRUE;
    
    for (NSDictionary *likeDictionary in currentPhoto.likes) {
        if ([[likeDictionary objectForKey:@"id"] isEqualToString:[Myself sharedInstance].FBID]) {
            pictureIsCurrentlyNotLiked = FALSE;
            break;
        }
    }
    
    
    if (pictureIsCurrentlyNotLiked) {
        [combinedPhotos likePhoto:currentPhoto.FBID];
    } else {
        [combinedPhotos unlikePhoto:currentPhoto.FBID];
    }
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

-(void)takePictureButtonPressed {
    savePhotoToLibrary = TRUE;
    UIImagePickerController *imgPicker = [[UIImagePickerController alloc] init];
    imgPicker.delegate = self;
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        imgPicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    
        [[MyAdBannerView sharedInstance] removeViewController];
        [self presentViewController:imgPicker animated:YES completion:NULL];
    } else {
        UIAlertView *noVideoAlert = [[UIAlertView alloc] initWithTitle:nil message:@"Sorry, your device is unable to take pictures" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [noVideoAlert show];
    }
    
    
}

-(void)chooseFromLibraryButtonPressed {
    UIImagePickerController *imgPicker = [[UIImagePickerController alloc] init];
    imgPicker.delegate = self;
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        imgPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        
        [[MyAdBannerView sharedInstance] removeViewController];
        [self presentViewController:imgPicker animated:YES completion:NULL];
    } else {
        UIAlertView *noVideoAlert = [[UIAlertView alloc] initWithTitle:nil message:@"Sorry, your device does not support photos" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [noVideoAlert show];
        
    }
    
    
}

-(void)allPicturesReceived {
    if (!loadingLabel.hidden) {
        [self.loadingActivityIndicator stopAnimating];
        self.loadingLabel.hidden = TRUE;
    }
    
    if (isRefreshing) {
        [self pullToRefreshStopLoading];
    }

    self.photoTableView.hidden = FALSE;
    [self.photoTableView reloadData];
    
    
}

-(IBAction)commentsLikesButtonPressed:(id)sender {
/*    UIButton *button = (UIButton *)sender;
    UITableViewCell *cell = (UITableViewCell *)[[button superview] superview];
    int row = [self.photoTableView indexPathForCell:cell].row;    
    
    Photo *thePhoto = [combinedPhotos.combinedPhotosArray objectAtIndex:row];
    
    CommentsViewController *commentsVC = [[CommentsViewController alloc] initWithFBObject:thePhoto andComments:thePhoto.comments andLikes:thePhoto.likes];
    
    [[MyAdBannerView sharedInstance] removeViewController];
    [self presentViewController:commentsVC animated:YES completion:NULL];
  */  
}

-(IBAction)actionButtonPressed:(id)sender {
    UIButton *button = (UIButton *)sender;
    UITableViewCell *cell = (UITableViewCell *)[[button superview] superview];
    int row = [self.photoTableView indexPathForCell:cell].row;    
        
    currentPhoto = [combinedPhotos.combinedPhotosArray objectAtIndex:row];
    
    NSString *likeTitle;
    
    // configure like title
    likeTitle = @"Like";
    
    for (NSDictionary *likeDictionary in currentPhoto.likes) {
        if ([[likeDictionary objectForKey:@"id"] isEqualToString:[Myself sharedInstance].FBID]) {
            likeTitle = @"Unlike";
        }
    }
    
    
    photoDetailActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles: likeTitle, @"Save Photo", nil];        
    
    photoDetailActionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    [photoDetailActionSheet showInView:self.view];
    
}

-(void)photoCommentsDoneButtonPressed {
    [self dismissViewControllerAnimated:YES completion:^{
        [[MyAdBannerView sharedInstance] setViewController:self withContentView:self.contentView];
    }];
     
    [self.photoTableView reloadData];
}

-(void)handlePhotoTap:(UIGestureRecognizer *)gesture {
    UIImageView *photoImageView = (UIImageView *)[gesture view];
    CGRect imageViewFrame = [[[photoImageView superview] superview] convertRect:photoImageView.frame toView:self.view.window];
        
    PhotoDetailViewController *photoDetailVC = [[PhotoDetailViewController alloc] initWithImage:photoImageView.image andFrame:imageViewFrame];
    photoDetailVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    photoDetailVC.wantsFullScreenLayout = TRUE;
    photoDetailVC.modalPresentationStyle = UIModalPresentationFullScreen;
    
    [[MyAdBannerView sharedInstance] removeViewController];
    [self presentViewController:photoDetailVC animated:YES completion:NULL];
    
}

-(void)dismissPhotoDetailView {
    [self dismissViewControllerAnimated:YES completion:^{
        [[MyAdBannerView sharedInstance] setViewController:self withContentView:self.contentView];
    }];
    
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
    [self.photoTableView reloadData];
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
    if (actionSheet == photoDetailActionSheet) {
        if (buttonIndex == 1) {
            UIImageWriteToSavedPhotosAlbum(currentPhoto.picture, nil, nil, nil);
        } else if (buttonIndex == 0) {
            [self likeButtonPressed];
        }
        
    } else {
        if (buttonIndex == 0) {
            [self takePictureButtonPressed];
        } else if (buttonIndex == 1) {
            [self chooseFromLibraryButtonPressed];
        }
    }
}

#pragma mark Image Picker functions
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *chosenImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    UploadPhotoViewController *uploadVC = [[UploadPhotoViewController alloc] initWithImage:chosenImage];
    uploadVC.delegate = self;
    
    [picker pushViewController:uploadVC animated:YES];
    

}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:^{
        [[MyAdBannerView sharedInstance] setViewController:self withContentView:self.contentView];
    }];
    
}

#pragma mark Upload Photos delegate
-(void)uploadPhotoWasCancelled:(UploadPhotoViewController *)viewController {
    [self dismissViewControllerAnimated:YES completion:^{
        [[MyAdBannerView sharedInstance] setViewController:self withContentView:self.contentView];
    }];
    
}

-(void)photoWasEdited:(UploadPhotoViewController *)viewController {
    savePhotoToLibrary = TRUE;
}

-(void)uploadPhoto:(UploadPhotoViewController *)viewController {
    // save image to library first (if applicable)
    if (savePhotoToLibrary) {
        UIImageWriteToSavedPhotosAlbum(viewController.photo, nil, nil, nil);
    }
    
    UIImage *theImage = [UIImage imageWithData:UIImageJPEGRepresentation(viewController.photo, 0.0)];

    float maxDimension = (theImage.size.width * theImage.scale > theImage.size.height * theImage.scale) ? theImage.size.width * theImage.scale : theImage.size.height * theImage.scale;
    float scaleFactor = maxDimension > kMaxPhotoDimension ? kMaxPhotoDimension / maxDimension : 1.0;
    CGSize newSize = CGSizeMake(ceilf(theImage.size.width * scaleFactor), ceilf(theImage.size.height * scaleFactor));
    UIGraphicsBeginImageContext( newSize );
    [theImage drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    self.imageToUpload = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    
    self.captionToUpload = viewController.captionTextField.text;
    
    [self createUploadingViews];
    
    [combinedPhotos uploadPhoto:self.imageToUpload withCaption:self.captionToUpload andPlace:nil];
    
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
    self.uploadingLabel.text = @"Uploading Photo";
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
            self.photoTableView.contentInset = UIEdgeInsetsZero;
        else if (scrollView.contentOffset.y >= -REFRESH_HEADER_HEIGHT)
            self.photoTableView.contentInset = UIEdgeInsetsMake(-scrollView.contentOffset.y, 0, 0, 0);
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
        combinedPhotos.combinedPhotosArray.count < combinedPhotos.totalPhotos &&                
        !combinedPhotos.retrievingPhotos) {
        // we are at the end
        NSLog(@"Reached the bottom");
        [combinedPhotos retrievePhotos:TRUE];
        [self.photoTableView reloadData];
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
    [self.photoTableView addSubview:refreshHeaderView];
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
    self.photoTableView.contentInset = UIEdgeInsetsMake(REFRESH_HEADER_HEIGHT, 0, 0, 0);
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
    self.photoTableView.contentInset = UIEdgeInsetsZero;
    UIEdgeInsets tableContentInset = self.photoTableView.contentInset;
    tableContentInset.top = 0.0;
    self.photoTableView.contentInset = tableContentInset;
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
    [combinedPhotos retrievePhotos:NO];    
    
}



-(void)handleUploadPhotoRequestResponse:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    NSLog(@"Successful Upload of Photo %@", [userInfo objectForKey:@"id"]);
    [self removeUploadingViews];
    [combinedPhotos retrievePhotos:FALSE];
    
    // send push notification
    NSString *pushMessage = [NSString stringWithFormat:@"%@ just uploaded a new photo.", myself.name];
    NSString *photoFBID = [userInfo objectForKey:@"id"];
    NSDictionary *pushUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:pushMessage, @"alert",
                              kPhotoNotification, kPushTypeKey, 
                              photoFBID, kPhotoFBIDKey,
                              nil];
    
    [PFPush sendPushDataToChannelInBackground:[PushNotificationController sharedInstance].sendChannel withData:pushUserInfo];
}
        
-(void)handleUploadPhotoError {
    [self removeUploadingViews];
    UIAlertView *uploadPhotoAlert = [[UIAlertView alloc] initWithTitle:nil message:@"Upload photo error.  Please try again later" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [uploadPhotoAlert show];

}

#pragma mark like functions
-(void)handleLikeRequestResponse {
    
    [[CombinedPhotos sharedInstance] retrieveCommentsAndLikes];
}

-(void)handleUnlikeRequestResponse {
    
    [[CombinedPhotos sharedInstance] retrieveCommentsAndLikes];
    
}

-(void)handleLikeRequestError {
    
    UIAlertView *likeAlert = [[UIAlertView alloc] initWithTitle:nil message:@"Error liking Photo.  Please try later" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [likeAlert show];
}

-(void)handleUnlikeRequestError {
    UIAlertView *unlikeAlert = [[UIAlertView alloc] initWithTitle:nil message:@"Error unliking Photo.  Please try later" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [unlikeAlert show];
    
}



@end
