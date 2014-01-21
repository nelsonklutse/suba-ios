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

@interface UserProfileViewController ()<UICollectionViewDataSource,UICollectionViewDelegate>
@property (weak, nonatomic) IBOutlet UICollectionView *userSpotsCollectionView;

@property (strong,nonatomic) NSArray *userSpots;
@property (strong,nonatomic) NSDictionary *userProfileInfo;

- (void)loadSpotsCreated:(NSString *)userId;
- (void)fetchUserInfo:(NSString *)userId;
@end

@implementation UserProfileViewController



- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
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
                                                             
                                NSArray *createdSpots = results[@"spots"];
                                NSSortDescriptor *timestampDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeCreated" ascending:NO];
                                NSArray *sortDescriptors = [NSArray arrayWithObject:timestampDescriptor];
                                NSArray *sortedSpots = [createdSpots sortedArrayUsingDescriptors:sortDescriptors];
                                self.userSpots = sortedSpots;
                                                             
                                NSLog(@"Spots created by user - %@",self.userSpots);
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
        }
    }];

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
        //numberOfItems = photos;
    }
    
    return numberOfItems;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = nil;
    if (indexPath.section == 0) {
        // It is the profile view
        cellIdentifier = @"USER_INFO_CELL";
        ProfileSpotCell *userInfoCell = [self.userSpotsCollectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
        
        if (self.userProfileInfo) {
            NSString *numberOfSpots = [self.userProfileInfo[@"numberOfSpots"] stringValue];
            NSURL *profilePhotoURL = [NSURL URLWithString:self.userProfileInfo[@"profilePicURL"]];
            NSString *userName = self.userProfileInfo[@"userName"];
            
            self.navigationItem.title = [NSString stringWithFormat:@"@%@",userName];
            userInfoCell.numberOfSpotsLabel.text = numberOfSpots;
            userInfoCell.spotsLabel.text = ([numberOfSpots integerValue] == 1) ? @"Spot" : @"Spots";
            if (profilePhotoURL) {
                [userInfoCell.userProfileImage setImageWithURL:profilePhotoURL];
            }
            
        }
        
        return userInfoCell;
        
        
        
    }else if (indexPath.section == 1){
        cellIdentifier = @"USER_CREATED_SPOTS_CELL";
        PhotosCell *photosCell = [self.userSpotsCollectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
        
        
        return photosCell;
    }
    
    return nil;
}


-(UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    ProfileSpotsHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"PROFILE_SPOTS_HEADER_VIEW" forIndexPath:indexPath];
    
    NSString *title = self.userSpots[indexPath.section][@"spotName"];
    NSString *spotVenue = self.userSpots[indexPath.section][@"venue"];
    if (![spotVenue isEqualToString:@"NONE"]) {
        headerView.locIcon.hidden = NO;
        headerView.spotVenue.hidden = NO;
        headerView.spotVenue.text = spotVenue;
    }else{
        headerView.locIcon.hidden = YES;
        headerView.spotVenue.hidden = YES;
    }
    headerView.spotTitle.text = title;
    return headerView;
    
}


#pragma mark - CollectionView Delegate
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    //NSLog(@"UserSpot details - %@",[self.userSpots[indexPath.section] description]);
    [self performSegueWithIdentifier:@"PROFILE_TO_SPOTVIEW_SEGUE" sender:self.userSpots[indexPath.section]];
    
}

@end
