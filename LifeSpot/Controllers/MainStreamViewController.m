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
#import "UserProfileViewController.h"
#import "Location.h"
#import "StreamSettingsViewController.h"
#import "PlacesWatchingViewController.h"
#import "S3PhotoFetcher.h"
#import "DACircularProgressView.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "NearbyStreamsHeaderView.h"
#import "StreamTypeViewController.h"
#import "Branch.h"

typedef void (^SBCurrentLocationCompletionHandler) (NSDictionary *latlng,NSError *error);
typedef void (^SBNewStreamsCompletionHandler) (BOOL newstreams);

typedef enum{
    kCollectionViewUpdateInsert = 0,
    kCollectionViewUpdateDelete
}ColectionViewUpdateType;


typedef enum{
    kPlacesButton = 0,
    kNearbyButton,
    kAllSpotsButton
}SelectedButton;


typedef enum{
    kPlacesCoachMark = 555,
    kNearbyCoachMark = 777,
    kMyStreamCoachMark = 888,
    kCreateSpotCoachMark = 999,
    kExploreCoachMark = 444
}CoachMark;


#define PlacesWatchingKey @"PlacesWatchingKey"
#define NearbySpotsKey @"NearbySpotsKey"
#define AllSpotsKey @"AllSpotsKey"
#define SelectedSpotKey @"SelectedSpotKey"
#define SelectedButtonKey @"SelectedButtonKey"


@interface MainStreamViewController()<UICollectionViewDataSource,UICollectionViewDelegate,CLLocationManagerDelegate,UIAlertViewDelegate,UITextFieldDelegate,UIGestureRecognizerDelegate>

@property (strong,nonatomic) NSMutableArray *nearbyStreams;
@property (strong,nonatomic) NSDictionary *currentSelectedSpot;
@property (strong,nonatomic) NSIndexPath *currentIndexPath;
@property (retain,nonatomic) CLLocation *currentLocation;
@property (strong,nonatomic) NSArray *globalStreams;

@property (weak, nonatomic) IBOutlet UIScrollView *welcomeBackUserFullNameView;

@property (weak, nonatomic) IBOutlet UICollectionView *noLocationCollectionView;
@property (weak, nonatomic) IBOutlet UICollectionView *noNearbyStreamsCollectionView;

@property (weak, nonatomic) IBOutlet UIView *firstLaunchView;
@property (weak, nonatomic) IBOutlet UIScrollView *welcomeBackView;
@property (weak, nonatomic) IBOutlet UITextField *firstNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *lastNameTextField;
@property (weak, nonatomic) IBOutlet UIButton *enterSubaButton;

@property (weak,nonatomic) IBOutlet UITextField *searchBarField;

@property (weak, nonatomic) IBOutlet UIView *seeNearbyStreamsView;

@property (weak, nonatomic) IBOutlet UIView *coachMarkView;

@property (weak, nonatomic) IBOutlet UIButton *gotItButton;

@property (weak, nonatomic) IBOutlet UIView *placesBeingWatchedLoadingView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingInfoIndicator;
@property (weak, nonatomic) IBOutlet UICollectionView *nearbySpotsCollectionView;
@property (weak, nonatomic) IBOutlet UICollectionView *allSpotsCollectionView;

@property (weak, nonatomic) IBOutlet UIImageView *coachMarkImage;
@property (retain, nonatomic) IBOutlet UIBarButtonItem *plusicon;
@property (weak, nonatomic) IBOutlet UILabel *welcomeTextLabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *searchBarButton;

- (IBAction)unWindToSpots:(UIStoryboardSegue *)segue;
- (IBAction)unWindToAllSpotsWithCreatedSpot:(UIStoryboardSegue *)segue;
- (IBAction)unWindToMainStream:(UIStoryboardSegue *)segue;

- (void)addSpotToAllSpotsStream:(NSDictionary *)spotDetails;
//- (void)fetchUserFavoriteLocations;
//- (void)fetchUserSpots;
- (void)fetchNearbySpots:(NSDictionary *)latLng completion:(SBNewStreamsCompletionHandler)completionHandler;
- (void)dataLoadingView:(BOOL)flag;
- (void)updateData;
- (void)refreshAllStreams;
- (void)updateCollectionView:(UICollectionView *)collectionView withUpdate:(NSArray *)indexPaths updateType:(ColectionViewUpdateType)updateType;
- (void)checkForLocation;
- (void)galleryTappedAtIndex:(NSNotification *)aNotification;
- (void)updateStreamInfo:(NSNotification *)aNotification;
- (void)showSearchBar;
- (void)fetchGlobalStreams;
- (void)makeInitialPlaceholderView:(UIView *)contextView name:(NSString *)person;
- (NSString *)initialStringForPersonString:(NSString *)personString;
- (UIColor *)circleColor;

- (IBAction)searchForStream:(UIBarButtonItem *)sender;
- (void)fillView:(UIView *)view WithImage:(NSString *)imageURL;

//- (void)networkChanged:(NSNotification *)aNotification;
//- (IBAction)switchCoachMark:(UIButton *)sender;
- (IBAction)showuserProfile:(UIButton *)sender;
- (IBAction)actionBtn:(id)sender;
- (IBAction)showCreateStream:(id)sender;
- (IBAction)createFirstStream:(id)sender;
- (IBAction)dismissFirstTimeView:(id)sender;
- (IBAction)enterSubaWithFullName:(UIButton *)sender;
- (void)hidePromptForSeeNearbyStreams;
- (NSArray *)filterNearbyStreamsForGlobalStreams:(NSArray *)nearbyStreams;
- (BOOL)areNearbyStreamsAvailable;
- (void)showNearbyStreamsCollectionView;
- (void)showNoNearbyStreamsCollectionView;
- (void)moveToUserProfile:(UITapGestureRecognizer *)sender;
- (void)moveToPhotoStream:(NSDictionary *)dataPassed;
@end

@implementation MainStreamViewController
int searchBartoggler;

static CLLocationManager *locationManager;
static NSInteger selectedButton = 10;

#pragma mark - Unwind Segues
-(IBAction)unWindToSpots:(UIStoryboardSegue *)segue
{
    if ([segue.identifier isEqualToString:@"LEAVE_STREAM_SEGUE"]) {
        //Show notification
        StreamSettingsViewController *aVC = segue.sourceViewController;
        NSString *albumName = aVC.spotName;
        NSString *spotId = aVC.spotID;
        NSString *streamCreator = aVC.streamCreator;
        
        int counter = 0;
        if ([[AppHelper userName] isEqualToString:streamCreator]){
            
            for (NSDictionary *spotToRemove in self.nearbyStreams){
                
                if ([spotToRemove[@"spotId"] integerValue] == [spotId integerValue]){
                    
                    [self.nearbyStreams removeObject:spotToRemove];
                    
                    break;
                    
                }
                counter += 1;
            }
            
            if (self.nearbySpotsCollectionView.alpha == 1) {
                [self updateCollectionView:self.nearbySpotsCollectionView
                                withUpdate:@[[NSIndexPath indexPathForItem:counter inSection:0]]
                                updateType:kCollectionViewUpdateDelete];
            }
            
            

            
            UIColor *tintColor = [UIColor colorWithRed:(217.0f/255.0f)
                                                 green:(77.0f/255.0f)
                                                  blue:(20.0f/255.0f)
                                                 alpha:1];
            
            [CSNotificationView showInViewController:self
                                           tintColor: tintColor
                                               image:nil
                                             message:[NSString stringWithFormat:
                                                      @"%@ removed from your nearby streams",albumName]
                                            duration:2.0f];
            
        }

     }
}

-(IBAction)unWindToAllSpotsWithCreatedSpot:(UIStoryboardSegue *)segue
{
    if ([segue.identifier isEqualToString:@"spotWasCreatedSegue"]) {
        CreateSpotViewController *csVC = segue.sourceViewController;
        NSDictionary *spotDetails = csVC.createdSpotDetails;
        [self addSpotToAllSpotsStream:spotDetails];
    }
}

-(void)unWindToMainStream:(UIStoryboardSegue *)segue
{
    if([segue.identifier isEqualToString:@"JoinAnotherStream"]){
        // What if we're coming from photo stream VC, hmmm...
        Branch *branch = [Branch getInstance:@"55726832636395855"];
        NSDictionary *params = [branch getReferringParams];
        if ([params count] > 0) {
            // Prepare info for segue
            NSString *numberOfPhotos = params[@"photos"];
            NSString *streamName = params[@"streamName"];
            NSString *streamId = params[@"streamId"];
            NSString *streamCode = params[@"streamCode"];
            
            NSDictionary *inviteInfo = @{@"photos":numberOfPhotos,@"spotName":streamName,@"spotId":streamId};
            
            [self joinSpot:streamCode data:inviteInfo completion:^(id results, NSError *error) {
                [self performSegueWithIdentifier:kPhotosStreamSegue sender:inviteInfo];
            }];

        }
        
    }
}


