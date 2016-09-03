//
//  ListsController.m
//  Shared
//
//  Created by Brian Bernberg on 5/14/12.
//  Copyright (c) 2012 BB Consulting. All rights reserved.
//

#import "ListsController.h"
#import "ListService.h"
#import "Parse/Parse.h"
#import "ListController.h"
#import "SVPullToRefresh.h"
#import "MyReach.h"
#import "Constants.h"
#import "PSPDFAlertView.h"
#import "SHUtil.h"
#import "NotificationRetriever.h"
#import <MMDrawerController/MMDrawerBarButtonItem.h>
#import <MMDrawerController/UIViewController+MMDrawerController.h>
#import "UIView+Helpers.h"

#define kPlaceholderText @"New List...";
#define kCellTextFieldTag 1
#define kModifiedLabelTag 2

#define kTextFieldLeftMargin 12.f
#define kTextFieldRightMargin 12.f

@interface ListsController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, readonly) ListService *listService;
@property (nonatomic, readonly) NSArray *lists;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) PFObject *editedList;
@property (nonatomic, strong) UITextField *editedTextfield;
@property (nonatomic, strong) NSString *editedListName;
@property BOOL showingDeleteAlert;
@property NSMutableSet *textFieldsForNewLists;
@property BOOL textFieldEditBeginning;
@property (nonatomic, strong) UIView *alertContainer;

@end

@implementation ListsController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    self.title = @"Lists";
    self.textFieldEditBeginning = FALSE;
    self.automaticallyAdjustsScrollViewInsets = NO;
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  [[NSUserDefaults standardUserDefaults] setObject:@(SharedControllerTypeList) forKey:kCurrentSharedControllerType];
  [[NSUserDefaults standardUserDefaults] synchronize];

  self.tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
  self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  self.tableView.dataSource = self;
  self.tableView.delegate = self;
  [self.view addSubview:self.tableView];
  
  // register for notifications
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAllListsReceived) name:kAllListsReceivedNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleRecieveListsError) name:kListsReceiveErrorNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleListDeleteError) name:kListDeleteErrorNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleListDeleteError) name:kListDeleteErrorNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleListsNetworkError) name:kListsNetworkErrorNotification object:nil];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWillShow:)
                                               name:UIKeyboardWillShowNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWillHide:)
                                               name:UIKeyboardWillHideNotification
                                             object:nil];
  
  
  // Customize nav bar
  self.navigationItem.rightBarButtonItem = self.editButtonItem;
  
  // left button
  self.navigationItem.leftBarButtonItem = [[MMDrawerBarButtonItem alloc] initWithTarget:self action:@selector(drawerButtonPressed)];
  
  // Custom initialization
  self.tableView.contentInset = UIEdgeInsetsMake(64.0, 0, 0, 0);
  self.tableView.backgroundColor = [SHPalette backgroundColor];
  self.tableView.opaque = FALSE;
  self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
  UIView* footer = [[UIView alloc] initWithFrame: CGRectMake(0, 0, self.tableView.frame.size.width, 40.0)];
  footer.backgroundColor = [UIColor clearColor];
  self.tableView.tableFooterView = footer;
  self.showingDeleteAlert = FALSE;
  self.textFieldsForNewLists = [NSMutableSet set];
  
  // Pull to refresh
  __weak ListsController *weakSelf = self;
  [self.tableView addPullToRefreshWithActionHandler:^{
    [weakSelf.listService retrieveLists];
  }];
  self.tableView.showsPullToRefresh = NO;
  self.tableView.pullToRefreshView.hidden = YES;
  
  self.alertContainer = [[UIView alloc] initWithFrame: CGRectMake(0.f,
                                                                  self.tableView.contentInset.top,
                                                                  self.view.frame.size.width,
                                                                  self.view.frame.size.height - self.tableView.contentInset.top)];
  self.alertContainer.backgroundColor = [UIColor clearColor];
  self.alertContainer.userInteractionEnabled = NO;
  self.alertContainer.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin;
  [self.view addSubview:self.alertContainer];
  
  // Fetch data
  [self.listService retrieveLists];
  
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    [[NotificationRetriever instance] deleteNotificationsOfType:kListNotification];
  });
}

