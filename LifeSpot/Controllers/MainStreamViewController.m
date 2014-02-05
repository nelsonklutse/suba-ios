//
//  MainStreamViewController.m
//  LifeSpot
//
//  Created by Kwame Nelson on 1/7/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import "MainStreamViewController.h"
#import "CreateSpotViewController.h"
#import "PhotoStreamViewController.h"
#import "PlacesWatchingCell.h"
#import "PersonalSpotCell.h"
#import "User.h"
#import "Location.h"
#import "AlbumSettingsViewController.h"
#import "PlacesWatchingViewController.h"

typedef enum{
    kCollectionViewUpdateInsert = 0,
    kCollectionViewUpdateDelete
}ColectionViewUpdateType;


typedef enum{
    kPlacesButton = 0,
    kNearbyButton,
    kAllSpotsButton
}SelectedButton;

#define PlacesWatchingKey @"PlacesWatchingKey"
#define NearbySpotsKey @"NearbySpotsKey"
#define AllSpotsKey @"AllSpotsKey"
#define SelectedSpotKey @"SelectedSpotKey"
#define SelectedButtonKey @"SelectedButtonKey"


@interface MainStreamViewController()<UITableViewDataSource,UITableViewDelegate,UICollectionViewDataSource,UICollectionViewDelegate,CLLocationManagerDelegate,UIAlertViewDelegate>

@property (strong,nonatomic) NSMutableArray *placesBeingWatched;
@property (strong,nonatomic) NSMutableArray *nearbySpots;
@property (strong,nonatomic) NSMutableArray *allSpots;
@property (strong,nonatomic) NSDictionary *currentSelectedSpot;
@property (strong,nonatomic) NSIndexPath *currentIndexPath;
//@property (strong,nonatomic) NSArray *images;
@property (retain,nonatomic) CLLocation *currentLocation;
@property (weak, nonatomic) IBOutlet UILabel *noDataLabel;

@property (weak, nonatomic) IBOutlet UIButton *placesBeingWatchedButton;
@property (weak, nonatomic) IBOutlet UIButton *nearbySpotsButton;
@property (weak, nonatomic) IBOutlet UIButton *allSpotsButton;
@property (weak, nonatomic) IBOutlet UITableView *placesBeingWatchedTableView;
@property (weak, nonatomic) IBOutlet UIView *placesBeingWatchedLoadingView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingInfoIndicator;
@property (weak, nonatomic) IBOutlet UICollectionView *nearbySpotsCollectionView;
@property (weak, nonatomic) IBOutlet UICollectionView *allSpotsCollectionView;

@property (weak, nonatomic) IBOutlet UIView *noDataView;


- (IBAction)unWindToSpots:(UIStoryboardSegue *)segue;
- (IBAction)unWindToAllSpotsWithCreatedSpot:(UIStoryboardSegue *)segue;

- (IBAction)placesButtonSelected:(UIButton *)sender;
- (IBAction)nearbySpotsButtonSelected:(UIButton *)sender;
- (IBAction)allSpotsButtonSelected:(UIButton *)sender;

- (void)joinSpot:(NSString *)spotCode data:(NSDictionary *)data;
- (void)addSpotToAllSpotsStream:(NSDictionary *)spotDetails;
- (void)fetchUserFavoriteLocations;
- (void)fetchUserSpots;
- (void)fetchNearbySpots:(NSDictionary *)latLng;
- (void)showPlacesBeingWatchedView:(BOOL)flag;
- (void)updateData;
- (void)updateCollectionView:(UICollectionView *)collectionView withUpdate:(NSArray *)indexPaths updateType:(ColectionViewUpdateType)updateType;
- (void)checkForLocation;
- (void)galleryTappedAtIndex:(NSNotification *)aNotification;
- (void)networkChanged:(NSNotification *)aNotification;
@end

@implementation MainStreamViewController
static CLLocationManager *locationManager;
static NSInteger selectedButton = 10;

