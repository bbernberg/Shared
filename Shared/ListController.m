//
//  ListController.m
//  Shared
//
//  Created by Brian Bernberg on 5/14/12.
//  Copyright (c) 2012 BB Consulting. All rights reserved.
//

#import "ListController.h"
#import "ListService.h"
#import "Parse/Parse.h"
#import "SVPullToRefresh.h"
#import "MyReach.h"
#import "Constants.h"
#import "SHUtil.h"
#import "ListTableViewCell.h"
#import "JTTableViewGestureRecognizer.h"
#import "YRDropdownView.h"
#import "PSPDFAlertView.h"

#define kListItemPlaceholderText @"New Item...";
#define kKeyboardPortraitHeight 216.f
#define kCellPaddingHeight 14.f
#define kMinimumCellHeight 70.f

#define kActionDeleteCompletedItems @"Delete Completed Items"
#define kActionEmailList @"E-mail List"
#define kActionSendNotification @"Notify Partner"

@interface ListController ()  <UITextFieldDelegate, UITextViewDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate, UIGestureRecognizerDelegate, HHPanningTableViewCellDelegate, JTTableViewGestureMoveRowDelegate, UIScrollViewDelegate>
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UITextField *addItemTextField;
@property (nonatomic, weak) IBOutlet UIView *addItemBackground;
@property (nonatomic, weak) IBOutlet UIView *disableAddItemView;
@property (nonatomic, weak) IBOutlet UILabel *disableAddItemLabel;

@property (nonatomic, weak) ListService *listService;
@property (nonatomic, strong) PFObject *list;
@property (nonatomic, strong) NSArray *listItems;
@property (nonatomic, weak) PFObject *editedListItem;
@property (nonatomic, strong) UITextView *editedTextView;
@property (nonatomic, strong) NSString *editedListItemName;
@property (nonatomic, strong) NSIndexPath *editedIndexPath;
@property (nonatomic, strong) NSString *editedText;
@property (nonatomic, strong) UIView *blockingView;
@property (nonatomic, strong) UITextView *calculationTextView;

@property (nonatomic, strong) UITapGestureRecognizer *dismissKeyboardTap;
@property (nonatomic, assign) BOOL textViewEditBeginning;

@property (nonatomic, strong) NSMutableArray *rows;
@property (nonatomic, strong) JTTableViewGestureRecognizer *tableViewRecognizer;
@property (nonatomic, strong) id grabbedObject;
@property (nonatomic, strong) NSIndexPath *dummyIndexPath;
@property (nonatomic, assign) CGFloat dummyCellHeight;
@property (nonatomic, strong) NSIndexPath *firstCompletedIP;
@property (nonatomic, strong) NSNotification *receivedNotification;
@property (nonatomic, strong) UIView *introView;

-(IBAction)introOKButtonPressed:(id)sender;

@end

@implementation ListController

