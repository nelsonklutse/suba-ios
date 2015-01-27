//
//  CreateStreamViewController.m
//  LifeSpot
//
//  Created by Kwame Nelson on 5/25/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import "CreateStreamViewController.h"
#import "PhotoStreamViewController.h"
#include "FoursquareLocationsViewController.h"
#import "User.h"
#import "Location.h"
#import "Privacy.h"
#import "Spot.h"
#import <MapKit/MapKit.h>

typedef enum {
    kCreate = 0,
    kJoin
} AddStreamType;

@interface CreateStreamViewController ()<UITextFieldDelegate,CLLocationManagerDelegate>{
    NSString *currentCity;
    NSString *currentCountry;
    NSArray *subaLocations;
}


@property (weak, nonatomic) IBOutlet UIView *locationPermissionView;
@property (weak, nonatomic) IBOutlet UITextField *streamNameField;
@property (weak, nonatomic) IBOutlet UIButton *createStreamButton;
@property (weak, nonatomic) IBOutlet UIButton *chooseLocationButton;

@property (copy,nonatomic) NSString *streamCode;
@property (strong,nonatomic) NSDictionary *createdStreamDetails;
@property (strong,nonatomic) NSMutableArray *allVenues;
@property (strong,nonatomic) CLLocation *currentLocation;
@property (strong,nonatomic) NSString *venueForCurrentLocation;
@property (strong,nonatomic) Location *chosenVenueLocation;

@property (weak, nonatomic) IBOutlet UIView *creatingStreamIndicatorView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *createStreamIndicator;
@property (weak, nonatomic) IBOutlet UISegmentedControl *addStreamSegmentedControl;
@property (weak, nonatomic) IBOutlet UIView *joinStreamView;
@property (weak, nonatomic) IBOutlet UIScrollView *createStreamView;
@property (weak, nonatomic) IBOutlet MKMapView *streamLocationMapView;
@property (weak, nonatomic) IBOutlet UITextField *streamCodeField;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *joiningStreamIndicator;

- (IBAction)createStreamWithInfo:(id)sender;
- (IBAction)pickLocation:(id)sender;
- (IBAction)addLocationLater:(id)sender;
- (IBAction)grantLocationPermission:(id)sender;

- (void)venueForCurrentLocation:(Location *)location;
- (void)updateMapView:(MKMapView *)mapView WithLocation:(CLLocation *)location;

- (IBAction)dismissVC:(id)sender;
- (IBAction)addStreamSegmentChanged:(UISegmentedControl *)sender;

- (IBAction)joinStreamAction:(id)sender;
- (IBAction)unwindToCreateStreamFromCancel:(UIStoryboardSegue *)segue;
- (IBAction)unWindToCreateStreamFromDone:(UIStoryboardSegue *)segue;

@end

@implementation CreateStreamViewController

static CLLocationManager *locationManager;

-(void)unwindToCreateStreamFromCancel:(UIStoryboardSegue *)segue
{
    
}

-(IBAction)unWindToCreateStreamFromDone:(UIStoryboardSegue *)segue
{
    FoursquareLocationsViewController *foursquareVC = segue.sourceViewController;
    self.venueForCurrentLocation = (foursquareVC.currentLocationSelected == nil) ? self.venueForCurrentLocation : foursquareVC.currentLocationSelected;
    
    [self.chooseLocationButton setTitle:self.venueForCurrentLocation forState:UIControlStateNormal];
    self.chosenVenueLocation = (foursquareVC.venueChosen == nil) ? self.chosenVenueLocation : foursquareVC.venueChosen;
    DLog(@"Foursquare venue chosen - %@",foursquareVC.venueChosen);
    if (self.streamNameField.text.length > 0) {
        self.createStreamButton.enabled = YES;
    }else{
        self.createStreamButton.enabled = NO;
    }
    

}



- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.locationPermissionView.alpha = 0;
    self.streamNameField.text = self.streamName;
    
    self.createStreamButton.enabled = NO;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
   /* if (locationManager != nil) {
        self.currentLocation = [locationManager location];
        if (self.currentLocation != nil){
            Location *location = [[Location alloc] initWithLat:[NSString stringWithFormat:@"%f",self.currentLocation.coordinate.latitude] Lng:[NSString stringWithFormat:@"%f",self.currentLocation.coordinate.longitude]];
            
            [self venueForCurrentLocation:location];
        }

    }*/
   
    self.navigationItem.title = @"Create Stream";
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

