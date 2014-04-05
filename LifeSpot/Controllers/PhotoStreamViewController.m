//
//  PhotoStreamViewController.m
//  LifeSpot
//
//  Created by Kwame Nelson on 1/14/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import "PhotoStreamViewController.h"
#import "PhotoStreamCell.h"
#import "S3PhotoFetcher.h"
#import "AlbumSettingsViewController.h"
#import "AlbumMembersViewController.h"
#import <CTAssetsPickerController.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "ALAssetsLibrary+CustomPhotoAlbum.h"
#import "LSPushProviderAPIClient.h"
#import "UserProfileViewController.h"
#import "Photo.h"
#import "User.h"
#import "Spot.h"
#import "BDKNotifyHUD.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <IDMPhotoBrowser.h>
#import "BOSImageResizeOperation.h"

typedef void (^PhotoResizedCompletion) (UIImage *compressedPhoto,NSError *error);
typedef void (^StandardPhotoCompletion) (CGImageRef standardPhoto,NSError *error);

#define SpotInfoKey @"SpotInfoKey"
#define SpotNameKey @"SpotNameKey"
#define SpotIdKey @"SpotIdKey"
#define SpotPhotosKey @"SpotPhotosKey"



@interface PhotoStreamViewController ()<UICollectionViewDataSource,UICollectionViewDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate,UIActionSheetDelegate,CTAssetsPickerControllerDelegate,IDMPhotoBrowserDelegate,UIGestureRecognizerDelegate>
{
    UIImage *photoToSave;
    NSIndexPath *selectedPhoto;
    
}

@property (strong,nonatomic) NSDictionary *photoInView;
@property (strong,nonatomic) NSDictionary *spotInfo;
@property (strong,atomic) ALAssetsLibrary *library;
@property (strong,nonatomic) UIImage *albumSharePhoto;

@property (weak, nonatomic) IBOutlet UIImageView *coachMarkImageView;
@property (weak, nonatomic) IBOutlet UIProgressView *imageUploadProgressView;
@property (weak, nonatomic) IBOutlet UICollectionView *photoCollectionView;
@property (weak, nonatomic) IBOutlet UIButton *gotItButton;

@property (weak, nonatomic) IBOutlet UIView *loadingInfoIndicatorView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingStreamInfoIndicator;
@property (weak, nonatomic) IBOutlet UIButton *cameraButton;
@property (weak, nonatomic) IBOutlet UIImageView *likeImage;

@property (retain,nonatomic) IDMPhotoBrowser *browser;

@property (nonatomic, readwrite) CGRect likeButtonBounds;
@property (nonatomic, strong) UIDynamicAnimator *likeButtonAnimator;

@property (weak, nonatomic) IBOutlet UIView *noPhotosView;


- (IBAction)unWindToPhotoStream:(UIStoryboardSegue *)segue;
- (IBAction)unWindToPhotoStreamWithWithInfo:(UIStoryboardSegue *)segue;

- (IBAction)sharePhoto:(UIButton *)sender;
- (IBAction)likePicture:(id)sender;
- (IBAction)cameraButtonTapped:(id)sender;
- (IBAction)settingsButtonTapped:(id)sender;
- (IBAction)shareAlbumAction:(id)sender;
- (IBAction)showMoreActions:(UIButton *)sender;

- (void)savePhoto:(UIImage *)imageToSave;
- (void)photoCardTapped:(UITapGestureRecognizer *)sender;
- (void)share:(Mutant)objectOfInterest Sender:(UIButton *)sender;
- (void)savePhotoToCustomAlbum:(UIImage *)photo;
- (void)resizeImage:(UIImage*) image
            towidth:(float) width
           toHeight:(float) height
          completon:(PhotoResizedCompletion)completion;
- (void)showPhotoOptions;
- (void)showReportOptions;
- (void)reportPhoto:(NSDictionary *)reportInfo;
- (IBAction)showMembers:(id)sender;
- (void)loadSpotInfo:(NSString *)spotId User:(NSString *)userId;
- (void)loadSpotImages:(NSString *)spotId;
- (void)pickImage:(id)sender;
-(void)likePhotoWithID:(NSString *)photoId atIndexPath:(NSIndexPath *)indexPath;
-(void)unlikePhotoWithID:(NSString *)photoId atIndexPath:(NSIndexPath *)indexPath;
- (void)resamplePhotoInfo:(NSDictionary *)info
                     flag:(NSString *)flag
                    numberOfLikes:(NSString *)likes
                  atIndex:(NSInteger)selectedIndex;
- (IBAction)moveToProfile:(UIButton *)sender;
-(NSString *)getRandomPINString:(NSInteger)length;
- (void)preparePhotoBrowser:(NSMutableArray *)photos;
-(void)createStandardImage:(CGImageRef)image completon:(StandardPhotoCompletion)completion;
- (void)resizePhoto:(UIImage*) image
            towidth:(float) width
           toHeight:(float) height
          completon:(PhotoResizedCompletion)completion;
- (IBAction)dismissCoachMark:(UIButton *)sender;
- (void)deletePhotoAtIndexFromStream:(NSInteger)index;
- (void)uploadPhotos:(NSArray *)images;
- (void)upDateCollectionViewWithCapturedPhotos:(NSArray *)photoInfo;
@end

@implementation PhotoStreamViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Load browser
    /*if (self.photos){
        
        [self preparePhotoBrowser:self.photos];
    }*/
    
    
    if ([[AppHelper shareStreamCoachMarkSeen] isEqualToString:@"NO"]){
        if ([[UIScreen mainScreen] respondsToSelector: @selector(scale)]) {
            CGSize result = [[UIScreen mainScreen] bounds].size;
            CGFloat scale = [UIScreen mainScreen].scale;
            result = CGSizeMake(result.width * scale, result.height * scale);
            
            if(result.height == 960){
            self.coachMarkImageView.image = [UIImage imageNamed:@"share-stream_iphone4"];
            CGRect btnFrame = CGRectMake(self.gotItButton.frame.origin.x, self.gotItButton.frame.origin.y-100, self.gotItButton.frame.size.width, self.gotItButton.frame.size.height);
                
                self.gotItButton.frame = btnFrame;
            }
            if(result.height == 1136){
                //  DLog(@"Using 5");
                //CODE IF iPHONE 5
                //self.coachMarkImage.image = [UIImage imageNamed:@"search-for-interesting-locations"];
                self.coachMarkImageView.image = [UIImage imageNamed:@"share-stream_new"];
                
               // self.gotItButton.frame = btnFrame;
            }
        }

        self.coachMarkImageView.alpha = 1;
        [self.view viewWithTag:10000].alpha = 1;
        [AppHelper setShareStreamCoachMark:@"YES"];
    }
    
    // Disable the camera button till we have all our info ready
    self.cameraButton.enabled = NO;
    
	// Do any additional setup after loading the view.
    self.noPhotosView.hidden = YES;
    
    self.navigationItem.title = (self.spotName) ? self.spotName : @"Stream";
    
    self.library = [[ALAssetsLibrary alloc] init];
    
    if(!self.photos && !self.spotName && self.numberOfPhotos == 0 && self.spotID){
        // We are coming from an activity screen
        DLog(@"Loading spotImages for when photos is not set AND spotName is not set and number of photos is 0 AND we have a spotID");
       [self loadSpotImages:self.spotID];
    }
    if(!self.photos && self.numberOfPhotos > 0 && self.spotID) {
        // We are coming from a place where spotName is not set so lets load spot info
       DLog(@"Loading spot images. We are from user profile");
        [self loadSpotImages:self.spotID];
    }
    
     if(self.numberOfPhotos == 0 && self.spotName && self.spotID){
        self.noPhotosView.hidden = NO;
        self.photoCollectionView.hidden = YES;
    }

    
     if(self.spotID) {
        DLog(@"Loading images in stream with SpotId - %@",self.spotID);
        
       [self loadSpotInfo:self.spotID User:[AppHelper userID]];
       //[self loadSpotImages:self.spotID];
    }
    
    
    
}


