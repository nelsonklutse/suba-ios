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
#import "AlbumSettingsViewController.h"
#import "Location.h"

@interface FoursquareLocationsViewController ()<UITableViewDataSource,UITableViewDelegate,UISearchBarDelegate,UISearchDisplayDelegate,CLLocationManagerDelegate>

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
- (void)showLoadingLocationsView:(BOOL)flag;
- (NSArray *)retrieveVenueDetails:(NSDictionary *)venue;
- (IBAction)dismissViewController:(UIBarButtonItem *)sender;
@end

@implementation FoursquareLocationsViewController
static CLLocationManager *locationManager;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Disable the done button until location is selected
    self.doneButton.enabled = NO;
    
    self.filteredLocations = [NSMutableArray arrayWithCapacity:[self.locations count]];
    
    
        if ([CLLocationManager locationServicesEnabled]) {
            locationManager = [[CLLocationManager alloc] init];
            locationManager.delegate = self;
            [locationManager startUpdatingLocation];
            
      }
    }


-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [locationManager stopUpdatingLocation];
}


-(void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:YES];
    [locationManager startUpdatingLocation];
    //DLog(@"Started monitoring Locations");
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{

    // Return the number of rows in the section.
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        
        return [self.filteredLocations count];
    }else{
    
    return [self.locations count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"VenueCell";
    FoursquareVenueCell *cell = [self.venuesTableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        cell.textLabel.text = [self.filteredLocations[indexPath.row] objectForKey:@"name"];
    }else{
        //DLog(@"Class of venue - %@",[self.locations[indexPath.row] class]);
        NSArray *venueDets = [self retrieveVenueDetails:(NSDictionary *)self.locations[indexPath.row]];
        
        cell.venueName.text = venueDets[0];
        cell.distanceLabel.text = [NSString stringWithFormat:@"%@meters",venueDets[1]];
        if ([venueDets count] == 3) {
            [cell.venueIcon setImageWithURL:[NSURL URLWithString:venueDets[2]] placeholderImage:[UIImage imageNamed:@"PointerIcon"]];
        }else{
        [cell.venueIcon setImage:[UIImage imageNamed:@"PointerIcon"]];
        }
    }
    
    return cell;
}


#pragma mark - TableView Delegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    //NSLog(@"Selected");
    
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
             self.locations = [[responseObject objectForKey:@"response"] objectForKey:@"venues"];
        [self.venuesTableView reloadData];
        
        /*for (NSDictionary *location in self.locations) {
            NSLog(@"%@",[location objectForKey:@"name"]);
        }*/
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DLog(@"Error: %@", error);
        [self showLoadingLocationsView:NO];
    }];
    
}



- (IBAction)locationChosen:(id)sender {
    /*NSLog(@"The delegate of this class is - %@",[self.delegate class]);
    if ([self.delegate respondsToSelector:@selector(viewController:DidSetLocation:)]) {
        
        if (self.currentLocationSelected != nil) {
            
            NSString *placeSelected = self.currentLocationSelected;
            NSDictionary *venue = [self.locations[self.lastSelected.row] objectForKey:@"location"];
            NSString *address = [venue objectForKey:@"address"];
            NSString *city = [venue objectForKey:@"city"];
            NSString *country = [venue objectForKey:@"country"];
            NSString *latitude = [venue objectForKey:@"lat"];
            NSString *longitude = [venue objectForKey:@"lng"];
            
            Location *chosenLocation = [[Location alloc] initWithLat:latitude Lng:longitude PlaceName:placeSelected Address:address City:city Country:country];
            
            [self.delegate viewController:self DidSetLocation:chosenLocation];
       
        }
    }
    
    [self.presentingViewController dismissViewControllerAnimated:YES
                                                      completion:nil];*/
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

- (IBAction)dismissViewController:(UIBarButtonItem *)sender
{
    if (sender.tag == 100) {
        
        if ([self.presentingViewController isKindOfClass:[CreateSpotViewController class]]) {
            [self performSegueWithIdentifier:@"FoursquareToCreateSegueCancel" sender:nil];
        }else if ([self.presentingViewController isKindOfClass:[AlbumSettingsViewController class]]){
            [self performSegueWithIdentifier:@"FoursquareToAlbumSettingsSegueCancel" sender:nil];
        }
    }else if (sender.tag == 200){
        if ([self.presentingViewController isKindOfClass:[CreateSpotViewController class]]) {
            [self performSegueWithIdentifier:@"FoursquareToCreateSegueDone" sender:nil];
        }else if ([self.presentingViewController isKindOfClass:[AlbumSettingsViewController class]]){
            [self performSegueWithIdentifier:@"FoursquareToAlbumSettingsSegueDone" sender:nil];
        }
 
    }
}


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
        if (self.locations == nil){
            DLog(@"Locations not set");
            self.currentLocation = [[Location alloc] initWithLat:latitude Lng:longitude];
            [self displayFourSquareLocations:self.currentLocation];
        }
        
    }
}


-(void)showLoadingLocationsView:(BOOL)flag
{
    self.searchingVenuesView.hidden = !flag;
    if (flag == YES) {
        [self.searchingVenuesIndicator startAnimating];
    }else [self.searchingVenuesIndicator stopAnimating];
}

@end
