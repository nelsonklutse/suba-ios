//
//  PhotoBrowserViewController.m
//  Suba
//
//  Created by Kwame Nelson on 2/12/15.
//  Copyright (c) 2015 Intruptiv. All rights reserved.
//

#import "PhotoBrowserViewController.h"
#import "TagCell.h"
#import "Spot.h"
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import <MessageUI/MessageUI.h>


@interface PhotoBrowserViewController ()<UIScrollViewDelegate,UITableViewDataSource,UITableViewDelegate,UITextFieldDelegate>
{
    
    NSInteger selectedRow;
    CGRect frameOfTagViewBeforeKeyboardShows;
    NSMutableArray *friendsOnSuba;
}


@property (weak, nonatomic) IBOutlet UIView *backgroundBlurView;

@property (weak, nonatomic) IBOutlet UITextField *friendNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *friendEmailTextField;
@property (weak, nonatomic) IBOutlet UITextField *searchFriendNameTextField;

@property (weak, nonatomic) IBOutlet UIView *tagWithEmailView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *contactsActivityIndicator;
@property (weak, nonatomic) IBOutlet UITableView *tagTableView;
@property (weak, nonatomic) IBOutlet UIView *tagView;
@property (weak, nonatomic) IBOutlet UIButton *tagFriendsInContactsButton;
@property (weak, nonatomic) IBOutlet UIButton *tagWithEmailButton;
@property (weak, nonatomic) IBOutlet UIImageView *tagImage;
@property (weak, nonatomic) IBOutlet UIButton *tagActionBtn;
- (IBAction)tagUserInPhoto:(UIButton *)sender;

@property (strong,nonatomic) NSMutableArray *taggableFriends;
@property (strong,nonatomic) NSArray *phoneContacts;



- (IBAction)dismissTagWithEmailView:(UIButton *)sender;
- (IBAction)findFriendsInContacts:(UIButton *)sender;
- (IBAction)tagWithEmailAction:(UIButton *)sender;
- (IBAction)handleTapToShowTagView:(UITapGestureRecognizer *)tap;

- (void)keyboardShouldShow:(NSNotification *)notification;
- (void)keyboardShouldHide:(NSNotification *)notification;
@end

@implementation PhotoBrowserViewController
int toggler = 0;

- (void)viewDidLoad {
    
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    selectedRow = 10000;
    self.backgroundBlurView.alpha = 0;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardShouldShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardShouldHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];

}


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    selectedRow = 10000;
    self.tagView.alpha = 0;
    
    if (self.streamId){
        [self loadAlbumMembers:self.streamId];
    }
    
    self.tagWithEmailView.frame = CGRectMake(self.tagView.frame.origin.x,0,
                                             self.tagView.frame.size.width,0);
    
    self.tagWithEmailView.alpha = 0;
    
    DLog(@"Image to tag: %@",self.imageURL);
    
    [self.tagImage setImageWithURL:[NSURL URLWithString:self.imageURL]];
    
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    toggler = 0;
}



- (void)didReceiveMemoryWarning{
    
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)dismissViewController:(id)sender {
    [self dismissViewControllerAnimated:NO completion:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


- (IBAction)findFriendsInContacts:(UIButton *)sender
{
    //DLog("Tag table view: %@",NSStringFromCGRect(self.tagTableView.frame));
    
    if ([sender.titleLabel.text isEqualToString:@"Find in Contacts"]) {
        [self showEmailContacts];
    }else{
        [self.tagFriendsInContactsButton setTitle:@"Find in Contacts" forState:UIControlStateNormal];
        self.taggableFriends = friendsOnSuba;
        
        [self.tagTableView reloadData];
    }
}


- (IBAction)tagWithEmailAction:(UIButton *)sender
{
    DLog("Tag with email");
    
    // Hide the tag view and show 'tag with email" view
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        CGRect tagFrame = self.tagView.frame;
        
        //[self shrinkTagViewHeight];
        
        //self.tagView.alpha = 0;
        self.tagWithEmailView.frame = CGRectMake(0,0,self.tagView.frame.size.width,0);
        
        self.tagWithEmailView.frame = CGRectMake(0, 0,
                                                 tagFrame.size.width, tagFrame.size.height);
        
        self.tagWithEmailView.alpha = 1;
    } completion:^(BOOL finished) {
        //[self resetTagViewFrame];
        [self.friendNameTextField becomeFirstResponder];
    }];

}


