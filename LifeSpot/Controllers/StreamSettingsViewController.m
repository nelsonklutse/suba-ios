//
//  AlbumSettingsViewController.m
//  LifeSpot
//
//  Created by Kwame Nelson on 1/15/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import "StreamSettingsViewController.h"
#import "FoursquareLocationsViewController.h"
#import "MainStreamViewController.h"
#import "Location.h"
#import "Spot.h"
#import "User.h"
#import <MapKit/MapKit.h>

@interface StreamSettingsViewController ()<UITextFieldDelegate,UITextViewDelegate,UIAlertViewDelegate,CLLocationManagerDelegate>


@property (copy,nonatomic) NSString *spotKey;
@property (copy,nonatomic) NSString *locationName;
@property (copy,nonatomic) NSString *spotDesc;
@property (strong,nonatomic) NSString *venueForCurrentLocation;
@property (strong,nonatomic) NSDictionary *latlng;
@property (weak, nonatomic) IBOutlet MKMapView *streamLocationMapView;

@property (weak, nonatomic) IBOutlet UITextField *streamNameField;
@property (weak, nonatomic) IBOutlet UITextField *streamCodeField;
//@property (weak, nonatomic) IBOutlet UITextView *spotDescription;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveAlbumSettingsBarItem;
@property (weak, nonatomic) IBOutlet UIButton *locationNameButton;

//@property (weak, nonatomic) IBOutlet UISwitch *viewPrivacySwitch;
@property (weak, nonatomic) IBOutlet UISwitch *makeStreamPrivateSwitch;
//@property (weak, nonatomic) IBOutlet UISwitch *memberInviteSwitch;
@property (weak, nonatomic) IBOutlet UIButton *leaveAlbumButton;
@property (weak, nonatomic) IBOutlet UIView *loadStreamSettingsIndicatorView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingStreamSettingsOndicator;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;

- (IBAction)unWindToSpotSettingsFromCancel:(UIStoryboardSegue *)segue;
- (IBAction)unWindToSpotSettingsFromDone:(UIStoryboardSegue *)segue;

//- (IBAction)toggleViewPrivacySwitch:(UISwitch *)sender;
- (IBAction)toggleMakeStreamPrivateSwitch:(UISwitch *)sender;
- (IBAction)saveAlbumAction:(UIBarButtonItem *)sender;
//- (IBAction)toggleMemberInviteSwitch:(id)sender;
- (IBAction)locationButtonTapped:(id)sender;
- (IBAction)leaveAlbumAction:(UIButton *)sender;
- (IBAction)dismissKeypadOnBackgroundClick:(id)sender;
- (IBAction)deleteStreamAction:(id)sender;

- (void)updateViewWithSpotInfo;
- (void)disableViews;
- (void)saveAlbumInfo:(NSMutableDictionary *)spotInfo indicator:(id)indicator;
- (BOOL)canUserDeleteStream;
@end

@implementation StreamSettingsViewController
static CLLocationManager *locationManager;
- (void)viewDidLoad
{
    [super viewDidLoad];
	
    self.streamCreator = self.spotInfo[@"userName"];
    DLog(@"Stream creator - %@",self.streamCreator);
    self.streamNameField.adjustsFontSizeToFitWidth = YES;
    self.streamCodeField.adjustsFontSizeToFitWidth = YES;
    self.locationNameButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    
    self.saveAlbumSettingsBarItem.enabled = NO;
    // self.navigationItem.title = self.spotName
    
    [self updateViewWithSpotInfo];
    
    /*if (!self.addPrivacySwitch.isOn) {
        self.viewPrivacySwitch.on = YES;
        self.viewPrivacySwitch.enabled = NO;
    }*/
    
    self.leaveAlbumButton.enabled = NO;
    //self.deleteButton.enabled = NO;
    //DLog(@"Stream info - %@",self.spotInfo);
    
    if (![self.spotInfo[@"userName"] isEqualToString:[AppHelper userName]]) {
      //  DLog(@"Stream creator - %@\nUser name - %@",self.spotInfo[@"userName"],[AppHelper userName]);
        
        // User did not create this album so disable stuff that he should not do
        [self disableViews];
        self.leaveAlbumButton.hidden = NO;
        [self.view viewWithTag:100].hidden = NO;
    }else{
        self.leaveAlbumButton.hidden = YES;
        [self.view viewWithTag:100].hidden = YES;
    }
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.streamCreator = self.spotInfo[@"userName"];
}