#pragma mark - View life cycle
- (void)canWeJoinStreamFromInvite
{
    // Get the current referring params if we still have one
    Branch *branch = [Branch getInstance:@"55726832636395855"];
    NSDictionary *params = [branch getReferringParams];
    if (![self.view viewWithTag:4]) {
        DLog(@"Referring params: %@",params);
        if ([params count] > 0){
            
            // Prepare info for segue
            NSString *numberOfPhotos = (params[@"photos"]) ? params[@"photos"] : @(0);
            NSString *streamName = params[@"streamName"];
            NSString *streamId = params[@"streamId"];
            NSString *streamCode = params[@"streamCode"];
            
            NSDictionary *inviteInfo = @{@"photos":numberOfPhotos,@"spotName":streamName,@"spotId":streamId};
            
            [self joinSpot:streamCode data:inviteInfo completion:^(id results, NSError *error){
                [AppHelper clearPendingInvites:params];
                if (self.navigationController){
                    [self performSegueWithIdentifier:kPhotosStreamSegue sender:inviteInfo];
                }
                
            }];
        }
    }
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //[self.plusicon setImage:[UIImage imageNamed:@"PlusIconWhite"]];
    [self.searchBarButton setImage:[IonIcons imageWithIcon:icon_ios7_search size:48 color:[UIColor whiteColor]]];
    
    UIImageView *navImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 50, 40)];
    navImageView.contentMode = UIViewContentModeScaleAspectFit;
    navImageView.image = [UIImage imageNamed:@"logo"];
    
    self.navigationItem.titleView = navImageView;
    self.welcomeBackView.alpha = 0;
    //self.enterSubaButton.enabled = YES;
    
    self.noLocationCollectionView.alpha = 0;
    self.noNearbyStreamsCollectionView.alpha = 0;
    
    self.welcomeTextLabel.text = [NSString stringWithFormat:@"Welcome, %@!",[AppHelper firstName]];
    
    [Flurry logAllPageViews:self.tabBarController];
    
    //Register remote notification types
    //[[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound)];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshAllStreams) name:kUserReloadStreamNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateStreamInfo:) name:kUpdateStreamNotification object:nil];
    
    if ([[AppHelper myStreamsCoachMarkSeen] isEqualToString:@"NO"]) {
        // Show the places coachmark
        self.coachMarkView.alpha = 1;
        self.gotItButton.alpha = 1;
        [AppHelper setMyStreamCoachMark:@"YES"];
        
        self.coachMarkImage.alpha = 1;
        [self.coachMarkImage setTag:kMyStreamCoachMark];
    }
    
       [self followScrollView:self.nearbySpotsCollectionView];
  
       //[self fetchGlobalStreams];
    
       [self checkForLocation];
    
    if (([[AppHelper firstName] isEqualToString:@""] || [AppHelper firstName] == NULL)
        && ([[AppHelper lastName] isEqualToString:@""] || [AppHelper lastName] == NULL)){
        if (self.welcomeBackView.alpha == 0){
            [UIView animateWithDuration:.5 animations:^{
                
                DLog(@"We have to show the welcome view");
                self.welcomeBackView.alpha = 1;
                [self.navigationController setNavigationBarHidden:YES animated:YES];
                self.tabBarController.tabBar.hidden = YES;
            }];
        }
        
    }
     
        
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
        // Suba does not have access to location
        DLog(@"Showing No Location collection view");
        self.nearbySpotsCollectionView.alpha = 0;
        self.noNearbyStreamsCollectionView.alpha = 0;
        self.noLocationCollectionView.alpha = 1;
        
    }else if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized){
        
        DLog(@"We have Location access");
        if (self.currentLocation == nil){
            self.currentLocation = [locationManager location];
            if (!self.nearbyStreams){
                // Let's check whether we can show the welcome view
                if (([[AppHelper firstName] isEqualToString:@""] || [AppHelper firstName] == NULL)
                    && ([[AppHelper lastName] isEqualToString:@""] || [AppHelper lastName] == NULL)){
                    if (self.welcomeBackView.alpha == 0){
                        [UIView animateWithDuration:.5 animations:^{
                            
                            DLog(@"We have to show the welcome view");
                            self.welcomeBackView.alpha = 1;
                            [self.navigationController setNavigationBarHidden:YES animated:YES];
                            self.tabBarController.tabBar.hidden = YES;
                        }];
                    }
                    
            }else{
                [AppHelper setUserSession:@"login"];
                NSString *latitude  =  [NSString stringWithFormat:@"%.8f",self.currentLocation.coordinate.latitude];
                NSString *longitude = [NSString stringWithFormat:@"%.8f",self.currentLocation.coordinate.longitude];
                DLog(@"We've got location so fetching nearby locations");
                [self fetchNearbySpots:@{@"lat": latitude, @"lng" :longitude,@"userId" : [AppHelper userID]} completion:nil];
             }
        }
      }
    }
    
    /*else{
        DLog(@"give access to location");
        //[self checkForLocation];
    }*/

   
    // If we are coming from an invite
    [self canWeJoinStreamFromInvite];
}


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    __weak typeof(self) weakSelf = self;
    
    // Set up PullToRefresh for NearbySpots
    [self.nearbySpotsCollectionView addPullToRefreshActionHandler:^{
        [weakSelf updateData];
    }];
    
    [self.nearbySpotsCollectionView.pullToRefreshView setImageIcon:[UIImage imageNamed:@"icon-72"]];
    [self.nearbySpotsCollectionView.pullToRefreshView setBorderWidth:6];
    
    [self.noLocationCollectionView addPullToRefreshActionHandler:^{
        [weakSelf updateData];
    }];
    
    [self.noLocationCollectionView.pullToRefreshView setImageIcon:[UIImage imageNamed:@"icon-72"]];
    [self.noLocationCollectionView.pullToRefreshView setBorderWidth:6];
    
    [self.noNearbyStreamsCollectionView addPullToRefreshActionHandler:^{
        [weakSelf updateData];
    }];
    
    [self.noNearbyStreamsCollectionView.pullToRefreshView setImageIcon:[UIImage imageNamed:@"icon-72"]];
    [self.noNearbyStreamsCollectionView.pullToRefreshView setBorderWidth:6];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(galleryTappedAtIndex:) name:kPhotoGalleryTappedAtIndexNotification object:nil];
    
    if ([AppHelper inviteCodeDetails]){
        //DLog(@"Invite code details - %@",[AppHelper inviteCodeDetails]);
        self.firstLaunchView.alpha = 0;
    }
    
    
    if (self.firstLaunchView.alpha == 1){
        [UIView animateWithDuration:.8 animations:^{
           // self.navigationController.navigationBar.alpha = 0;
            //[self.navigationController setNavigationBarHidden:YES animated:YES];
            //self.tabBarController.tabBar.hidden = YES;
        }];
        
    }
    
    if (IS_OS_7_OR_BEFORE) {
        DLog(@"IOS 7");
        [locationManager startUpdatingLocation];
    }else if(IS_OS_8_OR_LATER){
        [locationManager requestWhenInUseAuthorization];
    }

    

    
    
    // Check whether Suba has access to location
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
        // Suba does not have access to location
        DLog(@"Showing No Location collection view");
        self.nearbySpotsCollectionView.alpha = 0;
        self.noNearbyStreamsCollectionView.alpha = 0;
        self.noLocationCollectionView.alpha = 1;
    }else if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized){
        if (self.currentLocation == nil){
            self.currentLocation = [locationManager location];
            if (!self.nearbyStreams){
                
                // Let's check whether we can show the welcome view
                if (([[AppHelper firstName] isEqualToString:@""] || [AppHelper firstName] == NULL)
                    && ([[AppHelper lastName] isEqualToString:@""] || [AppHelper lastName] == NULL)){
                    if (self.welcomeBackView.alpha == 0){
                        [UIView animateWithDuration:.5 animations:^{
                            
                            DLog(@"We have to show the welcome view");
                            self.welcomeBackView.alpha = 1;
                            [self.navigationController setNavigationBarHidden:YES animated:YES];
                            self.tabBarController.tabBar.hidden = YES;
                        }];
                    }
                    
                }else{
                    

                [AppHelper setUserSession:@"login"];
                NSString *latitude  =  [NSString stringWithFormat:@"%.8f",self.currentLocation.coordinate.latitude];
                NSString *longitude = [NSString stringWithFormat:@"%.8f",self.currentLocation.coordinate.longitude];
                DLog(@"We've got location so fetching nearby locations");
                [self fetchNearbySpots:@{@"lat": latitude, @"lng" :longitude,@"userId" : [AppHelper userID]} completion:nil];
                
            }
        }
    }
  }
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    /*if ([AppHelper inviteCodeDetails]){
        
        DLog(@"Invite code details - %@",[AppHelper inviteCodeDetails]);
        
        NSDictionary *streamInfo = @{@"spotId": [AppHelper inviteCodeDetails][@"streamId"],
                                     @"spotName" : [AppHelper inviteCodeDetails][@"streamName"],
                                     @"photos" : [AppHelper inviteCodeDetails][@"photos"]};
        
        if(![[AppHelper userName] isEqualToString:@""])
        {
            [[User currentlyActiveUser] joinSpot:streamInfo[@"spotId"] completion:^(id results, NSError *error) {
                if (!error) {
                    if ([results[STATUS] isEqualToString:ALRIGHT]) {
                        DLog(@"Results - %@",results);
                    }else{
                        DLog(@"Error - %@",results);
                    }
                }
            }];
        }
        
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:ACTIVE_SPOT_CODE];
        [self performSegueWithIdentifier:@"PhotosStreamSegue" sender:streamInfo];
        
    }else{
        DLog("Active code not set");
    }*/
    
    NSInteger appsessions = [AppHelper appSessions];
    
    if (appsessions % 10 == 0 && [[AppHelper hasUserInvited] isEqualToString:@"NO"]) {
        
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Tell your friends about Suba"
                                                        message:@"Enjoying Suba? The Suba team is working really hard on making the app even better, and it'd mean a lot if you got a few friends to check us out. Want to tell a friend about Suba?" delegate:self
                                              cancelButtonTitle:@"Later"
                                              otherButtonTitles:@"Invite", nil];
        
        alert.tag = 100;
        [alert show];
    }
    
    
    // Let user update his full name if they're not set
    
    DLog(@"User first name - %@\nLastName - %@",[AppHelper firstName],[AppHelper lastName]);
     if (([[AppHelper firstName] isEqualToString:@""] || [AppHelper firstName] == NULL)
        && ([[AppHelper lastName] isEqualToString:@""] || [AppHelper lastName] == NULL)){
         if (self.welcomeBackView.alpha == 0){
             [UIView animateWithDuration:.5 animations:^{
                 
                 DLog(@"We have to show the welcome view");
                 self.welcomeBackView.alpha = 1;
                 [self.navigationController setNavigationBarHidden:YES animated:YES];
                 self.tabBarController.tabBar.hidden = YES;
             }];
         }

    }
    
    
    // Check whether we show first time view
    if ([AppHelper showFirstTimeView] == YES) {
        DLog(@"We have to show the first time view");
        [UIView animateWithDuration:.5 animations:^{
            self.firstLaunchView.alpha = 1;
            //self.navigationController.navigationBarHidden = YES;
            //self.tabBarController.tabBar.hidden = YES;
        }];
    }
}


