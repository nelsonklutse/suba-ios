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
#import <QuartzCore/QuartzCore.h>
#import "PhotoStreamFooterView.h"
#import "PhotoStreamHeaderView.h"
#import "InvitesViewController.h"
#import "SBDoodleViewController.h"
#import <IonIcons.h>
#import <ionicons-codes.h>
#import "TermsViewController.h"
#import <Social/Social.h>
#import <DACircularProgressView.h>
#import <IDMPhotoBrowser.h>
#import <AviarySDK/AviarySDK.h>
#import "Branch.h"
#import "WhatsAppKit.h"
#import "CommentsViewController.h" 

typedef enum{
    kActionLike = 0,
    kActionEdit
}ActionPending;

typedef void (^PhotoResizedCompletion) (UIImage *compressedPhoto,NSError *error);
typedef void (^StandardPhotoCompletion) (CGImageRef standardPhoto,NSError *error);
typedef void (^SBFlipDoodleCompletionHandler) (BOOL didFlipDoodle);

#define SpotInfoKey @"SpotInfoKey"
#define SpotNameKey @"SpotNameKey"
#define SpotIdKey @"SpotIdKey"
#define SpotPhotosKey @"SpotPhotosKey"

@interface PhotoStreamViewController ()<UICollectionViewDataSource,UICollectionViewDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate,UIActionSheetDelegate,UIGestureRecognizerDelegate,MFMessageComposeViewControllerDelegate,UITextFieldDelegate,UIAlertViewDelegate,MFMailComposeViewControllerDelegate,AFPhotoEditorControllerDelegate>

{
    UIImage *selectedPhoto;
    NSIndexPath *selectedPhotoIndexPath;
    NSString *selectedPhotoId;
    PhotoStreamCell *selectedPhotoCell;
    NSArray *pendingActions;
    UILabel *titleView;
    NSData *imageToUpload;
    NSString *nameOfImageToUpload;
    BOOL didImageFinishUploading;
    BOOL isDoodling;
    NSString *branchURLforInviteToStream;
    NSString *branchURLforShareStream;
}


@property (strong,nonatomic) NSDictionary *photoInView;
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
@property (retain, nonatomic) IBOutlet UIProgressView *imageUploadProgressView;
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

- (IBAction)sortPhotosButtonTapped:(UIButton *)sender;

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
- (IBAction)showCommentsAction:(UIButton *)sender;

- (IBAction)showMembers:(id)sender;
- (IBAction)dismissCoachMark:(UIButton *)sender;

- (void)showHiddenMoreOptions;
- (void)prepareBranchURLforInvitingFriendsToStream;
- (void)prepareBranchURLforSharingStream;
- (void)sendSMSToRecipients:(NSMutableArray *)recipients;
- (NSString *)getRandomPINString:(NSInteger)length;
- (void)preparePhotoBrowser:(NSMutableArray *)photos;
- (void)createStandardImage:(CGImageRef)image completon:(StandardPhotoCompletion)completion;
- (void)deletePhotoAtIndexFromStream:(NSInteger)index;
- (void)uploadPhotos:(NSArray *)images;
- (void)upDateCollectionViewWithCapturedPhotos:(NSArray *)photoInfo;
- (void)showHiddenMenu:(UITapGestureRecognizer *)sender;
- (void)savePhoto:(UIImage *)imageToSave;
- (void)photoCardTapped:(UITapGestureRecognizer *)sender;
- (void)share:(Mutant)objectOfInterest Sender:(UIButton *)sender;
- (void)savePhotoToCustomAlbum:(UIImage *)photo;
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
- (void)uploadingPhotoView:(BOOL)flag;
- (void)executePendingAction:(ActionPending)pendingAction;
- (void)doodlePhoto:(PhotoStreamCell *)cell;
- (void)findAndShowPhoto:(NSString *)photoToShow;
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
    titleView = [[UILabel alloc] initWithFrame:titleFrame];
    titleView.backgroundColor = [UIColor clearColor];
    titleView.textAlignment = NSTextAlignmentCenter;
    titleView.textColor = [UIColor whiteColor];
    titleView.shadowColor = [UIColor clearColor];
    
    //DLog(@"Setting up titleView with stream name - %@",self.spotName);
    //titleView.text = (self.spotName) ? self.spotName : @"Stream";
    titleView.text = @""; 
    //[titleView sizeToFit];
    titleView.adjustsFontSizeToFitWidth = YES;
    
    [_headerTitleSubtitleView addSubview:titleView];
    
    CGRect subtitleFrame = CGRectMake((160/2), 25, 160, 44-25);
    UILabel *subtitleView = [[UILabel alloc] initWithFrame:subtitleFrame];
    [IonIcons label:subtitleView setIcon:icon_arrow_down_b size:20.0f color:[UIColor whiteColor] sizeToFit:YES];
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
    [self setUpRightBarButtonItems];
    
    isDoodling = NO;
    
    // Load Aviary stuff so user doesn't have to wait longer to see the editor
    [AFOpenGLManager beginOpenGLLoad];
    
    
    CGRect hiddenMenuFrame = CGRectMake(0, 0, 320, 0);
    self.hiddenTopMenuView.alpha = 0;
    self.hiddenTopMenuView.frame = hiddenMenuFrame;
    self.createAccountView.alpha = 0;
    self.firstTimeNotificationScreen.alpha = 0;
    
    self.navigationController.navigationBar.topItem.title = (self.spotName)?:@"";
    
    // Do any additional setup after loading the view.
    self.noPhotosView.hidden = YES;
    //[self setUpTitleView];
    self.library = [[ALAssetsLibrary alloc] init];
    
    // Photostream is launching from an Activity Screen
    if(!self.photos && !self.spotName && self.numberOfPhotos == 0 && self.spotID){
        // We are coming from an activity screen
        DLog(@"Stream id - %@ coz we're coming from the activity screen",self.spotID);
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
        
        UIAlertView *addfirstPhotAlert =  [[UIAlertView alloc] initWithTitle:@"Add first photo" message:@"Add first photo so your friends can find this stream in \"Nearby Streams\"" delegate:self cancelButtonTitle:@"Later" otherButtonTitles:@"Add first photo",nil];
         addfirstPhotAlert.tag = 201;
         [addfirstPhotAlert show];
                                           
    }
    
    if (![self.isUserMemberOfStream isEqualToString:@"YES"]) { // If the user is not a member of this stream
        DLog(@"User is not a member of this stream so we are joining");
            [[User currentlyActiveUser] joinSpot:self.spotID completion:^(id results, NSError *error) {
                if (!error){
                    // Ask main stream to reload
                    DLog(@"Stream Info: %@",results);
                    [[NSNotificationCenter defaultCenter]
                     postNotificationName:kUpdateStreamNotification object:@{@"streamId" : results[@"spotId"]}];
                }else{
                    DLog(@"Error - %@",error);
                }
            }];

        }


    if(self.spotID && !self.spotInfo){
       [self loadSpotInfo:self.spotID];
    }else DLog(@"Spot Info already loaded here: %@",self.spotInfo);
    
}


-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.createAccountView.alpha = 0;
    //isDoodling = NO;
}


-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.navigationController.navigationBar.topItem.title = @"";
    [AppHelper increasePhotoStreamEntries];
    
    // Prepare branch
    if (self.spotInfo) {
        [self prepareBranchURLforInvitingFriendsToStream];
    }
}


