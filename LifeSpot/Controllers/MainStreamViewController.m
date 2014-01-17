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


@interface MainStreamViewController()<UITableViewDataSource,UITableViewDelegate,UICollectionViewDataSource,UICollectionViewDelegate,CLLocationManagerDelegate>

@property (strong,nonatomic) NSMutableArray *placesBeingWatched;
@property (strong,nonatomic) NSMutableArray *nearbySpots;
@property (strong,nonatomic) NSMutableArray *allSpots;
@property (strong,nonatomic) NSIndexPath *currentIndexPath;
@property (strong,nonatomic) NSArray *images;
@property (retain,nonatomic) CLLocation *currentLocation;

@property (weak, nonatomic) IBOutlet UIButton *placesBeingWatchedButton;
@property (weak, nonatomic) IBOutlet UIButton *nearbySpotsButton;
@property (weak, nonatomic) IBOutlet UIButton *allSpotsButton;
@property (weak, nonatomic) IBOutlet UITableView *placesBeingWatchedTableView;
@property (weak, nonatomic) IBOutlet UIView *placesBeingWatchedLoadingView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingInfoIndicator;
@property (weak, nonatomic) IBOutlet UICollectionView *nearbySpotsCollectionView;
@property (weak, nonatomic) IBOutlet UICollectionView *allSpotsCollectionView;



- (IBAction)unWindToSpots:(UIStoryboardSegue *)segue;
- (IBAction)unWindToAllSpotsWithCreatedSpot:(UIStoryboardSegue *)segue;

- (IBAction)placesButtonSelected:(UIButton *)sender;
- (IBAction)nearbySpotsButtonSelected:(UIButton *)sender;
- (IBAction)allSpotsButtonSelected:(UIButton *)sender;

- (void)addSpotToAllSpotsStream:(NSDictionary *)spotDetails;
- (void)fetchUserFavoriteLocations;
- (void)fetchUserSpots;
- (void)fetchNearbySpots:(NSDictionary *)latLng;
- (void)showPlacesBeingWatchedView:(BOOL)flag;
- (void)updateData;
- (void)updateCollectionView:(NSArray *)spots withUpdate:(NSArray *)updates;
- (void)checkForLocation;
- (void)galleryTappedAtIndex:(NSNotification *)aNotification;
@end

@implementation MainStreamViewController
static CLLocationManager *locationManager;

#pragma mark - Unwind Segues
-(IBAction)unWindToSpots:(UIStoryboardSegue *)segue
{
    
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

- (IBAction)placesButtonSelected:(UIButton *)sender {
    [UIView animateWithDuration:0.5 animations:^{
        self.allSpotsCollectionView.alpha = self.nearbySpotsCollectionView.alpha = 0;
        self.placesBeingWatchedTableView.alpha = 1;
    }];
    
    if (!self.placesBeingWatched) {
        [self fetchUserFavoriteLocations];
    }
}

- (IBAction)nearbySpotsButtonSelected:(UIButton *)sender{
    [UIView animateWithDuration:0.5 animations:^{
        self.allSpotsCollectionView.alpha = self.placesBeingWatchedTableView.alpha = 0;
        self.nearbySpotsCollectionView.alpha = 1;
    }];
}

- (IBAction)allSpotsButtonSelected:(UIButton *)sender {
    [UIView animateWithDuration:0.5 animations:^{
        self.nearbySpotsCollectionView.alpha = self.placesBeingWatchedTableView.alpha = 0;
        self.allSpotsCollectionView.alpha = 1;
    }];
    
    if (!self.allSpots) {
        [self fetchUserSpots];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    //self.allSpots = [NSMutableArray arrayWithCapacity:5];
    
    self.placesBeingWatchedTableView.alpha = 0;
    self.allSpotsCollectionView.alpha = 0;
    [self.nearbySpotsButton setSelected:YES];
    
    self.placesBeingWatchedLoadingView.hidden = YES;
    [self checkForLocation];
    self.currentLocation = [locationManager location];
    
    if (self.currentLocation != nil) {
        
        NSString *latitude = [NSString stringWithFormat:@"%.8f",self.currentLocation.coordinate.latitude];
        NSString *longitude = [NSString stringWithFormat:@"%.8f",self.currentLocation.coordinate.longitude];
        
        [self fetchNearbySpots:@{@"lat": latitude, @"lng" :longitude}];
    }else{
        [self showPlacesBeingWatchedView:YES];
    }
    
    self.images = @[@"gard_12.jpg",@"grad_01@2x.jpg",@"grad_05.jpg",@"grad_06.jpg",@"grad_07.jpg"];
    
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


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Helper methods
-(void)addSpotToAllSpotsStream:(NSDictionary *)spotDetails
{
    
}

-(void)fetchUserFavoriteLocations
{
    // Show Activity Indicator
    [self showPlacesBeingWatchedView:YES];
    User *userInSession = [User currentlyActiveUser];
    [userInSession fetchFavoriteLocationsCompletions:^(id results, NSError *error) {
        
        [self showPlacesBeingWatchedView:NO];
        
        if (error) {
            DLog(@"Error - %@",error);
        }else{
            NSArray *locationsInfo = [results objectForKey:@"watching"];
            if ([locationsInfo count] > 0) {
                self.placesBeingWatched = [NSMutableArray arrayWithArray:locationsInfo];
                
                [self.placesBeingWatchedTableView reloadData];
            }
         }
    }];
}

-(void)fetchUserSpots{
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
                
                NSSortDescriptor *timestampDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeCreated" ascending:NO];
                NSArray *sortDescriptors = [NSArray arrayWithObject:timestampDescriptor];
                NSArray *sortedSpots = [spots sortedArrayUsingDescriptors:sortDescriptors];
                
                if (!self.allSpots) { // If allspots is nil
                    self.allSpots = [NSMutableArray arrayWithArray:sortedSpots];
                    [self.allSpotsCollectionView reloadData];
                }else{
                    // Change to Perform Batch updates l8er
                    [self.allSpotsCollectionView reloadData];
                }
            }
        }
    }];
}


