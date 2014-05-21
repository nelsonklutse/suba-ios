//
//  UserProfileViewController.m
//  LifeSpot
//
//  Created by Kwame Nelson on 1/15/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import "UserProfileViewController.h"
#import "User.h"
#import "ProfileSpotCell.h"
#import "ProfileSpotsHeaderView.h"
#import "PhotosCell.h"
#import "PhotoStreamViewController.h"
#import "UserSettingsViewController.h"
#import "AlbumSettingsViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <IDMPhotoBrowser/IDMPhotoBrowser.h>

#define UserSpotsKey @"UserSpotsKey"
#define UserProfileInfoKey @"UserProfileInfoKey"
#define UserIdKey @"UserIdKey"

@interface UserProfileViewController ()<UICollectionViewDataSource,UICollectionViewDelegate>
@property (weak, nonatomic) IBOutlet UICollectionView *userSpotsCollectionView;

@property (strong,nonatomic) NSMutableArray *userSpots;
@property (strong,nonatomic) NSDictionary *userProfileInfo;
//@property (strong,nonatomic) NSString *spotID;
@property (weak, nonatomic) IBOutlet UIView *loadingUserStreamsIndicatorView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingUserStreamsIndicator;
@property (strong,nonatomic) NSString *userProfileId;

- (IBAction)showFullScreenImage:(UIButton *)sender;
- (void)loadSpotsCreated:(NSString *)userId;
- (void)fetchUserInfo:(NSString *)userId;
- (void)galleryTappedAtIndex:(NSNotification *)aNotification;
- (void)updateUserProfile;
- (void)refreshStream;
- (void)updateCollectionView:(UICollectionView *)collectionView withUpdate:(NSArray *)updates;
-(IBAction)unwindToUserProfile:(UIStoryboardSegue *)segue;
- (IBAction)showSettingsView:(id)sender;
@end

@implementation UserProfileViewController

-(IBAction)unwindToUserProfile:(UIStoryboardSegue *)segue
{
    AlbumSettingsViewController *aVC = segue.sourceViewController;
    NSString *albumName = aVC.spotName;
    NSString *spotId = aVC.spotID;
    
    int counter = 0;
    for (NSDictionary *spotToRemove in self.userSpots){
        
        if ([spotToRemove[@"spotId"] integerValue] == [spotId integerValue]){
            
            [self.userSpots removeObject:spotToRemove];
            
            [self updateCollectionView:self.userSpotsCollectionView
                            withUpdate:@[[NSIndexPath indexPathForItem:counter inSection:1]]];
            
            break;
            
        }
        counter += 1;
    }
    
    UIColor *tintColor = [UIColor colorWithRed:(217.0f/255.0f)
                                         green:(77.0f/255.0f)
                                          blue:(20.0f/255.0f)
                                         alpha:1];
    
    [CSNotificationView showInViewController:self.navigationController
                                   tintColor: tintColor
                                       image:nil
                                     message:[NSString stringWithFormat:
                                              @"%@ removed from your list of streams",albumName]
                                    duration:2.0f];
    
}

- (IBAction)showSettingsView:(id)sender
{
    [self performSegueWithIdentifier:@"UserProfileToMainSettingsSegue" sender:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
   // [self followScrollView:self.userSpotsCollectionView];
    
    //self.shouldAutoInvite = NO;
    //self.userProfileId = ( self.userId ) ? self.userId : [User currentlyActiveUser].userID;
    NSString *userId = ( self.userId ) ? self.userId : [User currentlyActiveUser].userID;
    //DLog(@"UserProfileId - %@\nUserInSession Id - %@",self.userProfileId,[AppHelper userID]);
    if (![self.userId isEqualToString:[AppHelper userID]]){
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
        ProfileSpotCell *userInfoCell = [self.userSpotsCollectionView dequeueReusableCellWithReuseIdentifier:@"USER_INFO_CELL" forIndexPath:indexPath];
        userInfoCell.userProfileImage.image = [UIImage imageNamed:@"anonymousUser"];
    }
    
     [self loadSpotsCreated:userId];
     [self fetchUserInfo:userId];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshStream) name:kUserReloadStreamNotification object:nil];

}


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(galleryTappedAtIndex:) name:kPhotoCellTappedAtIndexNotification object:nil];
    
    [self.userSpotsCollectionView addPullToRefreshActionHandler:^{
        [self updateUserProfile];
    }];
    
    [self.userSpotsCollectionView.pullToRefreshView setImageIcon:[UIImage imageNamed:@"icon-72"]];
    [self.userSpotsCollectionView.pullToRefreshView setBorderWidth:6];

    [self.userSpotsCollectionView.pullToRefreshView setBorderColor:[UIColor redColor]];
    
}


