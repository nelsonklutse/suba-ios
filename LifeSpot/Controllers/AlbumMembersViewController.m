//
//  AlbumMembersViewController.m
//  LifeSpot
//
//  Created by Kwame Nelson on 1/15/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import "AlbumMembersViewController.h"
#import "AlbumMembersCell.h"
#import "UserProfileViewController.h"
#import "InvitesViewController.h"
#import "EmailInvitesViewController.h"
#import "Spot.h"
#import "User.h"
#import "Branch.h"
#import "WhatsAppKit.h"

typedef enum {
    kInvite = 0,
    kMembers
} Tab;

#define MembersKey @"MembersKey"
#define SpotInfoKey @"SpotInfoKey"
#define SpotIdKey @"SpotIdKey"

@interface AlbumMembersViewController ()<UITableViewDataSource,UITableViewDelegate,MFMessageComposeViewControllerDelegate,UITextFieldDelegate,MFMailComposeViewControllerDelegate>{
    NSString *branchURL;
}
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;

@property (strong,nonatomic) NSArray *members;
//@property (strong,nonatomic) NSDictionary *spotInfo;

@property (weak, nonatomic) IBOutlet UITableView *memberTableView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *addMembersButton;
@property (weak, nonatomic) IBOutlet UIView *loadingMembersIndicatorView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingMembersIndicator;
@property (weak, nonatomic) IBOutlet UIButton *inviteByEmailButton;
@property (weak, nonatomic) IBOutlet UIButton *inviteBySMSButton;
@property (weak, nonatomic) IBOutlet UIButton *inviteByWhatsappButton;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UIView *invitesView;
@property (weak, nonatomic) IBOutlet UIButton *otherInviteOptionsButton;

- (void)loadAlbumMembers:(NSString *)spotId;
- (void)updateMembersData;
- (void)showAddMembersButton:(BOOL)flag;
-(void)sendSMSToRecipients:(NSMutableArray *)recipients;

- (IBAction)switchTabs:(UISegmentedControl *)sender;
- (IBAction)inviteBySMSButtonTapped:(UIButton *)sender;
- (IBAction)inviteByWhatsappButtonTapped:(UIButton *)sender;
- (IBAction)inviteByEmailButtonTapped:(UIButton *)sender;
- (IBAction)unWindToMembersFromCancel:(UIStoryboardSegue *)segue;
- (IBAction)unWindToMembersFromAdd:(UIStoryboardSegue *)segue;
- (IBAction)showOtherInviteOptions:(UIButton *)sender;
- (IBAction)inviteViaFacebook:(UIButton *)sender;
@end

@implementation AlbumMembersViewController

-(IBAction)unWindToMembersFromCancel:(UIStoryboardSegue *)segue
{
    
}

-(IBAction)unWindToMembersFromAdd:(UIStoryboardSegue *)segue
{
    [CSNotificationView showInViewController:self
                                       style:CSNotificationViewStyleSuccess message:@"Participants added"];
   
    [self loadAlbumMembers:self.spotID];
}

- (IBAction)showOtherInviteOptions:(UIButton *)sender
{
    [UIView animateWithDuration:.8 animations:^{
        
        self.otherInviteOptionsButton.alpha = 0;
        self.emailTextField.alpha = 0;
        self.inviteBySMSButton.alpha = 1;
        self.inviteByWhatsappButton.alpha = 1;
        
        CGFloat newFrameY = self.inviteBySMSButton.frame.origin.y - (self.inviteByEmailButton.frame.size.height + 20);
        CGRect newFrame = CGRectMake(self.inviteByEmailButton.frame.origin.x, newFrameY, self.inviteByEmailButton.frame.size.width, self.inviteByEmailButton.frame.size.height);
        
        self.inviteByEmailButton.frame = newFrame;
        //self.inviteByEmailButton.enabled = YES;
        [self.inviteByEmailButton setUserInteractionEnabled:YES];
        
    }];

}

