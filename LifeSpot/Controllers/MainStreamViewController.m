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

typedef enum{
    kCollectionViewUpdateInsert = 0,
    kCollectionViewUpdateDelete
}ColectionViewUpdateType;


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
- (void)updateCollectionView:(UICollectionView *)collectionView withUpdate:(NSArray *)indexPaths updateType:(ColectionViewUpdateType)updateType;
- (void)checkForLocation;
- (void)galleryTappedAtIndex:(NSNotification *)aNotification;
- (void)networkChanged:(NSNotification *)aNotification;
@end

@implementation MainStreamViewController
static CLLocationManager *locationManager;

#pragma mark - Unwind Segues
-(IBAction)unWindToSpots:(UIStoryboardSegue *)segue
{
    if ([segue.identifier isEqualToString:@"LEAVE_STREAM_SEGUE"]) {
        //Show notification
        AlbumSettingsViewController *aVC = segue.sourceViewController;
        NSString *albumName = aVC.spotName;
        
        UIColor *tintColor = [UIColor colorWithRed:(217.0f/255.0f)
                                                   green:(77.0f/255.0f)
                                                    blue:(20.0f/255.0f)
                                                   alpha:1];
        
        [CSNotificationView showInViewController:self
                                       tintColor: tintColor
                                           image:nil
                                         message:[NSString stringWithFormat:@"You are no longer a member of the album%@",albumName]
                                        duration:5.0f];
        
    }
    
    //Register remote notification types
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound)];

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
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkChanged:) name:AFNetworkingReachabilityDidChangeNotification object:nil];
    
    
}


-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter]
                removeObserver:self
                          name:kPhotoGalleryTappedAtIndexNotification
                        object:nil];
    
    [[NSNotificationCenter defaultCenter]
     removeObserver:self
     name:AFNetworkingReachabilityDidChangeNotification
     object:nil];
}


- (IBAction)placesButtonSelected:(UIButton *)sender {
    [UIView animateWithDuration:0.5 animations:^{
        self.allSpotsCollectionView.alpha = self.nearbySpotsCollectionView.alpha = 0;
        self.placesBeingWatchedTableView.alpha = 1;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1000), dispatch_get_main_queue(),^{
            [self.placesBeingWatchedButton setSelected:YES];
            [self.nearbySpotsButton setSelected:NO];
            [self.allSpotsButton setSelected:NO];
        });
    }];
    
    if (!self.placesBeingWatched) {
        [self fetchUserFavoriteLocations];
    }
}

- (IBAction)nearbySpotsButtonSelected:(UIButton *)sender{
    [UIView animateWithDuration:0.5 animations:^{
        self.allSpotsCollectionView.alpha = self.placesBeingWatchedTableView.alpha = 0;
        self.nearbySpotsCollectionView.alpha = 1;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1000), dispatch_get_main_queue(),^{
            [self.placesBeingWatchedButton setSelected:NO];
            [self.nearbySpotsButton setSelected:YES];
            [self.allSpotsButton setSelected:NO];
        });
    }];
    
}

- (IBAction)allSpotsButtonSelected:(UIButton *)sender {
    [UIView animateWithDuration:0.5 animations:^{
        self.nearbySpotsCollectionView.alpha = self.placesBeingWatchedTableView.alpha = 0;
        self.allSpotsCollectionView.alpha = 1;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1000), dispatch_get_main_queue(),^{
            [self.placesBeingWatchedButton setSelected:NO];
            [self.nearbySpotsButton setSelected:NO];
            [self.allSpotsButton setSelected:YES];
        });
    }];
    
    if (!self.allSpots) {
        [self fetchUserSpots];
    }
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
    DLog(@"Spot that was created details - %@",spotDetails);
    
    if (![spotDetails[@"venue"] isEqualToString:@"NONE"]) {
        // Spot was created with a location so we add it to nearby spots
        if (self.nearbySpots && self.nearbySpotsCollectionView.alpha == 1) {
            [self.nearbySpots insertObject:spotDetails atIndex:0];
            [self updateCollectionView:self.nearbySpotsCollectionView withUpdate:spotDetails updateType:kCollectionViewUpdateInsert];
        }
    }
    
    if (self.allSpots && self.allSpotsCollectionView.alpha == 1){
        [self.allSpots insertObject:spotDetails atIndex:0];
        [self updateCollectionView:self.allSpotsCollectionView withUpdate:spotDetails updateType:kCollectionViewUpdateInsert];
    }
    
    if ([self.allSpots count] == 0) {
        self.allSpots = [NSMutableArray arrayWithObject:spotDetails];
        [self updateCollectionView:self.allSpotsCollectionView withUpdate:spotDetails updateType:kCollectionViewUpdateInsert];
        
    }
    
}