-(IBAction)sortPhotosButtonTapped:(UIButton *)sender
{
    DLog(@"Sorting photos soon");
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
           
           NSArray *thePhotos = [NSMutableArray arrayWithArray:[allPhotos sortedArrayUsingDescriptors:sortDescriptors]];
           self.photos = [NSMutableArray arrayWithArray:[NSOrderedSet orderedSetWithArray:thePhotos].array];
           
           //DLog(@"Photos - %@",results);
           if ([self.photos count] > 0) {
               //DLog(@"Photos in spot - %@",self.photos);
               self.noPhotosView.hidden = YES;
               self.photoCollectionView.hidden = NO;
               [self.photoCollectionView reloadData];
               
               
               if (self.shouldShowPhoto == YES || self.shouldShowDoodle == YES){
                   //[self setUpTitleView];
                   // Also find photo
                   DLog(@"Just when we are about to pass photo to show - %@",self.photoToShow);
                   [self findAndShowPhoto:self.photoToShow];
               }
               
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
                //self.navItemTitle.text = self.spotName;
                
                DLog(@"Stream Name - %@",self.spotName);
                titleView.text = self.spotName;
                
                
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
    return [self.photos count];
}


-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PhotoStreamCell *photoCardCell = nil;
    static NSString *cellIdentifier = @"PhotoStreamCell";
    
    if ([[AppHelper kindOfDeviceScreen] isEqualToString:kIPHONE_4_SCREEN]){
        // Use ipHone 4 screen cell
        photoCardCell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
        //CGRect footerFrame  = CGRectMake(0, 367, 285, 67);
        //photoCardCell.photoCardFooterView.frame = footerFrame;
    }else{
        // Bigger phone
        photoCardCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"iPHONEBIGPhotoStreamCell" forIndexPath:indexPath];
    }
    
    // Set up the Gesture Recognizers
    UITapGestureRecognizer *oneTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(photoCardTapped:)];
    
    [oneTapRecognizer setNumberOfTapsRequired:1];
    [oneTapRecognizer setDelegate:self];
    
    UITapGestureRecognizer *oneTapRecognizer1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(photoCardTapped:)];
    
    [oneTapRecognizer1 setNumberOfTapsRequired:1];
    [oneTapRecognizer1 setDelegate:self];

    
    
    NSString *pictureTakerName = self.photos[indexPath.row][@"pictureTaker"];
    
    // Give border around header View
    [photoCardCell setBorderAroundView:photoCardCell.headerView];
    [photoCardCell setBorderAroundView:photoCardCell.footerView];
    
    photoCardCell.pictureTakerView.layer.borderWidth = 1;
    photoCardCell.pictureTakerView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    photoCardCell.pictureTakerView.layer.cornerRadius = 10;
    photoCardCell.pictureTakerView.clipsToBounds = YES;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10000), dispatch_get_main_queue(),^{
        NSString *photoLiked = self.photos[indexPath.item][@"userLikedPhoto"];
        if ([photoLiked isEqualToString:@"YES"]) {
            [photoCardCell.likePhotoButton setSelected:YES];
        }else{
           [photoCardCell.likePhotoButton setSelected:NO];
        }
    });
    
    [photoCardCell makeInitialPlaceholderView:photoCardCell.pictureTakerView name:pictureTakerName];
    //DLog(@"PicTakername - %@",pictureTakerName);
    
    NSString *photoURLstring = self.photos[indexPath.item][@"s3name"];
    NSString *photoRemixURLString = self.photos[indexPath.item][@"s3RemixName"];
   
    if(self.photos[indexPath.row][@"pictureTakerPhoto"]){
        
        NSString *pictureTakerPhotoURL = self.photos[indexPath.row][@"pictureTakerPhoto"];
        [photoCardCell fillView:photoCardCell.pictureTakerView WithImage:pictureTakerPhotoURL];
    }
    
    photoCardCell.pictureTakerName.text = pictureTakerName;
    
    // Fill the number of likes
    if ([self.photos[indexPath.row][@"likes"] integerValue] >= 1) {
       photoCardCell.numberOfLikesLabel.text = self.photos[indexPath.item][@"likes"];
        
    }else{
        photoCardCell.numberOfLikesLabel.text = kEMPTY_STRING_WITHOUT_SPACE;
    }
    
    // Fill the number of comments
    if ([self.photos[indexPath.row][@"comments"] integerValue] >= 1) {
        photoCardCell.numberOfCommentsLabel.text = self.photos[indexPath.item][@"comments"];
        
    }else{
        photoCardCell.numberOfCommentsLabel.text = kEMPTY_STRING_WITHOUT_SPACE;
    }
    
    // Add the gesture recognizer to original photo cell
    [photoCardCell.photoCardImage setUserInteractionEnabled:YES];
    [photoCardCell.photoCardImage setMultipleTouchEnabled:YES];
    [photoCardCell.photoCardImage addGestureRecognizer:oneTapRecognizer];
    
    // Add the gesture recognizer to remix photo cell
    [photoCardCell.remixedImageView setUserInteractionEnabled:YES];
    [photoCardCell.remixedImageView setMultipleTouchEnabled:YES];
    [photoCardCell.remixedImageView addGestureRecognizer:oneTapRecognizer1];
    
    
    // Download photo card image
    [self downloadPhoto:photoCardCell.photoCardImage
                withURL:photoURLstring
         downloadOption:SDWebImageProgressiveDownload];
    
    if (photoRemixURLString){
        
       
        [self downloadPhoto:photoCardCell.remixedImageView
                    withURL:photoRemixURLString
             downloadOption:SDWebImageRefreshCached];
        
     }else{
        photoCardCell.remixedImageView.image = nil;
    }
    
    if ([self.photos[indexPath.item][@"remixers"] integerValue] <= 0){
        photoCardCell.remixedImageView.alpha = 0;
        photoCardCell.photoCardImage.alpha = 1;
        //photoCardCell.viewDoodleContainer;
        photoCardCell.viewDoodleContainer.hidden = YES;
        //photoCardCell.showCommentsActionButton.hidden = YES;
        photoCardCell.numberOfRemixersLabel.hidden = YES;
    }else{
        //DLog(@"There are remixers for this photo");
        NSInteger remixers = [self.photos[indexPath.item][@"remixers"] integerValue];
        
        //photoCardCell.viewDoodleContainer.enabled = YES;
        photoCardCell.viewDoodleContainer.hidden = NO;
        
        //photoCardCell.showCommentsActionButton.hidden = NO;
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
    
    if (kind == UICollectionElementKindSectionHeader){
       
       PhotoStreamHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"PhotoStreamHeader" forIndexPath:indexPath];
        
        //[headerView.headerViewContainer showRealTimeBlurWithBlurStyle:XHBlurStyleTranslucent];
        
        [headerView.addPhotoButton addTarget:self action:@selector(cameraButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        [headerView.inviteFriendsButton addTarget:self action:@selector(requestForPhotos:) forControlEvents:UIControlEventTouchUpInside];
        
        [headerView.sortStreamButton addTarget:self action:@selector(sortPhotosButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        if (self.spotInfo) {
            DLog(@"Stream Info: %@",self.spotInfo);
            
            int numberOfPhotos = [self.spotInfo[@"photos"] intValue];
            
            headerView.streamNameLabel.text = self.spotInfo[@"spotName"];
            headerView.streamLocationLabel.text = self.spotInfo[@"venue"];
            headerView.numberOfPhotosLabel.text = self.spotInfo[@"photos"];
            
            if (numberOfPhotos == 1) {
                headerView.photosLabel.text = @"PHOTO";
            }else {
                headerView.photosLabel.text = @"PHOTOS";
            }
            
            if (self.spotInfo[@"members"]){
                if ([self.spotInfo[@"members"] isKindOfClass:[NSArray class]]) {
                    NSArray *members = self.spotInfo[@"members"];
                    DLog(@"Stream members are %i",[members count]);
                    if ([members count] == 1) {
                        headerView.membersLabel.text = @"MEMBER";
                    }else if ([members count] > 1){
                        headerView.membersLabel.text = @"MEMBERS";
                    }
                    
                    headerView.numberOfMembers.text = [NSString stringWithFormat:@"%i",[members count]];
                }else if ([self.spotInfo[@"members"] isKindOfClass:[NSString class]]){
                    int numOfMembers = [self.spotInfo[@"members"] intValue];
                    if (numOfMembers == 1) {
                        headerView.membersLabel.text = @"MEMBER";
                    }else{
                        headerView.membersLabel.text = @"MEMBERS";
                    }
                    headerView.numberOfMembers.text = self.spotInfo[@"members"];
                }
                
                
                
            }
            
            
        }
        
        reusableview = headerView;
        
    }else if (kind == UICollectionElementKindSectionFooter) {
        PhotoStreamFooterView *footerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"PhotoStreamFooter" forIndexPath:indexPath];
        
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
   selectedPhotoIndexPath = indexPath;
}


#pragma mark - Methods
-(IBAction)showMembers:(id)sender
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
            
            [self resamplePhotoInfo:selectedPhotoInfo
                               flag:@"NO"
                      numberOfLikes:results[@"likes"]
                            atIndex:indexPath.item];
            
            //Ask main stream to reload
            [[NSNotificationCenter defaultCenter]
             postNotificationName:kUserReloadStreamNotification object:nil];
            if ([results[@"likes"] intValue] == 0) {
                photoCardCell.numberOfLikesLabel.hidden = YES;
            }else photoCardCell.numberOfLikesLabel.text = results[@"likes"];
            
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
   
    if ([[AppHelper userStatus] isEqualToString:kSUBA_USER_STATUS_ANONYMOUS]) {
        [UIView animateWithDuration:.5 animations:^{
            self.createAccountView.alpha = 1;
            self.noActionLabel.text = CREATE_ACCOUNT_TO_LIKE_PHOTOS;
        }];
    }else{
        
        UIButton *likeButtonAction = (UIButton *)sender;
        
        PhotoStreamCell *cell = (PhotoStreamCell *)likeButtonAction.superview.superview.superview;
        NSIndexPath *indexPath = [self.photoCollectionView indexPathForCell:cell];
        selectedPhotoIndexPath = indexPath;
        
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


/*- (void)resizePhoto:(UIImage*) image towidth:(float) width toHeight:(float) height completon:(PhotoResizedCompletion)completion
{
       dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
         BOSImageResizeOperation* op = [[BOSImageResizeOperation alloc] initWithImage:image];
          [op start];
        
        UIImage* smallerImage = op.result;
        dispatch_async(dispatch_get_main_queue(),^{
            completion(smallerImage,nil);
        });
    });
}*/


- (IBAction)cameraButtonTapped:(id)sender
{
    [self showPhotoOptions];
}



-(void)showReportOptions
{
    UIActionSheet *actionsheet = [[UIActionSheet alloc] initWithTitle:@"Why're you reporting photo?"
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@" This photo is sexually explicit",@"This photo is unrelated",nil];
    actionsheet.tag = 2000;
    [actionsheet showInView:self.view];
  
}


- (IBAction)showMoreActions:(UIButton *)sender
{
    PhotoStreamCell *cell = (PhotoStreamCell *)sender.superview.superview.superview;
    NSIndexPath *indexpath = [self.photoCollectionView indexPathForCell:cell];
    self.photoInView = self.photos[indexpath.row];
    selectedPhoto = cell.photoCardImage.image;
    
    @try {
        NSString *pictureTakerId = self.photos[indexpath.item][@"pictureTakerId"];
        
        if ([[AppHelper userID] isEqualToString:pictureTakerId]) {
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
    @catch (NSException *exception) {}
    @finally {}
    
}



-(void)showPhotoOptions
{
    UIActionSheet *action = [[UIActionSheet alloc] initWithTitle:@"Add photos to this stream" delegate:self cancelButtonTitle:@"Not Now" destructiveButtonTitle:nil otherButtonTitles:@"Take New Photo",@"Choose Existing  Photo", nil];
    action.tag = 403;
    [action showInView:self.view];
}

-(void)resamplePhotoInfo:(NSDictionary *)info flag:(NSString *)flag numberOfLikes:(NSString *)likes atIndex:(NSInteger)selectedIndex
{
    [self.photos removeObjectAtIndex:selectedIndex];
    NSMutableDictionary *mutablePhotoInfo = [NSMutableDictionary dictionaryWithDictionary:info];
    
    mutablePhotoInfo[@"userLikedPhoto"] = flag;
    mutablePhotoInfo[@"likes"] = likes;
    
    [self.photos insertObject:mutablePhotoInfo atIndex:selectedIndex];

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
    
    activityVC.completionHandler = ^(NSString *activityType, BOOL completed){
        if (completed) {
            DLog(@"Completed with type: %@",activityType);
        }else{
            DLog(@"Dismissed");
        }
    };
    
    [self presentViewController:activityVC animated:YES completion:nil];
  
}


-(void)savePhotoToCustomAlbum:(UIImage *)photo
{
    [self.library saveImage:photo toAlbum:@"Suba" completion:^(NSURL *assetURL, NSError *error) {
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


/*- (void)pickAssets
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
           // DLog(@"Size of image - %fKB",(unsigned long)[imageData length]/1000.0f);
            [self uploadPhoto:imageData WithName:trimmedString];
        }];
        
           }else if([assets count] > 1){ // User selected more than one photo
        [self uploadPhotos:assets];
    }else if([assets count] == 0){
        [AppHelper showAlert:@"Add Photo"
                     message:@"You did not select a photo to add to the stream"
                     buttons:@[@"OK"] delegate:nil];
    }
    
}*/



-(void)pickImage:(id)sender
{
    //DLog(@"Source Type - %@",sender);
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
        
        if ([sender intValue] == kTakeCamera) {
            //[self openDBCamera];
            [self openNativeCamera:UIImagePickerControllerSourceTypeCamera];
        }else if ([sender intValue] == kGallery){
            [self openNativeCamera:UIImagePickerControllerSourceTypePhotoLibrary];
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
    if (alertView.tag == 400){
        if (buttonIndex == 1) {
            // Retry image upload now
            DLog(@"Retrying image upload");
            if (imageToUpload && nameOfImageToUpload) {
                [self uploadPhoto:imageToUpload WithName:nameOfImageToUpload];
            }
            
        }
    }else if (alertView.tag == 401){
     // Reload stream images
        if (buttonIndex == 1){
            
            DLog(@"Reloading stream");
            [self loadSpotImages:self.spotID];
        }
    }else if(alertView.tag == 3000){
        if (buttonIndex == 1) {
            NSInteger index = [self.photos indexOfObject:self.photoInView];
            [self deletePhotoAtIndexFromStream:index];
        }
    }else if (alertView.tag == 201){
        if (buttonIndex == 1) {
           [self showPhotoOptions];
        }
    }
}


#pragma mark - UIActionSheet Delegate Methods
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // Get branch link to share this stream
    
    
    if (actionSheet.tag == 7000){
        // Share the stream
         //NSString *randomString = [self getRandomPINString:5];
        //NSString *shareText = nil;
        
        if (buttonIndex == 0) {
            //We're sharing on facebook
            if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]){
                SLComposeViewController *composeVC = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
            
                [composeVC addImage:(selectedPhoto ? selectedPhoto : nil)];
                
                
                if (branchURLforShareStream) {
                    NSString *shareText = [NSString stringWithFormat:@"All the photos in my %@ group photo stream on Suba at %@",self.spotName,branchURLforShareStream];
                    [composeVC addImage:(selectedPhoto ? selectedPhoto : nil)];
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
                    
                    
                }else{
                    NSString *senderName = nil;
                    Branch *branch = [Branch getInstance:@"55726832636395855"];
                    if ([AppHelper firstName].length > 0 && [AppHelper lastName].length > 0) {
                        senderName = [NSString stringWithFormat:@"%@ %@",[AppHelper firstName],[AppHelper lastName]];
                        
                    }else{
                        
                        senderName = [AppHelper userName];
                    }
                    
                    
                    if ([AppHelper profilePhotoURL] == NULL | [[AppHelper profilePhotoURL] class] == [NSNull class]) {
                        [AppHelper setProfilePhotoURL:@"-1"];
                    }
                    
                    NSDictionary *dict = @{
                                           @"desktop_url" : @"http://app.subaapp.com/streams/share",
                                           @"streamId":self.spotInfo[@"spotId"],
                                           @"photos" : self.spotInfo[@"photos"],
                                           @"streamName":self.spotInfo[@"spotName"],
                                           @"sender": senderName,
                                           @"streamCode" : self.spotInfo[@"spotCode"],
                                           @"senderPhoto" : [AppHelper profilePhotoURL]};
                    
                    
                    NSMutableDictionary *streamDetails = [NSMutableDictionary dictionaryWithDictionary:dict];
                    
                    [branch getShortURLWithParams:streamDetails andTags:nil andChannel:@"share_stream" andFeature:BRANCH_FEATURE_TAG_SHARE andStage:nil andCallback:^(NSString *url){
                        
                        DLog(@"URL from Branch: %@",url);
                        branchURLforShareStream = url;
                        NSString *shareText = [NSString stringWithFormat:@"All the photos in my %@ group photo stream on Suba at %@",self.spotName,branchURLforShareStream];
                        [composeVC addImage:(selectedPhoto ? selectedPhoto : nil)];
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
                        
                        
                    }];
                    
                }

                
                
                
        }
            
        }else if (buttonIndex == 1){
            if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
                SLComposeViewController *composeVC = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
                
                if (branchURLforShareStream) {
                    NSString *shareText = [NSString stringWithFormat:@"All the photos in my %@ group photo stream via @SubaPhotoApp %@",self.spotName,branchURLforShareStream];
                    
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

                    
                }else{
                    
                    NSString *senderName = nil;
                    Branch *branch = [Branch getInstance:@"55726832636395855"];
                    if ([AppHelper firstName].length > 0 && [AppHelper lastName].length > 0) {
                        senderName = [NSString stringWithFormat:@"%@ %@",[AppHelper firstName],[AppHelper lastName]];
                        
                    }else{
                        
                        senderName = [AppHelper userName];
                    }
                    
                    if ([AppHelper profilePhotoURL] == NULL | [[AppHelper profilePhotoURL] class] == [NSNull class]) {
                        [AppHelper setProfilePhotoURL:@"-1"];
                    }
                    
                    NSDictionary *dict = @{
                                           @"desktop_url" : @"http://app.subaapp.com/streams/share",
                                           @"streamId":self.spotInfo[@"spotId"],
                                           @"photos" : self.spotInfo[@"photos"],
                                           @"streamName":self.spotInfo[@"spotName"],
                                           @"sender": senderName,
                                           @"streamCode" : self.spotInfo[@"spotCode"],
                                           @"senderPhoto" : [AppHelper profilePhotoURL]};
                    
                    
                    NSMutableDictionary *streamDetails = [NSMutableDictionary dictionaryWithDictionary:dict];
                    
                    [branch getShortURLWithParams:streamDetails andTags:nil andChannel:@"share_stream" andFeature:BRANCH_FEATURE_TAG_SHARE andStage:nil andCallback:^(NSString *url){
                        
                        DLog(@"URL from Branch: %@",url);
                        branchURLforShareStream = url;
                        NSString *shareText = [NSString stringWithFormat:@"All the photos in my %@ group photo stream via @SubaPhotoApp %@",self.spotName,branchURLforShareStream];
                        
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
                    }];
                    
                }
            }
        }else if (buttonIndex == 2){
            MFMailComposeViewController *mailComposer = [[MFMailComposeViewController alloc] init];
            mailComposer.mailComposeDelegate = self;
            [mailComposer setSubject:[NSString stringWithFormat:@"Photos from \"%@\" on Suba",self.spotName]];
            
            if (branchURLforShareStream) {
                NSString *shareText = [NSString stringWithFormat:@"All the photos in my %@ group photo stream via @SubaPhotoApp %@",self.spotName,branchURLforShareStream];
                
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
                
            }else{
                
                NSString *senderName = nil;
                Branch *branch = [Branch getInstance:@"55726832636395855"];
                if ([AppHelper firstName].length > 0 && [AppHelper lastName].length > 0) {
                    senderName = [NSString stringWithFormat:@"%@ %@",[AppHelper firstName],[AppHelper lastName]];
                    
                }else{
                    
                    senderName = [AppHelper userName];
                }
                
                if ([AppHelper profilePhotoURL] == NULL | [[AppHelper profilePhotoURL] class] == [NSNull class]) {
                    [AppHelper setProfilePhotoURL:@"-1"];
                }
                
                NSDictionary *dict = @{
                                       @"desktop_url" : @"http://app.subaapp.com/streams/share",
                                       @"streamId":self.spotInfo[@"spotId"],
                                       @"photos" : self.spotInfo[@"photos"],
                                       @"streamName":self.spotInfo[@"spotName"],
                                       @"sender": senderName,
                                       @"streamCode" : self.spotInfo[@"spotCode"],
                                       @"senderPhoto" : [AppHelper profilePhotoURL]};
                
                
                NSMutableDictionary *streamDetails = [NSMutableDictionary dictionaryWithDictionary:dict];
                
                [branch getShortURLWithParams:streamDetails andTags:nil andChannel:@"share_stream" andFeature:BRANCH_FEATURE_TAG_SHARE andStage:nil andCallback:^(NSString *url){
                    
                    DLog(@"URL from Branch: %@",url);
                    branchURLforShareStream = url;
                    NSString *shareText = [NSString stringWithFormat:@"All the photos in my %@ group photo stream via @SubaPhotoApp %@",self.spotName,branchURLforShareStream];
                    
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
                }];
            }
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
            deleteAlert.tag = 3000;
            [deleteAlert show];
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
            }
            
            NSDictionary *params = @{
                                     @"photoId":self.photoInView[@"id"],
                                     @"spotId" : self.spotID,
                                     @"pictureTakerName" : self.photoInView[@"pictureTaker"],
                                     @"reporterId" : [AppHelper userID],
                                     @"reportType" : reportType
                                     };
            
            
            [self reportPhoto:params];
      
    }else if(actionSheet.tag == 403){
    
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
    // Resetting the status bar here
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
    
    [Flurry logEvent:@"Photo_Taken"];
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    
    DLog(@"UIImagePickerInfo: %@",[info debugDescription]);
    if (info[UIImagePickerControllerMediaMetadata]) {
        NSMutableDictionary *imageMetaData = info[UIImagePickerControllerMediaMetadata];
        DLog(@"UIImagePickerControllerMediaMetadata: %@",info[UIImagePickerControllerMediaMetadata]);
        [self.library writeImageToSavedPhotosAlbum:image.CGImage metadata:imageMetaData completionBlock:^(NSURL *assetURL, NSError *error) {
            if (!error) {
                DLog(@"Image saved in - %@",assetURL.description);
            }else{
                DLog(@"Error - %@",error);
            }
            
        }];
    }
    
    NSData *img = UIImageJPEGRepresentation(image, 1.0);
    
    DLog(@"Size of image - %fKB",[img length]/1024.0f);
    [picker dismissViewControllerAnimated:YES completion:^{
        DLog(@"Lets display aviary");
        [self displayEditorForImage:image];
    }];
}


-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    // Resetting the status bar here
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
    [picker.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    
}



-(void)uploadPhotos:(NSArray *)assets
{
    @try {
        NSMutableArray *imagesData = [NSMutableArray arrayWithCapacity:2];
        NSString *userId = [User currentlyActiveUser].userID;
        NSString *spotId = self.spotID;
        
        NSDictionary *params = @{@"userId": userId,@"spotId": spotId};
        AFHTTPSessionManager *manager = [SubaAPIClient sharedInstance];
        
        NSURL *baseURL = (NSURL *)[SubaAPIClient subaAPIBaseURL];
        
        NSString *urlPath = [[NSURL URLWithString:kUPLOAD_PHOTOS_PATH relativeToURL:baseURL] absoluteString];
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
            
        }
        
        
        /*Upload photo. New way*/
        NSProgress *progress = nil;
        request = [manager.requestSerializer
                   multipartFormRequestWithMethod:kHTTP_METHOD_POST
                   URLString:urlPath
                   parameters:params
                   constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                       for (NSDictionary *imageInfo in imagesData){
                           //DLog(@"Images being resized");
                           
                           //[self resizePhoto:imageInfo[@"imageData"] towidth:640.0f toHeight:852.0f
                           //      completon:^(UIImage *compressedPhoto, NSError *error){
                           //DLog(@"Does it even get here - %@",imageInfo[@"imageName"]);
                           NSData *imageData = UIImageJPEGRepresentation(imageInfo[@"imageData"], .8);
                           [formData appendPartWithFileData:imageData name:imageInfo[@"imageName"] fileName:[NSString stringWithFormat:@"%@.jpg",imageInfo[@"imageName"]] mimeType:@"image/jpeg"];
                           //}];
                       }

        } error:nil];
        
        NSURLSessionUploadTask *uploadTask = [manager uploadTaskWithStreamedRequest:request progress:&progress completionHandler:^(NSURLResponse *response, id responseObject, NSError *error){
            if (error) {
                // Handle error here. Your photo failed to upload. Will you like to upload again
            }else{
                
                // Photos were uploaded successfully
                DLog(@"Image upload response");
                NSDictionary *photoInfo =  responseObject;
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
        }];
        
        
        [uploadTask resume];
        
        
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
                                            
                                        } error:nil];
        
         [manager.requestSerializer setValue:@"com.suba.subaapp-ios" forHTTPHeaderField:@"x-suba-api-token"];
         AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        self.imageUploadProgressView.hidden = NO;
        
        [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite){
            
            // Anything can happen here so lets just catch the exception
            
            @try{
                
                self.imageUploadProgressView.progress = (float)totalBytesWritten/totalBytesExpectedToWrite;
                
                if(self.imageUploadProgressView.progress == 1.0f){
                    
                    didImageFinishUploading = YES;
                    
                    self.imageUploadProgressView.hidden = YES; // or remove from superview
                    
                }
                
            }@catch(NSException *exception){}
            
        }];
        
        
       [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
           //[self uploadingPhotoView:NO];
           NSError *error = nil;
           NSDictionary *photoInfo = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingAllowFragments error:&error];
           
           [[NSNotificationCenter defaultCenter]
            postNotificationName:kUserReloadStreamNotification object:nil];
           //DLog(@"Old self.photos - %@",self.photos);
           PhotoStreamCell *cell = nil;
           for (NSDictionary *photo in self.photos){
               if([photoInfo[@"id"] integerValue] ==  [photo[@"id"] integerValue]){
                   // Lets replace this NSDictionary coz this object is the photo that was doodled
                   NSUInteger indexOfOriginalPhoto = [self.photos indexOfObject:photo];
                   NSIndexPath *indexPath = [NSIndexPath indexPathForItem:indexOfOriginalPhoto inSection:0];
                   cell = (PhotoStreamCell *)[self.photoCollectionView cellForItemAtIndexPath:indexPath];
                   
                   [self.photos replaceObjectAtIndex:indexOfOriginalPhoto withObject:photoInfo];
                   break;
               }
           }
           
           //DLog(@"Photo Info - %@",photoInfo);
           [Flurry logEvent:@"Photo_Doodled"];
           if (cell != nil) {
               DLog(@"Flipping to show doodle:");
               //cell.showCommentsActionButton.hidden = NO;
               
               [self showDoodleVersionOfPhotoInCell:cell completion:^(BOOL didFlipDoodle) {
                   //[self.photoCollectionView reloadItemsAtIndexPaths:@[[self.photoCollectionView indexPathForCell:cell]]];
                   //cell.commentsIcon.enabled = YES;
                   //cell.commentsIcon.hidden = NO;
                   //cell.showCommentsActionButton.hidden = NO;
                   cell.remixedImageView.alpha = 1;
                   cell.numberOfRemixersLabel.hidden = NO;
                   
                   NSIndexPath *indexPath = [self.photoCollectionView indexPathForCell:cell];
                  NSInteger remixers = [self.photos[indexPath.item][@"remixers"] integerValue];
                   if (remixers == 1){
                       cell.numberOfRemixersLabel.text = [NSString stringWithFormat:@"%li Doodler",(long)remixers];
                   }else{
                       cell.numberOfRemixersLabel.text = [NSString stringWithFormat:@"%li Doodlers",(long)remixers];
                   }

               }];
               
           }else{
               DLog(@"Lust reload the data==");
               [self.photoCollectionView reloadData];
           }
           if (isDoodling) {
               isDoodling = NO;
           }
       } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
           DLog(@"Error serializing %@", error);
           [AppHelper showAlert:@"Upload Failure"
                        message:error.localizedDescription
                        buttons:@[@"OK"] delegate:nil];

       }];
        
         [[NSOperationQueue mainQueue] addOperation:operation];
        
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
    @try{
        NSString *userId = [User currentlyActiveUser].userID;
        NSString *spotId = self.spotID;
        NSDictionary *params = @{@"userId": userId,@"spotId": spotId};
        AFHTTPSessionManager *manager = [SubaAPIClient sharedInstance];
        NSURL *baseURL = (NSURL *)[SubaAPIClient subaAPIBaseURL];
        NSString *urlPath = [[NSURL URLWithString:kUPLOAD_PHOTO_PATH relativeToURL:baseURL] absoluteString];
        
        NSMutableURLRequest *request = [manager.requestSerializer multipartFormRequestWithMethod:kHTTP_METHOD_POST URLString:urlPath parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
            [formData appendPartWithFileData:imageData name:@"picture" fileName:[NSString stringWithFormat:@"%@.jpg",name] mimeType:@"image/jpeg"];
        } error:nil];
        
        [manager.requestSerializer setValue:@"com.suba.subaapp-ios" forHTTPHeaderField:@"x-suba-api-token"];
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        self.imageUploadProgressView.hidden = NO;
        
        [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite){
            // Anything can happen here so lets just catch the exception
            @try{
                self.imageUploadProgressView.progress = (float)totalBytesWritten/totalBytesExpectedToWrite;
                if(self.imageUploadProgressView.progress == 1.0f){
                    didImageFinishUploading = YES;
                    self.imageUploadProgressView.hidden = YES; // or remove from superview
                }
            }@catch(NSException *exception){}
        }];
        
        
        
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation,id responseObject){
            NSError *error = nil;
             if (responseObject != nil){
                 imageToUpload = nil;
                 nameOfImageToUpload = nil;
                 
                 NSDictionary *photoInfo = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingAllowFragments error:&error];
                     DLog(@"Photo info: %@\nSerialized response: %@",photoInfo,operation.response.allHeaderFields[@"x-suba-status-code"]);
                 
                 
                     [Flurry logEvent:@"Photo_Upload"];
                     [[NSNotificationCenter defaultCenter]
                      postNotificationName:kUserReloadStreamNotification object:nil];
                     
                     self.noPhotosView.hidden = YES;
                     self.photoCollectionView.hidden = NO;
                     if (!self.photos){
                         self.photos = [NSMutableArray arrayWithObject:photoInfo];
                     }else{
                         [self.photos insertObject:photoInfo atIndex:0];
                     }
                 
                     [self upDateCollectionViewWithCapturedPhoto:photoInfo];
                }

         
        } failure:^(AFHTTPRequestOperation *operation, NSError *error){
            
            DLog(@"Operation.response: %@",operation.response.allHeaderFields[@"x-suba-status-code"]);
            
            NSString *subaStatusCode = operation.response.allHeaderFields[@"x-suba-status-code"];
            if ([subaStatusCode isEqualToString:kFAILED_UPLOAD]){
                // Image was not uploaded so retry upload
                UIAlertView *failedUploadAlertView = [[UIAlertView alloc] initWithTitle:@"Retry Upload" message:@"There was a problem uploading your photo. Check your internet connection and upload again" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Retry", nil];
                
                failedUploadAlertView.tag = 400;
                [failedUploadAlertView show];
                
            }else if ([subaStatusCode isEqualToString:kRELOAD_STREAM_IMAGES]){
                // Image was uploaded so reload stream
                UIAlertView *failedUploadAlertView = [[UIAlertView alloc] initWithTitle:@"Reload Stream" message:@"Your image was uploaded but we could not update your stream.Hit reload stream to update the stream with the new photo." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Reload Stream", nil];
                failedUploadAlertView.tag = 401;
                [failedUploadAlertView show];
            }
        }];
    
        [[NSOperationQueue mainQueue] addOperation:operation];
    }
    
    @catch (NSException *exception){
        
        [AppHelper showAlert:@"Network Error"
                     message:@"We encountered a problem uploading your photo"
                     buttons:@[@"Try Again"]
                    delegate:nil];
        
        [Flurry logError:@"Photo Upload Error" message:[exception name] exception:exception];
    }
}


