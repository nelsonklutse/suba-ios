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

@interface CreateSpotViewController ()<UITextFieldDelegate,CLLocationManagerDelegate>

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
- (IBAction)showNearbyLocations:(id)sender;
- (void)askLocationPermission;
- (void)foursquareVenueMatchingCurrentLocation:(Location *)here;
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


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)joinSpotAction:(id)sender
{
    [AppHelper showLoadingDataView:self.loadingDataView indicator:self.joiningSpotIndicator flag:YES];
    DLog(@"joining");
    [[User currentlyActiveUser] joinSpotCompletionCode:self.joinSpotId.text completion:^(id results, NSError *error) {
        DLog(@"Result - %@",results);
        if ([results[STATUS] isEqualToString:ALRIGHT]){
            // Joined successfully
            NSString *spotId = results[@"spotId"];
            [self performSegueWithIdentifier:@"JOIN_SPOT_SEGUE" sender:spotId];
            
        }else if ([results[STATUS] isEqualToString:@"error"]){
            // There is no spot with this code
            [AppHelper showNotificationWithMessage:@"We could find a spot with this code"
                                              type:kSUBANOTIFICATION_ERROR
                                  inViewController:self
                                   completionBlock:nil];
        }
        
        [AppHelper showLoadingDataView:self.loadingDataView indicator:self.joiningSpotIndicator flag:NO];
    }];
}

- (IBAction)createSpotAction:(UIButton *)sender {
    // 1. View Privacy  2. Add Privacy 3. Location 4.
    [self.creatingSpotIndicator startAnimating];
    NSString *viewPrivacy = @"0";
    NSString *addPrivacy = @"0";
    NSString *spotKey = @"NONE";
    self.spotName = self.spotNameField.text;
    
    User *user = [User currentlyActiveUser];
    Privacy *privacy = [[Privacy alloc] initWithView:viewPrivacy AddPrivacy:addPrivacy];
    Spot *spot = [[Spot alloc] initWithName:self.spotName Key:spotKey Privacy:privacy Location:self.chosenVenueLocation User:user];
    
    [user createSpot:spot completion:^(id results, NSError *error) {
        [self.creatingSpotIndicator stopAnimating];
        if (!error){
            
            // There were no errors
            self.createdSpotDetails = (NSDictionary *)results;
            [self performSegueWithIdentifier:@"spotWasCreatedSegue" sender:nil];
            
        }else{
            DLog(@"Error - %@",error);
        }
    }];
    

}

- (IBAction)showNearbyLocations:(id)sender
{
    
}

-(void)askLocationPermission
{
    if ([CLLocationManager locationServicesEnabled]) {
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        [locationManager startMonitoringSignificantLocationChanges];
        
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


-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    
    CLLocation *here = [locations lastObject];
    
    if (here != nil){
        
        NSString *latitude = [NSString stringWithFormat:@"%.8f",here.coordinate.latitude];
        NSString *longitude = [NSString stringWithFormat:@"%.8f",here.coordinate.longitude];
        self.userLocation = [[Location alloc] initWithLat:latitude Lng:longitude];
        
        // Go to Foursquare for location
        [self foursquareVenueMatchingCurrentLocation:self.userLocation];
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
        
    }
    
    if ([segue.identifier isEqualToString:@"JOIN_SPOT_SEGUE"]) {
        PhotoStreamViewController *pVC = segue.destinationViewController;
        pVC.spotID = sender;
    }
}

#pragma mark - Unwind Segue
- (IBAction)unWindToCreateSpotFromCancel:(UIStoryboardSegue *)segue{
    
}

-(IBAction)unWindToCreateSpotFromDone:(UIStoryboardSegue *)segue
{
    FoursquareLocationsViewController *foursquareVC = segue.sourceViewController;
    self.venueForCurrentLocation = (foursquareVC.currentLocationSelected == nil) ? self.venueForCurrentLocation : foursquareVC.currentLocationSelected;
    
    [self.currentLocationButton setTitle:self.venueForCurrentLocation forState:UIControlStateNormal];
    self.chosenVenueLocation = (foursquareVC.venueChosen == nil) ? self.chosenVenueLocation : foursquareVC.venueChosen;
}




@end
