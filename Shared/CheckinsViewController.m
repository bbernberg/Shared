//
//  CheckinsViewController.m
//  PowerOfTwo
//
//  Created by Brian Bernberg on 3/11/12.
//  Copyright (c) 2012 BB Consulting. All rights reserved.
//

#import "CheckinsViewController.h"
#import "Partner.h"
#import "Myself.h"
#import "Checkin.h"
#import "Constants.h"
#import <Quartzcore/QuartzCore.h>
#import "NearbyPlaces.h"
#import "CommentsViewController.h"
#import "PushNotificationController.h"
#import "PlacesListViewController.h"
#import "StatusUpdateViewController.h"
#import "PhotoDetailViewController.h"
#import "UIButton+myButton.h"
#import "SORelativeDateTransformer.h"
#import "MyAdBannerView.h"

#define REFRESH_HEADER_HEIGHT 52.0f
#define kLoadingCellHeight 50.0f
#define kCheckinCellHeight 197.0f

@interface CheckinsViewController()

// private variables
@property NSString *checkinToDisplay;
@property Checkin *currentCheckin;
    
// Pull to refresh variables
@property UIView *refreshHeaderView;
@property UILabel *refreshLabel;
@property UIImageView *refreshArrow;
@property UIActivityIndicatorView *refreshSpinner;
@property BOOL isDragging;
@property BOOL isRefreshing;    
    
@property UIActionSheet *checkinDetailActionSheet;
    
@property (weak) IBOutlet UIImageView *headerView;
@property (weak) IBOutlet UILabel *headerLabel;
@property (weak) IBOutlet UIButton *checkinButton;
@property (weak) IBOutlet UIButton *homeButton;
@property (weak) IBOutlet UITableView *checkinTableView;
@property (weak) IBOutlet UITableViewCell *checkinTableViewCell;
@property (weak) IBOutlet UILabel *loadingLabel;
@property (weak) IBOutlet UIActivityIndicatorView *loadingActivityIndicator;
@property (weak) IBOutlet UIView *contentView;

@property (weak) Partner *partner;
@property (weak) Myself *myself;

@property (weak) NearbyPlaces *combinedCheckins;

// private functions
-(IBAction)homeButtonPressed;
-(IBAction)checkinButtonPressed;
-(IBAction)commentsLikesButtonPressed:(id)sender;
-(IBAction)actionButtonPressed:(id)sender;

-(void)handleLikeRequestResponse;
-(void)handleLikeRequestError;
-(void)handleUnlikeRequestResponse;
-(void)handleUnlikeRequestError;

-(void)allCheckinsReceived;
-(void)receivedCommentsAndLikes;
-(void)checkinCommentsDoneButtonPressed;
-(void)setupCommentsLikesButton:(UIButton *)commentsLikesButton;
-(void)likeButtonPressed;
-(void)removeCheckinDetailView;
-(void)adjustLabelHeight:(UILabel *)theLabel;
-(void)dismissPhotoDetailView;

// pull to refresh functions
- (void)addPullToRefreshHeader;
- (void)pullToRefreshStartLoading;
- (void)pullToRefreshStopLoading;
- (void)refreshTable;
- (void)configureImageViewBorder:(UIImageView *)theImageView withBorderWidth:(CGFloat)borderWidth;

@end

@implementation CheckinsViewController

@synthesize headerView, headerLabel, checkinButton, homeButton, checkinTableView, checkinTableViewCell, loadingLabel, loadingActivityIndicator, combinedCheckins, partner, myself, checkinToDisplay, currentCheckin, refreshHeaderView, refreshLabel,refreshArrow, refreshSpinner, isDragging, isRefreshing, checkinDetailActionSheet, contentView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        partner = [Partner sharedInstance];
        myself = [Myself sharedInstance];
        self.combinedCheckins = [NearbyPlaces sharedInstance];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(allCheckinsReceived) name:kAllCheckinsReceived object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkinCommentsDoneButtonPressed) name:kCheckinCommentsDoneButtonPressed object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedCommentsAndLikes) name:kReceivedCheckinCommentsAndLikes object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLikeRequestResponse) name:kCheckinLikeRequestSuccess object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLikeRequestError) name:kCheckinLikeRequestError object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUnlikeRequestResponse) name:kCheckinUnlikeRequestSuccess object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUnlikeRequestError) name:kCheckinUnlikeRequestError object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeCheckinDetailView) name:@"removeCheckinDetailView" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissPhotoDetailView) name:kDismissPhotoDetailView object:nil];
        
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
    
    [self.checkinButton customizeButton];
    
    [self.loadingActivityIndicator startAnimating];
    
    [combinedCheckins retrieveCheckins:FALSE];
    self.checkinTableView.hidden = TRUE;
    
    [self addPullToRefreshHeader];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[MyAdBannerView sharedInstance] setViewController:self withContentView:self.contentView];
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[MyAdBannerView sharedInstance] removeViewController];
    
}