-(void)viewWillDisappear:(BOOL)animated
{
    //DLog();
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter]
     removeObserver:self
     name:kPhotoGalleryTappedAtIndexNotification
     object:nil];
    
    selectedButton = 10;
    [locationManager stopUpdatingLocation];
    self.currentLocation = nil;
}


-(void)moveToUserProfile:(UITapGestureRecognizer *)sender
{
    //DLog(@"Showing userprofile with uview - %@",sender.view);
    
    // Get the container view and increase height
    //DLog(@"Sender superview - %@",sender.view.superview.superview);
    
    if (sender.state == UIGestureRecognizerStateEnded){
        PersonalSpotCell *pCell = (PersonalSpotCell *)sender.view.superview.superview;
        NSIndexPath *indexPath = [self.nearbySpotsCollectionView indexPathForCell:pCell];
        NSDictionary *cellInfo = nil;
        
        NSString *userID = nil;
        if (self.nearbySpotsCollectionView.alpha == 1 || self.noNearbyStreamsCollectionView.alpha == 1) {
            cellInfo = self.nearbyStreams[indexPath.item];
        }else{
            cellInfo = self.globalStreams[indexPath.item];
        }
        if (sender.view.tag % 10000 == 1) {
            // First Member was tapped
            //DLog(@"First Member photo was tapped");
            userID = cellInfo[@"firstMemberID"];
        }else if (sender.view.tag % 10000 == 2){
            // Second Member View was tapped
            userID = cellInfo[@"secondMemberID"];
            //DLog(@"Second Member photo was tapped");
        }else if (sender.view.tag % 10000 == 3){
            // Third Member was tapped
            userID = cellInfo[@"thirdMemberID"];
            //DLog(@"Third Member photo was tapped");
        }
        
        [self performSegueWithIdentifier:@"MAINSTREAM_USERPROFILE_SEGUE" sender:userID];
    }
}


- (IBAction)showuserProfile:(UIButton *)sender
{
    
        PersonalSpotCell *pCell = (PersonalSpotCell *)sender.superview.superview;
        NSIndexPath *indexPath = [self.nearbySpotsCollectionView indexPathForCell:pCell];
        NSDictionary *cellInfo = nil;
        if (self.nearbySpotsCollectionView.alpha == 1 || self.noNearbyStreamsCollectionView.alpha == 1) {
            cellInfo = self.nearbyStreams[indexPath.item];
        }else{
            cellInfo = self.globalStreams[indexPath.item];
        }
        NSString *streamCreatorId = cellInfo[@"creatorId"];;
    
        //DLog(@"User Profile to look at - %@",[cellInfo description]);
        [self performSegueWithIdentifier:@"MAINSTREAM_USERPROFILE_SEGUE" sender:streamCreatorId];
}


- (IBAction)actionBtn:(id)sender
{
   
}


- (IBAction)showCreateStream:(id)sender
{
    
    [self performSegueWithIdentifier:@"CREATE_STREAM_SEGUE" sender:nil];
    
   //[self performSegueWithIdentifier:@"CreateFirstStreamSegue" sender:nil];
}


- (IBAction)createFirstStream:(id)sender
{
    //[AppHelper setShowFirstTimeView:NO];
   //[self.navigationController setNavigationBarHidden:NO animated:YES];
    //self.tabBarController.tabBar.hidden = NO;
    [self performSegueWithIdentifier:@"CREATE_STREAM_SEGUE" sender:nil];
    //[self performSegueWithIdentifier:@"CreateFirstStreamSegue" sender:nil];
}


- (IBAction)dismissFirstTimeView:(id)sender
{
    [UIView animateWithDuration:.8 animations:^{
        self.firstLaunchView.alpha = 0;
        //self.navigationController.navigationBar.alpha = 1;
        //self.tabBarController.tabBar.alpha = 1;
        //[AppHelper setShowFirstTimeView:NO];
        //[self.navigationController setNavigationBarHidden:NO animated:YES];
        //self.tabBarController.tabBar.hidden = NO;
    }];
    
    
    UIImageView *navImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 50, 40)];
    navImageView.contentMode = UIViewContentModeScaleAspectFit;
    navImageView.image = [UIImage imageNamed:@"logo"];
    self.navigationItem.titleView = navImageView;
    self.navigationItem.rightBarButtonItem.image = [UIImage imageNamed:@"PlusIcon"];
    DLog();
}