-(void)preparePhotoBrowser:(NSMutableArray *)photos
{
    
    NSMutableArray *photoURLs = [NSMutableArray array];
    for (NSDictionary *photoInfo in photos) {
        NSURL *photoURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",kS3_BASE_URL,photoInfo[@"s3name"]]];
        [photoURLs addObject:photoURL];
    }
    
    NSArray *idmPhotos = [IDMPhoto photosWithURLs:photoURLs];
    
    self.browser = [[IDMPhotoBrowser alloc] initWithPhotos:idmPhotos];
}



-(void)loadSpotImages:(NSString *)spotId
{
   [Spot fetchSpotImagesUsingSpotId:spotId completion:^(id results, NSError *error) {
       if (!error){
           NSArray *allPhotos = [results objectForKey:@"spotPhotos"];
           NSSortDescriptor *timestampDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
           NSArray *sortDescriptors = [NSArray arrayWithObject:timestampDescriptor];
           self.photos = [NSMutableArray arrayWithArray:[allPhotos sortedArrayUsingDescriptors:sortDescriptors]];
           DLog(@"Photos - %@",results);
           if ([self.photos count] > 0) {
               //DLog(@"Photos in spot - %@",self.photos);
               self.noPhotosView.hidden = YES;
               self.photoCollectionView.hidden = NO;
               [self.photoCollectionView reloadData];
               //[self preparePhotoBrowser:self.photos];
           }else{
                   self.noPhotosView.hidden = NO;
                   self.photoCollectionView.hidden = YES;
             }
           
       }else{
           DLog(@"Error - %@",error);
       }
   }];
}


-(void)loadSpotInfo:(NSString *)spotId User:(NSString *)userId
{
 // Show activity indicator
    [AppHelper showLoadingDataView:self.loadingInfoIndicatorView
                         indicator:self.loadingStreamInfoIndicator flag:YES];
    
    [Spot fetchSpotInfo:spotId User:userId completion:^(id results, NSError *error) {
        [AppHelper showLoadingDataView:self.loadingInfoIndicatorView
                             indicator:self.loadingStreamInfoIndicator flag:NO];
        if (error) {
            DLog(@"Error - %@",error);
            [AppHelper showAlert:@"Network Error" message:error.localizedDescription buttons:@[@"Ok"] delegate:nil];
        }else{
            if ([results[STATUS] isEqualToString:ALRIGHT]){
                self.spotInfo = (NSDictionary *)results;
                DLog(@"Spot Info - %@",self.spotInfo);
                self.spotName = (self.spotName) ? self.spotName : results[@"spotName"];
                self.navigationItem.title = self.spotName;
                [self.photoCollectionView reloadData];
                
                self.cameraButton.enabled = YES;
            }
            
        }
    }];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)dismissCoachMark:(UIButton *)sender
{
    [UIView animateWithDuration:1.0 animations:^{
        self.coachMarkImageView.alpha = 0;
        [self.view viewWithTag:10000].alpha = 0;
        [[self.view viewWithTag:10000] removeFromSuperview];
    }];
  
}


-(NSString *)getRandomPINString:(NSInteger)length
{
    NSMutableString *returnString = [NSMutableString stringWithCapacity:length];
    
    NSString *numbers = @"0123456789";
    
    // First number cannot be 0
    [returnString appendFormat:@"%C", [numbers characterAtIndex:(arc4random() % ([numbers length]-1))+1]];
    
    for (int i = 1; i < length; i++)
    {
        [returnString appendFormat:@"%C", [numbers characterAtIndex:arc4random() % [numbers length]]];
    }
    
    return returnString;
}


-(void)reportPhoto:(NSDictionary *)reportInfo
{
    [User reportPhoto:reportInfo completion:^(id results, NSError *error) {
        DLog(@"Results - %@",results);
        
        BDKNotifyHUD *hud = [BDKNotifyHUD notifyHUDWithImage:[UIImage imageNamed:@"Checkmark"]
                                                       text:@"Photo Reported!"];
        
        hud.center = CGPointMake(self.view.center.x, self.view.center.y - 100);
        
        // Animate it, then get rid of it. These settings last 1 second, takes a half-second fade.
        [self.view addSubview:hud];
        [hud presentWithDuration:2.0f speed:0.5f inView:self.view completion:^{
            [hud removeFromSuperview];
            [CSNotificationView showInViewController:self
                                           tintColor: [UIColor colorWithRed:0.850 green:0.301 blue:0.078 alpha:1]
                                               image:nil
                                             message:@"Thank you for your report. We will remove this photo if it violates our Community Guidelines."
                                            duration:5.0f];
        }];
        
        
    }];
}

-(void)deletePhotoAtIndexFromStream:(NSInteger)index
{
    [Flurry logEvent:@"Photo_Deleted"];

    NSInteger photoIndex = index;
    //DLog(@"PhotoInView - %@",self.photos[index]);
    [self.photos removeObjectAtIndex:photoIndex];
    
    [S3PhotoFetcher deletePhotoFromStream:self.photoInView completion:^(id results, NSError *error) {
        DLog(@"Response - %@",results);
        if (!error) {
            [self.photoCollectionView performBatchUpdates:^{
                [self.photoCollectionView
                 deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:photoIndex inSection:0]]];
            } completion:^(BOOL finished) {
                if ([self.photos count] == 0) {
                    self.noPhotosView.hidden = NO;
                    self.photoCollectionView.hidden = YES;
                }
            }];
            
            
            // Ask main stream to reload
            [[NSNotificationCenter defaultCenter]
             postNotificationName:kUserReloadStreamNotification object:nil];
            
        }
    }];
    
}

/*-(void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    PhotoStreamCell *photoStreamCell = (PhotoStreamCell *)cell;
    
    DLog(@"cell picture taker - %@\nCell frame - %@\nCell bounds - %@",
         photoStreamCell.pictureTakerName.text,NSStringFromCGRect(photoStreamCell.frame),NSStringFromCGRect(photoStreamCell.bounds));
}*/

#pragma mark - UICollectionView Datasource
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.photos count];
}