#pragma mark IB Actions
-(void)homeButtonPressed {
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"removeCheckinView" object:self];    
}

-(IBAction)checkinButtonPressed {
    PlacesListViewController *placesListViewController = [[PlacesListViewController alloc] init];
    placesListViewController.delegate = self;
    
    placesListViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [[MyAdBannerView sharedInstance] removeViewController];    
    [self presentViewController:placesListViewController animated:YES completion:NULL];
}



#pragma mark UITableView delegate & data source functions
- (NSInteger)tableView:(UITableView *)theTableView numberOfRowsInSection:(NSInteger)section
{
    if (combinedCheckins.retrievingCheckins &&
        combinedCheckins.retrievingMoreCheckins ) {
        return combinedCheckins.combinedCheckinsArray.count + 1;
    } else {
        return combinedCheckins.combinedCheckinsArray.count;
    }
    
}

#define kCheckinTableViewCellDescription @"CheckinTableViewCellDescription"
#define kLoadingCellIdentifier @"LoadingCellIdentifier"
#define kOwnerImageViewTag 1
#define kDateLabelTag 2 
#define kCommentsLikesButtonTag 3
#define kActionButtonTag 4
#define kPlacePictureImageViewTag 5
#define kMessageLabelTag 6
#define kNumCommentsLabelTag 7
#define kNumLikesLabelTag 8
#define kCellSeparatorTag 9
#define kPlaceNameLabelTag 10
#define kPlaceStreetLabelTag 11
#define kPlaceCityStateLabelTag 12
#define kCheckinPhotoImageViewTag 13

#define kInterLabelOffset 3
#define kInterCellOffset 20
#define kMessagePlaceOffset 10
#define kMessageViewY 12
#define kMessageLabelWidth 254
#define kMessageLabelFontSize 17
#define kDateLabelWidth 254
#define kDateLabelFontSize 15
#define kPlaceImageViewHeight 50
#define kPlaceNameLabelWidth 196
#define kPlaceNameLabelFontSize 15
#define kPlaceStreetLabelWidth 196
#define kPlaceStreetLabelFontSize 14
#define kPlaceCityStateLabelWidth 196
#define kPlaceCityStateLabelFontSize 14
#define kCheckinPhotoImageViewX 55
#define kCheckinPhotoImageViewWidth 250
#define kCheckinPhotoImageViewHeight 280

