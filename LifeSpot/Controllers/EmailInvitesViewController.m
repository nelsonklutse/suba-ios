//
//  EmailInvitesViewController.m
//  LifeSpot
//
//  Created by Kwame Nelson on 6/4/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import "EmailInvitesViewController.h"
#import "User.h"
#import <AddressBook/AddressBook.h>
#import "SMSContactsCell.h"


typedef enum{
    kEmail = 0
}InviteType;


@interface EmailInvitesViewController ()<UITableViewDataSource,UITableViewDelegate,UITextFieldDelegate,UIAlertViewDelegate>{
    
}

@property (copy,nonatomic) NSString *emaiFieldText;

@property (weak, nonatomic) IBOutlet UITextField *emailsTextField;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *sendInvitesButton;
@property (weak, nonatomic) IBOutlet UITableView *emailsFilterTableView;
@property (strong,nonatomic) NSMutableArray *emailContacts;
@property (strong,nonatomic) NSMutableArray *filteredContacts;
@property (strong,nonatomic) NSMutableArray *validatedEmailFormats;


- (IBAction)sendInvites:(UIBarButtonItem *)sender;
- (void)retrieveEmailContacts;
- (IBAction)dismissViewController:(id)sender;

@end

@implementation EmailInvitesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationController.navigationBar.topItem.title = @"";
    self.filteredContacts = [NSMutableArray arrayWithCapacity:[self.emailContacts count]];
    self.validatedEmailFormats = [NSMutableArray arrayWithCapacity:[self.emailContacts count]];
    self.emaiFieldText = kEMPTY_STRING_WITHOUT_SPACE;
    // Check whether we have access to the users contact list. If we don't show them a pre UI to give access to contacts
    //ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, NULL);
    
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined){
        
        UIAlertView *alert = [[UIAlertView alloc]
         initWithTitle:@"Access to Contacts"
         message:@"Giving Suba access to Contacts makes it easier to request photos from friends."
         delegate:self
         cancelButtonTitle:@"Not Now"
         otherButtonTitles:@"Use Contacts", nil];
        
        alert.tag = 1000;
         [alert show];
        
    }else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusDenied){
        
        [AppHelper showAlert:@"Contacts Access Denied"
                     message:@"To give Suba access to your Contacts later, please go to Settings -> Privacy -> Contacts and enable Contacts for Suba."
                     buttons:@[@"OK"] delegate:nil];
    }else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized){
        [self retrieveEmailContacts];
    }
    
}


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
}


-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.emailsTextField becomeFirstResponder];
    self.navigationController.navigationBar.topItem.title = @"";
}



#pragma mark - UITableView Datasource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.filteredContacts count];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 65.0f;
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"EmailInvitesCell";
    SMSContactsCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    cell.contactNameLabel.text = [NSString stringWithFormat:@"%@ %@",
                               self.filteredContacts[indexPath.row][@"firstName"],self.filteredContacts[indexPath.row][@"lastName"]];
    cell.phoneNumberLabel.text = self.filteredContacts[indexPath.row][@"email"];
    cell.contactImageView.image = self.filteredContacts[indexPath.row][@"image"];
    return cell;
}


#pragma mark - UITableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.emaiFieldText = kEMPTY_STRING_WITHOUT_SPACE;
   // Get the email of the contact selected
    NSString *email = self.filteredContacts[indexPath.row][@"email"];
    
    DLog(@"Email selected = %@",email);
    
    //NSString *emailFieldText = kEMPTY_STRING_WITHOUT_SPACE;
    if (![self.validatedEmailFormats containsObject:email]) {
        [self.validatedEmailFormats addObject:email];
    }
    
    
    DLog(@"Validated emails - %@",[self.validatedEmailFormats description]);
    
    for (NSString *validatedEmail in self.validatedEmailFormats){
        
    self.emaiFieldText = [self.emaiFieldText stringByAppendingString:
                              [NSString stringWithFormat:@"%@,",validatedEmail]];
        
    }
    
    DLog(@"New text in email field  = %@",self.emaiFieldText);
    self.emailsTextField.text = self.emaiFieldText;
}

-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *email = self.filteredContacts[indexPath.row][@"email"];
    [self.validatedEmailFormats removeObject:email];
    
    for (NSString *validatedEmail in self.validatedEmailFormats){
        
        self.emaiFieldText = [self.emaiFieldText stringByAppendingString:
                              [NSString stringWithFormat:@"%@,",validatedEmail]];
        
    }
    
    DLog(@"New text in email field  = %@",self.emaiFieldText);
    self.emailsTextField.text = self.emaiFieldText;

}

