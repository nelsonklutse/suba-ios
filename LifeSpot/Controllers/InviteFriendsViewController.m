//
//  InviteFriendsViewController.m
//  LifeSpot
//
//  Created by Kwame Nelson on 1/23/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import "InviteFriendsViewController.h"
#import "SMSContactsCell.h"
#import "FacebookUsersCell.h"
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import <MessageUI/MessageUI.h>


#define PhoneContactsKey @"PhoneContactsKey"
#define FacebookUsersKey @"FacebookUsersKey"
#define SelectedSegmentKey @"SelectedSegmentKey"

typedef enum{
    kContacts = 0,
    kFacebook
}InviteType;

@interface InviteFriendsViewController ()<UITableViewDataSource,UITableViewDelegate,MFMessageComposeViewControllerDelegate,UISearchBarDelegate,UISearchDisplayDelegate>

@property (weak, nonatomic) IBOutlet UISearchBar *invitesSearchBar;
@property (strong,nonatomic) NSArray *fbUsers;
@property (strong,nonatomic) NSMutableArray *facebookFriendsFilteredArray;
@property (strong,nonatomic) NSArray *phoneContacts;
@property (strong,nonatomic) NSMutableArray *contactsFilteredArray;
@property (strong,nonatomic) NSMutableArray *messageRecipients;
@property (strong,nonatomic) NSMutableArray *facebookRecipients;

@property (weak, nonatomic) IBOutlet UISegmentedControl *inviteContactsSegmentedControl;
@property (weak, nonatomic) IBOutlet UITableView *phoneContactsTableView;
@property (weak, nonatomic) IBOutlet UITableView *facebookFriendsTableView;
@property (weak, nonatomic) IBOutlet UIView *fbConnectView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *fbConnectIndicator;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *inviteBarButtonItem;
@property (weak, nonatomic) IBOutlet UIView *loadingDataView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingDataActivityIndicator;




- (void)sendSMSToRecipients:(NSMutableArray *)recipients;
-(void)showFbWebDialog:(NSDictionary *)params;
//- (NSMutableArray *)filterFacebookFriends:(NSArray *)fbUsers;
- (void)loadFacebookFriends;
- (void)openFbSession;
- (void)refreshTableView:(UITableView *)tableView;


- (void)fetchContacts:(void (^)(NSArray *contacts))success failure:(void (^)(NSError *error))failure;
static void readAddressBookContacts(ABAddressBookRef addressBook, void (^completion)(NSArray *contacts));
- (NSDictionary*)parseURLParams:(NSString *)query;
- (void)publishStory;


- (IBAction)inviteSegmentSelected:(UISegmentedControl *)sender;
- (IBAction)inviteUsers:(UIBarButtonItem *)sender;

- (IBAction)connectToFacebook:(UIButton *)sender;
@end

@implementation InviteFriendsViewController
static BOOL isFiltered = NO;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.inviteContactsSegmentedControl.selectedSegmentIndex = kContacts;
    
    self.facebookFriendsFilteredArray = [[NSMutableArray alloc] initWithCapacity:[self.fbUsers count]];
    self.contactsFilteredArray = [[NSMutableArray alloc] initWithCapacity:[self.phoneContacts count]];
    
    self.messageRecipients = [NSMutableArray arrayWithCapacity:[self.phoneContacts count]];
    self.facebookRecipients = [NSMutableArray arrayWithCapacity:[self.fbUsers count]];
    
    [self fetchContacts:^(NSArray *contacts) {
        // We are sorting the contacts here
        if ([contacts count] > 0) {
            NSSortDescriptor *firstNameDescriptor = [[NSSortDescriptor alloc] initWithKey:@"firstName" ascending:YES];
            NSArray *sortDescriptors = [NSArray arrayWithObject:firstNameDescriptor];
            NSArray *sortedContacts = [contacts sortedArrayUsingDescriptors:sortDescriptors];
            self.phoneContacts = sortedContacts;
            [self.phoneContactsTableView reloadData];
        }
        
    } failure:^(NSError *error) {
        DLog(@"Error - %@",error);
    }];
    
    
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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



