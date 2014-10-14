//
//  FoursquareLocationsViewController.m
//  LifeSpots
//
//  Created by Kwame Nelson on 11/3/13.
//  Copyright (c) 2013 Agana-Nsiire Agana. All rights reserved.
//

#import "FoursquareLocationsViewController.h"
#import "FoursquareVenueCell.h"
#import "CreateSpotViewController.h"
#import "StreamSettingsViewController.h"
#import "CreateStreamViewController.h"
#import "Location.h"

@interface FoursquareLocationsViewController ()<UITableViewDataSource,UITableViewDelegate,UISearchBarDelegate,UISearchDisplayDelegate,CLLocationManagerDelegate,UIAlertViewDelegate>

@property (retain,nonatomic) NSIndexPath *lastSelected;
@property (strong,nonatomic) Location *venueChosen;

@property (retain,nonatomic) NSMutableArray *filteredLocations;
@property (retain,nonatomic) CLLocation *userLocation;
@property (retain,nonatomic) NSString *currentLocationSelected;

@property (weak, nonatomic) IBOutlet UISearchBar *searchVenuesBar;
@property (weak, nonatomic) IBOutlet UITableView *venuesTableView;
@property (weak, nonatomic) IBOutlet UIView *searchingVenuesView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *searchingVenuesIndicator;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;


//- (IBAction)locationChosen:(id)sender;
- (void)displayFourSquareLocations:(Location *)locationPassed;
- (void)displaySubaLocations:(Location *)locationPassed;
- (void)showLoadingLocationsView:(BOOL)flag;
- (NSArray *)retrieveVenueDetails:(NSDictionary *)venue;
//- (IBAction)dismissViewController:(UIBarButtonItem *)sender;
@end

@implementation FoursquareLocationsViewController
static CLLocationManager *locationManager;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Disable the done button until location is selected
    self.doneButton.enabled = NO;
    
    self.filteredLocations = [NSMutableArray arrayWithCapacity:[self.locations count]];
    
    
    if ([CLLocationManager locationServicesEnabled]){
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized){
            
            locationManager = [[CLLocationManager alloc] init];
            locationManager.delegate = self;
            [locationManager startUpdatingLocation];
            
            
        }else{
            [AppHelper showAlert:@"Location Denied"
                         message:@"You have disabled location services for Suba. Please go to Settings->Privacy->Location and enable location for Suba"
                         buttons:@[@"OK"] delegate:nil];
        }

        
      }
    }


-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [locationManager stopUpdatingLocation];
}


-(void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:YES];
    [locationManager startUpdatingLocation];
    
    self.userLocation = [locationManager location];
    if (self.userLocation != nil){
        
        NSString *latitude = [NSString stringWithFormat:@"%.8f",self.userLocation.coordinate.latitude];
        NSString *longitude = [NSString stringWithFormat:@"%.8f",self.userLocation.coordinate.longitude];
        self.currentLocation = [[Location alloc] initWithLat:latitude Lng:longitude];
        
        if (self.locations == nil){
            [self displayFourSquareLocations:self.currentLocation];
        }
        if (self.subaLocations == nil) {
            DLog(@"Suba Locations is nil with Location - %@",[self.currentLocation description]);
            [self displaySubaLocations:self.currentLocation];
        }else{
            DLog(@"Suba Locations is not nil");
        }
    }
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
    return 3;
}


-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 40.0f;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    /*CGFloat height = 60.0f;
    
    if (indexPath.section == 1) {
        height = 60.0f;
    }*/
    
    return 60.0f;
}