- (IBAction)inviteViaFacebook:(UIButton *)sender
{
    
    if ([FBDialogs canPresentMessageDialog])
    {
        NSURL *link = [NSURL URLWithString:branchURL];
    
        NSString *shareLinkName = [NSString stringWithFormat:@"Photos from %@ stream on Suba",self.spotInfo[@"spotName"]];
    
        NSURL *linkPhoto = [NSURL URLWithString:[NSString stringWithFormat:@"https://s3.amazonaws.com/com.intruptiv.mypyx-photos/%@",self.spotInfo[@"spotName"]]];
    
        NSString *shareStreamDescription = [NSString stringWithFormat:@"Here're all the photos from %@ on Suba",self.spotInfo[@"spotName"]];
    
        FBLinkShareParams *params = [[FBLinkShareParams alloc] initWithLink:link name:shareLinkName caption:nil description:shareStreamDescription picture:linkPhoto];
        
       [FBDialogs presentMessageDialogWithParams:params clientState:nil handler:^(FBAppCall *call, NSDictionary *results, NSError *error) {
           DLog(@"Results - %@",results);
       }];
    }else{
        [AppHelper showAlert:@"Install Facebook"
                     message:@"Please install the Facebook app to invite your friends to this stream."
                     buttons:@[@"OK"]
                    delegate:nil];
    }
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.spotID){
        [self loadAlbumMembers:self.spotID];
    }
    
    
    self.invitesView.alpha = 1;
    self.memberTableView.alpha = 0;
    self.otherInviteOptionsButton.alpha = 0;
    [self showAddMembersButton:NO];
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.memberTableView addPullToRefreshActionHandler:^{
        // Method to update data
        [self updateMembersData];
    }];
        [self.memberTableView.pullToRefreshView setImageIcon:[UIImage imageNamed:@"icon-72"]];
    [self.memberTableView.pullToRefreshView setBorderWidth:6];
    [self.memberTableView.pullToRefreshView setBackgroundColor:[UIColor redColor]];

    UIBarButtonItem *cancel = self.navigationItem.leftBarButtonItem;
    [cancel setImage:[UIImage imageNamed:@"newX"]];
    
    // Prepare branch
    if (self.spotInfo) {
        [self prepareBranchURL];
    }
    
    
    if (self.shouldShowMembers){
        [self.segmentedControl setSelectedSegmentIndex:1];
        [UIView animateWithDuration:.5 animations:^{
            
            self.invitesView.alpha = 0;
            self.memberTableView.alpha = 1;
        }];
    }


    DLog(@"Spotinfo: %@",self.spotInfo);
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
   }


-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    self.shouldShowMembers = NO;
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Helpers
- (IBAction)inviteByWhatsappButtonTapped:(UIButton *)sender
{
    if ([WhatsAppKit isWhatsAppInstalled]){
        
        if(branchURL){
            // We already have the URL
            DLog(@"Branch URL already installed");
            NSString *message = [NSString stringWithFormat:@"See and add photos to the %@ photo stream on Suba : %@",self.spotInfo[@"spotName"],branchURL];
            
            //DLog(@"Yes whatsapp is installed so we show the whatsapp");
            [WhatsAppKit launchWhatsAppWithMessage:message];
            
        }else{
            
            NSString *senderName = nil;
            Branch *branch = [Branch getInstance:@"55726832636395855"];
            if ([AppHelper firstName].length > 0 && [AppHelper lastName].length > 0) {
                senderName = [NSString stringWithFormat:@"%@ %@",[AppHelper firstName],[AppHelper lastName]];
                
            }else if([AppHelper firstName].length > 0 && ([AppHelper lastName] == NULL | [[AppHelper lastName] class]== [NSNull class] | [AppHelper lastName].length == 0)){
                
                senderName = [AppHelper firstName];
            }else{
                senderName = [AppHelper userName];
            }
            
            if ([AppHelper profilePhotoURL] == NULL | [[AppHelper profilePhotoURL] class] == [NSNull class]) {
                [AppHelper setProfilePhotoURL:@"-1"];
            }
        
            if (self.spotInfo && senderName){
                
                NSDictionary *dict = @{
                                       @"$always_deeplink" : @"true",
                                       @"$desktop_url" : @"http://app.subaapp.com/streams/share",
                                       @"streamId":self.spotInfo[@"spotId"],
                                       @"photos" : self.spotInfo[@"numberOfPhotos"],
                                       @"streamName":self.spotInfo[@"spotName"],
                                       @"sender": senderName,
                                       @"streamCode" : self.spotInfo[@"spotCode"],
                                       @"senderPhoto" : [AppHelper profilePhotoURL]};
                
                NSMutableDictionary *streamDetails = [NSMutableDictionary dictionaryWithDictionary:dict];
                
                [branch getShortURLWithParams:streamDetails andChannel:@"whatsapp_message" andFeature:BRANCH_FEATURE_TAG_INVITE andCallback:^(NSString *url, NSError *error) {
                    if (!error) {
                        branchURL = url;
                        NSString *message = [NSString stringWithFormat:@"See and add photos to the \"%@\" photo stream on Suba : %@",self.spotInfo[@"spotName"],branchURL];
                        
                        [WhatsAppKit launchWhatsAppWithMessage:message];
                        
                    }else{
                        DLog(@"Branch link error: %@",error.debugDescription);
                    }
                }];

            }
        }
        
    }else{
        
        [AppHelper showAlert:@"Invite via WhatsApp" message:@"WhatsApp is not installed on your device." buttons:@[@"OK"] delegate:nil];
    }

}