#pragma mark - UITextFieldDelegate
-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range
    replacementString:(NSString *)string{
    
    // Filter email contacts and reload the table View
    NSString *searchText = [[textField.text componentsSeparatedByString:@","] lastObject];
    
    [self filterContentForSearchText:searchText];
    
    NSArray *emails = [textField.text componentsSeparatedByString:@","];
    
    if ([emails count] == 1) {
        if ([AppHelper validateEmail:emails[0]]){
            if (![self.validatedEmailFormats containsObject:emails[0]]) {
            [self.validatedEmailFormats addObject:emails[0]];
          }
        }
    }else{
        
        NSInteger numberOfEmailInvites = 0;
        for (int x = 0; x < [emails count]; x++){
            if([AppHelper validateEmail:emails[x]]){
                ++numberOfEmailInvites;
                
                if (![self.validatedEmailFormats containsObject:emails[x]]) {
                    [self.validatedEmailFormats addObject:emails[x]];
             }
          }
        }
        
    }
    
    return YES;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}




- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

- (IBAction)sendInvites:(UIBarButtonItem *)sender
{
    @try {
        NSString *emailInvites = self.emailsTextField.text;
        
        DLog(@"Emails - %@\nStream ID: %@\nUserID: %@",emailInvites,self.streamId,[User currentlyActiveUser].userID);
        
        NSDictionary *params = @{@"userId" : [User currentlyActiveUser].userID,
                                 @"streamId" : self.streamId,
                                 @"emails":emailInvites};
        
        DLog(@"Params - %@",params);
        [[User currentlyActiveUser] inviteUsersToStreamViaEmail:params completion:^(id results, NSError *error) {
            DLog(@"results - %@",results);
            if (!error){
                if ([results[STATUS] isEqualToString:ALRIGHT]){
                    // Email invites sent
                    [self dismissViewControllerAnimated:YES completion:nil];
                }
            }
        }];

    }
    @catch (NSException *exception) {
        // What to do when there's an error
        [AppHelper showAlert:@"Invites Error" message:@"We encountered an error inviting your friends, Please try again" buttons:@[@"OK"] delegate:nil];
    }
    @finally {
        
    }
}



#pragma mark - UIAlertView Delegate
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 1000) {
        if (buttonIndex == 1) {
            [self retrieveEmailContacts];
        }
    }
}



#pragma mark - Manipulate contacts
- (void)retrieveEmailContacts{
    [self fetchPhoneContacts:kEmail completion:^(NSArray *contacts) {
        // We are sorting the contacts here
        if ([contacts count] > 0){
            
            NSSortDescriptor *firstNameDescriptor = [[NSSortDescriptor alloc] initWithKey:@"firstName" ascending:YES];
            NSArray *sortDescriptors = [NSArray arrayWithObject:firstNameDescriptor];
            NSArray *sortedContacts = [contacts sortedArrayUsingDescriptors:sortDescriptors];
            self.emailContacts = [NSMutableArray arrayWithArray:sortedContacts];
            
            DLog(@"Email contacts - %@",self.emailContacts);
            
            //[self updateNumberOfInvitesLabel:[self.messageRecipients count]];
            //[self.emailsFilterTableView reloadData];
            
        }
    } failure:^(NSError *error) {
        DLog(@"Error - %@",error);
    }];
}

- (IBAction)dismissViewController:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
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
        
        NSString *emailAddress = nil;
        ABMultiValueRef contactInfo =  nil;
        
        if (inviteChannel == kEmail) {
            contactInfo = ABRecordCopyValue(person,kABPersonEmailProperty);
        }else{
            contactInfo = ABRecordCopyValue(person, kABPersonPhoneProperty);
        }
        
        
        if (ABMultiValueGetCount(contactInfo) > 0) {
            
            emailAddress = (__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(contactInfo, 0);
            
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
                                            @"email" : emailAddress,
                                            @"image" : image};
            
            [contacts addObject:singleContact];
            
        } else {
            
            emailAddress = @"[None]";
            
        }
    }
    
    completion(contacts);
}


-(void)filterContentForSearchText:(NSString*)searchText{
    [self.filteredContacts removeAllObjects];
    
    // Filter the array using NSPredicate
     NSPredicate *predicate = [NSPredicate predicateWithFormat:@"firstName contains[c] %@ OR lastName contains[c] %@ OR email contains[c] %@",searchText,searchText,searchText];
    
    self.filteredContacts = [NSMutableArray arrayWithArray:[self.emailContacts filteredArrayUsingPredicate:predicate]];
    
    [self.emailsFilterTableView reloadData];
    DLog(@"Filtered contacts - %@",self.filteredContacts);
    
}






















@end