-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    DLog(@"Should invite - %i",self.shouldAutoInvite);
    
    if (self.shouldAutoInvite == YES){
        [self performSegueWithIdentifier:@"UserProfileToMainSettingsSegue" sender:@(1)];
    }
    self.shouldAutoInvite = NO;
}


-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter]
     removeObserver:self
     name:kPhotoCellTappedAtIndexNotification
     object:nil];
}


-(void)refreshStream
{
    if (self != nil) {
      [self loadSpotsCreated:[AppHelper userID]];
   }
}

- (void)updateCollectionView:(UICollectionView *)collectionView withUpdate:(NSArray *)updates{
    //DLog(@"user spots - %@",self.allSpots);
    
        [collectionView performBatchUpdates:^{
            [collectionView deleteItemsAtIndexPaths:updates];
        } completion:nil];
}





-(void)galleryTappedAtIndex:(NSNotification *)aNotification
{
    //DLog(@"Galerry tapped");
    
    NSDictionary *notifInfo = [aNotification valueForKey:@"userInfo"];
    NSMutableDictionary *photoInfo = notifInfo[@"photoInfo"];
    //DLog(@"Photos - %@",photos);
    
    [self performSegueWithIdentifier:@"FromUserSpotsToPhotosStreamSegue" sender:photoInfo];
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)showFullScreenImage:(UIButton *)sender {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    ProfileSpotCell *userInfoCell = [self.userSpotsCollectionView dequeueReusableCellWithReuseIdentifier:@"USER_INFO_CELL" forIndexPath:indexPath];
    IDMPhoto *photo = [IDMPhoto photoWithImage:userInfoCell.userProfileImage.image];
    IDMPhotoBrowser *photoBrowser = [[IDMPhotoBrowser alloc] initWithPhotos:@[photo] animatedFromView:sender];
    
    photoBrowser.displayToolbar = NO;
    
    [self presentViewController:photoBrowser
                       animated:YES completion:nil];
}

-(void)loadSpotsCreated:(NSString *)userId
{
    [AppHelper showLoadingDataView:self.loadingUserStreamsIndicatorView indicator:self.loadingUserStreamsIndicator flag:YES];
    [[User currentlyActiveUser]
        fetchCreatedSpotsCompletion:userId
                         completion:^(id results, NSError *error) {
                             [AppHelper showLoadingDataView:self.loadingUserStreamsIndicatorView indicator:self.loadingUserStreamsIndicator flag:NO];
                            if (error) {
                                    DLog(@"Error - %@",error);
                            }else{
                            // If the user has created spots
                            if ([results[@"spots"] count] > 0){
                                //DLog(@"User spots");
                                NSArray *createdSpots = results[@"spots"];
                                NSSortDescriptor *timestampDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeCreated" ascending:NO];
                                NSArray *sortDescriptors = [NSArray arrayWithObject:timestampDescriptor];
                                NSArray *sortedSpots = [createdSpots sortedArrayUsingDescriptors:sortDescriptors];
                                self.userSpots = [NSMutableArray arrayWithArray:sortedSpots];
                                
                                [self.userSpotsCollectionView reloadData];
                            }/*else{
                        [UIView animateWithDuration:0.4 animations:^{
                          //self.spotsView.alpha = 0;
                          //self.nospotsView.alpha = 1;
                        }];
                     }*/
                 }
            }];
  
}


-(void)fetchUserInfo:(NSString *)userId
{
    [User fetchUserProfileInfoCompletion:userId completion:^(id results, NSError *error){
        if (error) {
            //Log the error
            DLog(@"Error -  %@",error);
        }else{
            DLog(@"User info - %@",results);
            if ([results[STATUS] isEqualToString:ALRIGHT]) {
                self.userProfileInfo = (NSDictionary *)results;
                [self.userSpotsCollectionView reloadData];
            }else{
                // There was a problem on the server
            }
        }
    }];
}


