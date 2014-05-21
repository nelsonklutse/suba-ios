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
#import "Comment.h"
#import "BDKNotifyHUD.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <MWPhotoBrowser.h>
#import <EBPhotoPagesController.h>
//#import <IDMPhotoBrowser.h>
#import "BOSImageResizeOperation.h"
#import <QuartzCore/QuartzCore.h>

typedef void (^PhotoResizedCompletion) (UIImage *compressedPhoto,NSError *error);
typedef void (^StandardPhotoCompletion) (CGImageRef standardPhoto,NSError *error);

#define SpotInfoKey @"SpotInfoKey"
#define SpotNameKey @"SpotNameKey"
#define SpotIdKey @"SpotIdKey"
#define SpotPhotosKey @"SpotPhotosKey"



@interface PhotoStreamViewController ()<UICollectionViewDataSource,UICollectionViewDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate,UIActionSheetDelegate,CTAssetsPickerControllerDelegate,MWPhotoBrowserDelegate,UIGestureRecognizerDelegate,EBPhotoPagesDataSource,EBPhotoPagesDelegate>
{
    UIImage *selectedPhoto;
    NSIndexPath *selectedPhotoIndexPath;
    EBPhotoPagesController *ebPhotoPagesController;
    NSMutableArray *comments;   //of comments
    
}

@property (strong,nonatomic) NSDictionary *photoInView;
@property (strong,nonatomic) NSDictionary *spotInfo;
@property (strong,atomic) ALAssetsLibrary *library;
@property (strong,nonatomic) UIImage *albumSharePhoto;

//@property (weak, nonatomic) IBOutlet FXBlurView *viewToAnimate;

@property (weak, nonatomic) IBOutlet UIImageView *coachMarkImageView;
@property (weak, nonatomic) IBOutlet UIProgressView *imageUploadProgressView;
@property (weak, nonatomic) IBOutlet UICollectionView *photoCollectionView;
@property (weak, nonatomic) IBOutlet UIButton *gotItButton;

@property (weak, nonatomic) IBOutlet UIView *loadingInfoIndicatorView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingStreamInfoIndicator;
@property (weak, nonatomic) IBOutlet UIButton *cameraButton;
@property (weak, nonatomic) IBOutlet UIImageView *likeImage;

@property (retain,nonatomic) MWPhotoBrowser *browser;

//@property (nonatomic, readwrite) CGRect likeButtonBounds;
//@property (nonatomic, strong) UIDynamicAnimator *likeButtonAnimator;

@property (weak, nonatomic) IBOutlet UIView *noPhotosView;

@property (strong,nonatomic) UILabel *navItemTitle;

- (IBAction)commentOnPhoto:(UIButton *)sender;
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

- (void)showFullScreenPhotoBrowser:(UITapGestureRecognizer *)sender;
- (void)scrollToCorrect:(UIScrollView*)scrollView;
- (NSMutableArray *)prepareComments:(NSArray *)commentsInfo;
@end

