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

typedef enum {
    kInvite = 0,
    kMembers
} Tab;

#define MembersKey @"MembersKey"
#define SpotInfoKey @"SpotInfoKey"
#define SpotIdKey @"SpotIdKey"

@interface AlbumMembersViewController ()<UITableViewDataSource,UITableViewDelegate,MFMessageComposeViewControllerDelegate,UITextFieldDelegate,MFMailComposeViewControllerDelegate>

@property (strong,nonatomic) NSArray *members;
//@property (strong,nonatomic) NSDictionary *spotInfo;

@property (weak, nonatomic) IBOutlet UITableView *memberTableView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *addMembersButton;
@property (weak, nonatomic) IBOutlet UIView *loadingMembersIndicatorView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingMembersIndicator;
@property (weak, nonatomic) IBOutlet UIButton *inviteByEmailButton;
@property (weak, nonatomic) IBOutlet UIButton *inviteBySMSButton;
@property (weak, nonatomic) IBOutlet UIButton *inviteByUsernameButton;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UIView *invitesView;
@property (weak, nonatomic) IBOutlet UIButton *otherInviteOptionsButton;

- (void)loadAlbumMembers:(NSString *)spotId;
- (void)updateMembersData;
- (void)showAddMembersButton:(BOOL)flag;
-(void)sendSMSToRecipients:(NSMutableArray *)recipients;

- (IBAction)switchTabs:(UISegmentedControl *)sender;
- (IBAction)inviteBySMSButtonTapped:(UIButton *)sender;
- (IBAction)inviteByUsernameButtonTapped:(UIButton *)sender;
- (IBAction)inviteByEmailButtonTapped:(UIButton *)sender;
- (IBAction)unWindToMembersFromCancel:(UIStoryboardSegue *)segue;
- (IBAction)unWindToMembersFromAdd:(UIStoryboardSegue *)segue;
- (IBAction)showOtherInviteOptions:(UIButton *)sender;
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
        self.inviteByUsernameButton.alpha = 1;
        
        CGFloat newFrameY = self.inviteBySMSButton.frame.origin.y - (self.inviteByEmailButton.frame.size.height + 20);
        CGRect newFrame = CGRectMake(self.inviteByEmailButton.frame.origin.x, newFrameY, self.inviteByEmailButton.frame.size.width, self.inviteByEmailButton.frame.size.height);
        
        self.inviteByEmailButton.frame = newFrame;
        //self.inviteByEmailButton.enabled = YES;
        [self.inviteByEmailButton setUserInteractionEnabled:YES];
        
    }];

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

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Helpers
- (IBAction)inviteByUsernameButtonTapped:(UIButton *)sender
{
    [self performSegueWithIdentifier:@"InviteSubaUsersSegue" sender:nil];
}