-(void)fetchNearbySpots:(NSDictionary *)latLng
{
    // Show Activity Indicator
        [self showPlacesBeingWatchedView:YES];
    
        [Location fetchNearbySpots:latLng completionBlock:^(id results, NSError *error) {
            [self showPlacesBeingWatchedView:NO];
            if (error) {
                DLog(@"Error - %@",error);
            }else{
                if ([results[STATUS] isEqualToString:ALRIGHT]) {
                    
                    NSArray *nearby = results[@"nearby"];
                    NSSortDescriptor *timestampDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeCreated" ascending:NO];
                    
                    NSArray *sortDescriptors = [NSArray arrayWithObject:timestampDescriptor];
                    NSArray *sortedSpots = [nearby sortedArrayUsingDescriptors:sortDescriptors];
                    
                    //DLog(@"Nearby spots - %@",self.nearbySpots);
                    if (!self.nearbySpots) {
                        self.nearbySpots = [NSMutableArray arrayWithArray:sortedSpots];
                        [self.nearbySpotsCollectionView reloadData];
                    }else{
                        // Change to Perform Batch updates l8er
                        [self.nearbySpotsCollectionView reloadData];
                    }
                    
                }
            }
            
        }];
}
    
    

-(void)updateCollectionView:(NSArray *)spots withUpdate:(NSArray *)updates
{
    
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
    NSArray *photos = notifInfo[@"photoURLs"];
    //DLog(@"Notification Info - %@",photos);
    [self performSegueWithIdentifier:@"PhotosStreamSegue" sender:photos];
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
    PlacesWatchingCell *placeCell = [tableView dequeueReusableCellWithIdentifier:@"PlacesWatchingCell"];
    
    placeCell.placeName.text = [self.placesBeingWatched[indexPath.row] objectForKey:@"prettyName"];
    placeCell.numberOfSpots.text = [NSString stringWithFormat:@"%@ spots",[self.placesBeingWatched[indexPath.row] objectForKey:@"spots"]];
    
    return placeCell;
}

