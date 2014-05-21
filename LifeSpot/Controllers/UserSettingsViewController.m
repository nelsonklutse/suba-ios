//
//  UserSettingsViewController.m
//  LifeSpots
//
//  Created by Kwame Nelson on 11/6/13.
//  Copyright (c) 2013 Agana-Nsiire Agana. All rights reserved.
//

#import "UserSettingsViewController.h"
#import "ProfileSettingsViewController.h"
#import "AppDelegate.h"
#import "CleverInvitesViewController.h"
#import "TermsViewController.h"
#import <MessageUI/MessageUI.h>

@interface UserSettingsViewController ()<MFMailComposeViewControllerDelegate,UIActionSheetDelegate>

@property(strong,nonatomic) NSArray *accountSettings;
@property(strong,nonatomic) NSArray *help;
@property(strong,nonatomic) NSArray *legal;

@property (weak, nonatomic) IBOutlet UITableView *appSettingsTableView;
- (void)sendFeedback:(NSString *)userEmail;
- (void)logout;

- (IBAction)unwindToUserSettings:(UIStoryboardSegue *)segue;
- (void)showActionSheet;

- (void)shareViaServiceType:(NSString *)serviceType;
- (void)showUnavailableAlertForServiceType: (NSString *)serviceType;
- (void)rateApp;
@end

@implementation UserSettingsViewController


-(void)unwindToUserSettings:(UIStoryboardSegue *)segue
{
    //ProfileSettingsViewController *pVC = segue.sourceViewController;
    
}

/*-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    //self.appSettingsTableView.frame = self.view.bounds;
    CGRect frame = self.view.bounds;
    frame.size.height -= 64;
    self.appSettingsTableView.frame = self.view.bounds;
}*/

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //self.autoInvite = NO;
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.accountSettings = @[@"Edit Profile",@"Tell a friend",@"Rate Suba"];
    self.help = @[@"Help",@"Send Feedback",@"Licenses"];
    self.legal = @[@"Privacy Policy",@"Terms of Use"];
    
    
   // DLog(@"Bounds of root view - %@\nFrame of appsettingsTable - %@",NSStringFromCGRect(self.view.bounds),NSStringFromCGRect(self.appSettingsTableView.frame));
}


-(void)viewDidAppear:(BOOL)animated
{
    DLog();
    [super viewDidAppear:animated];
    
    if (self.autoInvite == YES) {
        [self showActionSheet];
    }
    self.autoInvite = NO;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    
    // Return the number of sections.
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;
    if (section == 0) {
        numberOfRows = [self.accountSettings count];
    }else if (section == 1){
        numberOfRows = [self.help count];
    }else if (section == 2){
        numberOfRows = [self.legal count];
    }else numberOfRows = 1;
    
    return numberOfRows;
}


