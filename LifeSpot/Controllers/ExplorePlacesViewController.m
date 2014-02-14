//
//  ExplorePlacesViewController.m
//  LifeSpot
//
//  Created by Kwame Nelson on 1/17/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import "ExplorePlacesViewController.h"
#import "ExplorePlacesCell.h"
#import "SearchBarCell.h"
#import "Location.h"
#import "User.h"

@interface ExplorePlacesViewController ()<CLLocationManagerDelegate,UITableViewDataSource,UITableViewDelegate,UISearchBarDelegate>

@property (weak, nonatomic) IBOutlet UITableView *venuesTableView;
@property (weak, nonatomic) IBOutlet UIView *searchingLocationsView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *searchingIndicator;

@property (strong,nonatomic) UISearchBar *searchBar;
@property (strong,nonatomic) NSArray *locations;
@property (strong,nonatomic) NSMutableArray *watchingLocations;
@property (strong,nonatomic) NSMutableArray *filteredLocations;
@property (strong,nonatomic) CLLocation *currentLocation;


- (IBAction)followPlace:(UIButton *)sender;
- (void)checkForLocation;
- (void)showNearbyFoursuareVenues:(NSDictionary *)latlng;
- (NSArray *)retrieveVenueDetails:(NSDictionary *)venue;
- (void)fetchUserFavLocation;
@end

@implementation ExplorePlacesViewController
static CLLocationManager *locationManager;

- (void)viewDidLoad
{
    [super viewDidLoad];
    //CLLocationManager locationServicesEnabled
    if ([locationManager location]) {
        DLog(@"Current Location - %@",NSStringFromClass([locationManager.location class]));
        NSString *latitude = [NSString stringWithFormat:@"%.8f",self.currentLocation.coordinate.latitude];
        NSString *longitude = [NSString stringWithFormat:@"%.8f",self.currentLocation.coordinate.longitude];
        
        [self showNearbyFoursuareVenues:@{ @"latitude":latitude,@"longitude" :longitude}];

    }
    [self checkForLocation];
    
    
    [self fetchUserFavLocation];
    
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    self.searchBar.placeholder = @"Search Places";
    self.searchBar.delegate = self;
    
    self.venuesTableView.tableHeaderView = self.searchBar;
    
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
        [UIView animateWithDuration:0.8 animations:^{
        [self.venuesTableView setContentOffset:CGPointMake(0, 44)];
    } completion:nil];

}



-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (locationManager) {
        [locationManager startUpdatingLocation];
    }
}


-(void)viewWillDisappear:(BOOL)animated
{
    [locationManager stopUpdatingLocation];
    self.locations = nil;
}




- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Helpers
-(void)fetchUserFavLocation
{
    User *userInSession = [User currentlyActiveUser];
    [userInSession fetchFavoriteLocationsCompletions:^(id results, NSError *error) {
        if (error) {
            DLog(@"Error - %@",error);
        }else {
            self.watchingLocations = [NSMutableArray arrayWithArray:(NSArray *)[results objectForKey:@"watching"]];
            DLog(@"Watching - %@",self.watchingLocations);
            
        }
    }];
    

}