- (IBAction)enterSubaWithFullName:(UIButton *)sender
{
    [self.firstNameTextField resignFirstResponder];
    [self.lastNameTextField resignFirstResponder];
    
    NSString *firstName = self.firstNameTextField.text;
    NSString *lastName = self.lastNameTextField.text;
    
    NSDictionary *requestData = @{@"userId": [AppHelper userID],
                                 @"firstName" : firstName,
                                 @"lastName" : lastName};
    
    DLog(@"User details to send to the server - %@ :  %@",firstName,lastName);
    [User updateFullName:requestData completion:^(id results, NSError *error) {
        if (error) {
            [[[UIAlertView alloc] initWithTitle:@"Update Info Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"Try again" otherButtonTitles:nil] show];
            DLog(@"Error - %@",error); 
        }else{
            [Flurry logEvent:@"Full_Name_Updated"];
            //[AppHelper setFirstName:results[@"firstName"]];
            //[AppHelper setFirstName:results[@"lastName"]];
            
            [AppHelper savePreferences:results];
            
            //DLog(@"User prefs now - %@",[[AppHelper userPreferences] description]);
            [UIView animateWithDuration:.5 animations:^{
                self.welcomeBackView.alpha = 0;
                [self.navigationController setNavigationBarHidden:NO animated:YES];
                self.tabBarController.tabBar.hidden = NO;
                [self updateData];
            }];
        }
    }];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Helper methods
/*-(void)startShowingLoadingStreamsIndicator:(BOOL)shouldShow
{
    //UIFont *ionIconsFont = [IonIcons fontWithSize:30.0f];
    if (shouldShow == YES) {
        CGFloat indicatorWidth = 40.0f;
        CGFloat indicatorHeight = 40.0f;
        CGFloat XPOS = (self.view.frame.size.width / 2) - 40.0f;
        CGFloat YPOS = (self.view.frame.size.height / 2) - 40.0f;
        UIImageView *loadingView = [[UIImageView alloc] initWithFrame:CGRectMake(XPOS, YPOS, indicatorWidth, indicatorHeight)];
        loadingView.contentMode = UIViewContentModeScaleAspectFit;
        UIImage *icon = [IonIcons imageWithIcon:icon_ios7_reload
                                      iconColor:kSUBA_APP_COLOR
                                       iconSize:40.0f
                                      imageSize:CGSizeMake(indicatorWidth, indicatorHeight)];
        
        loadingView.image = icon;
        loadingView.tag = 10000;
        [self.view addSubview:loadingView];
    }else{
        UIImageView *loadingView = (UIImageView *)[self.view viewWithTag:10000];
        [loadingView removeFromSuperview];
    }
    
}*/

-(void)addSpotToAllSpotsStream:(NSDictionary *)spotDetails
{
    [Flurry logEvent:@"Stream_Added_To_All_Stream"];
    
    // Check which segment is selected
    // If spot was created with a location and nearby is selected, add it
    //DLog(@"Spot that was created details - %@",spotDetails);
    
    if (![spotDetails[@"venue"] isEqualToString:@"NONE"]) {
        // Spot was created with a location so we add it to nearby spots
        if (self.nearbyStreams && self.nearbySpotsCollectionView.alpha == 1) {
            [self.nearbyStreams insertObject:spotDetails atIndex:0];
            [self updateCollectionView:self.nearbySpotsCollectionView
                            withUpdate:@[ [NSIndexPath indexPathForItem:0 inSection:0] ]
                            updateType:kCollectionViewUpdateInsert];
        }else if ([self.nearbyStreams count] == 0){
            self.nearbyStreams = [NSMutableArray arrayWithObject:spotDetails];
            [self updateCollectionView:self.nearbySpotsCollectionView
                            withUpdate:@[ [NSIndexPath indexPathForItem:0 inSection:0] ]
                            updateType:kCollectionViewUpdateInsert];
        }
    }
    
    
    NSString *spotID = spotDetails[@"spotId"];
    NSString *spotName = spotDetails[@"spotName"];
    NSInteger numberOfPhotos = [spotDetails[@"photos"] integerValue];
    NSDictionary *dataPassed = @{@"spotId": spotID,@"spotName":spotName,@"photos" : @(numberOfPhotos)};
    
    [self performSelector:@selector(moveToPhotoStream:) withObject:dataPassed afterDelay:.8];

    
   // [self refreshAllStreams];
    
}


- (void)updateCollectionView:(UICollectionView *)collectionView withUpdate:(NSArray *)updates updateType:(ColectionViewUpdateType)updateType
{
    //DLog(@"user spots - %@",self.allSpots);
    /*if (updateType == kCollectionViewUpdateInsert) {
        [collectionView performBatchUpdates:^{
            [collectionView insertItemsAtIndexPaths:updates];
        } completion:^(BOOL finished) {
            [collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:YES];
        }];
    }else if(updateType == kCollectionViewUpdateDelete){
        [collectionView performBatchUpdates:^{
            [collectionView deleteItemsAtIndexPaths:updates];
        } completion:nil];
    }*/
    
    [collectionView reloadData];
}


-(void)fetchGlobalStreams
{
    [self dataLoadingView:YES];
    //[self startShowingLoadingStreamsIndicator:YES];
    
    User *activeUser = [User currentlyActiveUser];
    [[User currentlyActiveUser] fetchGlobalStreams:@{@"userId": activeUser.userID} completion:^(id results, NSError *error) {
        if (!error) {
            if ([results[STATUS] isEqualToString:ALRIGHT]) {
                NSArray *nearby = results[@"nearby"];
                //[self startShowingLoadingStreamsIndicator:NO];
                [self dataLoadingView:NO];
                if ([nearby count] > 0){
                    NSSortDescriptor *timestampDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeCreated" ascending:NO];
                    
                    NSArray *sortDescriptors = [NSArray arrayWithObject:timestampDescriptor];
                    NSArray *sortedSpots = [nearby sortedArrayUsingDescriptors:sortDescriptors];
                                        self.globalStreams = [NSMutableArray arrayWithArray:sortedSpots];
                    
                    [self.noLocationCollectionView reloadData];
                }
            }
        }
    }];
}


- (void)showNearbyStreamsCollectionView
{
    self.nearbySpotsCollectionView.alpha = 1;
    self.noLocationCollectionView.alpha = 0;
    self.noNearbyStreamsCollectionView.alpha = 0;
    [self.nearbySpotsCollectionView reloadData];
}


- (void)showNoNearbyStreamsCollectionView
{
    self.nearbySpotsCollectionView.alpha = 0;
    self.noLocationCollectionView.alpha = 0;
    self.noNearbyStreamsCollectionView.alpha = 1;
    [self.noNearbyStreamsCollectionView reloadData];
}


-(void)fetchNearbySpots:(NSDictionary *)latLng completion:(SBNewStreamsCompletionHandler)completionHandler
{
    // Show Activity Indicator
    [self dataLoadingView:YES];
    
    [Location fetchNearbySpots:latLng completionBlock:^(id results, NSError *error) {
        //[self startShowingLoadingStreamsIndicator:NO];
        [self dataLoadingView:NO];
        if (error) {
            DLog(@"Error - %@",error);
            [AppHelper showAlert:@"Error" message:error.localizedDescription buttons:@[@"OK"] delegate:nil];
            if (completionHandler) {
               completionHandler(NO);
            }
            
        }else{
            if ([results[STATUS] isEqualToString:ALRIGHT]) {
                
                NSArray *nearby = results[@"nearby"];
                
                DLog(@"Thare are %lu Streams",(unsigned long)[nearby count]);
                
                if ([nearby count] > 0){
                   // self.noDataView.alpha = 0;
                    NSSortDescriptor *timestampDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeCreated" ascending:NO];
                    
                    NSArray *sortDescriptors = [NSArray arrayWithObject:timestampDescriptor];
                    NSArray *sortedSpots = [nearby sortedArrayUsingDescriptors:sortDescriptors];
                    
                    self.nearbyStreams = [NSMutableArray arrayWithArray:sortedSpots];
                    if ([self areNearbyStreamsAvailable]) {
                        self.nearbySpotsCollectionView.alpha = 1;
                        self.noLocationCollectionView.alpha = 0;
                        self.noNearbyStreamsCollectionView.alpha = 0;
                        [self.nearbySpotsCollectionView reloadData];
                        if (completionHandler) {
                            completionHandler(YES);
                        }

                    }else{
                        self.nearbySpotsCollectionView.alpha = 0;
                        self.noLocationCollectionView.alpha = 0;
                        self.noNearbyStreamsCollectionView.alpha = 1;
                        [self.noNearbyStreamsCollectionView reloadData];
                        if (completionHandler) {
                            completionHandler(NO);
                        }

                    }
                    
                }
                
            }
        }
        
    }];
}


- (void)joinSpot:(NSString *)spotCode data:(NSDictionary *)data
{
    [[User currentlyActiveUser] joinSpotCompletionCode:spotCode completion:^(id results, NSError *error){
        if (!error) {
            if ([results[STATUS] isEqualToString:ALRIGHT]){
                [Flurry logEvent:@"Join_Stream_With_Code"];
                [self performSegueWithIdentifier:kPhotosStreamSegue sender:data];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:kUserReloadStreamNotification object:nil];
                
            }else{
                DLog(@"Error - %@",results[STATUS]);
            }
        }else{
            DLog(@"Error - %@",error);
            [AppHelper showAlert:@"Network Error"
                         message:error.localizedDescription
                         buttons:@[@"OK"] delegate:nil];
        }
    }];
}


-(void)joinSpot:(NSString *)spotCode data:(NSDictionary *)data completion:(GeneralCompletion)completionBlock
{
    [[User currentlyActiveUser] joinSpotCompletionCode:spotCode completion:^(id results, NSError *error){
        if (!error) {
            [Flurry logEvent:@"Join_Stream_With_Code"];
            completionBlock(results,nil);
        }else{
            completionBlock(nil,error);
        }
    }];

}


-(void)dataLoadingView:(BOOL)flag
{
    self.placesBeingWatchedLoadingView.hidden = !flag;
    if (flag == YES) {
        [self.loadingInfoIndicator startAnimating];
    }else [self.loadingInfoIndicator stopAnimating];
}


-(void)galleryTappedAtIndex:(NSNotification *)aNotification
{
    DLog();
    NSDictionary *notifInfo = [aNotification valueForKey:@"userInfo"];
    //NSArray *photos = notifInfo[@"spotInfo"][@"photoURLs"];
    
    //[self performSegueWithIdentifier:@"PhotosStreamSegue" sender:photos];
    
        // It is the nearby stream
        self.currentSelectedSpot = notifInfo[@"spotInfo"];
        //DLog(@"Notification Info - %@",notifInfo);
        //NSString *isMember = notifInfo[@"spotInfo"][@"userIsMember"];
        //NSString *spotCode = notifInfo[@"spotInfo"][@"spotCode"];
        //NSString *spotId = notifInfo[@"spotInfo"][@"spotId"];
    
        NSDictionary *streamInfo = notifInfo[@"spotInfo"];
    
        [self performSegueWithIdentifier:@"PhotosStreamSegue" sender:streamInfo];
    
       /* if (isMember) {
            [self performSegueWithIdentifier:@"PhotosStreamSegue" sender:photos];
        }else if([spotCode isEqualToString:@"NONE"]){
            
            // This album is public and user is not a member, so we add user to this stream
            [[User currentlyActiveUser] joinSpot:spotId completion:^(id results, NSError *error) {
                if (!error){
                    DLog(@"Stream is public so joining spot");
                    if ([results[STATUS] isEqualToString:ALRIGHT]){
                        
                        [[NSNotificationCenter defaultCenter] postNotificationName:kUserReloadStreamNotification object:nil];
     
                        [self performSegueWithIdentifier:kPhotosStreamSegue sender:photos];
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
            alertView.tag = 10;
            
            [alertView show];
        }*/
}


-(void)checkForLocation
{
    if ([CLLocationManager locationServicesEnabled]){
        //if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied){
            
            locationManager = [[CLLocationManager alloc] init];
            locationManager.delegate = self;
        if (IS_OS_7_OR_BEFORE) {
                    DLog(@"IOS 7");
            [locationManager startUpdatingLocation];
        }else if(IS_OS_8_OR_LATER){
            [locationManager requestWhenInUseAuthorization];
        }
       /* }else{
            [AppHelper showAlert:@"Location Denied"
                         message:@"You have disabled location services for Suba. Please go to Settings->Privacy->Location and enable location for Suba"
                         buttons:@[@"OK"] delegate:nil];
        }*/
    }else{
        [AppHelper showAlert:@"Location Error" message:[NSString stringWithFormat:@"%@\n%@",@"Suba does not have access to your location.",@"In order to see streams nearby, go to Settings->Privacy->Location Services and enable location for Suba" ] buttons:@[@"OK"] delegate:nil];
        
    }
}


- (void)getCurrentLatitudeAndLongitudeWithCompletion:(SBCurrentLocationCompletionHandler)completion
{
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
        // Suba does not have access to location
        DLog(@"Showing No Location collection view");
        self.nearbySpotsCollectionView.alpha = 0;
        self.noNearbyStreamsCollectionView.alpha = 0;
        self.noLocationCollectionView.alpha = 1;
        NSError *error = [NSError errorWithDomain:@"SBLocationDeniedErrorDomain" code:123 userInfo:@{@"errorDomain": @"SBLocationErrorDomain",@"code" : @(123)}];
        
        completion(nil,error);
        
        
    }else if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized){
            locationManager = [[CLLocationManager alloc] init];
        
        
            self.currentLocation = [locationManager location];
        
        if (!self.currentLocation) {
            
            NSError *error = [NSError errorWithDomain:@"SBLocationNotFoundErrorDomain" code:123 userInfo:@{@"errorDomain": @"SBLocationErrorDomain",@"code" : @(223)}];
            
            completion(nil,error);
        }else{
            DLog(@"We have Location: %@",[self.currentLocation debugDescription]);
            NSString *latitude  =  [NSString stringWithFormat:@"%.8f",self.currentLocation.coordinate.latitude];
            NSString *longitude = [NSString stringWithFormat:@"%.8f",self.currentLocation.coordinate.longitude];
            
            NSDictionary *latlng = @{@"lat":latitude,@"lng":longitude};
            
            completion(latlng,nil);
        }
    }
}



-(void)showSearchBar
{
    if (searchBartoggler % 2 == 0) {
        [UIView animateWithDuration:0.3 animations:^{
            CGRect searchBarFrame = CGRectMake(0, 0, 320, 40);
            self.searchBarField.frame = searchBarFrame;
            self.searchBarField.alpha = 1;
        }];
    }else{
        [UIView animateWithDuration:0.3 animations:^{
            CGRect searchBarFrame = CGRectMake(0, 0, 320, 0);
            self.searchBarField.frame = searchBarFrame;
            self.searchBarField.alpha = 0;
        }];
    }
    searchBartoggler += 1;
}

-(void)makeInitialPlaceholderView:(UIView *)contextView name:(NSString *)person
{
    UIFont *font = [UIFont fontWithName:@"AvenirNext-Regular" size:20.0];
    
    UILabel *initialsLabel = [[UILabel alloc] initWithFrame:contextView.frame];
    initialsLabel.font = font;
    initialsLabel.text = [[self initialStringForPersonString:person] uppercaseString];
    contextView.backgroundColor = [self circleColor];
    
    [contextView addSubview:initialsLabel];
    
}