-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    // Set the Double Tap Gesture Recognizer
    UITapGestureRecognizer *doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(photoCardTapped:)];
    
    [doubleTapRecognizer setNumberOfTapsRequired:2];
    [doubleTapRecognizer setDelegate:self];
    
    static NSString *cellIdentifier = @"PhotoStreamCell";
    
    PhotoStreamCell *photoCardCell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10000), dispatch_get_main_queue(),^{
        NSString *photoLiked = self.photos[indexPath.item][@"userLikedPhoto"];
        if ([photoLiked isEqualToString:@"YES"]) {
            [photoCardCell.likePhotoButton setSelected:YES];
        }else{
           [photoCardCell.likePhotoButton setSelected:NO];
        }
        
    });
    
      [AppHelper showLoadingDataView:photoCardCell.loadingPictureView
                         indicator:photoCardCell.loadingPictureIndicator
                              flag:YES];
    
    photoCardCell.pictureTakerView.image = [UIImage imageNamed:@"anonymousUser"];
    
    NSString *photoURLstring = self.photos[indexPath.row][@"s3name"];
    //DLog(@"Photos - %@",self.photos[indexPath.item]);
    if(self.photos[indexPath.row][@"pictureTakerPhoto"]){
        NSString *pictureTakerPhotoURL = self.photos[indexPath.row][@"pictureTakerPhoto"];
        
        [photoCardCell.pictureTakerView setImageWithURL: [NSURL URLWithString:pictureTakerPhotoURL] placeholderImage:[UIImage imageNamed:@"anonymousUser"] options:SDWebImageContinueInBackground];
    }
    
    photoCardCell.pictureTakerName.text = self.photos[indexPath.row][@"pictureTaker"];
    photoCardCell.numberOfLikesLabel.text = self.photos[indexPath.row][@"likes"];
    
    // Add the gesture recognizer to this cell
    [photoCardCell.photoCardImage setUserInteractionEnabled:YES];
    [photoCardCell.photoCardImage setMultipleTouchEnabled:YES];
    [photoCardCell.photoCardImage addGestureRecognizer:doubleTapRecognizer];
    
    
    // Download photo card image
    [[S3PhotoFetcher s3FetcherWithBaseURL] downloadPhoto:photoURLstring to:photoCardCell.photoCardImage placeholderImage:[UIImage imageNamed:@"blurBg"] completion:^(id results, NSError *error) {
        
        if (!error) {
            self.albumSharePhoto = (UIImage *)results;
            
        }
        
        [AppHelper showLoadingDataView:photoCardCell.loadingPictureView
                             indicator:photoCardCell.loadingPictureIndicator
                                  flag:NO];
    }];
    
    return photoCardCell;
}



#pragma mark - UICollectionView Delegate
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    //DLog(@"selected image index - %i",indexPath.item);
    selectedPhoto = indexPath;
}


#pragma mark - Methods
-(void)showMembers:(id)sender
{
    [self performSegueWithIdentifier:@"AlbumMembersSegue" sender:self.spotID];
}


- (IBAction)sharePhoto:(UIButton *)sender{
    PhotoStreamCell *cell = (PhotoStreamCell *)sender.superview.superview.superview;
    if (cell.photoCardImage.image != nil) {
        [self share:kPhoto Sender:sender];
    }else{
        [AppHelper showAlert:@"Share Image Request"
                     message:@"You can share image after it loads"
                     buttons:@[@"OK, I'll wait"]
                    delegate:nil];
    }
}


-(void)likePhotoWithID:(NSString *)photoId atIndexPath:(NSIndexPath *)indexPath
{
    [Flurry logEvent:@"Photo_Liked"];
    PhotoStreamCell *photoCardCell = (PhotoStreamCell *)[self.photoCollectionView cellForItemAtIndexPath:selectedPhoto];
    
    NSDictionary *selectedPhotoInfo = self.photos[indexPath.item];
    
    NSDictionary *params = @{@"userId": [AppHelper userID],@"pictureId" : photoId,@"updateFlag" :@"1"};
    
    [[User currentlyActiveUser] likePhoto:params completion:^(id results, NSError *error) {
        if ([results[STATUS] isEqualToString:ALRIGHT]){
            [self resamplePhotoInfo:selectedPhotoInfo flag:@"YES" numberOfLikes:results[@"likes"] atIndex:indexPath.item];
            
            // Ask main stream to reload
            [[NSNotificationCenter defaultCenter]
             postNotificationName:kUserReloadStreamNotification object:nil];
            
            photoCardCell.numberOfLikesLabel.text = results[@"likes"];
            
            //[self updatePhotosNumberOfLikes:self.photos photoId:photoId update:results[@"likes"]];
            
            [AppHelper showLikeImage:self.likeImage imageNamed:@"like-button"];
            
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10000), dispatch_get_main_queue(),^{
                //DLog(@"Button state - %i",photoCardCell.likePhotoButton.state);
                //[photoCardCell.likePhotoButton setSelected:YES];
                [UIView animateWithDuration:0.8 animations:^{
                    photoCardCell.likePhotoButton.alpha = 0;
                    [photoCardCell.likePhotoButton setSelected:YES];
                    photoCardCell.likePhotoButton.alpha = 1;
                }];
            });
        }
        
    }];

}


-(void)unlikePhotoWithID:(NSString *)photoId atIndexPath:(NSIndexPath *)indexPath
{
    [Flurry logEvent:@"Photo_UnLiked"];

    PhotoStreamCell *photoCardCell = (PhotoStreamCell *)[self.photoCollectionView cellForItemAtIndexPath:selectedPhoto];
    
    NSDictionary *selectedPhotoInfo = self.photos[indexPath.item];
    
    NSDictionary *params = @{@"userId": [AppHelper userID],@"pictureId" : photoId,@"updateFlag" :@"0"};
    
    [[User currentlyActiveUser] likePhoto:params completion:^(id results, NSError *error){
        
        if ([results[STATUS] isEqualToString:ALRIGHT]){
            //DLog(@"Number of likes - %@",results[@"likes"]);
            [self resamplePhotoInfo:selectedPhotoInfo
                               flag:@"NO"
                      numberOfLikes:results[@"likes"]
                            atIndex:indexPath.item];
            
            //Ask main stream to reload
            [[NSNotificationCenter defaultCenter]
             postNotificationName:kUserReloadStreamNotification object:nil];
            
            photoCardCell.numberOfLikesLabel.text = results[@"likes"];
            //[self updatePhotosNumberOfLikes:self.photos photoId:picId update:results[@"likes"]];
            
            [AppHelper showLikeImage:self.likeImage imageNamed:@"unlike-button"];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1000), dispatch_get_main_queue(),^{
                //[photoCardCell.likePhotoButton setSelected:NO];
                //DLog(@"Photo card cell - %@",[photoCardCell debugDescription]);
                //DLog(@"Set selected");
                [UIView animateWithDuration:0.8 animations:^{
                    photoCardCell.likePhotoButton.alpha = 0;
                    [photoCardCell.likePhotoButton setSelected:NO];
                    photoCardCell.likePhotoButton.alpha = 1;
                }];
            });
        }
        
    }];
 
}


- (IBAction)likePicture:(id)sender
{
    
    UIButton *likeButton = (UIButton *)sender;
    
    PhotoStreamCell *cell = (PhotoStreamCell *)likeButton.superview.superview.superview;
    NSIndexPath *indexPath = [self.photoCollectionView indexPathForCell:cell];
    
    NSString *picId = self.photos[indexPath.item][@"id"];
    
    if (likeButton.state == UIControlStateNormal || likeButton.state == UIControlStateHighlighted)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10000), dispatch_get_main_queue(),^{
            
            [cell.likePhotoButton setSelected:YES];
        });
        [self likePhotoWithID:picId atIndexPath:selectedPhoto];
        
    }else{
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10000), dispatch_get_main_queue(),^{
            
            [cell.likePhotoButton setSelected:NO];
        });

        [self unlikePhotoWithID:picId atIndexPath:selectedPhoto];
       }
    
        
}


