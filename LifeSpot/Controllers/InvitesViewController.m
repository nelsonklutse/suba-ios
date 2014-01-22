//
//  InvitesViewController.m
//  LifeSpot
//
//  Created by Kwame Nelson on 1/15/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import "InvitesViewController.h"
#import "SubaUsersInviteCell.h"
#import "FacebookUsersCell.h"
#import "SMSContactsCell.h"
#import "User.h"
#import "LSPushProviderAPIClient.h"
#import <AddressBook/AddressBook.h>
#import <MessageUI/MessageUI.h>
//#import ""

@interface InvitesViewController ()<UITableViewDataSource,UITableViewDelegate,MFMessageComposeViewControllerDelegate,UISearchBarDelegate,UISearchDisplayDelegate>

@property (strong,nonatomic) NSMutableArray *subaUsers;
@property (strong,nonatomic) NSMutableArray *invitedSubaUsers;
@property (strong,nonatomic) NSMutableArray *fbUsers;
@property (strong,nonatomic) NSArray *phoneContacts;
@property (retain,nonatomic) NSMutableArray *subaUsersFilteredArray;
@property (retain,nonatomic) NSMutableArray *fbUsersFilteredArray;
@property (retain,nonatomic) NSMutableArray *phoneContactsFilteredArray;
@property (strong,nonatomic) NSMutableArray *smsRecipients;
@property (strong,nonatomic) NSMutableArray *facebookRecipients;


@property (retain, nonatomic) IBOutlet UISearchBar *invitesSearchBar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *inviteBarButtonItem;
@property (weak, nonatomic) IBOutlet UITableView *subaUsersTableView;
@property (weak, nonatomic) IBOutlet UITableView *facebookFriendsTableView;
@property (weak, nonatomic) IBOutlet UITableView *contactsTableView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *inviteSegmentedControl;
//@property (weak, nonatomic) IBOutlet UITableView *fbConnectButton;
@property (weak, nonatomic) IBOutlet UIView *fbConnectView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *fbConnectIndicator;

- (IBAction)inviteSegmentSelected:(UISegmentedControl *)sender;
- (IBAction)inviteUsers:(id)sender;
- (IBAction)connectToFacebook:(id)sender;


- (void)displaySubaUsers;
- (void)sendSMSToRecipients:(NSMutableArray *)recipients;
-(void)showFbWebDialog:(NSDictionary *)params;
- (NSMutableArray *)filterFacebookFriends:(NSArray *)fbUsers;
- (void)loadFacebookFriends;
- (void)openFbSession;
- (void)refreshTableView:(UITableView *)tableView;

@end

@implementation InvitesViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    //self.fbConnectButton.hidden = YES;
    self.fbConnectView.hidden = YES;
    [self displaySubaUsers];
    
    self.smsRecipients = [NSMutableArray arrayWithCapacity:[self.phoneContacts count]];
    self.facebookRecipients = [NSMutableArray arrayWithCapacity:[self.fbUsers count]];
    
    self.invitedSubaUsers = [NSMutableArray array];
    
    self.subaUsersFilteredArray = [NSMutableArray arrayWithCapacity:[self.subaUsers count]];
    self.fbUsersFilteredArray = [NSMutableArray arrayWithCapacity:[self.fbUsers count]];
    self.phoneContactsFilteredArray = [NSMutableArray arrayWithCapacity:[self.phoneContacts count]];
    
    //self.invitesSearchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    //self.invitesSearchBar.showsCancelButton = YES;
    //self.invitesSearchBar.delegate = self;
    //self.subaUsersTableView.tableHeaderView = self.invitesSearchBar;
    
    self.searchDisplayController.searchResultsTableView.allowsMultipleSelection = YES;
}




- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)inviteUsers:(id)sender
{
    if (self.inviteSegmentedControl.selectedSegmentIndex == kFacebook){
        [self publishStory];
        
    }else if (self.inviteSegmentedControl.selectedSegmentIndex == kSuba){
        //NSString *requestURL = [NSString stringWithFormat:@"%@invitedtoalbum",PUSH_PROVIDER_BASE_URL];
        
        NSString *senderId = [AppHelper userID];
        NSDictionary *params = @{@"senderId": senderId,
                                 @"recipientIds" : [self.invitedSubaUsers description],
                                 @"spotOwner" : [AppHelper userName],
                                 @"spotId" : self.spotToInviteUserTo[@"spotId"],
                                 @"spotName" : self.spotToInviteUserTo[@"spotName"]};
        //NSLog(@"Params - %@",params);
        
        [[LSPushProviderAPIClient sharedInstance] POST:
         @"invitedtoalbum" parameters:params constructingBodyWithBlock:nil success:^(NSURLSessionDataTask *task, id responseObject) {
             
             //NSLog(@"Server response - %@",responseObject);
         } failure:^(NSURLSessionDataTask *task, NSError *error){
             //
             // NSLog(@"Request _ %@\nError - %@",[task.currentRequest debugDescription],error);
             
         }];
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    }else if(self.inviteSegmentedControl.selectedSegmentIndex == kPhoneContacts) {
               [self sendSMSToRecipients:self.smsRecipients];
        //}];
        
    }
    
   [self.invitesSearchBar resignFirstResponder];
 
}

- (IBAction)connectToFacebook:(id)sender
{
    [self openFbSession];
}


#pragma mark - Helpers

-(void)refreshTableView:(UITableView *)tableView
{
    for (NSIndexPath *indexPath in [tableView indexPathsForSelectedRows]) {
        //NSLog(@"IndexPath.row - %i",indexPath.row);
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
        NSArray *FBfriends = [result valueForKey:@"data"];
        NSSortDescriptor *firstNameDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
        NSArray *sortDescriptors = [NSArray arrayWithObject:firstNameDescriptor];
        NSArray *sortedFriends = [FBfriends sortedArrayUsingDescriptors:sortDescriptors];
        self.fbUsers = [NSMutableArray arrayWithArray:sortedFriends];
        
        [self.facebookFriendsTableView reloadData];
        //[self showLoadingUserView:NO];
        
    }];
 
}

-(void)displaySubaUsers
{
    
    //[self showLoadingUserView:YES];
    
   [User allUsers:^(id results, NSError *error) {
       //DLog(@"Suba Users - %@",results);
       if (!error) {
           NSArray *subaUsers = results;
           
           // Filter the users in ascending order
           NSSortDescriptor *firstNameDescriptor = [[NSSortDescriptor alloc] initWithKey:@"userName" ascending:YES];
           NSArray *sortDescriptors = [NSArray arrayWithObject:firstNameDescriptor];
           NSArray *sortedUsers = [subaUsers sortedArrayUsingDescriptors:sortDescriptors];
           
           self.subaUsers = [NSMutableArray arrayWithArray:sortedUsers];
           NSDictionary *userToRemove = nil;
           for (NSDictionary *user in self.subaUsers){
               if ([user[@"userName"] isEqualToString:[AppHelper userName]]) {
                   userToRemove = user;
               }
           }
           //[self showLoadingUserView:NO];
           [self.subaUsers removeObject:userToRemove];
           [self.subaUsersTableView reloadData];

       }else{
           DLog(@"Error - %@",error);
       }
   }];
    
}


