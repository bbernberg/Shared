//
//  AlbumListViewController.m
//  PowerOfTwo
//
//  Created by Brian Bernberg on 11/4/11.
//  Copyright (c) 2011 BB Consulting. All rights reserved.
//

#import "AlbumListViewController.h"
#import <Quartzcore/QuartzCore.h>
#import "Constants.h"
#import "Partner.h"
#import "Album.h"
#import "MyFacebook.h"

#define kInitialMaxAlbumsDisplayed 50


@interface AlbumListViewController()
-(void)customizeButton:(UIButton *)button;
-(void)eventHandler: (NSNotification *)notification;
-(void)retrieveAlbums;
-(void)queryAlbumList;
-(void)handleGetAlbumsRequestResponse:(id)result forRequest:(FBRequest *)request;
-(void)handleQueryAlbumRequest:(id)result;
@end

@implementation AlbumListViewController
@synthesize albumListTableView, homeButton, addAlbumButton, loadingLabel, loadingActivityIndicator, getMyAlbumsRequest, getPartnerAlbumsRequest, albumSet, albumList, queryAlbumRequests, headerView, headerLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        partner = [Partner sharedInstance];
        facebook = [MyFacebook sharedInstance];
        self.albumSet = [NSMutableSet set];
        self.albumList = [NSMutableArray array];   
        self.queryAlbumRequests = [NSMutableArray array];
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
    // Do any additional setup after loading the view from its nib.
    [self customizeButton:self.homeButton];
    [self customizeButton:self.addAlbumButton];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(eventHandler:) name:@"removeAlbumDetailView" object:nil];    
    
    [self.loadingActivityIndicator startAnimating];
    
    [self retrieveAlbums];
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.albumListTableView = nil;
    self.homeButton = nil;
    self.addAlbumButton = nil;
    self.headerLabel = nil;
    self.headerView = nil;
}

-(void)dealloc {
    self.albumListTableView = nil;
    self.homeButton = nil;
    self.addAlbumButton = nil;
    self.albumSet = nil;
    self.albumList = nil;
    self.queryAlbumRequests = nil;
    self.headerLabel = nil;
    self.headerView = nil;
    
    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark IB functions
-(void)homeButtonPressed:(id)sender {
    
}

-(void)addAlbumButtonPressed:(id)sender {
    
}

#pragma mark other functions
-(void)customizeButton:(UIButton *)button {
    button.layer.cornerRadius = 8.0f;
    button.layer.masksToBounds = YES;
    button.layer.borderWidth = 1.0f;
}

-(void)eventHandler: (NSNotification *)notification {
    
}

-(void)retrieveAlbums {
    completedAlbumRequests = 0;
    
    NSMutableDictionary * params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                    [NSString stringWithFormat:@"SELECT attachment, created_time FROM stream WHERE source_id = me() AND app_id = %@ AND created_time <= %ld", kAppIdString, [[NSDate date] timeIntervalSince1970]], @"query",
                                    nil];
    
    
    self.getMyAlbumsRequest = [facebook requestWithMethodName:@"fql.query"
                                                    andParams:params
                                                andHttpMethod:@"POST"
                                                  andDelegate:self];
    
    NSMutableDictionary *partnerParams = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                          [NSString stringWithFormat:@"SELECT attachment, created_time FROM stream WHERE source_id = %@ AND app_id = %@ AND created_time <= now()", partner.FBID, kAppIdString], @"query",
                                          nil];
    
    self.getPartnerAlbumsRequest = [facebook requestWithMethodName:@"fql.query"
                                                         andParams:partnerParams
                                                     andHttpMethod:@"POST"
                                                       andDelegate:self];
    
}

-(void)queryAlbumList {
    [queryAlbumRequests removeAllObjects];
    for (Album *album in albumSet) {
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
            [NSString stringWithFormat:@"SELECT aid, object_id, cover_object_id, name, modified_major, size, owner FROM album WHERE aid = %@", album.AID], @"query", nil];
        
        [queryAlbumRequests addObject:[facebook requestWithMethodName:@"fql.query"
                                                            andParams:params
                                                        andHttpMethod:@"POST"
                                                          andDelegate:self]];
    }
}

#pragma mark FB functions
////////////////////////////////////////////////////////////////////////////////
// FBRequestDelegate

/**
 * Called when the Facebook API request has returned a response. This callback
 * gives you access to the raw response. It's called before
 * (void)request:(FBRequest *)request didLoad:(id)result,
 * which is passed the parsed response object.
 */
- (void)request:(FBRequest *)request didReceiveResponse:(NSURLResponse *)response {
}