- (void)updateCollectionView:(UICollectionView *)collectionView withUpdate:(NSDictionary *)updates updateType:(ColectionViewUpdateType)updateType
{
    if (updateType == kCollectionViewUpdateInsert) {
        [collectionView performBatchUpdates:^{
            [collectionView insertItemsAtIndexPaths:@[ [NSIndexPath indexPathForItem:0 inSection:0] ]];
        } completion:^(BOOL finished) {
            [collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:YES];
        }];
    }else if(updateType == kCollectionViewUpdateDelete){
        
    }
    
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
            
            NSSortDescriptor *prettyNameDescriptor = [[NSSortDescriptor alloc] initWithKey:@"prettyName" ascending:YES];
            NSArray *sortDescriptors = [NSArray arrayWithObject:prettyNameDescriptor];
            NSArray *sortedPlaces = [locationsInfo sortedArrayUsingDescriptors:sortDescriptors];
            
            
            if ([locationsInfo count] > 0) {
                self.placesBeingWatched = [NSMutableArray arrayWithArray:sortedPlaces];
                
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
                
                if ([sortedSpots count] > 0) {
                    
                    DLog(@"User spots info - %@",sortedSpots[0]);
                    //if (!self.allSpots){ // If allspots is nil
                    self.allSpots = [NSMutableArray arrayWithArray:sortedSpots];
                    [self.allSpotsCollectionView reloadData];
                    
                    // }else{
                    // Change to Perform Batch updates l8er
                    //  [self.allSpotsCollectionView reloadData];
                    //}
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
                    //if (!self.nearbySpots) {
                        self.nearbySpots = [NSMutableArray arrayWithArray:sortedSpots];
                        [self.nearbySpotsCollectionView reloadData];
                   // }else{
                        // Change to Perform Batch updates l8er
                      //  [self.nearbySpotsCollectionView reloadData];
                   // }
                    
                }
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
    PlacesWatchingCell *placeCell = [self.placesBeingWatchedTableView dequeueReusableCellWithIdentifier:@"PlacesWatchingCell"];
    
    placeCell.placeName.text = [self.placesBeingWatched[indexPath.row] objectForKey:@"prettyName"];
    if ([[self.placesBeingWatched[indexPath.row] objectForKey:@"spots"] integerValue] == 1) {
        placeCell.numberOfSpots.text = [NSString stringWithFormat:@"%@ spot",[self.placesBeingWatched[indexPath.row] objectForKey:@"spots"]];
    }else{
       placeCell.numberOfSpots.text = [NSString stringWithFormat:@"%@ spots",[self.placesBeingWatched[indexPath.row] objectForKey:@"spots"]];
    }
    
    
    return placeCell;
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


#pragma mark - CollectionView Delegate
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger numberOfPhotos = 0;
    NSArray *spotsToDisplay = nil;
    
    if(self.allSpotsCollectionView.alpha == 1){
        spotsToDisplay = self.allSpots;
    }else if (self.nearbySpotsCollectionView.alpha == 1) {
        spotsToDisplay = self.nearbySpots;
    }
    
     numberOfPhotos = [spotsToDisplay[indexPath.item][@"photos"] integerValue];
    DLog(@"Number of photos = %i",numberOfPhotos);
    if (numberOfPhotos == 0) {
        NSString *spotID = spotsToDisplay[indexPath.item][@"spotId"];
        NSString *spotName = spotsToDisplay[indexPath.item][@"spotName"];
        NSInteger numberOfPhotos = [spotsToDisplay[indexPath.item][@"photos"] integerValue];
        NSDictionary *dataPassed = @{@"spotId": spotID,@"spotName":spotName,@"photos" : @(numberOfPhotos)};
        [self performSegueWithIdentifier:@"PhotosStreamSegue" sender:dataPassed];
    }
    
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
        
    
    }
}


#pragma mark - Network changes
- (void)networkChanged:(NSNotification *)aNotification
{
     NSDictionary *notifInfo = [aNotification valueForKey:@"userInfo"];
    DLog(@"Network status : %@",notifInfo[AFNetworkingReachabilityNotificationStatusItem]);
}



@end