/*-(void)updatePhotosNumberOfLikes:(NSMutableArray *)photos photoId:(NSString *)photoId update:(NSString *)likes
{
    NSMutableDictionary *guiltyPhoto = nil;
    NSInteger indexOfLikedPhoto = 0;
    for (NSDictionary *photo in photos) {
        if ([photo[@"id"] integerValue] == [photoId integerValue]){
            indexOfLikedPhoto = [photos indexOfObject:photo];
            DLog(@"Index of liked photo - %i",indexOfLikedPhoto);
            guiltyPhoto = [NSMutableDictionary dictionaryWithDictionary:photo];
            break;
        }
    }
    guiltyPhoto[@"id"] = likes;
    self.photos[indexOfLikedPhoto] = guiltyPhoto;
    DLog(@"Guilty photo - %@",self.photos[indexOfLikedPhoto]);
}*/



- (void)savePhoto:(UIImage *)imageToSave {
    
    if (imageToSave != nil){
        [self savePhotoToCustomAlbum:imageToSave];

    }else{
        [AppHelper showAlert:@"Save Image Request"
                     message:@"You can save image after it loads"
                     buttons:@[@"OK, I'll wait"]
                    delegate:nil];
    }
    
    
}


-(void)createStandardImage:(CGImageRef)image completon:(StandardPhotoCompletion)completion
{
   // __block CGImageRef rawImage =
    dispatch_queue_t createStandardPhotoQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(createStandardPhotoQueue, ^{
        
        const size_t width = CGImageGetWidth(image);
        const size_t height = CGImageGetHeight(image);
        CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
        CGContextRef ctx = CGBitmapContextCreate(NULL, width, height, 8, 4*width, space,
                                                 kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedFirst);
        CGColorSpaceRelease(space);
        CGContextDrawImage(ctx, CGRectMake(0, 0, width, height), image);
        CGImageRef dstImage = CGBitmapContextCreateImage(ctx);
        CGContextRelease(ctx);

        
        dispatch_async(dispatch_get_main_queue(),^{
            completion(dstImage,nil);
        });
    });

    //[UIImage alloc] in
}


- (void)resizePhoto:(UIImage*) image towidth:(float) width toHeight:(float) height completon:(PhotoResizedCompletion)completion
{
    /*dispatch_queue_t resizePhotoQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(resizePhotoQueue, ^{
        
        BOSImageResizeOperation* op = [[BOSImageResizeOperation alloc] initWithImage:image];
        [op resizeToFitWithinSize:CGSizeMake(width, height)];
        [op start];
        dispatch_async(dispatch_get_main_queue(),^{
            completion(image,nil);
        });
    });*/
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
         BOSImageResizeOperation* op = [[BOSImageResizeOperation alloc] initWithImage:image];
        [op start];
        
        UIImage* smallerImage = op.result;
        dispatch_async(dispatch_get_main_queue(),^{
            completion(smallerImage,nil);
        });
    });


    
}


-(void) resizeImage:(UIImage*)image towidth:(float)width toHeight:(float)height completon:(PhotoResizedCompletion)completion
{
    dispatch_queue_t resizePhotoQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(resizePhotoQueue, ^{
        
        float actualHeight = image.size.height;
        float actualWidth = image.size.width;
        float imgRatio = actualWidth/actualHeight;
        float maxRatio = width/height;
        if(imgRatio!=maxRatio){
            if(imgRatio < maxRatio){
                imgRatio = width/ actualHeight;
                actualWidth = imgRatio * actualWidth;
                actualHeight = height;
            }
            else{
                imgRatio = width / actualWidth;
                actualHeight = imgRatio * actualHeight;
                actualWidth = width;
            }
        }
        CGRect rect = CGRectMake(0.0, 0.0, actualWidth, actualHeight);
        UIGraphicsBeginImageContext(rect.size);
        [image drawInRect:rect];
        UIImage *resizedImg = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        dispatch_async(dispatch_get_main_queue(),^{
            completion(resizedImg,nil);
        });
    });
    
}

- (IBAction)cameraButtonTapped:(id)sender
{
    // Check whether the user
    
    
    
    NSString *streamCreator = self.spotInfo[@"userName"];
    
    if ([streamCreator isEqualToString:[AppHelper userName]]) { // If user created this album no problem
        [self showPhotoOptions];
        
    }else{ // If user is not creator,check whether he/she can add photos
        
    BOOL userCanAddPhoto = ([self.spotInfo[@"addPrivacy"] isEqualToString:@"ANYONE"]) ? YES: NO;
        
    if (userCanAddPhoto){
        [self showPhotoOptions];
    }else{
        [AppHelper showAlert:@"Add Photo"
                     message:@"You are not allowed to add photos to this stream"
                     buttons:@[@"OK"] delegate:nil];
    }
        
 }
    
}


- (IBAction)settingsButtonTapped:(id)sender
{
    [self performSegueWithIdentifier:@"SpotSettingsSegue" sender:self.spotID];
}

- (IBAction)shareAlbumAction:(id)sender
{
    [self share:kSpot Sender:sender];
}

-(void)showReportOptions
{
    UIActionSheet *actionsheet = [[UIActionSheet alloc] initWithTitle:@"Why are you reporting photo?"
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@" This photo is sexually explicit",@"This is photo is unrelated",nil];
    actionsheet.tag = 2000;
    //actionsheet.destructiveButtonIndex = 1;
    [actionsheet showInView:self.view];
  
}


- (IBAction)showMoreActions:(UIButton *)sender
{
    PhotoStreamCell *cell = (PhotoStreamCell *)sender.superview.superview.superview;
    NSIndexPath *indexpath = [self.photoCollectionView indexPathForCell:cell];
    self.photoInView = self.photos[indexpath.row];
    photoToSave = cell.photoCardImage.image;
    
    
    NSString *pictureTaker = self.photos[indexpath.item][@"pictureTaker"];
    
    if ([[AppHelper userName] isEqualToString:pictureTaker]) {
        //DLog(@"Allow the user to delete photo because -%@ = %@",[AppHelper userName],pictureTaker);
        UIActionSheet *actionsheet = [[UIActionSheet alloc] initWithTitle:@"More Actions"
                                                                 delegate:self
                                                        cancelButtonTitle:@"Cancel"
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:@"Save Photo",@"Delete Photo",@"Report Photo", nil];
        actionsheet.tag = 5000;
        actionsheet.destructiveButtonIndex = 2;
        [actionsheet showInView:self.view];
        
    }else{
        UIActionSheet *actionsheet = [[UIActionSheet alloc] initWithTitle:@"More Actions"
                                                                 delegate:self
                                                        cancelButtonTitle:@"Cancel"
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:@"Save Photo",@"Report Photo", nil];
        actionsheet.tag = 1000;
        actionsheet.destructiveButtonIndex = 1;
        [actionsheet showInView:self.view];
    }
    
    
    
}


-(void)showPhotoOptions
{
    UIActionSheet *action = [[UIActionSheet alloc] initWithTitle:@"Choose Photo" delegate:self cancelButtonTitle:@"Not Now" destructiveButtonTitle:nil otherButtonTitles:@"Take Photo",@"Choose From Gallery", nil];
    
    [action showInView:self.view];
}