-(void)loadAlbumMembers:(NSString *)spotId
{
    [AppHelper showLoadingDataView:self.loadingMembersIndicatorView indicator:self.loadingMembersIndicator flag:YES];
    
    [Spot fetchSpotInfo:spotId completion:^(id results, NSError *error) {
        
        [AppHelper showLoadingDataView:self.loadingMembersIndicatorView indicator:self.loadingMembersIndicator flag:NO];
        
        if (!error) {
            self.spotInfo = results;
            
            if (![self.spotInfo[@"userName"] isEqualToString:[AppHelper userName]]){
                // If user is not creator,we need to check whether he/she can invite users
                BOOL canUserAddMembers = ([self.spotInfo[@"memberInvitePrivacy"] isEqualToString:@"ONLY_MEMBERS"])? NO:YES;
                if(canUserAddMembers) {
                    [self showAddMembersButton:YES];
                }else [self showAddMembersButton:NO];
                
            }else [self showAddMembersButton:YES];
            self.members = results[@"members"];
            [self.memberTableView reloadData];
        }
    }];
}


-(void)updateMembersData
{
    __weak typeof(self) weakSelf = self;
    
    int64_t delayInSeconds = 1.2;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        
        [weakSelf loadAlbumMembers:self.spotID];
        [weakSelf.memberTableView stopRefreshAnimation];
        
    });
}


-(void)showAddMembersButton:(BOOL)flag
{
    NSMutableArray *navbarButtons = [self.navigationItem.rightBarButtonItems mutableCopy];
    
    if (flag) {
        if ([navbarButtons count] != 1) {
            [navbarButtons addObject:self.addMembersButton];
        }
        
    }else{
        [navbarButtons removeObject:self.addMembersButton];
    }
   
    [self.navigationItem setRightBarButtonItems:navbarButtons animated:YES];
}

- (IBAction)inviteBySMSButtonTapped:(UIButton *)sender
{
    [self sendSMSToRecipients:nil];
}