-(void)dismissTagWithEmailView:(UIButton *)sender
{
    [self.friendNameTextField resignFirstResponder];
    [self.friendEmailTextField resignFirstResponder];
    [self.searchFriendNameTextField resignFirstResponder];
    
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.tagView.alpha = 0;
        self.tagWithEmailView.alpha = 0;
        [self shrinkTagViewHeight];
    } completion:^(BOOL finished) {
        [self resetTagViewFrame];
        toggler += 1;
    }];
}


- (IBAction)handleTapToShowTagView:(UITapGestureRecognizer *)tap
{
    DLog(@"Tag view frame: %@",NSStringFromCGRect(self.tagView.frame));
    
    if (toggler % 2 == 0) {
        
        CGPoint tagLocation = [tap locationInView:self.tagImage];
        self.tagView.frame = [self updateTagViewFrame:tagLocation];
        self.tagWithEmailView.alpha = 0;
        DLog(@"tap location x - %f\ntap location y - %f",tagLocation.x,tagLocation.y);
        
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            [self shrinkTagViewHeight];
            self.tagView.alpha = 1;
            [self inflateTagViewHeight];
        } completion:^(BOOL finished) {
            [self.searchFriendNameTextField becomeFirstResponder];
        }];
    }else{
        
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.tagView.alpha = 0;
            self.tagWithEmailView.alpha = 0;
            [self shrinkTagViewHeight];
        } completion:^(BOOL finished) {
            [self resetTagViewFrame];
            [self.friendNameTextField resignFirstResponder];
            [self.friendEmailTextField resignFirstResponder];
            [self.searchFriendNameTextField resignFirstResponder];

        }];
    }
    
    toggler += 1;
}