-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *headerTitle = nil;
    if (section == 2) {
        headerTitle = @"Add Your Own Location";
    }else if (section == 1){
     headerTitle = @"Pick a Location - SUBA";
    }else if (section == 0){
        headerTitle = @"Pick a Location - FOURSQUARE";
    }
    
    return headerTitle;
}



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;
    if (section == 2) {
        
        return 1;
    }else if(section == 1){
        return [self.subaLocations count];
    }else if (section == 0){
        if (tableView == self.searchDisplayController.searchResultsTableView) {
            
            numberOfRows = [self.filteredLocations count];
        }else{
            
            numberOfRows = [self.locations count];
        }
    }
    
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 2) {
        static NSString *CellIdentifier = @"AddNewLocation";
        UITableViewCell *newLocationCell = [self.venuesTableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        newLocationCell.textLabel.text = @"Add a new Location";
        
        return newLocationCell;
    }else if(indexPath.section == 1){
        static NSString *CellIdentifier = @"SubaVenueCell";
        UITableViewCell *subaLocationCell = [self.venuesTableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        if ([self.subaLocations count] == 0) {
           subaLocationCell.textLabel.text = @"No Suba locations near you";
        }else{
            if (self.lastSelected.row == indexPath.row){
                //DLog(@"Last selected row - %li",(long)indexPath.row);
                //subaLocationCell.accessoryType = UITableViewCellAccessoryCheckmark;
                
            }else subaLocationCell.accessoryType = UITableViewCellAccessoryNone;
            
            NSDictionary *subaLocation = self.subaLocations[indexPath.row];
            subaLocationCell.textLabel.text = subaLocation[@"locationName"];
        }
        
        return subaLocationCell;
    }else if (indexPath.section == 0){
    static NSString *CellIdentifier = @"VenueCell";
    FoursquareVenueCell *cell = [self.venuesTableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        // Configure the cell...
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        cell.textLabel.text = [self.filteredLocations[indexPath.row] objectForKey:@"name"];
    }else{
        if (self.lastSelected.row == indexPath.row){ 
            //DLog(@"Last selected row - %li",(long)indexPath.row);
            //cell.accessoryType = UITableViewCellAccessoryCheckmark;
            
        }else cell.accessoryType = UITableViewCellAccessoryNone;
        
        //DLog(@"Class of venue - %@",[self.locations[indexPath.row] class]);
        NSArray *venueDets = [self retrieveVenueDetails:(NSDictionary *)self.locations[indexPath.row]];
        
        cell.venueName.text = venueDets[0];
        cell.distanceLabel.text = [NSString stringWithFormat:@"%@ meters",venueDets[1]];
        if ([venueDets count] == 3) {
            [cell.venueIcon setImageWithURL:[NSURL URLWithString:venueDets[2]] placeholderImage:[UIImage imageNamed:@"PointerIcon"]];
        }else{
        [cell.venueIcon setImage:[UIImage imageNamed:@"PointerIcon"]];
        }
    }
    
    return cell;
   }
    
    return nil;
}


#pragma mark - TableView Delegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    //NSLog(@"Selected");
    
    
    if (indexPath.section == 2){
        // Check whether we have access to the user's location
        if ([CLLocationManager locationServicesEnabled] && [CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
            
            [AppHelper showAlert:@"Location Error" message:[NSString stringWithFormat:@"%@\n%@",@"Suba does not have access to your location.",@"Please go to Settings->Privacy->Location Services and enable location for Suba" ] buttons:@[@"OK"] delegate:nil];
            
        }else{
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Add Location" message:@"Name your location" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Done", nil];
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        
        [alert show];
    }
    
    }else if(indexPath.section == 1){
        if (self.lastSelected != indexPath) {
            UITableViewCell *oldCell = [self.venuesTableView cellForRowAtIndexPath:self.lastSelected];
            
            oldCell.accessoryType = UITableViewCellAccessoryNone;
            
            UITableViewCell *cell = [self.venuesTableView cellForRowAtIndexPath:indexPath];
            self.currentLocationSelected = cell.textLabel.text;
            NSString *latitude = self.subaLocations[indexPath.row][@"latitude"];
            NSString *longitude = self.subaLocations[indexPath.row][@"longitude"];
            //NSString *city = [[self.locations[indexPath.row] objectForKey:@"location"] objectForKey:@"city"];
            //NSString *country = [[self.locations[indexPath.row] objectForKey:@"location"] objectForKey:@"country"];
            
            self.venueChosen = [[Location alloc] initWithLat:latitude Lng:longitude PrettyName:self.currentLocationSelected];
            
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            
            self.lastSelected = indexPath;
        }

    }else if(indexPath.section == 0){
    
    if (tableView == self.venuesTableView) {
        if (self.lastSelected != indexPath) {
            FoursquareVenueCell *oldCell = (FoursquareVenueCell *)[self.venuesTableView cellForRowAtIndexPath:self.lastSelected];
            
            oldCell.accessoryType = UITableViewCellAccessoryNone;
            
            FoursquareVenueCell *cell = (FoursquareVenueCell *)[self.venuesTableView cellForRowAtIndexPath:indexPath];
            self.currentLocationSelected = cell.venueName.text;
            NSString *latitude = [[self.locations[indexPath.row] objectForKey:@"location"] objectForKey:@"lat"];
            NSString *longitude = [[self.locations[indexPath.row] objectForKey:@"location"] objectForKey:@"lng"];
            NSString *city = [[self.locations[indexPath.row] objectForKey:@"location"] objectForKey:@"city"];
            NSString *country = [[self.locations[indexPath.row] objectForKey:@"location"] objectForKey:@"country"];
            
            self.venueChosen = [[Location alloc] initWithLat:latitude Lng:longitude PrettyName:self.currentLocationSelected];
            self.venueChosen.city = (city != nil) ? city : nil ;
            self.venueChosen.country = (country != nil) ? country : nil;
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            
            self.lastSelected = indexPath;
            //DLog(@"Last selected - %@",indexPath);
            
        }
    }else if(tableView == self.searchDisplayController.searchResultsTableView){
        if (self.lastSelected != indexPath) {
            UITableViewCell *oldCell = [tableView cellForRowAtIndexPath:self.lastSelected];
            oldCell.accessoryType = UITableViewCellAccessoryNone;
            
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            //NSLog(@"Text selected in Search - %@",cell.textLabel.text);
            self.currentLocationSelected = cell.textLabel.text;
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            self.lastSelected = indexPath;
        }
    }
  }
    self.doneButton.enabled = YES;
 
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

#pragma mark - Custom selectors
- (void)displayFourSquareLocations:(Location *)locationPassed{
    [self showLoadingLocationsView:YES];
    NSString *near = [NSString stringWithFormat:@"%@,%@",locationPassed.latitude,locationPassed.longitude];
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
             [self showLoadingLocationsView:NO];
             NSArray *foursquareLocations = [[responseObject objectForKey:@"response"] objectForKey:@"venues"];
             // Sort by distance
             NSSortDescriptor *distanceSorter = [[NSSortDescriptor alloc] initWithKey:@"location.distance" ascending:YES];
             
             NSArray *sortDescriptors = [NSArray arrayWithObject:distanceSorter];
             NSArray *sortedLocations = [foursquareLocations sortedArrayUsingDescriptors:sortDescriptors];
             self.locations = [NSMutableArray arrayWithArray:sortedLocations];
             
        [self.venuesTableView reloadData];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DLog(@"Error: %@", error);
        [self showLoadingLocationsView:NO];
    }];
}