-(void)resamplePhotoInfo:(NSDictionary *)info flag:(NSString *)flag numberOfLikes:(NSString *)likes atIndex:(NSInteger)selectedIndex
{
    [self.photos removeObjectAtIndex:selectedIndex];
    NSMutableDictionary *mutablePhotoInfo = [NSMutableDictionary dictionaryWithDictionary:info];
    
    mutablePhotoInfo[@"userLikedPhoto"] = flag;
    mutablePhotoInfo[@"likes"] = likes;
    
    [self.photos insertObject:mutablePhotoInfo atIndex:selectedIndex];
    
    //DLog(@"Before mutation - %@\nAfter mutation - %@",[info debugDescription],[mutablePhotoInfo debugDescription]);
}


-(void)saveLikeButtonInitialBounds:(UIButton *)button
{
    self.likeButtonBounds = button.bounds;
    DLog(@"Bouncing -%@",NSStringFromCGRect(button.bounds));
    
    // Force the button image to scale with its bounds.
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
    
    button.contentVerticalAlignment = UIControlContentHorizontalAlignmentFill;

}

/*-(void)bounceLikeButton:(id)sender
{
    // Reset the buttons bounds to their initial state.  See the comment in
    ((UIButton *)sender).bounds = self.likeButtonBounds;
    DLog(@"Bouncing -%@",NSStringFromCGRect(((UIButton *)sender).bounds));
    // UIDynamicAnimator instances are relatively cheap to create.
    UIDynamicAnimator *animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    
    // APLPositionToBoundsMapping maps the center of an id<ResizableDynamicItem>
    // (UIDynamicItem with mutable bounds) to its bounds.  As dynamics modifies
    // the center.x, the changes are forwarded to the bounds.size.width.
    // Similarly, as dynamics modifies the center.y, the changes are forwarded
    // to bounds.size.height.
    APLPositionToBoundsMapping *buttonBoundsDynamicItem = [[APLPositionToBoundsMapping alloc] initWithTarget:sender];
    
    // Create an attachment between the buttonBoundsDynamicItem and the initial
    // value of the button's bounds.
    UIAttachmentBehavior *attachmentBehavior = [[UIAttachmentBehavior alloc] initWithItem:buttonBoundsDynamicItem attachedToAnchor:buttonBoundsDynamicItem.center];
    [attachmentBehavior setFrequency:2.0];
    [attachmentBehavior setDamping:0.3];
    [animator addBehavior:attachmentBehavior];
    
    UIPushBehavior *pushBehavior = [[UIPushBehavior alloc] initWithItems:@[buttonBoundsDynamicItem] mode:UIPushBehaviorModeInstantaneous];
    pushBehavior.angle = M_PI_4;
    pushBehavior.magnitude = 2.0;
    [animator addBehavior:pushBehavior];
    
    [pushBehavior setActive:TRUE];
    
    self.likeButtonAnimator = animator;

}*/



#pragma mark - Helpers for Social Media
- (void)share:(Mutant)objectOfInterest Sender:(UIButton *)sender
{
    NSArray *activityItems = nil;
    NSString *shareText = nil;
    if (objectOfInterest == kSpot) {
        //DLog(@"SpotId - %@",self.spotID);
        NSString *randomString = [self getRandomPINString:5];
        //DLog(@"Random String - %@",randomString);
        shareText = [NSString stringWithFormat:@"Check out all the photos in my shared stream %@ with Suba for iOS @ http://www.subaapp.com/albums?%@",self.navigationItem.title,[NSString stringWithFormat:@"%@%@",self.spotID,randomString]];
        
        
        activityItems = @[self.albumSharePhoto,shareText];
        [Flurry logEvent:@"Share_Stream_Tapped"];
        
    }else if (objectOfInterest == kPhoto){
        
        //DLog(@"Photo Cell - %@",sender.superview.superview.superview);
        PhotoStreamCell *cell = (PhotoStreamCell *)sender.superview.superview.superview;
        shareText = [NSString stringWithFormat:@"Check out all the photos in my shared stream %@ with Suba for iOS.",self.navigationItem.title];
        
        activityItems = @[cell.photoCardImage.image,shareText];
        [Flurry logEvent:@"Share_Photo_Tapped"];
    }
    
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    
    activityVC.excludedActivityTypes = @[UIActivityTypePrint,UIActivityTypeCopyToPasteboard,UIActivityTypeAssignToContact,UIActivityTypeSaveToCameraRoll,UIActivityTypeAddToReadingList,UIActivityTypeAirDrop];
    
    [self presentViewController:activityVC animated:YES completion:nil];
  
}


-(void)savePhotoToCustomAlbum:(UIImage *)photo
{
    [self.library saveImage:photo toAlbum:@"Suba Photos" completion:^(NSURL *assetURL, NSError *error) {
        [AppHelper showNotificationWithMessage:@"Image saved in camera roll" type:kSUBANOTIFICATION_SUCCESS inViewController:self completionBlock:nil];
        
        [Flurry logEvent:@"Photo_Saved"];
        
    }failure:^(NSError *error){
        [AppHelper showAlert:@"Save image error"
                     message:@"There was an error saving the photo"
                     buttons:@[@"OK"]
                    delegate:nil];
    }];
}


- (void)pickAssets
{
    
    CTAssetsPickerController *picker = [[CTAssetsPickerController alloc] init];
    picker.navigationBar.translucent = NO;
    picker.navigationItem.rightBarButtonItem.tintColor = [UIColor whiteColor];
    //picker.navigationItem.rightBarButtonItem. = [UIColor whiteColor];
    picker.showsCancelButton = YES;
    //picker.navigationBar.barTintColor = [UIColor colorWithRed:(217.0f/255.0f)
                                                     //green:(77.0f/255.0f)
                                                      //blue:(20.0f/255.0f)
                                                     //alpha:1];
    picker.maximumNumberOfSelection = 5;
    picker.assetsFilter = [ALAssetsFilter allPhotos];
    picker.delegate = self;
    
    [self presentViewController:picker animated:YES completion:NULL];
}

#pragma mark - Assets Picker Delegate