#pragma mark - UITableView Datasource Methods
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    DLog(@"Taggable friends: %lu",(unsigned long)[self.taggableFriends count]);
    return [self.taggableFriends count];
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"TagCell";
    
    TagCell *tagCell = [self.tagTableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    NSString *imageURL = nil;
    
    if (self.taggableFriends[indexPath.row][@"photoURL"] != nil){
        
        if ([self.taggableFriends[indexPath.row][@"source"] isEqualToString:@"device"]) {
            
            if ([self.taggableFriends[indexPath.row][@"imageExists"] isEqualToString:@"YES"]) {
                UIImage *userImage = (UIImage *)self.taggableFriends[indexPath.row][@"photoURL"];
                [tagCell fillView:tagCell.friendImageView WithImage:userImage];
                
            }else{
                if (((NSString *)self.taggableFriends[indexPath.item][@"firstName"]).length > 0 &&
                    ((NSString *)self.taggableFriends[indexPath.item][@"lastName"]).length > 0){
                    
                    NSString *firstName = self.taggableFriends[indexPath.item][@"firstName"];
                    NSString *lastName = self.taggableFriends[indexPath.item][@"lastName"];
                    NSString *personString = [NSString stringWithFormat:@"%@ %@",firstName,lastName];
                    
                    tagCell.friendName.text = personString;
                    
                    NSString *userName = self.taggableFriends[indexPath.row][@"userName"];
                    tagCell.friendUserName.text = userName;
                    
                    [tagCell makeInitialPlaceholderView:tagCell.friendImageView name:personString];
                    
                }else if(((NSString *)self.taggableFriends[indexPath.item][@"firstName"]).length > 0 &&
                         ((NSString *)self.taggableFriends[indexPath.item][@"lastName"]).length == 0){
                    
                    NSString *firstName = self.taggableFriends[indexPath.item][@"firstName"];
                    tagCell.friendName.text = firstName;
                    
                    NSString *userName = self.taggableFriends[indexPath.row][@"userName"];
                    tagCell.friendUserName.text = userName;
                    
                    [tagCell makeInitialPlaceholderView:tagCell.friendImageView name:firstName];
                    
                }else if(((NSString *)self.taggableFriends[indexPath.item][@"firstName"]).length == 0 &&
                         ((NSString *)self.taggableFriends[indexPath.item][@"lastName"]).length > 0){
                    
                    NSString *lastName = self.taggableFriends[indexPath.item][@"firstName"];
                    tagCell.friendName.text = lastName;
                    
                    NSString *userName = self.taggableFriends[indexPath.row][@"userName"];
                    tagCell.friendUserName.text = userName;
                    
                    [tagCell makeInitialPlaceholderView:tagCell.friendImageView name:lastName];
                    
                }else{
                    NSString *userName = self.taggableFriends[indexPath.row][@"userName"];
                    tagCell.friendUserName.text = userName;
                    
                    [tagCell makeInitialPlaceholderView:tagCell.friendImageView name:userName];
                }

            }
            
            
        }else{
            imageURL = self.taggableFriends[indexPath.row][@"photoURL"];
            
            [tagCell fillView:tagCell.friendImageView WithImageURL:imageURL
                  placeholder:[UIImage imageNamed:@"anonymousUser"]];
            
            //[tagCell.friendImage setImageWithURL:[NSURL URLWithString:imageURL]];
        }
        
    }else{
        
        if (self.taggableFriends[indexPath.item][@"firstName"] && self.taggableFriends[indexPath.item][@"lastName"]){
            
            NSString *firstName = self.taggableFriends[indexPath.item][@"firstName"];
            NSString *lastName = self.taggableFriends[indexPath.item][@"lastName"];
            NSString *personString = [NSString stringWithFormat:@"%@ %@",firstName,lastName];
            
            tagCell.friendName.text = personString;
            
            NSString *userName = self.taggableFriends[indexPath.row][@"userName"];
            tagCell.friendUserName.text = userName;
            
            [tagCell makeInitialPlaceholderView:tagCell.friendImageView name:personString];
            
        }else{
            NSString *userName = self.taggableFriends[indexPath.row][@"userName"];
            tagCell.friendUserName.text = userName;
            
            [tagCell makeInitialPlaceholderView:tagCell.friendImageView name:userName];
        }
    }
    
    
    if (self.taggableFriends[indexPath.item][@"firstName"] && self.taggableFriends[indexPath.item][@"lastName"]){
        
            NSString *firstName = self.taggableFriends[indexPath.item][@"firstName"];
            NSString *lastName = self.taggableFriends[indexPath.item][@"lastName"];
            NSString *personString = [NSString stringWithFormat:@"%@ %@",firstName,lastName];
        
            tagCell.friendName.text = personString;
        
            NSString *userName = self.taggableFriends[indexPath.row][@"userName"];
            tagCell.friendUserName.text = userName;
        
        }else{
            NSString *userName = self.taggableFriends[indexPath.row][@"userName"];
            tagCell.friendUserName.text = userName;
        }
    
    
        // Remove the checkmark as a result of dequeuing
    //DLog(@"Selected row: %i\nCurrent index path row: %i",selectedRow,indexPath.row);
    if (indexPath.row == selectedRow){
        DLog(@"Setting accessory to None");
        tagCell.accessoryType = UITableViewCellAccessoryCheckmark;
    }else tagCell.accessoryType = UITableViewCellAccessoryNone;
    

    return tagCell;
}


#pragma mark - UITableView Delegate Methods
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    TagCell *cell = (TagCell *)[tableView cellForRowAtIndexPath:indexPath];
    NSUInteger index = indexPath.row;
        
        if (index != NSNotFound) {
            
            if ([cell accessoryType] == UITableViewCellAccessoryNone) {
                [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
            } else {
                [cell setAccessoryType:UITableViewCellAccessoryNone];
            }
            
            [cell setTintColor:[UIColor whiteColor]];
        }
    
    
    selectedRow = index;
    
    [self.tagActionBtn setTitle:[NSString stringWithFormat:@"Tag %@",cell.friendName.text] forState:UIControlStateNormal];
    [self.tagActionBtn sizeToFit];
    
    [self.friendNameTextField resignFirstResponder];
    [self.friendEmailTextField resignFirstResponder];
    [self.searchFriendNameTextField resignFirstResponder];
    
    
    self.backgroundBlurView.alpha = 1;
    
    DLog(@"Selected row: %li",(long)selectedRow);
}