#pragma mark - Unwind Segues
-(IBAction)unWindToSpots:(UIStoryboardSegue *)segue
{
    if ([segue.identifier isEqualToString:@"LEAVE_STREAM_SEGUE"]) {
        //Show notification
        AlbumSettingsViewController *aVC = segue.sourceViewController;
        NSString *albumName = aVC.spotName;
        DLog(@"album name - %@",albumName);
        NSString *spotId = aVC.spotID;
        DLog(@"SpotId - %@",spotId);
         int counter = 0;
        for (NSDictionary *spotToRemove in self.allSpots){
            
            if ([spotToRemove[@"spotId"] integerValue] == [spotId integerValue]){
                
                DLog(@"Spot to remove - %@",spotToRemove);
                [self.allSpots removeObject:spotToRemove];
                //NSUInteger indexOfSpot = [self.allSpots indexOfObject:spotToRemove];
                DLog(@"Index to be deleted - %d",counter);
                [self updateCollectionView:self.allSpotsCollectionView
                                withUpdate:@[[NSIndexPath indexPathForItem:counter inSection:0] ]
                                updateType:kCollectionViewUpdateDelete];
                break;
                
            }
            counter += 1;
        }
        
        UIColor *tintColor = [UIColor colorWithRed:(217.0f/255.0f)
                                                   green:(77.0f/255.0f)
                                                    blue:(20.0f/255.0f)
                                                   alpha:1];
        
        [CSNotificationView showInViewController:self
                                       tintColor: tintColor
                                           image:nil
                                         message:[NSString stringWithFormat:
                                                  @"You are no longer a member of the album %@",albumName]
                                        duration:5.0f];
        
        
        
    }
    

}

-(IBAction)unWindToAllSpotsWithCreatedSpot:(UIStoryboardSegue *)segue
{
    if ([segue.identifier isEqualToString:@"spotWasCreatedSegue"]) {
        CreateSpotViewController *csVC = segue.sourceViewController;
        NSDictionary *spotDetails = csVC.createdSpotDetails;
        //DLog(@"SpotDetails - %@",spotDetails);
        [self addSpotToAllSpotsStream:spotDetails];
    }
    
}


#pragma mark - View life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
	
    //self.allSpots = [NSMutableArray arrayWithCapacity:5];
    
    self.placesBeingWatchedTableView.alpha = 0;
    self.allSpotsCollectionView.alpha = 0;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10), dispatch_get_main_queue(),^{
        [self.nearbySpotsButton setSelected:YES];
    });
    
    self.placesBeingWatchedLoadingView.hidden = YES;
    [self checkForLocation];
    self.currentLocation = [locationManager location];
    
    if (self.currentLocation != nil) {
        
        NSString *latitude = [NSString stringWithFormat:@"%.8f",self.currentLocation.coordinate.latitude];
        NSString *longitude = [NSString stringWithFormat:@"%.8f",self.currentLocation.coordinate.longitude];
        
        [self fetchNearbySpots:@{@"lat": latitude, @"lng" :longitude, @"userId" : [AppHelper userID]}];
    }else{
        [self showPlacesBeingWatchedView:YES];
    }
    
    
    self.edgesForExtendedLayout = UIRectEdgeAll;
    self.placesBeingWatchedTableView.contentInset = UIEdgeInsetsMake(0., 0., CGRectGetHeight(self.tabBarController.tabBar.frame), 0);
    
    //self.images = @[@"gard_12.jpg",@"grad_01@2x.jpg",@"grad_05.jpg",@"grad_06.jpg",@"grad_07.jpg"];
    
    //Register remote notification types
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound)];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateData) name:kUserReloadStreamNotification object:nil];
    
    
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    __weak typeof(self) weakSelf = self;
    
    // Set up PullToRefresh for Favorite Locations
    
    [self.placesBeingWatchedTableView addPullToRefreshActionHandler:^{
        [weakSelf updateData];
    }];
    
    [self.placesBeingWatchedTableView.pullToRefreshView setImageIcon:[UIImage imageNamed:@"icon-72"]];
    [self.placesBeingWatchedTableView.pullToRefreshView setBorderWidth:6];
    //[self.placesBeingWatchedTableView.pullToRefreshView setBorderColor:<#(UIColor *)#>]
    
    
    // Set up PullToRefresh for NearbySpots
    [self.nearbySpotsCollectionView addPullToRefreshActionHandler:^{
        [weakSelf updateData];
    }];
    
    [self.nearbySpotsCollectionView.pullToRefreshView setImageIcon:[UIImage imageNamed:@"icon-72"]];
    [self.nearbySpotsCollectionView.pullToRefreshView setBorderWidth:6];
   
    
   // Set up PullToRefresh for AllSpots
    [self.allSpotsCollectionView addPullToRefreshActionHandler:^{
        [weakSelf updateData];
    }];
    
    [self.allSpotsCollectionView.pullToRefreshView setImageIcon:[UIImage imageNamed:@"icon-72"]];
    [self.allSpotsCollectionView.pullToRefreshView setBorderWidth:6];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(galleryTappedAtIndex:) name:kPhotoGalleryTappedAtIndexNotification object:nil];
    
}


-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter]
                removeObserver:self
                          name:kPhotoGalleryTappedAtIndexNotification
                        object:nil];
    
}