- (UIColor *)circleColor {
    return [UIColor colorWithHue:arc4random() % 256 / 256.0 saturation:0.7 brightness:0.8 alpha:1.0];
}

- (IBAction)searchForStream:(UIBarButtonItem *)sender
{
    [self showSearchBar];
}


- (NSString *)initialStringForPersonString:(NSString *)personString{
    NSString *initials = nil;
    NSArray *comps = [personString componentsSeparatedByString:k_SEPARATOR_CHARACTER];
    NSMutableArray *mutableComps = [NSMutableArray arrayWithArray:comps];
    
    for (NSString *component in mutableComps) {
        if ([component isEqualToString:kEMPTY_STRING_WITH_SPACE]) {
            [mutableComps removeObject:component];
        }
    }
    
    if ([mutableComps count] >= 2) {
        NSString *firstName = mutableComps[0];
        NSString *lastName = mutableComps[1];
        
        initials =  [NSString stringWithFormat:@"%@%@", [firstName substringToIndex:1], [lastName substringToIndex:1]];
    } else if ([mutableComps count]) {
        NSString *name = mutableComps[0];
        initials =  [name substringToIndex:1];
    }
    
    return initials;
}

-(void)fillView:(UIView *)view WithImage:(NSString *)imageURL
{
    if ([[view subviews] count] == 0) {
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:view.frame];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        [imageView sd_setImageWithURL:[NSURL URLWithString:imageURL]];
        
        view.backgroundColor = [UIColor clearColor];
        [view addSubview:imageView];
    }
    
}


-(void)hidePromptForSeeNearbyStreams
{
    
    
    if (self.seeNearbyStreamsView.alpha == 1){
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized){
            //[UIView animateWithDuration:.3 animations:^{
                self.seeNearbyStreamsView.alpha = 0;
                //[self.seeNearbyStreamsView removeFromSuperview];
                self.nearbySpotsCollectionView.frame = CGRectMake(0, 0, 320,
                                                                  self.nearbySpotsCollectionView.frame.size.height);
        }else{
            DLog(@"Location info is not available for Suba");
        }

    }
}


#pragma mark - UICollection View Datasource
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;
    if (self.nearbySpotsCollectionView.alpha == 1 || self.noNearbyStreamsCollectionView.alpha == 1) {
        numberOfRows = (self.nearbyStreams) ? [self.nearbyStreams count] : numberOfRows;
    }else if (self.noLocationCollectionView.alpha == 1){
        numberOfRows = (self.globalStreams) ? [self.globalStreams count] : numberOfRows;
    }
    
   
    return numberOfRows;
}