- (id)initWithList:(PFObject *)theList;
{
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    self.list = theList;
    self.editedIndexPath = nil;
    self.editedTextView = nil;
    self.textViewEditBeginning = NO;
    self.dummyIndexPath = nil;
    self.receivedNotification = nil;
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.automaticallyAdjustsScrollViewInsets = NO;
  
  // Customize nav bar
  self.navigationItem.title = [self.list objectForKey:kListNameKey];
  
  // Customize toolbar
  UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"UIButtonBarAction"]
                                                                    style:UIBarButtonItemStylePlain target:self
                                                                   action:@selector(actionButtonPressed)];
  barButtonItem.imageInsets = UIEdgeInsetsMake(0, 5.0, 0, 0);
  UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
  
  [self setToolbarItems:[NSArray arrayWithObjects:flexibleSpace, barButtonItem, nil]];
  
  // Custom initialization
  self.view.backgroundColor = [SHPalette backgroundColor];
  self.tableView.backgroundColor = [SHPalette backgroundColor];
  self.tableView.opaque = FALSE;
  self.tableView.contentInset = UIEdgeInsetsMake(self.tableView.contentInset.top,
                                                 self.tableView.contentInset.left,
                                                 44.f,
                                                 self.tableView.contentInset.right);
  self.listService = [ListService sharedInstance];
  self.calculationTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frameSizeWidth - kTextViewLeftMargin - kTextViewRightMargin, 44)];
  self.calculationTextView.font = [kAppDelegate globalFontWithSize:kTextViewFontSize];
  self.calculationTextView.alpha = 0;
  self.calculationTextView.scrollEnabled = YES;
  
  self.blockingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
  self.blockingView.backgroundColor = [UIColor whiteColor];
  [self.view addSubview:self.blockingView];
  
  self.addItemTextField.font = [kAppDelegate globalFontWithSize:kTextViewFontSize];
  self.disableAddItemLabel.font = [kAppDelegate globalFontWithSize:kTextViewFontSize];
  
  self.tableViewRecognizer = [self.tableView enableGestureTableViewWithDelegate:self];
  
  // Pull to refresh
  __weak ListController *wSelf = self;
  [self.tableView addPullToRefreshWithActionHandler:^{
    [wSelf closeAllDrawers];
    [wSelf.listService retrieveItemsForList:wSelf.list usingCache:NO];
  }];
  
  self.dismissKeyboardTap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                    action:@selector(dismissKeyboard)];
  self.dismissKeyboardTap.delegate = self;
  
  // register for notifications
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationHandler:) name:kAllListItemsReceivedNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationHandler:) name:kListItemsReceiveErrorNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationHandler:) name:kListItemDeleteErrorNotification object:nil];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardDidShow:)
                                               name:UIKeyboardDidShowNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWillBeHidden:)
                                               name:UIKeyboardWillHideNotification
                                             object:nil];
  
  
  NSString *key = [NSString stringWithFormat:@"%@%@", kListIntroShownKey, [User currentUser].myUserID];
  if ( ! [[NSUserDefaults standardUserDefaults] stringForKey:key] ) {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
    self.introView = [[UIView alloc] initWithFrame: self.view.bounds];
    self.introView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.introView.backgroundColor = [UIColor whiteColor];
    
    UIView *listIntroView = (UIView *)([[NSBundle mainBundle] loadNibNamed:@"ListIntroView" owner:self options:nil][0]);
    // center list intro view
    listIntroView.frame = CGRectMake(listIntroView.frame.origin.x,
                                     (self.introView.frame.size.height - listIntroView.frame.size.height) / 2.f,
                                     listIntroView.frame.size.width,
                                     listIntroView.frame.size.height);
    UIImageView* imageView = (UIImageView *)[listIntroView viewWithTag:100];
    imageView.layer.borderWidth = 1.f;
    imageView.layer.borderColor = [UIColor darkGrayColor].CGColor;
    imageView.layer.masksToBounds = NO;
    imageView.layer.shadowRadius = 2.f;
    imageView.layer.shadowOpacity = 0.6;
    
    imageView = (UIImageView *)[listIntroView viewWithTag:101];
    imageView.layer.borderWidth = 1.f;
    imageView.layer.borderColor = [UIColor darkGrayColor].CGColor;
    imageView.layer.masksToBounds = NO;
    imageView.layer.shadowRadius = 2.f;
    imageView.layer.shadowOpacity = 0.6;
    
    [self.introView addSubview:listIntroView];
    [self.view addSubview:self.introView];
    [self.navigationController setNavigationBarHidden: YES];
    [self.navigationController setToolbarHidden: YES];
  } else {
    [self kickoff];
  }
  
}

- (void)kickoff {
  // Fetch data
  [self.listService retrieveItemsMaybeFromCacheForList:self.list];
}

-(void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  if (self.introView.superview == nil) {
    [self.navigationController setToolbarHidden:NO animated:YES];
  }
  
}

-(void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  [self.navigationController setToolbarHidden:YES animated:YES];
  [self.navigationController setNavigationBarHidden:NO animated:YES];
  [[UIApplication sharedApplication] setStatusBarHidden:NO];
  
}

-(void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
  
  if (self.navigationController == nil) {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
  }
  
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];

  self.calculationTextView.frame = CGRectMake(0, 0, self.tableView.frameSizeWidth - kTextViewLeftMargin - kTextViewRightMargin, 44);
}

