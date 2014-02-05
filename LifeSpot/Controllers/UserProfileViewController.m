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
#import <SDWebImage/UIImageView+WebCache.h>

#define UserSpotsKey @"UserSpotsKey"
#define UserProfileInfoKey @"UserProfileInfoKey"
#define UserIdKey @"UserIdKey"

@interface UserProfileViewController ()<UICollectionViewDataSource,UICollectionViewDelegate>
@property (weak, nonatomic) IBOutlet UICollectionView *userSpotsCollectionView;

@property (strong,nonatomic) NSArray *userSpots;
@property (strong,nonatomic) NSDictionary *userProfileInfo;
//@property (strong,nonatomic) NSString *spotID;

- (void)loadSpotsCreated:(NSString *)userId;
- (void)fetchUserInfo:(NSString *)userId;
- (void)galleryTappedAtIndex:(NSNotification *)aNotification;
- (void)updateUserProfile;
@end

@implementation UserProfileViewController



- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    NSString *userId = ( self.userId ) ? self.userId : [User currentlyActiveUser].userID;
    [self loadSpotsCreated:userId];
     [self fetchUserInfo:userId];
    
    
     //DLog(@"Bounds of root view - %@\nFrame of collection view - %@",NSStringFromCGRect(self.view.bounds),NSStringFromCGRect(self.userSpotsCollectionView.frame));
    
    //self.userSpotsCollectionView.frame = [[UIScreen mainScreen] bounds];
    
}

 /*-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
   CGRect frame = self.view.bounds;
    frame.size.height -= (self.tabBarController.tabBar.frame.size.height + 64);
    
    self.userSpotsCollectionView.frame = frame;
    
    //self.userSpotsCollectionView.frame = self.view.bounds;
    DLog(@"Bounds of root view - %@\nFrame of collection view - %@",NSStringFromCGRect(self.view.bounds),NSStringFromCGRect(self.userSpotsCollectionView.frame));
}*/




-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(galleryTappedAtIndex:) name:kPhotoCellTappedAtIndexNotification object:nil];
    
    [self.userSpotsCollectionView addPullToRefreshActionHandler:^{
        [self updateUserProfile];
    }];
    
    [self.userSpotsCollectionView.pullToRefreshView setImageIcon:[UIImage imageNamed:@"icon-72"]];
    [self.userSpotsCollectionView.pullToRefreshView setBorderWidth:6];

    [self.userSpotsCollectionView.pullToRefreshView setBackgroundColor:[UIColor redColor]];
    
    DLog(@"Bounds of root view - %@\nFrame of collection view - %@",NSStringFromCGRect(self.view.bounds),NSStringFromCGRect(self.userSpotsCollectionView.frame));
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter]
     removeObserver:self
     name:kPhotoCellTappedAtIndexNotification
     object:nil];
}


-(void)galleryTappedAtIndex:(NSNotification *)aNotification
{
    
    NSDictionary *notifInfo = [aNotification valueForKey:@"userInfo"];
    NSArray *photos = notifInfo[@"photoURLs"];
    DLog(@"Notification Info - %@",notifInfo);
    [self performSegueWithIdentifier:@"FromUserSpotsToPhotosStreamSegue" sender:photos];
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)loadSpotsCreated:(NSString *)userId
{
    [[User currentlyActiveUser]
        fetchCreatedSpotsCompletion:userId
                         completion:^(id results, NSError *error) {
                            if (error) {
                                    DLog(@"Error - %@",error);
                            }else{
                            // If the user has created spots
                            if ([results[@"spots"] count] > 0){
                                DLog(@"User spots"); 
                                NSArray *createdSpots = results[@"spots"];
                                NSSortDescriptor *timestampDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeCreated" ascending:NO];
                                NSArray *sortDescriptors = [NSArray arrayWithObject:timestampDescriptor];
                                NSArray *sortedSpots = [createdSpots sortedArrayUsingDescriptors:sortDescriptors];
                                self.userSpots = sortedSpots;
                                                             
                                //NSLog(@"Spots created by user - %@",self.userSpots);
                                //self.nospotsView.alpha = 0;
                                
                                [self.userSpotsCollectionView reloadData];
                            }else{
                        [UIView animateWithDuration:0.4 animations:^{
                          //self.spotsView.alpha = 0;
                          //self.nospotsView.alpha = 1;
                        }];
                     }
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
            self.userProfileInfo = (NSDictionary *)results;
            [self.userSpotsCollectionView reloadData];
            
            //DLog(@"UserInfo - %@",self.userProfileInfo);
        }
    }];

}


-(void)updateUserProfile
{
    __weak typeof(self) weakSelf = self;
    
    int64_t delayInSeconds = 1.2;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        
        [weakSelf loadSpotsCreated:[AppHelper userID]];
        [weakSelf.userSpotsCollectionView stopRefreshAnimation];
    });
}


#pragma mark - UICollectionViewDatasource
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
   // NSLog(@"Number of sections is %lu",(unsigned long)[self.userSpots count]);
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
         NSURL *profilePhotoURL = [NSURL URLWithString:[AppHelper profilePhotoURL]];
        
        [userInfoCell.userProfileImage setImageWithURL:profilePhotoURL placeholderImage:[UIImage imageNamed:@"anonymousUser"] options:SDWebImageContinueInBackground];
        
        if (self.userProfileInfo) {
            NSString *numberOfSpots = [self.userProfileInfo[@"numberOfSpots"] stringValue];
            profilePhotoURL = [NSURL URLWithString:self.userProfileInfo[@"profilePicURL"]];
            
            NSString *userName = self.userProfileInfo[@"userName"];
            
            self.navigationItem.title = [NSString stringWithFormat:@"@%@",userName];
            userInfoCell.numberOfSpotsLabel.text = numberOfSpots;
            userInfoCell.spotsLabel.text = ([numberOfSpots integerValue] == 1) ? @"Spot" : @"Spots";
            
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
    
}


- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    if(section == 0)
    {
        return CGSizeZero;
    }
    
    return CGSizeMake(320, 40);
}*/


#pragma mark - CollectionView Delegate
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    //NSLog(@"UserSpot details - %@",[self.userSpots[indexPath.section] description]);
    
    if (indexPath.section == 1) {
        if ([self.userSpots[indexPath.item][@"photos"] integerValue] == 0 ) {
            //DLog(@"No photos so lets segue");
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
        if ([segue.destinationViewController isKindOfClass:[PhotoStreamViewController class]]) {
            PhotoStreamViewController *photosVC = segue.destinationViewController;
            //photosVC.photos = [NSMutableArray arrayWithArray:(NSArray *) sender[@"images"]];
            photosVC.spotName = sender[@"spotName"];
            photosVC.spotID = sender[@"spotId"];
            photosVC.numberOfPhotos = [sender[@"photos"] integerValue];
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
}


-(void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super decodeRestorableStateWithCoder:coder];
    
    self.userSpots = [coder decodeObjectForKey:UserSpotsKey];
    self.userProfileInfo = [coder decodeObjectForKey:UserProfileInfoKey];
    
}

-(void)applicationFinishedRestoringState
{
    if (self.userSpots && self.userProfileInfo) {
        [self.userSpotsCollectionView reloadData];
    }else{
        [self performSelector:@selector(loadSpotsCreated:) withObject:self.userId];
    }
}



@end