- (void)assetsPickerController:(CTAssetsPickerController *)picker didFinishPickingAssets:(NSArray *)assets
{
    //[self.assets addObjectsFromArray:assets];
    if ([assets count] == 1) {
        ALAsset *asset = (ALAsset *)assets[0];
        ALAssetRepresentation *representation = asset.defaultRepresentation;
        UIImage *fullResolutionImage = [UIImage imageWithCGImage:representation.fullScreenImage
                                                           scale:1.0f
                                                     orientation:(UIImageOrientation)ALAssetOrientationUp];
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        
        [dateFormatter setDateFormat:@"yyyy:MM:dd HH:mm:ss.SSSSSS"];
        NSString *timeStamp = [dateFormatter stringFromDate:[NSDate date]];
        NSString *trimmedString = [timeStamp stringByReplacingOccurrencesOfString:@" " withString:@""];
        trimmedString = [trimmedString stringByReplacingOccurrencesOfString:@"-" withString:@":"];
        trimmedString = [trimmedString stringByReplacingCharactersInRange:NSMakeRange([trimmedString length]-7, 7) withString:@""];
        
        
        [self resizePhoto:fullResolutionImage towidth:640.0f toHeight:852.0f completon:^(UIImage *compressedPhoto, NSError *error) {
            NSData *imageData = UIImageJPEGRepresentation(compressedPhoto, 1.0);
            [self uploadPhoto:imageData WithName:trimmedString];
        }];
        
        /*[self createStandardImage:representation.fullScreenImage
                        completon:^(CGImageRef standardPhoto, NSError *error) {
                            
        UIImage *fullResolutionImage = [UIImage imageWithCGImage:standardPhoto
                                                scale:1.0f
                                                orientation:(UIImageOrientation)ALAssetOrientationUp];
        
         NSData *imageData = UIImageJPEGRepresentation(fullResolutionImage, 1.0);
         [self uploadPhoto:imageData WithName:trimmedString];
                            
        }];*/
        
        
        /*[self resizeImage:fullResolutionImage towidth:640.0f toHeight:640.0f
                completon:^(UIImage *compressedPhoto, NSError *error) {
                    
                    UIImage *newImage = compressedPhoto;
                    NSData *imageData = UIImageJPEGRepresentation(newImage, 1.0);
                    
                    [self uploadPhoto:imageData WithName:trimmedString];
                    
        }];*/
        
    }else if([assets count] > 1){ // User selected more than one photo
        [self uploadPhotos:assets];
    }else if([assets count] == 0){
        [AppHelper showAlert:@"Add Photo"
                     message:@"You did not select a photo to add to the stream"
                     buttons:@[@"OK"] delegate:nil];
    }
    
}



-(void)pickImage:(id)sender
{
    //DLog(@"Source Type - %@",sender);
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
       
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
        if ([sender intValue] == kTakeCamera) {
            imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
            imagePicker.delegate = self;
            imagePicker.allowsEditing = NO;
            
            [self presentViewController:imagePicker animated:YES completion:nil];
        }else if([sender intValue] == kGallery){
            [self pickAssets];
        }
       
    }else{
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Camera Error" message:@"No Camera" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
        [alert show];
        
    }
}

- (IBAction)moveToProfile:(UIButton *)sender
{
    DLog(@"sender.superview.superview.superview - %@",[sender.superview.superview.superview class]);
    PhotoStreamCell *pCell = (PhotoStreamCell *)sender.superview.superview.superview;
    NSIndexPath *indexPath = [self.photoCollectionView indexPathForCell:pCell];
    NSDictionary *cellInfo = self.photos[indexPath.item];
    NSString *picTakerId = cellInfo[@"pictureTakerId"];
    
    [self performSegueWithIdentifier:@"PHOTOSTREAM_USERPROFILE" sender:picTakerId];
    DLog(@"Cell info -  %@\nUserId -%@",cellInfo,picTakerId);
}



#pragma mark - UIActionSheet Delegate Methods
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == 5000){
        
        if(buttonIndex == 0){
            //User wants to save photo
            [self savePhoto:photoToSave];
        }else if (buttonIndex == 1){
            DLog(@"User wants to delete photo");
            NSInteger index = [self.photos indexOfObject:self.photoInView];
            [self deletePhotoAtIndexFromStream:index];
        }
        
    }else if (actionSheet.tag == 1000){
        if(buttonIndex == 0){
            //User wants to save photo
            [self savePhoto:photoToSave];
        }
           
    }else if(actionSheet.tag == 2000){
        // User is reporting a photo
        NSString *reportType = nil;
        if (buttonIndex == kSexuallyExplicit){
            reportType = kSEXUALLY_EXPLICIT;
            
            
        }else{
            reportType = kUNRELATED_PHOTO;
           DLog(@"Photo is unrelated");
        }
        
        // form report photo info
        //DLog(@"report info - %@",self.reportInfo);
        NSDictionary *params = @{
                                 @"photoId":self.photoInView[@"id"],
                                 @"spotId" : self.spotID, 
                                 @"pictureTakerName" : self.photoInView[@"pictureTaker"],
                                 @"reporterId" : [AppHelper userID],
                                 @"reportType" : reportType
                                 };
        
        
        [self reportPhoto:params];
    }
    
    else{
    
    if (buttonIndex == kTakeCamera) {
        // Call the Camera here
        //DLog(@"Calling camera");
        //[self pickPhoto:kTakeCamera];
        [self performSelector:@selector(pickImage:) withObject:@(kTakeCamera) afterDelay:0.5];
    }else if (buttonIndex == kGallery){
        // Choose from the Gallery
        //DLog(@"Using the assets picker");
        //[self pickPhoto:kGallery];
        [self performSelector:@selector(pickImage:) withObject:@(kGallery) afterDelay:0.5];
    }
}
    //NSLog(@"Button Clicked is %li",(long)buttonIndex);
    //[actionSheet dismissWithClickedButtonIndex:buttonIndex animated:YES];
    
}


-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == 1000){
        if (buttonIndex == 1) {
            [self showReportOptions];
        }
    }else if (actionSheet.tag == 5000){
        if (buttonIndex == 2) {
            [self showReportOptions];
        }
    }
}


#pragma mark - UIImagePickerController Delegate
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [Flurry logEvent:@"Photo_Taken"];
    
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    [dateFormatter setDateFormat:@"yyyy:MM:dd HH:mm:ss.SSSSSS"];
    NSString *timeStamp = [dateFormatter stringFromDate:[NSDate date]];
    NSString *trimmedString = [timeStamp stringByReplacingOccurrencesOfString:@" " withString:@""];
    trimmedString = [trimmedString stringByReplacingOccurrencesOfString:@"-" withString:@":"];
    trimmedString = [trimmedString stringByReplacingCharactersInRange:NSMakeRange([trimmedString length]-7, 7) withString:@""];
    
    DLog(@"Image resolution - %@",NSStringFromCGSize(image.size));
    
    [self resizePhoto:image towidth:640.0f toHeight:852.0f
            completon:^(UIImage *compressedPhoto, NSError *error) {
                if (!error) {
                    NSData *imageData = UIImageJPEGRepresentation(compressedPhoto, 1.0);
                    
                    [self uploadPhoto:imageData WithName:trimmedString];
                }else DLog(@"Image resize error :%@",error);
        
    }];
    
    /*[self createStandardImage:image.CGImage
                    completon:^(CGImageRef standardPhoto, NSError *error) {
                        
        UIImage *fullResolutionImage = [UIImage imageWithCGImage:standardPhoto
                                                           scale:1.0
                                                     orientation:(UIImageOrientation)ALAssetOrientationRight];
                                        
        NSData *imageData = UIImageJPEGRepresentation(fullResolutionImage, 1.0);
        [self uploadPhoto:imageData WithName:trimmedString];
    }];*/
    
    /*[self resizeImage:image towidth:640.0f toHeight:640.0f
           completon:^(UIImage *compressedPhoto, NSError *error) {
                
                UIImage *newImage = compressedPhoto;
               NSData *imageData = UIImageJPEGRepresentation(newImage, 1.0);
               
               [self uploadPhoto:imageData WithName:trimmedString];
        }];*/
    
    [picker.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}


-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}