#pragma mark - getters/setters
-(NSArray *)listItems {
  return [self.listService listItemsForList:self.list];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)theTableView numberOfRowsInSection:(NSInteger)section
{
  return self.listItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)theTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  PFObject *theListItem = [self itemAtIndexPath:indexPath];
  if (!theListItem) {
    return [self dummyCell];
  }
  
  static NSString *CellIdentifier = @"panningCell";
  ListTableViewCell *cell = [theTableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (!cell) {
    cell = [[ListTableViewCell alloc] initWithReuseIdentifier:CellIdentifier];
    
    [cell.markButton addTarget:self
                        action:@selector(markButtonPressed:)
              forControlEvents:UIControlEventTouchUpInside];
    [cell.deleteButton addTarget:self
                          action:@selector(deleteButtonPressed:)
                forControlEvents:UIControlEventTouchUpInside];
    [cell.partnerButton addTarget:self
                           action:@selector(partnerButtonPressed:)
                 forControlEvents:UIControlEventTouchUpInside];
    [cell.myButton addTarget:self
                      action:@selector(myButtonPressed:)
            forControlEvents:UIControlEventTouchUpInside];
    
    cell.textView.delegate = self;
  }
  
  cell.delegate = self;
  cell.directionMask = HHPanningTableViewCellDirectionLeft | HHPanningTableViewCellDirectionRight;
  cell.maximumPan = 140.f;
  cell.minimumPan = 30.f;
  
  if ([indexPath isEqual:self.editedIndexPath]) {
    cell.textView.text = self.editedText;
  } else {
    cell.textView.text = theListItem[kListItemKey];
  }
  
  CGFloat cellHeight = [self cellHeightForText:cell.textView.text];
  CGRect textViewFrame = cell.textView.frame;
  textViewFrame.size.height = [self heightForTextInTextView:cell.textView.text];
  textViewFrame.origin.y = (cellHeight - textViewFrame.size.height) / 2.0;
  cell.textView.frame = textViewFrame;
  
  if ([theListItem[kListItemCompleteKey] boolValue]) {
    cell.textView.textColor = [UIColor lightGrayColor];
    [cell.markButton setTitle:@"Unmark" forState:UIControlStateNormal];
    cell.membersView.alpha = 0.3f;
  } else {
    cell.textView.textColor = [UIColor blackColor];
    [cell.markButton setTitle:@"Mark" forState:UIControlStateNormal];
    cell.membersView.alpha = 1.f;
  }
  
  if ([theListItem[kListItemMembersKey] containsObject:[User currentUser].partnerUserID]) {
    cell.partnerLabel.alpha = 1.0f;
  } else {
    cell.partnerLabel.alpha = 0.5f;
  }
  
  if ( [self currentUserIsAListItemMember:theListItem] ) {
    cell.myLabel.alpha = 1.0f;
  } else {
    cell.myLabel.alpha = 0.4f;
  }
  
  [cell updateMembers: theListItem[kListItemMembersKey]];
  
  cell.separator.hidden = (indexPath.row == 0);
  
  return cell;
}

-(void)tableView:(UITableView *)theTableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
  cell.backgroundColor = [UIColor whiteColor];
}


-(CGFloat)tableView:(UITableView *)theTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  NSString *theText;
  
  if ([indexPath isEqual:self.dummyIndexPath]) {
    return self.dummyCellHeight;
  } else if ([indexPath isEqual:self.editedIndexPath]) {
    theText = self.editedText;
  } else {
    PFObject *theListItem = [self itemAtIndexPath:indexPath];
    theText = theListItem[kListItemKey];
  }
  
  return [self cellHeightForText:theText];
}

-(CGFloat)cellHeightForText:(NSString *)text {
  
  
  return MAX([self heightForTextInTextView:text] + kCellPaddingHeight, kMinimumCellHeight);
  
}

-(CGFloat)heightForTextInTextView:(NSString *)text {
  self.calculationTextView.text = text;
  
  CGRect rect = [self.calculationTextView.layoutManager usedRectForTextContainer:self.calculationTextView.textContainer];
  UIEdgeInsets insets = self.calculationTextView.textContainerInset;
  
  return rect.size.height + insets.top + insets.bottom;
  
}

// Override to support editing the table view.
- (void)deleteButtonPressed:(UIButton *)button
{
  // Delete the row from the data source
  ListTableViewCell *cell = (ListTableViewCell *)[SHUtil tableViewCellForView:button];
  if (!cell) {
    return;
  }
  
  NSIndexPath *ip = [self.tableView indexPathForCell:cell];
  PFObject *theListItem = [self itemAtIndexPath:ip];
  [self performDeleteListItem:theListItem];
  
  [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:ip] withRowAnimation:UITableViewRowAnimationFade];
}

// Override to support rearranging the table view.
- (void)tableView:(UITableView *)theTableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
  if ([fromIndexPath compare:toIndexPath] != NSOrderedSame) {
    PFObject *theListItem = [self itemAtIndexPath:fromIndexPath];
    [self.listService moveListItem:theListItem toIndex:toIndexPath.row inList:self.list];
    [self.listService saveList:self.list withListItems:self.listItems];
  }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
  return NO;
}

-(void)tableView:(UITableView *)theTableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath {
  
}

-(void)tableView:(UITableView *)theTableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
  
}

-(UIView *)tableView:(UITableView *)theTableView viewForFooterInSection:(NSInteger)section {
  return [UIView new];
}

#pragma mark table view helpers
-(UITableViewCell *)dummyCell {
  static NSString *CellIdentifier = @"dummyCell";
  UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (!cell) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
  }
  cell.textLabel.text = @"";
  cell.detailTextLabel.text = @"";
  return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)theTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  ListTableViewCell *cell = (ListTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
  
  if ([cell isDrawerRevealed]) {
    return;
  }
  
  PFObject *theListItem = [self itemAtIndexPath:indexPath];
  if ( ! [theListItem[kListItemCompleteKey] boolValue] ) {
    if (self.editedIndexPath) {
      self.textViewEditBeginning = YES;
      [self storeEditedListItem];
      self.editedTextView.userInteractionEnabled = NO;
      self.editedTextView.editable = NO;
    }
    UITextView *tv = cell.textView;
    tv.userInteractionEnabled = YES;
    tv.editable = YES;
    self.editedIndexPath = indexPath;
    self.editedTextView = tv;
    self.editedText = tv.text;
    [tv becomeFirstResponder];
    double delayInSeconds = 0.6;
    __weak ListController *wSelf = self;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
      [wSelf.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:YES];
    });
    [self closeAllDrawers];
    
    if (self.addItemTextField.enabled) {
      [self.navigationItem setHidesBackButton:YES animated:YES];
      self.addItemTextField.enabled = FALSE;
      self.blockingView.frame = self.addItemBackground.frame;
      self.blockingView.alpha = 0.0;
      [UIView animateWithDuration:0.3 animations:^{
        wSelf.blockingView.alpha = 0.9;
      }];
    }
    
  }
}

