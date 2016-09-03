//
//  PlacesController.m
//  Shared
//
//  Created by Brian Bernberg on 10/28/15.
//  Copyright © 2015 BB Consulting. All rights reserved.
//

#import "PlacesController.h"
#import "SHUtil.h"
#import <GoogleMaps/GoogleMaps.h>

@interface PlacesController () <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate>
@property (nonatomic) NSString *location;
@property (nonatomic, weak) id<PlacesControllerDelegate> delegate;
@property (nonatomic) IBOutlet UITextField *textField;
@property (nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic) NSArray *places;
@property (nonatomic) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) GMSPlacesClient *placesClient;
@property (nonatomic) GMSCoordinateBounds *bounds;
@property (nonatomic) NSString *selectedPlaceID;
@end

@implementation PlacesController

- (instancetype)initWithLocation:(NSString *)location delegate:(id<PlacesControllerDelegate>)delegate {
  self = [super init];
  if ( self ) {
    _location = location;
    _delegate = delegate;
    _selectedPlaceID = nil;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.automaticallyAdjustsScrollViewInsets = NO;
  self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
  self.textField.rightViewMode = UITextFieldViewModeAlways;
  self.textField.rightView =  nil;
  self.textField.text = self.location;
  self.placesClient = [[GMSPlacesClient alloc] init];
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Clear"
                                                                            style:UIBarButtonItemStylePlain
                                                                           target:self
                                                                           action:@selector(clearButtonPressed:)];
  [self createBounds];
  UIImageView *iv = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"powered_by_google"]];
  iv.contentMode = UIViewContentModeCenter;
  self.tableView.tableFooterView =iv;
  
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [self.textField becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
  [self.delegate exitingWithPlaceID:self.selectedPlaceID location:self.textField.text];
}

- (void)keyboardWillShow:(NSNotification *)notification {
  // get keyboard size
  NSValue *frameValue = [[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey];
  CGFloat keyboardHeight = [frameValue CGRectValue].size.height;
  self.tableView.contentInset = UIEdgeInsetsMake(0.f, 0.f, keyboardHeight, 0.f);
}

#pragma UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  if ([self.textField.text length] > 0) {
    return [self.places count] + 1;
  } else {
    return 0;
  }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  return [SHUtil thinnestLineWidth];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return 50.f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.row == 0) {
    return [self customLocationCell];
  } else {
    return [self placesCellForIndexPath:indexPath];
  }
  return nil;
}

- (UITableViewCell *)customLocationCell {
  UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"customLocationCell"];
  if ( ! cell ) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"customLocationCell"];
  }
  cell.textLabel.text = self.textField.text;
  cell.textLabel.font = [UIFont systemFontOfSize:17.f];
  cell.detailTextLabel.text = @"Custom Location";
  cell.detailTextLabel.textColor = [UIColor lightGrayColor];
  cell.detailTextLabel.font = [UIFont systemFontOfSize:15.f];
  return cell;
}

- (UITableViewCell *)placesCellForIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"placesCell"];
  if ( ! cell ) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"placesCell"];
  }
  GMSAutocompletePrediction *place = self.places[indexPath.row - 1];
  
  NSMutableArray *components = [NSMutableArray arrayWithArray:[[place.attributedFullText string] componentsSeparatedByString:@", "]];
  cell.textLabel.text = [components firstObject];
  cell.textLabel.font = [UIFont systemFontOfSize:17.f];
  
  if ( [components count] > 1 ) {
    [components removeObjectAtIndex:0];
    cell.detailTextLabel.text = [components componentsJoinedByString:@", "];
    cell.detailTextLabel.textColor = [UIColor lightGrayColor];
  } else {
    cell.detailTextLabel.text = @"";
  }
  
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if ( indexPath.row != 0 ) {
    GMSAutocompletePrediction *place = self.places[indexPath.row - 1];
    self.selectedPlaceID = place.placeID;
    self.textField.text = [place.attributedFullText string];
  }
  [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark UITextFieldDelegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
  NSString *newText = [textField.text stringByReplacingCharactersInRange:range withString:string];
  if([newText length] > 0) {
    [self queryForSearchString:newText];
  } else {
    self.textField.rightView = nil;
    self.places = @[];
  }
  
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    [self.tableView reloadData];
  });
  return YES;
}

- (void)queryForSearchString:(NSString *)searchString {
  [self.spinner startAnimating];
  self.textField.rightView = self.spinner;
  
  [self.placesClient autocompleteQuery:searchString
                                bounds:self.bounds
                                filter:nil
                              callback:^(NSArray * _Nullable results, NSError * _Nullable error) {
                                [self.spinner stopAnimating];
                                self.textField.rightView = nil;
                                if ( ! error ) {
                                  NSLog(@"Results = %@\nError = %@", results, error);
                                  self.places = results;
                                  [self.tableView reloadData];
                                }
                              }];
  
}

#pragma mark button handlers
- (void)clearButtonPressed:(id)sender {
  self.textField.text = nil;
  self.places = @[];
  [self.tableView reloadData];
}

#pragma mark location bounds
- (void)createBounds {
  if ( [[NSUserDefaults standardUserDefaults] objectForKey:kLastLocationKey] ) {
    NSDictionary *location = [[NSUserDefaults standardUserDefaults] objectForKey:kLastLocationKey];
    CLLocationDegrees latitude = [location[@"latitude"] doubleValue];
    CLLocationDegrees longitude = [location[@"longitude"] doubleValue];
    CLLocationDegrees offset = 0.1;
    CLLocationCoordinate2D coordinate1 = {latitude - offset, longitude - offset};
    CLLocationCoordinate2D coordinate2 = {latitude + offset, longitude + offset};
    self.bounds = [[GMSCoordinateBounds alloc] initWithCoordinate:coordinate1 coordinate:coordinate2];
  }
}
  
@end