-(void)uploadPhotos:(NSArray *)assets
{
    NSMutableArray *imagesData = [NSMutableArray arrayWithCapacity:2];
   // NSMutableArray *mutableOperations = [NSMutableArray array];
    
    NSString *userId = [User currentlyActiveUser].userID;
    NSString *spotId = self.spotID;
    
    NSDictionary *params = @{@"userId": userId,@"spotId": spotId};
    AFHTTPSessionManager *manager = [SubaAPIClient sharedInstance];
    
    NSURL *baseURL = (NSURL *)[SubaAPIClient subaAPIBaseURL];
    
    NSString *urlPath = [[NSURL URLWithString:@"spot/pictures/add" relativeToURL:baseURL] absoluteString];
    __block NSMutableURLRequest *request = nil;
    
    for (ALAsset *asset in assets){
        ALAssetRepresentation *representation = asset.defaultRepresentation;
        UIImage *fullResolutionImage = [UIImage imageWithCGImage:representation.fullScreenImage
                                                           scale:1.0f
                                                     orientation:(UIImageOrientation)ALAssetOrientationUp];
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        
        [dateFormatter setDateFormat:@"yyyy:MM:dd HH:mm:ss.SSSSSS"];
        NSString *timeStamp = [dateFormatter stringFromDate:[NSDate date]];
        NSString *name = [timeStamp stringByReplacingOccurrencesOfString:@" " withString:@""];
        name = [name stringByReplacingOccurrencesOfString:@"-" withString:@":"];
        name = [name stringByReplacingCharactersInRange:NSMakeRange([name length]-7, 7) withString:@""];
        
        [imagesData addObject:@{@"imageData": fullResolutionImage, @"imageName" : name}];
        
        DLog(@"Filling images data with name - %@",name);
    }
    
    request = [manager.requestSerializer multipartFormRequestWithMethod:@"POST" URLString:urlPath parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        
        for (NSDictionary *imageInfo in imagesData){
            //DLog(@"Images being resized");
            
            //[self resizePhoto:imageInfo[@"imageData"] towidth:640.0f toHeight:852.0f
              //      completon:^(UIImage *compressedPhoto, NSError *error){
                        //DLog(@"Does it even get here - %@",imageInfo[@"imageName"]);
                    NSData *imageData = UIImageJPEGRepresentation(imageInfo[@"imageData"], 1.0);
                    [formData appendPartWithFileData:imageData name:imageInfo[@"imageName"] fileName:[NSString stringWithFormat:@"%@.jpg",imageInfo[@"imageName"]] mimeType:@"image/jpeg"];
                //}];
             }
        //DLog(@"DONE");
     }];
    
    AFURLConnectionOperation *operation = [[AFURLConnectionOperation alloc] initWithRequest:request];
    __weak AFURLConnectionOperation *woperation = operation;
    
    self.imageUploadProgressView.hidden = NO;
    
    [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite){
        self.imageUploadProgressView.progress = (float) totalBytesWritten / totalBytesExpectedToWrite;
        
        if (self.imageUploadProgressView.progress == 1.0){
            self.imageUploadProgressView.hidden = YES; // or remove from superview
        }
    }];
   
    
    [operation setCompletionBlock:^{
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSError *error = nil;
            
            // Check for when we are getting a nil data parameter back
            NSDictionary *photoInfo = [NSJSONSerialization JSONObjectWithData:woperation.responseData options:NSJSONReadingAllowFragments error:&error];
            if (error) {
                DLog(@"Error serializing %@", error);
                [AppHelper showAlert:@"Upload Failure" message:error.localizedDescription buttons:@[@"OK"] delegate:nil];
            }else{
                
                if ([photoInfo[STATUS] isEqualToString:ALRIGHT]) {
                    [Flurry logEvent:@"Photo_Upload"];
                    
                    [[NSNotificationCenter defaultCenter]
                     postNotificationName:kUserReloadStreamNotification object:nil];
                    
                    self.noPhotosView.hidden = YES;
                    self.photoCollectionView.hidden = NO;
                    if (!self.photos) {
                        
                        self.photos = [NSMutableArray arrayWithArray:photoInfo[@"photos"]];
                    }else{
                       //[self.photos insertObject:photoInfo atIndex:0];
                        [self.photos insertObjects:photoInfo[@"photos"] atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [photoInfo[@"photos"] count])]];
                        DLog(@"Photos Uploaded - %@",photoInfo); 
                    }
                    
                    [self upDateCollectionViewWithCapturedPhotos:photoInfo[@"photos"]];
                    
                }
            }
        });
    }];
    
    [operation start];
    
    
    
}





-(void)uploadPhoto:(NSData *)imageData WithName:(NSString *)name
{
    NSString *userId = [User currentlyActiveUser].userID;
    NSString *spotId = self.spotID;
    
    NSDictionary *params = @{@"userId": userId,@"spotId": spotId};
    AFHTTPSessionManager *manager = [SubaAPIClient sharedInstance];
    
    NSURL *baseURL = (NSURL *)[SubaAPIClient subaAPIBaseURL];
    
    NSString *urlPath = [[NSURL URLWithString:@"spot/picture/add" relativeToURL:baseURL] absoluteString];
    
    NSMutableURLRequest *request = [manager.requestSerializer
                                    multipartFormRequestWithMethod:@"POST"
                                    URLString:urlPath
                                    parameters:params
                                    constructingBodyWithBlock:^(id<AFMultipartFormData> formData){
                                        
                                        [formData appendPartWithFileData:imageData name:@"picture" fileName:[NSString stringWithFormat:@"%@.jpg",name] mimeType:@"image/jpeg"];
                                    }];
    
    //[manager.requestSerializer setValue:@"com.suba.subaapp" forHTTPHeaderField:@"x-suba-api-token"];

    AFURLConnectionOperation *operation = [[AFURLConnectionOperation alloc] initWithRequest:request];
    __weak AFURLConnectionOperation *woperation = operation;
    
    self.imageUploadProgressView.hidden = NO;
    
    [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        //DLog(@"Upload progress value -  %f",(float) totalBytesWritten / totalBytesExpectedToWrite);
        self.imageUploadProgressView.progress = (float) totalBytesWritten / totalBytesExpectedToWrite;
        if (self.imageUploadProgressView.progress == 1.0){
            self.imageUploadProgressView.hidden = YES; // or remove from superview
            
        }
    }];
    
    [operation setCompletionBlock:^{
        
        dispatch_async(dispatch_get_main_queue(), ^{
            //NSLog(@"response - %@",woperation.responseData);
            NSError *error = nil;
            // Check for when we are getting a nil data parameter back
            NSDictionary *photoInfo = [NSJSONSerialization JSONObjectWithData:woperation.responseData options:NSJSONReadingAllowFragments error:&error];
            if (error) {
                DLog(@"Error serializing %@", error);
                [AppHelper showAlert:@"Upload Failure" message:error.localizedDescription buttons:@[@"OK"] delegate:nil];
            }else{
                
                //DLog(@"Photo upload response - %@",[photoInfo valueForKey:@"status"]);
                
                if ([photoInfo[STATUS] isEqualToString:ALRIGHT]) {
                    [Flurry logEvent:@"Photo_Upload"];
                    
                    [[NSNotificationCenter defaultCenter]
                     postNotificationName:kUserReloadStreamNotification object:nil];
                    
                    self.noPhotosView.hidden = YES;
                    self.photoCollectionView.hidden = NO;
                    if (!self.photos) {
                        
                        self.photos = [NSMutableArray arrayWithObject:photoInfo];
                    }else [self.photos insertObject:photoInfo atIndex:0];
                    
                    [self upDateCollectionViewWithCapturedPhoto:photoInfo];

                }
            }
    });        
}];
    
    [operation start];
}