-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    
    self.currentIndexPath = indexPath;
    static NSString *cellIdentifier = @"NearbySpotCell";
    PersonalSpotCell *personalSpotCell = nil;
    NSArray *spotsToDisplay = nil;
    NSString *spotCode = nil;
    
    if (self.noLocationCollectionView.alpha == 1){
        personalSpotCell = [self.noLocationCollectionView dequeueReusableCellWithReuseIdentifier:@"NoLocationStreamCell" forIndexPath:indexPath];
        spotsToDisplay = self.globalStreams;
        DLog(@"Spot to display is global streams");
    }else if (self.nearbySpotsCollectionView.alpha == 1){
        personalSpotCell = [self.nearbySpotsCollectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
        spotsToDisplay = self.nearbyStreams;
    }else if (self.noNearbyStreamsCollectionView.alpha == 1){
        personalSpotCell = [self.noNearbyStreamsCollectionView dequeueReusableCellWithReuseIdentifier:@"NoNearbyStreamsCell" forIndexPath:indexPath];
        spotsToDisplay = self.nearbyStreams;
    }
    
    // Set up cell separator
    CGColorRef coloref = [UIColor colorWithRed:156/255.0f green:150/255.0f blue:129/255.0f alpha:1.0f].CGColor;
    [personalSpotCell setUpBorderWithColor:coloref AndThickness:.5f];
    
        if (personalSpotCell.pGallery.hidden) {
            personalSpotCell.pGallery.hidden = NO;
        }
    
    DLog(@"Stream name: %@ ---- Stream code : %@",spotsToDisplay[indexPath.item][@"spotName"],spotsToDisplay[indexPath.item][@"spotCode"]);
        spotCode = spotsToDisplay[indexPath.item][@"spotCode"];
        /*if ([spotCode isEqualToString:@"NONE"] || [spotCode class] == [NSNull class] || spotCode == NULL){
            personalSpotCell.privateStreamImageView.hidden = YES; 
        }else{
            personalSpotCell.privateStreamImageView.hidden = NO;
        }*/
    
    
    [[personalSpotCell.photoGalleryView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    NSString *photos = spotsToDisplay[indexPath.row][@"photos"];
    
    personalSpotCell.streamNameLabel.text = spotsToDisplay[indexPath.item][@"spotName"];
    personalSpotCell.streamNameLabel.adjustsFontSizeToFitWidth = YES;
    
    personalSpotCell.streamVenueLabel.text = spotsToDisplay[indexPath.item][@"venue"];
    personalSpotCell.streamVenueLabel.adjustsFontSizeToFitWidth = YES;
    
    NSInteger members = [spotsToDisplay[indexPath.item][@"members"] integerValue] - 1;
    
    NSString *imageSrc = spotsToDisplay[indexPath.row][@"creatorPhoto"];
    
    if (imageSrc){
        [personalSpotCell fillView:personalSpotCell.userNameView WithImage:imageSrc];
    }else{
        if (spotsToDisplay[indexPath.item][@"creatorFirstName"] && spotsToDisplay[indexPath.item][@"creatorLastName"]){
            NSString *firstName = [(NSString *)spotsToDisplay[indexPath.item][@"creatorFirstName"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            
            
            NSString *lastName = [(NSString *)spotsToDisplay[indexPath.item][@"creatorLastName"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            
            NSString *personString = [NSString stringWithFormat:@"%@<>%@",firstName,lastName];
            
           [personalSpotCell makeInitialPlaceholderView:personalSpotCell.userNameView name:personString];

        }else{
            NSString *userName = spotsToDisplay[indexPath.row][@"creatorName"];
            [personalSpotCell makeInitialPlaceholderView:personalSpotCell.userNameView name:userName];
        }
        
    }

    
    if (members == 0){
        //personalSpotCell.numberOfMembers.hidden = YES;
        personalSpotCell.firstMemberPhoto.hidden = YES;
        personalSpotCell.secondMemberPhoto.hidden = YES;
        personalSpotCell.thirdMemberPhoto.hidden = YES;
        
        if (spotsToDisplay[indexPath.item][@"creatorFirstName"] && spotsToDisplay[indexPath.item][@"creatorLastName"]){
            NSString *firstName = spotsToDisplay[indexPath.item][@"creatorFirstName"];
            NSString *lastName = spotsToDisplay[indexPath.item][@"creatorLastName"];
            NSString *lastNameInitial = [self initialStringForPersonString:lastName].uppercaseString;
            
            personalSpotCell.userNameLabel.text = [NSString stringWithFormat:@"%@ %@.",firstName,lastNameInitial];
        }else{
            NSString *userName = spotsToDisplay[indexPath.row][@"creatorName"];
            personalSpotCell.userNameLabel.text = userName;
        }
        
        
    }else if (members == 1){
       
        
        personalSpotCell.firstMemberPhoto.hidden = NO;
        personalSpotCell.secondMemberPhoto.hidden = YES;
        personalSpotCell.thirdMemberPhoto.hidden = YES;
        
        if (spotsToDisplay[indexPath.item][@"creatorFirstName"] && spotsToDisplay[indexPath.item][@"creatorLastName"]){
            NSString *firstName = spotsToDisplay[indexPath.item][@"creatorFirstName"];
            NSString *lastName = spotsToDisplay[indexPath.item][@"creatorLastName"];
            
            NSString *lastNameInitial = [self initialStringForPersonString:lastName].uppercaseString;
            NSMutableAttributedString *userNametext = [[NSMutableAttributedString alloc]
                                                                                initWithString:[NSString stringWithFormat:@"%@ %@. ",firstName,lastNameInitial]
                                                                            attributes:@{NSForegroundColorAttributeName: [UIColor colorWithRed:217/255.0f green:77/255.0f blue:20/255.0f alpha:1.0]}];
            
            NSString *participants = [NSString stringWithFormat:@"and %li other",(long)members];
            NSMutableAttributedString *others = [[NSMutableAttributedString alloc]
                                                 initWithString:participants attributes:@{NSForegroundColorAttributeName: [UIColor grayColor]}];
            
            // Add both texts
            [userNametext appendAttributedString:others];
            
            personalSpotCell.userNameLabel.attributedText = userNametext;
        }else{
            NSString *userName = spotsToDisplay[indexPath.row][@"creatorName"];
            NSMutableAttributedString *userNametext = [[NSMutableAttributedString alloc]
                                                       initWithString:[NSString stringWithFormat:@"%@ ",userName]
                                                       attributes:@{NSForegroundColorAttributeName: [UIColor colorWithRed:217/255.0f green:77/255.0f blue:20/255.0f alpha:1.0]}];
            
            NSString *participants = [NSString stringWithFormat:@"and %li other",(long)members];
            NSMutableAttributedString *others = [[NSMutableAttributedString alloc]
                                                 initWithString:participants attributes:@{NSForegroundColorAttributeName: [UIColor grayColor]}];
            
            // Add both texts
            [userNametext appendAttributedString:others];
            
            personalSpotCell.userNameLabel.attributedText = userNametext;
        }

        
        if (spotsToDisplay[indexPath.item][@"firstMemberPhoto"]){
            NSString *firstMemberPhotoURL = spotsToDisplay[indexPath.item][@"firstMemberPhoto"];
            [personalSpotCell fillView:personalSpotCell.firstMemberPhoto WithImage:firstMemberPhotoURL];
        }else if(spotsToDisplay[indexPath.item][@"firstMember"]){
            NSString *personString = spotsToDisplay[indexPath.item][@"firstMember"];
           
            [personalSpotCell makeInitialPlaceholderView:personalSpotCell.firstMemberPhoto name:personString];
        }
        
    }else if (members == 2){
        
        personalSpotCell.firstMemberPhoto.hidden = NO;
        personalSpotCell.secondMemberPhoto.hidden = NO;
        personalSpotCell.thirdMemberPhoto.hidden = YES;
        
        if (spotsToDisplay[indexPath.item][@"creatorFirstName"] && spotsToDisplay[indexPath.item][@"creatorLastName"]){
            NSString *firstName = spotsToDisplay[indexPath.item][@"creatorFirstName"];
            NSString *lastName = spotsToDisplay[indexPath.item][@"creatorLastName"];
            NSString *lastNameInitial = [self initialStringForPersonString:lastName].uppercaseString;
            
            NSMutableAttributedString *userNametext = [[NSMutableAttributedString alloc]
                                                       initWithString:[NSString stringWithFormat:@"%@ %@. ",firstName,lastNameInitial]
                                                       attributes:@{NSForegroundColorAttributeName: [UIColor colorWithRed:217/255.0f green:77/255.0f blue:20/255.0f alpha:1.0]}];
            
            NSString *participants = [NSString stringWithFormat:@"and %li others",(long)members];
            NSMutableAttributedString *others = [[NSMutableAttributedString alloc]
                                                 initWithString:participants attributes:@{NSForegroundColorAttributeName: [UIColor grayColor]}];
            
            // Add both texts
            [userNametext appendAttributedString:others];
            
            personalSpotCell.userNameLabel.attributedText = userNametext;
        }else{
            NSString *userName = spotsToDisplay[indexPath.row][@"creatorName"];
            NSMutableAttributedString *userNametext = [[NSMutableAttributedString alloc]
                                                       initWithString:[NSString stringWithFormat:@"%@ ",userName]
                                                       attributes:@{NSForegroundColorAttributeName: [UIColor colorWithRed:217/255.0f green:77/255.0f blue:20/255.0f alpha:1.0]}];
            
            NSString *participants = [NSString stringWithFormat:@"and %li others",(long)members];
            NSMutableAttributedString *others = [[NSMutableAttributedString alloc]
                                                 initWithString:participants attributes:@{NSForegroundColorAttributeName: [UIColor grayColor]}];
            
            // Add both texts
            [userNametext appendAttributedString:others];
            
            personalSpotCell.userNameLabel.attributedText = userNametext;
        }
        
        
        if (spotsToDisplay[indexPath.item][@"firstMemberPhoto"]){
            NSString *firstMemberPhotoURL = spotsToDisplay[indexPath.item][@"firstMemberPhoto"];
            //DLog(@"FirstMemberPhotoURL - %@",firstMemberPhotoURL);
            [personalSpotCell fillView:personalSpotCell.firstMemberPhoto WithImage:firstMemberPhotoURL];
        }else if(spotsToDisplay[indexPath.item][@"firstMember"]){
            // Construct Initials
            NSString *personString = spotsToDisplay[indexPath.item][@"firstMember"];
            [self makeInitialPlaceholderView:personalSpotCell.firstMemberPhoto name:personString];
        }
        if (spotsToDisplay[indexPath.item][@"secondMemberPhoto"]) {
            // If we have a pic to show
            NSString *secondMemberPhotoURL = spotsToDisplay[indexPath.item][@"secondMemberPhoto"];
            //DLog(@"SecondMemberPhotoURL - %@",secondMemberPhotoURL);
            [personalSpotCell fillView:personalSpotCell.secondMemberPhoto WithImage:secondMemberPhotoURL];
        }else if(spotsToDisplay[indexPath.item][@"secondMember"]){
            
            NSString *personString = spotsToDisplay[indexPath.item][@"secondMember"];
            [personalSpotCell makeInitialPlaceholderView:personalSpotCell.secondMemberPhoto name:personString];
        }
        
    }else if(members >= 3){
        
        if (spotsToDisplay[indexPath.item][@"creatorFirstName"] && spotsToDisplay[indexPath.item][@"creatorLastName"]){
            NSString *firstName = spotsToDisplay[indexPath.item][@"creatorFirstName"];
            NSString *lastName = spotsToDisplay[indexPath.item][@"creatorLastName"];
            NSString *lastNameInitial = [self initialStringForPersonString:lastName].uppercaseString;
            
            
            NSMutableAttributedString *userNametext = [[NSMutableAttributedString alloc]
        initWithString:[NSString stringWithFormat:@"%@ %@. ",firstName,lastNameInitial]
                                                       attributes:@{NSForegroundColorAttributeName: [UIColor colorWithRed:217/255.0f green:77/255.0f blue:20/255.0f alpha:1.0]}];
            
            NSString *participants = [NSString stringWithFormat:@"and %li others",(long)members];
            NSMutableAttributedString *others = [[NSMutableAttributedString alloc]
                                                 initWithString:participants attributes:@{NSForegroundColorAttributeName: [UIColor grayColor]}];
            
            // Add both texts
            [userNametext appendAttributedString:others];
            
            personalSpotCell.userNameLabel.attributedText = userNametext;
        }else{
            NSString *userName = spotsToDisplay[indexPath.row][@"creatorName"];
            NSMutableAttributedString *userNametext = [[NSMutableAttributedString alloc]
                                                       initWithString:[NSString stringWithFormat:@"%@ ",userName]
                                                       attributes:@{NSForegroundColorAttributeName: [UIColor colorWithRed:217/255.0f green:77/255.0f blue:20/255.0f alpha:1.0]}];
            
            NSString *participants = [NSString stringWithFormat:@"and %li others",(long)members];
            NSMutableAttributedString *others = [[NSMutableAttributedString alloc]
                                                 initWithString:participants attributes:@{NSForegroundColorAttributeName: [UIColor grayColor]}];
            
            // Add both texts
            [userNametext appendAttributedString:others];
            personalSpotCell.userNameLabel.attributedText = userNametext;
        }

        
        if (spotsToDisplay[indexPath.item][@"firstMemberPhoto"]){
            NSString *firstMemberPhotoURL = spotsToDisplay[indexPath.item][@"firstMemberPhoto"];
            //DLog(@"FirstMemberPhotoURL - %@",firstMemberPhotoURL);
            [personalSpotCell fillView:personalSpotCell.firstMemberPhoto WithImage:firstMemberPhotoURL];
        }else if(spotsToDisplay[indexPath.item][@"firstMember"]){
            NSString *personString = spotsToDisplay[indexPath.item][@"firstMember"];
            
            [personalSpotCell makeInitialPlaceholderView:personalSpotCell.firstMemberPhoto name:personString];
        }
        if (spotsToDisplay[indexPath.item][@"secondMemberPhoto"]) {
            
            NSString *secondMemberPhotoURL = spotsToDisplay[indexPath.item][@"secondMemberPhoto"];
            //DLog(@"secondMemberPhotoURL - %@",secondMemberPhotoURL);
            [personalSpotCell fillView:personalSpotCell.secondMemberPhoto WithImage:secondMemberPhotoURL];
        }else if(spotsToDisplay[indexPath.item][@"secondMember"]){
            
            NSString *personString = spotsToDisplay[indexPath.item][@"secondMember"];
            //DLog(@"second member - %@",personString);
            [personalSpotCell makeInitialPlaceholderView:personalSpotCell.secondMemberPhoto name:personString];
            
        }if (spotsToDisplay[indexPath.item][@"thirdMemberPhoto"]){
            NSString *thirdMemberPhotoURL = spotsToDisplay[indexPath.item][@"thirdMemberPhoto"];
            [personalSpotCell fillView:personalSpotCell.thirdMemberPhoto WithImage:thirdMemberPhotoURL];
            //DLog(@"Third memberPhotoURL - %@",thirdMemberPhotoURL);
        }else if(spotsToDisplay[indexPath.item][@"thirdMember"]){
            
            NSString *personString = spotsToDisplay[indexPath.item][@"thirdMember"];
            //DLog(@"Third member Photo URL - %@",personString);
            [personalSpotCell makeInitialPlaceholderView:personalSpotCell.thirdMemberPhoto name:personString];
            
        }
    }
    
    
    personalSpotCell.numberOfPhotosLabel.text = photos;
    
    if ([photos integerValue] > 0) {  // If there are photos to display
            
            [personalSpotCell prepareForGallery:spotsToDisplay[indexPath.row] index:indexPath];
        
            if ([personalSpotCell.pGallery superview]) {
                [personalSpotCell.pGallery removeFromSuperview];
            }
            personalSpotCell.photoGalleryView.backgroundColor = [UIColor clearColor];
            [personalSpotCell.photoGalleryView addSubview:personalSpotCell.pGallery];

        
    }else{
        
        UIImageView *noPhotosImageView = [[UIImageView alloc] initWithFrame:personalSpotCell.photoGalleryView.bounds];
        noPhotosImageView.image = [UIImage imageNamed:@"newaddFirstPhoto"];
        noPhotosImageView.contentMode = UIViewContentModeScaleAspectFit;
        
        if ([noPhotosImageView superview]){
            [noPhotosImageView removeFromSuperview];
        }
        
        [personalSpotCell.photoGalleryView addSubview:noPhotosImageView];
    }
    
    
    return personalSpotCell;
}


- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView *reusableview = nil;
        if (kind == UICollectionElementKindSectionHeader){
            //if (self.noLocationCollectionView.alpha == 0){
                reusableview = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"NoLocationStreamHeaderView" forIndexPath:indexPath];
            /*if (self.noNearbyStreamsCollectionView.alpha == 1){
                reusableview = [self.noLocationCollectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"NoNearbyHeaderView" forIndexPath:indexPath];
            }*/
        }
    DLog();
    return reusableview;
}




#pragma mark - CollectionView Delegate
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger numberOfPhotos = 0;
    NSArray *spotsToDisplay = nil;
 
    //[Flurry logEvent:@"Stream_Selected_My_Stream"];
        
        [Flurry logEvent:@"Stream_Selected_Nearby"];
        spotsToDisplay = self.nearbyStreams;
        numberOfPhotos = [spotsToDisplay[indexPath.item][@"photos"] integerValue];
    
    
    
        if (numberOfPhotos == 0){
            
            NSString *spotID = spotsToDisplay[indexPath.item][@"spotId"];
            NSString *spotName = spotsToDisplay[indexPath.item][@"spotName"];
            //NSString *spotCode = spotsToDisplay[indexPath.item][@"spotCode"];
            NSInteger numberOfPhotos = [spotsToDisplay[indexPath.item][@"photos"] integerValue];
            NSDictionary *dataPassed = @{@"spotId": spotID,@"spotName":spotName,@"photos" : @(numberOfPhotos)};
            //NSString *isMember = spotsToDisplay[indexPath.item][@"userIsMember"];
            self.currentSelectedSpot = dataPassed;
            
            [self performSegueWithIdentifier:@"PhotosStreamSegue" sender:dataPassed];
            
            /*if (isMember){
                // User is a member so let him view photos;
                [self performSegueWithIdentifier:@"PhotosStreamSegue" sender:dataPassed];
            }else if ([spotCode isEqualToString:@"NONE"]) {
                // This album has no spot code and user is not a member, so we add user to this stream
                [[User currentlyActiveUser] joinSpot:spotID completion:^(id results, NSError *error) {
                    
                    if (!error){
                        //DLog(@"Album is public so joining spot");
                        if ([results[STATUS] isEqualToString:ALRIGHT]){
                            DLog(@"User has been added to a stream");
                            [[NSNotificationCenter defaultCenter] postNotificationName:kUserReloadStreamNotification object:nil];
             
                            [self performSegueWithIdentifier:@"PhotosStreamSegue" sender:dataPassed];
                        }else{
                            DLog(@"Server error - %@",error);
                        }
                    }else{
                        DLog(@"Error - %@",error);
                    }
                }];
            }else{
                //if ([isMember isEqualToString:@"NO"] && ![spotCode isEqualToString:@"N/A"])
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Join Stream" message:@"Enter code for the stream you want to join" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Join", nil];
                alertView.alertViewStyle = UIAlertViewStyleSecureTextInput;
                [alertView show];
            }*/
            
        }else if (numberOfPhotos > 0){
            // User Tapped the name of the stream
            //NSArray *photos = self.nearbyStreams[indexPath.item][@"photoURLs"];
            
            // It is the nearby stream
            self.currentSelectedSpot = self.nearbyStreams[indexPath.item];
            NSDictionary *streamInfo = self.nearbyStreams[indexPath.item];
            
            //NSString *isMember = self.nearbyStreams[indexPath.item][@"userIsMember"];
            //NSString *spotCode = self.nearbyStreams[indexPath.item][@"spotCode"];
            //NSString *spotId = self.nearbyStreams[indexPath.item][@"spotId"];
            
            [self performSegueWithIdentifier:@"PhotosStreamSegue" sender:streamInfo];
            
            /*if (isMember) {
                [self performSegueWithIdentifier:@"PhotosStreamSegue" sender:photos];
            }else if([spotCode isEqualToString:@"NONE"]){
                
                // This album is public and user is not a member, so we add user to this stream
                [[User currentlyActiveUser] joinSpot:spotId completion:^(id results, NSError *error) {
                    if (!error){
                        DLog(@"Stream is public so joining spot");
                        if ([results[STATUS] isEqualToString:ALRIGHT]){
                            
                            [[NSNotificationCenter defaultCenter] postNotificationName:kUserReloadStreamNotification object:nil];
                            
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
                alertView.tag = 10;
                [alertView show];
            }*/

        }
}



#pragma mark - UITextField Delegate
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    if ([[AppHelper kindOfDeviceScreen] isEqualToString:kIPHONE_4_SCREEN]){
        
        [self.welcomeBackView setContentOffset:CGPointMake(0,0.0f)];
    }else{
      [self.welcomeBackView setContentOffset:CGPointMake(0,-20.0f)];
    }
    
    
    return YES;
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if(textField.text.length > 0) {
        self.enterSubaButton.enabled = YES;
    }else self.enterSubaButton.enabled = NO;
    
    return YES;
}

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    if(textField.text.length > 0) {
        self.enterSubaButton.enabled = YES;
    }else self.enterSubaButton.enabled = NO;
}

-(void)textFieldDidEndEditing:(UITextField *)textField
{
    if(textField.text.length > 0) {
        self.enterSubaButton.enabled = YES;
    }else self.enterSubaButton.enabled = NO;
}

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    // This is where we move the enter suba button up
    if ([[AppHelper kindOfDeviceScreen] isEqualToString:kIPHONE_5_SCREEN]){
        
        [self.welcomeBackView setContentOffset:CGPointMake(0,140.0f)];
        
    }else if ([[AppHelper kindOfDeviceScreen] isEqualToString:kIPHONE_4_SCREEN]){
        
        [self.welcomeBackView setContentOffset:CGPointMake(0,220.0f)];
}
    return YES;
}