-(void)upDateCollectionViewWithCapturedPhoto:(NSDictionary *)photoInfo{
    
        [self.photoCollectionView performBatchUpdates:^{
            @try {
            [self.photoCollectionView
             insertItemsAtIndexPaths:@[
                                       [NSIndexPath indexPathForItem:0 inSection:0]]];
            }@catch (NSException *exception) {
                // What to do when we have an exception
            }
        } completion:^(BOOL finished){
            @try{
            [self.photoCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionLeft animated:YES];
            }@catch (NSException *exception) {
                // What to do when we have an exception
            }
        }];
}


-(void)upDateCollectionViewWithCapturedPhotos:(NSArray *)photoInfo{
    
        [self uploadingPhotoView:NO];
        NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:2];
        for (int x = 0; x < [photoInfo count]; x++) {
            [indexPaths addObject:[NSIndexPath indexPathForItem:x inSection:0]];
        }
        
        [self.photoCollectionView performBatchUpdates:^{
            @try {
            [self.photoCollectionView insertItemsAtIndexPaths:indexPaths];
                 }@catch (NSException *exception) {[self uploadingPhotoView:NO];}
        } completion:^(BOOL finished) {
            @try{
            [self.photoCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionLeft animated:YES];
            
             }@catch (NSException *exception) {[self uploadingPhotoView:NO];}
        }];
        
          
       
}

