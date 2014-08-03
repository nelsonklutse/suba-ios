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
#import "StreamSettingsViewController.h"
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
#import "EmailInvitesViewController.h"
#import "BOSImageResizeOperation.h"
#import <QuartzCore/QuartzCore.h>
#import "PhotoStreamFooterView.h"
#import "InvitesViewController.h"
#import "SBDoodleViewController.h"
#import <IonIcons.h>
#import <ionicons-codes.h>
#import "DBCameraViewController.h"
#import "DBCameraContainerViewController.h"
#import "TermsViewController.h"
#import <Social/Social.h>
#import <DACircularProgressView.h>
#import <IDMPhotoBrowser.h>

typedef void (^PhotoResizedCompletion) (UIImage *compressedPhoto,NSError *error);
typedef void (^StandardPhotoCompletion) (CGImageRef standardPhoto,NSError *error);

#define SpotInfoKey @"SpotInfoKey"
#define SpotNameKey @"SpotNameKey"
#define SpotIdKey @"SpotIdKey"
#define SpotPhotosKey @"SpotPhotosKey"

@interface PhotoStreamViewController ()<UICollectionViewDataSource,UICollectionViewDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate,UIActionSheetDelegate,CTAssetsPickerControllerDelegate,UIGestureRecognizerDelegate,MFMessageComposeViewControllerDelegate,UITextFieldDelegate,DBCameraViewControllerDelegate,UIAlertViewDelegate,MFMailComposeViewControllerDelegate>

{
    UIImage *selectedPhoto;
    NSIndexPath *selectedPhotoIndexPath;
    
}


@property (strong,nonatomic) NSDictionary *photoInView;
@property (strong,nonatomic) NSDictionary *spotInfo;
@property (strong,atomic) ALAssetsLibrary *library;
@property (strong,nonatomic) UIImage *albumSharePhoto;
@property (weak, nonatomic) IBOutlet UIView *createAccountOptionsView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *facebookLoginIndicator;
@property (weak, nonatomic) IBOutlet UILabel *noActionLabel;
@property (copy,nonatomic) NSString *firstName;
@property (copy,nonatomic) NSString *lastName;
@property (copy,nonatomic) NSString *userName;
@property (copy,nonatomic) NSString *userEmail;
@property (copy,nonatomic) NSString *userPassword;
@property (copy,nonatomic) NSString *userPasswordConfirm;
@property (weak, nonatomic) IBOutlet UIView *uploadingPhoto;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *uploadingPhotoIndicator;
@property (weak, nonatomic) IBOutlet UIButton *addFirstPhotoCameraButton;

@property (retain, nonatomic) IBOutlet UIButton *requestForPhotosButton;
@property (retain, nonatomic) IBOutlet UIButton *shareStreamButton;
@property (retain, nonatomic) IBOutlet UIButton *streamSettingsButton;

@property (weak, nonatomic) IBOutlet UITextField *firstNameField;
@property (weak, nonatomic) IBOutlet UITextField *lastNameField;
@property (weak, nonatomic) IBOutlet UITextField *usernameField;
@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UITextField *reTypePasswordField;

@property (retain, nonatomic) IBOutlet UIView *hiddenTopMenuView;
@property (weak, nonatomic) IBOutlet UIScrollView *signUpWithEmailView;
@property (weak, nonatomic) IBOutlet UIScrollView *finalSignUpWithEmailView;

@property (weak, nonatomic) IBOutlet UIScrollView *createAccountView;
@property (weak, nonatomic) IBOutlet UIImageView *coachMarkImageView;
@property (weak, nonatomic) IBOutlet UIProgressView *imageUploadProgressView;
@property (weak, nonatomic) IBOutlet UICollectionView *photoCollectionView;
@property (weak, nonatomic) IBOutlet UIButton *gotItButton;

@property (weak, nonatomic) IBOutlet UIView *loadingInfoIndicatorView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingStreamInfoIndicator;
@property (weak, nonatomic) IBOutlet UIButton *cameraButton;
@property (weak, nonatomic) IBOutlet UIImageView *likeImage;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *signUpSpinner;

@property (weak, nonatomic) IBOutlet UIView *firstTimeNotificationScreen;
@property (weak, nonatomic) IBOutlet UIView *noPhotosView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *iconCameraButton;
@property (strong,nonatomic) UILabel *navItemTitle;

- (IBAction)unWindToPhotoStream:(UIStoryboardSegue *)segue;
- (IBAction)unWindToPhotoStreamWithWithInfo:(UIStoryboardSegue *)segue;

- (IBAction)addFirstPhotoButtonTapped:(UIButton *)sender;
- (IBAction)remixPhotoDone:(UIStoryboardSegue *)segue;
- (IBAction)showTermsOfService:(UIButton *)sender;
- (IBAction)showPrivacyPolicy:(UIButton *)sender;
- (IBAction)dismissNotificationScreen:(id)sender;
- (IBAction)registerForPushNotification:(id)sender;
- (IBAction)remixPhoto:(UIButton *)sender;
- (IBAction)sharePhoto:(UIButton *)sender;
- (IBAction)likePhoto:(id)sender;
- (IBAction)cameraButtonTapped:(id)sender;
- (IBAction)showMoreActions:(UIButton *)sender;
- (IBAction)signUpWithEmailOptionChosen:(id)sender;
- (IBAction)dismissCreateSubaAccountScreen:(id)sender;
- (IBAction)moveToProfile:(UIButton *)sender;
- (IBAction)doFacebookLogin:(id)sender;

- (IBAction)showMembers:(id)sender;
- (IBAction)dismissCoachMark:(UIButton *)sender;

//- (void)scrollToCorrect:(UIScrollView*)scrollView;
- (void)sendSMSToRecipients:(NSMutableArray *)recipients;
- (NSString *)getRandomPINString:(NSInteger)length;
- (void)preparePhotoBrowser:(NSMutableArray *)photos;
- (void)createStandardImage:(CGImageRef)image completon:(StandardPhotoCompletion)completion;
- (void)resizePhoto:(UIImage*) image
            towidth:(float) width
           toHeight:(float) height
          completon:(PhotoResizedCompletion)completion;
- (void)deletePhotoAtIndexFromStream:(NSInteger)index;
- (void)uploadPhotos:(NSArray *)images;
- (void)upDateCollectionViewWithCapturedPhotos:(NSArray *)photoInfo;
- (void)showHiddenMenu:(UITapGestureRecognizer *)sender;
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
- (void)loadSpotInfo:(NSString *)spotId;
- (void)loadSpotImages:(NSString *)spotId;
- (void)pickImage:(id)sender;
- (void)likePhotoWithID:(NSString *)photoId atIndexPath:(NSIndexPath *)indexPath;
- (void)unlikePhotoWithID:(NSString *)photoId atIndexPath:(NSIndexPath *)indexPath;
- (void)resamplePhotoInfo:(NSDictionary *)info
                     flag:(NSString *)flag
            numberOfLikes:(NSString *)likes
                  atIndex:(NSInteger)selectedIndex;
- (void)setUpTitleView;
- (void)checkAllTextFields;
- (void)dismissCreateAccountPopUp;
- (void)showGivePushNotificationScreen;
-(void)uploadingPhotoView:(BOOL)flag;
@end

@implementation PhotoStreamViewController
int toggler;

- (IBAction)remixPhotoDone:(UIStoryboardSegue *)segue
{
    SBDoodleViewController *ddVC = segue.sourceViewController;
    
    
    PhotoStreamCell *cell = (PhotoStreamCell *)[self.photoCollectionView
                                                cellForItemAtIndexPath:[NSIndexPath indexPathForItem:selectedPhotoIndexPath.item inSection:0]];
    
    cell.remixedImageView.alpha = 1;
    cell.remixedImageView.image = ddVC.savedPhoto;
    NSData *data = UIImageJPEGRepresentation(ddVC.savedPhoto, 1.0);
    
    [self uploadDoodle:data WithName:self.photos[selectedPhotoIndexPath.item][@"s3name"]];
}

- (IBAction)showTermsOfService:(UIButton *)sender
{
    TermsViewController *termsVC = [self.storyboard instantiateViewControllerWithIdentifier:@"TERMS_SCENE"];
    termsVC.urlToLoad = [NSURL URLWithString:@"http://www.subaapp.com/terms.html"];
    [self.navigationController pushViewController:termsVC animated:YES];
}

- (IBAction)showPrivacyPolicy:(UIButton *)sender
{
    TermsViewController *termsVC = [self.storyboard instantiateViewControllerWithIdentifier:@"TERMS_SCENE"];
    termsVC.urlToLoad = [NSURL URLWithString:@"http://www.subaapp.com/privacy.html"];
    [self.navigationController pushViewController:termsVC animated:YES];
}