- (void)loadFacebookFriends
{
    if (self.fbConnectView.hidden == NO) {
        self.fbConnectView.hidden = YES;
    }
    
    //[self showLoadingUserView:YES];
    NSString *fbID = [AppHelper facebookID];
    NSString *grapthPath = [NSString stringWithFormat:@"%@/friends",fbID];
    //NSLog(@"FBID - %@",fbID);
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObject:@"name,picture.type(large),first_name,last_name,middle_name" forKey:@"fields"];
    
    [FBRequestConnection startWithGraphPath:grapthPath parameters:parameters HTTPMethod:@"GET" completionHandler:^(FBRequestConnection *connection, id result, NSError *error){
        if (!error) {
            NSArray *FBfriends = [result valueForKey:@"data"];
            NSSortDescriptor *firstNameDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
            NSArray *sortDescriptors = [NSArray arrayWithObject:firstNameDescriptor];
            NSArray *sortedFriends = [FBfriends sortedArrayUsingDescriptors:sortDescriptors];
            self.fbUsers = [NSMutableArray arrayWithArray:sortedFriends];
            DLog(@"FB users - %@",self.fbUsers);
            [self.facebookFriendsTableView reloadData];
            
            [AppHelper showLoadingDataView:self.loadingDataView
                                 indicator:self.loadingDataActivityIndicator flag:NO];
        }else{
            DLog(@"Loading Facebook friends error %@",[error debugDescription]);
            [AppHelper showAlert:@"Facebook Error"
                         message:error.localizedDescription
                         buttons:@[@"OK"] delegate:nil];
        }
    }];
}



- (IBAction)inviteSegmentSelected:(UISegmentedControl *)sender {
    if (sender.selectedSegmentIndex == kFacebook){
       
        if (self.facebookFriendsTableView.alpha == 0){
            self.invitesSearchBar.showsCancelButton = NO;
            isFiltered = NO;
            [self.facebookFriendsTableView reloadData];
        }

        self.phoneContactsTableView.alpha = 0;
        
        // Is Facebook Session Open
        if ([FBSession activeSession].isOpen) {
            DLog(@"FBSession is Open with Token - %@\nAnd FBID - %@",[[FBSession activeSession].accessTokenData debugDescription],[AppHelper facebookID]);
            //self.fbConnectButton.hidden = YES;
            
            self.fbConnectView.hidden = YES;
            self.facebookFriendsTableView.alpha = 1;
            
            //if (!self.fbUsers) {
                [self loadFacebookFriends];
            //}
            
        }else{
            self.facebookFriendsTableView.alpha = 0;
            //self.fbConnectButton.hidden = NO;
            self.fbConnectView.hidden = NO;
        }
        
    }else if(sender.selectedSegmentIndex == kContacts){
        
        if (self.phoneContactsTableView.alpha == 0){
            self.invitesSearchBar.showsCancelButton = NO;
            isFiltered = NO;
            
            [self.phoneContactsTableView reloadData];
        }

        
        self.fbConnectView.hidden = YES;
        self.facebookFriendsTableView.alpha = 0;
        
        self.phoneContactsTableView.alpha = 1;
        
        
        
        [self fetchContacts:^(NSArray *contacts){
            if ([contacts count] > 0) {
                // We are sorting the contacts here
                NSSortDescriptor *firstNameDescriptor = [[NSSortDescriptor alloc] initWithKey:@"firstName" ascending:YES];
                NSArray *sortDescriptors = [NSArray arrayWithObject:firstNameDescriptor];
                NSArray *sortedContacts = [contacts sortedArrayUsingDescriptors:sortDescriptors];
                self.phoneContacts = sortedContacts;
                
                [self.phoneContactsTableView reloadData];
            }
            
        } failure:^(NSError *error) {
            DLog(@"Error - %@",error);
        }];
    }
}