- (IBAction)placesButtonSelected:(UIButton *)sender {
    self.navigationItem.title = @"Places";
    
    selectedButton = kPlacesButton;
    self.noDataView.alpha = 0;
    [UIView animateWithDuration:0.5 animations:^{
        self.allSpotsCollectionView.alpha = self.nearbySpotsCollectionView.alpha = 0;
        self.placesBeingWatchedTableView.alpha = 1;
        
        /*if ([self.placesBeingWatched count] == 0) {
            [self fetchUserFavoriteLocations];
        }*/
        
        if (!self.placesBeingWatched) {
            [self fetchUserFavoriteLocations];
        }
         dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1000), dispatch_get_main_queue(),^{
            [self.placesBeingWatchedButton setSelected:YES];
            [self.nearbySpotsButton setSelected:NO];
            [self.allSpotsButton setSelected:NO];
        });
    }];
    
   
}

- (IBAction)nearbySpotsButtonSelected:(UIButton *)sender{
    self.navigationItem.title = @"Nearby Stream";
    
    selectedButton = kNearbyButton;
    self.noDataView.alpha = 0;
    [UIView animateWithDuration:0.5 animations:^{
        self.allSpotsCollectionView.alpha = self.placesBeingWatchedTableView.alpha = 0;
        self.nearbySpotsCollectionView.alpha = 1;
        
        if (!self.nearbySpots) {
            self.currentLocation = [locationManager location];
            
            if (self.currentLocation != nil){
                
                NSString *latitude = [NSString stringWithFormat:@"%.8f",self.currentLocation.coordinate.latitude];
                NSString *longitude = [NSString stringWithFormat:@"%.8f",self.currentLocation.coordinate.longitude];
                
                [self fetchNearbySpots:@{@"lat": latitude, @"lng" :longitude,@"userId" : [AppHelper userID]}];
            }
        }
        
        
        /*if (self.nearbySpots && [self.nearbySpots count] > 0) {
            self.nearbySpotsCollectionView.alpha = 1;
            self.noDataView.alpha = 0;
        }else{
            self.nearbySpotsCollectionView.alpha = 0;
            self.noDataView.alpha = 1;
        }*/
        
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1000), dispatch_get_main_queue(),^{
            [self.placesBeingWatchedButton setSelected:NO];
            [self.nearbySpotsButton setSelected:YES];
            [self.allSpotsButton setSelected:NO];
        });
    }];
    
}

- (IBAction)allSpotsButtonSelected:(UIButton *)sender {
    self.navigationItem.title = @"All Streams";
    selectedButton = kAllSpotsButton;

    self.noDataView.alpha = 0;
    [UIView animateWithDuration:0.5 animations:^{
        self.nearbySpotsCollectionView.alpha = self.placesBeingWatchedTableView.alpha = 0;
        self.allSpotsCollectionView.alpha = 1;
        
        if (!self.allSpots) {
            [self fetchUserSpots];
        }
        /*if ([self.allSpots count] == 0) {
            [self fetchUserSpots];
        }
        if (self.allSpots && [self.allSpots count] > 0) {
            self.allSpotsCollectionView.alpha = 1;
            self.noDataView.alpha = 0;
        }else{
            self.allSpotsCollectionView.alpha = 0;
            self.noDataView.alpha = 1;
        }*/
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1000), dispatch_get_main_queue(),^{
            [self.placesBeingWatchedButton setSelected:NO];
            [self.nearbySpotsButton setSelected:NO];
            [self.allSpotsButton setSelected:YES];
        });
    }];
    
    }


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Helper methods
-(void)addSpotToAllSpotsStream:(NSDictionary *)spotDetails
{
   // Check which segment is selected
    // If spot was created with a location and nearby is selected, add it
    //DLog(@"Spot that was created details - %@",spotDetails);
    
    if (![spotDetails[@"venue"] isEqualToString:@"NONE"]) {
        // Spot was created with a location so we add it to nearby spots
        if (self.nearbySpots && self.nearbySpotsCollectionView.alpha == 1) {
            [self.nearbySpots insertObject:spotDetails atIndex:0];
            [self updateCollectionView:self.nearbySpotsCollectionView
                            withUpdate:@[ [NSIndexPath indexPathForItem:0 inSection:0] ]
                            updateType:kCollectionViewUpdateInsert];
        }
    }
    
    if (self.allSpots && self.allSpotsCollectionView.alpha == 1){
        [self.allSpots insertObject:spotDetails atIndex:0];
        [self updateCollectionView:self.allSpotsCollectionView
                        withUpdate:@[ [NSIndexPath indexPathForItem:0 inSection:0] ]
                        updateType:kCollectionViewUpdateInsert];
    }
    
    if ([self.allSpots count] == 0) {
        self.allSpots = [NSMutableArray arrayWithObject:spotDetails];
        [self updateCollectionView:self.allSpotsCollectionView
                        withUpdate:@[ [NSIndexPath indexPathForItem:0 inSection:0] ]
                        updateType:kCollectionViewUpdateInsert];
        
    }
    
}