-(void)updateUserProfile
{
    __weak typeof(self) weakSelf = self;
    
    int64_t delayInSeconds = 1.2;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        
        [weakSelf loadSpotsCreated:( self.userId ) ? self.userId : [User currentlyActiveUser].userID];
        [weakSelf fetchUserInfo:( self.userId ) ? self.userId : [User currentlyActiveUser].userID];
        [weakSelf.userSpotsCollectionView stopRefreshAnimation];
    });
}


#pragma mark - UICollectionViewDatasource
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 2;
}


-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSInteger numberOfItems = 0;
    if (section == 0) {
        numberOfItems = 1;
    }else{
        numberOfItems = (self.userSpots) ? [self.userSpots count] : numberOfItems;
    }
    
    return numberOfItems;
}


- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 0, 0, 0);
}


-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = nil;
    if (indexPath.section == 0) {
        //DLog(@"Its section - %i",indexPath.section);
        // It is the profile view
        cellIdentifier = @"USER_INFO_CELL";
        
        ProfileSpotCell *userInfoCell = [self.userSpotsCollectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
        
         NSURL *profilePhotoURL = nil;
        
        userInfoCell.userProfileImage.image = [UIImage imageNamed:@"anonymousUser"];
        
        if (self.userProfileInfo) {
            NSString *numberOfSpots = [self.userProfileInfo[@"numberOfSpots"] stringValue];
            profilePhotoURL = [NSURL URLWithString:self.userProfileInfo[@"profilePicURL"]];
            
            NSString *userName = self.userProfileInfo[@"userName"];
            
            self.navigationItem.title = [NSString stringWithFormat:@"@%@",userName];
            userInfoCell.numberOfSpotsLabel.text = numberOfSpots;
            userInfoCell.spotsLabel.text = ([numberOfSpots integerValue] == 1) ? @"Stream" : @"Streams";
            userInfoCell.numberOfPhotosLabel.text = [self.userProfileInfo[@"photos"] stringValue];
            userInfoCell.photosLabel.text = ([self.userProfileInfo[@"photos"] integerValue] == 1) ? @"Photo" : @"Photos";
            
            if (profilePhotoURL) {
                [userInfoCell.userProfileImage setImageWithURL:profilePhotoURL placeholderImage:[UIImage imageNamed:@"anonymousUser"] options:SDWebImageContinueInBackground];
            }
            
            //userInfoCell.userProfileImage.layer.borderColor = [UIColor whiteColor].CGColor;
            
        }
        
        return userInfoCell;
        
        
        
    }else if (indexPath.section == 1){
        //DLog(@"Its section - %i",indexPath.section);
        
        cellIdentifier = @"USER_CREATED_SPOTS_CELL";
        PhotosCell *photosCell = [self.userSpotsCollectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
        
        [[photosCell.photoGalleryView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
        
        NSString *photos = self.userSpots[indexPath.row][@"photos"];
        photosCell.spotName.text = self.userSpots[indexPath.row][@"spotName"];
        photosCell.spotVenue.text = self.userSpots[indexPath.row][@"venue"];
        if ([photos integerValue] > 0) {  // If there are photos to display
            
            NSDictionary *dataToGallery = @{@"images": self.userSpots[indexPath.row][@"photoURLs"],
                                            @"spotId" :self.userSpots[indexPath.row][@"spotId"],
                                            @"spotName" : self.userSpots[indexPath.row][@"spotName"],
                                            @"photos" : @([photos integerValue])};
            
            [photosCell prepareForGallery:dataToGallery index:indexPath];
            
            if ([photosCell.photoGallery superview]) {
                [photosCell.photoGallery removeFromSuperview];
            }
            photosCell.photoGalleryView.backgroundColor = [UIColor clearColor];
            [photosCell.photoGalleryView addSubview:photosCell.photoGallery];
            
            
            //DLog(@"Gallery subviews at index - %i is %@",indexPath.item,[[photosCell.photoGalleryView subviews] debugDescription]);
            
        }else{
            
            UIImageView *noPhotosImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, photosCell.photoGalleryView.frame.size.width, photosCell.photoGalleryView.frame.size.height)];
            
            noPhotosImageView.image = [UIImage imageNamed:@"noPhoto"];
            noPhotosImageView.contentMode = UIViewContentModeScaleAspectFit;
            
            if ([noPhotosImageView superview]) {
                //DLog(@"View has no subviews coz there are no photos");
                [noPhotosImageView removeFromSuperview];
            }
            
            [photosCell.photoGalleryView addSubview:noPhotosImageView];
        }

        
        return photosCell;
    }
    
    return nil;
}



/*-(UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    ProfileSpotsHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"PROFILE_SPOTS_HEADER_VIEW" forIndexPath:indexPath];
    
    if (indexPath.section == 1) {
        if (kind == UICollectionElementKindSectionHeader) {
            
            NSString *title = self.userSpots[indexPath.item][@"spotName"];
            NSString *spotVenue = self.userSpots[indexPath.item][@"venue"];
            if (![spotVenue isEqualToString:@"NONE"]) {
                headerView.locationIcon.hidden = NO;
                headerView.spotLocation.hidden = NO;
                headerView.spotLocation.text = spotVenue;
            }else{
                headerView.locationIcon.hidden = YES;
                headerView.spotLocation.hidden = YES;
            }
            headerView.spotName.text = title;
            headerView.spotLocation.text = spotVenue;
            DLog(@"Spot title - %@\nSpot venue - %@",title,spotVenue);
        }
    }
    
    return headerView;
    
}*/




#pragma mark - CollectionView Delegate
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    //NSLog(@"UserSpot details - %@",[self.userSpots[indexPath.section] description]);
    
    if (indexPath.section == 1) {
        if ([self.userSpots[indexPath.item][@"photos"] integerValue] == 0){
            
            NSString *spotID = self.userSpots[indexPath.item][@"spotId"];
            NSString *spotName = self.userSpots[indexPath.item][@"spotName"];
            NSInteger numberOfPhotos = [self.userSpots[indexPath.item][@"photos"] integerValue];
            NSDictionary *dataPassed = @{@"spotId": spotID,@"spotName":spotName,@"photos" : @(numberOfPhotos)};
            [self performSegueWithIdentifier:@"FromUserSpotsToPhotosStreamSegue" sender:dataPassed];
        }

    }
    
    
}