- (IBAction)doFacebookLogin:(id)sender
{
    [self.facebookLoginIndicator startAnimating];
    
    [AppHelper openFBSession:^(id results, NSError *error) {
        [AppHelper setUserStatus:kSUBA_USER_STATUS_CONFIRMED];
        [Flurry logEvent:@"Account_Confirmed_Facebook"];
        [self.facebookLoginIndicator stopAnimating];
        [self performSelector:@selector(dismissCreateAccountPopUp)];
        if ([pendingActions count] > 0) {
            int pAction = [[pendingActions lastObject] intValue];
            [self executePendingAction:pAction];
        }
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
    [self showPhotoOptions];
    //[self performSelector:@selector(pickImage:) withObject:@(kTakeCamera) afterDelay:0.5];
}

- (IBAction)registerForPushNotification:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kUserDidSignUpNotification object:nil];
    [self performSelector:@selector(dismissNotificationScreen:) withObject:nil afterDelay:0.5];
}

- (IBAction)remixPhoto:(UIButton *)sender
{
    // Remix Photo
    isDoodling = YES;
    PhotoStreamCell *cell = (PhotoStreamCell *)sender.superview.superview.superview;
    selectedPhotoCell = cell;
    [self doodlePhoto:cell];
    
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"SpotSettingsSegue"]) {
        if ([segue.destinationViewController isKindOfClass:[StreamSettingsViewController class]]) {
            StreamSettingsViewController *albumVC = segue.destinationViewController;
            albumVC.spotID = (NSString *)sender;
            albumVC.spotInfo = self.spotInfo;
            albumVC.whereToUnwind = [self.parentViewController childViewControllers][0];
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
    }else if ([segue.identifier isEqualToString:@"CommentsSegue"]){
        CommentsViewController *commentsVC = segue.destinationViewController;
        
        commentsVC.photoId = self.photoInView[@"id"];
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
    
    [[UINavigationBar appearance] setBackgroundImage:[[UIImage alloc] init] forBarMetrics:UIBarMetricsDefault];
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
    
    [[UINavigationBar appearance] setBackgroundImage:[[UIImage alloc] init] forBarMetrics:UIBarMetricsDefault];
}




#pragma mark - Send SMS
-(void)sendSMSToRecipients:(NSMutableArray *)recipients
{
    @try {
        NSString *senderName = nil;
        if ([MFMessageComposeViewController canSendText]){
            
            MFMessageComposeViewController *smsComposer = [[MFMessageComposeViewController alloc] init];
            
            smsComposer.messageComposeDelegate = self;
            smsComposer.recipients = recipients;
            
            if (branchURLforInviteToStream) {
                // We already have the branch URL set up
                DLog(@"Branch URL is already set up");
                smsComposer.body = [NSString stringWithFormat:@"See and add photos to the \"%@\" photo stream on Suba.\nSTEP 1) Download Suba: %@ \nSTEP 2) Go to Join Stream \nSTEP 3) Use invite code: %@.",self.spotInfo[@"spotName"],branchURLforInviteToStream,self.spotInfo[@"spotCode"]];
                [smsComposer.navigationBar setTranslucent:NO];
                
                if (!self.presentedViewController){
                    [self presentViewController:smsComposer animated:YES completion:nil];
                }
                
            }else{
                
            Branch *branch = [Branch getInstance:@"55726832636395855"];
            if ([AppHelper firstName].length > 0 && [AppHelper lastName].length > 0) {
                senderName = [NSString stringWithFormat:@"%@ %@",[AppHelper firstName],[AppHelper lastName]];
                
            }else{
                
                senderName = [AppHelper userName];
            }
            
            
            DLog(@"Stream code: - %@\n Sender: %@\nProfile photo: %@",self.spotInfo,senderName,[[AppHelper profilePhotoURL] class]);
            
            if ([AppHelper profilePhotoURL] == NULL | [[AppHelper profilePhotoURL] class] == [NSNull class]) {
                [AppHelper setProfilePhotoURL:@"-1"];
            }
            NSDictionary *dict = @{
                                   @"desktop_url" : @"http://app.subaapp.com/streams/invite",
                                   @"streamId":self.spotInfo[@"spotId"],
                                   @"photos" : self.spotInfo[@"numberOfPhotos"],
                                   @"streamName":self.spotInfo[@"spotName"],
                                   @"sender": senderName,
                                   @"streamCode" : self.spotInfo[@"spotCode"],
                                   @"senderPhoto" : [AppHelper profilePhotoURL]};
            
            
            NSMutableDictionary *streamDetails = [NSMutableDictionary dictionaryWithDictionary:dict];
            
            
            
            
            [branch getShortURLWithParams:streamDetails andTags:nil andChannel:@"text_message" andFeature:BRANCH_FEATURE_TAG_SHARE andStage:nil andCallback:^(NSString *url){
                branchURLforInviteToStream = url;
                DLog(@"URL from Branch: %@",url);
                smsComposer.body = [NSString stringWithFormat:@"See and add photos to the \"%@\" photo stream on Suba.\nSTEP 1) Download Suba: %@ \nSTEP 2) Go to Join Stream \nSTEP 3) Use invite code: %@.",self.spotInfo[@"spotName"],url,self.spotInfo[@"spotCode"]];
                
                [smsComposer.navigationBar setTranslucent:NO];
                
                if (!self.presentedViewController){
                    [self presentViewController:smsComposer animated:YES completion:nil];
                }
            }];
            
        }
            
        }else{
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:@"Text Message Failure"
                                  message:
                                  @"Your device doesn't support in-app sms"
                                  delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }

    }
    @catch (NSException *exception) {
        DLog(@"exception name: %@\nexception reason: %@\nException info: %@",exception.name,exception.reason,[exception.userInfo debugDescription]);
        
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Oops:)"
                              message:
                              @"Something went wrong.Please try again."
                              delegate:nil cancelButtonTitle:@"Try again" otherButtonTitles:nil];
        [alert show];
    }
}