-(void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  [self.listService saveLists];
}

-(void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)drawerButtonPressed {
  [self.view endEditing:YES];
  [[self mm_drawerController] toggleDrawerSide:MMDrawerSideLeft animated:YES completion:NULL];
}

#pragma mark getters/setters
- (ListService *)listService {
  return [ListService sharedInstance];
}

- (NSArray *)lists {
  return [[ListService sharedInstance] lists];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  if (self.lists.count < kMaxNumberOfLists && ! self.editing) {
    return self.lists.count + 1; // +1 is "New List..."
  } else {
    return self.lists.count;
  }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (indexPath.row < self.lists.count) {
    
    static NSString *CellIdentifier = @"ListCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
      cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
      cell.selectionStyle = UITableViewCellSelectionStyleNone;
      cell.separatorInset = UIEdgeInsetsZero;
      
      cell.backgroundColor = [UIColor whiteColor];
      cell.showsReorderControl = TRUE;
      UITextField *cellTextField = [[UITextField alloc] initWithFrame:CGRectMake(kTextFieldLeftMargin,
                                                                                 10.f,
                                                                                 cell.contentView.frameSizeWidth - kTextFieldRightMargin - kTextFieldLeftMargin,
                                                                                 24.0)];
      cellTextField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
      cellTextField.placeholder = kPlaceholderText;
      cellTextField.font = [kAppDelegate globalFontWithSize:20.0];
      cellTextField.textColor = [UIColor blackColor];
      cellTextField.returnKeyType = UIReturnKeyDone;
      cellTextField.minimumFontSize = 12;
      cellTextField.delegate = self;
      cellTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
      cellTextField.tag = kCellTextFieldTag;
      cellTextField.backgroundColor = [UIColor clearColor];
      [cell.contentView addSubview:cellTextField];
      
      UILabel *modifiedLabel = [[UILabel alloc] initWithFrame:CGRectMake(kTextFieldLeftMargin, 38, 230, 18)];
      modifiedLabel.font = [kAppDelegate globalFontWithSize:14.0];
      modifiedLabel.textColor = [UIColor darkGrayColor];
      modifiedLabel.backgroundColor = [UIColor clearColor];
      modifiedLabel.tag = kModifiedLabelTag;
      [cell.contentView addSubview:modifiedLabel];
      
    }
    
    UITextField *theTextField = (UITextField *)[cell.contentView viewWithTag:kCellTextFieldTag];
    UILabel *modifiedLabel = (UILabel *)[cell.contentView viewWithTag:kModifiedLabelTag];
    
    PFObject *theList = self.lists[indexPath.row];
    if (theTextField != self.editedTextfield) {
      theTextField.placeholder = kPlaceholderText;
      theTextField.text = theList[kListNameKey];
    }
    theTextField.font = [kAppDelegate globalFontWithSize:20.0];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    theTextField.enabled = self.editing;
    
    if (theList[kListModifiedDateKey]) {
      NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
      [dateFormatter setDateFormat:@"MM/dd/yy"];
      
      NSString *modifiedDate = [dateFormatter stringFromDate:theList[kListModifiedDateKey]];
      modifiedLabel.text = [NSString stringWithFormat:@"Updated %@",modifiedDate];
    } else {
      modifiedLabel.text = @"";
    }
    return cell;
  } else {
    static NSString *CellIdentifier = @"NewListCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
      cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
      cell.selectionStyle = UITableViewCellSelectionStyleNone;
      
      cell.backgroundColor = [UIColor whiteColor];
      cell.showsReorderControl = TRUE;
      UITextField *cellTextField = [[UITextField alloc] initWithFrame:CGRectMake(kTextFieldLeftMargin,
                                                                                 18.f,
                                                                                 cell.contentView.frameSizeWidth - kTextFieldLeftMargin - kTextFieldRightMargin,
                                                                                 24.0)];
      cellTextField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
      cellTextField.placeholder = kPlaceholderText;
      cellTextField.font = [kAppDelegate globalFontWithSize:20.0];
      cellTextField.textColor = [UIColor blackColor];
      cellTextField.minimumFontSize = 12;
      cellTextField.delegate = self;
      cellTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
      cellTextField.tag = kCellTextFieldTag;
      [cell.contentView addSubview:cellTextField];
    }
    
    UITextField *theTextField = (UITextField *)[cell.contentView viewWithTag:kCellTextFieldTag];
    
    theTextField.enabled = NO;
    if (theTextField != self.editedTextfield) {
      theTextField.text = @"";
    }
    theTextField.font = [kAppDelegate globalFontWithSize:20.0];
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    return cell;
  }
  
}