@implementation PhotoStreamViewController
int toggler;
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    comments = [NSMutableArray arrayWithCapacity:2];
    /*
     self.viewToAnimate.blurEnabled = YES;
    self.viewToAnimate.dynamic = NO;
    self.viewToAnimate.tintColor = [UIColor colorWithRed:38.0f/255.0f
                                                   green:37.0f/255.0f
                                                    blue:41.0f/255.0f
                                                   alpha:1.0f];
    self.viewToAnimate.blurRadius = 35.0f;*/
    // Load browser
    //if (self.photos){
        
      //  [self preparePhotoBrowser:self.photos];
    //}
    
    
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
            if(result.height == 1136){  //CODE IF iPHONE 5
                self.coachMarkImageView.image = [UIImage imageNamed:@"share-stream_new"];
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
    
    // Make the text on the navigation item a title view so we can touch it
    self.navItemTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, 100, 50)];
    self.navItemTitle.textColor = [UIColor whiteColor];
    self.navItemTitle.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16.0];
    self.navItemTitle.textAlignment = NSTextAlignmentCenter;
    
    self.navItemTitle.text = (self.spotName) ? self.spotName : @"Stream";
    
    self.navigationItem.titleView = self.navItemTitle;
    [self.navigationItem.titleView setUserInteractionEnabled:YES];
    [self.navigationItem.titleView setMultipleTouchEnabled:YES];

    /*UITapGestureRecognizer *oneTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(animateView:)];
    
    [tapGestureRecognizer setNumberOfTapsRequired:1];
    [tapGestureRecognizer setDelegate:self];
    
    [self.navigationItem.titleView addGestureRecognizer:tapGestureRecognizer];*/
    
    self.library = [[ALAssetsLibrary alloc] init];
    
    if(!self.photos && !self.spotName && self.numberOfPhotos == 0 && self.spotID){
        
      // We are coming from an activity screen
    [self loadSpotImages:self.spotID];
    
    }
    
    if(!self.photos && self.numberOfPhotos > 0 && self.spotID) {
        // We are coming from a place where spotName is not set so lets load spot info
       //DLog(@"Loading spot images. We are from user profile");
        [self loadSpotImages:self.spotID];
    }
    
     if(self.numberOfPhotos == 0 && self.spotName && self.spotID){
        self.noPhotosView.hidden = NO;
        self.photoCollectionView.hidden = YES;
    }

    
     if(self.spotID){
       [self loadSpotInfo:self.spotID User:[AppHelper userID]];
       //[self loadSpotImages:self.spotID];
    }
}


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    /*if(self.viewToAnimate.frame.size.height == self.view.frame.size.height){
        [self hideView];
    }*/
}


-(void)preparePhotoBrowser:(NSMutableArray *)photos
{
    /*NSMutableArray *photoURLs = [NSMutableArray array];
    for (NSDictionary *photoInfo in photos){
        NSURL *photoURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",kS3_BASE_URL,photoInfo[@"s3name"]]];
        
        [photoURLs addObject:[MWPhoto photoWithURL:photoURL]];
    }*/
    
    self.browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    
    // Set options
    self.browser.displayActionButton = YES; // Show action button to allow sharing, copying, etc (defaults to YES)
    self.browser.displayNavArrows = NO; // Whether to display left and right nav arrows on toolbar (defaults to NO)
    self.browser.displaySelectionButtons = NO; // Whether selection buttons are shown on each image (defaults to NO)
    self.browser.zoomPhotosToFill = YES; // Images that almost fill the screen will be initially zoomed to fill (defaults to YES)
    self.browser.alwaysShowControls = NO; // Allows to control whether the bars and controls are always visible or whether they fade away to show the photo full (defaults to NO)
    self.browser.enableGrid = YES; // Whether to allow the viewing of all the photo thumbnails on a grid (defaults to YES)
    self.browser.startOnGrid = NO; // Whether to start on the grid of thumbnails instead of the first photo (defaults to NO)
   
    
    // Optionally set the current visible photo before displaying
    //[browser setCurrentPhotoIndex:1];
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
                //self.navigationItem.title = self.spotName;
                self.navItemTitle.text = self.spotName;
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
        //DLog(@"Results - %@",results);
        
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
    
    /* Set the Single Tap gesture recognizer
    UITapGestureRecognizer *oneTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showFullScreenPhotoBrowser:)];
    
    [oneTapGestureRecognizer setNumberOfTapsRequired:1];
    [oneTapGestureRecognizer setDelegate:self];*/
    
    
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
    //[photoCardCell.photoCardImage addGestureRecognizer:oneTapGestureRecognizer];
    
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
    selectedPhotoIndexPath = indexPath;
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
    PhotoStreamCell *photoCardCell = (PhotoStreamCell *)[self.photoCollectionView cellForItemAtIndexPath:indexPath];
    //DLog(@"");
    NSDictionary *selectedPhotoInfo = self.photos[indexPath.item];
    
    NSDictionary *params = @{@"userId": [AppHelper userID],@"pictureId" : photoId,@"updateFlag" :@"1"};
    
    [[User currentlyActiveUser] likePhoto:params completion:^(id results, NSError *error){
        if ([results[STATUS] isEqualToString:ALRIGHT]){
            [self resamplePhotoInfo:selectedPhotoInfo flag:@"YES" numberOfLikes:results[@"likes"] atIndex:indexPath.item];
            
            // Ask main stream to reload
            [[NSNotificationCenter defaultCenter]
             postNotificationName:kUserReloadStreamNotification object:nil];
            
            DLog(@"Likes  - %i",[results[@"likes"] integerValue]);
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

    PhotoStreamCell *photoCardCell = (PhotoStreamCell *)[self.photoCollectionView cellForItemAtIndexPath:indexPath];
    
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
    
    //DLog(@"Photo Cell - %@ - %@",[likeButton.superview.superview class],[likeButton.superview class]);
    
    PhotoStreamCell *cell = (PhotoStreamCell *)likeButton.superview.superview;
    
    NSIndexPath *indexPath = [self.photoCollectionView indexPathForCell:cell];
    
    NSString *picId = self.photos[indexPath.item][@"id"];
    
    if (likeButton.state == UIControlStateNormal || likeButton.state == UIControlStateHighlighted)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10000), dispatch_get_main_queue(),^{
            
            [cell.likePhotoButton setSelected:YES];
        });
        [self likePhotoWithID:picId atIndexPath:indexPath];
        
    }else{
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10000), dispatch_get_main_queue(),^{
            
            [cell.likePhotoButton setSelected:NO];
        });
        
        [self unlikePhotoWithID:picId atIndexPath:indexPath];
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
    selectedPhoto = cell.photoCardImage.image;
    
    
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


