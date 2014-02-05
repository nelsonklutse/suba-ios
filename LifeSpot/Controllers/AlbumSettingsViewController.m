//
//  AlbumSettingsViewController.m
//  LifeSpot
//
//  Created by Kwame Nelson on 1/15/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import "AlbumSettingsViewController.h"
#import "FoursquareLocationsViewController.h"
#import "MainStreamViewController.h"
#import "Location.h"
#import "Spot.h"
#import "User.h"


@interface AlbumSettingsViewController ()<UITextFieldDelegate,UITextViewDelegate,UIAlertViewDelegate>


@property (copy,nonatomic) NSString *spotKey;
@property (copy,nonatomic) NSString *locationName;
@property (copy,nonatomic) NSString *spotDesc;
@property (strong,nonatomic) NSString *venueForCurrentLocation;
@property (strong,nonatomic) NSDictionary *latlng;

@property (weak, nonatomic) IBOutlet UITextField *spotNameField;
@property (weak, nonatomic) IBOutlet UITextField *spotKeyField;
@property (weak, nonatomic) IBOutlet UITextView *spotDescription;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveAlbumSettingsBarItem;
@property (weak, nonatomic) IBOutlet UIButton *locationNameButton;

@property (weak, nonatomic) IBOutlet UISwitch *viewPrivacySwitch;
@property (weak, nonatomic) IBOutlet UISwitch *addPrivacySwitch;
@property (weak, nonatomic) IBOutlet UISwitch *memberInviteSwitch;
@property (weak, nonatomic) IBOutlet UIButton *leaveAlbumButton;

- (IBAction)unWindToSpotSettingsFromCancel:(UIStoryboardSegue *)segue;
- (IBAction)unWindToSpotSettingsFromDone:(UIStoryboardSegue *)segue;

- (IBAction)toggleViewPrivacySwitch:(UISwitch *)sender;
- (IBAction)toggleAddPrivacySwitch:(UISwitch *)sender;
- (IBAction)saveAlbumAction:(UIBarButtonItem *)sender;
- (IBAction)toggleMemberInviteSwitch:(id)sender;
- (IBAction)locationButtonTapped:(id)sender;
- (IBAction)leaveAlbumAction:(UIButton *)sender;
- (IBAction)dismissKeypadOnBackgroundClick:(id)sender;

- (void)updateViewWithSpotInfo;
- (void)saveAlbumInfo:(NSMutableDictionary *)spotInfo indicator:(id)indicator;
@end

@implementation AlbumSettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    // [self.view setUserInteractionEnabled:NO];
    self.saveAlbumSettingsBarItem.enabled = NO;
    // self.navigationItem.title = self.spotName
    [self updateViewWithSpotInfo];
    
    if (!self.addPrivacySwitch.isOn) {
        self.viewPrivacySwitch.on = YES;
        self.viewPrivacySwitch.enabled = NO;
    }
    self.leaveAlbumButton.enabled = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITextField Delegate
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}


-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    self.saveAlbumSettingsBarItem.enabled = YES;
    return YES;
}


#pragma mark - UITextView Delegate
-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    self.saveAlbumSettingsBarItem.enabled = YES;
    return YES;
}


-(void)updateViewWithSpotInfo
{
    [Spot fetchSpotInfo:self.spotID User:[User currentlyActiveUser].userID
             completion:^(id results, NSError *error) {
                 //DLog(@"Spot Info - %@",results);
                 if (!error) {
                     if ([results[STATUS] isEqualToString:ALRIGHT]) {
                         self.spotInfo = (NSDictionary *)results;
                         self.spotName =  self.spotNameField.text = self.spotInfo[@"spotName"];
                         
                        self.spotKeyField.text = ([self.spotInfo[@"spotCode"] isEqualToString:@"NONE"])
                         ? @"" : self.spotInfo[@"spotCode"];
                         
                [self.locationNameButton setTitle:self.spotInfo[@"venue"] forState:UIControlStateNormal];
                self.spotDescription.text = (self.spotInfo[@"spotDescription"]) ? self.spotInfo[@"spotDescription"] : @"";
                         
                self.viewPrivacySwitch.on = ([self.spotInfo[@"viewPrivacy"] isEqualToString:sANYONE]) ? NO:YES;
                self.addPrivacySwitch.on = ([self.spotInfo[@"addPrivacy"] isEqualToString:sANYONE]) ? NO:YES;
                self.memberInviteSwitch.on = ([self.spotInfo[@"memberInvitePrivacy"] isEqualToString:sANYONE]) ? NO:YES;
                     }
                 }
                 self.leaveAlbumButton.enabled = YES;
             }];
}