#define kCellHeight 60.f

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return kCellHeight;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
  cell.backgroundColor = [UIColor whiteColor];
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
  // Return NO if you do not want the specified item to be editable.
  if (indexPath.row == self.lists.count) {
    return NO;
  } else {
    return YES;
  }
}


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (editingStyle == UITableViewCellEditingStyleDelete && indexPath.row < self.lists.count) {
    // Delete the row from the data source
    PFObject *theList = self.lists[indexPath.row];
    [self.listService deleteList:theList];
    [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
  }
}

// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
  if ([fromIndexPath compare:toIndexPath] != NSOrderedSame) {
    PFObject *theList = self.lists[fromIndexPath.row];
    [self.listService moveList:theList toIndex:toIndexPath.row];
  }
}

// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
  // Return NO if you do not want the item to be re-orderable.
  if (indexPath.row == self.lists.count) {
    return NO;
  } else {
    return YES;
  }
}


-(void)setEditing:(BOOL)editing animated:(BOOL)animated {
  [super setEditing:editing animated:animated];
  
  [self.tableView setEditing:editing animated:animated];
  
  if (!editing) {
    if (self.editedTextfield) {
      [self.editedTextfield resignFirstResponder];
    }
    self.editedTextfield = nil;
  }
  
  // ENABLE/DISABLE textfields
  for (UITableViewCell *theCell in self.tableView.visibleCells) {
    UITextField *theTextField = (UITextField *)[theCell.contentView viewWithTag:kCellTextFieldTag];
    if ([self.tableView indexPathForCell:theCell].row == self.lists.count) {
      theTextField.enabled = TRUE;
    } else {
      theTextField.enabled = editing;
    }
  }
  
  // ENABLE/DISABLE pull to refresh
  self.tableView.showsPullToRefresh = NO;
  
  
  NSIndexPath *lastIndexPath = [NSIndexPath indexPathForRow:self.lists.count inSection:0];
  
  if (editing) {
    [self.tableView deleteRowsAtIndexPaths:@[lastIndexPath]
                          withRowAnimation:UITableViewRowAnimationFade];
  } else {
    [self.tableView insertRowsAtIndexPaths:@[lastIndexPath]
                          withRowAnimation:UITableViewRowAnimationFade];
  }
  
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:NO];
  
  if (tableView.editing) {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    UITextField *tf = (UITextField *)[cell.contentView viewWithTag:kCellTextFieldTag];
    tf.enabled = YES;
    [tf becomeFirstResponder];
  } else {
    if ([self.textFieldsForNewLists count]) {
      // end editing
      [self.view endEditing: YES];
      return;
    }
    if (indexPath.row < self.lists.count) {
      PFObject *selectedList = [self.lists objectAtIndex:indexPath.row];
      if (selectedList) {
        [self.listService saveLists];
        
        // Show detail view of selected list
        ListController *listVC = [[ListController alloc] initWithList:selectedList];
        
        [self.navigationController pushViewController:listVC animated:YES];
      }
    } else {
      UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
      UITextField *tf = (UITextField *)[cell.contentView viewWithTag:kCellTextFieldTag];
      tf.enabled = YES;
      [tf becomeFirstResponder];
    }
  }
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
  if (proposedDestinationIndexPath.row >= self.lists.count) {
    return [NSIndexPath indexPathForRow:(self.lists.count-1) inSection:0];
  } else {
    return proposedDestinationIndexPath;
  }
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
  if (self.tableView.pullToRefreshView.state == SVPullToRefreshStateStopped) {
    if (self.tableView.contentOffset.y < -70 && ! self.tableView.editing) {
      self.tableView.showsPullToRefresh = YES;
    } else {
      self.tableView.showsPullToRefresh = NO;
    }
  }
}