- (IBAction)inviteByEmailButtonTapped:(UIButton *)sender
{
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mailComposer = [[MFMailComposeViewController alloc] init];
        mailComposer.mailComposeDelegate = self;
        
        [mailComposer.navigationBar setTranslucent:NO];
        
        [mailComposer.navigationItem setTitle:@"Send Email"];
        
        [mailComposer setSubject:[NSString stringWithFormat:@"Photos from the %@ photo stream",self.spotInfo[@"spotName"]]];
        
        if (branchURL) {
            //We already have the branch URL
            NSString *shareText = [NSString stringWithFormat:@"<p>See and add photos to the %@ photo stream on Suba : %@</p>",self.spotInfo[@"spotName"],branchURL];
            
            
            [mailComposer setMessageBody:shareText isHTML:YES];
            [Flurry logEvent:@"Share_Stream_Email_Done"];
            
            if (!self.presentedViewController) {
                [self presentViewController:mailComposer animated:YES completion:nil];
            }
            
        }else{
            
            NSString *senderName = nil;
            Branch *branch = [Branch getInstance:@"55726832636395855"];
            if ([AppHelper firstName].length > 0 && [AppHelper lastName].length > 0) {
                senderName = [NSString stringWithFormat:@"%@ %@",[AppHelper firstName],[AppHelper lastName]];
                
            }else if([AppHelper firstName].length > 0 && ([AppHelper lastName] == NULL | [[AppHelper lastName] class]== [NSNull class] | [AppHelper lastName].length == 0)){
                
                senderName = [AppHelper firstName];
            }else{
                senderName = [AppHelper userName];
            }
            
            if ([AppHelper profilePhotoURL] == NULL | [[AppHelper profilePhotoURL] class] == [NSNull class]) {
                [AppHelper setProfilePhotoURL:@"-1"];
            }
            
            if (self.spotInfo && senderName){
                NSDictionary *dict = @{
                                       @"$always_deeplink" : @"true",
                                       @"$desktop_url" : @"http://app.subaapp.com/streams/share",
                                       @"streamId":self.spotID,
                                       @"photos" : self.spotInfo[@"numberOfPhotos"],
                                       @"streamName":self.spotInfo[@"spotName"],
                                       @"sender": senderName,
                                       @"streamCode" : self.spotInfo[@"spotCode"],
                                       @"senderPhoto" : [AppHelper profilePhotoURL]};
                
                
                NSMutableDictionary *streamDetails = [NSMutableDictionary dictionaryWithDictionary:dict];
                
                [branch getShortURLWithParams:streamDetails andChannel:@"email" andFeature:BRANCH_FEATURE_TAG_INVITE andCallback:^(NSString *url, NSError *error){
                    if (!error) {
                        branchURL = url;
                        DLog(@"URL from Branch: %@",url);
                        
                        NSString *shareText = [NSString stringWithFormat:@"<p>See and add photos to the %@ photo stream on Suba : %@</p>",self.spotInfo[@"spotName"],branchURL];
                        
                        
                        [mailComposer setMessageBody:shareText isHTML:YES];
                        [Flurry logEvent:@"Share_Stream_Email_Done"];
                        if (!self.presentedViewController) {
                            [self presentViewController:mailComposer animated:YES completion:nil];
                        }
                    }else DLog(@"Branch error: %@",error.debugDescription);
                }];

            }
        }
    }else{
        [AppHelper showAlert:@"Configure email" message:@"Hey there:) Do you mind configuring your Mail app to send email" buttons:@[@"OK"] delegate:nil];
    }
}


#pragma mark - UITableViewDatasource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.members count];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"AlbumMembersCell";
    AlbumMembersCell *memberCell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    memberCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    if (self.members[indexPath.row][@"photoURL"] != nil) {
        NSString *photoURL = self.members[indexPath.row][@"photoURL"];
        [memberCell fillView:memberCell.memberImageView WithImage:photoURL];
        
        if (self.members[indexPath.item][@"firstName"] && self.members[indexPath.item][@"lastName"]){
            NSString *firstName = self.members[indexPath.item][@"firstName"];
            NSString *lastName = self.members[indexPath.item][@"lastName"];
            NSString *personString = [NSString stringWithFormat:@"%@ %@",firstName,lastName];
            memberCell.memberUserNameLabel.text = personString;
        }else{
            NSString *userName = self.members[indexPath.row][@"userName"];
            memberCell.memberUserNameLabel.text = userName;
        }
        
    }else{
            if (self.members[indexPath.item][@"firstName"] && self.members[indexPath.item][@"lastName"]){
                NSString *firstName = self.members[indexPath.item][@"firstName"];
                NSString *lastName = self.members[indexPath.item][@"lastName"];
                NSString *personString = [NSString stringWithFormat:@"%@ %@",firstName,lastName];
                memberCell.memberUserNameLabel.text = personString;
                [memberCell makeInitialPlaceholderView:memberCell.memberImageView name:personString];
                
            }else{
                NSString *userName = self.members[indexPath.row][@"userName"];
                memberCell.memberUserNameLabel.text = userName;
                [memberCell makeInitialPlaceholderView:memberCell.memberImageView name:userName];
            }
    }
    
    return memberCell;
    
}