- (IBAction)invitePeopleByEmail:(UIButton *)sender
{
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mailComposer = [[MFMailComposeViewController alloc] init];
        mailComposer.mailComposeDelegate = self;
        
        [mailComposer.navigationBar setTranslucent:NO];
        
        [mailComposer.navigationItem setTitle:@"Send Email"];
        
        [mailComposer setSubject:[NSString stringWithFormat:@"See and add photos to the  \"%@\" photo stream",self.spotInfo[@"spotName"]]];
        
        if (branchURLforInviteToStream) {
            //We already have the branch URL
            NSString *shareText = [NSString stringWithFormat:@"<p>See and add photos to the \"%@\" photo stream</p><ul><li>Step 1: Download Suba: %@</li><li>Step 2: Go to Join Stream (in the app, it’s via the + sign at the top right)</li><li>Step 3: Enter invite code: %@</li></ul>",self.spotInfo[@"spotName"],branchURLforInviteToStream,self.spotInfo[@"spotCode"]];
            
            
            [mailComposer setMessageBody:shareText isHTML:YES];
            [Flurry logEvent:@"Share_Stream_Email_Done"];
            
            if (!self.presentedViewController){
                [self presentViewController:mailComposer animated:YES completion:nil];
            }
            
        }else{
        
        NSString *senderName = nil;
        Branch *branch = [Branch getInstance:@"55726832636395855"];
        if ([AppHelper firstName].length > 0 && [AppHelper lastName].length > 0) {
            senderName = [NSString stringWithFormat:@"%@ %@",[AppHelper firstName],[AppHelper lastName]];
            
        }else if([AppHelper firstName].length > 0 && ([AppHelper lastName] == NULL | [[AppHelper lastName] class]== [NSNull class] | [AppHelper lastName].length == 0)){
            
            senderName = [AppHelper firstName];
        }
        if ([AppHelper profilePhotoURL] == NULL | [[AppHelper profilePhotoURL] class] == [NSNull class]) {
            [AppHelper setProfilePhotoURL:@"-1"];
        }
        NSDictionary *dict = @{
                               @"desktop_url" : @"http://app.subaapp.com/streams/invite",
                               @"streamId":self.spotID,
                               @"photos" : self.spotInfo[@"numberOfPhotos"],
                               @"streamName":self.spotInfo[@"spotName"],
                               @"sender": senderName,
                               @"streamCode" : self.spotInfo[@"spotCode"],
                               @"senderPhoto" : [AppHelper profilePhotoURL]};
        
        
        NSMutableDictionary *streamDetails = [NSMutableDictionary dictionaryWithDictionary:dict];
        
        [branch getShortURLWithParams:streamDetails
                              andTags:nil
                           andChannel:@"email"
                           andFeature:BRANCH_FEATURE_TAG_SHARE
                             andStage:nil
                          andCallback:^(NSString *url){
                              branchURLforInviteToStream = url;
        DLog(@"URL from Branch: %@",url);
                              
        NSString *shareText = [NSString stringWithFormat:@"<p>See and add photos to the \"%@\" photo stream</p><ul><li>Step 1: Download Suba: %@</li><li>Step 2: Go to Join Stream (in the app, it’s via the + sign at the top right)</li><li>Step 3: Enter invite code: %@</li></ul>",self.spotInfo[@"spotName"],url,self.spotInfo[@"spotCode"]];
                              
                              
        [mailComposer setMessageBody:shareText isHTML:YES];
        [Flurry logEvent:@"Share_Stream_Email_Done"];
                              
        if (!self.presentedViewController){
            [self presentViewController:mailComposer animated:YES completion:nil];
        }
                              
      }];
   }
    }else{
        [AppHelper showAlert:@"Configure email" message:@"Hey there:) Do you mind configuring your Mail app to send email" buttons:@[@"OK"] delegate:nil];
    }
}