-(void)displaySubaLocations:(Location *)locationPassed
{
    //DLog(@"Suba Locations");
    
    [[SubaAPIClient sharedInstance] GET:@"location/nearby"
                             parameters:@{@"latitude": locationPassed.latitude,@"longitude" : locationPassed.longitude}
                                success:^(NSURLSessionDataTask *task,id responseObject){
                                    if ([responseObject[STATUS] isEqualToString:ALRIGHT]) {
                                        DLog(@"Suba Locations - %@",responseObject[@"subaLocations"]);
                                        self.subaLocations = responseObject[@"subaLocations"];
                                        [self.venuesTableView reloadData];
                                    }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        DLog(@"Error - %@",error);
    }];
}



-(NSArray *)retrieveVenueDetails:(NSDictionary *)venue{
    NSMutableArray *venueDetails = [NSMutableArray arrayWithCapacity:2];
    NSString *venueName = [venue objectForKey:@"name"];
    NSString *venueDistanceFromUserCurrentLocation = [[venue objectForKey:@"location"] objectForKey:@"distance"];
    
    [venueDetails addObjectsFromArray:@[venueName,venueDistanceFromUserCurrentLocation]];
    
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
- (IBAction)dismissVC:(id)sender
{
    /*[self dismissViewControllerAnimated:YES completion:nil];*/
    DLog();
    if ([self.presentingViewController isKindOfClass:[CreateSpotViewController class]]){
        [self performSegueWithIdentifier:@"FoursquareToCreateSegueCancel" sender:nil];
    }else if ([self.presentingViewController isKindOfClass:[StreamSettingsViewController class]]){
        [self performSegueWithIdentifier:@"FoursquareToAlbumSettingsSegueCancel" sender:nil];
    }
    [self dismissViewControllerAnimated:YES completion:nil];

}

- (IBAction)locationChangeDone:(id)sender
{
    DLog(@"Presenting view controller - %@",[self.presentingViewController class]);
    if ([self.presentingViewController isKindOfClass:[UINavigationController class]]){
       // DLog(@"Going to create stream VC");
        
        [self performSegueWithIdentifier:@"FoursquareToCreateSegueDone" sender:nil];
    }else if ([self.presentingViewController isKindOfClass:[StreamSettingsViewController class]]){
        [self performSegueWithIdentifier:@"FoursquareToAlbumSettingsSegueDone" sender:nil];
    }
}

/*- (IBAction)dismissViewController:(UIBarButtonItem *)sender
{
    
    //CreateStreamViewController *createStreamVC = (CreateStreamViewController *)self.presentingViewController;
    
    if (sender.tag == 100) {
        //DLog(@"Presenting View Controller - %@",self.presentingViewController);
        if ([self.presentingViewController isKindOfClass:[CreateStreamViewController class]]){
            [self performSegueWithIdentifier:@"FoursquareToCreateStreamCancel" sender:nil];
        }else if ([self.presentingViewController isKindOfClass:[AlbumSettingsViewController class]]){
            [self performSegueWithIdentifier:@"FoursquareToAlbumSettingsSegueCancel" sender:nil];
        }
        
    }else if (sender.tag == 200){
        if ([self.presentingViewController isKindOfClass:[CreateStreamViewController class]]){
            [self performSegueWithIdentifier:@"FoursquareToCreateStreamDone" sender:nil];
        }else if ([self.presentingViewController isKindOfClass:[AlbumSettingsViewController class]]){
            [self performSegueWithIdentifier:@"FoursquareToAlbumSettingsSegueDone" sender:nil];
        }
    }
}*/


#pragma mark Content Filtering
-(void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope{
    
    // Update the filtered array based on the search text and scope.
    // Remove all objects from the filtered search array
    [self.filteredLocations removeAllObjects];
    
    // Filter the array using NSPredicate
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name contains[c] %@",searchText];
    self.filteredLocations = [NSMutableArray arrayWithArray:[self.locations filteredArrayUsingPredicate:predicate]];
}


#pragma mark - UISearchDisplayController Delegate Methods
-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString{
    // Tells the table data source to reload when text changes
    [self filterContentForSearchText:searchString scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}


/*-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {
    
    // Tells the table data source to reload when scope bar selection changes
    [self filterContentForSearchText:self.searchDisplayController.searchBar.text scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:searchOption]];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}*/



#pragma mark - Core Location Manager Delegate methods
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    self.userLocation = [locations lastObject];
    if (self.userLocation != nil){
        
        NSString *latitude = [NSString stringWithFormat:@"%.8f",self.userLocation.coordinate.latitude];
        NSString *longitude = [NSString stringWithFormat:@"%.8f",self.userLocation.coordinate.longitude];
        self.currentLocation = [[Location alloc] initWithLat:latitude Lng:longitude];
        
        if (self.locations == nil){
            [self displayFourSquareLocations:self.currentLocation];
        }
        if (self.subaLocations == nil) {
           //[self displaySubaLocations:self.currentLocation];
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




-(void)showLoadingLocationsView:(BOOL)flag
{
    self.searchingVenuesView.hidden = !flag;
    if (flag == YES) {
        [self.searchingVenuesIndicator startAnimating];
    }else [self.searchingVenuesIndicator stopAnimating];
}


#pragma mark - Alert View Delegate Methods
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
       self.currentLocationSelected = [alertView textFieldAtIndex:0].text;
        //self.userLocation = [locationManager location];
        NSString *latitude = [NSString stringWithFormat:@"%.8f",self.userLocation.coordinate.latitude];
        NSString *longitude = [NSString stringWithFormat:@"%.8f",self.userLocation.coordinate.longitude];
       self.venueChosen = [[Location alloc] initWithLat:latitude Lng:longitude PrettyName:self.currentLocationSelected];
        
        [self locationChangeDone:self.doneButton];
    }
}

@end