#pragma mark - UITableView Delegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    AlbumMembersCell *cell = (AlbumMembersCell *)[tableView cellForRowAtIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellEditingStyleNone;
    NSString *userId = self.members[indexPath.row][@"id"];
    //DLog(@"UserID of Participant - %@",userId);
    
    [self performSegueWithIdentifier:@"PARTICIPANTS_PROFILE_SEGUE" sender:userId];
}


#pragma mark - Segue
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"PARTICIPANTS_PROFILE_SEGUE"]) {
        UserProfileViewController *uVC = segue.destinationViewController;
        uVC.userId = sender;
        
    }else if ([segue.identifier isEqualToString:@"InviteSubaUsersSegue"]) {
        InvitesViewController *iVC = segue.destinationViewController;
        iVC.spotToInviteUserTo = self.spotInfo;
        
    }else if ([segue.identifier isEqualToString:@"EmailInvitesSegue"]){
        EmailInvitesViewController *emailVC = segue.destinationViewController;
        emailVC.streamId = sender;
    }
}


#pragma mark - Send SMS
-(void)sendSMSToRecipients:(NSMutableArray *)recipients
{
    @try {
        NSString *senderName = nil;
        if ([MFMessageComposeViewController canSendText]){
            
            MFMessageComposeViewController *smsComposer = [[MFMessageComposeViewController alloc] init];
            
            smsComposer.messageComposeDelegate = self;
            smsComposer.recipients = recipients;
            
            if (branchURL) {
                // We already have the branch URL set up
                DLog(@"Branch URL is already set up");
                smsComposer.body = [NSString stringWithFormat:@"See and add photos to the \"%@\" photo stream on Suba : %@",self.spotInfo[@"spotName"],branchURL];
                
                if (!self.presentedViewController){
                    [self presentViewController:smsComposer animated:YES completion:nil];
                }
                
            }else{
                
                Branch *branch = [Branch getInstance:@"55726832636395855"];
                if ([AppHelper firstName].length > 0 && [AppHelper lastName].length > 0) {
                    senderName = [NSString stringWithFormat:@"%@ %@",[AppHelper firstName],[AppHelper lastName]];
                    
                }else{
                    
                    senderName = [AppHelper userName];
                }
                
                
                DLog(@"Stream code: - %@\n Sender: %@\nProfile photo: %@",self.spotInfo,senderName,[[AppHelper profilePhotoURL] class]);
                
                if ([AppHelper profilePhotoURL] == NULL | [[AppHelper profilePhotoURL] class] == [NSNull class]) {
                    [AppHelper setProfilePhotoURL:@"-1"];
                }
                
                if (senderName && self.spotInfo) {
                    NSDictionary *dict = @{
                                           @"$always_deeplink" : @"true",
                                           @"$desktop_url" : @"http://app.subaapp.com/streams/share",
                                           @"streamId":self.spotInfo[@"spotId"],
                                           @"photos" : self.spotInfo[@"numberOfPhotos"],
                                           @"streamName":self.spotInfo[@"spotName"],
                                           @"sender": senderName,
                                           @"streamCode" : self.spotInfo[@"spotCode"],
                                           @"senderPhoto" : [AppHelper profilePhotoURL]};
                    
                    
                    NSMutableDictionary *streamDetails = [NSMutableDictionary dictionaryWithDictionary:dict];
                    
                    
                    
                    
                    [branch getShortURLWithParams:streamDetails andChannel:@"text_message" andFeature:BRANCH_FEATURE_TAG_INVITE andCallback:^(NSString *url, NSError *error) {
                        if (!error) {
                            branchURL = url;
                            //DLog(@"URL from Branch: %@",url);
                            smsComposer.body = [NSString stringWithFormat:@"See and add photos to the \"%@\" photo stream on Suba : %@",self.spotInfo[@"spotName"],branchURL];
                            
                            [smsComposer.navigationBar setTranslucent:NO];
                            
                            if (!self.presentedViewController){
                                [self presentViewController:smsComposer animated:YES completion:nil];
                            }
                        }else DLog(@"Branch error: %@",error.debugDescription);
                        
                    }];
 
                }
                
            }
            
        }else{
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:@"Text Message Failure"
                                  message:
                                  @"Your device doesn't support in-app sms"
                                  delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
        
    }
    @catch (NSException *exception) {
        DLog(@"exception name: %@\nexception reason: %@\nException info: %@",exception.name,exception.reason,[exception.userInfo debugDescription]);
        
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Oops:)"
                              message:
                              @"Something went wrong.Please try again."
                              delegate:nil cancelButtonTitle:@"Try again" otherButtonTitles:nil];
        [alert show];
    }
}