/*-(void)saveLikeButtonInitialBounds:(UIButton *)button
{
    self.likeButtonBounds = button.bounds;
    DLog(@"Bouncing -%@",NSStringFromCGRect(button.bounds));
    
    // Force the button image to scale with its bounds.
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
    
    button.contentVerticalAlignment = UIControlContentHorizontalAlignmentFill;

}*/

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
        shareText = [NSString stringWithFormat:@"Check out all the photos in my shared stream %@ with Suba for iOS @ http://www.subaapp.com/albums?%@",self.navItemTitle.text,[NSString stringWithFormat:@"%@%@",self.spotID,randomString]];
        
        
        activityItems = @[self.albumSharePhoto,shareText];
        [Flurry logEvent:@"Share_Stream_Tapped"];
        
    }else if (objectOfInterest == kPhoto){
        
        //DLog(@"Photo Cell - %@",sender.superview.superview.superview);
        PhotoStreamCell *cell = (PhotoStreamCell *)sender.superview.superview.superview;
        NSString *randomString = [self getRandomPINString:5];
        shareText = [NSString stringWithFormat:@"Check out all the photos in my shared stream %@ with Suba for iOS @ http://www.subaapp.com/albums?%@",self.navItemTitle.text,[NSString stringWithFormat:@"%@%@",self.spotID,randomString]];
        
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
        
        //640.0f X 852.0f
        [self resizePhoto:fullResolutionImage towidth:1136.0f toHeight:640.0f completon:^(UIImage *compressedPhoto, NSError *error) {
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
    //DLog(@"Cell info -  %@\nUserId -%@",cellInfo,picTakerId);
}

-(NSMutableArray *)prepareComments:(NSArray *)commentsInfo
{
    
    for (NSDictionary *comment in commentsInfo){
        //DLog(@"This is the comment we are decoding - %@",[comment description]);
        NSString *commentText = comment[@"commentText"];
        NSString *authorName = comment[@"authorName"];
        NSString *authorImage = comment[@"authorImage"];
        NSString *timestamp = comment[@"timestamp"];
        
        UIImage *imageOwner = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@", kS3_BASE_URL,authorImage]]]];
        
        NSDate *dateTime = [NSDate dateWithTimeIntervalSince1970:([timestamp doubleValue])/1000];
        NSDictionary *commentInfo = @{@"commentText": commentText,@"commentDate":timestamp,
                                      @"authorName":authorName,@"authorImage":[UIImage imageNamed:@"anonymousUser"]};
        
        DLog(@"Date time - %@",[NSDate dateWithTimeInterval:-252750 sinceDate:dateTime]);
        
        [comments addObject:[Comment commentWithProperties:commentInfo]];
    }
    return comments;
}

#pragma mark - UIActionSheet Delegate Methods
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == 5000){
        
        if(buttonIndex == 0){
            //User wants to save photo
            [self savePhoto:selectedPhoto];
        }else if (buttonIndex == 1){
            DLog(@"User wants to delete photo");
            NSInteger index = [self.photos indexOfObject:self.photoInView];
            [self deletePhotoAtIndexFromStream:index];
        }
        
    }else if (actionSheet.tag == 1000){
        if(buttonIndex == 0){
            //User wants to save photo
            [self savePhoto:selectedPhoto];
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
    
    //DLog(@"Image resolution - %@",NSStringFromCGSize(image.size));
    
    // 640 X 852
    
    [self resizePhoto:image towidth:1136.0f toHeight:640.0f
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
    self.navItemTitle.text = albumVC.spotName;
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"SpotSettingsSegue"]) {
        if ([segue.destinationViewController isKindOfClass:[AlbumSettingsViewController class]]) {
            AlbumSettingsViewController *albumVC = segue.destinationViewController;
            albumVC.spotID = (NSString *)sender;
            albumVC.spotInfo = self.spotInfo;
            albumVC.whereToUnwind = [self.parentViewController childViewControllers][0];
            //DLog(@"WhereToUnwind - %@",[albumVC.whereToUnwind class]);
        }
    }else if ([segue.identifier isEqualToString:@"AlbumMembersSegue"]){
        if ([segue.destinationViewController isKindOfClass:[AlbumMembersViewController class]]){
            AlbumMembersViewController *membersVC = segue.destinationViewController;
            membersVC.spotID = sender;
            //membersVC.spotInfo = self.spotInfo;
        }
    }else if ([segue.identifier isEqualToString:@"PHOTOSTREAM_USERPROFILE"]){
        UserProfileViewController *uVC = segue.destinationViewController;
        DLog(@"Sender UserId - %@",sender);
        uVC.userId = sender;
    }
}



#pragma mark - handle gesture recognizer
- (void)photoCardTapped:(UITapGestureRecognizer *)sender
{
    
    if (sender.state == UIGestureRecognizerStateEnded)
    {
        NSString *photoId = self.photos[selectedPhotoIndexPath.item][@"id"];
        
        if ([self.photos[selectedPhotoIndexPath.item][@"userLikedPhoto"] isEqualToString:@"NO"]){
            
            [self likePhotoWithID:photoId atIndexPath:selectedPhotoIndexPath];
            
        }else{
                [self unlikePhotoWithID:photoId atIndexPath:selectedPhotoIndexPath];
        }
        
    }
}

- (void)showFullScreenPhotoBrowser:(UITapGestureRecognizer *)sender{
    
    if (sender.state == UIGestureRecognizerStateEnded)
    {
        /*toggler++;
         //NSLog(@"The togger is %i",toggler);
        if (toggler % 2 == 1) {
            [self showView];
        }else{
            [self hideView];
        }*/
        
        //[self preparePhotoBrowser:nil];
        
        // Present
        [self.navigationController pushViewController:self.browser animated:YES];

    }
}


- (void)showView{
   /*
    CGRect viewFrame = self.viewToAnimate.frame;
    CGFloat newHeight = self.view.frame.size.height;
    viewFrame.size.height += newHeight;
    
    [UIView animateWithDuration:.3 animations:^{
        self.viewToAnimate.frame = viewFrame;
        
    } completion:^(BOOL finished) {
        [self.viewToAnimate updateAsynchronously:YES completion:NULL];
    }];*/
}

- (void)hideView{
    
    /*CGRect viewFrame = self.viewToAnimate.frame;
    CGFloat newHeight = self.view.frame.size.height;
    viewFrame.size.height -= newHeight;
    
    [UIView animateWithDuration:.3 animations:^{
        self.viewToAnimate.frame = viewFrame;
    } completion:^(BOOL finished) {
       [self.viewToAnimate setNeedsDisplay];
    }];*/
}



- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    // Has the user scrolled more than half of the photo currently in view
    // Get the  x content offset (Since we're doing horizontal scrolling)
    // The scale factor tells us the index of the image being viewed
    
    //CGFloat xpos = self.photoCollectionView.contentOffset.x;
    //CGFloat ypos = scrollView.frame.origin.y;
    int multiFactor = (int)floorf(self.photoCollectionView.contentOffset.x/300.0);
    
    int page = 300.0f;
    [scrollView setContentOffset:CGPointMake(multiFactor*page,0) animated:NO];
    
    //DLog(@"Y-POS - %f",scrollView.frame.origin.y);
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    //CGFloat xpos = self.photoCollectionView.contentOffset.x;
    //CGFloat ypos = self.photoCollectionView.frame.origin.y;
    //int multiFactor = (int)floorf(self.photoCollectionView.contentOffset.x/300.0);
    
    [self scrollToCorrect:scrollView];
}