#pragma mark - Location Manager Delegate
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    
    // Let's check whether we can show the welcome view
    if (([[AppHelper firstName] isEqualToString:@""] || [AppHelper firstName] == NULL)
        && ([[AppHelper lastName] isEqualToString:@""] || [AppHelper lastName] == NULL)){
        
        // Show update account details
      if (self.welcomeBackView.alpha == 0){
        [UIView animateWithDuration:.5 animations:^{
            
            DLog(@"We have to show the welcome view");
            self.welcomeBackView.alpha = 1;
            [self.navigationController setNavigationBarHidden:YES animated:YES];
            self.tabBarController.tabBar.hidden = YES;
        }];
      }
    }else{
        
    if (self.seeNearbyStreamsView.alpha == 1){
       [self hidePromptForSeeNearbyStreams];
    }
    
    if (self.currentLocation == nil){
        self.currentLocation = [locations lastObject];
        
        
        
        if (!self.nearbyStreams || [[AppHelper userSession] isEqualToString:@"l-out"]){
            //DLog(@"userSession - %@",[AppHelper userSession]);
            [AppHelper setUserSession:@"login"];
            NSString *latitude  =  [NSString stringWithFormat:@"%.8f",self.currentLocation.coordinate.latitude];
            NSString *longitude = [NSString stringWithFormat:@"%.8f",self.currentLocation.coordinate.longitude];
            DLog(@"Location manager");
            [self fetchNearbySpots:@{@"lat": latitude, @"lng" :longitude,@"userId" : [AppHelper userID]} completion:nil];
            
        }
      }
    }
}


-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    // Let's check whether we can show the welcome view
    if (([[AppHelper firstName] isEqualToString:@""] || [AppHelper firstName] == NULL)
        && ([[AppHelper lastName] isEqualToString:@""] || [AppHelper lastName] == NULL)){
        if (self.welcomeBackView.alpha == 0){
            [UIView animateWithDuration:.5 animations:^{
                
                DLog(@"We have to show the welcome view");
                self.welcomeBackView.alpha = 1;
                [self.navigationController setNavigationBarHidden:YES animated:YES];
                self.tabBarController.tabBar.hidden = YES;
            }];
        }
        
    }else{
        

    if ([error code] == kCLErrorDenied) {
        //you had denied
        /*[AppHelper showAlert:@"Location Error"
                     message:@"We could not retrieve your location at this time"
                     buttons:@[@"OK"] delegate:nil];*/
        
        if (self.noLocationCollectionView.alpha == 0) {
            
            if (self.noLocationCollectionView.alpha == 0){
                self.nearbySpotsCollectionView.alpha = 0;
                self.noNearbyStreamsCollectionView.alpha = 0;
                self.noLocationCollectionView.alpha = 1;
                
                if (self.nearbyStreams) {
                    self.globalStreams = [self filterNearbyStreamsForGlobalStreams:self.nearbyStreams];
                    [self.noLocationCollectionView reloadData];
                }else{
                    // Fetch Global Streams
                    [self fetchGlobalStreams];
                }
            }

        }
      }
    }
    
}

-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    DLog(@"Location status - %i",status);
    
    // Let's check whether we can show the welcome view
    if (([[AppHelper firstName] isEqualToString:@""] || [AppHelper firstName] == NULL)
        && ([[AppHelper lastName] isEqualToString:@""] || [AppHelper lastName] == NULL)){
        if (self.welcomeBackView.alpha == 0){
            [UIView animateWithDuration:.5 animations:^{
                
                DLog(@"We have to show the welcome view");
                self.welcomeBackView.alpha = 1;
                [self.navigationController setNavigationBarHidden:YES animated:YES];
                self.tabBarController.tabBar.hidden = YES;
            }];
        }
    }
    
    if (status == kCLAuthorizationStatusDenied){
        DLog(@"We've been denied access to location so show header view");
        
        if (self.noLocationCollectionView.alpha == 0){
            self.nearbySpotsCollectionView.alpha = 0;
            self.noNearbyStreamsCollectionView.alpha = 0;
            self.noLocationCollectionView.alpha = 1;
            
            if (self.nearbyStreams) {
                self.globalStreams = [self filterNearbyStreamsForGlobalStreams:self.nearbyStreams];
                [self.noLocationCollectionView reloadData];
            }else{
                // Fetch Global Streams
                [self fetchGlobalStreams];
            }
        }
    }else if (status == kCLAuthorizationStatusAuthorized || status == kCLAuthorizationStatusAuthorizedWhenInUse || status == kCLAuthorizationStatusAuthorizedAlways){
            self.currentLocation = [manager location];
            DLog(@"Authorization status changed");
        
            NSString *latitude  =  [NSString stringWithFormat:@"%.8f",self.currentLocation.coordinate.latitude];
            NSString *longitude = [NSString stringWithFormat:@"%.8f",self.currentLocation.coordinate.longitude];
            
            [self fetchNearbySpots:@{@"lat": latitude, @"lng" :longitude,@"userId" : [AppHelper userID]} completion:nil];
    }
}