#pragma mark - UICollection View Datasource
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;
    //DLog(@"%i spots",[self.allSpots count]);
    if (self.allSpotsCollectionView.alpha == 1) {
        
        numberOfRows = (self.allSpots) ? [self.allSpots count] : numberOfRows;
        DLog(@"It is the allSpots View so number of rows = %li",(long)numberOfRows);
        
    }else if (self.nearbySpotsCollectionView.alpha == 1) {
        
        numberOfRows = (self.nearbySpots) ? [self.nearbySpots count] : numberOfRows; 
        //DLog(@"It is the nearbySpots View so number of rows = %li",(long)numberOfRows);
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
        spotsToDisplay = self.nearbySpots;
        //DLog(@"Identifier set for nearby spotsCell");
        
    }else if (self.allSpotsCollectionView.alpha == 1){
        cellIdentifier = @"PersonalSpotCell";
        spotsToDisplay = self.allSpots;
        
        DLog(@"All Spots - %@",spotsToDisplay);
    }
    
     personalSpotCell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
   
    [[personalSpotCell.photoGalleryView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    NSString *photos = spotsToDisplay[indexPath.row][@"photos"];
    //DLog(@"%@ photos - %@",spotsToDisplay[indexPath.row][@"creatorName"],photos);
    personalSpotCell.userNameLabel.text = (spotsToDisplay[indexPath.row][@"creatorName"] != NULL)?spotsToDisplay[indexPath.row][@"creatorName"] : @"";
   
    NSString *imageSrc = spotsToDisplay[indexPath.row][@"creatorPhoto"];
    [personalSpotCell.userNameView setImageWithURL:[NSURL URLWithString:imageSrc]];
    personalSpotCell.spotNameLabel.text = spotsToDisplay[indexPath.row][@"spotName"];
    personalSpotCell.spotVenueLabel.text = spotsToDisplay[indexPath.row][@"venue"];
    
    personalSpotCell.numberOfPhotosLabel.text = photos;
    personalSpotCell.photosLabel.text = ([photos integerValue] == 1) ? @"photo": @"photos";
    
    
    
    if ([photos integerValue] > 0) {  // If there are photos to display
        
        [personalSpotCell prepareForGallery:spotsToDisplay[indexPath.row][@"photoURLs"] index:indexPath];
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



#pragma mark - Location Manager Delegate
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    
    self.currentLocation = [locations lastObject];
    if (self.currentLocation != nil){
        
        NSString *latitude = [NSString stringWithFormat:@"%.8f",self.currentLocation.coordinate.latitude];
        NSString *longitude = [NSString stringWithFormat:@"%.8f",self.currentLocation.coordinate.longitude];
        
        [self fetchNearbySpots:@{@"lat": latitude, @"lng" :longitude}];
    }
}


#pragma mark - Pull to refresh updates
-(void)updateData
{
    __weak typeof(self) weakSelf = self;
    
    int64_t delayInSeconds = 1.2;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        
        if (self.placesBeingWatchedTableView.alpha == 1) { // If the places table view is visible
            
            [weakSelf fetchUserFavoriteLocations];
            
            //Stop PullToRefresh Activity Animation
            [weakSelf.placesBeingWatchedTableView stopRefreshAnimation];

        }else if (self.nearbySpotsCollectionView.alpha == 1){ // Nearby spots is visible
            if (self.currentLocation != nil){
                
                NSString *latitude = [NSString stringWithFormat:@"%.8f",self.currentLocation.coordinate.latitude];
                NSString *longitude = [NSString stringWithFormat:@"%.8f",self.currentLocation.coordinate.longitude];
                
                [weakSelf fetchNearbySpots:@{@"lat": latitude, @"lng" :longitude}];
            }
            //DLog(@"Updating nearby spots coz dats whats visible");
            [weakSelf.nearbySpotsCollectionView stopRefreshAnimation];
        }else if (self.allSpotsCollectionView.alpha == 1){//All spots is visible
            [weakSelf fetchUserSpots];
            //DLog(@"Updating all spots coz dats whats visible");
            [weakSelf.allSpotsCollectionView stopRefreshAnimation];
        }
    });
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"PhotosStreamSegue"]) {
        if ([segue.destinationViewController isKindOfClass:[PhotoStreamViewController class]]) {
            PhotoStreamViewController *photosVC = segue.destinationViewController;
            photosVC.photos = [NSMutableArray arrayWithArray:(NSArray *) sender];
            photosVC.spotName = sender[0][@"spot"];
            photosVC.spotID = sender[0][@"spotId"];
        }
    }
}

@end
