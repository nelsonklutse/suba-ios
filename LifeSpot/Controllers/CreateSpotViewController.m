//
//  CreateSpotViewController.m
//  LifeSpot
//
//  Created by Kwame Nelson on 1/7/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import "CreateSpotViewController.h"
#import "FoursquareLocationsViewController.h"
#import "PhotoStreamViewController.h"
#import "Location.h"
#import "User.h"
#import "Privacy.h"
#import "Spot.h"

@interface CreateSpotViewController ()<UITextFieldDelegate,CLLocationManagerDelegate,UIAlertViewDelegate>{
    NSString *currentCity;
    NSString *currentCountry;
    NSArray *subaLocations;
}

@property (copy,nonatomic) NSString *spotName;
@property (copy,nonatomic) NSString *venueForCurrentLocation;
@property (strong,nonatomic) NSArray *otherVenues;
@property (retain,nonatomic) Location *userLocation;
@property (strong,nonatomic) Location *chosenVenueLocation;
@property (strong,nonatomic) NSDictionary *createdSpotDetails;

@property (weak, nonatomic) IBOutlet UIView *loadingDataView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *joiningSpotIndicator;
@property (weak, nonatomic) IBOutlet UITextField *spotNameField;
@property (weak, nonatomic) IBOutlet UIButton *currentLocationButton;
@property (weak, nonatomic) IBOutlet UIButton *createSpotButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *creatingSpotIndicator;
@property (weak, nonatomic) IBOutlet UITextField *joinSpotId;


- (IBAction)joinSpotAction:(id)sender;
- (IBAction)createSpotAction:(UIButton *)sender;
- (IBAction)dismissKeyPad:(id)sender;
- (IBAction)showNearbyLocations:(id)sender;
- (void)askLocationPermission;
- (void)foursquareVenueMatchingCurrentLocation:(Location *)here;
- (void)displaySubaLocationsMatchingCurrentVenue:(Location *)here;
- (void)joinStream:(NSString *)code;
- (IBAction)unWindToCreateSpotFromCancel:(UIStoryboardSegue *)segue;
- (IBAction)unWindToCreateSpotFromDone:(UIStoryboardSegue *)segue;
@end

@implementation CreateSpotViewController
static CLLocationManager *locationManager;


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.createSpotButton.enabled = NO;
    
    [self askLocationPermission];
}


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.spotNameField becomeFirstResponder];
    
    if (locationManager) {
        [locationManager startUpdatingLocation];
    }
    
    [Flurry logEvent:@"Create_Stream_Button_Tapped"];
}


-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [locationManager stopUpdatingLocation];
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)joinSpotAction:(id)sender
{
    
   UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Join A Stream" message:@"Enter code for the stream you want to join" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Join", nil];
    
    alertView.alertViewStyle = UIAlertViewStyleSecureTextInput;
    
    
    [alertView show];
    //[self performSegueWithIdentifier:@"JOIN_STREAM_SEGUE" sender:@"1"];
    
}


-(void)joinStream:(NSString *)code
{
    [AppHelper showLoadingDataView:self.loadingDataView indicator:self.joiningSpotIndicator flag:YES];
    
    DLog(@"joining");
    [[User currentlyActiveUser] joinSpotCompletionCode:code completion:^(id results, NSError *error) {
        DLog(@"Result - %@",results);
        [AppHelper showLoadingDataView:self.loadingDataView
                             indicator:self.joiningSpotIndicator flag:NO];
        
        if ([results[STATUS] isEqualToString:ALRIGHT]){
            
            [Flurry logEvent:@"Join_Stream_With_Code"];
            
            // Joined successfully
            NSString *spotId = [results[@"spotId"] stringValue];
            [[NSNotificationCenter defaultCenter] postNotificationName:kUserReloadStreamNotification object:nil];
            
            [self performSegueWithIdentifier:@"JOIN_STREAM_SEGUE" sender:spotId];
            
        }else if ([results[STATUS] isEqualToString:@"error"]){
            // There is no spot with this code
            [AppHelper showNotificationWithMessage:@"We could not find a stream with the entered code"
                                              type:kSUBANOTIFICATION_ERROR
                                  inViewController:self
                                   completionBlock:nil];
        }
        
        
    }];
    
}