-(void)askLocationPermission
{
    if ([CLLocationManager locationServicesEnabled]){
        //if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized){
        
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        if (IS_OS_7_OR_BEFORE) {
            DLog(@"IOS 7");
            [locationManager startUpdatingLocation];
        }else if(IS_OS_8_OR_LATER){
            [locationManager requestWhenInUseAuthorization];
        }
        
        //}
    }
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
    // Show activity indicator
    [AppHelper showLoadingDataView:self.loadStreamSettingsIndicatorView
                         indicator:self.loadingStreamSettingsOndicator flag:YES];
    
    [Spot fetchSpotInfo:self.spotID
             completion:^(id results, NSError *error){
                 
                 [AppHelper showLoadingDataView:self.loadStreamSettingsIndicatorView indicator:self.loadingStreamSettingsOndicator flag:NO];
                 
                 if (!error){
                     if([results[STATUS] isEqualToString:ALRIGHT]) {
                       self.spotInfo = (NSDictionary *)results;
                       DLog(@"SpotInfo: %@",self.spotInfo);
                       self.spotName =  self.streamNameField.text = self.spotInfo[@"spotName"];
                       self.streamCodeField.text = ([self.spotInfo[@"spotCode"] isEqualToString:@"NONE"])
                         ? @"" : self.spotInfo[@"spotCode"];
                
                [self.locationNameButton setTitle:self.spotInfo[@"venue"] forState:UIControlStateNormal];
                [self.locationNameButton setTitle:self.spotInfo[@"venue"] forState:UIControlStateDisabled];
                self.makeStreamPrivateSwitch.on=([self.spotInfo[@"addPrivacy"] isEqualToString:sANYONE])?NO:YES;
                         
                //self.spotDescription.text = (self.spotInfo[@"spotDescription"]) ? self.spotInfo[@"spotDescription"] : @"";
                         
                /*self.viewPrivacySwitch.on = ([self.spotInfo[@"viewPrivacy"] isEqualToString:sANYONE]) ? YES : NO;
                                self.memberInviteSwitch.on = ([self.spotInfo[@"memberInvitePrivacy"]
                                               isEqualToString:sANYONE]) ? YES : NO;*/
                         
                if (![self.spotInfo[@"userName"] isEqualToString:[AppHelper userName]]){
                    
                    // User did not create this album so disable stuff that he should not do
                        [self disableViews];
                        self.leaveAlbumButton.hidden = NO;
                        [self.view viewWithTag:100].hidden = NO;
                             
                         }else{ // If user is creator
                             self.leaveAlbumButton.hidden = YES;
                             [self.view viewWithTag:100].hidden = YES;
                             
                             if ([self canUserDeleteStream]) {
                                  self.deleteButton.hidden = NO;
                                }else{
                                 self.deleteButton.hidden = YES;
                             }
                           }
                        }
                     
                            self.leaveAlbumButton.enabled = YES;
                 }else{
                     
                     [AppHelper showAlert:@"Stream Settings Error"
                                  message:error.localizedDescription
                                  buttons:@[@"OK"]
                                 delegate:nil];
                 }
                 
             }];
 }




- (IBAction)saveAlbumAction:(UIBarButtonItem *)sender {
    
    UIActivityIndicatorView *acIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    acIndicator.hidesWhenStopped = YES;
    acIndicator.frame = CGRectMake(135, 150, 30, 30);
    [acIndicator startAnimating];
    NSMutableDictionary *spotInfo = [NSMutableDictionary dictionaryWithDictionary:
                                     @{@"userId" : [AppHelper userID],@"spotId": self.spotID}];
    
    if(![self.streamNameField.text isEqualToString:@""] && ![self.streamNameField.text isEqualToString:self.spotInfo[@"spotName"]]){
        self.spotName = self.streamNameField.text;
        [spotInfo addEntriesFromDictionary:@{@"spotName": self.spotName}];
    }
    
    //if (![self.streamCodeField.text isEqualToString:self.spotInfo[@"spotCode"]]){
        self.spotKey = self.streamCodeField.text;
        [spotInfo addEntriesFromDictionary:@{@"spotKey": self.spotKey}];
    //}
    
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
    
    
    /*if (![self.spotDescription.text isEqualToString:@""] && ![self.spotDescription.text isEqualToString:self.spotInfo[@"spotDescription"]]){
        //self.spotDesc = self.spotDescription.text;
        [spotInfo addEntriesFromDictionary:@{@"description" : self.spotDesc}];
    }*/
    
    //NSString *viewPrivacy = @"0";
    NSString *makeStreamPrivateSwitch = @"0";
    //NSString *memberInvitePrivacy = @"0";
    
    
    
    /*if (!self.makeStreamPrivateSwitch.isOn) {
        self.makeStreamPrivateSwitch.on = YES;
    }*/
    
    //viewPrivacy = (self.viewPrivacySwitch.isOn) ? @"0" : @"1";
    makeStreamPrivateSwitch = (self.makeStreamPrivateSwitch.isOn) ? @"1" : @"0";
    //memberInvitePrivacy = (self.memberInviteSwitch.isOn) ? @"0" : @"1";
    
    [spotInfo addEntriesFromDictionary:@{@"addSecurity" : makeStreamPrivateSwitch}];
    
    
    [self saveAlbumInfo:spotInfo indicator:acIndicator];
}