-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 30.0f;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *headerTitle = nil;
    if (section == 0) {
        headerTitle = @"ACCOUNT";
    }else if (section == 1){
        headerTitle = @"HELP/ABOUT";
    }else if (section == 2){
        headerTitle = @"LEGAL";
    }
    
    return headerTitle;
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"SETTINGS_CELL";
    UITableViewCell *cell = [self.appSettingsTableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    // Configure the cell...
    if (indexPath.section == 0) {
        cell.textLabel.text = self.accountSettings[indexPath.row];
        
    }else if (indexPath.section == 1){
        cell.textLabel.text = self.help[indexPath.row];
    }else if (indexPath.section == 2){
        cell.textLabel.text = self.legal[indexPath.row];
    }else{
        cell.textLabel.text = @"Logout";
        cell.textLabel.textColor = [UIColor redColor];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    //Get the cell that was selected
    
    if (indexPath.section == 0){
        if (indexPath.row == 0) {
            //We are at the very first cell in the first section.Go to the Edit Settings page
            UITableViewCell *cell = [self.appSettingsTableView cellForRowAtIndexPath:indexPath];
            [self performSegueWithIdentifier:@"EDIT_PROFILE_SEGUE" sender:cell.textLabel.text];
        }else if (indexPath.row == 1){
            // First section 2nd cell
            //UITableViewCell *cell = [self.appSettingsTableView cellForRowAtIndexPath:indexPath];
            //[self performSegueWithIdentifier:@"PUSH_NOTIFICATIONS_SEGUE" sender:cell.textLabel.text];*/
            
            [self showActionSheet];
            
        }else if (indexPath.row == 2){
            // First section 3rd cell
            //UITableViewCell *cell = [self.appSettingsTableView cellForRowAtIndexPath:indexPath];
            //[self performSegueWithIdentifier:@"INVITE_FRIENDS_TO_SUBA_SEGUE" sender:nil];
            
            [self rateApp];
            
        }
    }else if (indexPath.section == 1){
        if (indexPath.row == 0) {
            [self performSegueWithIdentifier:@"TERMS_SEGUE" sender:@(2)];
        }
        else if (indexPath.row == 1) {
            // NSLog(@"User with email address is sending feedback");
            [self sendFeedback:[AppHelper userEmail]];
        }else{
            [self performSegueWithIdentifier:@"TERMS_SEGUE" sender:@(10)];
        }
        
        
        
    }else if (indexPath.section == 2){
        [self performSegueWithIdentifier:@"TERMS_SEGUE" sender:@(indexPath.row)];
    }
    else if (indexPath.section == 3){
        if (indexPath.row == 0) {
            // Log the user out
            [self logout];
        }
    }
}


#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"EDIT_PROFILE_SEGUE"]) {
        ProfileSettingsViewController *profileSettingsVC = segue.destinationViewController;
        profileSettingsVC.navigationItem.title = (NSString *)sender;
    }else if ([segue.identifier isEqualToString:@"PUSH_NOTIFICATIONS_SEGUE"]){
        //PushNotificationsViewController *pushNVC = segue.destinationViewController;
        //pushNVC.navigationItem.title = (NSString *)sender;
    }else if([segue.identifier isEqualToString:@"TERMS_SEGUE"]){
        
        NSURL *url = nil;
        TermsViewController *tVC = segue.destinationViewController;
        
        if ([sender integerValue] == 0) {
            url = [NSURL URLWithString:@"http://www.subaapp.com/privacy.html"];
            tVC.navigationItem.title = @"Privacy";
        }else if([sender integerValue] == 1){
            url = [NSURL URLWithString:@"http://www.subaapp.com/terms.html"];
            tVC.navigationItem.title = @"Terms";
        }else if([sender integerValue] == 2){
            url = [NSURL URLWithString:@"http://www.subaapp.com/support.html"];
            tVC.navigationItem.title = @"Support";
        }else if ([sender integerValue] == 10){
            url = [NSURL URLWithString:@"http://www.subaapp.com/ioslicenses.html"];
            tVC.navigationItem.title = @"Licenses";
        }
       
        
        tVC.urlToLoad = url;
        
    }    
}


-(void)logout{
    [AppHelper logout];
    
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    
    UIViewController *topVC = [appDelegate topViewController];
    [topVC.navigationController popToRootViewControllerAnimated:YES];
    
    [topVC removeFromParentViewController];
    [appDelegate resetMainViewController];
    
    [Flurry logEvent:@"Logout"];
}


-(void)sendFeedback:(NSString *)userEmail
{
    if ([MFMailComposeViewController canSendMail]){
        MFMailComposeViewController *mailComposer = [[MFMailComposeViewController alloc] init];
        mailComposer.mailComposeDelegate = self;
        [mailComposer setToRecipients:@[@"support@subaapp.com"]];
        
        //[mailComposer setBccRecipients:@[@"nelson@intruptiv.com",@"agana@intruptiv.com",@"eric@intruptiv.com"]];
        
        [mailComposer setSubject:@"Suba Feedback"];
        
        [self presentViewController:mailComposer animated:YES completion:nil];
        
    }else{
        
        NSString *message = @"We did not detect a mail composer on your device";
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Mail Compose Issue" message:message delegate:nil cancelButtonTitle:@"It's true" otherButtonTitles:@"You're wrong",nil];
        
        [alertView show];
        
    }
}