#pragma mark Text Field delegate functions
-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
  self.textFieldEditBeginning = TRUE;
  if (self.editedTextfield && [self.editedTextfield.text isEqualToString:@""])
    return NO;
  else
    return YES;
}

-(void)textFieldDidBeginEditing:(UITextField *)textField {
  self.textFieldEditBeginning = FALSE;
  
  self.editedTextfield = textField;
  textField.placeholder = nil;
  textField.font = [kAppDelegate globalFontWithSize:20.0];
  
  // check if this is a potential new list
  UITableViewCell *theCell = [SHUtil tableViewCellForView: textField];
  if ([self.tableView indexPathForCell:theCell].row == self.lists.count) {
    [self.textFieldsForNewLists addObject:textField];
  } else {
    self.editedList = self.lists[[self.tableView indexPathForCell:theCell].row];
  }
  
  [self.navigationItem setRightBarButtonItem: nil animated: YES];
  [UIView animateWithDuration:0.2 animations:^{
    self.navigationItem.leftBarButtonItem.customView.alpha = 0.0;
  }];
  
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
  [textField resignFirstResponder];
  return YES;
}


-(void)textFieldDidEndEditing:(UITextField *)textField {
  if (!self.textFieldEditBeginning) {
    [self.navigationItem setRightBarButtonItem: self.editButtonItem animated: YES];
    [UIView animateWithDuration:0.2 animations:^{
      self.navigationItem.leftBarButtonItem.customView.alpha = 1.0;
    }];
  }
  
  BOOL potentialNewList = [self.textFieldsForNewLists containsObject:textField];
  if (potentialNewList) {
    [self.textFieldsForNewLists removeObject:textField];
  }
  
  if (textField.text && ![textField.text isEqualToString:@""]) {
    textField.placeholder = kPlaceholderText;
    self.editedTextfield = nil;
    if (potentialNewList) {
      // create a new list
      [self.listService createNewListWithName:textField.text];
      [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0]
                    withRowAnimation:UITableViewRowAnimationFade];
    } else {
      // modify name of current list
      if (self.editedList) {
        [self.editedList setObject:textField.text forKey:kListNameKey];
        [self.editedList setObject:[NSDate date] forKey:kModifiedDateKey];
      }
    }
    
    [self.listService saveLists];
    
  } else if ((!textField.text || [textField.text isEqualToString:@""]) &&
             !potentialNewList) {
    
    if ( !self.showingDeleteAlert ) {
      self.editedListName = [self.editedList objectForKey:kListNameKey];
      if (self.editedList) {
        [self.editedList setObject:@"" forKey:kListNameKey];
      }
      PSPDFAlertView *alert = [[PSPDFAlertView alloc] initWithTitle:nil message:@"Would you like to delete this list?"];
      [alert addButtonWithTitle:@"Yes" block:^(NSInteger buttonIndex) {
        [self.listService deleteList:self.editedList];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0]
                      withRowAnimation:UITableViewRowAnimationFade];
        
        self.showingDeleteAlert = NO;
        if (self.editedTextfield) {
          self.editedTextfield.placeholder = kPlaceholderText;
        }
        self.editedTextfield = nil;
        
        
      }];
      [alert addButtonWithTitle:@"No" block:^(NSInteger buttonIndex) {
        if (self.editedList) {
          [self.editedList setObject:self.editedListName forKey:kListNameKey];
        }
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0]
                      withRowAnimation:UITableViewRowAnimationFade];
        
        self.showingDeleteAlert = NO;
        if (self.editedTextfield) {
          self.editedTextfield.placeholder = kPlaceholderText;
        }
        self.editedTextfield = nil;
        
      }];
      [alert show];
      self.showingDeleteAlert = YES;
    }
  } else {
    // it's the new list cell
    self.editedTextfield = nil;
    textField.placeholder = kPlaceholderText;
    textField.font = [kAppDelegate globalFontWithSize:20.0];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0]
                  withRowAnimation:UITableViewRowAnimationFade];
  }
}