- (IBAction)switchTabs:(UISegmentedControl *)sender
{
    if (sender.selectedSegmentIndex == kMembers) {
        [UIView animateWithDuration:.5 animations:^{
            self.invitesView.alpha = 0;
            self.memberTableView.alpha = 1;
        }];
    }else if (sender.selectedSegmentIndex == kInvite){
        [UIView animateWithDuration:.5 animations:^{
            self.invitesView.alpha = 1;
            self.memberTableView.alpha = 0;
        }];
    }
}

#pragma mark - MFMessageComposeViewControllerDelegate
-(void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    
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


#pragma mark - UITextField Delegate
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    NSString *emailInvites = textField.text;
    NSDictionary *params = @{@"userId" : [User currentlyActiveUser].userID,@"emails":emailInvites};
    
    [[User currentlyActiveUser] inviteUsersToStreamViaEmail:params completion:^(id results, NSError *error) {
        if (!error) {
            if ([results[STATUS] isEqualToString:ALRIGHT]) {
                // Email invites sent
            }
        }
    }];
    
    return YES;
}




-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
       if (textField.text.length > 0){
        NSArray *emails = [textField.text componentsSeparatedByString:@","];
           
        if ([emails count] == 1){
            if ([AppHelper validateEmail:emails[0]]){
                //self.inviteByEmailButton.enabled = YES;
                [self.inviteByEmailButton setTitle:@"Invite 1 person" forState:UIControlStateNormal];
                [self.inviteByEmailButton setUserInteractionEnabled:YES];
                //self.inviteByEmailButton.enabled = YES;
                //self.inviteByEmailButton.frame = self.inviteBySMSButton.frame;
            }
        }else{
            
            NSInteger numberOfEmailInvites = 0;
            for (int x = 0; x < [emails count]; x++){
                if([AppHelper validateEmail:emails[x]]){
                    ++numberOfEmailInvites;
                }
            }
            
            [self.inviteByEmailButton setTitle:
            [NSString stringWithFormat:@"Invite %li people",(long)numberOfEmailInvites] forState:UIControlStateNormal];
            
            //[self.inviteByEmailButton sizeToFit];
            [self.inviteByEmailButton setUserInteractionEnabled:YES];
            //self.inviteByEmailButton.enabled = YES;
            //self.inviteByEmailButton.frame = self.inviteBySMSButton.frame;
            
        }
           //self.inviteByEmailButton.frame = self.inviteBySMSButton.frame;
           return YES;
    }
    
    else{
        self.inviteByEmailButton.titleLabel.text = @"Invite";
        //[self.inviteByEmailButton sizeToFit];
        [self.inviteByEmailButton setUserInteractionEnabled:NO];
        //self.inviteByEmailButton.enabled = NO;
        self.inviteByEmailButton.frame = self.inviteBySMSButton.frame;
    }
    
    return YES;
}