- (IBAction)followPlace:(UIButton *)sender{
    
    // Let's got the server
    ExplorePlacesCell *cell = (ExplorePlacesCell *)sender.superview.superview.superview;
    DLog(@"Sender state  - %u\n",sender.state);
     User *user = [User currentlyActiveUser];
    
    NSIndexPath *indexPath = [self.venuesTableView indexPathForCell:cell];
    
    NSString *lat = self.locations[indexPath.row][@"location"][@"lat"];
    NSString *lng = self.locations[indexPath.row][@"location"][@"lng"];
    NSString *placeName = self.locations[indexPath.row][@"name"];

    
    if (sender.state == UIControlStateNormal || sender.state == UIControlStateHighlighted) {
        DLog(@"ControlState is normal or highlighted so we follow place");
        
        Location *location = [[Location alloc] initWithLat:lat Lng:lng PrettyName:placeName];
        [user addLocationToWatching:location Completion:^(id results, NSError *error) {
            if (error) {
                DLog(@"error - %@",error);
            }else{
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                     [self.watchingLocations addObject:@{@"prettyName": location.placeName ,@"spots" : @(0)}];
                });
                
               
    
                [UIView animateWithDuration:1.8 animations:^{
                    sender.alpha = 0;
                    sender.alpha = 1;
                    
                    [sender setSelected:YES];
                }];
            }
        }];
        
    }else{
        DLog(@"Button is in selected state");
        
        // unfollow place
        [user removeLocationFromWatching:placeName Completion:^(id results, NSError *error) {
            if (!error && [results[STATUS] isEqualToString:ALRIGHT]) {
                
                for (NSDictionary *favPlace in self.watchingLocations) {
                    if ([favPlace[@"prettyName"] isEqualToString:cell.venueNameLabel.text]) {
                        //DLog(@"Setting selected");
                        
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10), dispatch_get_main_queue(), ^{
                            [self.watchingLocations removeObject:favPlace];
                            [cell.followPlaceButton setSelected:NO];
                            
                        });
                    }
                }
                
                [UIView animateWithDuration:1.8 animations:^{
                    sender.alpha = 0;
                    sender.alpha = 1;
                    
                    [sender setSelected:NO];
                }];
            }
        }];
    }
    
}

-(void)checkForLocation
{
    if ([CLLocationManager locationServicesEnabled]) {
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        [locationManager startUpdatingLocation];
        /*if ([locationManager location]) {
             DLog(@"Location - %@",NSStringFromClass([[locationManager location] class]));
            NSString *latitude = [NSString stringWithFormat:@"%.8f",self.currentLocation.coordinate.latitude];
            NSString *longitude = [NSString stringWithFormat:@"%.8f",self.currentLocation.coordinate.longitude];
            
            [self showNearbyFoursuareVenues:@{ @"latitude":latitude,@"longitude" :longitude}];

        }*/
       
        
        
        
    }else{
        [AppHelper showAlert:@"Location Services Disabled"
                     message:@"Location services is disabled for this app. Please enable location services to see nearby spots" buttons:@[@"OK"] delegate:nil];
        
    }
}

-(NSArray *)retrieveVenueDetails:(NSDictionary *)venue{
    NSMutableArray *venueDetails = [NSMutableArray arrayWithCapacity:2];
    NSString *venueName = [venue objectForKey:@"name"];
    //NSString *venueDistanceFromUserCurrentLocation = [[venue objectForKey:@"location"] objectForKey:@"distance"];
    
    [venueDetails addObjectsFromArray:@[venueName]];
    
    NSArray *categories = [venue objectForKey:@"categories"];
    NSString *venueIconURL = nil;
    if ([categories count] > 0) {
        
        NSString *venueIconURLPrefix = [[categories[0] objectForKey:@"icon"] objectForKey:@"prefix"];
        NSString *venueIconURLSuffix = [[categories[0] objectForKey:@"icon"] objectForKey:@"suffix"];
        
        venueIconURL = [NSString stringWithFormat:@"%@bg_64%@",venueIconURLPrefix,venueIconURLSuffix];
        [venueDetails addObject:venueIconURL];
    }
    
    return venueDetails;
}


-(void)showNearbyFoursuareVenues:(NSDictionary *)latlng
{
    DLog(@"LatLng- %@",latlng);
    Location *loc = [[Location alloc] initWithLat:latlng[@"latitude"] Lng:latlng[@"longitude"]];
    
    [loc showBestMatchingFoursquareVenueCriteria:@"ll" completion:^(id results, NSError *error) {
        if (!error) {
            self.locations = [[results objectForKey:@"response"] objectForKey:@"venues"];
            
            [self.venuesTableView reloadData];
        }else{
           DLog(@"Error: %@", error);
        }
    }];
    
    /*NSString *near = [NSString stringWithFormat:@"%@,%@",latlng[@"latitude"],latlng[@"longitude"]];
    NSString *radius = @"1000";
    NSString *requestURL = [NSString stringWithFormat:@"%@venues/search",FOURSQUARE_BASE_URL_STRING];
    
    AFHTTPRequestOperationManager *manager =[AFHTTPRequestOperationManager manager];
    [manager GET:requestURL parameters:@{@"client_id": FOURSQUARE_API_CLIENT_ID,
                                         @"client_secret": FOURSQUARE_API_CLIENT_SECRET,
                                         @"ll" : near,
                                         @"radius" : radius,
                                         @"limit" : @"50",
                                         @"v" : @"20140108"
                                         }
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             //DLog(@"Response from 4square - %@",responseObject);
             self.locations = [[responseObject objectForKey:@"response"] objectForKey:@"venues"];
             
             [self.venuesTableView reloadData];
             
         } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             DLog(@"Error: %@", error);
             
         }];*/

}