-(void)scrollToCorrect:(UIScrollView*)scrollView
{
    CGFloat xpos = self.photoCollectionView.contentOffset.x;
    int multiFactor = (int) floorf(self.photoCollectionView.contentOffset.x/300.0);
    int quotient = (int)(xpos/300.0);
    
    int step = 300 * quotient;
    
    int lag = xpos - step;
    
    if (lag <= 150) {
        // Move to the next image
        multiFactor = quotient;
        
    }else multiFactor = quotient + 1;
    
    
    
    int page = 300.0f;
    //CGFloat ypos = scrollView.frame.origin.y;
    //DLog(@"Y-POS - %f\nContent View y- %@",scrollView.frame.origin.y,NSStringFromUIEdgeInsets(scrollView.contentInset));
    
    [scrollView setContentOffset:CGPointMake(multiFactor*page,0) animated:YES];
}




#pragma mark - PhotoBrowser Delegate
/*-(void)photoBrowser:(IDMPhotoBrowser *)photoBrowser didDismissAtPageIndex:(NSUInteger)index
{
    [photoBrowser dismissViewControllerAnimated:YES completion:nil];
}*/




#pragma mark - State Preservation and Restoration
-(void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeObject:self.spotInfo forKey:SpotInfoKey];
    [coder encodeObject:self.spotName forKey:SpotNameKey];
    [coder encodeObject:self.spotID forKey:SpotIdKey];
    [coder encodeObject:self.photos forKey:SpotPhotosKey];
    //[coder encodeObject:@(selectedButton) forKey:SelectedButtonKey];
    
    //DLog(@"self.spotInfo -%@\nself.spotName -%@\nself.spotID - %@\nself.photos -%@",self.spotInfo,self.spotName,self.spotID,self.photos);
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
    
    if (self.spotName){
        self.navItemTitle.text = self.spotName;
    }
    
    //2. If spotInfo is nil,loadspotInfo
    if (self.spotID && !self.spotInfo) {
        [self loadSpotInfo:self.spotID User:[AppHelper userID]];
    }
    
  
}