- (UITableViewCell *)tableView:(UITableView *)theTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (combinedCheckins.retrievingCheckins &&
        combinedCheckins.retrievingMoreCheckins &&
        indexPath.row == combinedCheckins.combinedCheckinsArray.count) {
        
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
        
        UIView *separatorLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.checkinTableView.frame.size.width, 1.0)];
        separatorLine.backgroundColor = [UIColor blackColor];
        [cell addSubview:separatorLine];
        
        return cell;
        
    } else {
        
        Checkin *theCheckin = [combinedCheckins.combinedCheckinsArray objectAtIndex:indexPath.row];
        
        UITableViewCell *cell = [theTableView dequeueReusableCellWithIdentifier:kCheckinTableViewCellDescription];
        if (cell == nil) {
            [[NSBundle mainBundle] loadNibNamed:@"CheckinTableViewCell" owner:self options:nil];
            cell = checkinTableViewCell;
            UIButton *commentsLikesButton = (UIButton *)[cell viewWithTag:kCommentsLikesButtonTag];
            [commentsLikesButton customizeButton];
            [self setupCommentsLikesButton:commentsLikesButton];
            UIButton *actionButton = (UIButton *)[cell viewWithTag:kActionButtonTag];
            [actionButton customizeButton];
            // add gesture recognizer for photoImageView
            UITapGestureRecognizer *photoTap = [[UITapGestureRecognizer alloc]
                                                initWithTarget:self action:@selector(handlePhotoTap:)];
            UIImageView *photoImageView = (UIImageView *)[cell viewWithTag:kCheckinPhotoImageViewTag];
            photoImageView.userInteractionEnabled = YES;
            
            [photoImageView addGestureRecognizer:photoTap];
            
        }
        
        
        // configure owner image view
        UIImageView *ownerImageView = (UIImageView *)[cell viewWithTag:kOwnerImageViewTag];
        
        if (theCheckin.owner == kSelf) {
            ownerImageView.image = [Myself sharedInstance].picture;
        } else {
            ownerImageView.image = [Partner sharedInstance].picture;
        }
        [self configureImageViewBorder:ownerImageView withBorderWidth:2.0f];
        
        
        // configure view comments button
        UILabel *numCommentsLabel = (UILabel *)[cell viewWithTag:kNumCommentsLabelTag];
        UILabel *numLikesLabel = (UILabel *)[cell viewWithTag:kNumLikesLabelTag];
        if ([theCheckin.comments count] > 0) {
            numCommentsLabel.hidden = NO;
            numCommentsLabel.text = [NSString stringWithFormat:@"%d", theCheckin.comments.count];
        } else {
            numCommentsLabel.hidden = YES;
        }
        
        if ([theCheckin.likes count] > 0) {
            numLikesLabel.hidden = NO;
            numLikesLabel.text = [NSString stringWithFormat:@"%d", theCheckin.likes.count];
        } else {
            numLikesLabel.hidden = YES;
        }

        float verticalOffset;
        
        // configure message text view
        UILabel *messageLabel = (UILabel *)[cell viewWithTag:kMessageLabelTag];
        if (theCheckin.message == nil || [theCheckin.message isEqualToString:@""]) {
            if (theCheckin.owner == kSelf) {
                messageLabel.text = [NSString stringWithFormat:@"You were at %@.", [theCheckin.place objectForKey:@"name"]]; 
            } else {
                messageLabel.text = [NSString stringWithFormat:@"%@ was at %@.", partner.name, [theCheckin.place objectForKey:@"name"]]; 
            }
        } else {
            messageLabel.text = [NSString stringWithFormat:@"%@ - at %@.", theCheckin.message, [theCheckin.place objectForKey:@"name"]];
        }
        
        [self adjustLabelHeight:messageLabel];
        verticalOffset = messageLabel.frame.origin.y + messageLabel.frame.size.height + kInterLabelOffset;
        
        // configure date label
        UILabel *dateLabel = (UILabel *)[cell viewWithTag:kDateLabelTag];
/*        
        NSDateFormatter *outDF = [[NSDateFormatter alloc] init];
        NSDateComponents *checkinYear = [[NSCalendar currentCalendar] components:NSYearCalendarUnit fromDate:theCheckin.createdTime];
        NSDateComponents *today = [[NSCalendar currentCalendar] components:NSYearCalendarUnit fromDate:[NSDate date]];
        
        if ([checkinYear year] == [today year]) {
            [outDF setDateFormat:@"MMMM d h:mma"];
        } else {
            [outDF setDateFormat:@"MMMM d, yyyy h:mma"];            
        }

        dateLabel.text = [outDF stringFromDate:theCheckin.createdTime];
*/
        SORelativeDateTransformer *relativeDateTransformer = [[SORelativeDateTransformer alloc] init];
        dateLabel.text = [relativeDateTransformer transformedValue:theCheckin.createdTime];
        
        dateLabel.adjustsFontSizeToFitWidth = TRUE;
        dateLabel.frame = CGRectMake(dateLabel.frame.origin.x, verticalOffset, dateLabel.frame.size.width, dateLabel.frame.size.height);
        if (theCheckin.photo) {
            verticalOffset += dateLabel.frame.size.height + kInterLabelOffset;
        } else {
            verticalOffset += dateLabel.frame.size.height + kMessagePlaceOffset;
        }
        
        // configure checkin photo image view
        UIImageView *checkinPhotoImageView = (UIImageView *)[cell viewWithTag:kCheckinPhotoImageViewTag];
        if (theCheckin.photo == nil) {
            checkinPhotoImageView.hidden = YES;
        } else {
            checkinPhotoImageView.image = theCheckin.photo;
            checkinPhotoImageView.hidden = NO;
        
            CGRect checkinPhotoRect = [self aspectFittedRect:CGRectMake(0, 0, theCheckin.photo.size.width, theCheckin.photo.size.height) max:CGRectMake(kCheckinPhotoImageViewX, verticalOffset, kCheckinPhotoImageViewWidth, kCheckinPhotoImageViewHeight)];
            checkinPhotoImageView.frame = checkinPhotoRect;

            verticalOffset += checkinPhotoImageView.frame.size.height + kMessagePlaceOffset;
        }
        
        // configure place picture image view
        UIImageView *placePictureImageView = (UIImageView *)[cell viewWithTag:kPlacePictureImageViewTag];
        placePictureImageView.image = theCheckin.placePicture;
        placePictureImageView.frame = CGRectMake(placePictureImageView.frame.origin.x, verticalOffset, placePictureImageView.frame.size.width, placePictureImageView.frame.size.height);

        // configure place name label & place sub-name label
        UILabel *placeNameLabel = (UILabel *)[cell viewWithTag:kPlaceNameLabelTag];
        placeNameLabel.text = [theCheckin.place objectForKey:@"name"];
        
        placeNameLabel.frame = CGRectMake(placeNameLabel.frame.origin.x, verticalOffset, placeNameLabel.frame.size.width, placeNameLabel.frame.size.height);
        [self adjustLabelHeight:placeNameLabel];
        verticalOffset += placeNameLabel.frame.size.height + kInterLabelOffset;
        
        
        // configure place street label
        NSDictionary *locationDict = [theCheckin.place objectForKey:@"location"];
        UILabel *placeStreetLabel = (UILabel *)[cell viewWithTag:kPlaceStreetLabelTag];  
        if ([locationDict objectForKey:@"street"]) {
            placeStreetLabel.text = [locationDict objectForKey:@"street"];
            placeStreetLabel.frame = CGRectMake(placeStreetLabel.frame.origin.x, verticalOffset, placeStreetLabel.frame.size.width, placeStreetLabel.frame.size.height);
            [self adjustLabelHeight:placeStreetLabel];
            verticalOffset += placeStreetLabel.frame.size.height + kInterLabelOffset;
        } else {
            placeStreetLabel.frame = CGRectMake(placeStreetLabel.frame.origin.x, placeStreetLabel.frame.origin.y, 0, 0);
        }
        
        // configure place city, state label
        UILabel *placeCityStateLabel = (UILabel *)[cell viewWithTag:kPlaceCityStateLabelTag];        
        NSString *placeCity = [locationDict objectForKey:@"city"] ? [locationDict objectForKey:@"city"] : @"";
        NSString *placeState = [locationDict objectForKey:@"state"] ? [locationDict objectForKey:@"state"] : @"";
        placeCityStateLabel.text = [NSString stringWithFormat:@"%@, %@", placeCity, placeState];        
        
        if (placeCityStateLabel.text != nil &&
            ![placeCityStateLabel.text isEqualToString:@""]) {
            placeCityStateLabel.frame = CGRectMake(placeCityStateLabel.frame.origin.x, verticalOffset, placeCityStateLabel.frame.size.width, placeCityStateLabel.frame.size.height);
            [self adjustLabelHeight:placeCityStateLabel];
        } else {
            placeCityStateLabel.frame = CGRectMake(placeCityStateLabel.frame.origin.x, placeCityStateLabel.frame.origin.y, 0, 0);
        }
        return cell;
    }    
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (combinedCheckins.retrievingCheckins &&
        combinedCheckins.retrievingMoreCheckins &&
        indexPath.row == combinedCheckins.combinedCheckinsArray.count) {
        return kLoadingCellHeight;
    } else {
        Checkin *theCheckin = [combinedCheckins.combinedCheckinsArray objectAtIndex:indexPath.row];
        
        // calculate message height
        NSString *messageText;
        if (theCheckin.message == nil || [theCheckin.message isEqualToString:@""]) {
            if (theCheckin.owner == kSelf) {
                messageText = [NSString stringWithFormat:@"You were at %@", [theCheckin.place objectForKey:@"name"]]; 
            } else {
                messageText = [NSString stringWithFormat:@"%@ was at %@", partner.name, [theCheckin.place objectForKey:@"name"]]; 
            }
        } else {
            messageText = [NSString stringWithFormat:@"%@ - at %@", theCheckin.message, [theCheckin.place objectForKey:@"name"]];
        }

        CGSize maximumLabelSize = CGSizeMake(kMessageLabelWidth,9999);
        
        CGSize expectedLabelSize = [messageText sizeWithFont:[UIFont fontWithName:@"Copperplate" size:kMessageLabelFontSize]
                                             constrainedToSize:maximumLabelSize 
                                                 lineBreakMode:UILineBreakModeWordWrap]; 
        
        float verticalOffset = kMessageViewY + expectedLabelSize.height + kInterLabelOffset;
        
        // calculate date label height
        NSDateFormatter *outDF = [[NSDateFormatter alloc] init];
        NSDateComponents *checkinYear = [[NSCalendar currentCalendar] components:NSYearCalendarUnit fromDate:theCheckin.createdTime];
        NSDateComponents *today = [[NSCalendar currentCalendar] components:NSYearCalendarUnit fromDate:[NSDate date]];
        
        if ([checkinYear year] == [today year]) {
            [outDF setDateFormat:@"MMMM d h:mma"];
        } else {
            [outDF setDateFormat:@"MMMM d, yyyy h:mma"];            
        }
        NSString *dateText = [outDF stringFromDate:theCheckin.createdTime];
        
        maximumLabelSize = CGSizeMake(kDateLabelWidth, 9999);
        expectedLabelSize = [dateText sizeWithFont:[UIFont fontWithName:@"Copperplate" size:kDateLabelFontSize] constrainedToSize:maximumLabelSize lineBreakMode:UILineBreakModeWordWrap];
        
        if (theCheckin.photo == nil) {
            verticalOffset += expectedLabelSize.height + kMessagePlaceOffset;
        } else {
            verticalOffset += expectedLabelSize.height + kInterLabelOffset;
        }
        
        // configure checkin photo image view
        if (theCheckin.photo != nil) {
            
            CGRect checkinPhotoRect = [self aspectFittedRect:CGRectMake(0, 0, theCheckin.photo.size.width, theCheckin.photo.size.height) max:CGRectMake(kCheckinPhotoImageViewX, verticalOffset, kCheckinPhotoImageViewWidth, kCheckinPhotoImageViewHeight)];
            
            verticalOffset += checkinPhotoRect.size.height + kInterLabelOffset;
        }
        
        // configure place name label & place sub-name label
        NSString *placeNameLabelText = [theCheckin.place objectForKey:@"name"];
        
        maximumLabelSize = CGSizeMake(kPlaceNameLabelWidth, 9999);
        expectedLabelSize = [placeNameLabelText sizeWithFont:[UIFont fontWithName:@"Copperplate" size:kPlaceNameLabelFontSize] constrainedToSize:maximumLabelSize lineBreakMode:UILineBreakModeWordWrap];
        
        float placeTextHeight = expectedLabelSize.height + kInterLabelOffset;
        
        
        // configure place street label
        NSDictionary *locationDict = [theCheckin.place objectForKey:@"location"];
        if ([locationDict objectForKey:@"street"]) {
            NSString *placeStreetLabelText = [locationDict objectForKey:@"street"];
        
            maximumLabelSize = CGSizeMake(kPlaceStreetLabelWidth, 9999);
            expectedLabelSize = [placeStreetLabelText sizeWithFont:[UIFont fontWithName:@"Copperplate" size:kPlaceStreetLabelFontSize] constrainedToSize:maximumLabelSize lineBreakMode:UILineBreakModeWordWrap];
        
            placeTextHeight += expectedLabelSize.height + kInterLabelOffset;
        }
        
        // configure place city, state label
        NSString *placeCity = [locationDict objectForKey:@"city"] ? [locationDict objectForKey:@"city"] : @"";
        NSString *placeState = [locationDict objectForKey:@"state"] ? [locationDict objectForKey:@"state"] : @"";
        NSString *placeCityStateLabelText = [NSString stringWithFormat:@"%@, %@", placeCity, placeState];        

        if (placeCityStateLabelText != nil &&
            ![placeCityStateLabelText isEqualToString:@""]) {
            maximumLabelSize = CGSizeMake(kPlaceCityStateLabelWidth, 9999);
            expectedLabelSize = [placeCityStateLabelText sizeWithFont:[UIFont fontWithName:@"Copperplate" size:kPlaceCityStateLabelFontSize] constrainedToSize:maximumLabelSize lineBreakMode:UILineBreakModeWordWrap];
        
            placeTextHeight += expectedLabelSize.height;
        }
        
        if (placeTextHeight > kPlaceImageViewHeight)
            verticalOffset += placeTextHeight + kInterCellOffset;
        else
            verticalOffset += kPlaceImageViewHeight + kInterCellOffset;
        
        if (verticalOffset > kCheckinCellHeight)
            return verticalOffset;
        else
            return kCheckinCellHeight;
        
    }
}