- (void)setUpTitleView
{
    // Set up the hidden Menu
    self.requestForPhotosButton.layer.borderWidth = .5;
    self.requestForPhotosButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
    
    self.shareStreamButton.layer.borderWidth = .5;
    self.shareStreamButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
    
    self.streamSettingsButton.layer.borderWidth = .5;
    self.streamSettingsButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
    
    //Construct container view for labels to sit inside
    CGRect headerTitleSubtitleFrame = CGRectMake(0, 10, 200, 44);
    UIView* _headerTitleSubtitleView = [[UILabel alloc] initWithFrame:headerTitleSubtitleFrame];
    _headerTitleSubtitleView.backgroundColor = [UIColor clearColor];
    _headerTitleSubtitleView.autoresizesSubviews = NO;
    
    CGRect titleFrame = CGRectMake(10, 5, 160, 24);
    UILabel *titleView = [[UILabel alloc] initWithFrame:titleFrame];
    titleView.backgroundColor = [UIColor clearColor];
    titleView.textAlignment = NSTextAlignmentCenter;
    titleView.textColor = [UIColor whiteColor];
    titleView.shadowColor = [UIColor clearColor];
    titleView.text = (self.spotName) ? self.spotName : @"Stream";
    //[titleView sizeToFit];
    titleView.adjustsFontSizeToFitWidth = YES;
    
    [_headerTitleSubtitleView addSubview:titleView];
    
    CGRect subtitleFrame = CGRectMake((160/2), 25, 160, 44-25);
    UILabel *subtitleView = [[UILabel alloc] initWithFrame:subtitleFrame];
    [IonIcons label:subtitleView setIcon:icon_arrow_down_b size:20.0f color:[UIColor darkGrayColor] sizeToFit:YES];
    subtitleView.backgroundColor = [UIColor clearColor];
    subtitleView.textAlignment = NSTextAlignmentCenter;
    //subtitleView.textColor = [UIColor whiteColor];
    //subtitleView.shadowColor = [UIColor clearColor];
    subtitleView.adjustsFontSizeToFitWidth = YES;
    //[subtitleView sizeToFit];
    [_headerTitleSubtitleView addSubview:subtitleView];
    
    self.navigationItem.titleView = _headerTitleSubtitleView;
    
    [self.navigationItem.titleView setUserInteractionEnabled:YES];
    [self.navigationItem.titleView setMultipleTouchEnabled:YES];
    
    UITapGestureRecognizer *oneTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showHiddenMenu:)];
    
    [oneTapGestureRecognizer setNumberOfTapsRequired:1];
    [oneTapGestureRecognizer setDelegate:self];
    
    [self.navigationItem.titleView addGestureRecognizer:oneTapGestureRecognizer];
    
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIImage *image = [IonIcons imageWithIcon:icon_ios7_camera_outline
                                   iconColor:[UIColor darkGrayColor] iconSize:250.0f
                                   imageSize:CGSizeMake(220.0f, 250.0f)];
    
    [self.addFirstPhotoCameraButton setBackgroundImage:image forState:UIControlStateNormal];
    
    UIImage *iconCamera = [IonIcons imageWithIcon:icon_ios7_camera_outline size:44 color:[UIColor whiteColor]];
    [self.iconCameraButton setImage:iconCamera];
    
    CGRect hiddenMenuFrame = CGRectMake(0, 0, 320, 0);
    self.hiddenTopMenuView.alpha = 0;
    self.hiddenTopMenuView.frame = hiddenMenuFrame;
    self.createAccountView.alpha = 0;
    self.firstTimeNotificationScreen.alpha = 0;
    
    self.navigationController.navigationBar.topItem.title = @"";
    
    if ([[AppHelper shareStreamCoachMarkSeen] isEqualToString:@"NO"]){
      if([[AppHelper kindOfDeviceScreen] isEqualToString:kIPHONE_4_SCREEN]){
            self.coachMarkImageView.image = [UIImage imageNamed:@"share-stream_iphone4"];
            CGRect btnFrame = CGRectMake(self.gotItButton.frame.origin.x, self.gotItButton.frame.origin.y-100, self.gotItButton.frame.size.width, self.gotItButton.frame.size.height);
                
                self.gotItButton.frame = btnFrame;
            }
        
    if([[AppHelper kindOfDeviceScreen] isEqualToString:kIPHONE_5_SCREEN]){  //CODE IF iPHONE 5
         self.coachMarkImageView.image = [UIImage imageNamed:@"share-stream_new"];
            
        }

        self.coachMarkImageView.alpha = 1;
        [self.view viewWithTag:10000].alpha = 1;
        [AppHelper setShareStreamCoachMark:@"YES"];
    }
    
    // Disable the camera button till we have all our info ready
    self.cameraButton.enabled = NO;
    
	// Do any additional setup after loading the view.
    self.noPhotosView.hidden = YES;
    
    [self setUpTitleView];
    
    self.library = [[ALAssetsLibrary alloc] init];
    
    if(!self.photos && !self.spotName && self.numberOfPhotos == 0 && self.spotID){
        
      // We are coming from an activity screen
    [self loadSpotImages:self.spotID];
    
    }
    
    if(!self.photos && self.numberOfPhotos > 0 && self.spotID) {
        // We are coming from a place where spotName is not set so lets load spot info
        if ([[AppHelper userStatus] isEqualToString:kSUBA_USER_STATUS_ANONYMOUS]) {
            DLog(@"User status - %@",[AppHelper userStatus]);
            [UIView animateWithDuration:.5 animations:^{
                //self.navigationController.navigationBarHidden = YES;
                self.firstTimeNotificationScreen.alpha = 1;
            }];
            
        }
        [self loadSpotImages:self.spotID];
    }
    
     if(self.numberOfPhotos == 0 && self.spotName && self.spotID){
        self.noPhotosView.hidden = NO;
        self.photoCollectionView.hidden = YES;
    }

    
     if(self.spotID){
        
       [self loadSpotInfo:self.spotID];
       //[self loadSpotImages:self.spotID];
    }
}


-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.createAccountView.alpha = 0;
}


-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.navigationController.navigationBar.topItem.title = @"";
    [AppHelper increasePhotoStreamEntries];
}


-(void)preparePhotoBrowser:(NSMutableArray *)photos
{
    /*NSMutableArray *photoURLs = [NSMutableArray array];
    for (NSDictionary *photoInfo in photos){
        NSURL *photoURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",kS3_BASE_URL,photoInfo[@"s3name"]]];
        
        [photoURLs addObject:[MWPhoto photoWithURL:photoURL]];
    }
    
    self.browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    
    // Set options
    self.browser.displayActionButton = YES; // Show action button to allow sharing, copying, etc (defaults to YES)
    self.browser.displayNavArrows = NO; // Whether to display left and right nav arrows on toolbar (defaults to NO)
    self.browser.displaySelectionButtons = NO; // Whether selection buttons are shown on each image (defaults to NO)
    self.browser.zoomPhotosToFill = YES; // Images that almost fill the screen will be initially zoomed to fill (defaults to YES)
    self.browser.alwaysShowControls = NO; // Allows to control whether the bars and controls are always visible or whether they fade away to show the photo full (defaults to NO)
    self.browser.enableGrid = YES; // Whether to allow the viewing of all the photo thumbnails on a grid (defaults to YES)
    self.browser.startOnGrid = NO; // Whether to start on the grid of thumbnails instead of the first photo (defaults to NO)
   */
    
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
           //DLog(@"Photos - %@",results);
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


-(void)loadSpotInfo:(NSString *)spotId
{
 // Show activity indicator
    [AppHelper showLoadingDataView:self.loadingInfoIndicatorView
                         indicator:self.loadingStreamInfoIndicator flag:YES];
    
    [Spot fetchSpotInfo:spotId completion:^(id results, NSError *error) {
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
                /*[IonIcons label:self.navItemTitle setIcon:icon_arrow_down_b
                           size:10.0f color:[UIColor whiteColor] sizeToFit:NO];
                
                [self.navItemTitle sizeToFit];*/
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
    //DLog(@"Photos - %lu",(unsigned long)[self.photos count]);
    return [self.photos count];
}


-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    //DLog(@"Doing this again");
    // Set the Double Tap Gesture Recognizer
    UITapGestureRecognizer *oneTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(photoCardTapped:)];
    
    [oneTapRecognizer setNumberOfTapsRequired:1];
    [oneTapRecognizer setDelegate:self];
    
    static NSString *cellIdentifier = @"PhotoStreamCell";
    
    PhotoStreamCell *photoCardCell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    if ([[AppHelper kindOfDeviceScreen] isEqualToString:kIPHONE_4_SCREEN]){
        CGRect footerFrame  = CGRectMake(0, 367, 285, 67);
        photoCardCell.photoCardFooterView.frame = footerFrame;
    }else if([[AppHelper kindOfDeviceScreen] isEqualToString:kIPHONE_5_SCREEN]){
        CGRect footerFrame  = CGRectMake(0, 410, 285, 67);
        photoCardCell.photoCardFooterView.frame = footerFrame;
    }
    
    
    NSString *pictureTakerName = self.photos[indexPath.row][@"pictureTaker"];
    
    // Give border around header View
    [photoCardCell setBorderAroundView:photoCardCell.headerView];
    [photoCardCell setBorderAroundView:photoCardCell.footerView];
    
    photoCardCell.pictureTakerView.layer.borderWidth = 1;
    photoCardCell.pictureTakerView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    photoCardCell.pictureTakerView.layer.cornerRadius = 12.5;
    photoCardCell.pictureTakerView.clipsToBounds = YES;
    
    //photoCardCell.remixedImageView.alpha = 0;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10000), dispatch_get_main_queue(),^{
        NSString *photoLiked = self.photos[indexPath.item][@"userLikedPhoto"];
        if ([photoLiked isEqualToString:@"YES"]) {
            [photoCardCell.likePhotoButton setSelected:YES];
        }else{
           [photoCardCell.likePhotoButton setSelected:NO];
        }
    });
    
      /*[AppHelper showLoadingDataView:photoCardCell.loadingPictureView
                         indicator:photoCardCell.loadingPictureIndicator
                              flag:YES];*/
    
    [photoCardCell makeInitialPlaceholderView:photoCardCell.pictureTakerView name:pictureTakerName];
    
    NSString *photoURLstring = self.photos[indexPath.item][@"s3name"];
    NSString *photoRemixURLString = self.photos[indexPath.item][@"s3RemixName"];
    
    //DLog(@"Photos - %@",self.photos[indexPath.item]);
    if(self.photos[indexPath.row][@"pictureTakerPhoto"]){
        NSString *pictureTakerPhotoURL = self.photos[indexPath.row][@"pictureTakerPhoto"];
        [photoCardCell fillView:photoCardCell.pictureTakerView WithImage:pictureTakerPhotoURL];
    }
    
    photoCardCell.pictureTakerName.text = pictureTakerName;
    if ([self.photos[indexPath.row][@"likes"] integerValue] == 1) {
       photoCardCell.numberOfLikesLabel.text = [NSString stringWithFormat:@"%@ Like",self.photos[indexPath.item][@"likes"]];
    }else if ([self.photos[indexPath.row][@"likes"] integerValue] > 1){
      photoCardCell.numberOfLikesLabel.text = [NSString stringWithFormat:@"%@ Likes",self.photos[indexPath.item][@"likes"]];
    }else{
        photoCardCell.numberOfLikesLabel.text = kEMPTY_STRING_WITHOUT_SPACE;
    }
    
    
    // Add the gesture recognizer to this cell
    [photoCardCell.photoCardImage setUserInteractionEnabled:YES];
    [photoCardCell.photoCardImage setMultipleTouchEnabled:YES];
    [photoCardCell.photoCardImage addGestureRecognizer:oneTapRecognizer];
    
    [photoCardCell.remixedImageView setUserInteractionEnabled:YES];
    [photoCardCell.remixedImageView setMultipleTouchEnabled:YES];
    [photoCardCell.remixedImageView addGestureRecognizer:oneTapRecognizer];
    
    // Download photo card image
    [self downloadPhoto:photoCardCell.photoCardImage withURL:photoURLstring downloadOption:SDWebImageProgressiveDownload];
    
    //[S3PhotoFetcher s3FetcherWithBaseURL] download
    
    /*[[S3PhotoFetcher s3FetcherWithBaseURL] downloadPhoto:photoURLstring to:photoCardCell.photoCardImage placeholderImage:[UIImage imageNamed:@"newOverlay"] completion:^(id results, NSError *error) {
        
        if (!error) {
            self.albumSharePhoto = (UIImage *)results;
        }
        
        [AppHelper showLoadingDataView:photoCardCell.loadingPictureView
                             indicator:photoCardCell.loadingPictureIndicator
                                  flag:NO];
    }];*/
    
    if (photoRemixURLString){
        
        //DLog(@"Remix URL - %@",photoRemixURLString);
        //NSURL *photoRemixURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",kS3_BASE_URL,photoRemixURLString]];
        [self downloadPhoto:photoCardCell.remixedImageView withURL:photoRemixURLString downloadOption:SDWebImageRefreshCached];
        
        /*[photoCardCell.remixedImageView sd_setImageWithURL:photoRemixURL placeholderImage:nil options:SDWebImageRefreshCached];
        
        [[S3PhotoFetcher s3FetcherWithBaseURL] downloadPhoto:photoRemixURLString to:photoCardCell.remixedImageView placeholderImage:[UIImage imageNamed:@"newOverlay"] completion:^(id results, NSError *error) {
            
            [AppHelper showLoadingDataView:photoCardCell.loadingPictureView
                                 indicator:photoCardCell.loadingPictureIndicator
                                      flag:NO];
        }];*/
    }else{
        photoCardCell.remixedImageView.image = nil;
    }
    
    if ([self.photos[indexPath.item][@"remixers"] integerValue] <= 0){
        //DLog(@"There are no remixers for this photo");
        photoCardCell.remixedImageView.alpha = 0;
        photoCardCell.photoCardImage.alpha = 1;
        photoCardCell.toggleDoodleButton.enabled = NO;
        photoCardCell.toggleDoodleButton.hidden = YES;
        photoCardCell.seeDoodleBtn.hidden = YES;
        photoCardCell.numberOfRemixersLabel.hidden = YES;
    }else{
        //DLog(@"There are remixers for this photo");
        NSInteger remixers = [self.photos[indexPath.item][@"remixers"] integerValue];
        
        photoCardCell.toggleDoodleButton.enabled = YES;
        photoCardCell.toggleDoodleButton.hidden = NO;
        photoCardCell.seeDoodleBtn.hidden = NO;
        photoCardCell.remixedImageView.alpha = 1;
        photoCardCell.numberOfRemixersLabel.hidden = NO;
        if (remixers == 1){
            photoCardCell.numberOfRemixersLabel.text = [NSString stringWithFormat:@"%li Doodler",(long)remixers];
        }else{
            photoCardCell.numberOfRemixersLabel.text = [NSString stringWithFormat:@"%li Doodlers",(long)remixers];
        }
    }
    
    if (photoCardCell.photoCardImage.image != nil) {
        selectedPhoto = photoCardCell.photoCardImage.image;
    }
    
    return photoCardCell;
}


- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView *reusableview = nil;
    
    if (kind == UICollectionElementKindSectionFooter) {
        PhotoStreamFooterView *footerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"PhotoStreamFooter" forIndexPath:indexPath];
        
        /*if (self.spotInfo) {
            NSArray *members = self.spotInfo[@"members"];
            if ([members count] - 1 == 1) {
                footerView.quietHereLabel.text = @"It's a little quiet in here...";
            }else if([members count] - 1 > 1){
                footerView.quietHereLabel.text = @"Invite people to add more photos!";
            }
        }*/
        
        footerView.emailTextField.alpha = 0;
        footerView.emailTextField.delegate = self;
        footerView.otherInviteOptionsButton.alpha = 0;
        reusableview = footerView;
    }
    
    return reusableview;
}



#pragma mark - UICollectionView Delegate
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    //PhotoStreamCell *photoCardCell = (PhotoStreamCell *)[collectionView cellForItemAtIndexPath:indexPath];
    //DLog(@"selected image index - %li",(long)indexPath.item);

    selectedPhotoIndexPath = indexPath;
    
    
}


#pragma mark - Methods
-(IBAction)showMembers:(id)sender
{
    /*if ([[AppHelper userStatus] isEqualToString:kSUBA_USER_STATUS_ANONYMOUS]) {
        [UIView animateWithDuration:.5 animations:^{
            self.createAccountView.alpha = 1;
            self.noActionLabel.text = CREATE_ACCOUNT_TO_SEE_MEMBERS;
            //self.navigationController.navigationBarHidden = YES;
        }];
    }else{*/
       [self performSegueWithIdentifier:@"AlbumMembersSegue" sender:self.spotID];
   // }
}


- (IBAction)sharePhoto:(UIButton *)sender{
    
    /*if ([[AppHelper userStatus] isEqualToString:kSUBA_USER_STATUS_ANONYMOUS]) {
        [UIView animateWithDuration:.5 animations:^{
            self.createAccountView.alpha = 1;
            self.noActionLabel.text = CREATE_ACCOUNT_TO_SHARE_PHOTOS;
            //self.navigationController.navigationBarHidden = YES;
        }];
    }else{*/
        
    PhotoStreamCell *cell = (PhotoStreamCell *)sender.superview.superview.superview;
    if (cell.photoCardImage.image != nil) {
        [self share:kPhoto Sender:sender];
    }else{
        [AppHelper showAlert:@"Share Image Request"
                     message:@"You can share image after it loads"
                     buttons:@[@"OK, I'll wait"]
                    delegate:nil];
      }
   //}
}