- (IBAction)inviteUsers:(UIBarButtonItem *)sender
{
    isFiltered = NO;
    
    if (self.inviteContactsSegmentedControl.selectedSegmentIndex == kFacebook){
        [self publishStory];
        
    
    }else if(self.inviteContactsSegmentedControl.selectedSegmentIndex == kContacts) {
        [self sendSMSToRecipients:self.messageRecipients];
    }
    
    [self.invitesSearchBar resignFirstResponder];
}

- (IBAction)connectToFacebook:(UIButton *)sender
{
    [self openFbSession];
}




#pragma mark - Helper methods to read user's contacts
- (void)fetchContacts:(void (^)(NSArray *contacts))success failure:(void (^)(NSError *error))failure {
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
                    
                    readAddressBookContacts(addressBook, success);
                }
                CFRelease(addressBook);
            });
        });
    }
}


static void readAddressBookContacts(ABAddressBookRef addressBook, void (^completion)(NSArray *contacts)) {
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
    
    for (int x = 0; x < numberOfRecords; x++) {
        ABRecordRef person = CFArrayGetValueAtIndex(peopleMutable, x);
        NSString *firstName = (__bridge_transfer NSString*)ABRecordCopyValue(person,kABPersonFirstNameProperty);
        NSString *lastName = ( (__bridge_transfer NSString*)ABRecordCopyValue(person,kABPersonLastNameProperty) == nil) ? @"" : (__bridge_transfer NSString*)ABRecordCopyValue(person,kABPersonLastNameProperty) ;
        
        NSString* phone = nil;
        
        ABMultiValueRef phoneNumbers = ABRecordCopyValue(person,kABPersonPhoneProperty);
        
        if (ABMultiValueGetCount(phoneNumbers) > 0) {
            
            phone = (__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(phoneNumbers, 0);
            
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


#pragma mark - MFMessageComposeViewControllerDelegate
-(void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    NSDictionary *params = @{@"invitedUserNumbers": self.messageRecipients,@"userName" : [AppHelper userName]};
    DLog(@"invitedUserNumbers - %@",self.messageRecipients);
    [[SubaAPIClient sharedInstance] POST:@"/user/inviteduser" parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        DLog(@"Response - %@",responseObject);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        DLog(@"Response - %@",error);
    }];
    

    
    [self refreshTableView:self.phoneContactsTableView];
    [self.messageRecipients removeAllObjects];
    
    switch (result)
    {
        case MessageComposeResultCancelled:
            //DLog(@"SMS sending failed");
            [Flurry logEvent:@"SMS_Invite_Cancelled"];
            break;
        case MessageComposeResultSent:
            //DLog(@"SMS sent");
            [Flurry logEvent:@"SMS_Invite_Sent"];
            break;
        case MessageComposeResultFailed:
            //DLog(@"SMS sending failed");
            [Flurry logEvent:@"SMS_Invite_Failed"];
            break;
        default:
            DLog(@"SMS not sent");
            break;
    }
    
       [controller dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Send SMS
-(void)sendSMSToRecipients:(NSMutableArray *)recipients
{
    if ([MFMessageComposeViewController canSendText]){
        
        MFMessageComposeViewController *smsComposer = [[MFMessageComposeViewController alloc] init];
        
        smsComposer.messageComposeDelegate = self;
        smsComposer.recipients = recipients ;
        
        smsComposer.body = [NSString stringWithFormat:@"Hi.I've found this cool app we can use to share albums\nDownload @ http://subaapp.com"];
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


#pragma mark - Facebook Feed Dialog Methods
/**
 * A function for parsing URL parameters.
 */
- (NSDictionary*)parseURLParams:(NSString *)query {
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    for (NSString *pair in pairs) {
        NSArray *kv = [pair componentsSeparatedByString:@"="];
        NSString *val =
        [kv[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        params[kv[0]] = val;
    }
    return params;
}


- (void)publishStory{
    
    FBShareDialogParams *params = [[FBShareDialogParams alloc] init];
    params.link = [NSURL URLWithString:@"http://www.subaapp.com"];
    params.friends = self.facebookRecipients;
    params.name = @"Suba";
    params.picture = [NSURL URLWithString:@"https://s3.amazonaws.com/com.intruptiv.mypyx-photos/icons/Suba_1024x1024.jpg"];
    params.caption = @"Photo-storify your events today!";
    params.description = @"Get Suba today to create nice photo stories for your events.";
    BOOL canShare = [FBDialogs canPresentShareDialogWithParams:params];
    
    if (canShare) {
        [FBDialogs presentShareDialogWithParams:params clientState:nil handler:^(FBAppCall *call, NSDictionary *results, NSError *error) {
            if (!error) {
            [Flurry logEvent:@"Facebook_Share_Completed"];
        }else if (error) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed share" message:@"We could not share your album to your facebook contacts" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK" , nil];
                [alert show];
            }else if ([results[@"completionGesture"] isEqualToString:@"cancel"]){
                //NSLog(@"Share didComplete");
                [Flurry logEvent:@"Facebook_Share_Cancelled"];
                [self.facebookRecipients removeAllObjects];
            }
            [self refreshTableView:self.facebookFriendsTableView];
        }];
        
        
    }else{
        
        NSDictionary *friendInfo =  self.facebookRecipients[0];
        
        // Put together the dialog parameters
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       @"Suba", @"name",
                                       @"Photo-storify your events today", @"caption",
                                       @"Download Suba today to create nice photo stories for your events.", @"description",
                                       @"http://www.subaapp.com", @"link",
                                       @"https://s3.amazonaws.com/com.intruptiv.mypyx-photos/icons/Suba_1024x1024.jpg", @"source",
                                       [friendInfo valueForKey:@"id"], @"to", nil];
        
        // Invoke the Web Dialog
        [self showFbWebDialog:params];
    }
}


- (void)openFbSession{
    //[self refreshInvitesTableView];
    [self.fbConnectIndicator startAnimating];
    
    [FBSession openActiveSessionWithReadPermissions:@[@"basic_info",@"email"]
                                       allowLoginUI:YES
                                  completionHandler:^(FBSession *session, FBSessionState status, NSError *error){
                                      DLog(@"FBSession object - %@",[session debugDescription]);
                                      if (session.isOpen){
                                          [AppHelper setFacebookSession:@"YES"];
                                          //[self.fbConnectIndicator stopAnimating];
                                          self.fbConnectView.hidden =YES;
                                          self.facebookFriendsTableView.alpha = 1;
                                          
                                          [AppHelper showLoadingDataView:self.loadingDataView indicator:self.loadingDataActivityIndicator flag:YES];
                                          
                                         // if (![[AppHelper facebookID] isEqualToString:@"-1"]) {
                                           //   [self loadFacebookFriends];
                                          //}else{
                                              // Fetch FBUser Info
                                              [[FBRequest requestForMe] startWithCompletionHandler:
                                               ^(FBRequestConnection *connection,
                                                 NSDictionary<FBGraphUser> *user,
                                                 NSError *error){
                                                   if (!error){
                                                       if ([[AppHelper facebookID] isEqualToString:@"-1"]){ // Facebook ID is not set
                                                           [AppHelper setFacebookID:user.id]; // set the facebook id
                                                           [self loadFacebookFriends];
                                                       }
                                                       
                                                   }
                                               }];
                                       //   }

                                      }else{
                                          DLog(@"fbSession is not open");
                                      }
                                      [self.fbConnectIndicator stopAnimating];
                                      
                                  }];
    
}



-(void)showFbWebDialog:(NSDictionary *)params
{
    [FBWebDialogs presentFeedDialogModallyWithSession:nil
                                           parameters:params
                                              handler:
     ^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
         if (error) {
             // Error launching the dialog or publishing a story.
             //NSLog(@"Error publishing story.");
         } else {
             
             if (result == FBWebDialogResultDialogNotCompleted) {
                 // User clicked the "x" icon
                 //NSLog(@"User canceled story publishing.");
             } else {
                 // Handle the publish feed callback
                 NSDictionary *urlParams = [self parseURLParams:[resultURL query]];
                 if (![urlParams valueForKey:@"post_id"]) {
                     // User clicked the Cancel button
                     //NSLog(@"User canceled story publishing.");
                 } else {
                     // User clicked the Share button
                     NSString *msg = [NSString stringWithFormat:
                                      @"Posted story, id: %@",
                                      [urlParams valueForKey:@"post_id"]];
                     //NSLog(@"%@", msg);
                     // Show the result in an alert
                     [[[UIAlertView alloc] initWithTitle:@"Result"
                                                 message:msg
                                                delegate:nil
                                       cancelButtonTitle:@"OK!"
                                       otherButtonTitles:nil]
                      show];
                 }
             }
         }
         
         
     }];
}


#pragma mark - UITableView Datasource
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;
    
   if (self.inviteContactsSegmentedControl.selectedSegmentIndex == kFacebook){
        numberOfRows = (isFiltered) ? [self.facebookFriendsFilteredArray count]:[self.fbUsers count];
    }else{
        numberOfRows = (isFiltered) ? [self.contactsFilteredArray count]:[self.phoneContacts count];
    }
    
    return numberOfRows;
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = nil;
    
    
    if (self.inviteContactsSegmentedControl.selectedSegmentIndex == kContacts) {
        cellIdentifier = @"PhoneContactsCell";
        NSString *firstName = nil;
        NSString *lastName = nil;
        UIImage *contactImage = nil;
        NSString *phoneNumber = nil;
        SMSContactsCell *contactCell = (SMSContactsCell *)[self.phoneContactsTableView dequeueReusableCellWithIdentifier:cellIdentifier];
        
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
        
        if ([self.messageRecipients containsObject:phoneNumber]) {
            DLog(@"Contains object at row - %i",indexPath.row);
            contactCell.accessoryType = UITableViewCellAccessoryCheckmark;
        }else if(![self.messageRecipients containsObject:phoneNumber]){
            contactCell.accessoryType = UITableViewCellAccessoryNone;
        }
        
        contactCell.contactImageView.image = contactImage;
        contactCell.contactNameLabel.text = [NSString stringWithFormat:@"%@ %@",firstName,lastName];
        contactCell.phoneNumberLabel.text = phoneNumber;
        
        return contactCell;
    }else{
        cellIdentifier = @"FacebookInviteFriendCell";
        FacebookUsersCell *fbUserCell = (FacebookUsersCell *)[self.facebookFriendsTableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
        
        NSDictionary *friendInfo = nil;
        
        if (isFiltered) {
            friendInfo = self.facebookFriendsFilteredArray[indexPath.row];
        }else{
            friendInfo = self.fbUsers[indexPath.row];
        }
        
        if ([self.facebookRecipients containsObject:friendInfo]) {
            DLog(@"Contains object at row - %i",indexPath.row);
            fbUserCell.accessoryType = UITableViewCellAccessoryCheckmark;
        }else if(![self.facebookRecipients containsObject:friendInfo]){
            fbUserCell.accessoryType = UITableViewCellAccessoryNone;
        }
        
        NSString *friendPicURL = [[[friendInfo
                                    valueForKey:@"picture"]
                                   valueForKey:@"data"] valueForKey:@"url"];
        
        fbUserCell.fbfbFrienduserName.text = friendInfo[@"name"];
        [fbUserCell.fbFriendImageView setImageWithURL:[NSURL URLWithString:friendPicURL]];
        
        
        return fbUserCell;
    }
    
    return nil;
}


#pragma mark - UITableViewDelegate
-(NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Lets check whether person can share with the native Facebook share dialog
    FBShareDialogParams *params = [[FBShareDialogParams alloc] init];
    params.link = [NSURL URLWithString:@"http://www.subaapp.com"];
    params.friends = self.facebookRecipients;
    params.name = @"Suba";
    params.caption = @"Photo-storify your events today!";
    params.description = @"Get Suba today to create nice photo stories for your events.";
    BOOL canShare = [FBDialogs canPresentShareDialogWithParams:params];
    
    if (!canShare) {
        DLog(@"Facebook App not installed");
        self.facebookFriendsTableView.allowsMultipleSelection = NO;
        //self.searchDisplayController.searchResultsTableView.allowsMultipleSelection = NO;
    }
    return indexPath;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    self.inviteBarButtonItem.enabled = YES;
    
   if (self.inviteContactsSegmentedControl.selectedSegmentIndex == kFacebook){
        
        FacebookUsersCell *fbUserCell = (FacebookUsersCell *)[self.facebookFriendsTableView cellForRowAtIndexPath:indexPath];
        fbUserCell.accessoryType = UITableViewCellAccessoryCheckmark;
        NSDictionary *friendInfo =  nil;
        if (isFiltered) {
            friendInfo = self.facebookFriendsFilteredArray[indexPath.row];
            
        }else{
            friendInfo = self.fbUsers[indexPath.row];
        }
        [self.facebookRecipients addObject:friendInfo];
        //DLog(@"Facebook Recipients - %@",[[self.facebookRecipients[0] allKeys] debugDescription]);
    }
    else if(self.inviteContactsSegmentedControl.selectedSegmentIndex == kContacts) {
        SMSContactsCell *smsUserCell = (SMSContactsCell *)[self.phoneContactsTableView cellForRowAtIndexPath:indexPath];
        smsUserCell.accessoryType = UITableViewCellAccessoryCheckmark;
        
        NSString *phoneNumber = nil;
        if (isFiltered) {
            
            phoneNumber = self.contactsFilteredArray[indexPath.row][@"phoneNumber"];
        }else{
            phoneNumber = self.phoneContacts[indexPath.row][@"phoneNumber"];
        }
        
        [self.messageRecipients addObject:phoneNumber];
    }
}


-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    
    if (self.inviteContactsSegmentedControl.selectedSegmentIndex == kContacts){
        SMSContactsCell *cell = (SMSContactsCell *)[tableView cellForRowAtIndexPath:indexPath];
        cell.accessoryType = UITableViewCellAccessoryNone;
        [self.messageRecipients removeObject:cell.phoneNumberLabel.text];
        self.inviteBarButtonItem.enabled = ([self.messageRecipients count] != 0);
    }else{
        FacebookUsersCell *fbUserCell = (FacebookUsersCell *)[tableView cellForRowAtIndexPath:indexPath];
        fbUserCell.accessoryType = UITableViewCellAccessoryNone;
        NSDictionary *personSelected = self.fbUsers[indexPath.row];
        [self.facebookRecipients removeObject:personSelected];
        self.inviteBarButtonItem.enabled = ([self.facebookRecipients count] != 0);
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
    
    if (self.inviteContactsSegmentedControl.selectedSegmentIndex == kFacebook) {
        [self.facebookFriendsTableView reloadData];
        [self refreshTableView:self.facebookFriendsTableView];
    }else{
        [self.phoneContactsTableView reloadData];
        [self refreshTableView:self.phoneContactsTableView];
    }
    
}


-(void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
    // Update the filtered array based on the search text and scope.
    // Remove all objects from the filtered search array
    
    [self.facebookFriendsFilteredArray removeAllObjects];
    [self.contactsFilteredArray removeAllObjects];
    
    // Filter the array using NSPredicate
    if (self.inviteContactsSegmentedControl.selectedSegmentIndex == kFacebook){
        
       NSPredicate *predicate = [NSPredicate predicateWithFormat:@"first_name contains[c] %@ OR last_name contains[c] %@ OR middle_name contains[c] %@",searchText,searchText,searchText];
        
        //NSMutableArray *filteredFriends = [self filterFacebookFriends:self.fbUsers];
        self.facebookFriendsFilteredArray = [NSMutableArray arrayWithArray:[self.fbUsers filteredArrayUsingPredicate:predicate]];
        //DLog(@"FBUserFiltered array -%@\nPredicate - %@",[self.facebookFriendsFilteredArray  description],[predicate debugDescription]);
        [self.facebookFriendsTableView reloadData];
    }else{
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"firstName contains[c] %@ OR lastName contains[c] %@",searchText,searchText];
        self.contactsFilteredArray = [NSMutableArray arrayWithArray:[self.phoneContacts filteredArrayUsingPredicate:predicate]];
        
        [self.phoneContactsTableView reloadData];
        //DLog(@"Filtered contacts - %@",self.phoneContactsFilteredArray);
    }
}


#pragma mark - State Preservation and Restoration
-(void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeObject:self.phoneContacts forKey:PhoneContactsKey];
    [coder encodeObject:self.fbUsers forKey:FacebookUsersKey];
    
}


-(void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super decodeRestorableStateWithCoder:coder];
    
    self.phoneContacts = [coder decodeObjectForKey:PhoneContactsKey];
    self.fbUsers = [coder decodeObjectForKey:FacebookUsersKey];
}

-(void)applicationFinishedRestoringState
{
    if (self.inviteContactsSegmentedControl.selectedSegmentIndex == kContacts) {
        [self fetchContacts:^(NSArray *contacts) {
            if ([contacts count] > 0) {
                // We are sorting the contacts here
                NSSortDescriptor *firstNameDescriptor = [[NSSortDescriptor alloc] initWithKey:@"firstName" ascending:YES];
                NSArray *sortDescriptors = [NSArray arrayWithObject:firstNameDescriptor];
                NSArray *sortedContacts = [contacts sortedArrayUsingDescriptors:sortDescriptors];
                self.phoneContacts = sortedContacts;
                [self.phoneContactsTableView reloadData];
            }
           
        } failure:^(NSError *error) {
            DLog(@"Error - %@",error);
        }];

    }else{
        [self loadFacebookFriends];
    }
}




/*
 #pragma mark Content Filtering
-(void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
    // Update the filtered array based on the search text and scope.
    // Remove all objects from the filtered search array
    
    [self.facebookFriendsFilteredArray removeAllObjects];
    [self.contactsFilteredArray removeAllObjects];
    
    // Filter the array using NSPredicate
     if (self.inviteContactsSegmentedControl.selectedSegmentIndex == kFacebook){
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"first_name contains[c] %@ OR last_name contains[c] %@ OR middle_name contains[c] %@",searchText,searchText,searchText];
        
        //NSMutableArray *filteredFriends = [self filterFacebookFriends:self.fbUsers];
        self.facebookFriendsFilteredArray = [NSMutableArray arrayWithArray:[self.fbUsers filteredArrayUsingPredicate:predicate]];
        DLog(@"FBUserFiltered array -%@\nPredicate - %@",[self.facebookFriendsFilteredArray  description],[predicate debugDescription]);
    }else{
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"firstName contains[c] %@ OR lastName contains[c] %@",searchText,searchText];
        self.contactsFilteredArray = [NSMutableArray arrayWithArray:[self.phoneContacts filteredArrayUsingPredicate:predicate]];
        //DLog(@"Filtered contacts - %@",self.phoneContactsFilteredArray);
    }
    
}


#pragma mark - UISearchDisplayController Delegate Methods
-(void)searchDisplayControllerDidBeginSearch:(UISearchDisplayController *)controller
{
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    
     [self setCorrectFrames];
}




-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString{
    // Tells the table data source to reload when text changes
    [self filterContentForSearchText:searchString scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
    
    // Return YES to cause the search result table view to be reloaded.
    //[self refreshInvitesTableView];
    return YES;
}


-(void)setCorrectFrames
{
    // Here we set the frame to avoid overlay
    CGRect searchDisplayerFrame = self.searchDisplayController.searchResultsTableView.superview.frame;
    searchDisplayerFrame.origin.y = CGRectGetMaxY(self.searchDisplayController.searchBar.frame);
    searchDisplayerFrame.size.height -= searchDisplayerFrame.origin.y;
    self.searchDisplayController.searchResultsTableView.superview.frame = searchDisplayerFrame;
}*/

@end
