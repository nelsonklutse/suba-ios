//
//  CleverInvitesViewController.m
//  LifeSpot
//
//  Created by Kwame Nelson on 4/29/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import "CleverInvitesViewController.h"
#import "SMSContactsCell.h"


@interface CleverInvitesViewController()<UITableViewDataSource,UITableViewDelegate,UISearchBarDelegate,
MFMailComposeViewControllerDelegate,MFMessageComposeViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UISearchBar *invitesSearchBar;
@property (strong,nonatomic) NSArray *phoneContacts;
@property (strong,nonatomic) NSMutableArray *contactsFilteredArray;
@property (strong,nonatomic) NSMutableArray *messageRecipients;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *toggleSelectAllContactsBarButton;
@property (weak, nonatomic) IBOutlet UITableView *cleverInvitesTableView;
@property (weak, nonatomic) IBOutlet UILabel *numberOfInvitesLabel;
@property (weak, nonatomic) IBOutlet UIButton *sendMessageButton;

- (IBAction)toggleSelectAll:(id)sender;
- (IBAction)dismissViewController:(id)sender;
- (void)loadPossibleInviteRecipients:(InviteType)inviteType;
- (void)showEmailContacts;
- (void)showPhoneContacts;
- (void)removeAllCheckMarks;
- (void)refillAllCheckMark;
- (void)sendSMSToRecipients:(NSMutableArray *)recipients;
//- (void)updateNumberOfInvitesLabel:(NSInteger)update;
//- (void)readjustmentSendButton;
- (IBAction)sendMessage:(id)sender;


@end

@implementation CleverInvitesViewController
static BOOL isFiltered = NO;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.messageRecipients = self.contactsFilteredArray = [NSMutableArray arrayWithCapacity:[self.phoneContacts count]];
    
    [self loadPossibleInviteRecipients:self.inviteType];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - UITableView Datasource
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;
    numberOfRows = (isFiltered) ? [self.contactsFilteredArray count]:[self.phoneContacts count];
    return numberOfRows;
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
   static NSString *cellIdentifier = @"CleverInviteCell";
    
    NSString *firstName = nil;
    NSString *lastName = nil;
    UIImage *contactImage = nil;
    NSString *phoneNumber = nil;
    SMSContactsCell *contactCell = (SMSContactsCell *)[self.cleverInvitesTableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (isFiltered) {
        firstName = [self.contactsFilteredArray[indexPath.row] objectForKey:@"firstName"];
        lastName =  [self.contactsFilteredArray[indexPath.row] objectForKey:@"lastName"];
        contactImage = self.contactsFilteredArray[indexPath.row][@"image"];
        phoneNumber = [self.contactsFilteredArray[indexPath.row] objectForKey:@"phoneNumber"];
    }else{
        firstName = [self.phoneContacts[indexPath.row] objectForKey:@"firstName"];
        lastName =  [self.phoneContacts[indexPath.row] objectForKey:@"lastName"];
        contactImage =  self.phoneContacts[indexPath.row][@"image"];
        phoneNumber = [self.phoneContacts[indexPath.row] objectForKey:@"phoneNumber"];
    }
    
    /*if ([self.messageRecipients containsObject:phoneNumber]) {
        contactCell.accessoryType = UITableViewCellAccessoryCheckmark;
    }else if(![self.messageRecipients containsObject:phoneNumber]){
        contactCell.accessoryType = UITableViewCellAccessoryNone;
    }*/
    
    contactCell.contactImageView.image = contactImage;
    contactCell.contactNameLabel.text = [NSString stringWithFormat:@"%@ %@",firstName,lastName];
    contactCell.phoneNumberLabel.text = phoneNumber;
    
    /*if(contactCell.accessoryType == UITableViewCellAccessoryCheckmark){
        
    }*/
    
    
    contactCell.accessoryType = contactCell.accessoryType;
    
    return contactCell;

}


#pragma mark - UITableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  // Inidicate the selected row with a checkmark
    // Add it to a recipient array
    SMSContactsCell *smsUserCell = (SMSContactsCell *)[self.cleverInvitesTableView cellForRowAtIndexPath:indexPath];
    smsUserCell.accessoryType = UITableViewCellAccessoryCheckmark;
    NSString *phoneNumber = nil;
    
    if (isFiltered) {
        
        phoneNumber = self.contactsFilteredArray[indexPath.row][@"phoneNumber"];
    }else{
        phoneNumber = self.phoneContacts[indexPath.row][@"phoneNumber"];
    }
    
    [self.messageRecipients addObject:phoneNumber];
}


-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Indicate the selected row with no checkmark
    // Remove the selected row
    
    SMSContactsCell *cell = (SMSContactsCell *)[tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryNone;
    [self.messageRecipients removeObject:cell.phoneNumberLabel.text];
    
    //[self updateNumberOfInvitesLabel:(-1)];
    
    if ([self.messageRecipients count] == 0) {
        [self readjustmentSendButton];
    }

}