-(void)likePhotoWithID:(NSString *)photoId atIndexPath:(NSIndexPath *)indexPath
{
    [Flurry logEvent:@"Photo_Liked"];
    PhotoStreamCell *photoCardCell = (PhotoStreamCell *)[self.photoCollectionView cellForItemAtIndexPath:indexPath];
    NSDictionary *selectedPhotoInfo = self.photos[indexPath.item];
    
    NSDictionary *params = @{@"userId": [AppHelper userID],@"pictureId" : photoId,@"updateFlag" :@"1"};
    
    [[User currentlyActiveUser] likePhoto:params completion:^(id results, NSError *error){
        if ([results[STATUS] isEqualToString:ALRIGHT]){
            [self resamplePhotoInfo:selectedPhotoInfo flag:@"YES" numberOfLikes:results[@"likes"] atIndex:indexPath.item];
            
            // Ask main stream to reload
            [[NSNotificationCenter defaultCenter]
             postNotificationName:kUserReloadStreamNotification object:nil];
            
            if ([results[@"likes"] integerValue] == 1){
                photoCardCell.numberOfLikesLabel.text = [NSString stringWithFormat:@"%@ Like",results[@"likes"]];
            }else if ([results[@"likes"] integerValue] > 1){
                photoCardCell.numberOfLikesLabel.text = [NSString stringWithFormat:@"%@ Likes",results[@"likes"]];
            }
            
            [AppHelper showLikeImage:self.likeImage imageNamed:@"like-button"];
            
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10000), dispatch_get_main_queue(),^{
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


- (IBAction)likePhoto:(id)sender
{
    DLog(@"User status = %@",[AppHelper userStatus]);
    if ([[AppHelper userStatus] isEqualToString:kSUBA_USER_STATUS_ANONYMOUS]) {
        [UIView animateWithDuration:.5 animations:^{
            self.createAccountView.alpha = 1;
            self.noActionLabel.text = CREATE_ACCOUNT_TO_LIKE_PHOTOS;
            //self.navigationController.navigationBarHidden = YES;
        }];
    }else{
        
        UIButton *likeButtonAction = (UIButton *)sender;
        
        PhotoStreamCell *cell = (PhotoStreamCell *)likeButtonAction.superview.superview.superview;
        //UIButton *likeButton = cell.likePhotoButton;
        
        
        NSIndexPath *indexPath = [self.photoCollectionView indexPathForCell:cell];
        
        NSString *picId = self.photos[indexPath.item][@"id"];
        
        if (cell.likePhotoButton.state == UIControlStateNormal || cell.likePhotoButton.state == UIControlStateHighlighted)
        {
            DLog(@"Setting selected");
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10000), dispatch_get_main_queue(),^{
                
                [cell.likePhotoButton setSelected:YES];
            });
            
            [self likePhotoWithID:picId atIndexPath:indexPath];
            
        }else{
            DLog(@"Setting UnSelected");
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10000), dispatch_get_main_queue(),^{
                
                [cell.likePhotoButton setSelected:NO];
            });
            
            [self unlikePhotoWithID:picId atIndexPath:indexPath];
        }
 
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



- (void)savePhoto:(UIImage *)imageToSave
{
        DLog(@"User status = %@",[AppHelper userStatus]);
    if ([[AppHelper userStatus] isEqualToString:kSUBA_USER_STATUS_ANONYMOUS]){
        
        [UIView animateWithDuration:.5 animations:^{
            self.createAccountView.alpha = 1;
            self.noActionLabel.text = CREATE_ACCOUNT_TO_SAVE_PHOTOS;
            //self.navigationController.navigationBarHidden = YES;
        }];
        
    }else{
        if (imageToSave != nil){
            [self savePhotoToCustomAlbum:imageToSave];
            
        }else{
            [AppHelper showAlert:@"Save Image Request"
                         message:@"You can save image after it loads"
                         buttons:@[@"OK, I'll wait"]
                        delegate:nil];
        }
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
    /*if ([[AppHelper userStatus] isEqualToString:kSUBA_USER_STATUS_ANONYMOUS]){
        [UIView animateWithDuration:.5 animations:^{
            self.createAccountView.alpha = 1;
            self.noActionLabel.text = CREATE_ACCOUNT_TO_TAKE_PHOTOS;
            //self.navigationController.navigationBarHidden = YES;
        }];
        
    }else{*/
        
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
    //}
}



-(void)showReportOptions
{
    UIActionSheet *actionsheet = [[UIActionSheet alloc] initWithTitle:@"Why're you reporting photo?"
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@" This photo is sexually explicit",@"This photo is unrelated",nil];
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
    UIActionSheet *action = [[UIActionSheet alloc] initWithTitle:@"Add photos to this stream" delegate:self cancelButtonTitle:@"Not Now" destructiveButtonTitle:nil otherButtonTitles:@"Take Photo",@"Choose From Gallery", nil];
    
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



#pragma mark - Helpers for Social Media
- (void)share:(Mutant)objectOfInterest Sender:(UIButton *)sender
{
    NSArray *activityItems = nil;
    NSString *shareText = nil;
    
    if (objectOfInterest == kSpot){
        NSString *randomString = [self getRandomPINString:5];
        shareText = [NSString stringWithFormat:@"Check out all the photos in my shared photo stream %@ with Suba for iOS @ http://www.subaapp.com/albums?%@",self.spotName,[NSString stringWithFormat:@"%@%@",self.spotID,randomString]];
        
        activityItems = @[self.albumSharePhoto,shareText];
        [Flurry logEvent:@"Share_Stream_Tapped"];
        
    }else if (objectOfInterest == kPhoto){
        PhotoStreamCell *cell = (PhotoStreamCell *)sender.superview.superview.superview;
        NSString *randomString = [self getRandomPINString:5];
        shareText = [NSString stringWithFormat:@"Check out this photo in my shared photo stream %@ with Suba for iOS @ http://www.subaapp.com/albums?%@",self.spotName,[NSString stringWithFormat:@"%@%@",self.spotID,randomString]];
        
        if (cell.remixedImageView.alpha == 1) {
            activityItems = @[cell.remixedImageView.image,shareText];
        }else{
            activityItems = @[cell.photoCardImage.image,shareText];
        }
        
        [User updateUserStat:@"PHOTO_SHARED" completion:^(id results, NSError *error) {
            DLog(@"Response - %@",results);
        }];
        
        [Flurry logEvent:@"Share_Photo_Tapped"];
    }
    
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    
    activityVC.excludedActivityTypes = @[UIActivityTypePrint,UIActivityTypeCopyToPasteboard,UIActivityTypeAssignToContact,UIActivityTypeSaveToCameraRoll,UIActivityTypeAddToReadingList,UIActivityTypeAirDrop];
    
    //[activityVC setCompletionHandler:(UIActivityViewControllerCompletionHandler)completionHandler]
    [self presentViewController:activityVC animated:YES completion:nil];
  
}


-(void)savePhotoToCustomAlbum:(UIImage *)photo
{
    [self.library saveImage:photo toAlbum:@"Suba Photos" completion:^(NSURL *assetURL, NSError *error) {
        [AppHelper showNotificationWithMessage:@"Image saved in camera roll" type:kSUBANOTIFICATION_SUCCESS inViewController:self completionBlock:nil];
        
        [User updateUserStat:@"PHOTO_SAVED" completion:^(id results, NSError *error) {
            DLog(@"Response - %@",results);
        }];
        
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
    picker.maximumNumberOfSelection = 10;
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
       
        
        if ([sender intValue] == kTakeCamera) {
            [self openCamera];
            
            /*
             UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
             imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
            imagePicker.delegate = self;
            imagePicker.allowsEditing = NO;
            
            [self presentViewController:imagePicker animated:YES completion:nil];*/
            
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
    if ([[AppHelper userStatus] isEqualToString:kSUBA_USER_STATUS_ANONYMOUS]) {
            [UIView animateWithDuration:.5 animations:^{
                self.createAccountView.hidden = NO;
                self.noActionLabel.text = CREATE_ACCOUNT_TO_SEE_PROFILE;
                //self.navigationController.navigationBarHidden = YES;
            }];
    }else{
        PhotoStreamCell *pCell = (PhotoStreamCell *)sender.superview.superview.superview;
        NSIndexPath *indexPath = [self.photoCollectionView indexPathForCell:pCell];
        NSDictionary *cellInfo = self.photos[indexPath.item];
        NSString *picTakerId = cellInfo[@"pictureTakerId"];
        
        DLog(@"We are going to %@ with ID - %@",cellInfo,picTakerId);
        
        [self performSegueWithIdentifier:@"PHOTOSTREAM_USERPROFILE" sender:cellInfo];
    }
}


#pragma mark - UIAlertView Delegate
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(alertView.tag == 20000){
        if (buttonIndex == 1){
            // Upload Photo again
            //self uploadPhoto:<#(NSData *)#> WithName:<#(NSString *)#>
        }
    }else{
        if (buttonIndex == 1) {
            NSInteger index = [self.photos indexOfObject:self.photoInView];
            [self deletePhotoAtIndexFromStream:index];
        }
    }
    
}


#pragma mark - UIActionSheet Delegate Methods
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == 7000){
         NSString *randomString = [self getRandomPINString:5];
        NSString *shareText = [NSString stringWithFormat:@"Check out all the photos in my shared photo stream \"%@\" with Suba for iOS at http://www.subaapp.com/albums?%@",self.spotName,[NSString stringWithFormat:@"%@%@",self.spotID,randomString]];
        if (buttonIndex == 0) {
            //DLog(@"Facebook");
            
            if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) {
                // code to send message to Facebook
                //NSString *const SLServiceTypeFacebook;
                SLComposeViewController *composeVC = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
            
                [composeVC addImage:(selectedPhoto ? selectedPhoto : nil)];
                
                //[composeVC addURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.subaapp.com/albums?%@%@",self.spotID,randomString]]];
                
                [composeVC setInitialText:shareText];
                
                [composeVC setCompletionHandler:^(SLComposeViewControllerResult result) {
                    switch (result) {
                        case SLComposeViewControllerResultCancelled:
                            DLog(@"Share stream cancelled");
                            [Flurry logEvent:@"Share_Stream_Facebook_Cancelled"];
                            break;
                        case SLComposeViewControllerResultDone:
                            [User updateUserStat:@"STREAM_SHARED" completion:^(id results, NSError *error) {
                                DLog(@"Response  - %@",results);
                            }];
                            DLog(@"Stream Shared on Facebook");
                            [Flurry logEvent:@"Share_Stream_Facebook_Done"];
                            
                            break;
                        default:
                            break;
                    }
                    
                    [self dismissViewControllerAnimated:YES completion:nil];
                }];
                
                [self presentViewController:composeVC animated:YES completion:nil];
            }
            
        }else if (buttonIndex == 1){
            //DLog(@"Twitter seleced");
            if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
                SLComposeViewController *composeVC = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
                
                [composeVC addImage:(selectedPhoto ? selectedPhoto : nil)];
                
                [composeVC setInitialText:shareText];
                
                [composeVC setCompletionHandler:^(SLComposeViewControllerResult result) {
                    switch (result) {
                        case SLComposeViewControllerResultCancelled:
                            [Flurry logEvent:@"Share_Stream_Twitter_Cancelled"];
                            DLog(@"Message cancelled.");
                            break;
                        case SLComposeViewControllerResultDone:
                            DLog(@"Message sent.");
                            [User updateUserStat:@"STREAM_SHARED" completion:^(id results, NSError *error) {
                                DLog(@"Response  - %@",results);
                            }];
                            [Flurry logEvent:@"Share_Stream_Twitter_Done"];
                            break;
                        default:
                            break;
                    }
                    
                    [self dismissViewControllerAnimated:YES completion:nil];
                }];
                
                [self presentViewController:composeVC animated:YES completion:nil];
                
            }
        }else if (buttonIndex == 2){
            DLog(@"Email selected");
           
            MFMailComposeViewController *mailComposer = [[MFMailComposeViewController alloc] init];
            mailComposer.mailComposeDelegate = self;
            [mailComposer setSubject:[NSString stringWithFormat:@"Photos from \"%@\"",self.spotName]];
            
            
            [mailComposer setMessageBody:shareText isHTML:NO];
            if (selectedPhoto != nil) {
                NSData *imageData = UIImageJPEGRepresentation(selectedPhoto, 1.0);
                [mailComposer addAttachmentData:imageData mimeType:@"image/jpeg" fileName:@"subapic"];
            }
            
            [User updateUserStat:@"STREAM_SHARED" completion:^(id results, NSError *error) {
                DLog(@"Response  - %@",results);
            }];
            
            [Flurry logEvent:@"Share_Stream_Email_Done"];
            
            [self presentViewController:mailComposer animated:YES completion:nil];
        }
        /*else if (buttonIndex == 3){
            MFMessageComposeViewController *messageComposer = [[MFMessageComposeViewController alloc] init];
            messageComposer.delegate = self;
            
            [messageComposer setBody:shareText];
            
            NSDictionary *textTitleOptions = [NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName,[UIColor whiteColor],NSForegroundColorAttributeName, [UIFont fontWithName:@"HelveticaNeue-Light" size:17.0], NSFontAttributeName,nil];
            
            [messageComposer.navigationBar setTitleTextAttributes:textTitleOptions];
            
            if ([MFMessageComposeViewController canSendAttachments]) {
                NSData *imageData = UIImageJPEGRepresentation(selectedPhoto, 1.0);
                [messageComposer addAttachmentData:imageData typeIdentifier:@"" filename:@"subapic"];
                //[messageComposer addAttachmentData:imageData typeIdentifier:@"image/jpeg" fileName:@"subapic"];
            }
            
            
            [User updateUserStat:@"STREAM_SHARED" completion:^(id results, NSError *error) {
                DLog(@"Response  - %@",results);
            }];
            
            [Flurry logEvent:@"Share_Stream_SMS_Done"];
            
            [self presentViewController:messageComposer animated:YES completion:nil];
        }*/
        
    }else if (actionSheet.tag == 5000){
        
        if(buttonIndex == 0){
            if ([[AppHelper userStatus] isEqualToString:kSUBA_USER_STATUS_ANONYMOUS]){
                [UIView animateWithDuration:.5 animations:^{
                    self.createAccountView.alpha = 1;
                    self.noActionLabel.text = CREATE_ACCOUNT_TO_SAVE_PHOTOS;
                    //self.navigationController.navigationBarHidden = YES;
                }];
                
            }else{
                //User wants to save photo
                [self savePhoto:selectedPhoto];
            }
            
        }else if (buttonIndex == 1){
            
            
            UIAlertView *deleteAlert = [[UIAlertView alloc] initWithTitle:@"Delete Photo" message:@"Are you sure you want to delete this photo?" delegate:self cancelButtonTitle:@"NO" otherButtonTitles:@"YES", nil];
            
            [deleteAlert show];
        }
    }else if (actionSheet.tag == 1000){
        if(buttonIndex == 0){
            if ([[AppHelper userStatus] isEqualToString:kSUBA_USER_STATUS_ANONYMOUS]) {
                [UIView animateWithDuration:.5 animations:^{
                    self.createAccountView.alpha = 1;
                    self.noActionLabel.text = CREATE_ACCOUNT_TO_SAVE_PHOTOS;
                    //self.navigationController.navigationBarHidden = YES;
                }];
            }else{
                //User wants to save photo
                [self savePhoto:selectedPhoto];
            }
        }
           
    }else if(actionSheet.tag == 2000){
        
        
            // User is reporting a photo
            NSString *reportType = nil;
            if (buttonIndex == kSexuallyExplicit){
                reportType = kSEXUALLY_EXPLICIT;
            }else{
                reportType = kUNRELATED_PHOTO;
            }
            
            NSDictionary *params = @{
                                     @"photoId":self.photoInView[@"id"],
                                     @"spotId" : self.spotID,
                                     @"pictureTakerName" : self.photoInView[@"pictureTaker"],
                                     @"reporterId" : [AppHelper userID],
                                     @"reportType" : reportType
                                     };
            
            
            [self reportPhoto:params];
      
    }else{
    
    if (buttonIndex == kTakeCamera){
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
            if ([[AppHelper userStatus] isEqualToString:kSUBA_USER_STATUS_ANONYMOUS]) {
                [UIView animateWithDuration:.5 animations:^{
                    self.createAccountView.alpha = 1;
                    self.noActionLabel.text = CREATE_ACCOUNT_TO_REPORT_PHOTOS;
                    //self.navigationController.navigationBarHidden = YES;
                }];
            }else{
                [self showReportOptions];
            }
        }
    }else if (actionSheet.tag == 5000){
        if (buttonIndex == 2) {
            
            if ([[AppHelper userStatus] isEqualToString:kSUBA_USER_STATUS_ANONYMOUS]) {
                [UIView animateWithDuration:.5 animations:^{
                    self.createAccountView.alpha = 1;
                    self.noActionLabel.text = CREATE_ACCOUNT_TO_REPORT_PHOTOS;
                    //self.navigationController.navigationBarHidden = YES;
                }];
            }else{
                [self showReportOptions];
            }
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
    @try {
        
        
        
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
            
            //DLog(@"Filling images data with name - %@",name);
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
                
                //[self uploadingPhotoView:YES];
                // Check for when we are getting a nil data parameter back
                NSDictionary *photoInfo = [NSJSONSerialization JSONObjectWithData:woperation.responseData options:NSJSONReadingAllowFragments error:&error];
                //[self uploadingPhotoView:NO];
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
        
    }@catch (NSException *exception) {
        [self uploadingPhotoView:NO];
        [AppHelper showAlert:@"Network Error" message:@"We encountered a problem uploading your photo" buttons:@[@"Try Again"] delegate:nil];
        
        [Flurry logError:@"Photo Upload Error" message:[exception name] exception:exception];
    }
    @finally {
        [self uploadingPhotoView:NO];
    }
}


-(void)uploadDoodle:(NSData *)imageData WithName:(NSString *)name
{
    @try {
        
       // [self uploadingPhotoView:YES];
        
        //DLog(@"Selected photo ID = %@",self.photos[selectedPhotoIndexPath.item][@"id"]);
        NSString *userId = [User currentlyActiveUser].userID;
        NSString *spotId = self.spotID;
        
        NSDictionary *params = @{@"userId": userId,@"spotId": spotId,@"originalPhotoURL" : name,@"photoId": self.photos[selectedPhotoIndexPath.item][@"id"]};
        AFHTTPSessionManager *manager = [SubaAPIClient sharedInstance];
        
        NSURL *baseURL = (NSURL *)[SubaAPIClient subaAPIBaseURL];
        
        NSString *urlPath = [[NSURL URLWithString:@"spot/picture/doodle" relativeToURL:baseURL] absoluteString];
        
        NSMutableURLRequest *request = [manager.requestSerializer
                                        multipartFormRequestWithMethod:@"POST"
                                        URLString:urlPath
                                        parameters:params
                                        constructingBodyWithBlock:^(id<AFMultipartFormData> formData){
                                            
                                            
                                            
                                            [formData appendPartWithFileData:imageData name:@"picture" fileName:[NSString stringWithFormat:@"%@.jpg",name] mimeType:@"image/jpeg"];
                                        }];
        
        
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
                
                NSError *error = woperation.error;
                NSDictionary *photoInfo = [NSJSONSerialization JSONObjectWithData:woperation.responseData options:NSJSONReadingAllowFragments error:&error];
                 //[self uploadingPhotoView:NO];
                if (error) {
                     //[self uploadingPhotoView:NO];
                    DLog(@"Error serializing %@", error);
                    [AppHelper showAlert:@"Upload Failure"
                                 message:error.localizedDescription
                                 buttons:@[@"OK"] delegate:nil];
                }else{
                     //[self uploadingPhotoView:NO];
                    
                    [[NSNotificationCenter defaultCenter]
                     postNotificationName:kUserReloadStreamNotification object:nil];
                    //DLog(@"Old self.photos - %@",self.photos);
                    
                    for (NSDictionary *photo in self.photos){
                        //DLog(@"self.photo ID - %@\ndoodled photo ID - %@",photo[@"id"],photoInfo[@"id"]);
                        if([photoInfo[@"id"] integerValue] ==  [photo[@"id"] integerValue]){
                            // Lets replace this NSDictionary coz this object is the photo that was doodles
                            NSUInteger indexOfOriginalPhoto = [self.photos indexOfObject:photo];
                            [self.photos replaceObjectAtIndex:indexOfOriginalPhoto withObject:photoInfo];
                            
                            //DLog(@"Photo Info - %@\nNew self.photos- %@",photoInfo,self.photos);
                            break;
                        }
                    }
                    DLog(@"Photo Info - %@",photoInfo);
                    [Flurry logEvent:@"Photo_Doodled"];
                    [self.photoCollectionView reloadData];
                    
                    
                }
            });
        }];
        
        
        [operation start];
        
    }
    @catch (NSException *exception) {
        [self uploadingPhotoView:NO];
        [AppHelper showAlert:@"Network Error" message:@"We encountered a problem uploading your photo" buttons:@[@"Try Again"] delegate:nil];
        
        [Flurry logError:@"Doodle Upload Error" message:[exception name] exception:exception];
    }
    @finally {
        [self uploadingPhotoView:NO];
    }
}