#pragma mark - MWPhotoBrowser Delegate
-(NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser
{
    //DLog(@"Number of photos - %i",[self.photos count]);
    return [self.photos count];
}


-(id<MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index
{
    //DLog(@"Index of photo is - %i",index);
    
    if (index < [self.photos count]){
        NSString *photoURLstring = self.photos[index][@"s3name"];
        NSURL *photoSrc = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",kS3_BASE_URL,photoURLstring]];
        //DLog(@"PhotoSRC - %@",photoSrc);
        MWPhoto *photo = [MWPhoto photoWithURL:photoSrc];
        
        return photo;
    }
    
    return nil;
}



- (IBAction)commentOnPhoto:(UIButton *)sender
{
    
    //[self performSegueWithIdentifier:@"CommentsSegue" sender:nil];
    
    // Set Up EBPagesVC
    ebPhotoPagesController = [[EBPhotoPagesController alloc]
                            initWithDataSource:self
                            delegate:self];
    
    PhotoStreamCell *cell = (PhotoStreamCell *)sender.superview.superview.superview;
    
    NSIndexPath *indexPath = [self.photoCollectionView indexPathForCell:cell];
    if (cell.photoCardImage.image == nil) {
        [AppHelper showAlert:@"No Image" message:@"Image not loaded" buttons:@[@"OK"] delegate:nil];
    }else{
        
        selectedPhoto = cell.photoCardImage.image;
        selectedPhotoIndexPath = indexPath;
        
      [self presentViewController:ebPhotoPagesController animated:YES completion:^{
         // [ebPhotoPagesController enterCommentsMode];
          [ebPhotoPagesController startCommenting];
      }];
    }
}




#pragma mark - EBPhotoPages Datasource
- (BOOL)photoPagesController:(EBPhotoPagesController *)photoPagesController
    shouldExpectPhotoAtIndex:(NSInteger)index
{
    //if(index < 1){
        return YES;
   // }
    
    //return NO;
}


- (BOOL)photoPagesController:(EBPhotoPagesController *)photoPagesController
shouldHandleLongPressGesture:(UILongPressGestureRecognizer *)recognizer
             forPhotoAtIndex:(NSInteger)index{
    
    return NO;
}

- (void)photoPagesController:(EBPhotoPagesController *)controller
                imageAtIndex:(NSInteger)index
           completionHandler:(void (^)(UIImage *))handler
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        
        handler(selectedPhoto);
    });
}