/**
 * Called when a request returns and its response has been parsed into
 * an object. The resulting object may be a dictionary, an array, a string,
 * or a number, depending on the format of the API response. If you need access
 * to the raw response, use:
 *
 * (void)request:(FBRequest *)request
 *      didReceiveResponse:(NSURLResponse *)response
 */
- (void)request:(FBRequest *)request didLoad:(id)result {
    if (request == self.getMyAlbumsRequest || request == self.getPartnerAlbumsRequest) {
        [self handleGetAlbumsRequestResponse:result forRequest:request];
    } else if ([self.queryAlbumRequests indexOfObject:request] != NSNotFound) {
        [self handleQueryAlbumRequest:result];
    }
    
}

/**
 * Called when an error prevents the Facebook API request from completing
 * successfully.
 */
- (void)request:(FBRequest *)request didFailWithError:(NSError *)error {
    [request release];
    request = nil;
    NSLog(@"%@",[error localizedDescription]);
}

-(void)handleGetAlbumsRequestResponse:(id)result forRequest:(FBRequest *)request {
    
    NSString *resultCreatedTime = nil;
    
    for (NSDictionary *resultDictionary in result) {
        NSDictionary *resultAttachment = [resultDictionary objectForKey:@"attachment"];
        resultCreatedTime = [resultDictionary objectForKey:@"created_time"];
        
        if (resultAttachment != nil) {
            NSArray *resultMedia = [resultAttachment objectForKey:@"media"];
            if (resultMedia != nil) {
                for (NSDictionary *resultMediaDetail in resultMedia) {
                    NSDictionary *resultPhotoDictionary = [resultMediaDetail objectForKey:@"photo"];
                    if (resultPhotoDictionary != nil) {
                        Album *newAlbum = [[Album alloc] init];
                        newAlbum.AID = [resultPhotoDictionary objectForKey:@"aid"];
                        newAlbum.owner = (request == self.getMyAlbumsRequest) ? kSelf : kPartner;
                        [self.albumSet addObject:newAlbum];
                        [newAlbum release];
                    }
                }
            }
        }
    }
    
    if (resultCreatedTime == nil || [result count] < 50) {
        request = nil;    
        
        NSLog(@"Albums found = %d", [self.albumSet count]);
        
        if (++completedAlbumRequests >= 2) { 
            // partner request has already been processed
            [loadingActivityIndicator stopAnimating];
            self.loadingLabel.hidden = TRUE;
            self.albumListTableView.hidden = FALSE;
            [self queryAlbumList];
        }
    } else {
        // query for more data
        NSMutableDictionary *params;
        if (request == self.getMyAlbumsRequest) {
            params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                      [NSString stringWithFormat:@"SELECT attachment, created_time FROM stream WHERE source_id = me() AND app_id = %@ AND created_time <= %@", kAppIdString, resultCreatedTime], @"query",
                      nil];
        } else {
            params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                      [NSString stringWithFormat:@"SELECT attachment, created_time FROM stream WHERE source_id = %@ AND app_id = %@ AND created_time <= %@", partner.FBID, kAppIdString, resultCreatedTime], @"query",
                      nil];
            
        }
        
        request = [facebook requestWithMethodName:@"fql.query"
                                        andParams:params
                                    andHttpMethod:@"POST"
                                      andDelegate:self];
        
    }
        
    
}

-(void)handleQueryAlbumRequest:(id)result {
    NSDictionary *resultDicionary = [result objectAtIndex:0];
    if (resultDicionary != nil) {
        Album *album = [[Album alloc] init];
        album.AID = [resultDicionary objectForKey:@"aid"];
        album.coverImageObjectID = [resultDicionary objectForKey:@"cover_object_id"];
        album.updateTime = [resultDicionary objectForKey:@"modified_major"];
        album.name = [resultDicionary objectForKey:@"name"];
        album.objectID = [resultDicionary objectForKey:@"object_id"];
        album.size = [[resultDicionary objectForKey:@"size"] intValue];
        album.owner = [[resultDicionary objectForKey:@"owner"] intValue] == [partner.FBID intValue] ? kPartner : kSelf;
        [self.albumList addObject:album];
        [album release];
        
        [self.albumListTableView reloadData];
    }
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.albumList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    // Configure the cell...
    static NSString *MyIdentifier = @"MyIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MyIdentifier] autorelease];
    }
    Album *albumForRow = [albumList objectAtIndex:indexPath.row];
    cell.textLabel.text = albumForRow.name;
        
    return cell;
    
}


#pragma mark Table View delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

@end