- (void)saveAlbumInfo:(NSMutableDictionary *)spotInfo indicator:(id)indicator
{
    DLog(@"Spot Info - %@",spotInfo);
    
    //handle the save
    [Spot updateSpotInfo:spotInfo completion:^(id results, NSError *error) {
        
        if (error) {
            DLog(@"Error - %@",error);
        }else{
            //DLog(@"Status - %@",results[STATUS]);
            if ([results[STATUS] isEqualToString:ALRIGHT]) {
                DLog(@"New album Settings - %@",results);
                
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

-(BOOL)canUserDeleteStream
{
    NSArray *members = self.spotInfo[@"members"];
    NSInteger photos = [self.spotInfo[@"numberOfPhotos"] integerValue];
    
    if ([members count] == 1 || photos == 0){ // There are no members in this stream
        return YES;
        // Show delete stream button
    }
    /*else if(photos == 0){ // There are no photos in this stream
        // Show delete stream button
        return YES;
    }*/
    
    return NO;
}

-(void)disableViews
{
    self.streamNameField.enabled = NO;
    self.streamCodeField.enabled = NO;
    self.locationNameButton.enabled = NO;
    self.makeStreamPrivateSwitch.enabled = NO;
    
    //self.viewPrivacySwitch.enabled = NO;
    //self.memberInviteSwitch.enabled = NO;
}


/*- (IBAction)toggleViewPrivacySwitch:(UISwitch *)sender
{
    if (self.addPrivacySwitch.isOn) {
        self.viewPrivacySwitch.on = sender.on;
    }
    
    self.saveAlbumSettingsBarItem.enabled = YES;
}*/

- (IBAction)toggleMakeStreamPrivateSwitch:(UISwitch *)sender
{
    self.makeStreamPrivateSwitch.on = sender.on;
    
    // Show alert to user here
    UIAlertView *privacyAlertView = [[UIAlertView alloc]
                                     initWithTitle:@"Private Stream"
                                     message:@"Private streams do not show in nearby"
                                     delegate:self
                                     cancelButtonTitle:@"Cancel"
                                     otherButtonTitles:@"Make Private", nil];
    
    privacyAlertView.tag = 10000;
    [privacyAlertView show];
    
    
    self.saveAlbumSettingsBarItem.enabled = YES;
}


/*- (IBAction)toggleMemberInviteSwitch:(UISwitch *)sender
{
    self.memberInviteSwitch.on = sender.on;
    self.saveAlbumSettingsBarItem.enabled = YES;
}*/


- (IBAction)locationButtonTapped:(id)sender
{
    
}

- (IBAction)leaveAlbumAction:(UIButton *)sender
{
    // This is a destructive action. Prompt the user before he leaves the album
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Leave Stream"
                                                    message:@"Are you sure you want to leave this stream? It will no longer display in the My Streams view."
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"I'm sure", nil];
    
    alert.tag = 5000;
    [alert show];
    
}

- (IBAction)dismissKeypadOnBackgroundClick:(id)sender
{
    [self.streamNameField resignFirstResponder];
    [self.streamCodeField resignFirstResponder];
    //[self.spotDescription resignFirstResponder];
}

- (IBAction)deleteStreamAction:(id)sender {
    // This is a destructive action. Prompt the user later before finally deleting the album
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Delete Stream" message:@"Are you sure you want to delete this stream?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"I'm sure", nil];
    
    alert.tag = 2000;
    [alert show];

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
    if (alertView.tag == 5000){
        if (buttonIndex == 1){
            // User surely wants to leave the stream
            
            [[User currentlyActiveUser] leaveSpot:self.spotID completion:^(id results, NSError *error) {
                
                if (!error) {
                    [Flurry logEvent:@"Leave_Stream"];
                    if ([results[STATUS] isEqualToString:ALRIGHT]) {
                        DLog(@"where to unwind: %@",[self.whereToUnwind class]);
                        if ([self.whereToUnwind class] == [MainStreamViewController class]){
                            [self performSegueWithIdentifier:@"LEAVE_STREAM_SEGUE" sender:nil];
                        }else{
                            //[[NSNotificationCenter defaultCenter] postNotificationName:kUserReloadStreamNotification object:nil];
                            [self performSegueWithIdentifier:@"DELETE_STREAM_TO_USERPROFILE" sender:nil];
                        }
                    }
                }
            }];
        }
        
    }else if (alertView.tag == 2000){ // We are deleting a stream
        if(buttonIndex == 1){
            
            [[User currentlyActiveUser] deleteStream:self.spotID completion:^(id results, NSError *error) {
                
                if (!error){
                    
                    [Flurry logEvent:@"Stream_Deleted"];
                    
                    if ([results[STATUS] isEqualToString:ALRIGHT]){
                        
                        DLog(@"where to unwind: %@",[self.whereToUnwind class]);
                        
                        if ([self.whereToUnwind class] == [MainStreamViewController class]){
                            [self performSegueWithIdentifier:@"LEAVE_STREAM_SEGUE" sender:nil];
                        }else{
                           //[[NSNotificationCenter defaultCenter] postNotificationName:kUserReloadStreamNotification object:nil];
                           [self performSegueWithIdentifier:@"DELETE_STREAM_TO_USERPROFILE" sender:nil]; 
                        }
                    }
                }
            }];
        }
        
    }else if (alertView.tag == 10000){
        if (buttonIndex == 0){
            // User cancelled making a stream private
            self.makeStreamPrivateSwitch.on = NO;
        }else{
            self.makeStreamPrivateSwitch.on = YES;
        }
        
    }
}


#pragma mark - Location Manager Delegate
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    
    CLLocation *here = [locations lastObject];
    if (here != nil){
        
        
            NSString *latitude = [NSString stringWithFormat:@"%.8f",here.coordinate.latitude];
            NSString *longitude = [NSString stringWithFormat:@"%.8f",here.coordinate.longitude];
        
            Location *userLocation = [[Location alloc] initWithLat:latitude Lng:longitude];
            
            CLLocationCoordinate2D twoDCordinate = CLLocationCoordinate2DMake([userLocation.latitude doubleValue],[userLocation.longitude doubleValue]);
            
        
            [self.streamLocationMapView setCenterCoordinate:twoDCordinate animated:YES];
            [self updateMapView:self.streamLocationMapView WithLocation:userLocation];
        }
}


-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    if ([error code] == kCLErrorDenied) {
        //you had denied
        [AppHelper showAlert:@"Location Error" message:[NSString stringWithFormat:@"%@\n%@",@"Suba does not have access to your location.",@"Please go to Settings->Privacy->Location Services and enable location for Suba" ] buttons:@[@"OK"] delegate:nil];
    }
    
}

-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusDenied){
        
        [AppHelper showAlert:@"Location Error" message:[NSString stringWithFormat:@"%@\n%@",@"Suba does not have access to your location.",@"Please go to Settings->Privacy->Location Services and enable location for Suba" ] buttons:@[@"OK"] delegate:nil];
    }
}


-(void)updateMapView:(MKMapView *)mapView WithLocation:(Location *)location
{
    
    CLLocationCoordinate2D twoDCordinate = CLLocationCoordinate2DMake([location.latitude doubleValue], [location.longitude doubleValue]);
    
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(twoDCordinate, 500, 500);
    MKCoordinateRegion adjustedRegion = [mapView regionThatFits:viewRegion];
    [mapView setShowsBuildings:YES];
    [mapView setShowsUserLocation:YES];
    [mapView setRegion:adjustedRegion animated:YES];
    
    self.locationNameButton.alpha = 0.8;
}



@end