#pragma mark Notification handlers
-(void)handleAllListsReceived {
  [self.tableView.pullToRefreshView stopAnimating];
  
  if (!self.editedTextfield || ![self.editedTextfield isFirstResponder]) {
    [self.tableView reloadData];
  }
}

-(void)handleRecieveListsError {
  [self.tableView.pullToRefreshView stopAnimating];
  if ([self.navigationController.topViewController isEqual:self]) {
    [self.view bringSubviewToFront:self.alertContainer];
    [SHUtil showWarningInView:self.alertContainer
                        title:@"Network Error"
                      message:@"Unable to retrieve lists at this time.  Please try later."];
  }
}

-(void)handleListDeleteError {
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                 message:@"Unable to delete list at this time. Please try later."
                                                          preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                            style:UIAlertActionStyleCancel
                                          handler:nil]];
  [self presentViewController:alert
                     animated:YES
                   completion:nil];
  
  [self.tableView reloadData];
}

-(void)handleListsNetworkError {
  [self.tableView.pullToRefreshView stopAnimating];
  
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Network Error"
                                                                 message:@"Unable to update lists at this time."
                                                          preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                            style:UIAlertActionStyleCancel
                                          handler:nil]];
  [self presentViewController:alert
                     animated:YES
                   completion:nil];
    
}

- (void)keyboardWillShow:(NSNotification *)aNotification {
  NSDictionary *info = [aNotification userInfo];
  NSValue *aValue = [info objectForKey:UIKeyboardFrameEndUserInfoKey];
  CGSize keyboardSize = [aValue CGRectValue].size;
  NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] floatValue];
  
  [UIView animateWithDuration:duration
                        delay:0
                      options:UIViewAnimationOptionBeginFromCurrentState
                   animations:^{
                     self.tableView.contentInset = UIEdgeInsetsMake(self.tableView.contentInset.top,
                                                                    self.tableView.contentInset.left,
                                                                    self.tableView.contentInset.bottom + keyboardSize.height,
                                                                    self.tableView.contentInset.right);
                     self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
                   } completion:NULL];
  
}

- (void)keyboardWillHide:(NSNotification *)aNotification {
  
  NSDictionary *info = [aNotification userInfo];
  NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] floatValue];
  NSValue *aValue = [info objectForKey:UIKeyboardFrameEndUserInfoKey];
  CGSize keyboardSize = [aValue CGRectValue].size;
  
  [UIView animateWithDuration:duration
                        delay:0
                      options:UIViewAnimationOptionBeginFromCurrentState
                   animations:^{
                     self.tableView.contentInset = UIEdgeInsetsMake(self.tableView.contentInset.top,
                                                                    self.tableView.contentInset.left,
                                                                    self.tableView.contentInset.bottom - keyboardSize.height,
                                                                    self.tableView.contentInset.right);
                     self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
                   } completion:NULL];
  
}

@end