- (IBAction)createSpotAction:(UIButton *)sender {
    // Log this event with Flurry
    [Flurry logEvent:@"Create_Stream_Action"];
    
    
    // 1. View Privacy  2. Add Privacy 3. Location 4.
    [self.creatingSpotIndicator startAnimating];
    if ([CLLocationManager locationServicesEnabled] && [CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
        [AppHelper showAlert:@"Location Error" message:[NSString stringWithFormat:@"%@\n%@",@"Suba does not have access to your location.",@"To create a stream, go to Settings->Privacy->Location Services and enable location for Suba" ] buttons:@[@"OK"] delegate:nil];
    }else{
    if ([locationManager location]) {
        [[[CLGeocoder alloc] init] reverseGeocodeLocation:[locationManager location] completionHandler:^(NSArray *placemarks, NSError *error) {
            
            if (!error) {
                CLPlacemark *placemark = placemarks[0];
                //DLog(@"Placemarks - %@",placemark.locality);
                currentCity = placemark.locality;
                currentCountry = placemark.country;
                
                NSString *viewPrivacy = @"0";
                NSString *addPrivacy = @"0";
                NSString *spotKey = @"NONE";
                
                self.spotName = self.spotNameField.text;
                
                User *user = [User currentlyActiveUser];
                Privacy *privacy = [[Privacy alloc] initWithView:viewPrivacy AddPrivacy:addPrivacy];
                Spot *spot = [[Spot alloc] initWithName:self.spotName Key:spotKey Privacy:privacy Location:self.chosenVenueLocation User:user];
                self.chosenVenueLocation.city = currentCity;
                self.chosenVenueLocation.country = currentCountry;
                
                [user createSpot:spot completion:^(id results, NSError *error) {
                    [self.creatingSpotIndicator stopAnimating];
                    if (!error){
                        
                        // There were no errors
                        self.createdSpotDetails = (NSDictionary *)results;
                        [self performSegueWithIdentifier:@"spotWasCreatedSegue" sender:nil];
                        
                        [[NSNotificationCenter defaultCenter] postNotificationName:kUserReloadStreamNotification object:nil];
                    }else{
                        DLog(@"Error - %@",error);
                    }
                }];
                
            }else{
                DLog(@"Error - %@",error);
            }
            
        }];
    }
  }
}


- (IBAction)showNearbyLocations:(id)sender
{
    
}


-(void)askLocationPermission
{
    if ([CLLocationManager locationServicesEnabled]){
        //if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied){
            
            locationManager = [[CLLocationManager alloc] init];
            locationManager.delegate = self;
            [locationManager startUpdatingLocation];
            
       // }
    }
}


-(void)foursquareVenueMatchingCurrentLocation:(Location *)currentLocation{
    [currentLocation showBestMatchingFoursquareVenueCriteria:@"ll" completion:^(id results, NSError *error) {
        
        if (!error) {
            self.otherVenues = [[results objectForKey:@"response"] objectForKey:@"venues"];
            NSString *latitude = [[self.otherVenues[0] objectForKey:@"location"] objectForKey:@"lat"];
            NSString *longitude = [[self.otherVenues[0] objectForKey:@"location"] objectForKey:@"lng"];
            NSString *city = [[self.otherVenues[0] objectForKey:@"location"] objectForKey:@"city"];
            NSString *country = [[self.otherVenues[0] objectForKey:@"location"] objectForKey:@"country"];
            self.venueForCurrentLocation = [[[results objectForKey:@"response"] objectForKey:@"venues"][0] objectForKey:@"name"];
            
            //DLog(@"Foursquare Venue Matching User's current Location:\nName - %@\nAll locations - %@\nLat - %@\nLng - %@",self.venueForCurrentLocation,[[results objectForKey:@"response"] objectForKey:@"venues"],latitude,longitude);
            self.chosenVenueLocation = [[Location alloc] initWithLat:latitude Lng:longitude PrettyName:self.venueForCurrentLocation];
            self.chosenVenueLocation.city = (city != nil) ? city : nil ;
            self.chosenVenueLocation.country = (country != nil) ? country : nil;
            //DLog(@"Chosen Venue details - %@",self.chosenVenueLocation);
            
            [self.currentLocationButton setTitle:self.venueForCurrentLocation forState:UIControlStateNormal];
        }
    }];
}


- (void)displaySubaLocationsMatchingCurrentVenue:(Location *)here
{
    [[SubaAPIClient sharedInstance] GET:@"location/nearby"
                             parameters:@{@"latitude": here.latitude,@"longitude" : here.longitude}
                                success:^(NSURLSessionDataTask *task,id responseObject){
                                    if ([responseObject[STATUS] isEqualToString:ALRIGHT]) {
                                        //DLog(@"Suba Locations - %@",responseObject[@"subaLocations"]);
                                        subaLocations = responseObject[@"subaLocations"];
                                    }
                                } failure:^(NSURLSessionDataTask *task, NSError *error) {
                                    DLog(@"Error - %@",error);
                                }];
}



-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    
    CLLocation *here = [locations lastObject];
    
    if (here != nil){
        if (!self.chosenVenueLocation) {
            NSString *latitude = [NSString stringWithFormat:@"%.8f",here.coordinate.latitude];
            NSString *longitude = [NSString stringWithFormat:@"%.8f",here.coordinate.longitude];
            self.userLocation = [[Location alloc] initWithLat:latitude Lng:longitude];
            
            // Go to Foursquare for location
            [self foursquareVenueMatchingCurrentLocation:self.userLocation];
        }
        
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

#pragma mark - AlertView Delegate Methods
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1){
        
        NSString *passcode = [alertView textFieldAtIndex:0].text;
        
        [alertView dismissWithClickedButtonIndex:buttonIndex animated:YES];
        
        [self performSelector:@selector(joinStream:) withObject:passcode afterDelay:1.0];
    }
}