- (IBAction)invitePeopleBySMS:(id)sender
{
    [self sendSMSToRecipients:nil];
}


- (IBAction)inviteWhatsappContactsToStream:(id)sender
{
    if ([WhatsAppKit isWhatsAppInstalled]){
        if(branchURLforInviteToStream){
            // We already have the URL
            DLog(@"Branch URL already installed");
            NSString *message = [NSString stringWithFormat:@"See and add photos to the \"%@\" photo stream on Suba.\nSTEP 1) Download Suba: %@ \nSTEP 2) Go to Join Stream \nSTEP 3) Use invite code: %@.",self.spotInfo[@"spotName"],branchURLforInviteToStream,self.spotInfo[@"spotCode"]];
            
            DLog(@"Yes whatsapp is installed so we show the whatsapp");
            [WhatsAppKit launchWhatsAppWithMessage:message];
        }else{
            NSString *senderName = nil;
            Branch *branch = [Branch getInstance:@"55726832636395855"];
            if ([AppHelper firstName].length > 0 && [AppHelper lastName].length > 0) {
                senderName = [NSString stringWithFormat:@"%@ %@",[AppHelper firstName],[AppHelper lastName]];
                
            }else{
                senderName = [AppHelper userName];
            }
            
            DLog(@"Stream code: - %@\n Sender: %@\nProfile photo: %@",self.spotInfo,senderName,[[AppHelper profilePhotoURL] class]);
            
            if ([AppHelper profilePhotoURL] == NULL | [[AppHelper profilePhotoURL] class] == [NSNull class]) {
                [AppHelper setProfilePhotoURL:@"-1"];
            }
            
            NSDictionary *dict = @{
                                   @"desktop_url" : @"http://app.subaapp.com/streams/invite",
                                   @"streamId":self.spotInfo[@"spotId"],
                                   @"photos" : self.spotInfo[@"numberOfPhotos"],
                                   @"streamName":self.spotInfo[@"spotName"],
                                   @"sender": senderName,
                                   @"streamCode" : self.spotInfo[@"spotCode"],
                                   @"senderPhoto" : [AppHelper profilePhotoURL]};
            
            
            NSMutableDictionary *streamDetails = [NSMutableDictionary dictionaryWithDictionary:dict];
            
            [branch getShortURLWithParams:streamDetails andTags:nil andChannel:@"whatsapp_message" andFeature:BRANCH_FEATURE_TAG_SHARE andStage:nil andCallback:^(NSString *url){
                branchURLforInviteToStream = url;
                DLog(@"URL from Branch: %@",url);
                NSString *message = [NSString stringWithFormat:@"See and add photos to the \"%@\" photo stream on Suba.\nSTEP 1) Download Suba: %@ \nSTEP 2) Go to Join Stream \nSTEP 3) Use invite code: %@.",self.spotInfo[@"spotName"],url,self.spotInfo[@"spotCode"]];
                
                DLog(@"Yes whatsapp is installed so we show the whatsapp");
                [WhatsAppKit launchWhatsAppWithMessage:message];

            }];
        }
    }else{
        [AppHelper showAlert:@"Invite via Whatsapp" message:@"Whatsapp is not installed on your device" buttons:@[@"OK"] delegate:nil];
    }
    //[self performSegueWithIdentifier:@"InviteFriendsSegue" sender:nil];
}