-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DLog();
    TagCell *cell = (TagCell *)[tableView cellForRowAtIndexPath:indexPath];
    NSUInteger index = indexPath.row;
    
    if (index != NSNotFound) {
        
        [cell setAccessoryType:UITableViewCellAccessoryNone];
    }
}


#pragma mark - View Controller Methods
-(void)loadAlbumMembers:(NSString *)spotId
{
    
    [Spot fetchSpotInfo:spotId completion:^(id results, NSError *error) {
        
        if (!error) {
            //self.spotInfo = results;
            
            self.taggableFriends = [NSMutableArray arrayWithArray:results[@"members"]];
            [self.tagTableView reloadData];
        }
    }];
}

-(CGRect)updateTagViewFrame:(CGPoint)tapLocationInView
{
    CGRect newFrameForTagView;
    CGFloat xPos;CGFloat yPos;
    
    if (tapLocationInView.x >= 100) {
        
         xPos = ( (tapLocationInView.x - self.tagView.frame.origin.x) / 2.0);
        
        if ( (xPos + self.tagView.frame.size.width) > self.view.frame.size.width) {
            xPos = ( (tapLocationInView.x - self.tagView.frame.origin.x) / 4.0);
        }
        
        DLog(@"Tap location is greater than 100. New xpos = %f",xPos);
    }else{
        xPos = tapLocationInView.x / 2.0;
        
        if ( (xPos + self.tagView.frame.size.width) > self.view.frame.size.width) {
            xPos = tapLocationInView.x / 3.0;;
        }
        
        DLog(@"Tap location is less than 100. New xpos = %f",xPos);

    }
    
   
     yPos = tapLocationInView.y + 30.0;
        if ((yPos + self.tagView.frame.size.height) > self.view.frame.size.height){\
            DLog(@"ypos is taller than view: %f",yPos);
            yPos = self.view.frame.size.height - tapLocationInView.y + 30.0;
            //yPos = diff - self.tagView.frame.size.height;
    }
    
    newFrameForTagView = CGRectMake(xPos, yPos, self.tagView.frame.size.width, self.tagView.frame.size.height);
    
     DLog(@"xPos for tag: %f\nyPos for tag: %f\nNew frame: %@",xPos,yPos,NSStringFromCGRect(newFrameForTagView));
    
    // Update tag with email view frame
    self.tagWithEmailView.frame = CGRectMake(self.tagView.frame.origin.x, (self.tagView.frame.size.height-220), self.tagView.frame.size.width, 220);
    
    
    return newFrameForTagView;
}


-(CGRect)resetTagViewFrame
{
    self.tagView.frame = CGRectMake(0, 170, 236, 280);
    self.tagWithEmailView.alpha = 0;
    DLog(@"Tag view frame reset: %@",NSStringFromCGRect(self.tagView.frame));
    
    return self.tagView.frame;
}


-(CGRect)shrinkTagViewHeight
{
    self.tagView.frame = CGRectMake(self.tagView.frame.origin.x, self.tagView.frame.origin.y,
                                    self.tagView.frame.size.width, 0);
    
    DLog(@"Tag view frame reset: %@",NSStringFromCGRect(self.tagView.frame));
    
    return self.tagView.frame;
}