#pragma mark - TextField Delegate Methods
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.spotNameField resignFirstResponder];
    return YES;
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    if (![textField.text isEqualToString:@""]) {
        self.createSpotButton.enabled = YES;
    }
    
    return YES;
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    if ([segue.identifier isEqualToString:@"NearbyVenuesSegue"]) {
        FoursquareLocationsViewController *nearbyVenuesVC = segue.destinationViewController;
        nearbyVenuesVC.currentLocation = self.userLocation;
        nearbyVenuesVC.locations = self.otherVenues;
        nearbyVenuesVC.subaLocations = subaLocations;
        
    }
    
    if ([segue.identifier isEqualToString:@"JOIN_STREAM_SEGUE"]) {
        PhotoStreamViewController *pVC = segue.destinationViewController;
        
        pVC.spotID = sender;
        //DLog(@"SpotID - %@",pVC.spotID);
    }
}

#pragma mark - Unwind Segue
- (IBAction)unWindToCreateSpotFromCancel:(UIStoryboardSegue *)segue
{
}

-(IBAction)unWindToCreateSpotFromDone:(UIStoryboardSegue *)segue
{
    FoursquareLocationsViewController *foursquareVC = segue.sourceViewController;
    self.venueForCurrentLocation = (foursquareVC.currentLocationSelected == nil) ? self.venueForCurrentLocation : foursquareVC.currentLocationSelected;
    
    [self.currentLocationButton setTitle:self.venueForCurrentLocation forState:UIControlStateNormal];
    self.chosenVenueLocation = (foursquareVC.venueChosen == nil) ? self.chosenVenueLocation : foursquareVC.venueChosen;
    DLog(@"Foursquare venue chosen - %@",foursquareVC.venueChosen);
}




- (IBAction)dismissKeyPad:(id)sender
{
    [self.spotNameField resignFirstResponder];
}
@end