#pragma mark other functions

-(void)adjustLabelHeight:(UILabel *)theLabel {
    //Calculate the expected size based on the font and linebreak mode of your label
    CGSize maximumLabelSize = CGSizeMake(theLabel.frame.size.width,9999);

    CGSize expectedLabelSize = [theLabel.text sizeWithFont:theLabel.font 
                                         constrainedToSize:maximumLabelSize 
                                             lineBreakMode:theLabel.lineBreakMode]; 

    //adjust the label the the new height
    CGRect newLabelFrame = theLabel.frame;
    newLabelFrame.size.height = expectedLabelSize.height;
    theLabel.frame = newLabelFrame;        
}


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


-(void)likeButtonPressed {
    
    BOOL checkinIsCurrentlyNotLiked = TRUE;
    
    for (NSDictionary *likeDictionary in currentCheckin.likes) {
        if ([[likeDictionary objectForKey:@"id"] isEqualToString:[Myself sharedInstance].FBID]) {
            checkinIsCurrentlyNotLiked = FALSE;
            break;
        }
    }
    
    
    if (checkinIsCurrentlyNotLiked) {
        [combinedCheckins likeCheckin:currentCheckin.FBID];
    } else {
        [combinedCheckins unlikeCheckin:currentCheckin.FBID];
    }
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

-(void)allCheckinsReceived {
    if (!loadingLabel.hidden) {
        [loadingActivityIndicator stopAnimating];
        loadingLabel.hidden = TRUE;
    }
    
    if (isRefreshing) {
        [self pullToRefreshStopLoading];
    }
    
    self.checkinTableView.hidden = FALSE;
    [self.checkinTableView reloadData];
    
    
}

-(IBAction)commentsLikesButtonPressed:(id)sender {
/*    UIButton *button = (UIButton *)sender;
    UITableViewCell *cell = (UITableViewCell *)[[button superview] superview];
    int row = [self.checkinTableView indexPathForCell:cell].row;    
    
    Checkin *theCheckin = [combinedCheckins.combinedCheckinsArray objectAtIndex:row];
    
    CommentsViewController *commentsVC = [[CommentsViewController alloc] initWithFBObject:theCheckin andComments:theCheckin.comments andLikes:theCheckin.likes];
    [[MyAdBannerView sharedInstance] removeViewController];    
    [self presentViewController:commentsVC animated:YES completion:NULL];
*/  
}

-(IBAction)actionButtonPressed:(id)sender {
    UIButton *button = (UIButton *)sender;
    UITableViewCell *cell = (UITableViewCell *)[[button superview] superview];
    int row = [self.checkinTableView indexPathForCell:cell].row;    
    
    currentCheckin = [combinedCheckins.combinedCheckinsArray objectAtIndex:row];
    
    NSString *likeTitle;
    
    // configure like title
    likeTitle = @"Like";
    
    for (NSDictionary *likeDictionary in currentCheckin.likes) {
        if ([[likeDictionary objectForKey:@"id"] isEqualToString:[Myself sharedInstance].FBID]) {
            likeTitle = @"Unlike";
        }
    }
    
    if (currentCheckin.photo != nil) {
        checkinDetailActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles: likeTitle, @"Save Photo", nil];                
    } else {
        checkinDetailActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles: likeTitle, nil];        
    }
    
    checkinDetailActionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    [checkinDetailActionSheet showInView:self.view];
    
}