- (NSIndexPath *)tableView:(UITableView *)theTableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
  
  BOOL fromItemCompleted = [[[self.listItems objectAtIndex:sourceIndexPath.row] objectForKey:kListItemCompleteKey] boolValue];
  BOOL toItemCompleted = [[[self.listItems objectAtIndex:proposedDestinationIndexPath.row] objectForKey:kListItemCompleteKey] boolValue];
  
  if (fromItemCompleted == toItemCompleted) {
    return proposedDestinationIndexPath;
  } else {
    NSInteger firstCompleteItemIndex = -1;
    for (PFObject *anItem in self.listItems) {
      if ([[anItem objectForKey:kListItemCompleteKey] boolValue]) {
        firstCompleteItemIndex = [self.listItems indexOfObject:anItem];
        break;
      }
    }
    if (fromItemCompleted) {
      return [NSIndexPath indexPathForRow:firstCompleteItemIndex inSection:0];
    } else {
      if (firstCompleteItemIndex > 0) {
        return [NSIndexPath indexPathForRow:(firstCompleteItemIndex-1) inSection:0];
      } else {
        return [NSIndexPath indexPathForRow:([self.tableView numberOfRowsInSection:0] - 1) inSection:0];
      }
    }
  }
}

#pragma mark JTTableViewGestureMoveRowDelegate

- (BOOL)gestureRecognizer:(JTTableViewGestureRecognizer *)gestureRecognizer canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
  ListTableViewCell *cell = (ListTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
  return ![cell isDrawerRevealed] && !self.editedIndexPath;
}

- (void)gestureRecognizer:(JTTableViewGestureRecognizer *)gestureRecognizer needsCreatePlaceholderForRowAtIndexPath:(NSIndexPath *)indexPath {
  self.dummyIndexPath = indexPath;
  self.dummyCellHeight = [self.tableView cellForRowAtIndexPath:indexPath].frame.size.height;
  self.firstCompletedIP = [self firstCompletedIndexPath];
  [self closeAllDrawers];
}

- (void)gestureRecognizer:(JTTableViewGestureRecognizer *)gestureRecognizer needsMoveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
  if (![sourceIndexPath isEqual:destinationIndexPath]) {
    PFObject *theListItem = self.listItems[sourceIndexPath.row];
    [self.listService moveListItem:theListItem toIndex:destinationIndexPath.row inList:self.list];
    
    if (self.firstCompletedIP && destinationIndexPath.row >= self.firstCompletedIP.row) {
      theListItem[kListItemCompleteKey] = @YES;
    } else {
      theListItem[kListItemCompleteKey] = @NO;
    }
    [self.listService saveList:self.list withListItems:self.listItems];
    if ([sourceIndexPath isEqual:self.dummyIndexPath]) {
      self.dummyIndexPath = destinationIndexPath;
    }
    if (sourceIndexPath.row == 0) {
      UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:sourceIndexPath];
      if ([cell isKindOfClass:[ListTableViewCell class]]) {
        [(ListTableViewCell *)cell separator].hidden = NO;
      }
    }
  }
}

- (void)gestureRecognizer:(JTTableViewGestureRecognizer *)gestureRecognizer needsReplacePlaceholderForRowAtIndexPath:(NSIndexPath *)indexPath {
  self.dummyIndexPath = nil;
  [self.listService saveList:self.list withListItems:self.listItems];
  if (self.receivedNotification) {
    [self notificationHandler:self.receivedNotification];
  }
}


#pragma mark Text Field delegate functions
-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
  [self closeAllDrawers];
  self.tableView.userInteractionEnabled = FALSE;
  self.blockingView.frame = CGRectMake(0,
                                       self.addItemBackground.frame.size.height + 20.0,
                                       self.view.frame.size.width,
                                       self.view.frame.size.height - self.addItemBackground.frame.size.height - 20);
  self.blockingView.alpha = 0.0;
  __weak ListController *wSelf = self;
  [UIView animateWithDuration:0.3 animations:^{
    wSelf.addItemBackground.center = CGPointMake(wSelf.addItemBackground.center.x, wSelf.addItemBackground.center.y - 64.0);
    wSelf.blockingView.alpha = 0.9;
  }];
  
  [self.navigationItem setHidesBackButton:YES animated:YES];
  [self.navigationController setNavigationBarHidden:YES animated:YES];
  [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
  
  [self.navigationController setToolbarHidden:YES animated:NO];
  
  return YES;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
  [textField resignFirstResponder];
  return YES;
}