-(void)upDateCollectionViewWithCapturedPhoto:(NSDictionary *)photoInfo{
    
    
    [self.photoCollectionView performBatchUpdates:^{
        [self.photoCollectionView insertItemsAtIndexPaths:@[ [NSIndexPath indexPathForItem:0 inSection:0] ]];
    } completion:^(BOOL finished) {
        [self.photoCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionLeft animated:YES];
    }];
    
    // Tell push provider to send
    
    NSArray *members = self.spotInfo[@"members"];
    
    NSMutableArray *memberIds = [NSMutableArray arrayWithCapacity:1];
    for (NSDictionary *member in members){
        if (![member[@"userName"] isEqualToString:[AppHelper userName]]) {
            [memberIds addObject:member[@"id"]];
        }
        
    }
    
    NSDictionary *params = @{@"spotId": self.spotID,
                             @"spotName" : self.spotName,
                             @"memberIds" : [memberIds description]};
    
    //DLog(@"MEMBERSIDS  - %@\nPicture taker ID - %@",[memberIds description],[AppHelper userID]);
    
    [[LSPushProviderAPIClient sharedInstance] POST:@"photosadded"
                                        parameters:params
                         constructingBodyWithBlock:nil
                                           success:^(NSURLSessionDataTask *task, id responseObject) {
        DLog(@"From push provider - %@",responseObject);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        DLog(@"Error - %@",error);
    }];
    
}


-(void)upDateCollectionViewWithCapturedPhotos:(NSArray *)photoInfo{
    NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:2];
    for (int x = 0; x < [photoInfo count]; x++) {
        [indexPaths addObject:[NSIndexPath indexPathForItem:x inSection:0]];
    }
    
    [self.photoCollectionView performBatchUpdates:^{
        [self.photoCollectionView insertItemsAtIndexPaths:indexPaths];
    } completion:^(BOOL finished) {
        [self.photoCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionLeft animated:YES];
    }];
    
    // Tell push provider to send
    
    NSArray *members = self.spotInfo[@"members"];
    
    NSMutableArray *memberIds = [NSMutableArray arrayWithCapacity:1];
    for (NSDictionary *member in members){
        if (![member[@"userName"] isEqualToString:[AppHelper userName]]) {
            [memberIds addObject:member[@"id"]];
        }
        
    }
    
    NSDictionary *params = @{@"spotId": self.spotID,
                             @"spotName" : self.spotName,
                             @"memberIds" : [memberIds description]};
    
    //DLog(@"MEMBERSIDS  - %@\nPicture taker ID - %@",[memberIds description],[AppHelper userID]);
    
    [[LSPushProviderAPIClient sharedInstance] POST:@"photosadded"
                                        parameters:params
                         constructingBodyWithBlock:nil
                                           success:^(NSURLSessionDataTask *task, id responseObject) {
                                               DLog(@"From push provider - %@",responseObject);
                                           } failure:^(NSURLSessionDataTask *task, NSError *error) {
                                               DLog(@"Error - %@",error);
                                           }];
    
}



#pragma mark - Segues
-(void)unWindToPhotoStream:(UIStoryboardSegue *)segue
{
    
}

-(void)unWindToPhotoStreamWithWithInfo:(UIStoryboardSegue *)segue
{
    AlbumSettingsViewController *albumVC = segue.sourceViewController;
    self.navigationItem.title = albumVC.spotName;
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"SpotSettingsSegue"]) {
        if ([segue.destinationViewController isKindOfClass:[AlbumSettingsViewController class]]) {
            AlbumSettingsViewController *albumVC = segue.destinationViewController;
            albumVC.spotID = (NSString *)sender;
            albumVC.spotInfo = self.spotInfo;
            albumVC.whereToUnwind = [self.parentViewController childViewControllers][0];
            DLog(@"WhereToUnwind - %@",[albumVC.whereToUnwind class]);
        }
    }else if ([segue.identifier isEqualToString:@"AlbumMembersSegue"]){
        if ([segue.destinationViewController isKindOfClass:[AlbumMembersViewController class]]){
            AlbumMembersViewController *membersVC = segue.destinationViewController;
            membersVC.spotID = sender;
            //membersVC.spotInfo = self.spotInfo;
        }
    }else if ([segue.identifier isEqualToString:@"PHOTOSTREAM_USERPROFILE"]){
        UserProfileViewController *uVC = segue.destinationViewController;
        uVC.userId = sender;
    }
}



#pragma mark - handle gesture recognizer
- (void)photoCardTapped:(UITapGestureRecognizer *)sender
{
    
    if (sender.state == UIGestureRecognizerStateEnded)
    {
        NSString *photoId = self.photos[selectedPhoto.item][@"id"];
        
        if ([self.photos[selectedPhoto.item][@"userLikedPhoto"] isEqualToString:@"NO"]) {
            
            [self likePhotoWithID:photoId atIndexPath:selectedPhoto];
            
        }else{
                [self unlikePhotoWithID:photoId atIndexPath:selectedPhoto];
        }
        
    }
}



#pragma mark - PhotoBrowser Delegate
-(void)photoBrowser:(IDMPhotoBrowser *)photoBrowser didDismissAtPageIndex:(NSUInteger)index
{
    [photoBrowser dismissViewControllerAnimated:YES completion:nil];
}



#pragma mark - State Preservation and Restoration
-(void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeObject:self.spotInfo forKey:SpotInfoKey];
    [coder encodeObject:self.spotName forKey:SpotNameKey];
    [coder encodeObject:self.spotID forKey:SpotIdKey];
    [coder encodeObject:self.photos forKey:SpotPhotosKey];
    //[coder encodeObject:@(selectedButton) forKey:SelectedButtonKey];
    
    //DLog(@"self.spotInfo -%@\nself.spotName -%@\nself.spotID - %@\nself.photos - %@",self.spotInfo,self.spotName,self.spotID,self.photos);
}


-(void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super decodeRestorableStateWithCoder:coder];
    
    self.spotInfo = [coder decodeObjectForKey:SpotInfoKey];
    self.spotName = [coder decodeObjectForKey:SpotNameKey];
    self.spotID = [coder decodeObjectForKey:SpotIdKey];
    self.photos = [coder decodeObjectForKey:SpotPhotosKey];
    
   //DLog(@"self.spotInfo -%@\nself.spotName -%@\nself.spotID - %@\nself.photos - %@",self.spotInfo,self.spotName,self.spotID,self.photos);
    
}

-(void)applicationFinishedRestoringState
{
     //DLog(@"self.spotInfo -%@\nself.spotName -%@\nself.spotID - %@\nself.photos - %@",self.spotInfo,self.spotName,self.spotID,self.photos);
    [self loadSpotInfo:self.spotID User:[AppHelper userID]];
    //1. Update photos
    if (self.photos) {
        [self.photoCollectionView reloadData];
    }
    
    if (self.spotID) {
        [self loadSpotImages:self.spotID];
    }
    
    if (self.spotName) {
        //DLog(@"SpotName - %@\nSpotId - %@",self.spotName,self.spotID);
        self.navigationItem.title = self.spotName;
    }
    
    //2. If spotInfo is nil,loadspotInfo
    if (self.spotID && !self.spotInfo) {
        [self loadSpotInfo:self.spotID User:[AppHelper userID]];
    }
    
  
}







@end