- (void)updateCollectionView:(UICollectionView *)collectionView withUpdate:(NSArray *)updates updateType:(ColectionViewUpdateType)updateType
{
    if (updateType == kCollectionViewUpdateInsert) {
        [collectionView performBatchUpdates:^{
            [collectionView insertItemsAtIndexPaths:updates];
        } completion:^(BOOL finished) {
            [collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:YES];
        }];
    }else if(updateType == kCollectionViewUpdateDelete){
       [collectionView performBatchUpdates:^{
           //DLog(@"Deleted item at index path");
           [collectionView deleteItemsAtIndexPaths:updates];
       } completion:nil];
    }
    
}


-(void)fetchUserFavoriteLocations
{
    DLog();
    // Show Activity Indicator
    [self showPlacesBeingWatchedView:YES];
    User *userInSession = [User currentlyActiveUser];
    [userInSession fetchFavoriteLocationsCompletions:^(id results, NSError *error) {
        
        [self showPlacesBeingWatchedView:NO];
        
        if (error) {
            DLog(@"Error - %@",NSStringFromClass([error class]));
        }else{
            DLog(@"Results - %@",results);
            NSArray *locationsInfo = [results objectForKey:@"watching"];
            
            if ([locationsInfo count] > 0) { // User is watching locations
                NSSortDescriptor *prettyNameDescriptor = [[NSSortDescriptor alloc] initWithKey:@"prettyName" ascending:YES];
                NSArray *sortDescriptors = [NSArray arrayWithObject:prettyNameDescriptor];
                NSArray *sortedPlaces = [locationsInfo sortedArrayUsingDescriptors:sortDescriptors];
                
                
               // if ([locationsInfo count] > 0) {
                    self.placesBeingWatched = [NSMutableArray arrayWithArray:sortedPlaces];
                    [self.placesBeingWatchedTableView reloadData];
                //}
            }else{ // User is not watching any locations
                self.placesBeingWatchedTableView.alpha = 0;
                self.noDataView.alpha = 1;
                self.noDataLabel.text = @"When you watch locations, they appear here. Tap Explore to start watching";
            }
            
         }
        
        
    }];
}



-(void)fetchUserSpots{
    DLog();
    // Show Activity Indicator
    [self showPlacesBeingWatchedView:YES];
    [[User currentlyActiveUser] loadPersonalSpotsWithCompletion:^(id results, NSError *error) {
        // Show Activity Indicator
        [self showPlacesBeingWatchedView:NO];
        if (error) {
            DLog(@"There was an error - %@",error);
        }else{
            if ([results[STATUS] isEqualToString:ALRIGHT]) {
                NSArray *spots = (NSArray *)results[@"spots"];
                
                if ([spots count] > 0){ // We've got some spots to display
                    self.noDataView.alpha = 0;
                    NSSortDescriptor *timestampDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeCreated" ascending:NO];
                    NSArray *sortDescriptors = [NSArray arrayWithObject:timestampDescriptor];
                    NSArray *sortedSpots = [spots sortedArrayUsingDescriptors:sortDescriptors];
                    
                        //DLog(@"User spots info - %@",sortedSpots[0]);
                        //if (!self.allSpots){ // If allspots is nil
                        self.allSpots = [NSMutableArray arrayWithArray:sortedSpots];
                        [self.allSpotsCollectionView reloadData];
                        
                        // }else{
                        // Change to Perform Batch updates l8er
                        //  [self.allSpotsCollectionView reloadData];
                        //}
                    

                }else{ //We've got no spots to display
                    self.allSpotsCollectionView.alpha = 0;
                    self.noDataView.alpha = 1;
                    self.noDataLabel.text = @"When you create or join spots they will appear here. Tap the plus button up top to add spots to your stream";
                }
                
                
            }
        }
    }];
}