- (IBAction)saveAlbumAction:(UIBarButtonItem *)sender {
    UIActivityIndicatorView *acIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    acIndicator.hidesWhenStopped = YES;
    acIndicator.frame = CGRectMake(135, 150, 30, 30);
    [acIndicator startAnimating];
    //self.saveAlbumSettingsBarItem.
    NSMutableDictionary *spotInfo = [NSMutableDictionary dictionaryWithDictionary:
                                     @{@"userId" : [AppHelper userID],@"spotId": self.spotID}];
    
    if(![self.spotNameField.text isEqualToString:@""] && ![self.spotNameField.text isEqualToString:self.spotInfo[@"spotName"]]){
        self.spotName = self.spotNameField.text;
        [spotInfo addEntriesFromDictionary:@{@"spotName": self.spotName}];
    }
    
    if (![self.spotKeyField.text isEqualToString:@""] && ![self.spotKeyField.text isEqualToString:self.spotInfo[@"spotCode"]]) {
        self.spotKey = self.spotKeyField.text;
        [spotInfo addEntriesFromDictionary:@{@"spotKey": self.spotKey}];
    }
    
    if (![self.locationNameButton.titleLabel.text isEqualToString:@"NONE"]
                && ![self.spotInfo[@"venue"] isEqualToString:@"NONE"]){
        
        self.locationName = self.locationNameButton.titleLabel.text;
        [spotInfo addEntriesFromDictionary:@{@"spotVenue": self.locationName}];
        [spotInfo addEntriesFromDictionary:self.latlng];
    }
    
    if (![self.locationNameButton.titleLabel.text isEqualToString:@"NONE"]
        && ![self.spotInfo[@"venue"] isEqualToString:self.locationNameButton.titleLabel.text]){
        
        self.locationName = self.locationNameButton.titleLabel.text;
        [spotInfo addEntriesFromDictionary:@{@"spotVenue": self.locationName}];
        [spotInfo addEntriesFromDictionary:self.latlng];
    }
    
    
    if (![self.spotDescription.text isEqualToString:@""] && ![self.spotDescription.text isEqualToString:self.spotInfo[@"spotDescription"]]){
        self.spotDesc = self.spotDescription.text;
        [spotInfo addEntriesFromDictionary:@{@"description" : self.spotDesc}];
    }
    
    NSString *viewPrivacy = @"0";
    NSString *addPrivacy = @"0";
    NSString *memberInvitePrivacy = @"0";
    
    
    
    if (!self.addPrivacySwitch.isOn) {
        self.viewPrivacySwitch.on = YES;
    }
    viewPrivacy = (self.viewPrivacySwitch.isOn) ? @"0" : @"1";
    addPrivacy = (self.addPrivacySwitch.isOn) ? @"1" : @"0";
    memberInvitePrivacy = (self.memberInviteSwitch.isOn) ? @"1" : @"0";
    
    [spotInfo addEntriesFromDictionary:@{@"viewSecurity": viewPrivacy,
                                         @"addSecurity" : addPrivacy,
                                         @"memberInvitePrivacy" : memberInvitePrivacy}];
    
    
    [self saveAlbumInfo:spotInfo indicator:acIndicator];
}