- (IBAction)createStreamWithInfo:(id)sender
{
    //User *currentuser = [User currentlyActiveUser];
    //Spot *spot = [Spot all
    /*currentuser createSpot:<#(Spot *)#> completion:^(id results, NSError *error) {
        <#code#>
    }];*/
    NSDictionary *info = @{@"venue": self.venueForCurrentLocation,@"name":self.streamName};
    DLog(@"Info - %@",info);
    
    // Create stream and then go to PhotoStreamVC
    // Log this event with Flurry
    [Flurry logEvent:@"Create_Stream_Action"];
    
    
    // 1. View Privacy  2. Add Privacy 3. Location
    [AppHelper showLoadingDataView:self.creatingStreamIndicatorView
                         indicator:self.createStreamIndicator flag:YES];
    if ([CLLocationManager locationServicesEnabled] && [CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
        [AppHelper showAlert:@"Oops!" message:[NSString stringWithFormat:@"%@\n%@",@"Suba does not have access to your location.",@"To create a stream, go to Settings->Privacy->Location Services and enable location for Suba" ] buttons:@[@"OK"] delegate:nil];
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
                    
                    self.streamName = self.streamNameField.text;
                    
                    User *user = [User currentlyActiveUser];
                    Privacy *privacy = [[Privacy alloc] initWithView:viewPrivacy AddPrivacy:addPrivacy];
                    Spot *spot = [[Spot alloc] initWithName:self.streamName Key:spotKey Privacy:privacy Location:self.chosenVenueLocation User:user];
                    self.chosenVenueLocation.city = currentCity;
                    self.chosenVenueLocation.country = currentCountry;
                    
                    [user createSpot:spot completion:^(id results, NSError *error) {
                        //[self.creatingSpotIndicator stopAnimating];
                        if (!error){
                            [AppHelper showLoadingDataView:self.creatingStreamIndicatorView
                                                 indicator:self.createStreamIndicator flag:NO];
                            // There were no errors
                            self.createdStreamDetails = (NSDictionary *)results;
                            DLog(@"Created stream details - %@",self.createdStreamDetails);
                            [self performSegueWithIdentifier:@"PhotoStreamSegue"
                                                      sender:self.createdStreamDetails];
                            
                            [[NSNotificationCenter defaultCenter] postNotificationName:kUserReloadStreamNotification object:nil];
                        }else{
                           // DLog(@"Error - %@",error);
                            [AppHelper showAlert:@"Oops!"
                                         message:@"Something went wrong. Try again?"
                                         buttons:@[@"OK"] delegate:nil];
                        }
                    }];
                    
                }else{
                   // DLog(@"Error - %@",error);
                    [AppHelper showAlert:@"Error" message:error.localizedDescription buttons:@[@"OK"] delegate:nil];
                }
                
            }];
        }
    }

}

- (IBAction)pickLocation:(id)sender
{
    if (!locationManager) {
        [UIView animateWithDuration:.5 animations:^{
            self.locationPermissionView.alpha = 1;
        }];
      
    }else{
        // Show foursquare Location to choose
        DLog(@"Showing Foursquare venues");
        [self performSegueWithIdentifier:@"ChooseStreamLocationSegue" sender:nil];
    }
   
    
}


-(IBAction)grantLocationPermission:(id)sender
{
    if ([CLLocationManager locationServicesEnabled]){
        
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        [locationManager startUpdatingLocation];
        
        
    }else{
        [AppHelper showAlert:@"Location Services Disabled"
                message:@"Location services is disabled for this app. Please enable location services to see nearby spots" buttons:@[@"OK"] delegate:nil];
        //locationEnabled = NO;
    }
    
    self.locationPermissionView.alpha = 0;
}


- (IBAction)addLocationLater:(id)sender
{
    [UIView animateWithDuration:.5 animations:^{
        self.locationPermissionView.alpha = 0;
    }];
  
}


#pragma mark - Location Manager Delegate
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
   
    self.currentLocation = [locations lastObject];
    
    if (self.currentLocation != nil){
        
        Location *location = [[Location alloc] initWithLat:[NSString stringWithFormat:@"%f",self.currentLocation.coordinate.latitude] Lng:[NSString stringWithFormat:@"%f",self.currentLocation.coordinate.longitude]];
        
        CLLocationCoordinate2D twoDCordinate = CLLocationCoordinate2DMake(self.currentLocation.coordinate.latitude, self.currentLocation.coordinate.longitude);
    
        
        [self venueForCurrentLocation:location];
        [self.streamLocationMapView setCenterCoordinate:twoDCordinate animated:YES];
        [self updateMapView:self.streamLocationMapView WithLocation:self.currentLocation];
   }
}


- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error
{
    //DLog(@"Error while getting core location : %@",[error localizedFailureReason]);
    if ([error code] == kCLErrorDenied) {
        //you had denied
        [AppHelper showAlert:@"Location Error" message:@"Suba does not have access to your location.In order to see locations to watch, go to Settings->Privacy->Location Services and enable location for Suba" buttons:@[@"OK"] delegate:nil];
    }
    //[manager stopUpdatingLocation];
}