- (BOOL)photoPagesController:(EBPhotoPagesController *)photoPagesController shouldAllowCommentingForPhotoAtIndex:(NSInteger)index
{
    return YES;
}


- (void)photoPagesController:(EBPhotoPagesController *)controller
numberOfcommentsForPhotoAtIndex:(NSInteger)index
           completionHandler:(void (^)(NSInteger))handler
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        DLog(@"Number of comments - %i",[comments count]); 
        handler([comments count]);
    });
}


- (void)photoPagesController:(EBPhotoPagesController *)controller
     commentsForPhotoAtIndex:(NSInteger)index
           completionHandler:(void (^)(NSArray *))handler
{
    
    NSString *selectedPhotoId = self.photos[selectedPhotoIndexPath.row][@"id"];
    [Photo showCommentsForPhotoWithID:selectedPhotoId completion:^(id results, NSError *error) {
        if (!error){
            
            if ([results[STATUS] isEqualToString:ALRIGHT]) {
                comments = [self prepareComments:results[@"photoComments"]];
                
                DLog(@"Comments - %@\nPhoto comments - %@",[comments description],results[@"photoComments"]);
                handler(comments);
            }
        }
    }];
    
}


- (BOOL)photoPagesController:(EBPhotoPagesController *)photoPagesController shouldAllowActivitiesForPhotoAtIndex:(NSInteger)index
{
    return NO;
}


- (BOOL)photoPagesController:(EBPhotoPagesController *)photoPagesController shouldAllowMiscActionsForPhotoAtIndex:(NSInteger)index
{
    return NO;
}


#pragma mark - EBPPhotoPagesDelegate
- (void)photoPagesControllerDidDismiss:(EBPhotoPagesController *)photoPagesController
{
    selectedPhoto = nil;
    ebPhotoPagesController = nil;
}


- (void)photoPagesController:(EBPhotoPagesController *)controller didPostComment:(NSString *)commentText forPhotoAtIndex:(NSInteger)index
{
    NSDictionary *photoInfo = self.photos[selectedPhotoIndexPath.row];
    //DLog(@"Selected photo info - %@\nComment - %@",photoInfo,commentText);
    NSString *userId = [User currentlyActiveUser].userID;
    NSDictionary *params = @{@"actualComment": commentText,@"photoId" : photoInfo[@"id"],@"userId" : userId};
    
    [User commentOnPhoto:params completion:^(id results, NSError *error) {
        if (!error) {
            if ([results[STATUS] isEqualToString:ALRIGHT]){
                
                [comments addObject:results[@"comment"]];
                DLog(@"Setting comments");
                [controller setComments:comments forPhotoAtIndex:index];
                
            }else{
                DLog(@"error - %@",results);
            }
        }else{
            DLog(@"Error - %@",error);

        }
    }];
}





@end