-(void)fetchNearbySpots:(NSDictionary *)latLng
{
    DLog();
    // Show Activity Indicator
        [self showPlacesBeingWatchedView:YES];
    
        [Location fetchNearbySpots:latLng completionBlock:^(id results, NSError *error) {
            [self showPlacesBeingWatchedView:NO];
            if (error) {
                DLog(@"Error - %@",error);
            }else{
                if ([results[STATUS] isEqualToString:ALRIGHT]) {
                    
                    NSArray *nearby = results[@"nearby"];
                    
                    if ([nearby count] > 0){
                        self.noDataView.alpha = 0;
                        NSSortDescriptor *timestampDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeCreated" ascending:NO];
                        
                        NSArray *sortDescriptors = [NSArray arrayWithObject:timestampDescriptor];
                        NSArray *sortedSpots = [nearby sortedArrayUsingDescriptors:sortDescriptors];
                        
                        //DLog(@"Nearby spots - %@",self.nearbySpots);
                        
                        self.nearbySpots = [NSMutableArray arrayWithArray:sortedSpots];
                        [self.nearbySpotsCollectionView reloadData];
                        
                    }else{
                        
                        self.nearbySpotsCollectionView.alpha = 0;
                        self.noDataView.alpha = 1;
                        self.noDataLabel.text = @"When there are albums created near your location,they will appear here";
                    }
                    
                    
                }
                
                
                
            }
            
        }];
}
    
    
- (void)joinSpot:(NSString *)spotCode data:(NSDictionary *)data
{
    [[User currentlyActiveUser] joinSpotCompletionCode:spotCode completion:^(id results, NSError *error){
        if (!error) {
            if ([results[STATUS] isEqualToString:ALRIGHT]) {
                
                [self performSegueWithIdentifier:@"PhotosStreamSegue" sender:data];
                [[NSNotificationCenter defaultCenter] postNotificationName:kUserReloadStreamNotification object:nil];
                // Add a notification to tell Mainstream to reload its data
                
            }else{
                DLog(@"Error - %@",results[STATUS]);
            }
        }else{
            DLog(@"Error - %@",error);
        }
    }];
}

-(void)showPlacesBeingWatchedView:(BOOL)flag
{
    self.placesBeingWatchedLoadingView.hidden = !flag;
    if (flag == YES) {
        [self.loadingInfoIndicator startAnimating];
    }else [self.loadingInfoIndicator stopAnimating];
}


-(void)galleryTappedAtIndex:(NSNotification *)aNotification
{
    
    NSDictionary *notifInfo = [aNotification valueForKey:@"userInfo"];
    NSArray *photos = notifInfo[@"spotInfo"][@"photoURLs"];
    
    
    if (self.allSpotsCollectionView.alpha == 1) {
        [self performSegueWithIdentifier:@"PhotosStreamSegue" sender:photos];
    }else{
    self.currentSelectedSpot = notifInfo[@"spotInfo"];
    DLog(@"Notification Info - %@",notifInfo);
    NSString *isMember = notifInfo[@"spotInfo"][@"userIsMember"];
    NSString *spotCode = notifInfo[@"spotInfo"][@"spotCode"];
    NSString *spotId = notifInfo[@"spotInfo"][@"spotId"];
   // NSString *spotName = notifInfo[@"spotInfo"][@"spot"];

    DLog(@"Is user Member - %@",isMember);
    if (isMember) {
        [self performSegueWithIdentifier:@"PhotosStreamSegue" sender:photos];
    }else if ([spotCode isEqualToString:@"NONE"]) {
        
        // This album has no spot code and user is not a member, so we add user to this stream
        [[User currentlyActiveUser] joinSpot:spotId completion:^(id results, NSError *error) {
            if (!error){
                DLog(@"Album is public so joining spot");
                if ([results[STATUS] isEqualToString:ALRIGHT]){
                    
                    [AppHelper showNotificationWithMessage:@"You are now a member of this spot" type:kSUBANOTIFICATION_SUCCESS inViewController:self completionBlock:nil];
                    
                    [self performSegueWithIdentifier:@"PhotosStreamSegue" sender:photos];
                }else{
                    DLog(@"Server error - %@",error);
                }
                
            }else{
                DLog(@"Error - %@",error);
            }
        }];
    }else{
    
    //if ([isMember isEqualToString:@"NO"] && ![spotCode isEqualToString:@"N/A"])
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Join Stream" message:@"Enter code for the album you want to join" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Join", nil];
    
    alertView.alertViewStyle = UIAlertViewStyleSecureTextInput;
    [alertView show];
    }
  }
}

-(void)checkForLocation
{
    if ([CLLocationManager locationServicesEnabled]) {
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        [locationManager startMonitoringSignificantLocationChanges];
        
    }else{
        [AppHelper showAlert:@"Location Services Disabled"
                message:@"Location services is disabled for this app. Please enable location services to see nearby spots" buttons:@[@"OK"] delegate:nil];
       
    }
}