-(void)uploadPhoto:(NSData *)imageData WithName:(NSString *)name
{
    @try {
        
        
        
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
        
        [manager.requestSerializer setValue:@"com.suba.subaapp-ios" forHTTPHeaderField:@"x-suba-api-token"];
        
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
        
        //if (self.imageUploadProgressView.hidden == YES) {
        [operation setCompletionBlock:^{
            
            dispatch_async(dispatch_get_main_queue(), ^{
                NSError *error = woperation.error;
                //[self uploadingPhotoView:YES];
                
                NSDictionary *photoInfo = [NSJSONSerialization JSONObjectWithData:woperation.responseData options:NSJSONReadingAllowFragments error:&error];
                //[self uploadingPhotoView:NO];
                if (error) {
                    //[self uploadingPhotoView:NO];
                    DLog(@"Error serializing %@", error);
                    [AppHelper showAlert:@"Upload Failure" message:error.localizedDescription buttons:@[@"OK"] delegate:nil];
                }else{
                    //[self uploadingPhotoView:NO];
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
        
        /*}else{
         UIAlertView *uploadFailureAlert = [[UIAlertView alloc] initWithTitle:@"Upload Error"
         message:@"Your photo could not finish uploading.Try again?" delegate:self cancelButtonTitle:@"NO" otherButtonTitles:@"YES", nil];
         uploadFailureAlert.tag = 20000;
         [uploadFailureAlert show];
         }*/
        
        [operation start];
 
    }
    @catch (NSException *exception) {
        // What to do when we have an error
        [self uploadingPhotoView:NO];
        [AppHelper showAlert:@"Network Error" message:@"We encountered a problem uploading your photo" buttons:@[@"Try Again"] delegate:nil];
        
        [Flurry logError:@"Photo Upload Error" message:[exception name] exception:exception];
    }
    @finally {
        [self uploadingPhotoView:NO];
    }
}

-(void)upDateCollectionViewWithCapturedPhoto:(NSDictionary *)photoInfo{
    @try {
        [self.photoCollectionView performBatchUpdates:^{
            [self.photoCollectionView insertItemsAtIndexPaths:@[ [NSIndexPath indexPathForItem:0 inSection:0] ]];
        } completion:^(BOOL finished){
            
            [self.photoCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionLeft animated:YES];
            
            [self showGivePushNotificationScreen];
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
    @catch (NSException *exception) {
        // What to do when we have an exception
    }
    @finally {
        
    }
    
}


-(void)upDateCollectionViewWithCapturedPhotos:(NSArray *)photoInfo{
    @try {
        [self uploadingPhotoView:NO];
        NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:2];
        for (int x = 0; x < [photoInfo count]; x++) {
            [indexPaths addObject:[NSIndexPath indexPathForItem:x inSection:0]];
        }
        
        [self.photoCollectionView performBatchUpdates:^{
            [self.photoCollectionView insertItemsAtIndexPaths:indexPaths];
        } completion:^(BOOL finished) {
            [self.photoCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionLeft animated:YES];
            
            [self showGivePushNotificationScreen];
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
        
        [[LSPushProviderAPIClient sharedInstance] POST:@"photosadded"
                                            parameters:params
                             constructingBodyWithBlock:nil
                                               success:^(NSURLSessionDataTask *task, id responseObject) {
                                                   DLog(@"From push provider - %@",responseObject);
                                               } failure:^(NSURLSessionDataTask *task, NSError *error) {
                                                   DLog(@"Error - %@",error);
                                               }];

    }
    @catch (NSException *exception) {[self uploadingPhotoView:NO];}
    @finally {[self uploadingPhotoView:NO];}
    
}

- (IBAction)doFacebookLogin:(id)sender
{
    [self.facebookLoginIndicator startAnimating];
    
    [AppHelper openFBSession:^(id results, NSError *error) {
        [AppHelper setUserStatus:kSUBA_USER_STATUS_CONFIRMED];
        [Flurry logEvent:@"Account_Confirmed_Facebook"];
        [self.facebookLoginIndicator stopAnimating];
        [self performSelector:@selector(dismissCreateAccountPopUp)];
       
    }];
}



#pragma mark - Segues
-(void)unWindToPhotoStream:(UIStoryboardSegue *)segue
{
    
}

-(void)unWindToPhotoStreamWithWithInfo:(UIStoryboardSegue *)segue
{
    StreamSettingsViewController *albumVC = segue.sourceViewController;
    self.navItemTitle.text = albumVC.spotName;

    /*[IonIcons label:self.navItemTitle setIcon:icon_arrow_down_b
               size:10.0f color:[UIColor whiteColor] sizeToFit:NO];*/
    
    [self.navItemTitle sizeToFit];
}

- (IBAction)addFirstPhotoButtonTapped:(UIButton *)sender
{
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

- (IBAction)registerForPushNotification:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kUserDidSignUpNotification object:nil];
    [self performSelector:@selector(dismissNotificationScreen:) withObject:nil afterDelay:0.5];
}

- (IBAction)remixPhoto:(UIButton *)sender
{
    if ([[AppHelper userStatus] isEqualToString:kSUBA_USER_STATUS_ANONYMOUS]) {
        [UIView animateWithDuration:.5 animations:^{
            self.createAccountView.alpha = 1;
            self.noActionLabel.text = CREATE_ACCOUNT_TO_REMIX_PHOTOS;
        }];
        
    }else{
        
    // Remix Photo
    PhotoStreamCell *cell = (PhotoStreamCell *)sender.superview.superview.superview;
    NSIndexPath *indexpath = [self.photoCollectionView indexPathForCell:cell];
    self.photoInView = self.photos[indexpath.row];
    
     if (cell.remixedImageView.image){
        if (cell.photoCardImage.alpha == 1){
            [UIView transitionWithView:cell.photoCardImage duration:0.8 options:UIViewAnimationOptionTransitionFlipFromRight animations:^{
                cell.photoCardImage.alpha = 0;
                cell.remixedImageView.alpha = 1;
            } completion:^(BOOL finished) {
               selectedPhoto = cell.remixedImageView.image;
                selectedPhotoIndexPath = indexpath;
                [self performSegueWithIdentifier:@"DoodleSegue" sender:selectedPhoto];
            }];
        }else if (cell.remixedImageView.alpha == 1){
            selectedPhoto = cell.remixedImageView.image;
            selectedPhotoIndexPath = indexpath;
            [self performSegueWithIdentifier:@"DoodleSegue" sender:selectedPhoto];
        }
    }else{
        
        selectedPhoto = cell.photoCardImage.image;
        selectedPhotoIndexPath = indexpath;
        [self performSegueWithIdentifier:@"DoodleSegue" sender:selectedPhoto];
        
    }
  }
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"SpotSettingsSegue"]) {
        if ([segue.destinationViewController isKindOfClass:[StreamSettingsViewController class]]) {
            StreamSettingsViewController *albumVC = segue.destinationViewController;
            albumVC.spotID = (NSString *)sender;
            albumVC.spotInfo = self.spotInfo;
            albumVC.whereToUnwind = [self.parentViewController childViewControllers][0];
            //DLog(@"WhereToUnwind - %@",[albumVC.whereToUnwind class]);
        }
    }else if ([segue.identifier isEqualToString:@"AlbumMembersSegue"]){
        if ([segue.destinationViewController isKindOfClass:[AlbumMembersViewController class]]){
            AlbumMembersViewController *membersVC = segue.destinationViewController;
            membersVC.spotID = sender;
            membersVC.spotInfo = self.spotInfo;
        }
    }else if ([segue.identifier isEqualToString:@"PHOTOSTREAM_USERPROFILE"]){
        UserProfileViewController *uVC = segue.destinationViewController;
        DLog(@"Sender UserId - %@",sender[@"pictureTakerId"]);
        uVC.userId = sender[@"pictureTakerId"];
    }else if ([segue.identifier isEqualToString:@"InviteFriendsSegue"]) {
            InvitesViewController *iVC = segue.destinationViewController;
            iVC.spotToInviteUserTo = self.spotInfo;
    }else if ([segue.identifier isEqualToString:@"PhotoToEmailInvitesSegue"]){
        EmailInvitesViewController *emailVC = segue.destinationViewController;
        emailVC.streamId = sender;
    }else if ([segue.identifier isEqualToString:@"DoodleSegue"]){
        SBDoodleViewController *doodleVC = segue.destinationViewController;
        doodleVC.imageToRemix = (UIImage *)sender;
        NSString *remixURL =self.photos[selectedPhotoIndexPath.item][@"s3RemixName"];
        doodleVC.imageToRemixURL = remixURL;
        doodleVC.remixImageID = [self.photoInView[@"id"] integerValue];
    }
}



#pragma mark - handle gesture recognizer
- (void)photoCardTapped:(UITapGestureRecognizer *)sender
{
    
    if (sender.state == UIGestureRecognizerStateEnded)
    {
        /*NSString *photoId = self.photos[selectedPhotoIndexPath.item][@"id"];
        
        if ([self.photos[selectedPhotoIndexPath.item][@"userLikedPhoto"] isEqualToString:@"NO"]){
            
            [self likePhotoWithID:photoId atIndexPath:selectedPhotoIndexPath];
            
        }else{
                [self unlikePhotoWithID:photoId atIndexPath:selectedPhotoIndexPath];
        }*/
        PhotoStreamCell *photoCardCell = (PhotoStreamCell *)sender.view.superview.superview;
        DLog(@"Show photo full screen from view - %@ - %@",[sender.view class],[sender.view.superview.superview class]);
        /*UIImageView *imgView = (UIImageView *)sender.view;
        if(imgView.image){
            NSArray *photos = [IDMPhoto photosWithImages:@[imgView.image]];
            
            IDMPhotoBrowser *photoBrowser = [[IDMPhotoBrowser alloc] initWithPhotos:photos];
            
            [self presentViewController:photoBrowser animated:YES completion:nil];
        }*/
        
        
       // @try {
            if (photoCardCell.photoCardImage.alpha == 1) {
                if (photoCardCell.photoCardImage.image){
                    
                    NSArray *photos = [IDMPhoto photosWithImages:@[photoCardCell.photoCardImage.image]];
                    
                    IDMPhotoBrowser *photoBrowser = [[IDMPhotoBrowser alloc] initWithPhotos:photos animatedFromView:photoCardCell.photoCardImage];
                    photoBrowser.displayActionButton = NO;
                    photoBrowser.displayToolbar = NO;
                    photoBrowser.displayDoneButton= YES;
                    
                    [self presentViewController:photoBrowser animated:YES completion:nil];
                }
            }else if (photoCardCell.remixedImageView.alpha == 1) {
                // If the doodle is showing
                if (photoCardCell.remixedImageView.image){
                    
                    NSArray *photos = [IDMPhoto photosWithImages:@[photoCardCell.remixedImageView.image]];
                    
                    IDMPhotoBrowser *photoBrowser = [[IDMPhotoBrowser alloc] initWithPhotos:photos animatedFromView:photoCardCell.remixedImageView];
                    photoBrowser.displayActionButton = NO;
                    photoBrowser.displayToolbar = NO;
                    photoBrowser.displayDoneButton= YES;
                    [self presentViewController:photoBrowser animated:YES completion:nil];                }
            }
        }
     
}


/*- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    self.cameraButton.alpha = 0.2;
}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    self.cameraButton.alpha = 0.2;
}


-(void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
 
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    // Has the user scrolled more than half of the photo currently in view
    // Get the  x content offset (Since we're doing horizontal scrolling)
    // The scale factor tells us the index of the image being viewed
    
    //CGFloat xpos = self.photoCollectionView.contentOffset.x;
    //CGFloat ypos = scrollView.frame.origin.y;
    //int multiFactor = (int)floorf(self.photoCollectionView.contentOffset.x/300.0);
    
    //int page = 300.0f;
    //[scrollView setContentOffset:CGPointMake(multiFactor*page,0) animated:NO];
    
    //DLog(@"Y-POS - %f",scrollView.frame.origin.y);
    [UIView animateWithDuration:.3
                     animations:^{
                         self.cameraButton.alpha = 1;
                     }];
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
   // CGFloat xpos = self.photoCollectionView.contentOffset.x;
    //CGFloat ypos = self.photoCollectionView.frame.origin.y;
    //int multiFactor = (int)floorf(self.photoCollectionView.contentOffset.x/300.0);
    
    [self scrollToCorrect:scrollView];
}


-(void)scrollToCorrect:(UIScrollView*)scrollView
{
    CGFloat xpos = self.photoCollectionView.contentOffset.x;
    int multiFactor = (int) floorf(self.photoCollectionView.contentOffset.x/285.0);
    int quotient = (int)(xpos/285.0);
    
    int step = 310 * quotient;
    
    int lag = xpos - step;
    
    if (lag <= 143) {
        // Move to the next image
        multiFactor = quotient;
        
    }else multiFactor = quotient + 1;
    
    int page = 285.0f;
    
    DLog(@"\nCONTENT OFFSET - %@\n MULTIPLICATION FACTOR - %i\nNew offset - %i\n",
         NSStringFromCGPoint(self.photoCollectionView.contentOffset),multiFactor,multiFactor*page);
    
    [scrollView setContentOffset:CGPointMake(multiFactor*page,0) animated:YES];
}*/




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
    [self loadSpotInfo:self.spotID];
    //1. Update photos
    if (self.photos) {
        [self.photoCollectionView reloadData];
    }
    
    if (self.spotID){
        DLog(@"SpotId");
        [self loadSpotImages:self.spotID];
    }
    
    if (self.spotName){
        DLog(@"SpotId");
        self.navItemTitle.text = self.spotName;
        /*[IonIcons label:self.navItemTitle setIcon:icon_arrow_down_b
                   size:10.0f color:[UIColor whiteColor] sizeToFit:NO];*/
        
        [self.navItemTitle sizeToFit];
    }
    
    //2. If spotInfo is nil,loadspotInfo
    if (self.spotID && !self.spotInfo) {
        [self loadSpotInfo:self.spotID];
    }
    
  
}


-(void)showGivePushNotificationScreen
{
    if ([AppHelper numberOfPhotoStreamEntries] % 10 == 0) {
        [UIView animateWithDuration:.2 animations:^{
            self.firstTimeNotificationScreen.alpha = 1;
        }];
    }
    
}


- (IBAction)dismissNotificationScreen:(id)sender
{
    [UIView animateWithDuration:.2 animations:^{
        self.firstTimeNotificationScreen.alpha = 0;
        //self.navigationController.navigationBarHidden = NO;
        //[self.firstTimeNotificationScreen removeFromSuperview];
    }];
    
}



#pragma mark - MFMessageComposeViewControllerDelegate
-(void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    
      switch (result)
    {
        case MessageComposeResultCancelled:
            DLog(@"SMS sending failed");
            [Flurry logEvent:@"SMS_Invite_Cancelled"];
            break;
        case MessageComposeResultSent:
            DLog(@"SMS sent");
            [Flurry logEvent:@"SMS_Invite_Sent"];
            break;
        case MessageComposeResultFailed:
            //DLog(@"SMS sending failed");
            [Flurry logEvent:@"SMS_Invite_Failed"];
            break;
        default:
            DLog(@"SMS not sent");
            break;
    }
    
    [controller dismissViewControllerAnimated:YES completion:nil];
}



#pragma mark - MFMailComposeViewController
-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    
    switch (result)
    {
        case MFMailComposeResultCancelled:
            //DLog(@"SMS sending failed");
            [Flurry logEvent:@"Email_Share_Cancelled"];
            break;
        case MFMailComposeResultSent:
            //DLog(@"SMS sent");
            [Flurry logEvent:@"Email_Share_Sent"];
            break;
        case MFMailComposeResultFailed:
            //DLog(@"SMS sending failed");
            [Flurry logEvent:@"Email_Share_Failed"];
            break;
        default:
            DLog(@"Email not sent");
            break;
    }
    
    [controller dismissViewControllerAnimated:YES completion:nil];
}




#pragma mark - Send SMS
-(void)sendSMSToRecipients:(NSMutableArray *)recipients
{
    if ([MFMessageComposeViewController canSendText]){
        
        MFMessageComposeViewController *smsComposer = [[MFMessageComposeViewController alloc] init];
        
        smsComposer.messageComposeDelegate = self;
        smsComposer.recipients = recipients ;
        
        /*Add your photos to the group photo stream “[name of stream]” on Suba for iPhone. 
         This is where everyone is sharing their pics from this event! Download Suba here: http://appstore.com/suba*/
        
        smsComposer.body = [NSString stringWithFormat:@"Add your photos to the group photo stream \"%@\" on Suba for iPhone. This is where everyone is sharing their pics from this event! Download Suba here: http://subaapp.com/download",self.spotName];
                            
        smsComposer.navigationBar.translucent = NO;
        UIColor *navbarTintColor = [UIColor colorWithRed:(217.0f/255.0f)
                                                   green:(77.0f/255.0f)
                                                    blue:(20.0f/255.0f)
                                                   alpha:1];
        
        smsComposer.navigationBar.barTintColor = navbarTintColor;
        smsComposer.navigationBar.tintColor = navbarTintColor;
        smsComposer.navigationItem.title = @"Send Message";
        
        NSDictionary *textTitleOptions = [NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName,[UIColor whiteColor],NSForegroundColorAttributeName, [UIFont fontWithName:@"HelveticaNeue-Light" size:17.0], NSFontAttributeName,nil];
        
        [smsComposer.navigationBar setTitleTextAttributes:textTitleOptions];
        
        [self presentViewController:smsComposer animated:NO completion:nil];
        
    }else{
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Text Message Failure"
                              message:
                              @"Your device doesn't support in-app sms"
                              delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}


- (IBAction)invitePeopleByEmail:(UIButton *)sender
{
    DLog(@"Email selected");
    NSString *shareText = [NSString stringWithFormat:@"Join my photo stream \"%@\" on Suba at https://subaapp.com/download",self.spotName];
    
    MFMailComposeViewController *mailComposer = [[MFMailComposeViewController alloc] init];
    mailComposer.mailComposeDelegate = self;
    [mailComposer setSubject:[NSString stringWithFormat:@"Photos from \"%@\"",self.spotName]];
    
    
    [mailComposer setMessageBody:shareText isHTML:NO];
    if (selectedPhoto != nil) {
        NSData *imageData = UIImageJPEGRepresentation(selectedPhoto, 1.0);
        [mailComposer addAttachmentData:imageData mimeType:@"image/jpeg" fileName:@"subapic"];
    }
    
    [Flurry logEvent:@"Share_Stream_Email_Done"];
    
    [self presentViewController:mailComposer animated:YES completion:nil];
    //[self performSegueWithIdentifier:@"PhotoToEmailInvitesSegue" sender:self.spotID];
    
}


- (IBAction)invitePeopleBySMS:(id)sender
{
    [self sendSMSToRecipients:nil];
}


- (IBAction)inviteSubaUsersToJoinStream:(id)sender
{
    [self performSegueWithIdentifier:@"InviteFriendsSegue" sender:nil];
}

- (IBAction)showOtherInviteOptions:(UIButton *)sender
{
    PhotoStreamFooterView *footerView = (PhotoStreamFooterView *)sender.superview.superview;
    
    [UIView animateWithDuration:.8 animations:^{
        
        sender.alpha = 0;
        footerView.emailTextField.alpha = 0;
        footerView.smsInviteButton.alpha = 1;
        footerView.inviteByUsernameButton.alpha = 1;
        
        CGFloat newFrameY = footerView.smsInviteButton.frame.origin.y - (footerView.emailInviteButton.frame.size.height + 20);
        CGRect newFrame = CGRectMake(footerView.emailInviteButton.frame.origin.x, newFrameY, footerView.emailInviteButton.frame.size.width, footerView.emailInviteButton.frame.size.height);
        
        footerView.emailInviteButton.enabled = YES;
        footerView.emailInviteButton.frame = newFrame;
        [footerView.emailInviteButton setTitle:@"Invite by email" forState:UIControlStateNormal];
        
    }];
}


#pragma mark - UITextField Delegate
-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    // Move the textfield up to give space for user to continue
    if (textField == self.firstNameField || textField == self.lastNameField || textField == self.usernameField)
    {
       [self.signUpWithEmailView setContentOffset:CGPointMake(0.0f, 100.0f) animated:YES];
        
    }else if (textField == self.emailField || textField == self.passwordField || textField == self.reTypePasswordField)
    {
       [self.finalSignUpWithEmailView setContentOffset:CGPointMake(0.0f, 100.0f) animated:YES];
    }
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    /*if (textField == self.userNameOrEmailTextField) {
        [self.userNameOrEmailTextField resignFirstResponder];
        
    }else if (textField == self.loginPasswordTextField){ // if we are in the password field
        
        if (![self.loginPasswordTextField.text isEqualToString:@""] && ![self.userNameOrEmailTextField.text isEqualToString:@""]){
            self.userEmail = self.userNameOrEmailTextField.text;
            self.userPassword = self.loginPasswordTextField.text;
            
            [self performSelector:@selector(performLoginAction:)];
        }else{
            [self.loginPasswordTextField resignFirstResponder];
        }
    }else{*/
    
        if (textField == self.firstNameField)[self.lastNameField becomeFirstResponder];
        if (textField == self.lastNameField)[self.usernameField becomeFirstResponder];
        if (textField == self.usernameField)[self.usernameField resignFirstResponder];
        if (textField == self.emailField)[self.passwordField becomeFirstResponder];
        if (textField == self.passwordField)[self.reTypePasswordField becomeFirstResponder];
        if (textField == self.reTypePasswordField && ![textField.text isEqualToString:@""]) {
            if (![self.emailField.text isEqualToString:@""] && ![self.usernameField.text isEqualToString:@""]
                && ![self.firstNameField.text isEqualToString:@""] && ![self.lastNameField.text isEqualToString:@""]
                && ![self.passwordField.text isEqualToString:@""]){
                // Now all the fields are not empty
                //1. Let's first check whether the email is correct
                if ([AppHelper validateEmail:self.emailField.text]){
                    // If the email is correct,begin to process everything else
                    if ([self.usernameField.text isEqualToString:self.passwordField.text]){
                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Yet to sign up" message:@"Your username and password appear to be the same" delegate:nil cancelButtonTitle:@"I'll check" otherButtonTitles:nil];
                        [alertView show];
                    }else{
                        self.firstName = self.firstNameField.text;
                        self.lastName = self.lastNameField.text;
                        self.userEmail = self.emailField.text;
                        self.userName = self.usernameField.text;
                        self.userPassword = self.passwordField.text;
                        NSDictionary *params = @{
                                                 @"userId" : [AppHelper userID],
                                                 @"firstName" : self.firstName,
                                                 @"lastName" : self.lastName,
                                                 @"email": self.userEmail,
                                                 @"pass":self.userPassword,
                                                 @"userName":self.userName,
                                                 @"fbLogin" : NATIVE
                                                 };
                        [AppHelper createUserAccount:params WithType:NATIVE completion:^(id results, NSError *error){
                            if (!error) {
                                [AppHelper savePreferences:results];
                                
                                [self performSelector:@selector(dismissCreateSubaAccountScreen:)];
                                
                            }else{
                                [AppHelper showAlert:results[STATUS] message:results[@"message"]
                                             buttons:@[@"I'll check again"] delegate:nil];
                            }
                        }];
                    }
                }else{
                    
                    UIAlertView *alertView = [[UIAlertView alloc]
                                              initWithTitle:@"Email check"
                                              message:@"We could not verfiy your email address format.Please check again"
                                              delegate:nil
                                              cancelButtonTitle:@"I'll check"
                                              otherButtonTitles:nil];
                    
                    [alertView show];
                }
                
                [textField resignFirstResponder];
            }
            
        }
        
        
    //}
    return YES;
}


-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    return YES;
}



#pragma mark - Other Actions
- (IBAction)flipPhotoToShowRemix:(id)sender
{
    UIButton *flipButton = (UIButton *)sender;
    PhotoStreamCell *cell = (PhotoStreamCell *)flipButton.superview.superview.superview;
    
    if (cell.photoCardImage.alpha == 1) {
        [UIView transitionWithView:cell.photoCardImage duration:0.8 options:UIViewAnimationOptionTransitionFlipFromRight animations:^{
            cell.photoCardImage.alpha = 0;
            cell.remixedImageView.alpha = 1;
        } completion:NULL];
    }else{
        [UIView transitionWithView:cell.remixedImageView duration:0.8 options:UIViewAnimationOptionTransitionFlipFromRight animations:^{
            cell.photoCardImage.alpha = 1;
            cell.remixedImageView.alpha = 0;
        } completion:NULL];
    }
}


#pragma mark - Hidden Menu Tins
- (void)showHiddenMenu:(UITapGestureRecognizer *)sender
{
    DLog(@"Showing Hidden View with uview - %@",sender.view);
   // Get the container view and increase height
    if (sender.state == UIGestureRecognizerStateEnded){
        if (toggler % 2 == 0) {
            [UIView animateWithDuration:0.3 animations:^{
                CGRect hiddenMenuFrame = CGRectMake(0, 0, 320, 150);
                self.hiddenTopMenuView.frame = hiddenMenuFrame;
                self.hiddenTopMenuView.alpha = 1;
            }];
        }else{
            [UIView animateWithDuration:0.3 animations:^{
                CGRect hiddenMenuFrame = CGRectMake(0, 0, 320, 0);
                self.hiddenTopMenuView.frame = hiddenMenuFrame;
                self.hiddenTopMenuView.alpha = 0;
            }];
        }
        
        
    }
    
    toggler += 1;
}

- (IBAction)requestForPhotos:(id)sender
{
    
    [UIView animateWithDuration:0.2 animations:^{
        CGRect hiddenMenuFrame = CGRectMake(0, 0, 320, 0);
        self.hiddenTopMenuView.frame = hiddenMenuFrame;
        self.hiddenTopMenuView.alpha = 0;

    } completion:^(BOOL finished) {
        
        // Actual code to request for photos
        /*if ([[AppHelper userStatus] isEqualToString:kSUBA_USER_STATUS_ANONYMOUS]) {
            [UIView animateWithDuration:.5 animations:^{
                self.createAccountView.alpha = 1;
                self.noActionLabel.text = CREATE_ACCOUNT_TO_SEE_MEMBERS;
                //self.navigationController.navigationBarHidden = YES;
            }];
        }else{*/
        
            [self performSegueWithIdentifier:@"AlbumMembersSegue" sender:self.spotID];
        //}
    }];
    
    toggler += 1;
}


- (IBAction)shareStream:(id)sender
{
    [UIView animateWithDuration:0.2 animations:^{
        CGRect hiddenMenuFrame = CGRectMake(0, 0, 320, 0);
        self.hiddenTopMenuView.frame = hiddenMenuFrame;
        self.hiddenTopMenuView.alpha = 0;
        
    } completion:^(BOOL finished) {
        // Actual code to share Share stream
        /*if ([[AppHelper userStatus] isEqualToString:kSUBA_USER_STATUS_ANONYMOUS]) {
            [UIView animateWithDuration:.5 animations:^{
                self.createAccountView.alpha = 1;
                self.noActionLabel.text = CREATE_ACCOUNT_TO_SHARE_STREAM;
            }];
        }else{*/
        
            // Present Action Sheet
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Share this stream" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Via Facebook",@"Via Twitter",@"Via Email", nil];
        
         actionSheet.tag = 7000;
        [actionSheet showInView:self.view];
        
            //[self share:kSpot Sender:sender];
        //}
    }];
    toggler += 1;
}

- (IBAction)showStreamSettings:(id)sender
{
    [UIView animateWithDuration:0.2 animations:^{
        CGRect hiddenMenuFrame = CGRectMake(0, 0, 320, 0);
        self.hiddenTopMenuView.frame = hiddenMenuFrame;
        self.hiddenTopMenuView.alpha = 0;
        
    } completion:^(BOOL finished) {
        // Actual code to show stream settings
        /*if ([[AppHelper userStatus] isEqualToString:kSUBA_USER_STATUS_ANONYMOUS]) {
            [UIView animateWithDuration:.5 animations:^{
                self.createAccountView.alpha = 1;
                self.noActionLabel.text = CREATE_ACCOUNT_TO_STREAM_SETTINGS;
                //self.navigationController.navigationBarHidden = YES;
            }];
        }
         else{*/
            [self performSegueWithIdentifier:@"SpotSettingsSegue" sender:self.spotID];
        //}
    }];
    toggler += 1;
}


#pragma mark - Create Account tins
- (IBAction)signUpWithEmailOptionChosen:(id)sender
{
    // Transition from create Account View to Sign up details view with left animation
    [UIView transitionWithView:self.createAccountOptionsView duration:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
        
        CGRect newFrame = CGRectMake(0, 0, 320, 440);
        CGRect newFrameForCreateAccountOptionsView = CGRectMake(-340, 0, 320, 440);
        //self.createAccountOptionsView.alpha = 0;
        self.createAccountOptionsView.frame = newFrameForCreateAccountOptionsView;
        //self.signUpWithEmailView.alpha = 1;
        self.signUpWithEmailView.frame = newFrame;
        
    } completion:^(BOOL finished) {
        
        int64_t delayInSeconds = 0.5;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            
            [self.firstNameField becomeFirstResponder];
            
        });
    }];
}