#pragma mark - Helpers
-(void)refreshTableView:(UITableView *)tableView
{
    for (NSIndexPath *indexPath in [tableView indexPathsForRowsInRect:tableView.bounds]){
        UITableViewCell *cell = (UITableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
        cell.accessoryType = UITableViewCellAccessoryNone;
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
    
}

/*-(void)updateNumberOfInvitesLabel:(NSInteger)update
{
    NSString *updateLabelText = self.numberOfInvitesLabel.text;
    NSInteger number = [updateLabelText integerValue];
    
    number = number + update;
    DLog(@"Number of invites - %i",update);
    self.numberOfInvitesLabel.text = [NSString stringWithFormat:@"%i",number];
}*/

-(void)readjustmentSendButton
{
    CGRect originalFrame = CGRectMake(142, 12, 58, 24);
    if ([self.messageRecipients count] == 0) {
        [self.view viewWithTag:100].hidden = YES;
        self.numberOfInvitesLabel.hidden = YES;
        CGRect sendFrame = self.sendMessageButton.frame;
        sendFrame.origin.x = self.view.frame.size.width - (self.sendMessageButton.frame.size.width + 20);
        self.sendMessageButton.frame = sendFrame;
    }else{
        [self.view viewWithTag:100].hidden = NO;
        self.numberOfInvitesLabel.hidden = NO;
        self.sendMessageButton.frame = originalFrame;
    }
}


#pragma mark - Helper methods to read user's contacts
- (void)fetchPhoneContacts:(InviteType)inviteChannel completion:(void (^)(NSArray *contacts))success failure:(void (^)(NSError *error))failure {
    if (ABAddressBookRequestAccessWithCompletion) {
        
        CFErrorRef err;
        ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, &err);
        
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            // ABAddressBook doesn't gaurantee execution of this block on main thread, but we want our callbacks to be
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!granted) {
                    //failure((__bridge NSError *)error);
                    DLog(@"Access to contacts refused");
                    [AppHelper showAlert:@"Contacts Access Denied"
                                 message:@"We do not have access to your contacts. To allow us to access your contacts,please go to Settings->Privacy->Contacts"
                                 buttons:@[@"OK"] delegate:nil];
                } else {
                    
                    readAddressBookContacts(addressBook,inviteChannel, success);
                }
                CFRelease(addressBook);
            });
        });
    }
}


static void readAddressBookContacts(ABAddressBookRef addressBook, InviteType inviteChannel, void (^completion)(NSArray *contacts)) {
    CFArrayRef people =  ABAddressBookCopyArrayOfAllPeople(addressBook);
    CFMutableArrayRef peopleMutable = CFArrayCreateMutableCopy(
                                                               kCFAllocatorDefault,
                                                               CFArrayGetCount(people),
                                                               people
                                                               );
    long numberOfRecords = ABAddressBookGetPersonCount(addressBook);
    CFArraySortValues(
                      peopleMutable,
                      CFRangeMake(0, CFArrayGetCount(peopleMutable)),
                      (CFComparatorFunction) ABPersonComparePeopleByName,
                      (void *) ABPersonGetSortOrdering()
                    );
    
    
    NSMutableArray *contacts = [NSMutableArray arrayWithCapacity:numberOfRecords];
    
    for (int x = 0; x < numberOfRecords; x++){
        
        ABRecordRef person = CFArrayGetValueAtIndex(peopleMutable, x);
        NSString *firstName = (__bridge_transfer NSString*)ABRecordCopyValue(person,kABPersonFirstNameProperty);
        NSString *lastName = ( (__bridge_transfer NSString*)ABRecordCopyValue(person,kABPersonLastNameProperty) == nil) ? @"" : (__bridge_transfer NSString*)ABRecordCopyValue(person,kABPersonLastNameProperty) ;
        
        NSString *phone = nil;
        ABMultiValueRef contactInfo =  nil;
        
        if (inviteChannel == kEmail) {
            contactInfo = ABRecordCopyValue(person,kABPersonEmailProperty);
        }else{
          contactInfo = ABRecordCopyValue(person, kABPersonPhoneProperty);
        }
        
        
        if (ABMultiValueGetCount(contactInfo) > 0) {
            
            phone = (__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(contactInfo, 0);
            
            UIImage* image;
            
            if(ABPersonHasImageData(person)){
                image = [UIImage imageWithData:(__bridge NSData *)ABPersonCopyImageData(person)];
                // myima.image=image;
            }else{
                image = [UIImage imageNamed:@"anonymousUser"];
                // myima.image=image;
            }
            NSDictionary *singleContact = @{@"firstName": ( (firstName== nil) ? @"" : firstName ),
                                            @"lastName" : ( (lastName==nil) ? @"" :lastName ),
                                            @"phoneNumber" : phone,
                                            @"image" : image};
            [contacts addObject:singleContact];
            
        } else {
            
            phone = @"[None]";
            
        }
    }
    
    completion(contacts);
}




/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)toggleSelectAll:(id)sender
{
    if ([self.toggleSelectAllContactsBarButton.title isEqualToString:@"Deselect All"]) {
        self.toggleSelectAllContactsBarButton.title = @"Select All";
        [self removeAllCheckMarks];
        
    }else{
      self.toggleSelectAllContactsBarButton.title = @"Deselect All";
        [self refillAllCheckMark];
    }
    
}