#pragma mark - MailComposeViewController Delegate methods
-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    switch (result) {
        case MFMailComposeResultFailed:
            // Find out why the email failed to send
            break;
        case MFMailComposeResultCancelled:
            // We need analytics here so we know when someone tried to send an email but cancelled
        case MFMailComposeResultSaved:
            // Ananlytics here to know how many email drafs are being saved
        case MFMailComposeResultSent:
            // Analytics here. We need to know that a user successfully sent an email address
            [controller dismissViewControllerAnimated:YES completion:nil];
            break;
        default:
            break;
    }
}


#pragma mark - Helpers
-(void)showActionSheet
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Tell a friend about Suba via..."
                                                             delegate:self cancelButtonTitle:@"Dismiss"destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Mail",@"Message",@"Twitter",@"Facebook", nil];
    
    [actionSheet showInView:self.view];
}

#pragma mark - Action Sheet Delegate
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    CleverInvitesViewController *cVC = nil;
    UIStoryboard *invitesSb = [UIStoryboard storyboardWithName:@"Invites" bundle:[NSBundle mainBundle]];
    cVC = [invitesSb instantiateViewControllerWithIdentifier:@"CleverInvitation"];
    if (buttonIndex == 0){
        // We want to email
        cVC.inviteType = kEmail;
        [self presentViewController:cVC animated:YES completion:nil];
    }else if(buttonIndex == 1){
        // Send Message
        cVC.inviteType = kContacts;
        [self presentViewController:cVC animated:YES completion:nil];
    }else if (buttonIndex == 2){
        cVC.inviteType = kTwitter;
        [self shareViaServiceType:SLServiceTypeTwitter];
    }else if(buttonIndex == 3){
        cVC.inviteType = kFacebook;
        [self shareViaServiceType:SLServiceTypeFacebook];
    }else{
        [actionSheet dismissWithClickedButtonIndex:4 animated:YES];
    }
}


-(void)rateApp
{
    // Make call to Appirater
    [Appirater rateApp];

}


- (void)shareViaServiceType:(NSString *)serviceType
{
    //NSString *serviceType = SLServiceTypeTwitter;
    if (![SLComposeViewController isAvailableForServiceType:serviceType]) {
        [self showUnavailableAlertForServiceType:serviceType];
        
    }else{
        SLComposeViewController *composeViewController = [SLComposeViewController
                                                          composeViewControllerForServiceType:serviceType];
        
        [composeViewController addImage:[UIImage imageNamed:@"facebook_v1.jpg"]];
        
        
        
        
        if (serviceType == SLServiceTypeTwitter){
            NSString *initalTextString = [NSString stringWithFormat:@"%@",@"I'm using this awesome photo app @SubaPhotoApp"];
            
            [composeViewController setInitialText:initalTextString];
            
            [composeViewController addURL:[NSURL URLWithString:@"http://bit.ly/suba_t"]];
        }else if (serviceType == SLServiceTypeFacebook){
            
            NSString *initalTextString = [NSString stringWithFormat:@"%@\n%@",@"Ever been to a party or event and wished you got all those nice photos others took without waiting a decade for them?",@" Don't miss out again. Download Suba @ "];
            
            [composeViewController setInitialText:initalTextString];
            [composeViewController addURL:[NSURL URLWithString:@"http://bit.ly/suba_fb"]];
        }
        
        
        [self presentViewController:composeViewController animated:YES completion:nil];
    }
}




- (void)showUnavailableAlertForServiceType: (NSString *)serviceType
{
    NSString *serviceName = @"";
    if (serviceType == SLServiceTypeFacebook) {
        serviceName = @"Facebook";
    }
    else if (serviceType == SLServiceTypeTwitter) {
        serviceName = @"Twitter";
    }
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Account"
                                                        message:[NSString stringWithFormat:@"Please go to the device settings and add a %@ account in order to share through that service", serviceName]
                                                       delegate:nil
                                              cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
    
    [alertView show];
}



@end