- (void)dismissCreateAccountPopUp
{
    [UIView animateWithDuration:.5 animations:^{
        self.createAccountView.alpha = 0;
        //self.navigationController.navigationBarHidden = NO;
    }];
}

- (IBAction)dismissCreateSubaAccountScreen:(id)sender
{
    [self dismissCreateAccountPopUp];
}

- (IBAction)dismissSignUpWithEmailView:(id)sender
{
    [self.signUpWithEmailView setContentOffset:CGPointMake(0.0f, 0.0f) animated:YES];
    [self.firstNameField resignFirstResponder];
    [self.lastNameField resignFirstResponder];
    [self.usernameField resignFirstResponder];
    
    int64_t delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){

        [UIView transitionWithView:self.signUpWithEmailView duration:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
        
            CGRect newFrame = CGRectMake(0, 0, 320, 440);
            CGRect newFrameForSignUpWithEmailView = CGRectMake(320, 0, 320, 440);
            self.signUpWithEmailView.frame = newFrameForSignUpWithEmailView;
            self.createAccountOptionsView.frame = newFrame;
        } completion:nil];
  });
}

- (IBAction)showFinalSignUpWithEmailView:(id)sender
{
    [self.signUpWithEmailView setContentOffset:CGPointMake(0.0f, 0.0f) animated:YES];
    [self.firstNameField resignFirstResponder];
    [self.lastNameField resignFirstResponder];
    [self.usernameField resignFirstResponder];
    
    int64_t delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        
        [UIView transitionWithView:self.signUpWithEmailView duration:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
        
            CGRect newFrame = CGRectMake(0, 0, 320, 440);
            CGRect newFrameForSignUpWithEmailView = CGRectMake(-320, 0, 320, 440);
            self.signUpWithEmailView.frame = newFrameForSignUpWithEmailView;
            self.finalSignUpWithEmailView.frame = newFrame;
        
        } completion:^(BOOL finished){
        
        int64_t delayInSeconds = .5;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self.emailField becomeFirstResponder];
        });
            
      }];
   });
}