-(void)removeAllCheckMarks
{
    for (NSIndexPath *indexPath in [self.cleverInvitesTableView indexPathsForRowsInRect:self.cleverInvitesTableView.bounds]){
        UITableViewCell *cell = (UITableViewCell *)[self.cleverInvitesTableView cellForRowAtIndexPath:indexPath];
        cell.accessoryType = UITableViewCellAccessoryNone;
        [self.cleverInvitesTableView deselectRowAtIndexPath:indexPath animated:NO];
    }
    
    //[self updateNumberOfInvitesLabel:-[self.messageRecipients count]];
    [self.messageRecipients removeAllObjects];
    
    //[self readjustmentSendButton];
    //[self performSelector:@selector(toggleSelectAll:) withObject:self.toggleSelectAllContactsBarButton];
    
}

-(void)refillAllCheckMark
{
    for (NSIndexPath *indexPath in [self.cleverInvitesTableView indexPathsForRowsInRect:self.cleverInvitesTableView.bounds]){
        UITableViewCell *cell = (UITableViewCell *)[self.cleverInvitesTableView cellForRowAtIndexPath:indexPath];
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        [self.cleverInvitesTableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
    
    for (NSDictionary *contact in self.phoneContacts) {
        [self.messageRecipients addObject:contact[@"phoneNumber"]];
    }
    
    //[self updateNumberOfInvitesLabel:[self.messageRecipients count]];
    //[self readjustmentSendButton];
    //[self performSelector:@selector(toggleSelectAll:) withObject:self.toggleSelectAllContactsBarButton];
    
}


- (IBAction)dismissViewController:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


-(void)loadPossibleInviteRecipients:(InviteType)inviteType
{
    if(self.inviteType == kEmail) {
        [self showEmailContacts];
    }else if (self.inviteType == kContacts){
        [self showPhoneContacts];
    }
    
    
}


- (void)showEmailContacts{
    [self fetchPhoneContacts:kEmail completion:^(NSArray *contacts) {
        // We are sorting the contacts here
        if ([contacts count] > 0){
            
            NSSortDescriptor *firstNameDescriptor = [[NSSortDescriptor alloc] initWithKey:@"firstName" ascending:YES];
            NSArray *sortDescriptors = [NSArray arrayWithObject:firstNameDescriptor];
            NSArray *sortedContacts = [contacts sortedArrayUsingDescriptors:sortDescriptors];
            self.phoneContacts = sortedContacts;
           
            //[self updateNumberOfInvitesLabel:[self.messageRecipients count]];
            [self.cleverInvitesTableView reloadData];
            
        }
    } failure:^(NSError *error) {
        DLog(@"Error - %@",error);
    }];
}

- (void)showPhoneContacts{
    //DLog(@"Phone property - %d",kABPersonPhoneProperty);
    [self fetchPhoneContacts:kContacts completion:^(NSArray *contacts) {
        // We are sorting the contacts here
        if ([contacts count] > 0){
            
            NSSortDescriptor *firstNameDescriptor = [[NSSortDescriptor alloc] initWithKey:@"firstName" ascending:YES];
            NSArray *sortDescriptors = [NSArray arrayWithObject:firstNameDescriptor];
            NSArray *sortedContacts = [contacts sortedArrayUsingDescriptors:sortDescriptors];
            self.phoneContacts = sortedContacts;
            
            /*for (NSDictionary *contact in self.phoneContacts) {
                [self.messageRecipients addObject:contact[@"phoneNumber"]];
            }*/
            
            //[self updateNumberOfInvitesLabel:[self.messageRecipients count]];
            [self.cleverInvitesTableView reloadData];
        }
        
    } failure:^(NSError *error) {
        DLog(@"Error - %@",error);
    }];
}


#pragma mark - MFMessageComposeViewControllerDelegate
-(void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    NSDictionary *params = @{@"invitedUserNumbers": self.messageRecipients,@"userName" : [AppHelper userName]};
    //DLog(@"invitedUserNumbers - %@",self.messageRecipients);
    [[SubaAPIClient sharedInstance] POST:@"/user/inviteduser" parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        DLog(@"Response - %@",responseObject);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        DLog(@"Response - %@",error);
    }];
    
    
    
    [self removeAllCheckMarks];
    [self.messageRecipients removeAllObjects];
    
    //if ([self.toggleSelectAllContactsBarButton.title isEqualToString:@"Deselect All"]) {
        self.toggleSelectAllContactsBarButton.title = @"Select All";
    //}
    
    switch (result)
    {
        case MessageComposeResultCancelled:
            //DLog(@"SMS sending failed");
            [FBAppEvents logEvent:@"SMS_Invite_Cancelled"];
            break;
        case MessageComposeResultSent:
            //DLog(@"SMS sent");
            [FBAppEvents logEvent:@"SMS_Invite_Sent"];
            break;
        case MessageComposeResultFailed:
            //DLog(@"SMS sending failed");
            [FBAppEvents logEvent:@"SMS_Invite_Failed"];
            break;
        default:
            DLog(@"SMS not sent");
            break;
    }
    
    [controller dismissViewControllerAnimated:YES completion:nil];
}


- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error
{
    [self removeAllCheckMarks];
    [self.messageRecipients removeAllObjects];
    self.toggleSelectAllContactsBarButton.title = @"Select All";
    switch (result)
    {
        case MFMailComposeResultCancelled:
            DLog(@"Mail send canceled...");
            [FBAppEvents logEvent:@"Email_Invite_Cancelled"];
            break;
        case MFMailComposeResultSaved:
            DLog(@"Mail saved...");
            [FBAppEvents logEvent:@"Email_Invite_Saved"];
            break;
        case MFMailComposeResultSent:
            DLog(@"Mail sent...");
            [FBAppEvents logEvent:@"Email_Invite_Sent"];
            break;
        case MFMailComposeResultFailed:
            DLog(@"Mail send error: %@...", [error localizedDescription]);
            [FBAppEvents logEvent:@"Email_Invite_Failed"];
            break;
        default:
        break;
    }
    
    [controller dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Send Messages
-(void)sendSMSToRecipients:(NSMutableArray *)recipients
{
    if ([MFMessageComposeViewController canSendText]){
        
        MFMessageComposeViewController *smsComposer = [[MFMessageComposeViewController alloc] init];
        
        smsComposer.messageComposeDelegate = self;
        smsComposer.recipients = recipients ;
        
        smsComposer.body = [NSString stringWithFormat:@"I’m using Suba app to collect everyone’s photos at events. Get it here: http://subaapp.com/download"];
        smsComposer.navigationBar.translucent = NO;
        
        [self presentViewController:smsComposer animated:NO completion:nil];
        //}];
        
        
    }else{
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Text Message Failure"
                              message:
                              @"Your device doesn't support in-app sms"
                              delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    
}

- (void)sendEmailToRecipients:(NSMutableArray *)recipients
{
    MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
    mc.mailComposeDelegate = self;
    
    [mc setSubject:@"This is the best app I know for creating photo memories"];
    
    [mc setToRecipients:self.messageRecipients];
    
    [mc setMessageBody:@"I've been using this awesome app to create and share photo memories\nDownload now @ http://bit.ly/suba_m so we can share one together" isHTML:NO];
    
    [self presentViewController:mc animated:YES completion:nil];
}


- (IBAction)sendMessage:(id)sender
{
    if (self.inviteType == kEmail) {
        // Send email to all selected contacts
        [self sendEmailToRecipients:self.messageRecipients];
    }else if (self.inviteType == kContacts){
        [self sendSMSToRecipients:self.messageRecipients];
    }
}

#pragma mark - UISearchBar Delegate
-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if (searchText.length == 0) {
        isFiltered = NO;
    }else{
        
        isFiltered = YES;
        [self filterContentForSearchText:searchText
                                   scope:[[self.invitesSearchBar scopeButtonTitles]
                                          objectAtIndex:[self.invitesSearchBar selectedScopeButtonIndex]]];
    }
}


-(BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    searchBar.showsCancelButton = YES;
    
    return YES;
}


-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    searchBar.showsCancelButton = NO;
    isFiltered = NO;
    
    [self.cleverInvitesTableView reloadData];
    [self removeAllCheckMarks];
    
}


-(void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
    // Update the filtered array based on the search text and scope.
    // Remove all objects from the filtered search array
    
    [self.contactsFilteredArray removeAllObjects];
    
    // Filter the array using NSPredicate
    
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"firstName contains[c] %@ OR lastName contains[c] %@",searchText,searchText];
        self.contactsFilteredArray = [NSMutableArray arrayWithArray:[self.phoneContacts filteredArrayUsingPredicate:predicate]];
        
        [self.cleverInvitesTableView reloadData];
        //DLog(@"Filtered contacts - %@",self.phoneContactsFilteredArray);
    
}



@end
