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
#import <MapKit/MapKit.h>

typedef enum {
    kCreate = 0,
    kJoin
} AddStreamType;

@interface CreateSpotViewController ()<UITextFieldDelegate,CLLocationManagerDelegate,UIAlertViewDelegate>
{
    NSString *currentCity;
    NSString *currentCountry;
    NSArray *subaLocations;
}

@property (copy,nonatomic) NSString *streamName;
@property (copy,nonatomic) NSString *streamCode;
@property (copy,nonatomic) NSString *venueForCurrentLocation;
@property (strong,nonatomic) NSMutableArray *otherVenues;
@property (retain,nonatomic) Location *userLocation;
@property (strong,nonatomic) Location *chosenVenueLocation;
@property (strong,nonatomic) NSDictionary *createdSpotDetails;

@property (weak,nonatomic) IBOutlet UIScrollView *createStreamView;
@property (retain,nonatomic) IBOutlet UIView *joinStreamView;
@property (weak, nonatomic) IBOutlet UITextField *streamCodeField;
@property (weak, nonatomic) IBOutlet UIButton *joinStreamButton;
@property (weak, nonatomic) IBOutlet UISegmentedControl *addStreamSegmentedControl;
@property (weak, nonatomic) IBOutlet MKMapView *streamLocationMapView;

@property (weak, nonatomic) IBOutlet UIView *loadingDataView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *joiningSpotIndicator;
@property (weak, nonatomic) IBOutlet UITextField *spotNameField;
@property (weak, nonatomic) IBOutlet UIButton *currentLocationButton;
@property (weak, nonatomic) IBOutlet UIButton *createSpotButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *creatingSpotIndicator;

@property (weak, nonatomic) IBOutlet UITextField *joinSpotId;


- (IBAction)joinStreamAction:(id)sender;
- (IBAction)createSpotAction:(UIButton *)sender;
- (IBAction)dismissKeyPad:(id)sender;
- (IBAction)showNearbyLocations:(id)sender;
- (void)askLocationPermission;
- (void)foursquareVenueMatchingCurrentLocation:(Location *)here;
- (void)displaySubaLocationsMatchingCurrentVenue:(Location *)here;
- (void)joinStream:(NSString *)code;
- (IBAction)unWindToCreateSpotFromCancel:(UIStoryboardSegue *)segue;
- (IBAction)unWindToCreateSpotFromDone:(UIStoryboardSegue *)segue;
- (IBAction)addStreamSegmentChanged:(id)sender;

- (IBAction)dismissVC:(id)sender;
-(void)updateMapView:(MKMapView *)mapView WithLocation:(Location *)location;
@end