- (IBAction)dismissFinalSignUpView:(id)sender
{
    [self.finalSignUpWithEmailView setContentOffset:CGPointMake(0.0f, 0.0f) animated:YES];
    
    [self.emailField resignFirstResponder];
    [self.passwordField resignFirstResponder];
    [self.reTypePasswordField resignFirstResponder];
    
    int64_t delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        
        [UIView transitionWithView:self.finalSignUpWithEmailView duration:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
            
            CGRect newFrame = CGRectMake(0, 0, 320, 440);
            CGRect newFrameForSignUpWithEmailView = CGRectMake(320, 0, 320, 440);
            self.finalSignUpWithEmailView.frame = newFrameForSignUpWithEmailView;
            //self.signUpWithEmailView.alpha = 0;
            //self.createAccountOptionsView.alpha = 1;
            self.signUpWithEmailView.frame = newFrame;
            
        } completion:^(BOOL finished) {
           //self.firstNameField
        }];
        
    });
    
    
}


- (IBAction)manualSignUpDetailsDoneAction:(id)sender
{
    if (![self.reTypePasswordField.text isEqualToString:self.passwordField.text]) {
        [AppHelper showAlert:@"Password Error" message:@"Your passwords do not match" buttons:@[@"Will check again"] delegate:nil];
    }else{
        [self.signUpSpinner startAnimating];
        
        [self.passwordField resignFirstResponder];
        [self.reTypePasswordField resignFirstResponder];
        
        /*Save these in a model
         self.firstName = self.firstNameField.text;
         self.lastName = self.lastNameField.text;
         self.userEmail = self.emailField.text;
        
         self.userName = self.usernameField.text;
         self.userPasswordConfirm = self.passwordField.text;
        */
        
        [self checkAllTextFields];
    }
}