#pragma mark - UITableViewDataSource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.placesBeingWatched count];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PlacesWatchingCell *placeCell = [self.placesBeingWatchedTableView dequeueReusableCellWithIdentifier:@"PlacesWatchingCell"];
    
    placeCell.placeName.text = [self.placesBeingWatched[indexPath.row] objectForKey:@"prettyName"];
    
    NSInteger numberOfSpots = [[self.placesBeingWatched[indexPath.row] objectForKey:@"numberOfSpots"] integerValue];
    
    if (numberOfSpots > 0) {
        placeCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    
    if (numberOfSpots == 1) {
        placeCell.numberOfSpots.text = [NSString stringWithFormat:@"%@ spot",[self.placesBeingWatched[indexPath.row] objectForKey:@"numberOfSpots"]];
    }else{
       placeCell.numberOfSpots.text = [NSString stringWithFormat:@"%i spots",numberOfSpots];
    }
    
    
    return placeCell;
}


#pragma mark - UITableView Delegate 
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger numberOfSpots = [[self.placesBeingWatched[indexPath.row] objectForKey:@"numberOfSpots"] integerValue];
    
    
    if (numberOfSpots > 0) {
        [self performSegueWithIdentifier:@"FromPlacesViewToWatching"
                                  sender:@{@"spotName": self.placesBeingWatched[indexPath.row][@"prettyName"],
                                           @"spots" : self.placesBeingWatched[indexPath.row][@"spots"]}];
    }
    
}