#pragma mark - Location Manager Delegate
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    DLog();
    self.currentLocation = [locations lastObject];
    if (self.currentLocation != nil){
        if (!self.locations) {
            NSString *latitude = [NSString stringWithFormat:@"%.8f",self.currentLocation.coordinate.latitude];
            NSString *longitude = [NSString stringWithFormat:@"%.8f",self.currentLocation.coordinate.longitude];
            
            [self showNearbyFoursuareVenues:@{ @"latitude":latitude,@"longitude" :longitude}];
        }
        
    }
}


- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error
{
    DLog(@"Error while getting core location : %@",[error localizedFailureReason]);
    if ([error code] == kCLErrorDenied) {
        //you had denied
    }
    [manager stopUpdatingLocation];
}


#pragma mark - UITableView DataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    // Return the number of rows in the section.
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        
        return [self.filteredLocations count];
    }else{
        
        return [self.locations count];
    }
}



/*-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    SearchBarCell *headerCell = (SearchBarCell *)[tableView dequeueReusableCellWithIdentifier:@"SearchBar"];
    
    return headerCell;
}*/

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *CellIdentifier = @"ExplorePlaceCell";
    ExplorePlacesCell *cell = (ExplorePlacesCell *)[self.venuesTableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    [cell.followPlaceButton setSelected:NO];
    // Configure the cell...
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        cell.textLabel.text = [self.filteredLocations[indexPath.row] objectForKey:@"name"];
    }else{
        
        NSArray *venueDets = [self retrieveVenueDetails:(NSDictionary *)self.locations[indexPath.row]];
        
        cell.venueNameLabel.text = venueDets[0];
        
        for (NSDictionary *favPlace in self.watchingLocations) {
            if ([favPlace[@"prettyName"] isEqualToString:venueDets[0]]) {
                //DLog(@"Setting selected");
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 100), dispatch_get_main_queue(), ^{
                    [cell.followPlaceButton setSelected:YES];

                });
            }
        }
        
        //cell.venueDistanceLabel.text = [NSString stringWithFormat:@"%@meters",venueDets[1]];
        if ([venueDets count] == 2) {
            [cell.venueIconImageView setImageWithURL:[NSURL URLWithString:venueDets[1]] placeholderImage:[UIImage imageNamed:@"PointerIcon"]];
        }else{
            [cell.venueIconImageView setImage:[UIImage imageNamed:@"PointerIcon"]];
        }
    }
    
    return cell;
}


#pragma mark - UISearchBar Delegate
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    //DLog(@"First Responder - %@",searchBar);
    if (![searchText isEqualToString:@""]) {
        searchBar.showsCancelButton = YES;
    }else{
        searchBar.showsCancelButton = NO;
    }
}


- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    searchBar.text = @"";
    [searchBar resignFirstResponder];
    searchBar.showsCancelButton = NO;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    
    [AppHelper showLoadingDataView:self.searchingLocationsView indicator:self.searchingIndicator flag:YES];
    
    [Location searchFourquareWithSearchTerm:searchBar.text completionBlock:^(id results, NSError *error) {
        [AppHelper showLoadingDataView:self.searchingLocationsView indicator:self.searchingIndicator flag:NO];
        
        if (error) {
            DLog(@"Error - %@",error);
        }else{
            NSArray *searchResults = [[results objectForKey:@"response"] objectForKey:@"venues"];
            if ([searchResults count] > 0){
                
                self.locations = searchResults;
                DLog(@"Locations - %@",searchResults);
                [self.venuesTableView reloadData];
            }
            
        }
       [searchBar resignFirstResponder];
    }];
    
    
}

@end