-(void)textFieldDidEndEditing:(UITextField *)textField {
  self.tableView.userInteractionEnabled = TRUE;
  __weak ListController *wSelf = self;
  [UIView animateWithDuration:0.2 animations:^{
    wSelf.addItemBackground.center = CGPointMake(wSelf.addItemBackground.center.x, wSelf.addItemBackground.center.y + 64.0);
    wSelf.blockingView.alpha = 0.0;
  } completion:^(BOOL finished) {
    wSelf.blockingView.frame = CGRectMake(0, 0, 0, 0);
  }];
  [self.navigationItem setHidesBackButton:NO animated:YES];
  [self.navigationController setNavigationBarHidden:NO animated:YES];
  [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
  
  if (![textField.text isEqualToString:@""]) {
    // create a new list item
    [self.listService createNewListItem:textField.text forList:self.list];
    textField.text = @"";
    
    ListTableViewCell *cell = (ListTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    cell.separator.hidden = NO;
    
    [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationTop];
    
    if (self.listItems.count >= kMaxNumberOfListItems) {
      [self disableAddItemTextField];
    }
    
  }
}

#pragma mark Text View delegate functions
-(BOOL)textViewShouldBeginEditing:(UITextView *)textView {
  
  [self.navigationController setToolbarHidden:YES animated:NO];
  
  return YES;
}

-(void)textViewDidBeginEditing:(UITextView *)textView {
  self.textViewEditBeginning = NO;
}

-(void)textViewDidEndEditing:(UITextView *)textView {
  if (self.editedTextView == textView) {
    [self completeTextViewEdit];
  }
  [self.navigationController setToolbarHidden:NO animated:YES];
}


-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
  
  if ([text isEqualToString:@"\n"]) {
    [textView resignFirstResponder];
  }
  
  return TRUE;
}

-(void)textViewDidChange:(UITextView *)textView {
  
  CGRect textViewFrame = textView.frame;
  if (self.editedTextView == textView) {
    self.editedText = textView.text;
  }
  
  CGFloat height = [self heightForTextInTextView:textView.text];
  if (height != textViewFrame.size.height) {
    textViewFrame.size.height = height;
    textView.frame = textViewFrame;
    
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
  }
  
}
#pragma mark utilities
-(PFObject *)itemAtIndexPath:(NSIndexPath *)indexPath {
  if (!self.dummyIndexPath) {
    return self.listItems[indexPath.row];
  } else if (indexPath.row == self.dummyIndexPath.row) {
    return nil;
  } else {
    return self.listItems[indexPath.row];
  }
  
}

-(NSIndexPath *)firstCompletedIndexPath {
  for (PFObject *item in self.listItems) {
    if ([item[kListItemCompleteKey] boolValue]) {
      return [NSIndexPath indexPathForRow:[self.listItems indexOfObject:item] inSection:0];
    }
  }
  return nil;
}

-(void)completeTextViewEdit {
  [self storeEditedListItem];
  self.editedTextView.editable = NO;
  self.editedTextView.userInteractionEnabled = NO;
  self.editedIndexPath = nil;
  self.editedTextView = nil;
  if (!self.textViewEditBeginning) {
    [self.navigationItem setHidesBackButton:NO animated:YES];
    
    self.addItemTextField.enabled = TRUE;
    __weak ListController *wSelf = self;
    [UIView animateWithDuration:0.3 animations:^{
      wSelf.blockingView.alpha = 0.0;
    } completion:^(BOOL finished) {
      wSelf.blockingView.frame = CGRectMake(0, 0, 0, 0);
    }];
  }
}

- (BOOL)currentUserIsAListItemMember:(PFObject *)listItem {
  return  ([User currentUser].myUserEmail && [listItem[kListItemMembersKey] containsObject:[User currentUser].myUserEmail]) ||
  ([User currentUser].myFBID && [listItem[kListItemMembersKey] containsObject:[User currentUser].myFBID]);
  
}
#pragma mark button presses
-(void)markButtonPressed:(UIButton *)theButton {
  ListTableViewCell *cell = (ListTableViewCell *)[SHUtil tableViewCellForView: theButton];
  if (!cell) {
    return;
  }
  
  [cell setDrawerRevealed:NO animated:YES];
  
  PFObject *theListItem = [self itemAtIndexPath:[self.tableView indexPathForCell:cell]];
  if (!theListItem) {
    return;
  }
  
  if ([theListItem[kListItemCompleteKey] boolValue]) {
    [theButton setTitle:@"Mark" forState:UIControlStateNormal];
    cell.membersView.alpha = 1.0f;
    cell.textView.textColor = [UIColor blackColor];
    theListItem[kListItemCompleteKey] = @NO;
    theListItem[kModifiedDateKey] = [NSDate date];
    
    // move cell
    NSIndexPath *fromIndexPath = [self.tableView indexPathForCell:cell];
    // count number of incomplete list items
    NSInteger numIncompleteItems = 0;
    for (PFObject *aListItem in self.listItems) {
      if (aListItem != theListItem &&
          ![[aListItem objectForKey:kListItemCompleteKey] boolValue]) {
        numIncompleteItems++;
      }
    }
    
    NSIndexPath *toIndexPath = [NSIndexPath indexPathForRow:numIncompleteItems inSection:0];
    
    if ([fromIndexPath compare:toIndexPath] != NSOrderedSame) {
      PFObject *theListItem = [self.listItems objectAtIndex:fromIndexPath.row];
      [self.listService moveListItem:theListItem toIndex:toIndexPath.row inList:self.list];
      [self.tableView moveRowAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
      
    }
    
  } else {
    [theButton setTitle:@"Unmark" forState:UIControlStateNormal];
    cell.membersView.alpha = 0.3f;
    cell.textView.textColor = [UIColor lightGrayColor];
    theListItem[kListItemCompleteKey] = @YES;
    theListItem[kModifiedDateKey] = [NSDate date];
    
    // move cell
    NSIndexPath *fromIndexPath = [self.tableView indexPathForCell:cell];
    // count number of complete list items
    NSInteger numCompleteItems = 0;
    for (PFObject *aListItem in self.listItems) {
      if (aListItem != theListItem &&
          [[aListItem objectForKey:kListItemCompleteKey] boolValue]) {
        numCompleteItems++;
      }
    }
    
    NSIndexPath *toIndexPath = [NSIndexPath indexPathForRow:(self.listItems.count - 1 - numCompleteItems) inSection:0];
    if ([fromIndexPath compare:toIndexPath] != NSOrderedSame) {
      PFObject *theListItem = [self.listItems objectAtIndex:fromIndexPath.row];
      [self.listService moveListItem:theListItem toIndex:toIndexPath.row inList:self.list];
      [self.tableView moveRowAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
      
    }
    
    cell.separator.hidden = (toIndexPath.row == 0);
    
    // keep track of edited index path
    if (self.editedIndexPath && fromIndexPath.row < self.editedIndexPath.row) {
      self.editedIndexPath = [NSIndexPath indexPathForRow:(self.editedIndexPath.row - 1) inSection:self.editedIndexPath.section];
    }
    
  }
  
  [self.listService saveList:self.list withListItems:self.listItems];
  
}

-(void)actionButtonPressed {
  [self closeAllDrawers];
  UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:kActionDeleteCompletedItems, kActionEmailList, kActionSendNotification, nil];
  actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
  
  [actionSheet showFromToolbar:self.navigationController.toolbar];
}

-(void)partnerButtonPressed:(UIButton *)button {
  NSMutableArray *members = [NSMutableArray array];
  
  ListTableViewCell *cell = (ListTableViewCell *)[SHUtil tableViewCellForView:button];
  if (!cell) {
    return;
  }
  PFObject *listItem = self.listItems[ [self.tableView indexPathForCell:cell].row ];
  if ( ! [listItem[kListItemMembersKey] containsObject:[User currentUser].partnerUserID] ) {
    [members addObject:[User currentUser].partnerUserID];
    cell.partnerLabel.alpha = 1.0;
  } else {
    cell.partnerLabel.alpha = 0.5;
  }
  if ( [self currentUserIsAListItemMember:listItem] ) {
    [members addObjectsFromArray:[User currentUser].myUserIDs];
  }
  listItem[kListItemMembersKey] = members;
  [self.listService saveListItem:listItem];
  
  [cell updateMembers:listItem[kListItemMembersKey]];
  
}

-(void)myButtonPressed:(UIButton *)button {
  NSMutableArray *members = [NSMutableArray array];
  
  ListTableViewCell *cell = (ListTableViewCell *)[SHUtil tableViewCellForView:button];
  if (!cell) {
    return;
  }
  PFObject *listItem = self.listItems[ [self.tableView indexPathForCell:cell].row ];
  if ( ! [self currentUserIsAListItemMember:listItem] ) {
    [members addObjectsFromArray:[User currentUser].myUserIDs];
    cell.myLabel.alpha = 1.0f;
  } else {
    cell.myLabel.alpha = 0.4f;
  }
  if ( [listItem[kListItemMembersKey] containsObject:[User currentUser].partnerUserID] ) {
    [members addObject:[User currentUser].partnerUserID];
  }
  listItem[kListItemMembersKey] = members;
  [self.listService saveListItem:listItem];
  
  [cell updateMembers:listItem[kListItemMembersKey]];
}

#pragma mark Action Sheet delegate functions
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
  NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
  if ([buttonTitle isEqualToString:kActionDeleteCompletedItems]) {
    NSMutableArray *discardedItems = [NSMutableArray array];
    for (PFObject *listItem in self.listItems) {
      if ([[listItem objectForKey:kListItemCompleteKey] boolValue]) {
        [discardedItems addObject:listItem];
      }
    }
    if (discardedItems.count > 0) {
      for (PFObject *listItem in discardedItems) {
        [self performDeleteListItem:listItem];
      }
      [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0]
                    withRowAnimation:UITableViewRowAnimationFade];
    }
  } else if ([buttonTitle isEqualToString:kActionEmailList]) {
    
    if ([MFMailComposeViewController canSendMail] == FALSE) {
      UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                     message:@"Sorry, your device is unable to send e-mail."
                                                              preferredStyle:UIAlertControllerStyleAlert];
      [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                style:UIAlertActionStyleCancel
                                              handler:nil]];
      [self presentViewController:alert
                         animated:YES
                       completion:nil];
      
    } else {
      MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
      picker.mailComposeDelegate = self;
      
      // Set up recipients
      
      [picker setSubject:[self.list objectForKey:kListNameKey]];
      
      NSString *messageBody = @"";
      BOOL seenCompleted = FALSE;
      
      for (PFObject *listItem in self.listItems) {
        if ([[listItem objectForKey:kListItemCompleteKey] boolValue] && !seenCompleted) {
          seenCompleted = TRUE;
          messageBody = [messageBody stringByAppendingString:@"\nCompleted:\n"];
        }
        
        messageBody = [messageBody stringByAppendingFormat:@"%@\n", [listItem objectForKey:kListItemKey]];
      }
      
      [picker setMessageBody:messageBody isHTML:NO];
      
      [self presentViewController:picker animated:YES completion:NULL];
    }
  } else if ([buttonTitle isEqualToString:kActionSendNotification]) {
    NSString *pushMessage = [NSString stringWithFormat:@"%@ has updated the %@ list", [[User currentUser] myNameOrEmail], self.list[kListNameKey]];
    
    NSDictionary *pushUserInfo = @{@"alert" : pushMessage,
                                   @"sound" : @"default",
                                   kPushTypeKey : kListNotification,
                                   @"badge" : @"Increment"};
    
    [SHUtil sendPushNotification:pushUserInfo];
    
  }
  
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
  
  [self dismissViewControllerAnimated:YES completion:NULL];
  
}