-(void)checkinCommentsDoneButtonPressed {
    [self dismissViewControllerAnimated:YES completion:^{
        [[MyAdBannerView sharedInstance] setViewController:self withContentView:self.contentView];    
    }];
    
    [self.checkinTableView reloadData];
}


-(void)receivedCommentsAndLikes {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self.checkinTableView reloadData];
}

-(void)configureImageViewBorder:(UIImageView *)theImageView withBorderWidth:(CGFloat)borderWidth {
    CALayer* layer = [theImageView layer];
    [layer setBorderWidth:borderWidth];
    [layer setBorderColor:[UIColor whiteColor].CGColor];
    [layer setShadowOffset:CGSizeMake(-3.0, 3.0)];
    [layer setShadowRadius:3.0];
    [layer setShadowOpacity:1.0];
}

-(void)removePlacesListView {
    [self dismissViewControllerAnimated:YES completion:^{
        [[MyAdBannerView sharedInstance] setViewController:self withContentView:self.contentView];    
    }];
    [self.checkinTableView reloadData];
}


-(CGRect)aspectFittedRect:(CGRect)inRect max:(CGRect)maxRect {
    float scaleFactor = maxRect.size.width/inRect.size.width;
    
    CGRect newRect = CGRectMake(maxRect.origin.x, maxRect.origin.y, maxRect.size.width, inRect.size.height*scaleFactor);
        
    return CGRectIntegral(newRect);
    
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

-(void)removeCheckinDetailView {
    [self dismissViewControllerAnimated:YES completion:^{
        [[MyAdBannerView sharedInstance] setViewController:self withContentView:self.contentView];    
    }];
    [self.combinedCheckins retrieveCheckins:FALSE];
}

-(void)dismissPhotoDetailView {
    [self dismissViewControllerAnimated:YES completion:^{
        [[MyAdBannerView sharedInstance] setViewController:self withContentView:self.contentView];    
    }];
}



#pragma mark Places List delegate
-(void)placeSelected:(NSDictionary *)thePlaceDictionary {
    StatusUpdateViewController *detailVC = [[StatusUpdateViewController alloc] initWithPlace:thePlaceDictionary];
    [self dismissViewControllerAnimated:NO completion:^{
        [self presentViewController:detailVC animated:NO completion:NULL];
    }];
    
}

-(void)placesListCancelButtonPressed {
    [self dismissViewControllerAnimated:YES completion:^{
        [[MyAdBannerView sharedInstance] setViewController:self withContentView:self.contentView];
    }];
    [combinedCheckins retrieveCheckins:FALSE];
}

#pragma mark Action Sheet delegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (actionSheet == checkinDetailActionSheet) {
        if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Save Photo"]) {
            UIImageWriteToSavedPhotosAlbum(currentCheckin.photo, nil, nil, nil);
        } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Like"] ||
                   [[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Unlike"]) {
            [self likeButtonPressed];
        }
    }
}



