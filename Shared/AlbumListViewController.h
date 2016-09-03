//
//  AlbumListViewController.h
//  PowerOfTwo
//
//  Created by Brian Bernberg on 11/4/11.
//  Copyright (c) 2011 BB Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FBConnect.h"
@class Partner;

@interface AlbumListViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, FBRequestDelegate> {
    UITableView *albumListTableView;    
    UIButton *homeButton;
    UIButton *addAlbumButton;
    UILabel *loadingLabel;
    UIActivityIndicatorView *loadingActivityIndicator;
    UIImageView *headerView;
    UILabel *headerLabel;
    
    Partner *partner;    
    NSMutableSet *albumSet;
    NSMutableArray *albumList;
    
    // Facebook variables
    Facebook *facebook;
    FBRequest *getMyAlbumsRequest;
    FBRequest *getPartnerAlbumsRequest;
    NSMutableArray *queryAlbumRequests;
    NSInteger completedAlbumRequests;
    
}

@property (nonatomic, retain) IBOutlet UITableView *albumListTableView;
@property (nonatomic, retain) IBOutlet UIButton *homeButton;
@property (nonatomic, retain) IBOutlet UIButton *addAlbumButton;
@property (nonatomic, retain) IBOutlet UILabel *loadingLabel;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *loadingActivityIndicator;
@property (nonatomic, retain) IBOutlet UIImageView *headerView;
@property (nonatomic, retain) IBOutlet UILabel *headerLabel;

@property (nonatomic, retain) NSMutableSet *albumSet;
@property (nonatomic, retain) NSMutableArray *albumList;

@property (nonatomic, retain) FBRequest *getMyAlbumsRequest;
@property (nonatomic, retain) FBRequest *getPartnerAlbumsRequest;
@property (nonatomic, retain) NSMutableArray *queryAlbumRequests;

-(IBAction)homeButtonPressed:(id)sender;
-(IBAction)addAlbumButtonPressed:(id)sender;
@end