- (IBAction)showOtherInviteOptions:(UIButton *)sender
{
    PhotoStreamFooterView *footerView = (PhotoStreamFooterView *)sender.superview.superview;
    
    [UIView animateWithDuration:.8 animations:^{
        
        sender.alpha = 0;
        footerView.emailTextField.alpha = 0;
        footerView.smsInviteButton.alpha = 1;
        footerView.inviteByWhatsappButton.alpha = 1;
        
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
- (void)showDoodleVersionOfPhotoInCell:(PhotoStreamCell *)cell completion:(SBFlipDoodleCompletionHandler)completionHandler
{
    if (cell.photoCardImage.alpha == 1) {
        [UIView transitionWithView:cell.photoCardImage duration:0.8 options:UIViewAnimationOptionTransitionFlipFromRight animations:^{
            cell.photoCardImage.alpha = 0;
            cell.remixedImageView.alpha = 1;
        } completion:completionHandler];
    }else{
        [UIView transitionWithView:cell.remixedImageView duration:0.8 options:UIViewAnimationOptionTransitionFlipFromRight animations:^{
            cell.photoCardImage.alpha = 1;
            cell.remixedImageView.alpha = 0;
        } completion:completionHandler];
    }
}

- (IBAction)flipPhotoToShowRemix:(id)sender
{
    UIButton *flipButton = (UIButton *)sender;
    PhotoStreamCell *cell = (PhotoStreamCell *)flipButton.superview.superview.superview;
    
    [self showDoodleVersionOfPhotoInCell:cell completion:nil];
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


- (void)showHiddenMoreOptions
{
   
    // Get the container view and increase height
    
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
        // Present Action Sheet
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Share this stream" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Via Facebook",@"Via Twitter",@"Via Email", nil];
        
         actionSheet.tag = 7000;
        [actionSheet showInView:self.view];
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
            [self performSegueWithIdentifier:@"SpotSettingsSegue" sender:self.spotID];
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
                            //DLog(@"User preferences - %@",[AppHelper userPreferences]);
                            [self performSelector:@selector(dismissCreateAccountPopUp)];
                            if ([pendingActions count] > 0) {
                                int pAction = [[pendingActions lastObject] intValue];
                                [self executePendingAction:pAction];
                            }
                           
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


- (void)openNativeCamera:(UIImagePickerControllerSourceType)sourceType
{
    UIImagePickerController *nativepickerController = [[UIImagePickerController alloc] init];
    nativepickerController.delegate = self;
    nativepickerController.sourceType = sourceType;
    
    NSArray *sourceTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
    
    if ([sourceTypes containsObject:@"public.image"]) {
        if (sourceType == UIImagePickerControllerSourceTypeCamera) {
            DLog(@"Camera source types: %@",sourceTypes);
            nativepickerController.allowsEditing = YES;
            //nativepickerController.cameraFlashMode = UIImagePickerControllerCameraFlashModeOn;
        }else{
            
            /*nativepickerController.navigationController.navigationBar.tintColor = kSUBA_APP_COLOR;
             nativepickerController.navigationController.navigationBar.translucent = YES;
             [nativepickerController.navigationController.navigationItem setTitle:@"Choose Photo"];*/
            
            [nativepickerController setNavigationBarHidden:NO];
            nativepickerController.navigationBar.barTintColor = kSUBA_APP_COLOR;
            [nativepickerController.navigationBar setTintColor:[UIColor whiteColor]];
            [nativepickerController.navigationBar setTranslucent:NO];
            [nativepickerController.navigationItem setTitle:@"Choose Photo"];
        }
    }
    
    [self presentViewController:nativepickerController animated:YES completion:nil];
}




/*#pragma mark - DBCameraViewControllerDelegate
- (void) camera:(id)cameraViewController didFinishWithImage:(UIImage *)image withMetadata:(NSDictionary *)metadata
{
    
    UIImage *fullResolutionImage = [image rotateUIImage];
    NSData *img = UIImageJPEGRepresentation(fullResolutionImage, 1.0);
    
    DLog(@"Size of image - %fKB",[img length]/1024.0f);
    [cameraViewController dismissViewControllerAnimated:YES completion:^{
        DLog(@"Lets display aviary");
        [self displayEditorForImage:fullResolutionImage];
    }];
}

- (void) dismissCamera:(id)cameraViewController{
    //DLog();
    [self dismissViewControllerAnimated:NO completion:nil];
    [cameraViewController restoreFullScreenMode];
}



- (void)openDBCamera
{
    DBCameraViewController *cameraController = [DBCameraViewController initWithDelegate:self];
    
    //[cameraController setForceQuadCrop:YES];
    //[cameraController set]
    
    DBCameraContainerViewController *container = [[DBCameraContainerViewController alloc] initWithDelegate:self];
    [cameraController setUseCameraSegue:NO];
    
    [container setCameraViewController:cameraController];
    [container setFullScreenMode];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:container];
    [nav setNavigationBarHidden:YES];
    
    [self presentViewController:nav animated:YES completion:nil];
}*/


- (void)displayEditorForImage:(UIImage *)imageToEdit
{
    //dispatch_once(&onceToken, ^{
        [AFPhotoEditorController setAPIKey:kAviaryAPIKey secret:kAviarySecret];
         AFPhotoEditorController *editorController = [[AFPhotoEditorController alloc] initWithImage:imageToEdit];
        [editorController setDelegate:self];
    
    if (isDoodling) {
        // Customize the tools that appear
        // Set the tools to Draw (to be displayed in that order).
        [AFPhotoEditorCustomization setToolOrder:@[kAFDraw]];
    }else{
        
        // Customize the tools that appear
        // Set the tools to Contrast, Brightness, Enhance, and Crop (to be displayed in that order).
        [AFPhotoEditorCustomization setToolOrder:@[kAFEnhance,kAFEffects,kAFCrop,kAFOrientation]];
    }
        [self presentViewController:editorController animated:YES completion:nil];
}


#pragma mark - AFPhotoEditorDelegate
- (void)photoEditor:(AFPhotoEditorController *)editor finishedWithImage:(UIImage *)image
{
    //[self.library saveImage:image toAlbum:@"Suba" completion:^(NSURL *assetURL, NSError *error){} failure:nil];
    
    // Handle the result image here
    [editor dismissViewControllerAnimated:YES completion:^{
        // Upload the image after we have dismissed the editor
        if (isDoodling) {
            PhotoStreamCell *cell = (PhotoStreamCell *)[self.photoCollectionView
                                                        cellForItemAtIndexPath:[NSIndexPath indexPathForItem:selectedPhotoIndexPath.item inSection:0]];
            
            cell.remixedImageView.alpha = 1;
            cell.remixedImageView.image = image;
            NSData *data = UIImageJPEGRepresentation(image, .8);
            DLog(@"Uploading Doodle");
            [self uploadDoodle:data WithName:self.photos[selectedPhotoIndexPath.item][@"s3name"]];
    }else{
        DLog(@"Upload photo");
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy:MM:dd HH:mm:ss.SSSSSS"];
        NSString *timeStamp = [dateFormatter stringFromDate:[NSDate date]];
        NSString *trimmedString = [timeStamp stringByReplacingOccurrencesOfString:@" " withString:@""];
        trimmedString = [trimmedString stringByReplacingOccurrencesOfString:@"-" withString:@":"];
        trimmedString = [trimmedString stringByReplacingCharactersInRange:NSMakeRange([trimmedString length]-7, 7) withString:@""];
        
        //[self resizePhoto:image towidth:1136.0f toHeight:640.0f
                //completon:^(UIImage *compressedPhoto, NSError *error) {
                   // if(!error){
                        imageToUpload = UIImageJPEGRepresentation(image, .8);
                        nameOfImageToUpload = trimmedString;
                        DLog(@"Size of image - %fKB",[imageToUpload length]/1024.0f);
                        [self uploadPhoto:imageToUpload WithName:trimmedString];
                    //}else DLog(@"Image resize error :%@",error);
                //}];
        }

    }];

}

- (void)photoEditorCanceled:(AFPhotoEditorController *)editor
{
    // Handle cancellation here
    [editor dismissViewControllerAnimated:YES completion:^{
        if (isDoodling){
            isDoodling = NO;
        }
    }];
    
    DLog();
}



- (void)imageSavedToPhotosAlbum:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    
    if (!error) {
        //[AppHelper showNotificationWithMessage:@"Photo saved to gallery" type:CSNotificationViewStyleSuccess //inViewController:self completionBlock:^{
        
        DLog(@"Context info - %@",contextInfo);
    }
}


-(void)uploadingPhotoView:(BOOL)flag
{
    /*DLog(@"Uploading photo");
    self.uploadingPhoto.hidden = !flag;
    if (flag == YES) {
        [self.uploadingPhotoIndicator startAnimating];
    }else [self.uploadingPhotoIndicator stopAnimating];*/
    
}

- (void)downloadPhoto:(UIImageView *)destination withURL:(NSString *)imgURL downloadOption:(SDWebImageOptions)option
{
    if ([destination.subviews count] == 1) {
        // Lets remove all subviews
        [[destination subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    }
    
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
                 DLog(@"error - %@",error.userInfo);
                 
                 NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:imgURL]];
                 [destination setImageWithURLRequest:request placeholderImage:[UIImage imageNamed:@"newOverlay"] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                     
                     [progressView removeFromSuperview];
                     if (!error) {
                         self.albumSharePhoto = image;
                     }
                 } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                     DLog(@"Error: %@",error.userInfo);
                 }];
            }
         }];

    //}
    
}