-(void)textFieldDidEndEditing:(UITextField *)textField
{
    
}


#pragma mark - MFMailComposeViewController
-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    
    switch (result)
    {
        case MFMailComposeResultCancelled:
            //DLog(@"SMS sending failed");
            [Flurry logEvent:@"Email_Share_Cancelled"];
            break;
        case MFMailComposeResultSent:
            //DLog(@"SMS sent");
            [Flurry logEvent:@"Email_Share_Sent"];
            break;
        case MFMailComposeResultFailed:
            //DLog(@"SMS sending failed");
            [Flurry logEvent:@"Email_Share_Failed"];
            break;
        default:
            DLog(@"Email not sent");
            break;
    }
    
    [controller dismissViewControllerAnimated:YES completion:nil];
}



#pragma mark - State Preservation and Restoration
-(void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeObject:self.spotID forKey:SpotIdKey];
    [coder encodeObject:self.members forKey:MembersKey];
    [coder encodeObject:self.spotInfo forKey:SpotInfoKey];
    //DLog(@"Self.spotID -%@\nself.members - %@\nself.spotInfo - %@",self.spotID,self.members,self.spotInfo);
}


-(void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super decodeRestorableStateWithCoder:coder];
    
    self.spotID = [coder decodeObjectForKey:SpotIdKey];
    self.members = [coder decodeObjectForKey:MembersKey];
    self.spotInfo = [coder decodeObjectForKey:SpotInfoKey];
    DLog(@"Self.spotID -%@\nself.members - %@\nself.spotInfo - %@",self.spotID,self.members,self.spotInfo);

}

-(void)applicationFinishedRestoringState
{
    if (self.members) {
        [self.memberTableView reloadData];
    }else if(self.spotID){
        [self loadAlbumMembers:self.spotID];
    }
    
    DLog(@"Self.spotID -%@\nself.members - %@\nself.spotInfo - %@",self.spotID,self.members,self.spotInfo);

}



-(void)prepareBranchURL
{
    //NSString __block *branchurl = @"";
    NSString *senderName = nil;
    
    Branch *branch = [Branch getInstance:@"55726832636395855"];
    if ([AppHelper firstName].length > 0 && [AppHelper lastName].length > 0) {
        senderName = [NSString stringWithFormat:@"%@ %@",[AppHelper firstName],[AppHelper lastName]];
        
    }else{
        
        senderName = [AppHelper userName];
    }
    
    
    DLog(@"Stream code: - %@\n Sender: %@\nProfile photo: %@",self.spotInfo,senderName,[[AppHelper profilePhotoURL] class]);
    
    if ([AppHelper profilePhotoURL] == NULL | [[AppHelper profilePhotoURL] class] == [NSNull class]) {
        [AppHelper setProfilePhotoURL:@"-1"];
    }
    NSDictionary *dict = @{
                           @"$always_deeplink" : @"true",
                           @"$desktop_url" : @"http://app.subaapp.com/streams/share",
                           @"streamId":self.spotInfo[@"spotId"],
                           @"photos" : self.spotInfo[@"photos"],
                           @"streamName":self.spotInfo[@"spotName"],
                           @"sender": senderName,
                           @"streamCode" : self.spotInfo[@"spotCode"],
                           @"senderPhoto" : [AppHelper profilePhotoURL]};
    
    
    NSMutableDictionary *streamDetails = [NSMutableDictionary dictionaryWithDictionary:dict];
    
    [branch getShortURLWithParams:streamDetails andChannel:@"whatsapp_message" andFeature:BRANCH_FEATURE_TAG_INVITE andCallback:^(NSString *url, NSError *error) {
        if (!error) {
            DLog(@"URL from Branch: %@",url);
            branchURL = url;
        }else{
            DLog("Branch Error: %@",error.debugDescription);
        }
        
        
    }];
    
    //return branchURL;
    
}



@end