-(CGRect)inflateTagViewHeight
{
    if (self.tagFriendsInContactsButton.hidden == YES) {
        
        self.tagTableView.frame = CGRectMake(self.tagTableView.frame.origin.x, self.tagTableView.frame.origin.y, self.tagTableView.frame.size.width, self.tagTableView.frame.size.height + self.tagFriendsInContactsButton.frame.size.height + 20);
        
    }
        
        self.tagView.frame = CGRectMake(self.tagView.frame.origin.x, self.tagView.frame.origin.y,
                                        self.tagView.frame.size.width, 280);
        
        DLog(@"Tag view frame reset: %@",NSStringFromCGRect(self.tagView.frame));
 
    [self.tagTableView setNeedsLayout];
    [self.tagTableView setNeedsDisplay];
    
    return self.tagView.frame;
}


#pragma mark - Helper methods to read user's contacts
- (void)fetchPhoneContacts:(TagType)inviteChannel completion:(void (^)(NSArray *contacts))success failure:(void (^)(NSError *error))failure {
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


static void readAddressBookContacts(ABAddressBookRef addressBook, TagType inviteChannel, void (^completion)(NSArray *contacts)) {
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
        
        NSString *email = nil;
        NSString *phone = nil;
        ABMultiValueRef contactInfo =  nil;
        ABMultiValueRef  phoneNumber = nil;
        
        if (inviteChannel == kEmail) {
            contactInfo = ABRecordCopyValue(person,kABPersonEmailProperty);
            phoneNumber = ABRecordCopyValue(person, kABPersonPhoneProperty);
        }else{
            contactInfo = ABRecordCopyValue(person, kABPersonPhoneProperty);
        }
        
        //DLog(@"Copy value: %@",);
        
        if (ABMultiValueGetCount(phoneNumber) > 0) {
            
            email = (__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(contactInfo, 0);
            phone = (__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(phoneNumber, 0);
            
            UIImage* image;
            
            NSDictionary *singleContact = @{@"firstName": ( (firstName== nil) ? @"" : firstName ),
                                            @"lastName" : ( (lastName==nil) ? @"" :lastName ),
                                            @"userName" :  ( (email == nil) ? phone : email ),
                                            @"email" : ( (email == nil) ? @"" : email ),
                                            @"phone" : ( (phone == nil) ? @"" : phone ),
                                            @"source" : @"device"};
            
            NSMutableDictionary *userContact = [NSMutableDictionary dictionaryWithDictionary:singleContact];
            
            if(ABPersonHasImageData(person)){
                image = [UIImage imageWithData:(__bridge NSData *)ABPersonCopyImageData(person)];
                [userContact setValue:@"YES" forKey:@"imageExists"];
                
            }else{
                image = [UIImage imageNamed:@"anonymousUser"];
                [userContact setValue:@"NO" forKey:@"imageExists"];
            }
            
            [userContact setValue:image forKey:@"photoURL"];
            
            [contacts addObject:userContact];
            
        } else {
            
            phone = @"[None]";
        }
    }
    
    completion(contacts);
}


- (void)showEmailContacts{
    
    [self.contactsActivityIndicator startAnimating];
    
    [self fetchPhoneContacts:kEmail completion:^(NSArray *contacts) {
        
        [self.tagFriendsInContactsButton setTitle:@"Find on Suba" forState:UIControlStateNormal];
        
        //DLog(@"Tag friends Btn text: %@",self.tagFriendsInContactsButton.titleLabel.text);
        
        [self.contactsActivityIndicator stopAnimating];
        
        // We are sorting the contacts here
        if ([contacts count] > 0){
            
            NSSortDescriptor *firstNameDescriptor = [[NSSortDescriptor alloc] initWithKey:@"firstName" ascending:YES];
            NSArray *sortDescriptors = [NSArray arrayWithObject:firstNameDescriptor];
            NSArray *sortedContacts = [contacts sortedArrayUsingDescriptors:sortDescriptors];
            self.phoneContacts = sortedContacts;
            
            DLog(@"Contacts - %@",sortedContacts);
            friendsOnSuba = self.taggableFriends;
            
            self.taggableFriends = [NSMutableArray arrayWithArray:sortedContacts];
            //[self.taggableFriends addObjectsFromArray:sortedContacts];
            
            self.tagTableView.frame = CGRectMake(self.tagTableView.frame.origin.x, self.tagTableView.frame.origin.y, self.tagTableView.frame.size.width, self.tagTableView.frame.size.height + self.tagFriendsInContactsButton.frame.size.height + 20);
            
            [self.tagTableView setNeedsLayout];
            [self.tagTableView setNeedsDisplay];
            
            [self.tagTableView reloadData];
            
            DLog("Tag table view: %@",NSStringFromCGRect(self.tagTableView.frame));
            
        }
        
    } failure:^(NSError *error) {
        DLog(@"Error - %@",error);
    }];
}



- (void)showPhoneContacts{
    [self.contactsActivityIndicator startAnimating];
    
    [self fetchPhoneContacts:kContacts completion:^(NSArray *contacts) {
        
        [self.contactsActivityIndicator stopAnimating];
        
        // We are sorting the contacts here
        if ([contacts count] > 0){
            
            NSSortDescriptor *firstNameDescriptor = [[NSSortDescriptor alloc] initWithKey:@"firstName" ascending:YES];
            NSArray *sortDescriptors = [NSArray arrayWithObject:firstNameDescriptor];
            NSArray *sortedContacts = [contacts sortedArrayUsingDescriptors:sortDescriptors];
            self.phoneContacts = sortedContacts;
            
            [self.taggableFriends addObjectsFromArray:sortedContacts];
            
            [self.tagTableView reloadData];
        }
        
    } failure:^(NSError *error) {
        DLog(@"Error - %@",error);
    }];
}


#pragma mark - UITextField Delegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    return YES;
}


- (void)keyboardShouldShow:(NSNotification *)notification{
    
    //Store frame of tag view before keyboard shows
    frameOfTagViewBeforeKeyboardShows = self.tagView.frame;
    
    NSDictionary* userInfo = [notification userInfo];
    
    
    NSTimeInterval duration;
    UIViewAnimationCurve animationCurve;
    CGRect startFrame;
    CGRect endFrame;
    
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&duration];
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey]    getValue:&animationCurve];
    [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey]        getValue:&startFrame];
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey]          getValue:&endFrame];
    
    
    DLog(@"Start Frame: %@\nEnd frame: %@",NSStringFromCGRect(startFrame),NSStringFromCGRect(endFrame));
    
    CGFloat sumOfTagViewAndHeight = self.tagView.frame.origin.y + self.tagView.frame.size.height;
    CGFloat yPosOfKeyboardFrame = endFrame.origin.y;
    
    
    CGFloat yChangeOfTagViewFrame = (sumOfTagViewAndHeight > yPosOfKeyboardFrame) ? sumOfTagViewAndHeight-yPosOfKeyboardFrame : 0 ;
   
    
    CGRect newContainerFrame = CGRectMake(self.tagView.frame.origin.x, self.tagView.frame.origin.y-yChangeOfTagViewFrame, self.tagView.frame.size.width, self.tagView.frame.size.height);
    
    DLog(@"Tag view frame: %@\nNew frame: %@",NSStringFromCGRect(self.tagView.frame),NSStringFromCGRect(newContainerFrame));
    
    //newContainerFrame.origin.y += ( sizeChange /2 );
    
    [UIView animateWithDuration:duration
                          delay:0
                        options:(animationCurve << 16)|UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         
                         [self.tagView setFrame:newContainerFrame];
                     }
                     completion:NULL];
}


- (void)keyboardShouldHide:(NSNotification *)notification{
    NSDictionary* userInfo = [notification userInfo];
    
    NSTimeInterval duration;
    UIViewAnimationCurve animationCurve;
    CGRect startFrame;
    CGRect endFrame;
    
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&duration];
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey]    getValue:&animationCurve];
    [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey]        getValue:&startFrame];
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey]          getValue:&endFrame];
    
    
    
    [UIView animateWithDuration:duration
                          delay:0
                        options:(animationCurve << 16)|UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         
                         [self.tagView setFrame:frameOfTagViewBeforeKeyboardShows];
                     }
                     completion:NULL];
}





- (IBAction)tagUserInPhoto:(UIButton *)sender
{
    self.backgroundBlurView.alpha = 0;
}







@end