#pragma mark Notification handlers
-(void)notificationHandler:(NSNotification *)notification {
  if (self.dummyIndexPath) {
    self.receivedNotification = notification;
  } else {
    if ([notification.name isEqualToString:kAllListItemsReceivedNotification]) {
      [self handleAllListItemsReceived:notification];
    } else if ([notification.name isEqualToString:kListItemsReceiveErrorNotification]) {
      [self handleReceiveListItemsError:notification];
    } else if ([notification.name isEqualToString:kListItemDeleteErrorNotification]) {
      [self handleListItemDeleteError:notification];
    }
    self.receivedNotification = nil;
  }
}

-(void)handleAllListItemsReceived:(NSNotification *)notification {
  
  [self.tableView.pullToRefreshView stopAnimating];
  [self closeAllDrawers];
  
  NSDictionary *userInfo = [notification userInfo];
  if (userInfo[kNotificationListKey] == self.list) {
    if (!self.editedIndexPath) {
      [self.tableView reloadData];
    }
    
    if (self.listItems.count >= kMaxNumberOfListItems) {
      [self disableAddItemTextField];
    } else {
      [self enableAddItemTextField];
    }
    
  }
}

-(void)handleReceiveListItemsError:(NSNotification *)notification {
  [self.tableView.pullToRefreshView stopAnimating];
  [self closeAllDrawers];
  [SHUtil showWarningInView:self.tableView
                      title:@"Network Error"
                    message:@"Unable to retrieve list items at this time.  Please try later."];
  
}

