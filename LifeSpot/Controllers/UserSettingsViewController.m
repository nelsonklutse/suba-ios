//
//  UserSettingsViewController.m
//  LifeSpots
//
//  Created by Kwame Nelson on 11/6/13.
//  Copyright (c) 2013 Agana-Nsiire Agana. All rights reserved.
//

#import "UserSettingsViewController.h"
#import "ProfileSettingsViewController.h"
//#import "PushNotificationsViewController.h"
//#import "InviteFriendsViewController.h"
#import <MessageUI/MessageUI.h>

@interface UserSettingsViewController ()<MFMailComposeViewControllerDelegate>

@property(strong,nonatomic) NSArray *accountSettings;
@property(strong,nonatomic) NSArray *help;
@property(strong,nonatomic) NSArray *legal;

@property (weak, nonatomic) IBOutlet UITableView *appSettingsTableView;
- (void)sendFeedback:(NSString *)userEmail;
- (void)logout;

- (IBAction)unwindToUserSettings:(UIStoryboardSegue *)segue;
@end

@implementation UserSettingsViewController


-(void)unwindToUserSettings:(UIStoryboardSegue *)segue
{
    //ProfileSettingsViewController *pVC = segue.sourceViewController;
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.accountSettings = @[@"Edit Profile",@"Push Notifications",@"Invite Friends To Suba"];
    self.help = @[@"Help",@"Send Feedback",@"About Suba"];
    self.legal = @[@"Privacy Policy",@"Terms of Use"];
    
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
            UITableViewCell *cell = [self.appSettingsTableView cellForRowAtIndexPath:indexPath];
            [self performSegueWithIdentifier:@"PUSH_NOTIFICATIONS_SEGUE" sender:cell.textLabel.text];
        }else{
            // First section 3rd cell
            UITableViewCell *cell = [self.appSettingsTableView cellForRowAtIndexPath:indexPath];
            [self performSegueWithIdentifier:@"INVITE_PEOPLE_SEGUE" sender:cell.textLabel.text];
        }
    }else if (indexPath.section == 1){
        if (indexPath.row == 1) {
            // NSLog(@"User with email address is sending feedback");
            [self sendFeedback:[AppHelper userEmail]];
        }
        
    }else if (indexPath.section == 3){
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
    }else if ([segue.identifier isEqualToString:@"INVITE_PEOPLE_SEGUE"]){
        //InviteFriendsViewController *friendsVC = segue.destinationViewController;
        //friendsVC.navigationItem.title = @"Invite People";
    }
    
}



-(void)logout{
    [AppHelper logout];
    // Move to the main view controller
    UINavigationController *rvc = (UINavigationController *)[[[UIApplication sharedApplication] keyWindow] rootViewController];
    NSLog(@"Class- %@",[[[[UIApplication sharedApplication] keyWindow] rootViewController] class]);
    
    //[self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    [rvc popToRootViewControllerAnimated:YES];
}


-(void)sendFeedback:(NSString *)userEmail
{
    if ([MFMailComposeViewController canSendMail]){
        MFMailComposeViewController *mailComposer = [[MFMailComposeViewController alloc] init];
        mailComposer.mailComposeDelegate = self;
        [mailComposer setToRecipients:@[@"support@lifespotsapp.com"]];
        
        //[mailComposer setBccRecipients:@[@"nelson@intruptiv.com",@"agana@intruptiv.com",@"eric@intruptiv.com"]];
        
        [mailComposer setSubject:@"Lifespots Feedback"];
        
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


@end
