//
//  PlacesWatchingViewController.m
//  LifeSpot
//
//  Created by Kwame Nelson on 1/30/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import "PlacesWatchingViewController.h"
#import "User.h"
#import "PlacesWatchingStreamCell.h"
#import "PhotoStreamViewController.h"

@interface PlacesWatchingViewController ()<UICollectionViewDataSource,UICollectionViewDelegate,UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UICollectionView *placesWatchingSpotsCollectionView;
@property (strong,nonatomic) NSDictionary *currentSelectedSpot;

- (void)fetchUserWatchingSpotsAtLocation;
- (void)joinSpot:(NSString *)spotCode data:(NSDictionary *)data;
@end

@implementation PlacesWatchingViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.navigationItem.title = [NSString stringWithFormat:@"Albums @ %@",self.locationName];
    
    if (!self.locationName) {
        //[self fetchUserWatchingSpotsAtLocation];
    }
}


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    
}


- (void)joinSpot:(NSString *)spotCode data:(NSDictionary *)data
{
    [[User currentlyActiveUser] joinSpotCompletionCode:spotCode completion:^(id results, NSError *error){
        if (!error) {
            if ([results[STATUS] isEqualToString:ALRIGHT]) {
                
                [self performSegueWithIdentifier:@"FromWatchingStreamsToPhotoStream" sender:data];
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


-(void)fetchUserWatchingSpotsAtLocation
{
    DLog();
   
    User *userInSession = [User currentlyActiveUser];
    [userInSession fetchFavoriteLocationsCompletions:^(id results, NSError *error) {
        
       
        
        if (error) {
            DLog(@"Error - %@",error);
        }else{
            DLog(@"Results - %@",results);
            NSArray *locationsInfo = [results objectForKey:@"watching"][@"spots"];
            
            if ([locationsInfo count] > 0) { // User is watching locations
                NSSortDescriptor *prettyNameDescriptor = [[NSSortDescriptor alloc] initWithKey:@"prettyName" ascending:YES];
                NSArray *sortDescriptors = [NSArray arrayWithObject:prettyNameDescriptor];
                NSArray *sortedPlaces = [locationsInfo sortedArrayUsingDescriptors:sortDescriptors];
                
                
                // if ([locationsInfo count] > 0) {
                self.spotsWatching = [NSMutableArray arrayWithArray:sortedPlaces];
                
                [self.placesWatchingSpotsCollectionView reloadData];
                //}
            }
        }
        
        
    }];
 
}


-(void)galleryTappedAtIndex:(NSNotification *)aNotification
{
    
    NSDictionary *notifInfo = [aNotification valueForKey:@"userInfo"];
    NSArray *photos = notifInfo[@"spotInfo"][@"photoURLs"];
    
        //self.currentSelectedSpot = notifInfo[@"spotInfo"];
        DLog(@"Notification Info - %@",notifInfo);
        NSString *isMember = notifInfo[@"spotInfo"][@"userIsMember"];
        NSString *spotCode = notifInfo[@"spotInfo"][@"spotCode"];
        NSString *spotId = notifInfo[@"spotInfo"][@"spotId"];
        // NSString *spotName = notifInfo[@"spotInfo"][@"spot"];
        
        DLog(@"Is user Member - %@",isMember);
        if (isMember) {
            [self performSegueWithIdentifier:@"FromWatchingStreamsToPhotoStream" sender:photos];
        }else if ([spotCode isEqualToString:@"NONE"]) {
            
            // This album has no spot code and user is not a member, so we add user to this stream
            [[User currentlyActiveUser] joinSpot:spotId completion:^(id results, NSError *error) {
                if (!error){
                    DLog(@"Album is public so joining spot");
                    if ([results[STATUS] isEqualToString:ALRIGHT]){
                        
                        [AppHelper showNotificationWithMessage:@"You are now a member of this spot" type:kSUBANOTIFICATION_SUCCESS inViewController:self completionBlock:nil];
                        
                        [self performSegueWithIdentifier:@"FromWatchingStreamsToPhotoStream" sender:photos];
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
    //}

}



#pragma mark - UICollection View Datasource
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    DLog(@"Watching - %@",self.spotsWatching);
    return [self.spotsWatching count]; 
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    //self.currentIndexPath = indexPath;
    static NSString *cellIdentifier = @"PlacesWatchingStreamCell";
    PlacesWatchingStreamCell *placesSpotsCell = [self.placesWatchingSpotsCollectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    
    [[placesSpotsCell.photoGalleryView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    NSString *photos = self.spotsWatching[indexPath.row][@"numberOfPhotos"];
    //DLog(@"%@ photos - %@",spotsToDisplay[indexPath.row][@"creatorName"],photos);
    placesSpotsCell.userNameLabel.text = (self.spotsWatching[indexPath.row][@"creatorName"] != NULL) ?
                                          self.spotsWatching[indexPath.row][@"creatorName"] : @"";
    
    NSString *imageSrc = self.spotsWatching[indexPath.row][@"creatorPhoto"];
    [placesSpotsCell.userNameView setImageWithURL:[NSURL URLWithString:imageSrc] placeholderImage:[UIImage imageNamed:@"anonymousUser"]];
    placesSpotsCell.spotNameLabel.text = self.spotsWatching[indexPath.row][@"spotName"];
    placesSpotsCell.numberOfPhotosLabel.text = photos;
    placesSpotsCell.photosLabel.text = ([photos integerValue] == 1) ? @"photo": @"photos";
    
    
    if ([photos integerValue] > 0) {  // If there are photos to display
        
        [placesSpotsCell prepareForGallery:self.spotsWatching[indexPath.row] index:indexPath];
        if ([placesSpotsCell.pGallery superview]) {
            [placesSpotsCell.pGallery removeFromSuperview];
        }
        placesSpotsCell.photoGalleryView.backgroundColor = [UIColor lightGrayColor];
        [placesSpotsCell.photoGalleryView addSubview:placesSpotsCell.pGallery];
        
    }else{
        
        UIImageView *noPhotosImageView = [[UIImageView alloc] initWithFrame:placesSpotsCell.photoGalleryView.frame];
        noPhotosImageView.image = [UIImage imageNamed:@"noPhoto"];
        noPhotosImageView.contentMode = UIViewContentModeScaleAspectFit;
        
        if ([noPhotosImageView superview]) {
            //DLog(@"View has no subviews coz there are no photos");
            [noPhotosImageView removeFromSuperview];
        }
        [placesSpotsCell.photoGalleryView addSubview:noPhotosImageView];
    }
    
    
    return placesSpotsCell;
}


#pragma mark - CollectionView Delegate
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    
      NSInteger numberOfPhotos = [self.spotsWatching[indexPath.item][@"numberOfPhotos"] integerValue];
    
        if (numberOfPhotos == 0){
            NSString *spotID = self.spotsWatching[indexPath.item][@"spotId"];
            NSString *spotName = self.spotsWatching[indexPath.item][@"spotName"];
            NSString *spotCode = self.spotsWatching[indexPath.item][@"spotCode"];
            NSInteger numberOfPhotos = [self.spotsWatching[indexPath.item][@"numberOfPhotos"] integerValue];
            NSDictionary *dataPassed = @{@"spotId": spotID,@"spotName":spotName,@"numberOfPhotos" : @(numberOfPhotos)};
            NSString *isMember = self.spotsWatching[indexPath.item][@"userIsMember"];
            
            self.currentSelectedSpot = dataPassed;
            
            if (isMember){
                DLog(@"isUser member - %@",isMember);
                // User is a member so let him view photos;
                [self performSegueWithIdentifier:@"FromWatchingStreamsToPhotoStream" sender:dataPassed];
                DLog(@" code - %@",spotCode);
            }else if ([spotCode isEqualToString:@"NONE"] || spotCode == NULL) {
                DLog(@" code - %@",spotCode);
                // This album has no spot code and user is not a member, so we add user to this stream
                [[User currentlyActiveUser] joinSpot:spotID completion:^(id results, NSError *error) {
                    if (!error){
                        DLog(@"Album is public so joining spot");
                        if ([results[STATUS] isEqualToString:ALRIGHT]){
                            
                            [AppHelper showNotificationWithMessage:[NSString stringWithFormat:@"You are now a member of the spot %@",spotName] type:kSUBANOTIFICATION_SUCCESS inViewController:self completionBlock:nil];
                            
                            [self performSegueWithIdentifier:@"FromWatchingStreamsToPhotoStream" sender:dataPassed];
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







-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"FromWatchingStreamsToPhotoStream"]) {
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
        
    }
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}









@end