-(void)loadAlbumMembers:(NSString *)spotId
{
    [AppHelper showLoadingDataView:self.loadingMembersIndicatorView indicator:self.loadingMembersIndicator flag:YES];
    
    [Spot fetchSpotInfo:spotId completion:^(id results, NSError *error) {
        
        [AppHelper showLoadingDataView:self.loadingMembersIndicatorView indicator:self.loadingMembersIndicator flag:NO];
        
        if (!error) {
            //DLog(@"Results - %@",results);
            self.spotInfo = results;
            //DLog(@"Spot Info - %@",self.spotInfo);
            
            if (![self.spotInfo[@"userName"] isEqualToString:[AppHelper userName]]){
                // If user is not creator,we need to check whether he/she can invite users
                BOOL canUserAddMembers = ([self.spotInfo[@"memberInvitePrivacy"] isEqualToString:@"ONLY_MEMBERS"])?NO:YES;
                if (canUserAddMembers) {
                    [self showAddMembersButton:YES];
                }else [self showAddMembersButton:NO];
                
            }else [self showAddMembersButton:YES];
            //[self showAddMembersButton:YES];
            self.members = results[@"members"];
            [self.memberTableView reloadData];
        }else{
            [AppHelper showAlert:@"Network error" message:@"Sorry we could not load the members of this stream" buttons:@[@"Try Later"] delegate:nil];
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
    DLog(@"Spot Info - %@",self.spotInfo); 
    NSString *shareText = [NSString stringWithFormat:@"Join my photo stream \"%@\" on Suba at https://subaapp.com/download",self.spotInfo[@"spotName"]];
    
    MFMailComposeViewController *mailComposer = [[MFMailComposeViewController alloc] init];
    mailComposer.mailComposeDelegate = self;
    [mailComposer setSubject:[NSString stringWithFormat:@"Photos from \"%@\"",self.spotInfo[@"spotName"]]];
    
    
    [mailComposer setMessageBody:shareText isHTML:NO];
    /*if (selectedPhoto != nil) {
        NSData *imageData = UIImageJPEGRepresentation(selectedPhoto, 1.0);
        [mailComposer addAttachmentData:imageData mimeType:@"image/jpeg" fileName:@"subapic"];
    }*/
    
    [Flurry logEvent:@"Share_Stream_Email_Done"];
    
    [self presentViewController:mailComposer animated:YES completion:nil];
    
    //[self performSegueWithIdentifier:@"EmailInvitesSegue" sender:self.spotID];
    
    /*if (self.emailTextField.alpha == 1) {
        // Send emails
        [self.emailTextField resignFirstResponder];
        NSString *emailInvites = self.emailTextField.text;
        NSDictionary *params = @{@"userId" : [User currentlyActiveUser].userID,@"emails":emailInvites};
        
        [[User currentlyActiveUser] inviteUsersToStreamViaEmail:params completion:^(id results, NSError *error) {
            if (!error) {
                if ([results[STATUS] isEqualToString:ALRIGHT]) {
                    // Email invites sent
                }
            }
        }];
    }
    else{
        
    [UIView animateWithDuration:.8 animations:^{
        CGRect smsButtonFrame = self.inviteBySMSButton.frame;
        CGRect userNameButtonFrame = self.inviteByUsernameButton.frame;
        self.inviteByUsernameButton.alpha = 0;
        self.inviteBySMSButton.alpha = 0;
        
        // Move the frame of the email button to where the username invite was
        self.emailTextField.alpha = 1;
        self.otherInviteOptionsButton.alpha = 1;
        self.otherInviteOptionsButton.frame = userNameButtonFrame;
        
        [self.inviteByEmailButton setTitle:@"Invite" forState:UIControlStateDisabled];
        
        self.inviteByEmailButton.frame = smsButtonFrame;
        [self.inviteByEmailButton setUserInteractionEnabled:NO];
        
        
    }];
  }*/
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
    
    //memberCell.memberImageView.image = [UIImage imageNamed:@"anonymousUser"];
    
    
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
    if ([MFMessageComposeViewController canSendText]){
        
        MFMessageComposeViewController *smsComposer = [[MFMessageComposeViewController alloc] init];
        
        smsComposer.messageComposeDelegate = self;
        smsComposer.recipients = recipients ;
        if ([self.spotInfo[@"spotCode"] isEqualToString:@"NONE"]) {
           smsComposer.body = [NSString stringWithFormat:@"Add your photos to the group photo stream \"%@\" on Suba for iPhone. This is where everyone is sharing their pics from this event! Download Suba here: http://appstore.com/suba",self.spotInfo[@"spotName"]];
        }else{
            smsComposer.body = [NSString stringWithFormat:@"Add your photos to the group photo stream \"%@\" on Suba for iPhone. Download Suba here: http://subaapp.com/download and enter the invite code \"%@\" ",self.spotInfo[@"spotName"],self.spotInfo[@"spotCode"]];
        }
        
        
        smsComposer.navigationBar.translucent = NO;
        UIColor *navbarTintColor = [UIColor colorWithRed:(217.0f/255.0f)
                                                   green:(77.0f/255.0f)
                                                    blue:(20.0f/255.0f)
                                                   alpha:1];
        
        smsComposer.navigationBar.barTintColor = navbarTintColor;
        smsComposer.navigationBar.tintColor = navbarTintColor;
        smsComposer.navigationItem.title = @"Send Message";
        NSDictionary *textTitleOptions = [NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName,[UIColor whiteColor],NSForegroundColorAttributeName, [UIFont fontWithName:@"HelveticaNeue-Light" size:17.0], NSFontAttributeName,nil];
        [smsComposer.navigationBar setTitleTextAttributes:textTitleOptions];
        
        [self presentViewController:smsComposer animated:NO completion:nil];
        
    }else{
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Text Message Failure"
                              message:
                              @"Your device doesn't support in-app sms"
                              delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
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
            [NSString stringWithFormat:@"Invite %i people",numberOfEmailInvites] forState:UIControlStateNormal];
            
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


@end