@implementation CreateSpotViewController
static CLLocationManager *locationManager;
static CLPlacemark *placemark;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.createSpotButton.enabled = NO;
    self.joinStreamButton.enabled = NO;
    self.joinStreamView.alpha = 0;
    
    [self.currentLocationButton sizeToFit];
    self.currentLocationButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    [self askLocationPermission];
}


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //[self.spotNameField becomeFirstResponder];
    
   
        if ([locationManager location]){
            
            [[[CLGeocoder alloc] init] reverseGeocodeLocation:[locationManager location]
                                            completionHandler:^(NSArray *placemarks, NSError *error) {
                placemark = placemarks[0];
            }];
        }
    
        if (IS_OS_7_OR_BEFORE) {
        DLog(@"IOS 7");
        [locationManager startUpdatingLocation];
    }else if(IS_OS_8_OR_LATER){
        [locationManager requestWhenInUseAuthorization];
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


- (IBAction)joinStreamAction:(id)sender
{
    self.streamCode = self.streamCodeField.text;
    [self joinStream:self.streamCode];
}


-(void)joinStream:(NSString *)code
{
    [AppHelper showLoadingDataView:self.loadingDataView indicator:self.joiningSpotIndicator flag:YES];
    
   
    [[User currentlyActiveUser] joinSpotCompletionCode:code completion:^(id results, NSError *error) {
        DLog(@"Join stream result - %@",results);
        self.streamCodeField.text = kEMPTY_STRING_WITH_SPACE;
        [AppHelper showLoadingDataView:self.loadingDataView
                             indicator:self.joiningSpotIndicator flag:NO];
        
        if ([results[STATUS] isEqualToString:ALRIGHT]){
            
            [Flurry logEvent:@"Join_Stream_With_Code"];
            
            // Joined successfully
            NSString *spotId = [results[@"spotId"] stringValue];
            [[NSNotificationCenter defaultCenter] postNotificationName:kUserReloadStreamNotification object:nil];
            
            [self performSegueWithIdentifier:@"JOIN_STREAM_SEGUE" sender:spotId];
            
        }else {
            // There is no spot with this code
            [AppHelper showAlert:@"Couldn't join stream"
                         message:@"Looks like that code is incorrect. Try again?" buttons:@[@"OK"] delegate:nil];
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
        
    if ([locationManager location]){
        
        if (placemark != nil) {
            NSString *viewPrivacy = @"0";
            NSString *addPrivacy = @"0";
            NSString *spotKey = @"NONE";
            
            self.streamName = self.spotNameField.text;
            User *user = [User currentlyActiveUser];
            Privacy *privacy = [[Privacy alloc] initWithView:viewPrivacy AddPrivacy:addPrivacy];
            Spot *spot = [[Spot alloc] initWithName:self.streamName Key:spotKey Privacy:privacy Location:self.chosenVenueLocation User:user];
            
               
                currentCity = placemark.locality;
                currentCountry = placemark.country;
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

        }else if(placemark == nil){
        
        [[[CLGeocoder alloc] init] reverseGeocodeLocation:[locationManager location] completionHandler:^(NSArray *placemarks, NSError *error) {
            
            NSString *viewPrivacy = @"0";
            NSString *addPrivacy = @"0";
            NSString *spotKey = @"NONE";
            
            self.streamName = self.spotNameField.text;
            User *user = [User currentlyActiveUser];
            Privacy *privacy = [[Privacy alloc] initWithView:viewPrivacy AddPrivacy:addPrivacy];
            Spot *spot = [[Spot alloc] initWithName:self.streamName Key:spotKey Privacy:privacy Location:self.chosenVenueLocation User:user];
            
            
            if (!error){
                CLPlacemark *placemark = placemarks[0];
                //DLog(@"Placemarks - %@",placemark.locality);
                currentCity = placemark.locality;
                currentCountry = placemark.country;
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
                // We could not geocode location
                
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

                //DLog(@"Error - %@",error);
            }
        
        }];
      }
    }
  }
}


- (IBAction)showNearbyLocations:(id)sender
{
    
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
            
            //[self.currentLocationButton setTitle:self.venueForCurrentLocation forState:UIControlStateNormal];
            [self.currentLocationButton sizeToFit];
            self.currentLocationButton.titleLabel.adjustsFontSizeToFitWidth = YES;
        }
    }];
}


- (void)displaySubaLocationsMatchingCurrentVenue:(Location *)here
{
    [[SubaAPIClient sharedInstance] GET:@"location/nearby"
                             parameters:@{@"latitude": here.latitude,@"longitude" : here.longitude}
                                success:^(NSURLSessionDataTask *task,id responseObject){
                                    if ([responseObject[STATUS] isEqualToString:ALRIGHT]) {
                                        DLog(@"Suba Locations - %@",responseObject[@"subaLocations"]);
                                        subaLocations = responseObject[@"subaLocations"];
                                    }
                                } failure:^(NSURLSessionDataTask *task, NSError *error) {
                                    DLog(@"Error - %@",error);
                                }];
}


#pragma mark - Location Manager Delegate
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    
    CLLocation *here = [locations lastObject];
      //DLog(@"new location - %@\n here - %@",self.chosenVenueLocation,here);
    if (here != nil){
        
        if (!self.chosenVenueLocation) {
            NSString *latitude = [NSString stringWithFormat:@"%.8f",here.coordinate.latitude];
            NSString *longitude = [NSString stringWithFormat:@"%.8f",here.coordinate.longitude];
            self.userLocation = [[Location alloc] initWithLat:latitude Lng:longitude];
            
            CLLocationCoordinate2D twoDCordinate = CLLocationCoordinate2DMake([self.userLocation.latitude doubleValue],[self.userLocation.longitude doubleValue]);
            
            // Go to Foursquare for location
            [self foursquareVenueMatchingCurrentLocation:self.userLocation];
            
            [self.streamLocationMapView setCenterCoordinate:twoDCordinate animated:YES];
            [self updateMapView:self.streamLocationMapView WithLocation:self.userLocation];
        }else{
            
           CLLocationCoordinate2D twoDCordinate = CLLocationCoordinate2DMake([self.chosenVenueLocation.latitude doubleValue], [self.chosenVenueLocation.longitude doubleValue]);
            [self.streamLocationMapView setCenterCoordinate:twoDCordinate animated:YES];
            [self updateMapView:self.streamLocationMapView WithLocation:self.chosenVenueLocation];
        }
    }
}