- (void)saveAlbumInfo:(NSMutableDictionary *)spotInfo indicator:(id)indicator
{
    //handle the save
    [Spot updateSpotInfo:spotInfo completion:^(id results, NSError *error) {
        
        if (error) {
            DLog(@"Error - %@",error);
        }else{
            //DLog(@"Status - %@",results[STATUS]);
            if ([results[STATUS] isEqualToString:ALRIGHT]) {
                DLog(@"From save - %@",results);
                
                [[NSNotificationCenter defaultCenter]
                 postNotificationName:kUserReloadStreamNotification object:nil];
                
                [indicator stopAnimating];
                //self.navigationItem.title = results[@"spotName"];
                self.spotName = results[@"spotName"];
                // Perform segue to photo stream
                [self performSegueWithIdentifier:@"UnwindToPhotoStreamInfo" sender:nil];
            }
        }
    }];
}


- (IBAction)toggleViewPrivacySwitch:(UISwitch *)sender
{
    if (self.addPrivacySwitch.isOn) {
        self.viewPrivacySwitch.on = sender.on;
    }
    self.saveAlbumSettingsBarItem.enabled = YES;
    
}

- (IBAction)toggleAddPrivacySwitch:(UISwitch *)sender
{
    self.addPrivacySwitch.on = sender.on;
    
    if (!self.addPrivacySwitch.isOn) {
        self.viewPrivacySwitch.on = YES;
        self.viewPrivacySwitch.enabled = NO;
    }else{
        self.viewPrivacySwitch.enabled = YES;
    }
    self.saveAlbumSettingsBarItem.enabled = YES;
}


- (IBAction)toggleMemberInviteSwitch:(UISwitch *)sender
{
    self.memberInviteSwitch.on = sender.on;
    self.saveAlbumSettingsBarItem.enabled = YES;
}

- (IBAction)locationButtonTapped:(id)sender
{
    
}

- (IBAction)leaveAlbumAction:(UIButton *)sender
{
    // This is a destructive action. Prompt the user later before finally deleting the album
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Leave Album" message:@"Are you sure you want to leave this album" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"I'm sure", nil];
    
    [alert show];
    
}

- (IBAction)dismissKeypadOnBackgroundClick:(id)sender
{
    [self.spotNameField resignFirstResponder];
    [self.spotKeyField resignFirstResponder];
    [self.spotDescription resignFirstResponder];
}



#pragma mark - Unwind Segue
- (IBAction)unWindToSpotSettingsFromCancel:(UIStoryboardSegue *)segue{
    
}

-(IBAction)unWindToSpotSettingsFromDone:(UIStoryboardSegue *)segue
{
    FoursquareLocationsViewController *foursquareVC = segue.sourceViewController;
    self.locationName = (foursquareVC.currentLocationSelected == nil) ? self.locationName : foursquareVC.currentLocationSelected;
    
    [self.locationNameButton setTitle:self.locationName forState:UIControlStateNormal];
    self.latlng = @{@"lat": foursquareVC.venueChosen.latitude,@"lng" : foursquareVC.venueChosen.longitude};
    //self.chosenVenueLocation = (foursquareVC.venueChosen == nil) ? self.chosenVenueLocation : foursquareVC.venueChosen;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"ChangeLocationFromSettings"]) {
        self.saveAlbumSettingsBarItem.enabled = YES;
    }
    
}



#pragma mark - AlertView Delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    //DLog(@"button index - %ld",(long)buttonIndex);
    if (buttonIndex == 1) {
        // User surely wants to leave the album
       // DLog(@"User surely wants to leave the album");
        [[User currentlyActiveUser] leaveSpot:self.spotID completion:^(id results, NSError *error) {
            //DLog(@"And back");
            if (!error) {
                if ([results[STATUS] isEqualToString:ALRIGHT]) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:kUserReloadStreamNotification object:nil];
                    [self performSegueWithIdentifier:@"LEAVE_STREAM_SEGUE" sender:nil];
                }
            }
        }];
    }
    
}





@end