- (void)executePendingAction:(ActionPending)pendingAction
{
    DLog("Pending request");
    if (pendingAction == kActionLike) {
        [self performSelector:@selector(likePhotoWithID:atIndexPath:) withObject:selectedPhotoId withObject:selectedPhotoIndexPath];
    }else if(pendingAction == kActionEdit){
        [self performSelector:@selector(doodlePhoto:) withObject:selectedPhotoCell];
    }
}


- (void)doodlePhoto:(PhotoStreamCell *)cell
{
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
                
                [self displayEditorForImage:selectedPhoto];
            }];
            
        }else if (cell.remixedImageView.alpha == 1){
            selectedPhoto = cell.remixedImageView.image;
            selectedPhotoIndexPath = indexpath;
            [self displayEditorForImage:selectedPhoto];
            
            //[self performSegueWithIdentifier:@"DoodleSegue" sender:selectedPhoto];
        }
    }else{
        
        selectedPhoto = cell.photoCardImage.image;
        selectedPhotoIndexPath = indexpath;
        [self displayEditorForImage:selectedPhoto];
        
        //[self performSegueWithIdentifier:@"DoodleSegue" sender:selectedPhoto];
        
    }
}


- (void)showDoodle:(PhotoStreamCell *)cell
{
    cell.photoCardImage.alpha = 0;
    cell.remixedImageView.alpha = 1;
}

-(void)findAndShowPhoto:(NSString *)photoToShow
{
    NSUInteger index = 0;
    
    // Go find this photo in self.photos
    for (NSDictionary *photoInfo in self.photos){
        DLog(@"s3name: %@\nPhoto to show: %@",photoInfo[@"s3name"],photoToShow);
        
        if([photoInfo[@"s3name"] isEqualToString:photoToShow]){
           // index = [self.photos indexOfObject:photoToShow];
            DLog(@"Index: %lu",(unsigned long)index);
            break;
        }
        index++;
    }
    
    // Now determine where we need o scroll to
    //int scrollPosition = (285 * index) + 5;
    //DLog(@"Scroll position - %d",scrollPosition);
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:(index % 12) inSection:0];
    
    [self.photoCollectionView scrollToItemAtIndexPath:indexPath
                                     atScrollPosition:UICollectionViewScrollPositionLeft
                                             animated:YES];
    
    if (self.shouldShowDoodle == YES){
        DLog(@"We are flipping the photo");
        PhotoStreamCell *cell =  (PhotoStreamCell *)[self.photoCollectionView cellForItemAtIndexPath:indexPath];
        
        [self performSelector:@selector(showDoodle:)
                   withObject:cell
                   afterDelay:1.5];
        
           // } completion:NULL];
    }
}


-(IBAction)showCommentsAction:(UIButton *)sender
{
    PhotoStreamCell *cell = (PhotoStreamCell *)sender.superview.superview.superview;
    NSIndexPath *indexpath = [self.photoCollectionView indexPathForCell:cell];
    self.photoInView = self.photos[indexpath.row];

    DLog(@"Photo selected: %@",self.photoInView);
    [self performSegueWithIdentifier:@"CommentsSegue" sender:nil];
    
}


/*- (UIImage *)fixrotation:(UIImage *)image{
    
    int kMaxResolution = 320; // Or whatever
    
    CGImageRef imgRef = image.CGImage;
    
    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    CGRect bounds = CGRectMake(0, 0, width, height);
    if (width > kMaxResolution || height > kMaxResolution) {
        CGFloat ratio = width/height;
        if (ratio > 1) {
            bounds.size.width = kMaxResolution;
            bounds.size.height = bounds.size.width / ratio;
        }
        else {
            bounds.size.height = kMaxResolution;
            bounds.size.width = bounds.size.height * ratio;
        }
    }
    
    CGFloat scaleRatio = bounds.size.width / width;
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef));
    CGFloat boundHeight;
    UIImageOrientation orient = image.imageOrientation;
    switch(orient) {
            
        case UIImageOrientationUp: //EXIF = 1
            transform = CGAffineTransformIdentity;
            break;
            
        case UIImageOrientationUpMirrored: //EXIF = 2
            transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            break;
            
        case UIImageOrientationDown: //EXIF = 3
            transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationDownMirrored: //EXIF = 4
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);
            transform = CGAffineTransformScale(transform, 1.0, -1.0);
            break;
            
        case UIImageOrientationLeftMirrored: //EXIF = 5
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationLeft: //EXIF = 6
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationRightMirrored: //EXIF = 7
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeScale(-1.0, 1.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
            
        case UIImageOrientationRight: //EXIF = 8
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
            
        default:
            [NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];
            
    }
    
    UIGraphicsBeginImageContext(bounds.size);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft) {
        CGContextScaleCTM(context, -scaleRatio, scaleRatio);
        CGContextTranslateCTM(context, -height, 0);
    }
    else {
        CGContextScaleCTM(context, scaleRatio, -scaleRatio);
        CGContextTranslateCTM(context, 0, -height);
    }
    
    CGContextConcatCTM(context, transform);
    
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);
    UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();  
    
    return imageCopy;  
}*/

-(void)prepareBranchURLforInvitingFriendsToStream
{
    NSString __block *branchurl = @"";
    NSString *senderName = nil;
    
        Branch *branch = [Branch getInstance:@"55726832636395855"];
        if ([AppHelper firstName].length > 0 && [AppHelper lastName].length > 0) {
            senderName = [NSString stringWithFormat:@"%@ %@",[AppHelper firstName],[AppHelper lastName]];
            
        }else{
            
            senderName = [AppHelper userName];
        }
        
        
        DLog(@"Stream code: - %@\n Sender: %@\nProfile photo: %@",self.spotInfo,senderName,[[AppHelper profilePhotoURL] class]);
        
        if ([AppHelper profilePhotoURL] == NULL | [[AppHelper profilePhotoURL] class] == [NSNull class]) {
            [AppHelper setProfilePhotoURL:@"-1"];
        }
    
    
        NSDictionary *dict = @{
                               @"desktop_url" : @"http://app.subaapp.com/streams/invite",
                               @"streamId":self.spotInfo[@"spotId"],
                               @"photos" : self.spotInfo[@"photos"],
                               @"streamName":self.spotInfo[@"spotName"],
                               @"sender": senderName,
                               @"streamCode" : self.spotInfo[@"spotCode"],
                               @"senderPhoto" : [AppHelper profilePhotoURL]};
        
        
        NSMutableDictionary *streamDetails = [NSMutableDictionary dictionaryWithDictionary:dict];
    
        [branch getShortURLWithParams:streamDetails andTags:nil andChannel:@"text_message" andFeature:BRANCH_FEATURE_TAG_SHARE andStage:nil andCallback:^(NSString *url){
            
            DLog(@"URL from Branch: %@",url);
            branchURLforInviteToStream = url;
            branchurl = url;
        }];
}


-(void)prepareBranchURLforSharingStream
{
    NSString *senderName = nil;
    
    Branch *branch = [Branch getInstance:@"55726832636395855"];
    if ([AppHelper firstName].length > 0 && [AppHelper lastName].length > 0) {
        senderName = [NSString stringWithFormat:@"%@ %@",[AppHelper firstName],[AppHelper lastName]];
        
    }else{
        
        senderName = [AppHelper userName];
    }
    
    
    if ([AppHelper profilePhotoURL] == NULL | [[AppHelper profilePhotoURL] class] == [NSNull class]) {
        [AppHelper setProfilePhotoURL:@"-1"];
    }
    
    NSDictionary *dict = @{
                           @"desktop_url" : @"http://app.subaapp.com/streams/share",
                           @"streamId":self.spotInfo[@"spotId"],
                           @"photos" : self.spotInfo[@"photos"],
                           @"streamName":self.spotInfo[@"spotName"],
                           @"sender": senderName,
                           @"streamCode" : self.spotInfo[@"spotCode"],
                           @"senderPhoto" : [AppHelper profilePhotoURL]};
    
    
    NSMutableDictionary *streamDetails = [NSMutableDictionary dictionaryWithDictionary:dict];
    
    [branch getShortURLWithParams:streamDetails andTags:nil andChannel:@"share_stream" andFeature:BRANCH_FEATURE_TAG_SHARE andStage:nil andCallback:^(NSString *url){
        
        DLog(@"URL from Branch: %@",url);
        branchURLforShareStream = url; 
        
    }];
}


-(void)setUpRightBarButtonItems
{
    UIBarButtonItem *addPhotoButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"addphoto"] style:UIBarButtonItemStyleBordered target:self action:@selector(cameraButtonTapped:)];
    
    UIBarButtonItem *inviteFriendsIcon = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"inviteIcon"] style:UIBarButtonItemStyleBordered target:self action:@selector(requestForPhotos:)];
    
    UIBarButtonItem *moreIcon = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"moreIcon_nav"] style:UIBarButtonItemStyleBordered target:self action:@selector(showHiddenMoreOptions)]; 
    
    
    [self.navigationItem setRightBarButtonItems:@[moreIcon,inviteFriendsIcon,addPhotoButton] animated:YES];
    
    
}





@end