- (IBAction)inviteSegmentSelected:(UISegmentedControl *)sender
{
    if (sender.selectedSegmentIndex == kSuba) {
        
        // Hide the other TableViews
        self.facebookFriendsTableView.alpha = 0;
        self.contactsTableView.alpha = 0;
        self.subaUsersTableView.alpha = 1;
        self.fbConnectView.hidden =YES;
        
    }else if (sender.selectedSegmentIndex == kFacebook){
        
        self.subaUsersTableView.alpha = 0;
        self.contactsTableView.alpha = 0;
        
        // Is Facebook Session Open
        if ([FBSession activeSession].state == FBSessionStateOpen) {
            
            //self.fbConnectButton.hidden = YES;
            self.fbConnectView.hidden = YES;
            self.facebookFriendsTableView.alpha = 1;
            
            if (!self.fbUsers) {
                [self loadFacebookFriends];
            }

        }else{
           self.facebookFriendsTableView.alpha = 0;
           //self.fbConnectButton.hidden = NO;
           self.fbConnectView.hidden = NO;
        }
        
        
    }else if(sender.selectedSegmentIndex == kPhoneContacts){
        
        self.fbConnectView.hidden = YES;
        self.facebookFriendsTableView.alpha = 0;
        self.subaUsersTableView.alpha = 0;
        self.contactsTableView.alpha = 1;
        
       
        
        [self fetchContacts:^(NSArray *contacts){
            
                // We are sorting the contacts here
                NSSortDescriptor *firstNameDescriptor = [[NSSortDescriptor alloc] initWithKey:@"firstName" ascending:YES];
                NSArray *sortDescriptors = [NSArray arrayWithObject:firstNameDescriptor];
                NSArray *sortedContacts = [contacts sortedArrayUsingDescriptors:sortDescriptors];
                self.phoneContacts = sortedContacts;
            
                [self.contactsTableView reloadData];
            } failure:^(NSError *error) {
                DLog(@"Error - %@",error);

            }];
        
        
    }
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
                    failure((__bridge NSError *)error);
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
   
        [self refreshTableView:self.contactsTableView];
        [self.smsRecipients removeAllObjects];
    
    switch (result)
    {
        case MessageComposeResultCancelled:
            DLog(@"SMS sending failed");
            break;
        case MessageComposeResultSent:
            DLog(@"SMS sent");
            break;
        case MessageComposeResultFailed:
            DLog(@"SMS sending failed");
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
            //NSLog(@"FbAppCall - %@\nFBShare results -%@",[call debugDescription],[results[@"completionGesture"] class]);
            
            if (error) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed share" message:@"We could not share your album to your facebook contacts" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK" , nil];
                [alert show];
            }else if ([results[@"completionGesture"] isEqualToString:@"cancel"]){
                //NSLog(@"Share didComplete");
                
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
                                          
        if (session.isOpen){
            DLog();
            //[self.fbConnectIndicator stopAnimating];
            self.fbConnectView.hidden =YES;
            self.facebookFriendsTableView.alpha = 1;

            DLog(@"About to load FB friends");

            if (![[AppHelper facebookID] isEqualToString:@"-1"]) {
                [self loadFacebookFriends];
            }
            
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



-(NSMutableArray *)filterFacebookFriends:(NSArray *)fbUsers
{
    NSMutableArray *filteredFriends = [[NSMutableArray alloc] initWithCapacity:[fbUsers count]];
    for (NSDictionary *friend in fbUsers) {
        NSString *fbFriendFullName = [friend objectForKey:@"name"];
        [filteredFriends addObject:@{@"fullName": fbFriendFullName}];
    }
    // NSLog(@"Filtered Facebook friends - %@",[filteredFriends description]);
    return filteredFriends;
}



#pragma mark - UITableView Datasource
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;
    
    if (self.inviteSegmentedControl.selectedSegmentIndex == kSuba) {
        
        numberOfRows = (tableView == self.searchDisplayController.searchResultsTableView) ? [self.subaUsersFilteredArray count]:[self.subaUsers count];
        
    }else if (self.inviteSegmentedControl.selectedSegmentIndex == kFacebook){
        numberOfRows = (tableView == self.searchDisplayController.searchResultsTableView) ? [self.fbUsersFilteredArray count]:[self.fbUsers count];
    }else{
        numberOfRows = (tableView == self.searchDisplayController.searchResultsTableView) ? [self.phoneContactsFilteredArray count]:[self.phoneContacts count];
    }
    
    return numberOfRows;
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = nil;
    
    
    if (self.inviteSegmentedControl.selectedSegmentIndex == kSuba) {
        NSString *userName = nil;
        NSString *photoURL = nil;
        cellIdentifier = @"SubaInvitesCell";
       
        SubaUsersInviteCell *subaUserCell = (SubaUsersInviteCell *)[self.subaUsersTableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (tableView == self.searchDisplayController.searchResultsTableView) {
            userName = [self.subaUsersFilteredArray[indexPath.row] objectForKey:@"userName"];
            photoURL = (NSString *)[self.subaUsersFilteredArray[indexPath.row] objectForKey:@"photo"];
        }else{
            userName = [self.subaUsers[indexPath.row] objectForKey:@"userName"];
            photoURL = (NSString *)[self.subaUsers[indexPath.row] objectForKey:@"photo"];
        }
        subaUserCell.userNameLabel.text = userName;
        
        if(![photoURL isKindOfClass:[NSNull class]]){
            [subaUserCell.subaUserImageView setImageWithURL:[NSURL URLWithString:photoURL]];
        }else subaUserCell.subaUserImageView.image = [UIImage imageNamed:@"anonymousUser"];

        
        return subaUserCell;
        
    }else if (self.inviteSegmentedControl.selectedSegmentIndex == kPhoneContacts) {
        cellIdentifier = @"PhoneContactCell";
        NSString *firstName = nil;
        NSString *lastName = nil;
        UIImage *contactImage = nil;
        NSString *phoneNumber = nil;
        SMSContactsCell *contactCell = (SMSContactsCell *)[self.contactsTableView dequeueReusableCellWithIdentifier:cellIdentifier];
        
        if (tableView == self.searchDisplayController.searchResultsTableView) {
            firstName = [self.phoneContactsFilteredArray[indexPath.row] objectForKey:@"firstName"];
            lastName =  [self.phoneContactsFilteredArray[indexPath.row] objectForKey:@"lastName"];
            contactImage = self.phoneContactsFilteredArray[indexPath.row][@"image"];
            phoneNumber = [self.phoneContactsFilteredArray[indexPath.row] objectForKey:@"phoneNumber"];
        }else{
            firstName = [self.phoneContacts[indexPath.row] objectForKey:@"firstName"];
            lastName =  [self.phoneContacts[indexPath.row] objectForKey:@"lastName"];
            contactImage =  self.phoneContacts[indexPath.row][@"image"];
            phoneNumber = [self.phoneContacts[indexPath.row] objectForKey:@"phoneNumber"];
        }
        
        contactCell.contactImageView.image = contactImage;
        contactCell.contactNameLabel.text = [NSString stringWithFormat:@"%@ %@",firstName,lastName];
        contactCell.phoneNumberLabel.text = phoneNumber;
        
        return contactCell;
    }else{
        cellIdentifier = @"FacebookUserCell";
        FacebookUsersCell *fbUserCell = (FacebookUsersCell *)[self.facebookFriendsTableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
        
        NSDictionary *friendInfo = nil;
        
        friendInfo = self.fbUsers[indexPath.row];
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
        self.searchDisplayController.searchResultsTableView.allowsMultipleSelection = NO;
    }
    return indexPath;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    self.inviteBarButtonItem.enabled = YES;
    
    if (self.inviteSegmentedControl.selectedSegmentIndex == kSuba) {
        SubaUsersInviteCell *subaUserCell = (SubaUsersInviteCell *)[self.subaUsersTableView cellForRowAtIndexPath:indexPath];
        subaUserCell.accessoryType = UITableViewCellAccessoryCheckmark;
        NSString *recipientSelectedId = nil;
        
        if (tableView == self.searchDisplayController.searchResultsTableView) {
            recipientSelectedId = [self.subaUsersFilteredArray[indexPath.row] objectForKey:@"id"];
        }else{
            recipientSelectedId = [self.subaUsers[indexPath.row] objectForKey:@"id"];
        }
        [self.invitedSubaUsers addObject:recipientSelectedId];
        
    }else if (self.inviteSegmentedControl.selectedSegmentIndex == kFacebook){
        
        FacebookUsersCell *fbUserCell = (FacebookUsersCell *)[self.facebookFriendsTableView cellForRowAtIndexPath:indexPath];
        fbUserCell.accessoryType = UITableViewCellAccessoryCheckmark;
        NSDictionary *friendInfo =  nil;
        if (tableView == self.searchDisplayController.searchResultsTableView) {
            friendInfo = self.fbUsersFilteredArray[indexPath.row];
        }else{
            friendInfo = self.fbUsers[indexPath.row];
        }
        [self.facebookRecipients addObject:friendInfo];
        //DLog(@"Facebook Recipients - %@",[[self.facebookRecipients[0] allKeys] debugDescription]);
    }
    else if(self.inviteSegmentedControl.selectedSegmentIndex == kPhoneContacts) {
        SMSContactsCell *smsUserCell = (SMSContactsCell *)[self.contactsTableView cellForRowAtIndexPath:indexPath];
        smsUserCell.accessoryType = UITableViewCellAccessoryCheckmark;
        
        NSString *phoneNumber = nil;
        if (tableView == self.searchDisplayController.searchResultsTableView) {
            phoneNumber = self.phoneContactsFilteredArray[indexPath.row][@"phoneNumber"];
        }else{
            phoneNumber = self.phoneContacts[indexPath.row][@"phoneNumber"];
        }
        [self.smsRecipients addObject:phoneNumber];
    }
}


-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    
    if (self.inviteSegmentedControl.selectedSegmentIndex == kSuba){
        SubaUsersInviteCell *cell = (SubaUsersInviteCell *)[tableView cellForRowAtIndexPath:indexPath];
        cell.accessoryType = UITableViewCellAccessoryNone;
        NSString *recipientSelectedId = [self.subaUsers[indexPath.row] objectForKey:@"id"];
        [self.invitedSubaUsers removeObject:recipientSelectedId];
        self.inviteBarButtonItem.enabled = ([self.invitedSubaUsers count] != 0);
    }
    else if (self.inviteSegmentedControl.selectedSegmentIndex == kPhoneContacts){
        SMSContactsCell *cell = (SMSContactsCell *)[tableView cellForRowAtIndexPath:indexPath];
        cell.accessoryType = UITableViewCellAccessoryNone;
        [self.smsRecipients removeObject:cell.phoneNumberLabel.text];
        self.inviteBarButtonItem.enabled = ([self.smsRecipients count] != 0);
    }else{
        FacebookUsersCell *fbUserCell = (FacebookUsersCell *)[tableView cellForRowAtIndexPath:indexPath];
        fbUserCell.accessoryType = UITableViewCellAccessoryNone;
        NSDictionary *personSelected = self.fbUsers[indexPath.row];
        [self.facebookRecipients removeObject:personSelected];
        self.inviteBarButtonItem.enabled = ([self.facebookRecipients count] != 0);
    }
}




#pragma mark Content Filtering
-(void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
    // Update the filtered array based on the search text and scope.
    // Remove all objects from the filtered search array
    [self.subaUsersFilteredArray removeAllObjects];
    [self.fbUsersFilteredArray removeAllObjects];
    [self.phoneContactsFilteredArray removeAllObjects];
    
    // Filter the array using NSPredicate
    if (self.inviteSegmentedControl.selectedSegmentIndex == kSuba) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"userName contains[c] %@",searchText];
        self.subaUsersFilteredArray = [NSMutableArray arrayWithArray:[self.subaUsers filteredArrayUsingPredicate:predicate]];
    }else if (self.inviteSegmentedControl.selectedSegmentIndex == kFacebook){
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"first_name contains[c] %@ OR last_name contains[c] %@ OR middle_name contains[c] %@",searchText,searchText,searchText];
        
        //NSMutableArray *filteredFriends = [self filterFacebookFriends:self.fbUsers];
        self.fbUsersFilteredArray = [NSMutableArray arrayWithArray:[self.fbUsers filteredArrayUsingPredicate:predicate]];
        DLog(@"FBUserFiltered array -%@\nPredicate - %@",[self.fbUsersFilteredArray description],[predicate debugDescription]); 
    }else{
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"firstName contains[c] %@ OR lastName contains[c] %@",searchText,searchText];
        self.phoneContactsFilteredArray = [NSMutableArray arrayWithArray:[self.phoneContacts filteredArrayUsingPredicate:predicate]];
        //DLog(@"Filtered contacts - %@",self.phoneContactsFilteredArray);
    }
    
}


#pragma mark - UISearchDisplayController Delegate Methods
-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString{
    // Tells the table data source to reload when text changes
    [self filterContentForSearchText:searchString scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
    
    // Return YES to cause the search result table view to be reloaded.
    //[self refreshInvitesTableView];
    return YES;
}


@end