- (void)checkAllTextFields
{
    if (![self.reTypePasswordField.text isEqualToString:@""]) {
        
        if (![self.emailField.text isEqualToString:@""] && ![self.usernameField.text isEqualToString:@""]
            && ![self.firstNameField.text isEqualToString:@""] && ![self.lastNameField.text isEqualToString:@""]
            && ![self.passwordField.text isEqualToString:@""]){
            // Now all the fields are not empty
            
            //1. Let's first check whether the email is correct
            if ([AppHelper validateEmail:self.emailField.text]){
                // If the email is correct,begin to process everything else
                
                
                if ([self.usernameField.text isEqualToString:self.passwordField.text]){
                    
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Yet to sign up" message:@"Your username and password appear to be the same" delegate:nil cancelButtonTitle:@"I'll check" otherButtonTitles:nil];
                    
                    [alertView show];
                }else{
                    
                    self.firstName = [self.firstNameField.text
                                      stringByReplacingOccurrencesOfString:kEMPTY_STRING_WITH_SPACE withString:kEMPTY_STRING_WITHOUT_SPACE];
                    
                    self.lastName = [self.lastNameField.text stringByReplacingOccurrencesOfString:kEMPTY_STRING_WITH_SPACE withString:kEMPTY_STRING_WITHOUT_SPACE];
                    
                    self.userName = [self.usernameField.text stringByReplacingOccurrencesOfString:kEMPTY_STRING_WITH_SPACE withString:kEMPTY_STRING_WITHOUT_SPACE];
                    
                    self.userEmail = [self.emailField.text stringByReplacingOccurrencesOfString:kEMPTY_STRING_WITH_SPACE withString:kEMPTY_STRING_WITHOUT_SPACE];
                    
                    self.userPasswordConfirm = [self.reTypePasswordField.text stringByReplacingOccurrencesOfString:kEMPTY_STRING_WITH_SPACE withString:kEMPTY_STRING_WITHOUT_SPACE];
                    
                    self.userPassword = [self.passwordField.text stringByReplacingOccurrencesOfString:kEMPTY_STRING_WITH_SPACE withString:kEMPTY_STRING_WITHOUT_SPACE];
                    
                    NSDictionary *params = @{
                                             @"userId" : [AppHelper userID],
                                             @"firstName":self.firstName,
                                             @"lastName":self.lastName,
                                             @"email": self.userEmail,
                                             @"pass":self.userPassword,
                                             @"userName":self.userName,
                                             @"fbLogin" : NATIVE
                                             };
                    
                    
                    [AppHelper createUserAccount:params WithType:NATIVE completion:^(id results, NSError *error) {
                        if (!error) {
                            [self.signUpSpinner stopAnimating];
                            [Flurry logEvent:@"Account_Confirmed_Manual"];
                            [AppHelper savePreferences:results];
                            DLog(@"User preferences - %@",[AppHelper userPreferences]);
                            [self performSelector:@selector(dismissCreateAccountPopUp)];
                            // Update user info
                           
                        }else{
                            [AppHelper showAlert:results[STATUS] message:results[@"message"] buttons:@[@"I'll check again"] delegate:nil];
                        }
                    }];
                    
                }
            }else{
                UIAlertView *alertView = [[UIAlertView alloc]
                                          initWithTitle:@"Email check"
                                          message:@"We could not verfiy your email address format.Please check again"
                                          delegate:nil
                                          cancelButtonTitle:@"I'll check"
                                          otherButtonTitles:nil];
                
                [alertView show];
            }
        }
        
    }
    
}

#pragma mark - DBCameraViewControllerDelegate
- (void) camera:(id)cameraViewController didFinishWithImage:(UIImage *)image withMetadata:(NSDictionary *)metadata
{
    UIImageWriteToSavedPhotosAlbum(image, self, @selector(imageSavedToPhotosAlbum: didFinishSavingWithError: contextInfo:), nil);
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    [dateFormatter setDateFormat:@"yyyy:MM:dd HH:mm:ss.SSSSSS"];
    NSString *timeStamp = [dateFormatter stringFromDate:[NSDate date]];
    NSString *trimmedString = [timeStamp stringByReplacingOccurrencesOfString:@" " withString:@""];
    trimmedString = [trimmedString stringByReplacingOccurrencesOfString:@"-" withString:@":"];
    trimmedString = [trimmedString stringByReplacingCharactersInRange:NSMakeRange([trimmedString length]-7, 7) withString:@""];
    
    [self resizePhoto:image towidth:1136.0f toHeight:640.0f
            completon:^(UIImage *compressedPhoto, NSError *error) {
                if (!error) {
                    NSData *imageData = UIImageJPEGRepresentation(compressedPhoto, 1.0);
                    
                    [self uploadPhoto:imageData WithName:trimmedString];
                }else DLog(@"Image resize error :%@",error);
                
            }];
    
    [cameraViewController restoreFullScreenMode];
    [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void) dismissCamera:(id)cameraViewController{
    [self dismissViewControllerAnimated:YES completion:nil];
    [cameraViewController restoreFullScreenMode];
}

- (void) openCamera
{
    DBCameraContainerViewController *cameraContainer = [[DBCameraContainerViewController alloc] initWithDelegate:self];
    [cameraContainer setFullScreenMode];
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:cameraContainer];
    [nav setNavigationBarHidden:YES];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)imageSavedToPhotosAlbum:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    
    if (!error) {
        //[AppHelper showNotificationWithMessage:@"Photo saved to gallery" type:CSNotificationViewStyleSuccess //inViewController:self completionBlock:^{
        
        DLog(@"Context info - %@",contextInfo);
    }
}


-(void)uploadingPhotoView:(BOOL)flag
{
    DLog(@"Uploading photo");
    self.uploadingPhoto.hidden = !flag;
    if (flag == YES) {
        [self.uploadingPhotoIndicator startAnimating];
    }else [self.uploadingPhotoIndicator stopAnimating];
}

- (void)downloadPhoto:(UIImageView *)destination withURL:(NSString *)imgURL downloadOption:(SDWebImageOptions)option
{
    DLog(@"number of subviews - %i",[destination.subviews count]);
    if ([destination.subviews count] == 1) {
        // Lets remove all subviews
        [[destination subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    }
    //if (destination.image == nil) {
        DACircularProgressView *progressView = [[DACircularProgressView alloc]
                                                initWithFrame:CGRectMake((destination.bounds.size.width/2) - 20, (destination.bounds.size.height/2) - 20, 40.0f, 40.0f)];
        progressView.thicknessRatio = .1f;
        progressView.roundedCorners = YES;
        progressView.trackTintColor = [UIColor lightGrayColor];
        progressView.progressTintColor = [UIColor whiteColor];
        [destination addSubview:progressView];
        
        [[S3PhotoFetcher s3FetcherWithBaseURL]
         downloadPhoto:imgURL to:destination
         placeholderImage:[UIImage imageNamed:@"newOverlay"]
         progressView:progressView
         downloadOption:option
         completion:^(id results, NSError *error){
             
             [progressView removeFromSuperview];
             if (!error) {
                 self.albumSharePhoto = (UIImage *)results;
             }else{
                 DLog(@"error - %@",error);
            }
             
         }];

    //}
    
}

@end