#pragma mark Scroll View Delegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (isRefreshing) {
        // Update the content inset, good for section headers
        if (scrollView.contentOffset.y > 0)
            self.checkinTableView.contentInset = UIEdgeInsetsZero;
        else if (scrollView.contentOffset.y >= -REFRESH_HEADER_HEIGHT)
            self.checkinTableView.contentInset = UIEdgeInsetsMake(-scrollView.contentOffset.y, 0, 0, 0);
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
        combinedCheckins.combinedCheckinsArray.count < combinedCheckins.totalCheckins &&                
        !combinedCheckins.retrievingCheckins) {
        // we are at the end
        NSLog(@"Reached the bottom");
        [combinedCheckins retrieveCheckins:TRUE];
        [self.checkinTableView reloadData];
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
    [self.checkinTableView addSubview:refreshHeaderView];
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
    self.checkinTableView.contentInset = UIEdgeInsetsMake(REFRESH_HEADER_HEIGHT, 0, 0, 0);
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
    self.checkinTableView.contentInset = UIEdgeInsetsZero;
    UIEdgeInsets tableContentInset = self.checkinTableView.contentInset;
    tableContentInset.top = 0.0;
    self.checkinTableView.contentInset = tableContentInset;
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
    [combinedCheckins retrieveCheckins:NO];    
    
}




#pragma mark like functions
-(void)handleLikeRequestResponse {
    
    [[NearbyPlaces sharedInstance] retrieveCommentsAndLikes];
}

-(void)handleUnlikeRequestResponse {
    
    [[NearbyPlaces sharedInstance] retrieveCommentsAndLikes];
    
}

-(void)handleLikeRequestError {
    
    UIAlertView *likeAlert = [[UIAlertView alloc] initWithTitle:nil message:@"Error liking Checkin.  Please try later" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [likeAlert show];
}

-(void)handleUnlikeRequestError {
    UIAlertView *unlikeAlert = [[UIAlertView alloc] initWithTitle:nil message:@"Error unliking Checkin.  Please try later" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [unlikeAlert show];
    
}

@end