-(void)handleListItemDeleteError:(NSNotification *)notification {
  [self closeAllDrawers];
  [SHUtil showWarningInView:self.tableView
                      title:@"Network Error"
                    message:@"Unable to delete list item at this time.  Please try later."];
  
  [self.tableView reloadData];
}

#pragma mark utility functions
-(void)storeEditedListItem {
  if (self.editedText && ![self.editedText isEqualToString:@""]) {
    
    // modify name of current list item
    PFObject *theListItem = self.listItems[self.editedIndexPath.row];
    if (theListItem &&
        ![theListItem[kListItemKey] isEqualToString:self.editedText]) {
      theListItem[kListItemKey] = self.editedText;
      theListItem[kModifiedDateKey] = [NSDate date];
      [self.listService saveList:self.list withListItems:self.listItems];
    }
  } else {
    PFObject *theListItem = self.listItems[self.editedIndexPath.row];
    [self performDeleteListItem:theListItem];
    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:self.editedIndexPath] withRowAnimation:UITableViewRowAnimationFade];
  }
}

-(void)performDeleteListItem:(PFObject *)theListItem {
  theListItem[kModifiedDateKey] = [NSDate date];
  [self.listService deleteListItem:theListItem fromList:self.list];
  [self.listService saveList:self.list withListItems:self.listItems];
  
  if (self.listItems.count < kMaxNumberOfListItems && !self.disableAddItemView.hidden) {
    [self enableAddItemTextField];
  }
  
}