#pragma mark - Segue Methods
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"FromUserSpotsToPhotosStreamSegue"]){
        if ([segue.destinationViewController isKindOfClass:[PhotoStreamViewController class]]){
            
            PhotoStreamViewController *photosVC = segue.destinationViewController;
            if (sender[@"photoURLs"]) {
                
                photosVC.photos = [NSMutableArray arrayWithArray:(NSArray *) sender[@"photoURLs"]];
            }
            
            photosVC.spotName = sender[@"spotName"];
            photosVC.spotID = sender[@"spotId"];
            photosVC.numberOfPhotos = [sender[@"photos"] integerValue];
            //DLog(@"Number of photos - %i",photosVC.numberOfPhotos);
        }
    }else if ([segue.identifier isEqualToString:@"UserProfileToMainSettingsSegue"]){
        
        if ([sender  isEqual: @(1)]) {
            //DLog(@"Sender class - %@",[sender class]);
            UserSettingsViewController *userSettingsVC = segue.destinationViewController;
            userSettingsVC.autoInvite = YES;
            //DLog();
        }
        
        
    }
}


#pragma mark - State Preservation and Restoration
-(void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeObject:self.userSpots forKey:UserSpotsKey];
    [coder encodeObject:self.userProfileInfo forKey:UserProfileInfoKey];
    [coder encodeObject:self.userId forKey:UserIdKey];
    
    //DLog();
}


-(void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super decodeRestorableStateWithCoder:coder];
    
    self.userSpots = [coder decodeObjectForKey:UserSpotsKey];
    self.userProfileInfo = [coder decodeObjectForKey:UserProfileInfoKey];
    self.userId = [coder decodeObjectForKey:UserIdKey];
    
    //DLog();
}

-(void)applicationFinishedRestoringState
{
    
    if (self.userSpots && self.userProfileInfo) {
        [self.userSpotsCollectionView reloadData];
    }else{
        if (self.userId) {
            [self loadSpotsCreated:self.userId];
        }
    }
    
    //DLog(@"UserId decoded - %@",self.userId);
}



@end