-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    DLog();
    if ([error code] == kCLErrorDenied) {
        //you had denied
        [AppHelper showAlert:@"Location Error" message:[NSString stringWithFormat:@"%@\n",@"Suba does not have access to your location."] buttons:@[@"OK"] delegate:nil];
    }
    
}


-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    DLog();
    if (status == kCLAuthorizationStatusDenied){
        [AppHelper showAlert:@"Location Error" message:[NSString stringWithFormat:@"%@\n%@",@"Suba does not have access to your location.",@"Please go to Settings->Privacy->Location Services and enable location for Suba" ] buttons:@[@"OK"] delegate:nil];
    }
}


-(void)updateMapView:(MKMapView *)mapView WithLocation:(Location *)location
{
    @try {
        CLLocationCoordinate2D twoDCordinate = CLLocationCoordinate2DMake([location.latitude doubleValue], [location.longitude doubleValue]);
        
        MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(twoDCordinate, 500, 500);
        MKCoordinateRegion adjustedRegion = [mapView regionThatFits:viewRegion];
        [mapView setShowsBuildings:YES];
        [mapView setShowsUserLocation:YES];
        [mapView setRegion:adjustedRegion animated:YES];
        
        self.currentLocationButton.alpha = 0.8;

    }
    @catch (NSException *exception) {}
    @finally {}
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
    [textField resignFirstResponder];
    DLog();
    
    if (textField == self.streamCodeField) {
        if (textField.text.length > 0) {
            self.streamCode = textField.text;
            [self joinStream:self.streamCode];
        }
    }else if (textField == self.spotNameField){
        if (([textField.text isEqualToString:@""]) | (textField.text.length == 0)) {
            self.createSpotButton.enabled = NO;
        }else {
            if ([self.currentLocationButton.titleLabel.text isEqualToString:@"Choose Location"]) {
                self.createSpotButton.enabled = NO;
            }else self.createSpotButton.enabled = YES;
        }
    }
    
    return YES;
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    
    if (textField == self.spotNameField && ![textField.text isEqualToString:@""]) {
        if ([self.currentLocationButton.titleLabel.text isEqualToString:@"Choose Location"]) {
            self.createSpotButton.enabled = NO;
        }else self.createSpotButton.enabled = YES;
    }else if (textField == self.streamCodeField && ![textField.text isEqualToString:@""]){
        self.joinStreamButton.enabled = YES;
    }
    
    return YES;
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    if ([segue.identifier isEqualToString:@"NearbyVenuesSegue"]) {
        FoursquareLocationsViewController *nearbyVenuesVC = segue.destinationViewController;
        nearbyVenuesVC.currentLocation = self.userLocation;
        nearbyVenuesVC.locations = self.otherVenues;
        DLog(@"Locations being sent: %@",self.otherVenues);
        nearbyVenuesVC.subaLocations = subaLocations;
        
    }
    
    if ([segue.identifier isEqualToString:@"JOIN_STREAM_SEGUE"]) {
        PhotoStreamViewController *pVC = segue.destinationViewController;
        //pVC.spotName =
        pVC.spotID = sender;
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
    [self.currentLocationButton sizeToFit];
    self.currentLocationButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    
    self.chosenVenueLocation = (foursquareVC.venueChosen == nil) ? self.chosenVenueLocation : foursquareVC.venueChosen;
    [self updateMapView:self.streamLocationMapView WithLocation:self.chosenVenueLocation];
    //DLog(@"Foursquare venue chosen - %@",foursquareVC.venueChosen);
    
    if (self.spotNameField.text.length > 0) {
        self.createSpotButton.enabled = YES;
    }else{
        self.createSpotButton.enabled = NO;
    }
}

- (IBAction)addStreamSegmentChanged:(UISegmentedControl *)sender
{
    if (sender.selectedSegmentIndex == kCreate) {
        self.createStreamView.alpha = 1;
        self.joinStreamView.alpha = 0;
        [self.streamCodeField resignFirstResponder];
    }else if (sender.selectedSegmentIndex == kJoin){
        self.joinStreamView.alpha = 1;
        [self.streamCodeField becomeFirstResponder];
        self.createStreamView.alpha = 0;
    }
}

- (IBAction)dismissVC:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}




- (IBAction)dismissKeyPad:(id)sender
{
    [self.spotNameField resignFirstResponder];
}
@end