#pragma mark - UICollection View Datasource
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;
    
    if (self.allSpotsCollectionView.alpha == 1) {
        
        numberOfRows = (self.allSpots) ? [self.allSpots count] : numberOfRows;
        //DLog(@"It is the allSpots View so number of rows = %li",(long)numberOfRows);
        
    }else if (self.nearbySpotsCollectionView.alpha == 1) {
        
        numberOfRows = (self.nearbySpots) ? [self.nearbySpots count] : numberOfRows;
    }
    
    return numberOfRows;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    self.currentIndexPath = indexPath;
    static NSString *cellIdentifier = nil;
    PersonalSpotCell *personalSpotCell = nil;
    NSArray *spotsToDisplay = nil;
    
    if (self.nearbySpotsCollectionView.alpha == 1) {
        
        cellIdentifier = @"NearbySpotCell";
        personalSpotCell = [self.nearbySpotsCollectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
        spotsToDisplay = self.nearbySpots;
        //DLog(@"Identifier set for nearby spotsCell");
        
    }else if (self.allSpotsCollectionView.alpha == 1){
        cellIdentifier = @"PersonalSpotCell";
        spotsToDisplay = self.allSpots;
        personalSpotCell = [self.allSpotsCollectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
        //DLog(@"All Spots - %@",spotsToDisplay);
    }
    
    
   
    [[personalSpotCell.photoGalleryView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    NSString *photos = spotsToDisplay[indexPath.row][@"photos"];
    //DLog(@"%@ photos - %@",spotsToDisplay[indexPath.row][@"creatorName"],photos);
    personalSpotCell.userNameLabel.text = (spotsToDisplay[indexPath.row][@"creatorName"] != NULL)?spotsToDisplay[indexPath.row][@"creatorName"] : @"";
   
    NSString *imageSrc = spotsToDisplay[indexPath.row][@"creatorPhoto"];
    [personalSpotCell.userNameView setImageWithURL:[NSURL URLWithString:imageSrc] placeholderImage:[UIImage imageNamed:@"anonymousUser"]];
    personalSpotCell.spotNameLabel.text = spotsToDisplay[indexPath.row][@"spotName"];
    personalSpotCell.spotVenueLabel.text = spotsToDisplay[indexPath.row][@"venue"];
    
    personalSpotCell.numberOfPhotosLabel.text = photos;
    personalSpotCell.photosLabel.text = ([photos integerValue] == 1) ? @"photo": @"photos";
    
    
    
    if ([photos integerValue] > 0) {  // If there are photos to display
        
        [personalSpotCell prepareForGallery:spotsToDisplay[indexPath.row] index:indexPath];
        //[personalSpotCell mScroller];

        if ([personalSpotCell.pGallery superview]) {
            [personalSpotCell.pGallery removeFromSuperview];
        }
        personalSpotCell.photoGalleryView.backgroundColor = [UIColor lightGrayColor];
        [personalSpotCell.photoGalleryView addSubview:personalSpotCell.pGallery];
        
        
    }else{
        
        UIImageView *noPhotosImageView = [[UIImageView alloc] initWithFrame:personalSpotCell.photoGalleryView.bounds];
        noPhotosImageView.image = [UIImage imageNamed:@"noPhoto"];
        noPhotosImageView.contentMode = UIViewContentModeScaleAspectFit;
        
        if ([noPhotosImageView superview]) {
            //DLog(@"View has no subviews coz there are no photos");
            [noPhotosImageView removeFromSuperview];
        }
        [personalSpotCell.photoGalleryView addSubview:noPhotosImageView];
    }
    
    
    return personalSpotCell;
}


#pragma mark - CollectionView Delegate
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger numberOfPhotos = 0;
    NSArray *spotsToDisplay = nil;
    
    if(self.allSpotsCollectionView.alpha == 1){
        numberOfPhotos = [spotsToDisplay[indexPath.item][@"photos"] integerValue];
        spotsToDisplay = self.allSpots;
        if (numberOfPhotos == 0) {
            NSString *spotID = spotsToDisplay[indexPath.item][@"spotId"];
            NSString *spotName = spotsToDisplay[indexPath.item][@"spotName"];
            //NSString *spotCode = spotsToDisplay[indexPath.item][@"spotCode"];
            NSInteger numberOfPhotos = [spotsToDisplay[indexPath.item][@"photos"] integerValue];
            NSDictionary *dataPassed = @{@"spotId": spotID,@"spotName":spotName,@"photos" : @(numberOfPhotos)};
            self.currentSelectedSpot = dataPassed;
            //NSString *isMember = spotsToDisplay[indexPath.item][@"userIsMember"];
            
            [self performSegueWithIdentifier:@"PhotosStreamSegue" sender:dataPassed];
            
        }

    }else if (self.nearbySpotsCollectionView.alpha == 1){
        
         spotsToDisplay = self.nearbySpots;
         numberOfPhotos = [spotsToDisplay[indexPath.item][@"photos"] integerValue];
        
        if (numberOfPhotos == 0){
            NSString *spotID = spotsToDisplay[indexPath.item][@"spotId"];
            NSString *spotName = spotsToDisplay[indexPath.item][@"spotName"];
            NSString *spotCode = spotsToDisplay[indexPath.item][@"spotCode"];
            NSInteger numberOfPhotos = [spotsToDisplay[indexPath.item][@"photos"] integerValue];
            NSDictionary *dataPassed = @{@"spotId": spotID,@"spotName":spotName,@"photos" : @(numberOfPhotos)};
            NSString *isMember = spotsToDisplay[indexPath.item][@"userIsMember"];
            self.currentSelectedSpot = dataPassed;
            
            if (isMember){
                
                    // User is a member so let him view photos;
                    [self performSegueWithIdentifier:@"PhotosStreamSegue" sender:dataPassed];
                    
                }else if ([spotCode isEqualToString:@"NONE"]) {
                    
                    // This album has no spot code and user is not a member, so we add user to this stream
                    [[User currentlyActiveUser] joinSpot:spotID completion:^(id results, NSError *error) {
                     if (!error){
                         DLog(@"Album is public so joining spot");
                         if ([results[STATUS] isEqualToString:ALRIGHT]){
                     
                        [[NSNotificationCenter defaultCenter] postNotificationName:kUserReloadStreamNotification object:nil];
                             
                     [AppHelper showNotificationWithMessage:[NSString stringWithFormat:@"You are now a member of the spot %@",spotName] type:kSUBANOTIFICATION_SUCCESS inViewController:self completionBlock:nil];
                     
                             [self performSegueWithIdentifier:@"PhotosStreamSegue" sender:dataPassed];
                       }else{
                         DLog(@"Server error - %@",error);
                       }
                         
                     }else{
                         DLog(@"Error - %@",error);
                     }
                 }];
              }
                    
                }else{
                    
                    //if ([isMember isEqualToString:@"NO"] && ![spotCode isEqualToString:@"N/A"])
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Join Stream" message:@"Enter code for the album you want to join" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Join", nil];
                    
                    alertView.alertViewStyle = UIAlertViewStyleSecureTextInput;
                    [alertView show];
                    
                }
            }
        }




#pragma mark - Location Manager Delegate
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    
    self.currentLocation = [locations lastObject];
    if (self.currentLocation != nil){
        
        NSString *latitude = [NSString stringWithFormat:@"%.8f",self.currentLocation.coordinate.latitude];
        NSString *longitude = [NSString stringWithFormat:@"%.8f",self.currentLocation.coordinate.longitude];
        
        [self fetchNearbySpots:@{@"lat": latitude, @"lng" :longitude,@"userId" : [AppHelper userID]}];
    }
}


