//
//  SavedMessagesController.m
//  Shared
//
//  Created by Brian Bernberg on 8/20/13.
//  Copyright (c) 2013 BB Consulting. All rights reserved.
//

#import "SavedMessagesController.h"
#import "Constants.h"
#import "User.h"
#import "SavedMessagesService.h"
#import "NSString+SHString.h"

#define kLabelTag 100
#define kLabelPadding 6.f

@interface SavedMessagesController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UITextField *textField;
@property (nonatomic, weak) id<SavedMessagesDelegate> delegate;
@end

@implementation SavedMessagesController

- (id)initWithDelegate: (id<SavedMessagesDelegate>)delegate;
{
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    // Custom initialization
    self.delegate = delegate;
    self.title = @"Saved Messages";
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                          target:self
                                                                                          action:@selector(doneButtonPressed:)];
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.view.backgroundColor = [SHPalette backgroundColor];
  self.tableView.backgroundColor = [SHPalette backgroundColor];
}

-(void)setEditing:(BOOL)editing animated:(BOOL)animated {
  [super setEditing:editing animated:animated];
  
  [self.tableView setEditing:editing animated:animated];
}

#pragma mark cancel
-(void)doneButtonPressed:(id)sender {
  [self.delegate dismiss];
}

#pragma mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [[SavedMessagesService instance].messages count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *cellID = @"savedMessagesCell";
  UILabel *label = nil;
  UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellID];
  if (!cell) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                  reuseIdentifier:cellID];
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    cell.separatorInset = UIEdgeInsetsZero;
    
    label = [[UILabel alloc] initWithFrame:CGRectMake(10.f,
                                                      0.f,
                                                      cell.contentView.frame.size.width - 20.f,
                                                      cell.contentView.frame.size.height)];
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    label.tag = kLabelTag;
    label.textAlignment = NSTextAlignmentLeft;
    label.numberOfLines = 0;
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor blackColor];
    label.font = [UIFont systemFontOfSize:18.f];
    label.lineBreakMode = NSLineBreakByWordWrapping;
    [cell.contentView addSubview:label];
  }
  
  label = (UILabel *)[cell viewWithTag:kLabelTag];
  label.text = [SavedMessagesService instance].messages[indexPath.row][kSavedMessageMessageKey];
  
  return cell;
}

#pragma mark UITableViewDelegate
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  NSString *message = [SavedMessagesService instance].messages[indexPath.row][kSavedMessageMessageKey];
  return [self cellHeightForMessage:message];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
  NSString *message = [SavedMessagesService instance].messages[indexPath.row][kSavedMessageMessageKey];
  [self.delegate savedMessageSelected:message];
}

-(CGFloat)cellHeightForMessage:(NSString *)message {
  CGFloat height = [message heightForStringUsingWidth:300.f
                                              andFont:[UIFont boldSystemFontOfSize:18.f]];
  
  return MAX(height + kLabelPadding * 2.f, 48.f);
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
  return YES;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
  return YES;
}

-(UIView *)tableView:(UITableView *)theTableView viewForFooterInSection:(NSInteger)section {
  return [UIView new];
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
  if ([fromIndexPath compare:toIndexPath] != NSOrderedSame) {
    PFObject *message = [SavedMessagesService instance].messages[fromIndexPath.row];
    [[SavedMessagesService instance] moveSavedMessage:message toIndex:toIndexPath.row];
  }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    PFObject *message = [SavedMessagesService instance].messages[indexPath.row];
    [[SavedMessagesService instance] deleteSavedMessage:message];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
  }
}

#pragma mark UITextFieldDelegate
-(BOOL)textFieldShouldReturn:(UITextField *)textField {
  NSString *message = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  if ([message length] > 0) {
    [[SavedMessagesService instance] addSavedMessage: message];
    NSIndexPath *ip = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[ip] withRowAnimation:UITableViewRowAnimationAutomatic];
  }
  textField.text = @"";
  [textField resignFirstResponder];
  return YES;
}

@end