#pragma mark - Pull to refresh updates
-(void)updateData
{
   
    __weak typeof(self) weakSelf = self;
    
    int64_t delayInSeconds = 1.2;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        
    if(self.nearbySpotsCollectionView.alpha == 1 || self.noNearbyStreamsCollectionView.alpha == 1){
        self.currentLocation = [locationManager location];
        NSString *latitude = [NSString stringWithFormat:@"%.8f",self.currentLocation.coordinate.latitude];
        NSString *longitude = [NSString stringWithFormat:@"%.8f",self.currentLocation.coordinate.longitude];
        
        [weakSelf fetchNearbySpots:@{@"lat": latitude, @"lng" :longitude, @"userId" : [AppHelper userID]} completion:nil];
        
        [weakSelf.nearbySpotsCollectionView stopRefreshAnimation];
    }else if (self.noLocationCollectionView.alpha == 1){
        [weakSelf fetchGlobalStreams];
    }
        
    });
} 


-(void)moveToPhotoStream:(NSDictionary *)dataPassed
{
  [self performSegueWithIdentifier:@"PhotosStreamSegue" sender:dataPassed];
}


-(void)updateStreamInfo:(NSNotification *)aNotification
{
    NSInteger streamId = [aNotification.object[@"streamId"] integerValue];
    DLog(@"StreamId:  %ld",(long)streamId);
    if (self.nearbyStreams){
        //DLog(@"%i streams be4 removing",[self.nearbyStreams count]);
        for (NSDictionary *streamInfo in self.nearbyStreams) {
            if ([streamInfo[@"spotId"] integerValue] == streamId) {
                
                DLog(@"Stream to remove is %@",streamInfo[@"spotName"]);
                
                // Get the index of the stream to be updated
                NSUInteger indexOfGuiltyStream = [self.nearbyStreams indexOfObject:streamInfo];
                NSMutableDictionary *mutableStreamInfo = [NSMutableDictionary dictionaryWithDictionary:streamInfo];
                
                // Edit the stream
                [mutableStreamInfo addEntriesFromDictionary:@{@"userIsMember" : @"YES"}];
                [self.nearbyStreams removeObject:streamInfo]; 
                
                // Now add it back to the nearby stream
                [self.nearbyStreams insertObject:mutableStreamInfo atIndex:indexOfGuiltyStream];
                
                
                break;
            }
        }
        
        [self.nearbySpotsCollectionView reloadData];
    }else if(self.globalStreams){
        
        NSMutableArray *mutableGlobalStreams = [NSMutableArray arrayWithArray:self.globalStreams];
        for (NSDictionary *streamInfo in self.globalStreams) {
            if ([streamInfo[@"spotId"] integerValue] == streamId) {
                DLog(@"Stream to remove is %@",streamInfo[@"spotName"]);
                [mutableGlobalStreams removeObject:streamInfo];
                
                self.globalStreams = mutableGlobalStreams;
                
                break;
            }
        }
        
        [self.nearbySpotsCollectionView reloadData];
    }
    
}

- (void)refreshAllStreams
{
    if ([locationManager location]){
        self.currentLocation = [locationManager location];
        NSString *latitude = [NSString stringWithFormat:@"%.8f",self.currentLocation.coordinate.latitude];
        NSString *longitude = [NSString stringWithFormat:@"%.8f",self.currentLocation.coordinate.longitude];
        
        [self fetchNearbySpots:@{@"lat": latitude, @"lng" :longitude, @"userId" : [AppHelper userID]} completion:nil];
    }
    
}

- (IBAction)grantLocationPermission:(UIButton *)sender
{
    [self checkForLocation];
}

#pragma mark - Segue Method
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kPhotosStreamSegue]) {
        if ([segue.destinationViewController isKindOfClass:[PhotoStreamViewController class]]){
            PhotoStreamViewController *photosVC = segue.destinationViewController;
            
            if ([sender isKindOfClass:[NSArray class]]){
                photosVC.photos = [NSMutableArray arrayWithArray:
                                        [NSOrderedSet orderedSetWithArray:(NSArray *) sender].array];
                
                photosVC.spotName = sender[0][@"spot"];
                photosVC.spotID = sender[0][@"spotId"];
                photosVC.numberOfPhotos = 1;
                
            }else if([sender isKindOfClass:[NSDictionary class]]){
                //NSDictionary *streamInfo = sender;
                DLog(@"Stream Info: %@",sender);
                if (sender[@"photoURLs"]){
                    DLog(@"Is user a member: %@",sender[@"userIsMember"]);
                    // The stream info contains info as to whether user is a member or not
                    NSArray *photos = sender[@"photoURLs"];
                    photosVC.photos = [NSMutableArray arrayWithArray:
                                       [NSOrderedSet orderedSetWithArray:(NSArray *) photos].array];
                    photosVC.spotName = sender[@"spotName"];
                    photosVC.spotID = sender[@"spotId"];
                    photosVC.numberOfPhotos = [photos count];
                    if ([sender[@"userIsMember"] isEqualToString:@"YES"]) {
                      photosVC.isUserMemberOfStream = @"YES";
                    }else{
                       photosVC.isUserMemberOfStream = @"NO";
                    }
                    photosVC.spotInfo = sender;
                    
                }else{
                
                //DLog(@"Segue Identifier - %@\nSender - %@",segue.identifier,sender);
                
                photosVC.numberOfPhotos = [sender[@"photos"] integerValue];
                photosVC.spotName = sender[@"spotName"];
                photosVC.spotID = sender[@"spotId"];
              }
          }
        }
        
    }else if([segue.identifier isEqualToString:@"MAINSTREAM_USERPROFILE_SEGUE"]){
        
        UserProfileViewController *uVC = segue.destinationViewController;
        uVC.userId = sender;
        
    }
    //else if([segue.identifier isEqualToString:@"CreateFirstStreamSegue"]){
        //CreateSpotViewController *streamType = segue.destinationViewController;
        //streamType.navTitle = @"Create Stream";
    //}
}



#pragma mark - AlertView Delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    //DLog(@"button index - %ld",(long)buttonIndex);
    if (alertView.tag == 10) {
        if (buttonIndex == 1) {
            NSString *passcode = [alertView textFieldAtIndex:0].text;
            [self joinSpot:passcode data:self.currentSelectedSpot];
        }
    }else if(alertView.tag == 100){
        [AppHelper userHasInvited:@"YES"];
        
        if (buttonIndex == 1) {
            //UserProfileViewController *userPVC = [self.storyboard instantiateViewControllerWithIdentifier:@"USERPROFILE_SCENE"];
            DLog(@"Class - %@",[[[self.tabBarController viewControllers][1] childViewControllers][0] class]);
            UserProfileViewController *userVC = (UserProfileViewController *)[[self.tabBarController viewControllers][1] childViewControllers][0];
            
            userVC.shouldAutoInvite = YES;
            
            [self.tabBarController setSelectedIndex:1];
            //[self.tabBarController.delegate tabBarController:self.tabBarController
              //                    shouldSelectViewController:[self.tabBarController viewControllers][1]];
            
            //self.tabBarController.selectedViewController = [self.tabBarController viewControllers][1];
            
        }
    }
    
    
}



#pragma mark - State Preservation and Restoration
-(void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super encodeRestorableStateWithCoder:coder];
    
    //[coder encodeObject:self.allStreams forKey:AllSpotsKey];
    [coder encodeObject:self.nearbyStreams forKey:NearbySpotsKey];
    //[coder encodeObject:self.placesBeingWatched forKey:PlacesWatchingKey];
    //[coder encodeObject:self.currentSelectedSpot forKey:SelectedSpotKey];
    //[coder encodeObject:@(selectedButton) forKey:SelectedButtonKey];
}


-(void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super decodeRestorableStateWithCoder:coder];
    self.nearbyStreams = [coder decodeObjectForKey:NearbySpotsKey];
}

-(void)applicationFinishedRestoringState
{
    
        self.currentLocation = [locationManager location];
        if (self.currentLocation != nil){
            DLog("Self.current location is not nil");
            NSString *latitude = [NSString stringWithFormat:@"%.8f",self.currentLocation.coordinate.latitude];
            NSString *longitude = [NSString stringWithFormat:@"%.8f",self.currentLocation.coordinate.longitude];
            
            [self fetchNearbySpots:@{@"lat": latitude, @"lng" :longitude,@"userId" : [AppHelper userID]} completion:nil];
            
        }else if([self.nearbyStreams count] > 0){
           
             self.nearbySpotsCollectionView.alpha = 1;
            [self.nearbySpotsCollectionView reloadData];
        }else if ([self.globalStreams count] > 0){
            [self showNoNearbyStreamsCollectionView];
        }
}


-(NSArray *)filterNearbyStreamsForGlobalStreams:(NSArray *)nearbyStreams
{
    NSMutableArray *globals = [NSMutableArray array];
    for (NSDictionary *stream in nearbyStreams) {
        if ([stream[kSUBA_STREAM_VENUE] isEqualToString:kSUBA_GLOBAL_STREAM]) {
            [globals addObject:stream];
        }
    }
    
    return globals;
}

-(BOOL)areNearbyStreamsAvailable
{
    NSArray *globals = [self filterNearbyStreamsForGlobalStreams:self.nearbyStreams];
    if ([globals count] < [self.nearbyStreams count]) {
        // There are some nearby streams
        return YES;
    }else if ([self.nearbyStreams count] == [globals count]){
        self.globalStreams = self.nearbyStreams;
        return NO;
    }
    return NO;
}



/*#pragma mark - Background mode
-(void)fetchNearbyStreamsInBackgroundWithCompletion:(SBRefreshCompletionHandler)completionHandler
{
    
    [self getCurrentLatitudeAndLongitudeWithCompletion:^(NSDictionary *latlng, NSError *error) {
        if (!error) {
            DLog(@"Fetch nearby streams");
            [self fetchNearbySpots:@{@"lat": latlng[@"lat"], @"lng" :latlng[@"lng"],@"userId" : [AppHelper userID]} completion:completionHandler];
        }else{
            DLog(@"Error: %@",error);
        }
    }];
}*/




-(void)dealloc
{
    self.nearbyStreams = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:kUserReloadStreamNotification];
    [[NSNotificationCenter defaultCenter] removeObserver:kUpdateStreamNotification];
}

@end