#pragma mark - Pull to refresh updates
-(void)updateData
{
    DLog();
    __weak typeof(self) weakSelf = self;
    
    int64_t delayInSeconds = 1.2;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        
        if (self.placesBeingWatchedTableView.alpha == 1) { // If the places table view is visible
            
            [weakSelf fetchUserFavoriteLocations];
            
            //Stop PullToRefresh Activity Animation
            [weakSelf.placesBeingWatchedTableView stopRefreshAnimation];

        }else if (self.nearbySpotsCollectionView.alpha == 1){ // Nearby spots is visible
            DLog(@"Update nearby spots");
            if (self.currentLocation != nil){
                
                NSString *latitude = [NSString stringWithFormat:@"%.8f",self.currentLocation.coordinate.latitude];
                NSString *longitude = [NSString stringWithFormat:@"%.8f",self.currentLocation.coordinate.longitude];
                
                [weakSelf fetchNearbySpots:@{@"lat": latitude, @"lng" :longitude, @"userId" : [AppHelper userID]}];
            }
            //DLog(@"Updating nearby spots coz dats whats visible");
            [weakSelf.nearbySpotsCollectionView stopRefreshAnimation];
            
        }else if (self.allSpotsCollectionView.alpha == 1){//All spots is visible
            [weakSelf fetchUserSpots];
            
            [weakSelf.allSpotsCollectionView stopRefreshAnimation];
        }
    });
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"PhotosStreamSegue"]) {
        if ([segue.destinationViewController isKindOfClass:[PhotoStreamViewController class]]){
            PhotoStreamViewController *photosVC = segue.destinationViewController;

            if ([sender isKindOfClass:[NSArray class]]) {
                photosVC.photos = [NSMutableArray arrayWithArray:(NSArray *) sender];
                photosVC.spotName = sender[0][@"spot"];
                photosVC.spotID = sender[0][@"spotId"];
                photosVC.numberOfPhotos = 1;
            }else if([sender isKindOfClass:[NSDictionary class]]){
                photosVC.numberOfPhotos = [sender[@"photos"] integerValue];
                photosVC.spotName = sender[@"spotName"];
                photosVC.spotID = sender[@"spotId"];
            }
        }
    
    }else if ([segue.identifier isEqualToString:@"FromPlacesViewToWatching"]){
        PlacesWatchingViewController *placesVC = segue.destinationViewController;
        placesVC.spotsWatching = sender[@"spots"];
        placesVC.locationName = sender[@"spotName"];
    }
}


#pragma mark - Network changes
- (void)networkChanged:(NSNotification *)aNotification
{
     NSDictionary *notifInfo = [aNotification valueForKey:@"userInfo"];
    DLog(@"Network status : %@",notifInfo[AFNetworkingReachabilityNotificationStatusItem]);
}


#pragma mark - AlertView Delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    //DLog(@"button index - %ld",(long)buttonIndex);
    if (buttonIndex == 1) {
        NSString *passcode = [alertView textFieldAtIndex:0].text;
        [self joinSpot:passcode data:self.currentSelectedSpot];
        
    }
    
}



#pragma mark - State Preservation and Restoration
-(void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeObject:self.allSpots forKey:AllSpotsKey];
    [coder encodeObject:self.nearbySpots forKey:NearbySpotsKey];
    [coder encodeObject:self.placesBeingWatched forKey:PlacesWatchingKey];
    [coder encodeObject:self.currentSelectedSpot forKey:SelectedSpotKey];
    [coder encodeObject:@(selectedButton) forKey:SelectedButtonKey];
    
    DLog();
}


-(void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super decodeRestorableStateWithCoder:coder];
    
    self.allSpots = [coder decodeObjectForKey:AllSpotsKey];
    self.nearbySpots = [coder decodeObjectForKey:NearbySpotsKey];
    self.placesBeingWatched = [coder decodeObjectForKey:PlacesWatchingKey];
    self.currentSelectedSpot = [coder decodeObjectForKey:SelectedSpotKey];
    selectedButton = [[coder decodeObjectForKey:SelectedButtonKey] integerValue];
    
    DLog();
}

-(void)applicationFinishedRestoringState
{
    /*DLog(@"Selected Button is - %i",selectedButton);
    if (self.allSpots) {
        [self.allSpotsCollectionView reloadData];
    }*/
    
    DLog();
    
    if (selectedButton == 0) {
        // Places was the last visible view
        if (!self.placesBeingWatched) {
           [self fetchUserFavoriteLocations];
        }else [self.placesBeingWatchedTableView reloadData];
        
    }else if (selectedButton == 1){
        //DLog(@"Selected Button is - %i",selectedButton);
        // Nearby spots was the last visible view
        if (!self.nearbySpots) {
            //[self performSelector:@selector(nearbySpotsButtonSelected:)];
        }else [self.nearbySpotsCollectionView reloadData];
        
    }else{
        //DLog(@"Selected Button is - %i",selectedButton);
        if (!self.allSpots) {
          [self fetchUserSpots];
        }else [self.allSpotsCollectionView reloadData];
        
    }
    
    // Reload all the views
    //[self updateData];
}



-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:kUserReloadStreamNotification];
}



@end