- (void)keyboardDidShow:(NSNotification *)aNotification {
  
  NSDictionary *info = [aNotification userInfo];
  NSValue *aValue = [info objectForKey:UIKeyboardFrameEndUserInfoKey];
  CGSize keyboardSize = [aValue CGRectValue].size;
  NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] floatValue];
  
  if (self.navigationController.navigationBarHidden) {
    [self.blockingView addGestureRecognizer:self.dismissKeyboardTap];
  }
  
  __weak ListController *wSelf = self;
  
  [UIView animateWithDuration:duration
                        delay:0
                      options:UIViewAnimationOptionBeginFromCurrentState
                   animations:^{
                     wSelf.tableView.contentInset = UIEdgeInsetsMake(wSelf.tableView.contentInset.top,
                                                                     wSelf.tableView.contentInset.left,
                                                                     keyboardSize.height,
                                                                     wSelf.tableView.contentInset.right);
                     wSelf.tableView.scrollIndicatorInsets = wSelf.tableView.contentInset;
                   } completion:NULL];
}

- (void)keyboardWillBeHidden:(NSNotification *)aNotification {
  [self.navigationController setToolbarHidden:NO animated:NO];
  
  NSDictionary *info = [aNotification userInfo];
  NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] floatValue];
  
  [self.blockingView removeGestureRecognizer:self.dismissKeyboardTap];
  
  __weak ListController *wSelf = self;
  
  [UIView animateWithDuration:duration
                        delay:0
                      options:UIViewAnimationOptionBeginFromCurrentState
                   animations:^{
                     wSelf.tableView.contentInset = UIEdgeInsetsMake(wSelf.tableView.contentInset.top,
                                                                     wSelf.tableView.contentInset.left,
                                                                     44.0,
                                                                     wSelf.tableView.contentInset.right);
                     wSelf.tableView.scrollIndicatorInsets = wSelf.tableView.contentInset;
                   } completion:NULL];
  
}

-(void)dismissKeyboard {
  [self.view endEditing:YES];
}

-(void)disableAddItemTextField {
  self.disableAddItemView.hidden = FALSE;
  self.disableAddItemLabel.hidden = FALSE;
  self.addItemTextField.placeholder = @"";
}

-(void)enableAddItemTextField {
  self.disableAddItemView.hidden = TRUE;
  self.disableAddItemLabel.hidden = TRUE;
  self.addItemTextField.placeholder = kListItemPlaceholderText;
}

-(void)closeAllDrawers {
  for (UITableViewCell *cell in self.tableView.visibleCells) {
    if ([cell isKindOfClass:[ListTableViewCell class]]) {
      [(ListTableViewCell *)cell setDrawerRevealed:NO animated:YES];
    }
  }
}

-(void)closeAllDrawersExceptCell:(ListTableViewCell *)exceptedCell {
  for (UITableViewCell *cell in self.tableView.visibleCells) {
    if ([cell isKindOfClass:[ListTableViewCell class]] && ! [cell isEqual:exceptedCell]) {
      [(ListTableViewCell *)cell setDrawerRevealed:NO animated:YES];
    }
  }
}

#pragma mark HHPanningTableViewCellDelegate

- (BOOL)panningTableViewCellShouldSlide:(HHPanningTableViewCell *)cell {
  [self closeAllDrawersExceptCell:(ListTableViewCell *)cell];
  
  return !self.navigationItem.hidesBackButton;
  
}

#pragma mark intro
-(void)introOKButtonPressed:(id)sender {
  [self.navigationController setNavigationBarHidden: NO animated:YES];
  [self.navigationController setToolbarHidden:NO animated:YES];
  
  __weak ListController *wSelf = self;
  
  [UIView animateWithDuration:0.4
                   animations:^{
                     wSelf.introView.alpha = 0.0;
                   } completion:^(BOOL finished) {
                     [wSelf.introView removeFromSuperview];
                   }];
  [self kickoff];
}

#pragma mark UIScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
  [self closeAllDrawers];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  for (UITableViewCell *cell in self.tableView.visibleCells) {
    if ([cell isKindOfClass:[ListTableViewCell class]]) {
      if ([(HHPanningTableViewCell *)cell isDrawerRevealed]) {
        [(ListTableViewCell *)cell setDrawerRevealed:NO animated:YES];
      }
    }
  }
}

@end