-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusDenied){
        
        [AppHelper showAlert:@"Location Error"
                     message:[NSString stringWithFormat:@"%@\n%@",@"Suba does not have access to your location.",@"In order to see locations to watch, go to Settings->Privacy->Location Services and enable location for Suba"]
         
                     buttons:@[@"OK"] delegate:nil];
    }
}


-(void)venueForCurrentLocation:(Location *)location
{
    [location showBestMatchingFoursquareVenueCriteria:@"ll" completion:^(id results, NSError *error) {
        
        if (!error){
            
            self.allVenues = [[results objectForKey:@"response"] objectForKey:@"venues"];
            NSString *latitude = [[self.allVenues[0] objectForKey:@"location"] objectForKey:@"lat"];
            NSString *longitude = [[self.allVenues[0] objectForKey:@"location"] objectForKey:@"lng"];
            NSString *city = [[self.allVenues[0] objectForKey:@"location"] objectForKey:@"city"];
            NSString *country = [[self.allVenues[0] objectForKey:@"location"] objectForKey:@"country"];
            self.venueForCurrentLocation = [[[results objectForKey:@"response"] objectForKey:@"venues"][0] objectForKey:@"name"];
            
            
            self.chosenVenueLocation = [[Location alloc] initWithLat:latitude Lng:longitude PrettyName:self.venueForCurrentLocation];
            self.chosenVenueLocation.city = (city != nil) ? city : nil ;
            self.chosenVenueLocation.country = (country != nil) ? country : nil;
            
            [self.chooseLocationButton setTitle:self.venueForCurrentLocation forState:UIControlStateNormal];
            
        }
    }];
}


-(void)updateMapView:(MKMapView *)mapView WithLocation:(CLLocation *)location
{
    CLLocationCoordinate2D twoDCordinate = CLLocationCoordinate2DMake(self.currentLocation.coordinate.latitude, self.currentLocation.coordinate.longitude);
    
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(twoDCordinate, 500, 500);
    MKCoordinateRegion adjustedRegion = [mapView regionThatFits:viewRegion];
    
    [mapView setShowsUserLocation:YES]; 
    [mapView setRegion:adjustedRegion animated:YES];
}


-(IBAction)addStreamSegmentChanged:(UISegmentedControl *)sender
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

- (IBAction)joinStreamAction:(id)sender
{
    self.streamCode = self.streamCodeField.text;
    [self joinStream:self.streamCode];
}

- (IBAction)dismissVC:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}


-(void)joinStream:(NSString *)code
{
    [self.joiningStreamIndicator startAnimating];
    
    [[User currentlyActiveUser] joinSpotCompletionCode:code completion:^(id results, NSError *error) {
            DLog(@"Result - %@",results);
          if ([results[STATUS] isEqualToString:ALRIGHT]){
            
            [Flurry logEvent:@"Join_Stream_With_Code"];
            
            // Joined successfully
            NSString *spotId = [results[@"spotId"] stringValue];
            [[NSNotificationCenter defaultCenter] postNotificationName:kUserReloadStreamNotification object:nil];
            
            [self performSegueWithIdentifier:@"JOIN_STREAM_SEGUE" sender:spotId];
            
        }else if ([results[STATUS] isEqualToString:@"error"]){
            // There is no spot with this code
            [AppHelper showNotificationWithMessage:@"Looks like that code is incorrect"
                                              type:kSUBANOTIFICATION_ERROR
                                  inViewController:self
                                   completionBlock:nil];
        }
        
        [self.joiningStreamIndicator stopAnimating];
    }];
    
}


#pragma mark - Navigation
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"PhotoStreamSegue"]) {
        PhotoStreamViewController *photosVC = segue.destinationViewController;
        photosVC.numberOfPhotos = [sender[@"photos"] integerValue];
        photosVC.spotName = sender[@"spotName"];
        photosVC.spotID = sender[@"spotId"];
    }else if ([segue.identifier isEqualToString:@"ChooseStreamLocationSegue"]){
        FoursquareLocationsViewController *nearbyVenuesVC = segue.destinationViewController;
        nearbyVenuesVC.currentLocation = self.chosenVenueLocation;
        nearbyVenuesVC.locations = self.allVenues;
        nearbyVenuesVC.subaLocations = subaLocations;
    }
}


#pragma mark - UITextField Delegate
-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    return YES;
}


-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    DLog();
    
        if (textField == self.streamCodeField) {
            if (textField.text.length > 0) {
              self.streamCode = textField.text;
              [self joinStream:self.streamCode];
          }
        }else if (textField == self.streamNameField){
            if (([textField.text isEqualToString:@""]) | (textField.text.length > 0)) {
                self.createStreamButton.enabled = NO;
            }else {
                if ([self.chooseLocationButton.titleLabel.text isEqualToString:@"Choose Location"]) {
                   self.createStreamButton.enabled = NO;
                }else self.createStreamButton.enabled = YES;
            }
        }
    
    
    return YES;
}






@end
